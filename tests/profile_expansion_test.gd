extends SceneTree
## Isolated v1 migration, atomic recovery, workshop and matched-reward regressions.
const Profile=preload("res://game/profile.gd")
const Run=preload("res://game/run.gd")
const Chambers=preload("res://game/chambers.gd")
const Upgrades=preload("res://game/upgrades.gd")
var checks:=0
var failures:Array[String]=[]
var paths:Array[String]=[]
var prefix:=""
var fixtures:Array=[]

func _initialize() -> void:call_deferred("execute")
func check(ok:bool, message:String) -> void:
	checks+=1
	if not ok:failures.append(message);push_error(message)
func same(a:Variant,b:Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):return absf(float(a)-float(b))<0.000001
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not same(a[i],b[i]):return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not same(a[key],b[key]):return false
		return true
	return a==b
func case_path(name:String) -> String:
	var path:=prefix.trim_suffix(".json")+"-"+name+".json"
	assert(not FileAccess.file_exists(path),"Fixture refuses to overwrite an existing profile")
	paths.append(path);return path
func write_json(path:String,value:Variant) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	assert(file!=null);file.store_string(JSON.stringify(value));file.close()
func legacy_profile(cleared:int=0) -> Dictionary:
	var old:=Profile.defaults();old.version=1;old.erase("campaign_frontier")
	old.gear={"drill":4,"echo":2,"salvage":3};old.coins=12345;old.xp=6789;old.sequence=42
	old.next_run=8;old.last_paid_run=6;old.last_receipt={"coins":123,"xp":45,"run_id":6}
	old.login_day=20000;old.streak=4;old.quest_day=20000;old.daily_paid=19999
	old.quest={"crystals":44,"clears":2,"ricochets":17};old.quest_claims=["crystals"]
	old.achievements={"first_fracture":true,"master_miner":true}
	old.music=false;old.motion=false;old.skin=2
	old.stars=[]
	for i in range(cleared):old.stars.append(1+i%3)
	return old
func legacy_run(fixture:Dictionary, state:String="ready") -> Dictionary:
	var spec:Dictionary=fixture.spec
	var result:Dictionary={"run_id":7,"mode":"campaign","chamber":fixture.legacy_index,"seed_value":fixture.seed,"day":20000,"depth":1,"gear":{"drill":4,"echo":2,"salvage":3},"shots":spec.shots,"used":0,"score":0,"crystals":0,"stage_crystals":0,"best_combo":0,"chains":0,"ricochets":0,"shot_combo":0,"shot_time":0.0,"moving":false,"done":false,"won":false,"continued":false,"stage_ready":false,"ore":spec.ore.duplicate(true),"position":[0.0,10.35],"velocity":[0.0,0.0]}
	if state=="moving":
		result.moving=true;result.used=1;result.shots-=1;result.position=[0.0,8.0];result.velocity=[0.0,-12.0];result.shot_time=0.2
		result.ore[0].hp=0;result.crystals=1;result.stage_crystals=1;result.score=100;result.best_combo=1;result.shot_combo=1;result.chains=1
	if state in ["won","daily","endless"]:
		result.used=1;result.shots-=1;result.score=2000;result.crystals=result.ore.size();result.stage_crystals=result.crystals;result.best_combo=result.crystals;result.chains=result.crystals
		for ore in result.ore:ore.hp=0
		if state=="endless":result.mode="endless";result.depth=5;result.stage_ready=true
		else:result.done=true;result.won=true
		if state=="daily":result.mode="daily"
	if state in ["failed","continued"]:
		result.used=spec.shots;result.shots=0;result.done=true
		if state=="continued":result.done=false;result.continued=true;result.shots=2
	return result

func execute() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-profile=user://qa-"):prefix=arg.trim_prefix("--qa-profile=")
	if prefix.is_empty():push_error("Supply an isolated --qa-profile=user://qa-* argument");quit(2);return
	fixtures=Profile.read_json("res://tests/fixtures/campaign_legacy_v1.json").fixtures
	check(fixtures.size()==120,"120 frozen legacy chamber/seed fixtures available")
	for cleared in range(31):
		var old:=legacy_profile(cleared);var path:=case_path("frontier-%d"%cleared);write_json(path,old)
		var original:=FileAccess.get_sha256(path);var profile:=Profile.new(path)
		var expected:=50 if cleared==30 else cleared+int(cleared/10)*10
		check(profile.data.version==2 and Profile.valid(profile.data),"migrated valid v2 frontier %d"%cleared)
		check(profile.unlocked_chamber()==expected,"legacy contiguous frontier %d maps to %d"%[cleared,expected])
		var stars_ok:=true
		for i in range(Chambers.COUNT):
			var found:=0
			for j in range(cleared):
				if i==j+int(j/10)*10:found=1+j%3
			stars_ok=stars_ok and int(profile.data.stars[i])==found
		check(stars_ok,"all mapped stars and inserted gaps preserved %d"%cleared)
		for key in old:
			if key not in ["version","sequence","gear","stars"]:check(same(profile.data[key],old[key]),"migration retains %s frontier %d"%[key,cleared])
		check(profile.data.gear=={"drill":4,"echo":2,"salvage":3,"focus":0,"prism":0,"combo":0},"legacy ranks retained and new choices start at zero")
		check(FileAccess.get_sha256(path+".migration-v1.bak")==original,"original migration bytes preserved %d"%cleared)
		var sequence:int=profile.data.sequence;var again:=Profile.new(path)
		check(again.data.sequence==sequence and same(again.data,profile.data),"migration does not run twice %d"%cleared)
		profile.setting("music",true);profile.login(20001)
		check(FileAccess.get_sha256(path+".migration-v1.bak")==original,"later writes retain original migration backup")
	var holey:=legacy_profile(30);holey.stars[4]=0
	var migrated:=Profile.migrate_legacy(holey)
	check(migrated.campaign_frontier==4 and migrated.stars[49]>0,"sparse legacy stars do not invent contiguous unlocks")
	for fixture in fixtures:
		var old:=legacy_run(fixture,"moving");var converted:=Run.migrate_legacy_snapshot(old)
		check(not Run.valid_snapshot(old) and not converted.is_empty(),"legacy active requires deliberate conversion")
		check(converted.chamber==fixture.current_index and converted.seed_value==fixture.seed,"legacy chamber and seed map exactly")
		for key in old:
			if key not in ["chamber","gear"]:check(same(old[key],converted[key]),"active state retains "+key)
		var restored:=Run.restore(converted)
		for key in ["ore","bumpers","flight","shots","goal"]:check(same(restored.spec[key],fixture.spec[key]),"legacy geometry preserves "+key)
	for state in ["moving","won","daily","endless","failed","continued"]:
		var old:=legacy_profile(20);old.active=legacy_run(fixtures[0],state)
		var path:=case_path(state);write_json(path,old);var profile:=Profile.new(path)
		check(same(profile.data.active,Run.migrate_legacy_snapshot(old.active)),"disk migration preserves active "+state)
		var restored:=Run.restore(profile.data.active)
		if state=="continued":restored.done=true;check(not restored.continue_earned(),"migrated earned continuation cannot be granted twice")
		if state in ["won","daily"]:
			var receipt:=profile.settle(restored,20000);check(not receipt.is_empty(),"unpaid migrated win settles once")
			var coins:int=profile.data.coins;var paid:=Profile.new(path)
			check(paid.settle(restored,20000).is_empty() and paid.data.coins==coins,"paid migrated result cannot replay")
	var paid_old:=legacy_profile(30);paid_old.last_paid_run=7;paid_old.last_receipt.run_id=7
	var paid_path:=case_path("already-paid");write_json(paid_path,paid_old);var paid_profile:=Profile.new(paid_path)
	check(paid_profile.settle(Run.restore(Run.migrate_legacy_snapshot(legacy_run(fixtures[0],"won"))),20000).is_empty() and paid_profile.data.coins==paid_old.coins,"historical paid run ID remains consumed")
	var daily_old:=legacy_profile(30);daily_old.daily_paid=20000;daily_old.active=legacy_run(fixtures[0],"daily")
	var daily_path:=case_path("daily-already-paid");write_json(daily_path,daily_old);var daily_profile:=Profile.new(daily_path)
	var daily_run:=Run.restore(daily_profile.data.active);var daily_receipt:=daily_profile.settle(daily_run,20000)
	check(daily_receipt.coins==Profile.completion_coins(daily_run,3,false),"migrated daily entitlement does not award a second bonus")
	var daily_coins:int=daily_profile.data.coins
	check(not daily_profile.claim_quest("crystals",20000) and daily_profile.data.coins==daily_coins,"migrated claimed quest cannot pay twice")
	var next_run:=Run.new();next_run.start(paid_profile.new_run(),"campaign",50,paid_profile.data.gear,20000)
	for ore in next_run.ore:ore.hp=0
	next_run.used=1;next_run.done=true;next_run.won=true;next_run.crystals=next_run.ore.size();next_run.stage_crystals=next_run.crystals;next_run.score=2000
	check(not paid_profile.settle(next_run,20000).is_empty() and paid_profile.unlocked_chamber()==51,"all-legacy-complete frontier advances beyond50 without re-locking inserted gaps")
	check_recovery()
	var payout_rows:=check_economy()
	check_upgrades()
	var report:Dictionary={"checks":checks,"failures":failures,"legacy_frontiers_tested":31,"legacy_geometry_fixtures":fixtures.size(),"payout_cases":payout_rows.size(),"payout_examples":[payout_rows[0],payout_rows[-1]],"scope":"isolated synthetic migration/recovery and real model effect checks; no owner saves or backend actions"}
	DirAccess.make_dir_recursive_absolute("res://build/evidence")
	write_json("res://build/evidence/profile-expansion.json",report)
	write_json("res://build/evidence/economy-matched-payouts.json",payout_rows)
	for path in paths:
		for suffix in ["",".tmp",".recovery.tmp",".bak",".corrupt",".migration-v1.bak"]:
			if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
	print("PROFILE EXPANSION: %d checks; %d failures"%[checks,failures.size()])
	quit(0 if failures.is_empty() else 1)

func check_recovery() -> void:
	var path:=case_path("backup");var old:=legacy_profile(20)
	write_json(path,{"broken":true});write_json(path+".bak",old)
	var original:=FileAccess.get_sha256(path+".bak");var profile:=Profile.new(path)
	check(profile.unlocked_chamber()==40 and profile.data.coins==old.coins,"corrupt primary recovers and migrates v1 backup")
	check(FileAccess.get_sha256(path+".migration-v1.bak")==original and FileAccess.file_exists(path+".corrupt"),"recovery preserves actual legacy backup and corrupt primary")
	path=case_path("temporary");var base:=Profile.defaults();base.sequence=5;base.coins=100
	var pending:=base.duplicate(true);pending.sequence=6;pending.coins=200
	write_json(path,base);write_json(path+".tmp",pending);profile=Profile.new(path)
	check(profile.data.coins==200 and profile.data.sequence>6,"complete interrupted temporary write promoted")
	var reloaded:=Profile.new(path);check(reloaded.data.coins==200,"temporary recovery never applies currency twice")
	path=case_path("only-valid-temporary");write_json(path,{"broken":true});write_json(path+".tmp",pending)
	var temporary_hash:=FileAccess.get_sha256(path+".tmp");var broken_hash:=FileAccess.get_sha256(path)
	var blocked:=ProjectSettings.globalize_path(path+".recovery.tmp")
	check(DirAccess.make_dir_recursive_absolute(blocked)==OK,"blocked recovery staging fixture prepared")
	profile=Profile.new(path)
	check(not profile.last_error.is_empty() and FileAccess.get_sha256(path+".tmp")==temporary_hash and FileAccess.get_sha256(path)==broken_hash,"failed promotion preserves the only valid temporary source")
	check(not profile.commit(profile.data) and FileAccess.get_sha256(path+".tmp")==temporary_hash,"retry also protects the selected temporary source")
	check(DirAccess.remove_absolute(blocked)==OK,"isolated recovery staging obstruction removed")
	reloaded=Profile.new(path)
	check(reloaded.data.coins==200 and FileAccess.get_sha256(path+".corrupt")==broken_hash,"only valid temporary source recovers after storage returns")
	path=case_path("interrupted-recovery");write_json(path,{"broken":true});write_json(path+".recovery.tmp",pending)
	reloaded=Profile.new(path)
	check(reloaded.data.coins==200,"complete alternate recovery temporary write is recoverable")
	path=case_path("truncated");write_json(path,base);write_json(path+".tmp",{"partial":true});profile=Profile.new(path)
	check(profile.data.coins==100,"truncated temporary write cannot replace valid primary")
	path=case_path("equal-sequence");pending.sequence=base.sequence;write_json(path,base);write_json(path+".tmp",pending);profile=Profile.new(path)
	check(profile.data.coins==100,"valid primary wins an equal-sequence temporary tie")
	path=case_path("migration-interrupted");old=legacy_profile(10);pending=Profile.migrate_legacy(old);pending.sequence=43
	write_json(path,old);write_json(path+".tmp",pending);original=FileAccess.get_sha256(path);profile=Profile.new(path)
	check(profile.data.version==2 and profile.unlocked_chamber()==20 and FileAccess.get_sha256(path+".migration-v1.bak")==original,"interrupted migration preserves legacy primary before promoting v2")
	path=case_path("all-corrupt");write_json(path,{"version":1});original=FileAccess.get_sha256(path);profile=Profile.new(path)
	check(not profile.recovery.is_empty() and FileAccess.get_sha256(path)==original,"invalid save is retained for recovery")
	path=case_path("backup-blocked");old=legacy_profile(5);write_json(path,old);write_json(path+".migration-v1.bak",{"invalid":true});original=FileAccess.get_sha256(path);profile=Profile.new(path)
	check(not profile.last_error.is_empty() and not profile.commit(profile.data) and FileAccess.get_sha256(path)==original,"invalid permanent backup blocks replacement without data loss")
	var invalid:=Profile.defaults();invalid.gear.focus=13;check(not Profile.valid(invalid),"out-of-cap upgrade save rejected")
	invalid=Profile.defaults();invalid.campaign_frontier=200;check(not Profile.valid(invalid),"out-of-range frontier rejected")
	profile=Profile.new(case_path("unavailable-storage"));var funded:=profile.data.duplicate(true);funded.coins=1000;profile.commit(funded)
	var before:Dictionary=profile.data.duplicate(true)
	profile.path=prefix.trim_suffix(".json")+"-missing-directory/blocked.json"
	check(not profile.upgrade("focus") and same(profile.data,before),"unavailable storage cannot charge or grant an upgrade")
	path=case_path("late-backup-failure");profile=Profile.new(path);profile.commit(funded)
	blocked=ProjectSettings.globalize_path(path+".bak");check(DirAccess.make_dir_recursive_absolute(blocked)==OK,"late backup failure fixture prepared")
	check(not profile.upgrade("focus") and not FileAccess.file_exists(path+".tmp"),"failed backup removes rejected purchase staging")
	reloaded=Profile.new(path);check(reloaded.data.coins==funded.coins and reloaded.data.gear.focus==0,"rejected purchase cannot apply on restart")
	check(DirAccess.remove_absolute(blocked)==OK,"late backup obstruction removed")
	path=case_path("late-rename-failure");blocked=ProjectSettings.globalize_path(path)
	check(DirAccess.make_dir_recursive_absolute(blocked)==OK,"late rename failure fixture prepared")
	profile.path=path;before=profile.data.duplicate(true)
	check(not profile.upgrade("focus") and same(profile.data,before) and not FileAccess.file_exists(path+".tmp"),"failed rename discards rejected transaction and retains memory")
	check(DirAccess.remove_absolute(blocked)==OK,"late rename obstruction removed")

func check_economy() -> Array:
	var rows:Array=[];var run:=Run.new();run.start(1,"campaign",0,Upgrades.normalize({}),20000)
	for crystals in [0,1,9,40,60]:
		for score in [0,1800,10000,250000]:
			for won in [false,true]:
				for daily in [false,true]:
					for rank in range(13):
						for used in [0,1]:
							run.crystals=crystals;run.score=score;run.won=won;run.used=used
							var old:int=crystals*(2+mini(rank,4))+int(score/80)+(35 if won else 8)
							if used==0 and crystals==0:old=0
							if daily:old+=120
							var amount:=Profile.completion_coins(run,rank,daily)
							check(amount>=0 and amount<=int(old/4),"completion and daily total stay below quarter of old matched payout")
							check(amount==int(old*(800+25*maxi(rank-4,0))/4000),"payout follows documented integer retained fraction")
							rows.append({"crystals":crystals,"score":score,"won":won,"daily":daily,"salvage_rank":rank,"used":used,"legacy":old,"new":amount,"quarter_cap":int(old/4)})
	check(Profile.login_reward(1)==10 and Profile.login_reward(7)==28,"login gifts scale with slower economy")
	check(Profile.QUEST_COINS==18 and Profile.QUEST_XP==40,"quest ore scaled while XP retained")
	return rows

func check_upgrades() -> void:
	var profile:=Profile.new(case_path("workshop"));var funded:=profile.data.duplicate(true);funded.coins=100000;profile.commit(funded)
	for key in Upgrades.KEYS:
		for rank in range(Upgrades.cap(key)):
			var before:int=profile.data.coins;var price:=Upgrades.price(key,rank)
			check(profile.upgrade(key) and profile.data.gear[key]==rank+1 and profile.data.coins==before-price,"purchase spends exact next-tier price for "+key)
		check(not profile.upgrade(key) and Upgrades.price(key,12)==0,"cap prevents extra purchase for "+key)
	for rank in range(5):
		check(is_equal_approx(Upgrades.flight_bonus(rank),rank*0.15) and is_equal_approx(Upgrades.echo_radius(rank),1.08+rank*0.06),"legacy drill and echo effects preserved")
	check(is_equal_approx(Upgrades.hit_radius(12),0.62) and is_equal_approx(Upgrades.prism_radius(12),2.64) and is_equal_approx(Upgrades.combo_multiplier(12),1.12),"new choices have bounded distinct maximum effects")
	var maximum:Dictionary={}
	for key in Upgrades.KEYS:maximum[key]=12
	var run:=Run.new();run.start(1,"campaign",0,maximum,20000)
	check(Run.valid_snapshot(run.snapshot()) and run.preview(Vector2.UP).size()>1,"maximum six-choice rig previews and saves")
	run.launch(Vector2.UP)
	for i in range(600):
		if not run.moving:break
		run.step(1.0/60.0)
	check(not run.moving and Run.valid_snapshot(run.snapshot()),"maximum effects finish within valid deterministic model bounds")
	var baseline:=Run.new();baseline.start(2,"campaign",0,{},20000);baseline._fracture(0)
	var scored:=Run.new();scored.start(2,"campaign",0,{"combo":12},20000);scored._fracture(0)
	check(scored.crystals==baseline.crystals and scored.score>baseline.score,"combo choice changes score without inventing crystals")
	var focused:=Run.new();focused.start(3,"campaign",0,{"focus":12},20000)
	baseline=Run.new();baseline.start(3,"campaign",0,{},20000)
	for candidate in [baseline,focused]:
		candidate.moving=true;candidate.used=1;candidate.shots-=1
		candidate.position=Vector2(candidate.ore[0].x-0.56,candidate.ore[0].y+0.1);candidate.velocity=Vector2.UP*Run.SPEED;candidate.step(0.001)
	check(baseline.crystals==0 and focused.crystals>0,"focus changes real near-miss crystal contact")
	for key in ["echo","prism"]:
		var source_kind:=3 if key=="prism" else 0;var distance:=2.5 if key=="prism" else 1.45
		var base_link:=Run.new();base_link.start(4,"campaign",0,{},20000)
		var wide_link:=Run.new();wide_link.start(4,"campaign",0,{key:12},20000)
		for candidate in [base_link,wide_link]:
			candidate.ore=[{"x":0.0,"y":2.0,"kind":source_kind,"hp":1},{"x":distance,"y":2.0,"kind":0,"hp":1}];candidate._fracture(0)
		check(base_link.crystals==1 and wide_link.crystals==2,"maximum "+key+" reaches a crystal outside baseline linkage")
	var longburn:=Run.new();longburn.start(5,"campaign",0,{"drill":12},20000)
	baseline=Run.new();baseline.start(5,"campaign",0,{},20000)
	for candidate in [baseline,longburn]:
		candidate.moving=true;candidate.used=1;candidate.shots-=1;candidate.shot_time=candidate.spec.flight+0.1
		candidate.position=Vector2(3,8);candidate.velocity=Vector2.UP*Run.SPEED;candidate.step(0.001)
	check(not baseline.moving and longburn.moving,"longburn delays actual timed recall")
