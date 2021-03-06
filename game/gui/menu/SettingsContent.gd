
extends "res://gui/menu/MenuContent.gd"

# allow players to adjust settings for sounds and controls

var sfxslider
var bgmslider

var sfxMute = false
var bgmMute = false

var sfxValue
var bgmValue

var mute = preload("res://gui/menu/icons/mute.png")
var sound = preload("res://gui/menu/icons/sound.png")
var sfxclass = preload("res://gui/menu/sfx.tscn")
var sfx

var is_global = false

var layouts = [{"id": "keyboard", "name": "INPUT_KEYBOARD"},
	{"id": "nintendo", "name": "INPUT_NINTENDO"},
	{"id": "playstation", "name": "INPUT_PLAYSTATION"},
	{"id": "xbox", "name": "INPUT_XBOX"},
	{"id": "generic", "name": "INPUT_GENERIC"}
]
var layout_index = 0
var old_layout_index = 0

signal saved
signal nogamepad

func _ready():
	detect_gamepad()
	set_layout_index(Globals.get("current_input"))
	has_content = true
	if (!Globals.has("sfxvolume")):
		Globals.set("sfxvolume", 1)
	if (!Globals.has("bgmvolume")):
		Globals.set("bgmvolume", 1)
	sfxValue = Globals.get("sfxvolume")
	bgmValue = Globals.get("bgmvolume")
	sfxslider = get_node("sfxslider")
	bgmslider = get_node("bgmslider")
	sfx = sfxclass.instance()
	add_child(sfx)

func detect_gamepad():
	if (Input.get_connected_joysticks().size() == 0):
		Globals.set("current_input", "keyboard")
		set_layout_index(Globals.get("current_input"))
		get_node("layout").set_disabled(true)
		emit_signal("nogamepad")
	else:
		get_node("layout").set_disabled(false)

func update_container():
	detect_gamepad()
	sfxValue = Globals.get("sfxvolume")
	bgmValue = Globals.get("bgmvolume")
	sfxslider.set_val(sfxValue)
	bgmslider.set_val(bgmValue)
	if (!Globals.has("sfxmute")):
		Globals.set("sfxmute", false)
	sfxMute = Globals.get("sfxmute")
	if (!Globals.has("bgmmute")):
		Globals.set("bgmmute", false)
	bgmMute = Globals.get("bgmmute")
	sfxMute = Globals.get("sfxmute")
	update_mute_controls()
	get_node("layout").set_text(tr(layouts[old_layout_index].name))
	for key in get_node("inputs").get_children():
		key.update_key()
	Globals.set("newcontrols", Globals.get("controls"))
	var resetwidth = get_node("reset").get_size().x
	get_node("reset").set_pos(Vector2(689 - resetwidth, get_node("reset").get_pos().y))

func _on_sfxslider_value_changed( value ):
	if (!sfxMute):
		AudioServer.set_fx_global_volume_scale(value)

func _on_bgmslider_value_changed( value ):
	if (!bgmMute):
		AudioServer.set_stream_global_volume_scale(value)

func unfocus_all():
	reset()
	if (get_focus_owner() != null):
		get_focus_owner().release_focus()

func reset_content():
	reset()

func reset():
	sfxMute = Globals.get("sfxmute")
	bgmMute = Globals.get("bgmmute")
	var sfx = sfxValue
	if (sfxMute):
		sfx = 0
	var bgm = bgmValue
	if (bgmMute):
		bgm = 0
	update_mute_controls()
	AudioServer.set_fx_global_volume_scale(sfx)
	AudioServer.set_stream_global_volume_scale(bgm)
	sfxslider.set_val(sfxValue)
	bgmslider.set_val(bgmValue)
	layout_index = old_layout_index
	get_node("layout").set_text(tr(layouts[old_layout_index].name))
	Globals.set("current_input", layouts[old_layout_index].id)
	for key in get_node("inputs").get_children():
		key.update_key()
	Globals.set("newcontrols", Globals.get("controls"))

func update_mute_controls():
	if (sfxMute):
		sfxslider.set_self_opacity(0.5)
		sfxslider.get_node("mute").set_texture(mute)
	else:
		sfxslider.set_self_opacity(1)
		sfxslider.get_node("mute").set_texture(sound)
	if (bgmMute):
		bgmslider.set_self_opacity(0.5)
		bgmslider.get_node("mute").set_texture(mute)
	else:
		bgmslider.set_self_opacity(1)
		bgmslider.get_node("mute").set_texture(sound)

func save():
	sfxValue = sfxslider.get_val()
	bgmValue = bgmslider.get_val()
	Globals.set("sfxvolume", sfxValue)
	Globals.set("bgmvolume", bgmValue)
	Globals.set("sfxmute", sfxMute)
	Globals.set("bgmmute", bgmMute)
	Globals.set("controls", Globals.get("newcontrols"))
	if (Globals.get("current_input") == "keyboard"):
		Globals.set("keyboard_controls", Globals.get("controls"))
	else:
		Globals.set("gamepad_controls", Globals.get("controls"))
	for key in get_node("inputs").get_children():
		key.set_input()
		key.get_node("key").set("custom_colors/font_color", null)
	old_layout_index = layout_index
	emit_signal("saved")

func _on_sfxslider_focus_exit():
	if (get_focus_owner() != null && get_focus_owner() == get_parent().get_node("tabs/HBoxContainer/settings")):
		unfocus_all()

func _on_reset_pressed():
	reset()
	sfx.play("confirm")

func _on_save_pressed():
	save()
	sfx.play("confirm")

func block_cancel():
	# block focusing on tabs while capturing input
	for i in get_node("inputs").get_children():
		if (!i.get("isfocusable")):
			return true
	return false

func block_pause():
	# also block pause button as well during capture
	return block_cancel()

func _on_sfxslider_input_event( ev ):
	if (ev.is_action_pressed("ui_accept") && ev.is_pressed() && !ev.is_echo()):
		sfxMute = !sfxMute
		if (sfxMute):
			AudioServer.set_fx_global_volume_scale(0)
			sfxslider.set_self_opacity(0.5)
			sfxslider.get_node("mute").set_texture(mute)
		else:
			AudioServer.set_fx_global_volume_scale(sfxValue)
			sfxslider.set_self_opacity(1)
			sfxslider.get_node("mute").set_texture(sound)

func _on_bgmslider_input_event( ev ):
	if (ev.is_action_pressed("ui_accept") && ev.is_pressed() && !ev.is_echo()):
		bgmMute = !bgmMute
		if (bgmMute):
			AudioServer.set_stream_global_volume_scale(0)
			bgmslider.set_self_opacity(0.5)
			bgmslider.get_node("mute").set_texture(mute)
		else:
			AudioServer.set_stream_global_volume_scale(bgmValue)
			bgmslider.set_self_opacity(1)
			bgmslider.get_node("mute").set_texture(sound)

func _input(event):
	if (event.is_pressed() && !event.is_echo()):
		var old_index = layout_index
		if (event.is_action_pressed("ui_left")):
			layout_index -= 1
			if (layout_index < 0):
				layout_index = layouts.size() - 1
		elif (event.is_action_pressed("ui_right")):
			layout_index += 1
			if (layout_index >= layouts.size()):
				layout_index = 0

		if (old_index != layout_index):
			get_node("layout").set_text(tr(layouts[layout_index].name))
			Globals.set("current_input", layouts[layout_index].id)
			for key in get_node("inputs").get_children():
				key.update_key()
			Globals.set("newcontrols", Globals.get("controls"))

func set_layout_index(id):
	var size = layouts.size()
	for i in range(0, size):
		if (layouts[i].id == id):
			layout_index = i
			old_layout_index = i

func _on_layout_focus_enter():
	set_process_input(true)

func _on_layout_focus_exit():
	set_process_input(false)