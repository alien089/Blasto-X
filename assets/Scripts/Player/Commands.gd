extends Sprite

func _on_StaticBody2D_area_entered(_area):
	if _area.owner.is_in_group("player"):
		visible = false
