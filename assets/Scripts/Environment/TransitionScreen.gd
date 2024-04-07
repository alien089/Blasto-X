extends CanvasLayer

signal black_screen

func transition():
	$AnimationPlayer.play("fade_to_black")

func notifySceneManager():
	emit_signal("black_screen")

func _on_StageManager_fading():
	transition()
