class_name ImpactZone
extends Position2D

onready var timer: Timer = $Timer
onready var impactArea: Sprite = $Sprite
onready var collider: CollisionShape2D = $Area2D/CollisionShape2D
onready var area: Area2D = $Area2D
onready var anim_player: AnimationPlayer = $AnimationPlayer
onready var sprite: Sprite = $Sprite
onready var explosion: Sprite = $explosion

export(int) var delay_explosion = 5
export(Array, StreamTexture) var impact_states

var damage: int

func _ready():
	timer.wait_time = delay_explosion
	area.monitoring = false
	area.monitorable = false

func _process(delta):
	if timer.time_left <= timer.wait_time/impact_states.size():
		sprite.texture = impact_states[2]
	elif timer.time_left <= (timer.wait_time/impact_states.size()) * 2:
		sprite.texture = impact_states[1]
	else:
		sprite.texture = impact_states[0]
		
func explode():
	collider.disabled = false
	area.monitoring = true
	area.monitorable = true

func activate(_damage):
	damage = _damage
	impactArea.visible = true
	timer.start()

func _on_Timer_timeout():
	anim_player.play("explosion")
	impactArea.visible = false


func _on_AnimationPlayer_animation_finished(anim_name:String):
	if anim_name == "explosion":
		custom_queue_free()


func _on_Area2D_area_entered(area:Area2D):
	if area.is_in_group("granade") && anim_player.current_animation == "explosion":
		var player = area.owner
		player.hit(damage, "melee", self)
		custom_queue_free()


func custom_queue_free():
	area.monitoring = false
	area.monitorable = false
	impactArea.visible = false
	explosion.visible = false
	collider.disabled = true
	anim_player.stop()
	timer.stop()
