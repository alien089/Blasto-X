class_name BulletRifle
extends Node2D

var velocity = Vector2.ZERO
var direction

export(int) var speed: int = 700
export(int) var damage: int = 1
export(String) var target

func _process(delta: float) -> void:
	velocity = speed * delta
	
	position += velocity * direction

func _on_Timer_timeout():
	queue_free()


func _on_BulletArea_body_entered(body:Node):
	if body.is_in_group(target):
		var enemy = body as Player
		enemy.hit(damage, "melee", self)
		$BulletArea.monitorable = false
		queue_free()
