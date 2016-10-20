
extends Button

# member variables here, example:
# var a=2
# var b="textvar"

func _ready():
	pass

func _pressed():
	get_node("/root/global").savegame()