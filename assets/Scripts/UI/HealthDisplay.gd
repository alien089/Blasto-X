extends Node2D

onready var healthbar = $HealthBar

func update_healthbar(amount):
	healthbar.value = healthbar.value - amount
	

func set_healtbar(value):
	healthbar.value = value
	
