class_name Rifle
extends TurianWeapon

export(int) var numberOfBullets
export(float) var shootingAmplitude

func shoot(player):
	var deltaAngle = shootingAmplitude/(numberOfBullets -1)
	var playerRef := player as Player
	var direction = playerRef.global_position - position2d.get_global_position()
	var numerator = (direction.x * direction.y + playerRef.global_position.x * playerRef.global_position.y)
	var denominator = (sqrt(powFunctionSum(direction.x, direction.y, 2)) *sqrt( powFunctionSum(playerRef.global_position.x, playerRef.global_position.y, 2)))
	var angle = numerator / denominator
	var i = 0
	for n in numberOfBullets:
		var bullet_instance = bullet.instance()
		var angleOffset = shootingAmplitude/2 - deltaAngle * i
		bullet_instance.rotate(deg2rad(angle + angleOffset))
		bullet_instance.direction = -Vector2(cos(bullet_instance.rotation), sin(bullet_instance.rotation))
		get_parent().get_parent().get_parent().get_parent().get_parent().add_child(bullet_instance)
		bullet_instance.set_global_position(position2d.get_global_position())
		i+=1


func powFunctionSum(value1 : float, value2 : float, base : float) -> float:
	return (pow(value1, base) + pow(value2, base))
