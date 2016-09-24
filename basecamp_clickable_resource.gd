extends TextureButton

func _ready():
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("details").set_text(this_thing_name)
	set_process(true)

func _pressed():
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("/root/global").writeToLog(str('Picked up ', this_thing_name, '!'))
	get_node("/root/global").addInventory(this_thing_name, 1)