extends SceneTree
const Run=preload("res://game/run.gd")
const Profile=preload("res://game/profile.gd")
const Chambers=preload("res://game/chambers.gd")
var checks:=0
var failures: Array[String]=[]
func check(value: bool, message: String) -> void:
	checks+=1
	if not value:failures.append(message);push_error(message)
func _initialize() -> void:call_deferred("execute")
func finish_shot(r: RefCounted) -> void:
	for i in range(800):
		if not r.moving:break
		r.step(1.0/60.0)
func solve(r: RefCounted) -> Array:
	var angles:Array=[]
	for shot in range(4):
		if r.done:break
		var best:RefCounted=null;var best_angle:=0
		for angle in range(-70,71,3):
			var candidate:RefCounted=Run.restore(r.snapshot())
			candidate.launch(Vector2(sin(deg_to_rad(angle)),-cos(deg_to_rad(angle))))
			finish_shot(candidate)
			if best==null or candidate.score>best.score:best=candidate;best_angle=angle
		angles.append(best_angle)
		var snap:Dictionary=best.snapshot()
		for key in snap:
			if key not in ["position","velocity"]:r.set(key,snap[key])
		r.position=best.position;r.velocity=best.velocity
	return angles
func execute() -> void:
	var solutions:Array=[];var straight_wins:=0;var fixed_sweep_wins:=0
	for i in range(30):
		var r:=Run.new();r.start(i+1,"campaign",i,{"drill":0,"echo":0,"salvage":0},20000)
		check(Run.valid_snapshot(r.snapshot()),"valid initial chamber %d"%i)
		var direct:=Run.restore(r.snapshot());direct.launch(Vector2.UP);finish_shot(direct);straight_wins+=int(direct.won)
		var fixed:RefCounted=Run.restore(r.snapshot())
		for shot in range(int(fixed.spec.shots)):
			if fixed.done:break
			fixed.launch(Vector2(sin(deg_to_rad(-70)),-cos(deg_to_rad(-70))));finish_shot(fixed)
		fixed_sweep_wins+=int(fixed.won)
		var angles:=solve(r)
		check(r.won,"baseline without upgrades chamber %d"%i)
		check(r.used<=int(r.spec.shots),"shot budget %d"%i)
		check(r.stars()==3,"all ore reachable chamber %d"%i)
		check(Run.valid_snapshot(r.snapshot()),"valid complete chamber %d"%i)
		solutions.append({"chamber":i+1,"angles_degrees":angles,"stars":r.stars(),"score":r.score,"shots":r.used,"crystals":r.crystals,"straight_first_shot_wins":direct.won,"fixed_sweep_wins":fixed.won})
	check(straight_wins<25,"varied aim: most chambers are not a straight-only win")
	check(fixed_sweep_wins<20,"fixed sweep cannot clear most chapters")
	var r:=Run.new();r.start(1,"campaign",0,{"drill":0,"echo":0,"salvage":0},20000)
	check(not r.launch(Vector2.ZERO),"reject zero direction")
	check(r.launch(Vector2.UP),"launch accepted")
	check(not r.launch(Vector2.UP),"single drill enforced")
	r.step(0.2);check(r.shot_time<=0.101,"large frame bounded")
	var resumed:RefCounted=Run.restore(r.snapshot());r.step(0.02);resumed.step(0.02)
	check(r.snapshot()==resumed.snapshot(),"shot snapshot deterministic resume")
	finish_shot(r);check(r.chains==9 and r.won and r.stars()==3,"first seam cascade and perfect stars")
	check(not r.continue_earned(),"successful round rejects continue")
	var fail:=Run.new();fail.start(2,"campaign",0,{"drill":0,"echo":0,"salvage":0},20000)
	for j in range(3):fail.launch(Vector2(1,-0.1));fail.recall()
	check(fail.done and not fail.won,"empty shots fail")
	check(fail.continue_earned() and fail.shots==2 and not fail.done,"earned continuation")
	fail.done=true;check(not fail.continue_earned(),"continue exactly once")
	var daily1:=Run.new();daily1.start(3,"daily",0,{"drill":0,"echo":0,"salvage":0},20001)
	var daily2:=Run.new();daily2.start(3,"daily",12,{"drill":0,"echo":0,"salvage":0},20001)
	check(daily1.ore==daily2.ore,"daily seeded deterministically")
	var endless:=Run.new();endless.start(4,"endless",0,{"drill":0,"echo":0,"salvage":0},20001);endless.launch(Vector2.UP);finish_shot(endless)
	check(endless.stage_ready and not endless.done,"endless next seam")
	check(endless.next_depth() and endless.depth==2 and endless.crystals==9,"endless preserves haul")
	var save_path:="user://qa-model-%d.json"%Time.get_ticks_usec()
	var p:=Profile.new(save_path)
	check(Profile.valid(p.data),"profile defaults valid")
	check(p.login(20000)==50,"first login gift")
	var coins:int=p.data.coins
	check(p.login(20000)==0 and p.login(19999)==0 and p.data.coins==coins,"login replay/clock rollback")
	for day in range(20001,20007):p.login(day)
	check(p.data.streak==7 and p.metrics().login_streak==7,"seven day streak")
	p.login(20007);check(p.data.streak==1 and p.metrics().login_streak==7,"seven day cycle best retained")
	var id:=p.new_run();r.run_id=id
	check(p.store_run(r.snapshot()),"store completed unpaid run")
	check(not p.settle(r,20007).is_empty(),"settle first payout")
	coins=p.data.coins;var xp:int=p.data.xp
	check(p.settle(r,20007).is_empty() and p.data.coins==coins and p.data.xp==xp,"repeat settlement idempotent")
	var reload:=Profile.new(save_path)
	check(reload.data.coins==coins and reload.data.active.is_empty(),"cold load paid result")
	var n:Dictionary=p.data.duplicate(true);n.coins=20000;n.quest={"crystals":40,"clears":3,"ricochets":15};p.commit(n)
	check(p.claim_quest("crystals",20007),"quest claim")
	coins=p.data.coins
	check(not p.claim_quest("crystals",20007) and not p.claim_quest("clears",20006) and p.data.coins==coins,"quest repeated/rollback claim")
	check(p.upgrade("echo") and p.data.gear.echo==1,"real upgrade")
	check(not p.upgrade("unknown"),"unknown upgrade rejected")
	var stale_id:=p.new_run()
	var current_id:=p.new_run()
	var current:=Run.new();current.start(current_id,"campaign",2,{"drill":0,"echo":0,"salvage":0},20007)
	p.store_run(current.snapshot())
	var stale:RefCounted=Run.restore(r.snapshot());stale.run_id=stale_id
	coins=p.data.coins
	check(p.settle(stale,20007).is_empty() and p.data.active.run_id==current_id and p.data.coins==coins,"stale result cannot erase current round")
	var nextday:=Run.new();nextday.start(p.new_run(),"daily",0,{"drill":0,"echo":0,"salvage":0},20007)
	solve(nextday)
	check(nextday.won,"overnight daily fixture wins")
	p.settle(nextday,20008)
	check(p.data.totals.daily_clears==1 and p.data.daily_paid==-1,"overnight daily gets achievement but no wrong-day bonus")
	var deep:=Run.new();deep.start(p.new_run(),"endless",0,{"drill":0,"echo":0,"salvage":0},20008);deep.depth=5
	for j in range(3):deep.launch(Vector2.UP);deep.recall()
	p.settle(deep,20008)
	check(p.metrics().endless_depth==5,"deepest reached survives failure")
	var invalid_run:Dictionary=r.snapshot();invalid_run.position=[100,100]
	check(not Run.valid_snapshot(invalid_run),"out-of-board snapshot rejected")
	invalid_run=r.snapshot();invalid_run.ore[0].hp=0.5
	check(not Run.valid_snapshot(invalid_run),"fractional crystal health rejected")
	var invalid:Dictionary=p.data.duplicate(true);invalid.xp=-1;check(not p.commit(invalid),"invalid negative save rejected")
	invalid=p.data.duplicate(true);invalid.gear.drill=99;check(not Profile.valid(invalid),"invalid gear rejected")
	invalid=p.data.duplicate(true);invalid.stars=[4];check(not Profile.valid(invalid),"invalid stars rejected")
	var f:=FileAccess.open(save_path,FileAccess.WRITE);f.store_string("corrupt");f.close()
	var recovered:=Profile.new(save_path);check(not recovered.recovery.is_empty() and recovered.data.sequence>0,"corrupt primary backup recovery")
	var blocked:=Profile.new("user://qa-missing-dir/save.json");check(blocked.new_run()==0 and blocked.data.next_run==1,"storage failure rolls back")
	for suffix in ["",".bak",".tmp",".corrupt"]:
		if FileAccess.file_exists(save_path+suffix):DirAccess.remove_absolute(save_path+suffix)
	DirAccess.make_dir_recursive_absolute("res://build/evidence")
	var report:=FileAccess.open("res://build/evidence/game-model.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"checks":checks,"failures":failures,"straight_first_shot_wins":straight_wins,"fixed_sweep_wins":fixed_sweep_wins,"solutions":solutions,"evidence_kind":"deterministic model fixtures, not human playtesting"},"\t"));report.close()
	print("GAME MODEL: ",checks," checks; ",failures.size()," failures; ",straight_wins," straight wins")
	quit(0 if failures.is_empty() else 1)
