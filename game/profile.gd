extends RefCounted
const Run = preload("res://game/run.gd")
const Chambers = preload("res://game/chambers.gd")
const Upgrades = preload("res://game/upgrades.gd")
const QUEST_COINS := 18
const QUEST_XP := 40
var path := "user://quarry-v1.json"
var data: Dictionary
var recovery := ""
var last_error := ""
var migration_source := ""
var recovery_source := ""

func _init(save_path: String = "user://quarry-v1.json") -> void:
	path=save_path;data=defaults();load_profile()

static func defaults() -> Dictionary:
	return {"version":2,"sequence":0,"xp":0,"coins":0,"gear":Upgrades.normalize({}),"stars":[],"campaign_frontier":0,"next_run":1,"last_paid_run":0,"active":{},"totals":{"rounds":0,"clears":0,"crystals":0,"ricochets":0,"perfect":0,"daily_clears":0},"records":{"best_score":0,"best_combo":0,"chains":0,"endless_depth":0,"login_streak":0},"login_day":-1,"streak":0,"quest_day":-1,"quest":{"crystals":0,"clears":0,"ricochets":0},"quest_claims":[],"daily_paid":-1,"achievements":{},"music":true,"sfx":true,"motion":true,"vibration":true,"skin":0,"last_receipt":{}}

static func today() -> int:return int(Time.get_unix_time_from_system()/86400.0)
static func login_reward(streak:int) -> int:return int((35+clampi(streak,1,7)*15)/5)

static func valid(v: Variant) -> bool:
	return _valid(v,false)

static func valid_legacy(v:Variant) -> bool:
	return _valid(v,true)

static func _valid(v:Variant, legacy:bool) -> bool:
	if not v is Dictionary:return false
	for key in defaults():
		if legacy and key=="campaign_frontier":continue
		if not v.has(key):return false
	if v.version!=(1 if legacy else 2):return false
	if not legacy and (not Run.number(v.campaign_frontier,0,Chambers.COUNT-1) or float(v.campaign_frontier)!=floor(float(v.campaign_frontier))):return false
	for key in ["sequence","xp","coins","next_run","last_paid_run","streak","skin"]:
		if not Run.number(v[key],0,1e12) or float(v[key])!=floor(float(v[key])):return false
	if v.skin>2 or v.streak>7 or v.next_run<1 or v.last_paid_run>=v.next_run:return false
	for key in ["login_day","quest_day","daily_paid"]:
		if not Run.number(v[key],-1,1e9) or float(v[key])!=floor(float(v[key])):return false
	for key in ["music","sfx","motion","vibration"]:
		if not v[key] is bool:return false
	for key in ["gear","active","totals","records","quest","achievements","last_receipt"]:
		if not v[key] is Dictionary:return false
	if not v.active.is_empty():
		if legacy:
			if Run.migrate_legacy_snapshot(v.active).is_empty():return false
		elif not Run.valid_snapshot(v.active):return false
		if int(v.active.run_id)<=int(v.last_paid_run) or int(v.active.run_id)>=int(v.next_run):return false
	for key in (["drill","echo","salvage"] if legacy else Upgrades.KEYS):
		if not Run.number(v.gear.get(key),0,4 if legacy else Upgrades.cap(key)) or float(v.gear[key])!=floor(float(v.gear[key])):return false
	for section in ["totals","records","quest"]:
		for key in defaults()[section]:
			if not Run.number(v[section].get(key),0,1e12) or float(v[section][key])!=floor(float(v[section][key])):return false
	if not v.stars is Array or v.stars.size()>(30 if legacy else Chambers.COUNT) or not v.quest_claims is Array or v.quest_claims.size()>3:return false
	for n in v.stars:
		if not Run.number(n,0,3) or float(n)!=floor(float(n)):return false
	for key in v.quest_claims:
		if key not in ["crystals","clears","ricochets"]:return false
	for key in v.achievements:
		if not key is String or not v.achievements[key] is bool:return false
	if not v.last_receipt.is_empty():
		for key in ["coins","xp","run_id"]:
			if not Run.number(v.last_receipt.get(key),0,1e12) or float(v.last_receipt[key])!=floor(float(v.last_receipt[key])):return false
		if int(v.last_receipt.run_id)>int(v.last_paid_run):return false
	return true

static func migrate_legacy(v:Variant) -> Dictionary:
	if not valid_legacy(v):return {}
	var converted:Dictionary=v.duplicate(true)
	converted.version=2
	converted.gear=Upgrades.normalize({"drill":v.gear.drill,"echo":v.gear.echo,"salvage":v.gear.salvage})
	converted.stars=[];converted.stars.resize(Chambers.COUNT);converted.stars.fill(0)
	for i in range(v.stars.size()):converted.stars[Chambers.legacy_to_current(i)]=int(v.stars[i])
	var next_old:=0
	while next_old<v.stars.size() and int(v.stars[next_old])>0:next_old+=1
	converted.campaign_frontier=50 if next_old==30 else Chambers.legacy_to_current(next_old)
	if not v.active.is_empty():converted.active=Run.migrate_legacy_snapshot(v.active)
	return converted if valid(converted) else {}

static func read_json(filename: String) -> Variant:
	var parser:=JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(filename))==OK else null

func load_profile() -> void:
	var selected:Dictionary={};var selected_path:="";var selected_legacy:=false
	for candidate in [path,path+".tmp",path+".recovery.tmp",path+".bak",path+".migration-v1.bak"]:
		if not FileAccess.file_exists(candidate):continue
		var v: Variant=read_json(candidate)
		var legacy:=valid_legacy(v)
		var converted:Dictionary=migrate_legacy(v) if legacy else v if valid(v) else {}
		if converted.is_empty():continue
		if selected.is_empty() or int(converted.sequence)>int(selected.sequence):
			selected=converted;selected_path=candidate;selected_legacy=legacy
	if selected.is_empty():
		if FileAccess.file_exists(path):recovery="Your save needs recovery. Original files are preserved; this session starts fresh."
		return
	data=selected
	if selected_legacy:migration_source=selected_path
	# A complete v2 temporary write can outlive a v1 primary after interruption.
	if not selected_legacy and not FileAccess.file_exists(path+".migration-v1.bak"):
		for candidate in [path,path+".bak"]:
			if FileAccess.file_exists(candidate) and valid_legacy(read_json(candidate)):migration_source=candidate;break
	if selected_legacy or selected_path!=path:
		recovery_source=selected_path
		recovery="Your original progress is preserved in the expanded quarry." if selected_legacy else "Recovered your last safe save."
		# Never truncate the selected temporary file: it may be the only safe copy.
		var staging_suffix:=".recovery.tmp" if selected_path==path+".tmp" else ".tmp"
		if not commit(data,staging_suffix):recovery="Your progress was recovered, but storage must be available before it can be saved."

func _preserve_migration_original() -> bool:
	if migration_source.is_empty():return true
	var backup:=path+".migration-v1.bak"
	if FileAccess.file_exists(backup):
		if valid_legacy(read_json(backup)):return true
		last_error="The original migration backup needs recovery; no save was replaced.";return false
	if not FileAccess.file_exists(migration_source) or not valid_legacy(read_json(migration_source)):
		last_error="The original save could not be preserved.";return false
	if DirAccess.copy_absolute(migration_source,backup)!=OK:
		last_error="The original save backup could not be written. Please retry.";return false
	return true

func commit(next: Dictionary, staging_suffix:String=".tmp") -> bool:
	if staging_suffix not in [".tmp",".recovery.tmp"]:last_error="Invalid save staging path.";return false
	if recovery_source==path+staging_suffix:staging_suffix=".recovery.tmp" if staging_suffix==".tmp" else ".tmp"
	if not valid(next):last_error="This progress could not be saved.";return false
	if not _preserve_migration_original():return false
	next=next.duplicate(true);next.sequence=int(data.sequence)+1
	if not valid(next):last_error="This progress could not be saved.";return false
	var file:=FileAccess.open(path+staging_suffix,FileAccess.WRITE)
	if file==null:last_error="Storage is unavailable. Progress is paused; please retry.";return false
	file.store_string(JSON.stringify(next));file.flush()
	var err:=file.get_error();file.close()
	if err!=OK:_discard_failed_write(staging_suffix);last_error="Your save could not be written.";return false
	if FileAccess.file_exists(path) and (valid(read_json(path)) or valid_legacy(read_json(path))):
		if DirAccess.copy_absolute(path,path+".bak")!=OK:_discard_failed_write(staging_suffix);last_error="Your backup could not be written.";return false
	elif FileAccess.file_exists(path) and not FileAccess.file_exists(path+".corrupt"):
		if DirAccess.copy_absolute(path,path+".corrupt")!=OK:_discard_failed_write(staging_suffix);last_error="Your original save could not be preserved.";return false
	if DirAccess.rename_absolute(path+staging_suffix,path)!=OK:_discard_failed_write(staging_suffix);last_error="Your save could not be replaced.";return false
	data=next;last_error="";migration_source="";recovery_source="";return true

func _discard_failed_write(staging_suffix:String) -> void:
	# A reported failure must not leave a rejected purchase pending on restart.
	# The selected recovery source uses the other filename and is never removed.
	var staged:=path+staging_suffix
	if staged!=recovery_source and FileAccess.file_exists(staged):DirAccess.remove_absolute(staged)

func level() -> int:return 1+int(sqrt(float(data.xp)/70.0))

func unlocked_chamber() -> int:
	return int(data.campaign_frontier)

func new_run() -> int:
	var n:=data.duplicate(true)
	var id:=int(n.next_run)
	n.next_run=id+1;n.active={}
	return id if commit(n) else 0

func store_run(run: Dictionary) -> bool:
	var n:=data.duplicate(true);n.active=run.duplicate(true)
	return commit(n)

func abandon() -> bool:
	var n:=data.duplicate(true);n.active={};return commit(n)

func settle(run: RefCounted, current_day: int) -> Dictionary:
	if not run.done or run.run_id<=int(data.last_paid_run) or run.run_id!=int(data.next_run)-1:return {}
	var n:=data.duplicate(true)
	var daily_bonus:bool=run.mode=="daily" and run.won and run.day==current_day and current_day>int(n.daily_paid)
	var pay:int=completion_coins(run,int(n.gear.salvage),daily_bonus)
	var earned_xp:int=run.crystals*3+(55 if run.won else 15)
	if run.used==0 and run.crystals==0:earned_xp=0
	if daily_bonus:
		earned_xp+=75;n.daily_paid=current_day
	if run.mode=="daily" and run.won:n.totals.daily_clears+=1
	n.coins+=pay;n.xp+=earned_xp;n.last_paid_run=run.run_id;n.active={}
	n.totals.rounds+=int(run.used>0);n.totals.clears+=int(run.won)
	n.totals.perfect+=int(run.won and run.remaining()==0)
	for key in ["crystals","ricochets"]:n.totals[key]+=run.get(key)
	n.records.best_score=maxi(int(n.records.best_score),run.score)
	n.records.best_combo=maxi(int(n.records.best_combo),run.best_combo)
	n.records.chains=maxi(int(n.records.chains),run.chains)
	if run.mode=="endless" and run.used>0:n.records.endless_depth=maxi(int(n.records.endless_depth),run.depth)
	if run.mode=="campaign" and run.won:
		while n.stars.size()<=run.chamber:n.stars.append(0)
		n.stars[run.chamber]=maxi(int(n.stars[run.chamber]),run.stars())
		while int(n.campaign_frontier)<Chambers.COUNT-1 and int(n.campaign_frontier)<n.stars.size() and int(n.stars[int(n.campaign_frontier)])>0:n.campaign_frontier+=1
	_roll_day(n,current_day)
	if int(n.quest_day)==current_day:
		n.quest.crystals+=run.crystals;n.quest.clears+=int(run.won);n.quest.ricochets+=run.ricochets
	var receipt: Dictionary={"coins":pay,"xp":earned_xp,"run_id":run.run_id}
	n.last_receipt=receipt
	return receipt if commit(n) else {}

static func legacy_completion_coins(run:RefCounted, salvage_rank:int, daily_bonus:bool) -> int:
	var amount:int=run.crystals*(2+clampi(salvage_rank,0,4))+int(run.score/80)+(35 if run.won else 8)
	if run.used==0 and run.crystals==0:amount=0
	return amount+(120 if daily_bonus else 0)

static func completion_coins(run:RefCounted, salvage_rank:int, daily_bonus:bool) -> int:
	var reference:=legacy_completion_coins(run,salvage_rank,daily_bonus)
	return mini(int(reference/4),int(reference*Upgrades.reward_numerator(salvage_rank)/4000))

static func _roll_day(n: Dictionary, day: int) -> void:
	if day>int(n.quest_day):n.quest_day=day;n.quest={"crystals":0,"clears":0,"ricochets":0};n.quest_claims=[]

func login(day: int) -> int:
	if day<=int(data.login_day):return 0
	var n:=data.duplicate(true)
	n.streak=(int(n.streak)%7+1) if day==int(n.login_day)+1 else 1
	n.login_day=day;n.records.login_streak=maxi(int(n.records.login_streak),int(n.streak))
	var amount:=login_reward(int(n.streak))
	n.coins+=amount;_roll_day(n,day)
	return amount if commit(n) else 0

func claim_quest(key: String, day: int) -> bool:
	var goals: Dictionary={"crystals":40,"clears":3,"ricochets":15}
	if not goals.has(key) or int(data.quest_day)!=day or data.quest_claims.has(key) or int(data.quest[key])<int(goals[key]):return false
	var n:=data.duplicate(true);n.quest_claims.append(key);n.coins+=QUEST_COINS;n.xp+=QUEST_XP
	return commit(n)

func upgrade(key: String) -> bool:
	if key not in Upgrades.KEYS:return false
	var rank:=int(data.gear[key]);var price:=Upgrades.price(key,rank)
	if rank>=Upgrades.cap(key) or price<=0 or data.coins<price:return false
	var n:=data.duplicate(true);n.coins-=price;n.gear[key]+=1;return commit(n)

func setting(key: String, value: Variant) -> bool:
	if key not in ["music","sfx","motion","vibration","skin"]:return false
	if key=="skin" and (not value is int or value<0 or value>mini(2,int((level()-1)/3))):return false
	var n:=data.duplicate(true);n[key]=value;return commit(n)

func metrics() -> Dictionary:
	var m: Dictionary=data.totals.duplicate(true)
	m.merge(data.records,true);m.xp=int(data.xp);m.level=level();m.campaign_clears=0;m.stars=0;m.upgrades=0
	for star in data.stars:m.stars+=int(star);m.campaign_clears+=int(int(star)>0)
	for rank in data.gear.values():m.upgrades+=int(rank)
	return m

func update_achievements(catalog: Dictionary) -> void:
	var n:=data.duplicate(true);var m:=metrics();var changed:=false
	for a in catalog.get("achievements",[]):
		if float(m.get(a.metric,0))>=float(a.threshold) and not n.achievements.get(a.key,false):n.achievements[a.key]=true;changed=true
	if changed:commit(n)
