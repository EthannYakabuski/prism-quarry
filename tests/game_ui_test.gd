extends SceneTree
## Bounded application/UI regression suite. Pointer events use the real Viewport
## dispatch path. Reward/foreground/storage cases are explicitly synthetic
## fixtures and are not evidence of Android SDK callbacks or physical touch.
const Profile=preload("res://game/profile.gd")
const Run=preload("res://game/run.gd")
var game:Node3D
var checks:Array=[]
var failures:Array[String]=[]
var save_path:=""
var pointer_evidence:Dictionary={}
var created_paths:Array[String]=[]

func _initialize() -> void:
	call_deferred("execute")

func check(value:bool, message:String) -> void:
	checks.append({"check":message,"pass":value})
	if not value:
		failures.append(message)
		push_error(message)

func same_json_state(a:Variant,b:Variant) -> bool:
	# JSON converts integral values to floats and rounds decimal text. Accept
	# only that representation change; model coordinates must stay within 1e-6.
	if (a is int or a is float) and (b is int or b is float):return absf(float(a)-float(b))<=0.000001
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not same_json_state(a[i],b[i]):return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not same_json_state(a[key],b[key]):return false
		return true
	return a==b

func find_button(node:Node, text:String) -> Button:
	if node is Button and node.text==text:return node
	for child in node.get_children():
		var found:=find_button(child,text)
		if found:return found
	return null

func press(text:String) -> bool:
	var b:=find_button(game.ui,text)
	if b==null or b.disabled:
		check(false,"UI button available: "+text)
		return false
	b.pressed.emit()
	return true

func all_buttons(node:Node) -> Array[Button]:
	var found:Array[Button]=[]
	if node is Button:found.append(node)
	for child in node.get_children():found.append_array(all_buttons(child))
	return found

func wait_layout() -> void:
	await process_frame
	await process_frame

func load_game() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	await wait_layout()

func pointer(pos:Vector2, down:bool) -> void:
	var event:=InputEventMouseButton.new()
	event.button_index=MOUSE_BUTTON_LEFT
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
	event.position=pos;event.global_position=pos;event.pressed=down
	root.push_input(event,true)

func finish_flight() -> void:
	for frame in range(700):
		if not game.run.moving:break
		game._process(1.0/60.0)
	check(not game.run.moving,"flight completes within bounded simulation")

func fail_fixture() -> void:
	game.start_run("campaign",0)
	for i in range(3):
		game.run.launch(Vector2.UP)
		game.run.recall()
	game._checkpoint();game._result()
	check(game.run.done and not game.run.won and game.screen=="result","failed-round fixture established")

func execute() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-profile=user://qa-ui-"):save_path=arg.trim_prefix("--qa-profile=")
	if save_path.is_empty():
		push_error("Supply -- --qa-profile=user://qa-ui-<unique>.json; refusing owner profile")
		quit(2);return
	if FileAccess.file_exists(save_path):
		push_error("UI test requires a fresh unique qa-ui profile")
		quit(2);return
	created_paths.append(save_path)
	root.size=Vector2i(540,960)
	await load_game()
	check(game.profile.path==save_path,"isolated QA profile selected")
	check(game.screen=="home","first launch home")
	check(game.profile.data.coins==50,"one first-day gift in isolated profile")
	var home_buttons:=all_buttons(game.ui)
	check(home_buttons.size()==7,"home has seven primary navigation buttons")
	var viewport:=Rect2(Vector2.ZERO,game.ui.size)
	for b in home_buttons:
		check(viewport.encloses(b.get_global_rect()),"home button fits viewport: "+b.text)
		check(b.size.y>=42,"home touch height: "+b.text)
	for route in [["Chambers","map"],["Workshop","workshop"],["Daily","daily"],["Journal","journal"],["Settings","settings"]]:
		press(route[0]);await wait_layout()
		check(game.screen==route[1],"navigation opens "+route[1])
		check(find_button(game.ui,"‹ Back")!=null or find_button(game.ui,"< Back")!=null,"page exposes Back: "+route[1])
		game._back();await wait_layout()
		check(game.screen=="home","Back returns home from "+route[1])

	game.start_run("campaign",0);await wait_layout()
	check(game.screen=="play" and game.run.used==0,"fresh chamber is ready")
	check(game.hud_score.size.x>=130 and game.hud_score.get_line_count()==1,"score HUD remains a single line")
	var at:Vector2=game.cavern.board_to_screen(Vector2(0,2.5))
	pointer_evidence={"method":"Viewport.push_input(InputEventMouseButton)","pointer_position":[at.x,at.y],"viewport":[root.size.x,root.size.y],"physical_input":false}
	check(at.y>190 and at.y<game.ui.size.y-190,"first seam lies in interactive cave region")
	pointer(at,true)
	check(game.dragging,"pointer press enters aim state through event dispatch")
	check(game.run.used==0,"aim press does not spend a shot")
	pointer(at,false)
	check(game.run.used==1 and game.run.moving,"pointer release launches one drill through event dispatch")
	check(not game.dragging,"release clears drag state")
	game._process(0.1)
	check(game.run.position!=Run.ORIGIN,"launched drill advances")
	game._pause()
	var paused:Dictionary=game.run.snapshot()
	game._process(0.1)
	check(game.screen=="pause" and game.run.snapshot()==paused,"pause freezes complete model snapshot")
	game._back();game._process(0.1)
	check(game.screen=="pause" and game.run.snapshot()==paused,"Back while paused never resumes physics")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.music.stream_paused and not game.app_focused,"focus loss pauses music")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(game.screen=="pause" and game.run.snapshot()==paused,"foreground return remains paused")
	check(not game.music.stream_paused,"foreground restores enabled music")
	press("Resume drilling")
	check(game.screen=="play","explicit Resume returns to play")
	finish_flight()
	check(game.screen=="result" and game.run.won,"input-launched first seam reaches results")
	check(game.run.crystals==9 and game.run.stars()==3,"input-launched seam fractures nine crystals for three stars")
	var coins:int=game.profile.data.coins
	var xp:int=game.profile.data.xp
	var rounds:int=game.profile.data.totals.rounds
	game._result();game._result()
	check(game.profile.data.coins==coins and game.profile.data.xp==xp and game.profile.data.totals.rounds==rounds,"repeated result presentation pays once")
	check(game.profile.data.active.is_empty(),"paid result clears active snapshot")
	var cold:=Profile.new(save_path)
	check(cold.data.coins==coins and cold.data.stars[0]==3,"cold profile retains paid three-star result")
	game.if_settled_home();await wait_layout()
	check(game.screen=="home","bank result returns home")

	game.start_run("campaign",0)
	coins=game.profile.data.coins;xp=game.profile.data.xp;rounds=game.profile.data.totals.rounds
	game._pause();game._leave_prompt();press("Bank & return home")
	check(game.screen=="home","zero-activity leave returns home")
	check(game.profile.data.coins==coins and game.profile.data.xp==xp and game.profile.data.totals.rounds==rounds,"zero-activity bank grants no payout or completed round")

	fail_fixture()
	var failed:Dictionary=game.run.snapshot()
	game.reward_waiting=true;game._reward_finished(false)
	check(game.run.snapshot()==failed and not game.reward_waiting,"no-earned callback grants nothing")
	game.reward_waiting=true;game._reward_finished(true)
	check(game.screen=="pause" and game.run.continued and game.run.shots==2 and not game.run.done,"earned fixture adds two shots and requires Resume")
	var continued:Dictionary=game.run.snapshot()
	game._reward_finished(true)
	check(game.run.snapshot()==continued,"repeated earned callback cannot grant again")
	cold=Profile.new(save_path)
	check(cold.data.active.continued and cold.data.active.shots==2,"earned continuation persists before play")
	press("Resume drilling");check(game.screen=="play","earned continuation explicit Resume")

	fail_fixture()
	var real_path:String=game.profile.path
	game.profile.path="user://qa-ui-missing-%d/blocked.json"%Time.get_ticks_usec()
	game.reward_waiting=true;game._reward_finished(true)
	check(game.screen=="pause" and game.run.continued and game.run.shots==2,"storage failure retains earned entitlement paused in memory")
	continued=game.run.snapshot()
	press("Resume drilling")
	check(game.screen=="pause" and game.run.snapshot()==continued,"failed save retry does not resume earned shot")
	game.profile.path=real_path
	press("Resume drilling")
	check(game.screen=="play" and game.profile.data.active.continued and game.profile.data.active.shots==2,"storage recovery saves same earned entitlement exactly once")

	game.start_run("endless",0)
	game.run.launch(Vector2.UP);finish_flight()
	check(game.run.stage_ready and game.screen=="depth","endless completion opens descent choice")
	game._pause();press("Resume drilling")
	check(game.screen=="depth","paused stage-ready run resumes to descent choice")
	var prior_depth:int=game.run.depth
	real_path=game.profile.path;game.profile.path="user://qa-ui-missing-%d/blocked.json"%Time.get_ticks_usec()
	game._descend()
	check(game.run.depth==prior_depth and game.screen=="depth","failed descent save preserves prior seam")
	game.profile.path=real_path;game._descend()
	check(game.run.depth==prior_depth+1 and game.screen=="play","saved descent enters next depth")

	game.start_run("campaign",0)
	game.run.launch(Vector2.UP)
	for i in range(700):
		if not game.run.moving:break
		game.run.step(1.0/60.0)
	check(game.run.done and game.run.won,"completed unpaid result fixture")
	real_path=game.profile.path;game.profile.path="user://qa-ui-missing-%d/blocked.json"%Time.get_ticks_usec()
	game._result()
	check(game.screen=="pause","result save failure stays paused")
	game.profile.path=real_path;press("Resume drilling")
	check(game.screen=="result" and game.profile.data.active.is_empty(),"done-state Resume retries save and opens result")

	# Simulate a process left open across a day boundary by moving only its
	# isolated stored day backward. The system clock is never changed.
	game.start_run("campaign",0);game._pause()
	var next:Dictionary=game.profile.data.duplicate(true)
	next.login_day=Profile.today()-1;next.quest_day=Profile.today()-1;next.streak=2
	next.quest={"crystals":12,"clears":1,"ricochets":4};next.quest_claims=["clears"]
	check(game.profile.commit(next),"day rollover fixture committed")
	coins=game.profile.data.coins
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(game.profile.data.streak==3 and game.profile.data.coins==coins+80,"foreground refresh awards one next-day gift")
	check(game.profile.data.quest_day==Profile.today() and game.profile.data.quest.crystals==0 and game.profile.data.quest_claims.is_empty(),"foreground refresh resets daily goals")
	check(game.screen=="pause","day refresh does not resume gameplay")
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(game.profile.data.coins==coins+80,"repeated foreground does not duplicate daily gift")
	game.profile.setting("music",false);game._audio_state()
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT);game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(game.music.stream_paused,"music Off survives foreground lifecycle")
	game.profile.setting("music",true);game._audio_state()
	game._fullscreen_pending("fixture")
	check(game.screen=="pause" and game.fullscreen,"fullscreen pending freezes application")
	game._fullscreen_changed(true);check(game.music.stream_paused,"fullscreen presentation pauses audio")
	game._fullscreen_changed(false)
	check(game.screen=="pause" and not game.fullscreen,"fullscreen dismissal still requires explicit Resume")

	# Cold restored shot returns to a pause screen; no automatic physics tick.
	game.start_run("campaign",0);game.run.launch(Vector2.UP);game.run.step(0.1);game._checkpoint()
	var active_before:Dictionary=game.run.snapshot()
	game.queue_free();await process_frame;await process_frame
	await load_game()
	check(game.screen=="pause" and same_json_state(game.run.snapshot(),active_before),"cold scene restoration preserves moving shot and requires Resume")
	var restored_before:Dictionary=game.run.snapshot()
	game._process(0.1)
	check(game.run.snapshot()==restored_before,"cold restored shot remains stationary until explicit Resume")
	press("Resume drilling");game._process(0.1)
	check(game.screen=="play" and game.run.position!=Vector2(active_before.position[0],active_before.position[1]),"cold restored shot advances after Resume")

	var semantics_path:String=save_path.trim_suffix(".json")+"-semantics.json"
	created_paths.append(semantics_path)
	var semantics:=Profile.new(semantics_path)
	var yesterday:=Profile.today()-1
	var old_daily:=Run.new();old_daily.start(semantics.new_run(),"daily",0,{"drill":0,"echo":0,"salvage":0},yesterday)
	old_daily.used=1;old_daily.done=true;old_daily.won=true;old_daily.stage_crystals=old_daily.spec.goal;old_daily.crystals=old_daily.spec.goal
	check(not semantics.settle(old_daily,Profile.today()).is_empty(),"across-midnight daily completion settles")
	check(semantics.data.totals.daily_clears==1 and semantics.data.daily_paid==-1,"across-midnight daily counts clear without current-day bonus")
	var deep:=Run.new();deep.start(semantics.new_run(),"endless",0,{"drill":0,"echo":0,"salvage":0},Profile.today())
	deep.depth=5;deep.used=1;deep.done=true;deep.won=false
	semantics.settle(deep,Profile.today())
	check(semantics.metrics().endless_depth==5,"failed deep run records deepest reached")
	var stale:=Run.new();stale.start(semantics.new_run(),"campaign",0,{"drill":0,"echo":0,"salvage":0},Profile.today());stale.done=true;stale.used=1
	var current:=Run.new();current.start(semantics.new_run(),"campaign",1,{"drill":0,"echo":0,"salvage":0},Profile.today());semantics.store_run(current.snapshot())
	var before_stale:Dictionary=semantics.data.duplicate(true)
	check(semantics.settle(stale,Profile.today()).is_empty() and semantics.data==before_stale,"stale older run cannot settle over current active run")

	var final_report:Dictionary={"checks":checks.size(),"failures":failures,"assertions":checks,"pointer_evidence":pointer_evidence,"evidence_kind":"headless UI/input dispatch and synthetic lifecycle/reward/storage fixtures; not native SDK or physical-device acceptance"}
	DirAccess.make_dir_recursive_absolute("res://build/evidence")
	var report:=FileAccess.open("res://build/evidence/game-ui.json",FileAccess.WRITE)
	report.store_string(JSON.stringify(final_report,"\t"));report.close()
	game.queue_free();await process_frame;await process_frame
	game=null;cold=null;semantics=null;old_daily=null;deep=null;stale=null;current=null
	for path in created_paths:
		for suffix in ["",".bak",".tmp",".corrupt"]:
			if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(path+suffix)
	print("GAME UI: ",checks.size()," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
