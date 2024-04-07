extends Control

onready var miscMenu: Control = get_parent().get_node("MiscMenu")
onready var optionMenu: Control = get_node("OptionMenu")
onready var commandMenu: Control = get_parent().get_node("CommandMenu")

export var main: bool = false

var menuShowed: bool = false

func _ready():
	var musicSlider: Slider 
	var sfxSlider: Slider 
	var tickFullScreen: CheckBox

	if main:
		musicSlider = $MusicSlider
		sfxSlider = $SFXSlider
		tickFullScreen = $checkFullscreen
		
		if SaveManager.load_game():
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), SaveManager.game_data.musicValue);
			musicSlider.value = pow(10, SaveManager.game_data.musicValue / 20)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), SaveManager.game_data.sfxValue);
			sfxSlider.value = pow(10, SaveManager.game_data.sfxValue / 20)
			OS.window_fullscreen = SaveManager.game_data.fullscreen
		else:
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), SaveManager.game_data.musicValue);
			musicSlider.value = pow(10, SaveManager.game_data.musicValue / 20)
			AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), SaveManager.game_data.sfxValue);
			sfxSlider.value = pow(10, SaveManager.game_data.sfxValue / 20)
			OS.window_fullscreen = SaveManager.game_data.fullscreen

	else:
		musicSlider = $OptionMenu/MusicSlider
		sfxSlider = $OptionMenu/SFXSlider
		tickFullScreen = $OptionMenu/checkFullscreen

		var bus_index = AudioServer.get_bus_index("Music")
		var current_volume_db = AudioServer.get_bus_volume_db(bus_index)
		musicSlider.value = pow(10, current_volume_db / 20)

		bus_index = AudioServer.get_bus_index("SFX")
		current_volume_db = AudioServer.get_bus_volume_db(bus_index)
		sfxSlider.value = pow(10, current_volume_db / 20)


func _process(_delta):
	if(main == false):
		var sceneManager = get_parent().get_parent().get_node("StageManager")
		if sceneManager.game_over.visible == false && sceneManager.win.visible == false:
			if (Input.is_action_just_pressed(Global.player1_input[7]) || Input.is_action_just_pressed(Global.player2_input[7])) && !main:
				get_tree().paused = !get_tree().paused
				visible = !visible
				

func _on_ReturnBtn_pressed():
	if main:
		miscMenu.visible = true
		visible = false
		
	else:
		get_tree().paused = !get_tree().paused
		visible = !visible
	
func _on_SFXSlider_value_changed(value: float) -> void:
	var newValue = (log(value) / log(10)) * 20
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), newValue);
	
	SaveManager.game_data.sfxValue = newValue
	SaveManager.save_game()

func _on_MusicSlider_value_changed(value: float) -> void:
	var newValue = (log(value) / log(10)) * 20
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), newValue);
	
	SaveManager.game_data.musicValue = newValue
	SaveManager.save_game()

func _on_checkFullscreen_toggled(_button_pressed: bool) -> void:

	OS.window_fullscreen = !OS.window_fullscreen

	SaveManager.game_data.fullscreen = OS.window_fullscreen
	SaveManager.save_game()

func _on_backToPauseBtn_pressed():
	var mainPauseMenu = get_node("mainPauseMenu")
	mainPauseMenu.visible = true
	optionMenu.visible = false

func _on_OptionBtn_pressed():
	var mainPauseMenu = get_node("mainPauseMenu")
	mainPauseMenu.visible = false
	optionMenu.visible = true

func _on_MainMenuBtn_pressed():
	get_tree().paused = !get_tree().paused
	visible = !visible
	get_tree().change_scene("res://scenes/misc/MainMenu.tscn")

func _on_QuitBtn_pressed():
	get_tree().quit()


func _on_CommandBtn_pressed():
	commandMenu.visible = true
	visible = false


func _on_RestartLevelBtn_pressed():
	var stageManager = get_parent().get_parent().get_child(0)
	get_tree().paused = !get_tree().paused
	get_tree().change_scene("res://scenes/levels/" + Global.dirType + stageManager.current_level + ".tscn")
