extends TextureButton

func _ready():
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("details").set_text(this_thing_name)
	set_process(true)

func _pressed():
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("/root/global").writeToLog(str('Picked up ', this_thing_name.replace('_', ' '), '!'))
	get_node("/root/global").addInventory(this_thing_name, 1)
	get_node("/root/global").log_reset()
	get_parent().get_node("log_line").set_bbcode(str('[center]', get_node("/root/global").getLogLine(), '[/center]'))