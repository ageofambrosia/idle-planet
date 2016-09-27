extends Button

func _ready():
	pass

func _pressed():
	get_node("/root/global").setNewFlag(get_node("Label").get_text().to_lower(), false)
	get_node("/root/global").setScene(str("res://", get_node("Label").get_text().to_lower(), ".tscn"))