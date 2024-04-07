extends Node

const save_path = "user://save_data.save"
var game_data = {}

func _process(delta):
	pass

func save_game():
	var file = File.new()
	file.open(save_path, File.WRITE)
	file.store_var(game_data)
	file.close()


func load_game() -> bool:
	var file = File.new()
	if file.file_exists(save_path):
		file.open(save_path, File.READ)
		game_data = file.get_var()
		file.close()
		return true
	else:
		game_data = {
			"stage_saved": "",
			"isMultiplayer": false,
			"musicValue": -10.5,
			"sfxValue": -10.5,
			"fullscreen": false,
			"lastScore": 0,
			"highScore": 0
		}
		return false
