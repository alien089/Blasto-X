class_name VineSpear
extends Node2D

onready var sprite: Sprite = $Sprite
onready var anim_player : AnimationPlayer = $AnimationPlayer
onready var collision_shape : CollisionShape2D = $HitBox/CollisionShape2D

export(int) var dps = 1

var initialFrame = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	anim_player.play("growth")
	collision_shape.disabled = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if sprite.frame == initialFrame + 1:
		collision_shape.disabled = false
	if anim_player.current_animation != "growth":
		queue_free()
	

func _on_HitBox_body_entered(body:Node):
	(body as Player).hit(dps, "spear", self)
	queue_free()
