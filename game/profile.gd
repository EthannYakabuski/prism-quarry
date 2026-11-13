extends RefCounted
const Run = preload("res://game/run.gd")
var path := "user://quarry-v1.json"
var data: Dictionary
var recovery := ""
var last_error := ""

func _init(save_path: String = "user://quarry-v1.json") -> void:
	path=save_path;data=defaults();load_profile()

static func defaults() -> Dictionary:
	return {"version":1,"sequence":0,"xp":0,"coins":0,"gear":{"drill":0,"echo":0,"salvage":0},"stars":[],"next_run":1,"last_paid_run":0,"active":{},"totals":{"rounds":0,"clears":0,"crystals":0,"ricochets":0,"perfect":0,"daily_clears":0},"records":{"best_score":0,"best_combo":0,"chains":0,"endless_depth":0,"login_streak":0},"login_day":-1,"streak":0,"quest_day":-1,"quest":{"crystals":0,"clears":0,"ricochets":0},"quest_claims":[],"daily_paid":-1,"achievements":{},"music":true,"sfx":true,"motion":true,"vibration":true,"skin":0,"last_receipt":{}}

static func today() -> int:return int(Time.get_unix_time_from_system()/86400.0)

static func valid(v: Variant) -> bool:
	if not v is Dictionary:return false
	for key in defaults():
		if not v.has(key):return false
	if v.version!=1:return false
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
		if not Run.valid_snapshot(v.active):return false
		if int(v.active.run_id)<=int(v.last_paid_run) or int(v.active.run_id)>=int(v.next_run):return false
	for key in ["drill","echo","salvage"]:
		if not Run.number(v.gear.get(key),0,4) or float(v.gear[key])!=floor(float(v.gear[key])):return false
	for section in ["totals","records","quest"]:
		for key in defaults()[section]:
			if not Run.number(v[section].get(key),0,1e12) or float(v[section][key])!=floor(float(v[section][key])):return false
	if not v.stars is Array or v.stars.size()>30 or not v.quest_claims is Array or v.quest_claims.size()>3:return false
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

static func read_json(filename: String) -> Variant:
	var parser:=JSON.new()
	return parser.data if parser.parse(FileAccess.get_file_as_string(filename))==OK else null

func load_profile() -> void:
	for candidate in [path,path+".bak"]:
		if not FileAccess.file_exists(candidate):continue
		var v: Variant=read_json(candidate)
		if valid(v):
			data=v
			if candidate.ends_with(".bak"):recovery="Recovered your last safe save."
			return
	if FileAccess.file_exists(path):recovery="Your save needs recovery. Original files are preserved; this session starts fresh."

func commit(next: Dictionary) -> bool:
	if not valid(next):last_error="This progress could not be saved.";return false
	next=next.duplicate(true);next.sequence=int(data.sequence)+1
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null:last_error="Storage is unavailable. Progress is paused; please retry.";return false
	file.store_string(JSON.stringify(next));file.flush()
	var err:=file.get_error();file.close()
	if err!=OK:last_error="Your save could not be written.";return false
	if FileAccess.file_exists(path) and valid(read_json(path)):
		if DirAccess.copy_absolute(path,path+".bak")!=OK:last_error="Your backup could not be written.";return false
	elif FileAccess.file_exists(path) and not FileAccess.file_exists(path+".corrupt"):
		if DirAccess.copy_absolute(path,path+".corrupt")!=OK:last_error="Your original save could not be preserved.";return false
	if DirAccess.rename_absolute(path+".tmp",path)!=OK:last_error="Your save could not be replaced.";return false
	data=next;last_error="";return true

func level() -> int:return 1+int(sqrt(float(data.xp)/70.0))

func unlocked_chamber() -> int:
	var index:=0
	for i in range(data.stars.size()):
		if int(data.stars[i])>0:index=maxi(index,i+1)
	return mini(index,29)

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
	var pay:int=run.crystals*(2+int(n.gear.salvage))+int(run.score/80)+(35 if run.won else 8)
	var earned_xp:int=run.crystals*3+(55 if run.won else 15)
	if run.used==0 and run.crystals==0:pay=0;earned_xp=0
	if run.mode=="daily" and run.won and run.day==current_day and current_day>int(n.daily_paid):
		pay+=120;earned_xp+=75;n.daily_paid=current_day
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
	_roll_day(n,current_day)
	if int(n.quest_day)==current_day:
		n.quest.crystals+=run.crystals;n.quest.clears+=int(run.won);n.quest.ricochets+=run.ricochets
	var receipt: Dictionary={"coins":pay,"xp":earned_xp,"run_id":run.run_id}
	n.last_receipt=receipt
	return receipt if commit(n) else {}

static func _roll_day(n: Dictionary, day: int) -> void:
	if day>int(n.quest_day):n.quest_day=day;n.quest={"crystals":0,"clears":0,"ricochets":0};n.quest_claims=[]

func login(day: int) -> int:
	if day<=int(data.login_day):return 0
	var n:=data.duplicate(true)
	n.streak=(int(n.streak)%7+1) if day==int(n.login_day)+1 else 1
	n.login_day=day;n.records.login_streak=maxi(int(n.records.login_streak),int(n.streak))
	var amount:=35+int(n.streak)*15
	n.coins+=amount;_roll_day(n,day)
	return amount if commit(n) else 0

func claim_quest(key: String, day: int) -> bool:
	var goals: Dictionary={"crystals":40,"clears":3,"ricochets":15}
	if not goals.has(key) or int(data.quest_day)!=day or data.quest_claims.has(key) or int(data.quest[key])<int(goals[key]):return false
	var n:=data.duplicate(true);n.quest_claims.append(key);n.coins+=90;n.xp+=40
	return commit(n)

func upgrade(key: String) -> bool:
	if not data.gear.has(key):return false
	var rank:=int(data.gear[key]);var price:=180+rank*240
	if rank>=4 or data.coins<price:return false
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
