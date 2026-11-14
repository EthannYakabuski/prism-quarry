extends SceneTree
## Actual rendered application captures. Later chamber selection is a fixture;
## images remain unmodified viewport pixels, never illustration composites.
var game:Node3D
var directory:="res://build/visual"
var quick:=false
var profile_name:="diagnostic"
var captures:Array=[]
const BIOME_VIEWS := [
	{"view":"gameplay","chamber":4},{"view":"azure","chamber":21},
	{"view":"violet","chamber":43},{"view":"copper","chamber":64},
	{"view":"jade","chamber":84},{"view":"frostglass","chamber":104},
	{"view":"ember","chamber":124},{"view":"moonstone","chamber":144},
	{"view":"obsidian","chamber":164},{"view":"prismatic","chamber":184}
]
func _initialize() -> void:call_deferred("capture")
func shot(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	var error:=image.save_png(directory+"/"+name+".png")
	var bytes:=FileAccess.get_file_as_bytes(directory+"/"+name+".png")
	var hash:=HashingContext.new();hash.start(HashingContext.HASH_SHA256);hash.update(bytes)
	captures.append({"path":profile_name+"/"+name+".png","profile":profile_name,"width":image.get_width(),"height":image.get_height(),"description":name.capitalize()+" screen from the implemented game","method":"Automated rendered Godot viewport; direct chamber selection fixture for environment views; results computed by actual Run.step","device_class":"desktop viewport, not physical device or Android emulator","sha256":hash.finish().hex_encode(),"source_commit":"working tree; capture-source.json hashes identify runtime files","view":name})
	print("CAPTURE ",name," ",image.get_width(),"x",image.get_height()," error=",error)
func capture() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):directory=arg.trim_prefix("--capture-dir=")
		if arg.begins_with("--capture-profile="):profile_name=arg.trim_prefix("--capture-profile=")
		if arg.begins_with("--capture-size="):
			var parts:=arg.trim_prefix("--capture-size=").split("x")
			root.size=Vector2i(int(parts[0]),int(parts[1]))
		if arg=="--quick":quick=true
	DirAccess.make_dir_recursive_absolute(directory)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
	await process_frame
	game.home();await shot("home")
	game.show_map(0);await shot("map")
	for view in BIOME_VIEWS:
		game.start_run("campaign",int(view.chamber))
		if view.view=="gameplay":game.aim=Vector2(-0.55,-1).normalized();game.cavern.show_preview(game.run.preview(game.aim))
		await shot(str(view.view))
		if quick:game.queue_free();await process_frame;quit();return
	game.show_workshop();await shot("workshop")
	game.start_run("campaign",0)
	game.run.launch(Vector2.UP)
	for i in range(700):
		game.run.step(1.0/60.0)
		if game.run.done:break
	game.cavern.sync(game.run);game._result()
	# The new popup starts transparent. Capture only after the real fade/scale completes.
	for frame in range(300):
		if game.result_elapsed>=game.RESULT_APPEAR_SECONDS:break
		await process_frame
	if game.result_elapsed<game.RESULT_APPEAR_SECONDS:
		push_error("CAPTURE FAILED: result appearance did not finish");quit(1);return
	await shot("results")
	var manifest:=FileAccess.open(directory+"/captures.json",FileAccess.WRITE);manifest.store_string(JSON.stringify({"captures":captures},"\t"));manifest.close()
	game.queue_free();await process_frame;quit()
