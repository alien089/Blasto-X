extends Control

export var firstTab = ""

onready var miscMenu: Control = get_parent().get_node("MiscMenu")

func _process(delta):
	if Input.is_action_pressed("ksSecret"):
		$MultiBtn.visible = true
		pass

func _on_SingleBtn_pressed():
	Global.isMultiplayer = false
	get_tree().change_scene("res://scenes/cutscenes/" + firstTab + ".tscn")


func _on_BackBtn_pressed():
	visible = false
	miscMenu.visible = true


func _on_MultiBtn_pressed():
	Global.isMultiplayer = true
	get_tree().change_scene("res://scenes/cutscenes/" + firstTab + ".tscn")


func _on_LoadBtn_pressed():
	if SaveManager.load_game():
		Global.isMultiplayer = SaveManager.game_data.isMultiplayer
		var t = SaveManager.game_data.stage_saved
		get_tree().change_scene("res://scenes/cutscenes/" + SaveManager.game_data.stage_saved + ".tscn")
