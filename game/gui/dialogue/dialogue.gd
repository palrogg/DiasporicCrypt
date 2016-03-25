
extends Control

var text
var textarea
var next
var profile
var dialogs
var hchoice
var vchoice
var current_dialog

var choiceclass = preload("res://gui/dialogue/choice.scn")

const DIAG_DIRECTION = 0
const DIAG_TITLE = 1
const DIAG_TEXT = 2
const DIAG_ITEM = 3
const DIAG_CHOICE = 4

const ITEM_TITLE = 0
const ITEM_TYPE = 1

const CHOICE_TEXT = 0
const CHOICE_ACTION = 1 #dialog, save, shop or end
const CHOICE_VALUE = 2
#dialogue - another dialog array (replace current one completely) or index for current dialog array to jump to
const CHOICE_ORIENTATION = 3

var avatars = {"Friederich": preload("res://gui/dialogue/profiles/friederich.png"), "Kaleva": preload("res://gui/dialogue/profiles/kaleva.png")}

func _ready():
	get_node("frame").hide()
	textarea = get_node("frame/textarea")
	text = textarea.get_node("textcontent")
	var test = RichTextLabel.new()
	next = get_node("next")
	profile = get_node("profile")
	hchoice = textarea.get_node("hchoice")
	vchoice = textarea.get_node("vchoice")
	next.hide()
	profile.hide()
	set_fixed_process(true)

func has_choice():
	var dialog = dialogs[current_dialog]
	return dialog.size() > DIAG_CHOICE && dialog[DIAG_CHOICE] != null

func _fixed_process(delta):
	if (dialogs != null):
		if (text.get_total_character_count() > text.get_visible_characters() && text.get_visible_characters() >= 0):
			text.set_visible_characters(text.get_visible_characters() + 1)
			next.hide()
		elif (text.get_visible_characters() != 0 && !has_choice()):
			next.show()
		elif (has_choice() && hchoice.get_child_count() == 0 && vchoice.get_child_count() == 0):
			add_choices()
	
func start(data):
	get_node("frame").show()
	dialogs = data
	current_dialog = -1
	show_dialog()
	next.hide()

func add_choices():
	var choices = dialogs[current_dialog][DIAG_CHOICE]
	var choicecontainer = hchoice
	var basemargin = 0
	# set correct choice obj y pos
	var obj_y = 48
	
	if (!choices[0][CHOICE_ORIENTATION]):
		choicecontainer = vchoice
		basemargin += 1
		obj_y = 0
		# set correct y pos
		vchoice.set_pos(Vector2(vchoice.get_pos().x, 48))
	for choice in choices:
		var choice_obj = choiceclass.instance()
		choice_obj.get_node("text").set_text(choice[CHOICE_TEXT])
		choice_obj.set_pos(Vector2(0, obj_y))
		choice_obj.set("action", choice[CHOICE_ACTION])
		if (choice.size() > CHOICE_VALUE):
			choice_obj.set("data", choice[CHOICE_VALUE])
		if (choicecontainer.get_child_count() > 0):
			var neighbour = choicecontainer.get_child(choicecontainer.get_child_count() - 1)
			choice_obj.set_focus_neighbour(basemargin, neighbour.get_path())
			neighbour.set_focus_neighbour(basemargin + 2, choice_obj.get_path())
		choicecontainer.add_child(choice_obj)
	choicecontainer.get_child(0).grab_focus()

func clear_choices():
	for choice in vchoice.get_children():
		choice.queue_free()
	for choice in hchoice.get_children():
		choice.queue_free()

func find_choice():
	var choicecontainer = hchoice
	if (vchoice.get_child_count() > 0):
		choicecontainer = vchoice
	for choice in choicecontainer.get_children():
		if (choice.has_focus()):
			return choice
	return null

func check_dialog():
	if (text.get_total_character_count() == text.get_visible_characters() || text.get_visible_characters() < 0):
		if (has_choice()):
			var choice = find_choice()
			if (choice.get("action") == "dialog"):
				clear_choices()
				if (typeof(choice.get("data")) == TYPE_INT):
					current_dialog = choice.get("data") - 1
				else:
					current_dialog = -1
					dialogs = choice.get("data")
				show_dialog()
			elif (choice.get("action") == "end"):
				hide_dialog()
		else:
			show_dialog()
	else:
		text.set_visible_characters(-1)
		if (has_choice()):
			add_choices()
		else:
			next.show()

func show_dialog():
	current_dialog += 1
	if (current_dialog < dialogs.size()):
		var dialog = dialogs[current_dialog]
		while (current_dialog < dialogs.size() && dialog[DIAG_TEXT].empty()): 
			current_dialog += 1
			dialog = dialogs[current_dialog]

		if (current_dialog < dialogs.size()):
			if (dialog[DIAG_DIRECTION] != 0):
				profile.show()
				profile.get_node("avatar").set_texture(avatars[dialog[DIAG_TITLE]])
				textarea.set_pos(Vector2(191*(dialog[DIAG_DIRECTION] - 1)/2 + 215, textarea.get_pos().y))
				hchoice.set_pos(Vector2(191*(dialog[DIAG_DIRECTION] - 1)/2 + 215, hchoice.get_pos().y))
				vchoice.set_pos(Vector2(191*(dialog[DIAG_DIRECTION] - 1)/2 + 215, vchoice.get_pos().y))
				profile.get_node("title").set_text(tr(dialog[DIAG_TITLE]))
				profile.get_node("avatar").set_scale(Vector2(dialog[DIAG_DIRECTION], 1))
				profile.get_node("title").set_align(-(dialog[DIAG_DIRECTION] - 1))
				profile.get_node("title").set_pos(Vector2(242*(dialog[DIAG_DIRECTION] - 1) / 2 + 10, profile.get_node("title").get_pos().y))
				profile.set_pos(Vector2(-400*(dialog[DIAG_DIRECTION] - 1), profile.get_pos().y))
				
			else:
				profile.hide()
				textarea.set_pos(Vector2(119, textarea.get_pos().y))
				hchoice.set_pos(Vector2(119, hchoice.get_pos().y))
				vchoice.set_pos(Vector2(119, vchoice.get_pos().y))
			var basetext = tr(dialog[DIAG_TEXT])
			if (dialog.size() > DIAG_ITEM && dialog[DIAG_ITEM] != null):
				basetext = tr("ITEM_RECEIVED")
				var item = dialog[DIAG_ITEM]
				var itemtext = item[ITEM_TITLE]
				var itemicon = "res://gui/hud/potion.png"
				if (item[ITEM_TYPE] == "exp"):
					itemicon = "res://gui/hud/exporb.png"
					itemtext = itemtext + tr("ITEM_EXP")
				if (item[ITEM_TYPE] == "gold"):
					itemicon = "res://gui/hud/gold.png"
					itemtext = itemtext + "G"
				if (item[ITEM_TYPE] == "scroll"):
					itemicon = "res://gui/hud/scroll.png"
				itemtext = "[img]" + itemicon + "[/img]" + itemtext
				basetext = basetext.replace("[item]", itemtext)
				#put item in inventory
			text.set_bbcode(basetext)
			text.set_visible_characters(0)
		else :
			hide_dialog()
	else:
		hide_dialog()
	next.hide()

func hide_dialog():
	dialogs = null
	profile.hide()
	get_node("frame").hide()
	get_tree().set_pause(false)
	clear_choices()