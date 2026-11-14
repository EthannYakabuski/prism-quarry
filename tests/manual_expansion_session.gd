extends SceneTree
## A separately launched graphical QA fixture. Never included in player exports.
## Seeds only a fresh, explicitly named QA profile; subsequent input is manual.
const Profile = preload("res://game/profile.gd")
const Chambers = preload("res://game/chambers.gd")
var game: Node
var evidence_dir := ""
var last_state := ""
var captures: Array = []
var transitions: Array = []
var captured_keys: Dictionary = {}

func _initialize() -> void:
	call_deferred("open_session")

func open_session() -> void:
	var save_path := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--qa-profile=user://qa-expansion-manual-"):
			save_path = argument.trim_prefix("--qa-profile=")
	if save_path.is_empty() or not save_path.ends_with(".json") or "/" in save_path.trim_prefix("user://"):
		push_error("A fresh user://qa-expansion-manual-*.json profile is required.")
		quit(2)
		return
	var resume_fixture := FileAccess.file_exists(save_path) and Profile.valid(Profile.read_json(save_path))
	for suffix in ["", ".bak", ".tmp", ".migration-v1.bak"]:
		if FileAccess.file_exists(save_path + suffix):
			if resume_fixture:continue
			push_error("Refusing to overwrite an existing QA profile.")
			quit(2)
			return
	var profile := Profile.new(save_path)
	if not resume_fixture:
		var fixture: Dictionary = profile.data.duplicate(true)
		fixture.campaign_frontier = Chambers.COUNT - 1
		fixture.coins = 2500
		fixture.login_day = Profile.today()
		fixture.quest_day = Profile.today()
		if not profile.commit(fixture):
			push_error("Cannot prepare isolated manual fixture: " + profile.last_error)
			quit(2)
			return
	if not OS.has_feature("web"):
		root.size = Vector2i(540, 960)
		evidence_dir = "res://build/expansion-20261114/manual/" + save_path.get_file().get_basename()
		DirAccess.make_dir_recursive_absolute(evidence_dir)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	DisplayServer.window_set_title("Prism Quarry - isolated expansion QA")
	print("MANUAL QA FIXTURE: all chambers selectable, base gear, 2500 seeded ore; not earned progression.")
	print("MANUAL QA PROFILE: ", save_path)
	if not OS.has_feature("web"):process_frame.connect(observe_frame)

func observe_frame() -> void:
	if not is_instance_valid(game):return
	var state := str(game.get("screen"))
	var run: RefCounted = game.get("run")
	if run == null:return
	var key := "%d-%d-%s" % [run.run_id, run.depth, state]
	if key != last_state:
		last_state = key
		transitions.append({"ticks_msec":Time.get_ticks_msec(),"screen":state,"run_id":run.run_id,"chamber":run.chamber+1,"shots":run.shots,"crystals":run.stage_crystals,"score":run.score,"won":run.won})
		write_report()
	var view := ""
	if state in ["play", "clearing", "map", "workshop", "pause"]:view=state
	if state=="result":
		var elapsed := float(game.get("result_elapsed"))
		if elapsed>=0.10 and elapsed<0.20:view="popup-opening"
		elif elapsed>=float(game.RESULT_APPEAR_SECONDS):view="result"
	if view.is_empty():return
	key = "%03d-%d-%s" % [run.chamber+1,run.run_id,view]
	if captured_keys.has(key):return
	captured_keys[key]=true
	capture_frame.call_deferred(key, view)

func capture_frame(key:String, view:String) -> void:
	await RenderingServer.frame_post_draw
	var frame := root.get_texture().get_image()
	var filename := evidence_dir+"/"+key+".png"
	var error := frame.save_png(filename)
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(FileAccess.get_file_as_bytes(filename))
	captures.append({"path":filename,"view":view,"width":frame.get_width(),"height":frame.get_height(),"error":error,"sha256":context.finish().hex_encode(),"evidence":"Unmodified game viewport during actual pointer QA; initial profile is a disclosed fixture."})
	write_report()

func write_report() -> void:
	var file := FileAccess.open(evidence_dir+"/session.json",FileAccess.WRITE)
	if file==null:return
	file.store_string(JSON.stringify({"fixture":"Fresh isolated profile with all chambers selectable, base gear and 2500 seeded ore. Not earned progression or human balance acceptance.","transitions":transitions,"captures":captures},"\t"))
	file.close()
