extends SceneTree
## Exercises actual GUI input dispatch while button callbacks replace screens.
var game:Node3D
var steps:Array=[]
var touch_mode:=false
func _initialize() -> void:call_deferred("execute")
func find_button(node:Node, text:String) -> Button:
	if node.is_queued_for_deletion():return null
	if node is Button and node.text==text:return node
	for child in node.get_children():
		var found:=find_button(child,text)
		if found:return found
	return null
func tap(text:String) -> void:
	await process_frame
	await process_frame
	var button:=find_button(game.ui,text)
	if not button:push_error("BUTTON MISSING "+text);quit(1);return
	var at:=button.get_global_rect().get_center()
	print("TEARDOWN TAP ",text," at ",at)
	for down in [true,false]:
		if touch_mode:
			var event:=InputEventScreenTouch.new();event.index=0;event.position=at;event.pressed=down
			Input.parse_input_event(event)
		else:
			var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0;event.position=at;event.global_position=at;event.pressed=down
			root.push_input(event,true)
		await process_frame
	steps.append({"button":text,"result_screen":game.screen})
	print("TEARDOWN AFTER ",text," screen=",game.screen)
func execute() -> void:
	var isolated:=false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-profile=user://qa-teardown-"):isolated=true
		if arg=="--touch":touch_mode=true
	if not isolated:push_error("Requires isolated qa-teardown profile");quit(2);return
	root.size=Vector2i(540,960)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);game.set_process(false)
	await tap("Drill chamber 01  ›")
	await tap("Ⅱ")
	await tap("Resume drilling")
	for i in range(3):
		game.run.launch(Vector2.UP)
		await tap("Recall drill")
	await tap("Try this chamber again")
	await tap("Ⅱ")
	await tap("Leave chamber")
	await tap("Bank & return home")
	var f:=FileAccess.open("res://build/evidence/game-touch-teardown.json",FileAccess.WRITE);f.store_string(JSON.stringify({"method":"Input.parse_input_event ScreenTouch with native-style mouse emulation" if touch_mode else "Actual Viewport GUI mouse press/release dispatch fixture", "steps":steps},"\t"));f.close()
	print("TEARDOWN TEST COMPLETE ",steps.size()," GUI transitions")
	game.queue_free();await process_frame;quit()
