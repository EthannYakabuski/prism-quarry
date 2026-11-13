extends Node3D
const Run = preload("res://game/run.gd")
const Profile = preload("res://game/profile.gd")
const Cavern = preload("res://game/cavern.gd")
const Chambers = preload("res://game/chambers.gd")
const INK := Color("10232c")
const CREAM := Color("f6e9cc")
const MUTED := Color("a9bdc4")
const GOLD := Color("f5c674")
var profile: RefCounted
var run: RefCounted
var cavern: Node3D
var ui: Control
var overlay: Control
var screen := "home"
var aim := Vector2(0,-1)
var dragging := false
var fullscreen := false
var reward_waiting := false
var receipt: Dictionary={}
var catalog: Dictionary={}
var service: Node
var hud_score: Label
var hud_ore: Label
var hud_shots: Label
var hud_bar: ProgressBar
var hint: Label
var toast_label: Label
var toast_time:=0.0
var checkpoint_time:=0.0
var banner_spacer: Control
var reward_button: Button
var reward_hint: Label
var music: AudioStreamPlayer
var sound_players: Array[AudioStreamPlayer]=[]
var music_key:=""
var audio_manifest: Dictionary={}
var starting:=false
var app_focused:=true

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	var save_path:="user://quarry-v1.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--qa-profile=user://qa-"):save_path=arg.trim_prefix("--qa-profile=")
	profile=Profile.new(save_path)
	if FileAccess.file_exists("res://game/catalog.json"):catalog=JSON.parse_string(FileAccess.get_file_as_string("res://game/catalog.json"))
	if FileAccess.file_exists("res://assets/audio/manifest.json"):audio_manifest=JSON.parse_string(FileAccess.get_file_as_string("res://assets/audio/manifest.json"))
	music=AudioStreamPlayer.new();music.volume_db=-14;add_child(music)
	for i in range(8):
		var player:=AudioStreamPlayer.new();add_child(player);sound_players.append(player)
	cavern=Cavern.new();add_child(cavern)
	var layer:=CanvasLayer.new();add_child(layer)
	ui=Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
	var font_theme:=Theme.new();font_theme.default_font_size=20
	font_theme.set_color("font_color","Label",CREAM)
	font_theme.set_color("font_color","Button",INK)
	font_theme.set_color("font_disabled_color","Button",Color("7e9095"))
	font_theme.set_stylebox("normal","Button",button_style(Color("e7b76d")))
	font_theme.set_stylebox("hover","Button",button_style(Color("ffdc99")))
	font_theme.set_stylebox("pressed","Button",button_style(Color("bc8d4e"),true))
	font_theme.set_stylebox("disabled","Button",style(Color("31454c"),14))
	ui.theme=font_theme
	service=get_node_or_null("/root/Services")
	if service:
		service.configure_catalog(catalog)
		service.fullscreen_pending.connect(_fullscreen_pending)
		service.fullscreen_visibility_changed.connect(_fullscreen_changed)
		service.reward_finished.connect(_reward_finished)
		service.interstitial_finished.connect(_interstitial_finished)
		service.menu_bottom_reserve_changed.connect(_reserve_changed)
		service.services_updated.connect(_services_updated)
		fullscreen=service.fullscreen_ad_active()
	var login:int=profile.login(Profile.today())
	_sync_metrics()
	if not profile.data.active.is_empty():
		run=Run.restore(profile.data.active);cavern.build(run,int(profile.data.skin))
		if run.done:_result()
		else:_pause("Your chamber is safe. Resume when you're ready.")
	else:
		_preview_run();home()
	if login>0:toast("Day %d gift · +%d ore"%[profile.data.streak,login])
	if not profile.recovery.is_empty():toast(profile.recovery)
	get_viewport().size_changed.connect(_resized)
	_resized()

func style(color: Color, radius: int=18) -> StyleBoxFlat:
	var b:=StyleBoxFlat.new();b.bg_color=color;b.corner_radius_top_left=radius;b.corner_radius_top_right=radius;b.corner_radius_bottom_left=radius;b.corner_radius_bottom_right=radius
	b.content_margin_left=18;b.content_margin_right=18;b.content_margin_top=12;b.content_margin_bottom=12
	return b

func button_style(color: Color, pressed: bool=false) -> StyleBoxTexture:
	var b:=StyleBoxTexture.new();b.texture=load("res://assets/ui/button_pressed.png" if pressed else "res://assets/ui/button.png");b.modulate_color=color
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:b.set_texture_margin(side,8);b.set_content_margin(side,12)
	return b

func label(text: String, size: int=20, color: Color=CREAM) -> Label:
	var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

func button(text: String, callback: Callable, muted: bool=false) -> Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=56;b.add_theme_font_size_override("font_size",20);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	if muted:
		b.add_theme_stylebox_override("normal",button_style(Color("29414b")));b.add_theme_stylebox_override("hover",button_style(Color("3a5660")));b.add_theme_color_override("font_color",CREAM)
	b.pressed.connect(func():sound("click");callback.call())
	return b

func _clear_ui() -> void:
	# Touch-to-mouse dispatch can still retain the old Control after pressed.
	# Hide now, then let queue_free detach it after the current event unwinds.
	for child in ui.get_children():
		if child is CanvasItem:child.hide()
		child.queue_free()
	hud_score=null;hud_ore=null;hud_shots=null;hud_bar=null;hint=null;banner_spacer=null;toast_label=null;reward_button=null;reward_hint=null
	dragging=false;cavern.trajectory.visible=false

func _margin(parent: Control, preset: int, top: int=20, bottom: int=-20) -> VBoxContainer:
	var m:=MarginContainer.new();m.set_anchors_and_offsets_preset(preset);m.offset_left=24;m.offset_right=-24;m.offset_top=top;m.offset_bottom=bottom;parent.add_child(m)
	var v:=VBoxContainer.new();v.add_theme_constant_override("separation",10);m.add_child(v);return v

func _panel(v: VBoxContainer) -> VBoxContainer:
	var panel:=PanelContainer.new();var st:=style(Color(0.035,0.09,0.12,0.95),20);st.border_width_bottom=2;st.border_color=Color("42626a");panel.add_theme_stylebox_override("panel",st);v.add_child(panel)
	var inner:=VBoxContainer.new();inner.add_theme_constant_override("separation",10);panel.add_child(inner);return inner

func _row(v: VBoxContainer) -> HBoxContainer:
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",10);v.add_child(row);return row

func _spacer(v: VBoxContainer, h: float) -> Control:
	var c:=Control.new();c.custom_minimum_size.y=h;v.add_child(c);return c

func _menu_state(value: String) -> void:
	screen=value;_clear_ui()
	if service:service.set_banner_visible(value in ["home","result"])
	cavern.reduced_motion=not profile.data.motion
	_music("menu" if value in ["home","workshop","map","daily","journal","settings"] else ["amber_hollow","azure_grotto","violet_vault"][int(run.spec.theme)])

func _preview_run() -> void:
	run=Run.new();run.start(0,"campaign",profile.unlocked_chamber(),profile.data.gear,Profile.today());cavern.build(run,int(profile.data.skin))

func home() -> void:
	_refresh_day()
	_menu_state("home")
	var backdrop:=TextureRect.new();backdrop.texture=load("res://assets/brand/splash.png");backdrop.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;backdrop.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);backdrop.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.add_child(backdrop)
	var bottom:=_margin(ui,Control.PRESET_BOTTOM_WIDE,-390-int(_reserve()),-18)
	var card:=_panel(bottom)
	var header:=_row(card);var lv:=label("MINER %d"%profile.level(),15,GOLD);lv.size_flags_horizontal=Control.SIZE_EXPAND_FILL;header.add_child(lv);var pouch:=label("%s ore"%_number(profile.data.coins),18);pouch.autowrap_mode=TextServer.AUTOWRAP_OFF;header.add_child(pouch)
	card.add_child(button("Drill chamber %02d  ›"%(profile.unlocked_chamber()+1),func():start_run("campaign",profile.unlocked_chamber())))
	var row:=_row(card);row.add_child(button("Chambers",show_map,true));row.add_child(button("Workshop",show_workshop,true))
	row=_row(card);row.add_child(button("Daily",show_daily,true));row.add_child(button("Endless",func():start_run("endless",0),true))
	row=_row(card);var journal:=button("Journal",show_journal,true);journal.custom_minimum_size.y=42;row.add_child(journal);var settings:=button("Settings",show_settings,true);settings.custom_minimum_size.y=42;row.add_child(settings)
	banner_spacer=_spacer(bottom,_reserve())

func _number(n: int) -> String:
	return "%d"%n if n<10000 else "%.1fk"%(n/1000.0)

func start_run(mode: String, index: int) -> void:
	if starting:return
	starting=true
	var id:int=profile.new_run()
	if id==0:starting=false;toast(profile.last_error);return
	run=Run.new();run.start(id,mode,index,profile.data.gear,Profile.today())
	if not profile.store_run(run.snapshot()):starting=false;toast(profile.last_error);return
	receipt={};reward_waiting=false;aim=Vector2(0,-1)
	cavern.build(run,int(profile.data.skin));starting=false;_play_ui()

func _play_ui() -> void:
	_menu_state("play")
	var top:=_margin(ui,Control.PRESET_TOP_WIDE,18,165)
	var head:=_row(top)
	var title:=label(("ENDLESS · DEPTH %d"%run.depth if run.mode=="endless" else "DAILY CHAMBER" if run.mode=="daily" else "CHAMBER %02d"%(run.chamber+1))+" · "+Chambers.THEMES[int(run.spec.theme)].to_upper(),14,GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;head.add_child(title)
	var pause:=button("Ⅱ",func():_pause(),true);pause.custom_minimum_size=Vector2(52,44);pause.size_flags_horizontal=0;head.add_child(pause)
	var panel:=_panel(top);var row:=_row(panel)
	hud_ore=label("",20);hud_ore.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(hud_ore);hud_score=label("",20,GOLD);hud_score.autowrap_mode=TextServer.AUTOWRAP_OFF;hud_score.custom_minimum_size.x=130;hud_score.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT;row.add_child(hud_score)
	hud_bar=ProgressBar.new();hud_bar.custom_minimum_size.y=9;hud_bar.show_percentage=false;hud_bar.add_theme_stylebox_override("background",style(Color("283f46"),5));hud_bar.add_theme_stylebox_override("fill",style(cavern.tint,5));panel.add_child(hud_bar)
	var bottom:=_margin(ui,Control.PRESET_BOTTOM_WIDE,-182,-20)
	var card:=_panel(bottom)
	hud_shots=label("",18,GOLD);hud_shots.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_child(hud_shots)
	hint=label("DRAG TO AIM · RELEASE TO DRILL",16);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_child(hint)
	var actions:=_row(card)
	actions.add_child(button("Recall drill",_recall,true))
	actions.add_child(button("Bank haul",_bank,true))
	_update_hud()
	if not run.moving:cavern.show_preview(run.preview(aim))

func _update_hud() -> void:
	if not is_instance_valid(hud_score):return
	hud_score.text="%s pts"%_number(run.score)
	hud_ore.text="%d / %d crystals"%[run.stage_crystals,run.spec.goal]
	hud_bar.max_value=run.spec.goal;hud_bar.value=run.stage_crystals
	hud_shots.text="%s  %d %s LEFT"%["● ".repeat(run.shots),run.shots,"SHOT" if run.shots==1 else "SHOTS"]
	if run.moving:hint.text="%d CRYSTAL COMBO · TAP RECALL TO RETURN"%run.shot_combo
	elif run.stage_crystals>=int(run.spec.goal):hint.text="TARGET REACHED · BANK OR MINE EVERY CRYSTAL"
	elif run.chamber==0 and run.mode=="campaign":hint.text="DRAG ON THE CAVE. RELEASE INTO THE GOLD VEIN."
	elif run.chamber==1 and run.mode=="campaign":hint.text="AIM AROUND BRASS. WALLS BOUNCE YOUR DRILL."
	else:hint.text="DRAG TO AIM · RELEASE TO DRILL"

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_ESCAPE:
		_back();get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if screen!="play" or fullscreen or run.moving or run.done:return
	if event is InputEventScreenTouch:
		if event.pressed:_aim_begin(event.position)
		elif dragging:_aim_release(event.position)
	elif event is InputEventScreenDrag and dragging:_aim_to(event.position)
	elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:_aim_begin(event.position)
		elif dragging:_aim_release(event.position)
	elif event is InputEventMouseMotion and dragging:_aim_to(event.position)

func _aim_begin(pos: Vector2) -> void:
	if pos.y<190 or pos.y>ui.size.y-190:return
	dragging=true;_aim_to(pos)

func _aim_to(pos: Vector2) -> void:
	var target:Vector2=cavern.screen_to_board(pos)
	aim=(target-Run.ORIGIN).normalized()
	if aim.y>-0.1:aim.y=-0.1;aim=aim.normalized()
	cavern.show_preview(run.preview(aim))

func _aim_release(pos: Vector2) -> void:
	_aim_to(pos);dragging=false
	var before:Dictionary=run.snapshot()
	if run.launch(aim):
		if not profile.store_run(run.snapshot()):run=Run.restore(before);_pause(profile.last_error)
		else:_update_hud()

func _recall() -> void:
	if screen!="play" or fullscreen:return
	if run.moving:
		run.recall();sound("recall")
		if _checkpoint():_after_step()
	else:toast("Aim at the cave, then release to launch.")

func _bank() -> void:
	if run.moving:toast("Recall the drill before banking.");return
	if run.mode!="endless" and run.stage_crystals<int(run.spec.goal):toast("Mine %d more crystals to complete this chamber."%(int(run.spec.goal)-run.stage_crystals));return
	run.bank()
	if _checkpoint():_result()

func _process(delta: float) -> void:
	if is_instance_valid(toast_label):
		toast_time-=delta
		if toast_time<=0:toast_label.queue_free();toast_label=null
	if screen!="play" or fullscreen or run==null:return
	var was_moving:bool=run.moving
	run.step(delta)
	var gems:=0
	for event in run.events:
		match event.type:
			"gem":cavern.fracture(event);gems+=1
			"chain":toast("CRYSTAL CASCADE  ×%d"%event.count);sound("chain")
			"ricochet":sound("ricochet")
			"shot":sound("shot")
	run.events.clear()
	if gems>0:
		sound("gem")
		if profile.data.vibration and OS.has_feature("mobile"):Input.vibrate_handheld(18)
	cavern.sync(run);_update_hud()
	checkpoint_time+=delta
	if checkpoint_time>=1.0 and run.moving:_checkpoint();checkpoint_time=0
	if was_moving and not run.moving:
		if _checkpoint():_after_step()

func _after_step() -> void:
	if run.done:_result()
	elif run.stage_ready:
		_menu_state("depth")
		var card:=_dialog("SEAM COMPLETE", "A little deeper, a little brighter.")
		card.add_child(label("%s points · %d crystals"%[_number(run.score),run.crystals],22,GOLD))
		card.add_child(button("Descend to depth %d  ›"%(run.depth+1),_descend))
		card.add_child(button("Bank this haul",_bank,true))
	else:cavern.show_preview(run.preview(aim))

func _checkpoint() -> bool:
	if run==null or run.run_id<=int(profile.data.last_paid_run):return true
	if not profile.store_run(run.snapshot()):
		_pause(profile.last_error,false)
		return false
	return true

func _dialog(title_text: String, description: String) -> VBoxContainer:
	var shade:=ColorRect.new();shade.color=Color(0.01,0.025,0.04,0.67);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(shade)
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);center.offset_left=24;center.offset_right=-24;center.offset_top=25;center.offset_bottom=-35-_reserve();ui.add_child(center)
	var panel:=PanelContainer.new();panel.custom_minimum_size.x=minf(492,ui.size.x-48);panel.add_theme_stylebox_override("panel",style(Color("112d38"),22));center.add_child(panel)
	var v:=VBoxContainer.new();v.add_theme_constant_override("separation",14);panel.add_child(v)
	var title:=label(title_text,30,GOLD);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;v.add_child(title)
	if not description.is_empty():
		var text:=label(description,19,MUTED);text.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;v.add_child(text)
	return v

func _descend() -> void:
	var next:RefCounted=Run.restore(run.snapshot())
	if not next.next_depth():return
	if not profile.store_run(next.snapshot()):toast(profile.last_error);return
	run=next;cavern.build(run,int(profile.data.skin));_play_ui()

func _pause(message: String="Take a breath. Your drill can wait.", save: bool=true) -> void:
	if run==null:return
	if save and run.run_id>0 and run.run_id>int(profile.data.last_paid_run):
		if not profile.store_run(run.snapshot()):message=profile.last_error
	_menu_state("pause")
	var card:=_dialog("SHIFT PAUSED",message)
	card.add_child(button("Resume drilling",func():
		if fullscreen:toast("Your drill will be ready when this closes.");return
		if not _checkpoint():toast(profile.last_error);return
		if run.done:_result()
		elif run.stage_ready:_after_step()
		else:_play_ui()))
	card.add_child(button("Settings",show_settings,true))
	card.add_child(button("Leave chamber",_leave_prompt,true))

func _leave_prompt() -> void:
	_clear_ui()
	var card:=_dialog("BANK & LEAVE?","Keep the ore and XP you've mined. This chamber will end.")
	card.add_child(button("Bank & return home",func():run.recall();run.bank();if_settled_home()))
	card.add_child(button("Keep drilling",func():_pause(),true))

func if_settled_home() -> void:
	if not _settle():return
	_preview_run();home();_interstitial()

func _settle() -> bool:
	if run.run_id<=int(profile.data.last_paid_run):return true
	receipt=profile.settle(run,Profile.today())
	if receipt.is_empty():toast(profile.last_error);return false
	_sync_metrics()
	if service and run.used>0:service.record_round_completed(str(run.run_id))
	return true

func _result() -> void:
	if not _checkpoint():return
	if run.won and not _settle():_pause(profile.last_error);return
	_menu_state("result")
	var card:=_dialog("BEAUTIFUL HAUL" if run.won else "ONE MORE ANGLE?",run.spec.name+" · "+Chambers.THEMES[int(run.spec.theme)])
	var stars:=HBoxContainer.new();stars.alignment=BoxContainer.ALIGNMENT_CENTER;card.add_child(stars)
	for i in range(3):
		var icon:=TextureRect.new();icon.texture=load("res://assets/ui/star.png" if i<run.stars() else "res://assets/ui/star_empty.png");icon.custom_minimum_size=Vector2(48,48);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;stars.add_child(icon)
	var points:=label("%s POINTS"%_number(run.score),34);points.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;card.add_child(points)
	card.add_child(label("%d crystals  ·  best combo ×%d\n%d ricochets  ·  %d %s"%[run.crystals,run.best_combo,run.ricochets,run.used,"shot" if run.used==1 else "shots"],19,MUTED))
	if run.won:
		card.add_child(label("+%d ore   +%d XP"%[receipt.get("coins",profile.data.last_receipt.get("coins",0)),receipt.get("xp",profile.data.last_receipt.get("xp",0))],22,GOLD))
		if run.mode=="campaign" and run.chamber<29:card.add_child(button("Next chamber  ›",func():var index:int=run.chamber+1;start_run("campaign",index);_interstitial()))
		else:card.add_child(button("Back to the workshop",func():_preview_run();home();_interstitial()))
	else:
		card.add_child(label("%d / %d crystals found. Your haul is kept when you finish."%[run.stage_crystals,run.spec.goal],18))
		if not run.continued:
			reward_button=button("Watch an ad · 2 extra shots",_request_reward)
			reward_button.disabled=not service or not service.can_reward();card.add_child(reward_button)
			reward_hint=label("Extra shots are unavailable right now.",15,MUTED);reward_hint.visible=reward_button.disabled;card.add_child(reward_hint)
	card.add_child(button("Try this chamber again",_retry,true))
	card.add_child(button("Bank & return home",if_settled_home,true))
	sound("victory" if run.won else "back")

func _retry() -> void:
	var kind:String=run.mode;var index:int=run.chamber
	if not _settle():return
	start_run(kind,index);_interstitial()

func _request_reward() -> void:
	if reward_waiting or run.continued or run.won or not run.done:return
	if not service or not service.can_reward():toast("Extra shots are unavailable right now.");return
	if not _checkpoint():return
	reward_waiting=true;service.request_rewarded_continue()

func _reward_finished(earned: bool) -> void:
	if not reward_waiting:return
	reward_waiting=false
	if earned and run.done and not run.won and not run.continued:
		var next:RefCounted=Run.restore(run.snapshot())
		if next.continue_earned():
			run=next
			if not profile.store_run(next.snapshot()):_pause("Your extra shots are earned. Storage needs attention; tap Resume to retry saving.",false);return
			_pause("Two extra shots are ready. Tap Resume to continue.");sound("reward");return
	_result()
	if not earned:toast("No extra shots were added. Your chamber is safe.")

func _fullscreen_pending(_reason: String) -> void:
	fullscreen=true;dragging=false
	if screen in ["play","depth"]:_pause("Your chamber is safe. Tap Resume when you're ready.")
	else:_checkpoint()

func _fullscreen_changed(showing: bool) -> void:
	fullscreen=showing
	_audio_state()

func _interstitial() -> void:
	if service:service.request_interstitial_at_transition()

func _interstitial_finished(_shown: bool) -> void:
	fullscreen=false
	_audio_state()

func _services_updated() -> void:
	if screen=="result" and not reward_waiting and not fullscreen and is_instance_valid(reward_button):
		reward_button.disabled=not service or not service.can_reward()
		if is_instance_valid(reward_hint):reward_hint.visible=reward_button.disabled

func _sync_metrics() -> void:
	profile.update_achievements(catalog)
	if service:service.submit_metrics(profile.metrics())

func _back() -> void:
	if fullscreen:return
	if screen=="play":_pause()
	elif screen=="result":if_settled_home()
	elif screen=="pause":toast("Tap Resume when you're ready.")
	elif screen in ["settings","workshop","daily","journal","map"]:
		if run and run.run_id>int(profile.data.last_paid_run) and run.run_id>0:_pause()
		else:home()

func _notification(what: int) -> void:
	if not is_instance_valid(ui):return
	if what==NOTIFICATION_WM_GO_BACK_REQUEST:_back()
	elif what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_APPLICATION_FOCUS_OUT]:
		app_focused=false;_audio_state()
		if screen=="play":_pause("Your shift was interrupted. Tap Resume when you're ready.")
		elif run and run.run_id>int(profile.data.last_paid_run):_checkpoint()
	elif what==NOTIFICATION_WM_CLOSE_REQUEST:_checkpoint()
	elif what in [NOTIFICATION_APPLICATION_RESUMED,NOTIFICATION_APPLICATION_FOCUS_IN]:app_focused=true;_audio_state();_refresh_day()

func _refresh_day() -> void:
	if profile==null:return
	var gift:int=profile.login(Profile.today())
	if gift>0:_sync_metrics();toast("Day %d gift · +%d ore"%[profile.data.streak,gift])

func _page(title_text: String, subtitle: String) -> VBoxContainer:
	var shade:=ColorRect.new();shade.color=Color(0.015,0.04,0.055,0.94);shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.add_child(shade)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);margin.offset_left=24;margin.offset_right=-24;margin.offset_top=24;margin.offset_bottom=-24;ui.add_child(margin)
	var outer:=VBoxContainer.new();outer.add_theme_constant_override("separation",14);margin.add_child(outer)
	var top:=_row(outer);var title:=label(title_text,30,GOLD);title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title);var back:=button("‹ Back",_back,true);back.custom_minimum_size.x=100;back.size_flags_horizontal=0;top.add_child(back)
	outer.add_child(label(subtitle,18,MUTED))
	var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;outer.add_child(scroll)
	var content:=VBoxContainer.new();content.add_theme_constant_override("separation",12);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(content)
	return content

func show_map() -> void:
	_menu_state("map")
	var v:=_page("THE QUARRY","30 little wonders. Clear a chamber to open the next.")
	for t in range(3):
		v.add_child(label(Chambers.THEMES[t].to_upper(),21,Cavern.PALETTES[t]))
		for i in range(t*10,t*10+10):
			var stars:int=int(profile.data.stars[i]) if profile.data.stars.size()>i else 0
			var row:=_row(v)
			var b:=button("%02d  %s"%[i+1,Chambers.NAMES[i]],func():start_run("campaign",i),true);b.disabled=i>profile.unlocked_chamber();row.add_child(b)
			for star in range(3):
				var icon:=TextureRect.new();icon.texture=load("res://assets/ui/star.png" if star<stars else "res://assets/ui/star_empty.png");icon.custom_minimum_size=Vector2(22,40);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(icon)

func show_workshop() -> void:
	_menu_state("workshop")
	var v:=_page("YOUR WORKSHOP","Miner %d · %d XP · %d ore"%[profile.level(),profile.data.xp,profile.data.coins])
	var defs:Dictionary={"drill":["Flywheel","Stay in the chamber 0.15 seconds longer per rank."],"echo":["Echo coil","Link neighboring crystal seams a little farther."],"salvage":["Ore catcher","Bank one extra ore per crystal for each rank."]}
	for key in defs:
		var rank:int=profile.data.gear[key];var card:=_panel(v)
		card.add_child(label("%s   %d / 4"%[defs[key][0],rank],24,GOLD));card.add_child(label(defs[key][1],18,MUTED))
		var b:=button("Upgrade · %d ore"%(180+rank*240) if rank<4 else "Fully upgraded",func():
			if profile.upgrade(key):sound("upgrade");_sync_metrics();show_workshop()
			else:toast(profile.last_error if not profile.last_error.is_empty() else "Mine a little more ore first."))
		b.disabled=rank>=4;card.add_child(b)
	v.add_child(label("DRILL FINISHES",21,GOLD))
	for i in range(3):
		var unlocked:bool=profile.level()>=1+i*3
		var b:=button(["Seafoam","Sunfire","Amethyst"][i]+(" · equipped" if profile.data.skin==i else "" if unlocked else " · miner %d"%(1+i*3)),func():profile.setting("skin",i);cavern.build(run,i);show_workshop(),true);b.disabled=not unlocked;v.add_child(b)

func show_daily() -> void:
	_refresh_day()
	_menu_state("daily")
	var v:=_page("DAILY SPARKS","A fresh seeded chamber and three goals every UTC day.")
	var card:=_panel(v);card.add_child(label("DAY %d OF 7"%profile.data.streak,23,GOLD));card.add_child(label("Today's gift is already in your ore pouch. Return tomorrow to keep your streak glowing.",18,MUTED))
	var days:=_row(card)
	for i in range(7):
		var item:=label("%s\n%d"%["●" if i<profile.data.streak else "○",50+i*15],15,GOLD if i<profile.data.streak else MUTED);item.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;days.add_child(item)
	v.add_child(button("Play today's chamber  ›",func():start_run("daily",0)))
	var goals:Dictionary={"crystals":["Mine 40 crystals",40],"clears":["Clear 3 chambers",3],"ricochets":["Make 15 ricochets",15]}
	for key in goals:
		card=_panel(v);card.add_child(label(goals[key][0],22));card.add_child(label("%d / %d · +90 ore, +40 XP"%[mini(int(profile.data.quest[key]),int(goals[key][1])),goals[key][1]],18,MUTED))
		var claimed:bool=profile.data.quest_claims.has(key)
		var b:=button("Claimed" if claimed else "Collect reward",func():
			if profile.claim_quest(key,Profile.today()):sound("reward");_sync_metrics();show_daily()
			else:toast("Complete this goal to collect your reward."),true)
		b.disabled=claimed or int(profile.data.quest[key])<int(goals[key][1]);card.add_child(b)

func show_journal() -> void:
	_menu_state("journal")
	var v:=_page("MINER'S JOURNAL","Your discoveries are saved on this device, even offline.")
	var row:=_row(v);row.add_child(button("Play achievements",func():if service:service.open_achievements(),true));row.add_child(button("Leaderboards",func():if service:service.open_leaderboards(),true))
	var m:Dictionary=profile.metrics()
	for a in catalog.get("achievements",[]):
		var card:=_panel(v);var line:=_row(card)
		var icon_path:="res://assets/badges/%s.png"%a.key
		if ResourceLoader.exists(icon_path):
			var icon:=TextureRect.new();icon.texture=load(icon_path);icon.custom_minimum_size=Vector2(62,62);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;line.add_child(icon)
		var text:=VBoxContainer.new();text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;line.add_child(text)
		text.add_child(label(a.name+("  ✓" if profile.data.achievements.get(a.key,false) else ""),21,GOLD));text.add_child(label(a.description,16,MUTED));text.add_child(label("%d / %d"%[mini(int(m.get(a.metric,0)),int(a.threshold)),a.threshold],15))

func show_settings() -> void:
	_menu_state("settings")
	var v:=_page("A QUIETER CORNER","Make the quarry feel right for you.")
	for setting in [["music","Music"],["sfx","Sound effects"],["motion","Motion & crystal effects"],["vibration","Haptic feedback"]]:
		var key:String=setting[0]
		v.add_child(button(setting[1]+(" · On" if profile.data[key] else " · Off"),func():profile.setting(key,not profile.data[key]);_audio_state();show_settings(),true))
	v.add_child(label("GOOGLE PLAY",20,GOLD))
	v.add_child(button("Connect Play Games",func():
		if service:service.request_sign_in();toast(service.status())
		else:toast("Play Games is available on Android when connected."),true))
	v.add_child(button("Privacy choices",func():
		if service:service.request_privacy_options();toast(service.status())
		else:toast("No advertising connection is active here."),true))
	v.add_child(label("Aim anywhere inside the cave, then release. Matching shapes link into a chain. White prisms fracture nearby colors. Brass rings bounce the drill; the bottom opening returns it. Recall ends a shot early. Mine the target for one star, 88% for two, every crystal for three.",18,MUTED))
	v.add_child(label("Prism Quarry · 1.0\nOriginal code: Apache-2.0. Models, UI and sounds: Kenney CC0. Original music. See bundled notices.",15,MUTED))

func _reserve() -> float:return maxf(60,service.menu_bottom_reserve(ui)) if service else 0
func _reserve_changed() -> void:
	if is_instance_valid(banner_spacer):banner_spacer.custom_minimum_size.y=_reserve()

func _resized() -> void:
	if not cavern or not cavern.camera:return
	var aspect:=get_viewport().get_visible_rect().size.x/maxf(get_viewport().get_visible_rect().size.y,1)
	cavern.camera.size=maxf(16.5,10.4/aspect)

func toast(message: String) -> void:
	if not is_instance_valid(ui):return
	if is_instance_valid(toast_label):toast_label.queue_free()
	toast_label=label(message,19,GOLD);toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;toast_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);toast_label.offset_left=-230;toast_label.offset_right=230;toast_label.offset_top=185;toast_label.offset_bottom=245;ui.add_child(toast_label);toast_time=3.5

func _music(key: String) -> void:
	if music_key==key:_audio_state();return
	music_key=key
	var path:="res://assets/audio/music/%s.wav"%key
	if not ResourceLoader.exists(path):return
	var stream:AudioStream=load(path).duplicate()
	if stream is AudioStreamWAV:stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_begin=0;stream.loop_end=int(stream.get_length()*stream.mix_rate)
	music.stream=stream;music.play();_audio_state()
	music.volume_db=float(audio_manifest.get("music",{}).get(key,{}).get("gain_db",-9.0))

func sound(key: String) -> void:
	if not profile.data.sfx or not app_focused or fullscreen:return
	var path:="res://assets/audio/sfx/%s.ogg"%key
	if not ResourceLoader.exists(path):return
	for player in sound_players:
		if not player.playing:player.stream=load(path);player.volume_db=float(audio_manifest.get("sfx",{}).get(key,{}).get("gain_db",-11.0));player.play();break

func _audio_state() -> void:
	if not is_instance_valid(music) or profile==null:return
	music.stream_paused=not profile.data.music or not app_focused or fullscreen
	if not app_focused or fullscreen:
		for player in sound_players:player.stop()
