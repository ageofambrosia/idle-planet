extends TextureButton

func _ready():
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("details").set_text(this_thing_name)
	set_process(true)

func _pressed():
	get_node("/root/global").addClick()
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("/root/global").addInventory(this_thing_name, 1)
	get_node("/root/global").writeToLog(str('Hired a ', this_thing_name.replace('_', ' '), '!'))
	get_node("/root/global").log_reset()
	get_parent().get_node("log_line").set_bbcode(str('[center]', get_node("/root/global").getLogLine(), '[/center]'))
	
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'cost'):
		get_node("/root/global").subtractInventory(item["item"], item["value"])
	
	get_node("/root/global").thing_cost_multiplier(this_thing_name)

func _process(delta):
	var this_thing_name = str(get_node("details").get_parent().get_name())
	var can_afford = true
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'cost'):
		can_afford = can_afford and get_node("/root/global").getThingCount(item["item"]) >= item["value"]
	
	can_afford = can_afford and get_node("/root/global").get_num_workers() < get_node("/root/global").get_max_workers()
	
	if can_afford:
		get_node("details").get_parent().set_disabled(false)
	else:
		get_node("details").get_parent().set_disabled(true)
	
	var cost_str = ""
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'cost'):
		cost_str = str(cost_str, item['item'].capitalize(), ": ", round(item['value']*100)/100, "\n")
	get_node("details").set_text(str(this_thing_name, "\n", cost_str))
	
	var prod_str = ""
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'production'):
		prod_str = str(prod_str, item['item'].capitalize(), ": +", round(item['value']*100)/100, " / sec\n")
	get_node("production").set_text(str(prod_str))
	get_node("production").set_pos(get_node("details").get_pos()+Vector2(0,get_node("details").get_size()[1]*0.8))
	
	var cons_str = ""
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'consumption'):
		cons_str = str(cons_str, item['item'].capitalize(), ": -", round(item['value']*100)/100, " / sec\n")
	get_node("consumption").set_text(str(cons_str))
	get_node("consumption").set_pos(get_node("production").get_pos()+Vector2(0,get_node("production").get_size()[1]*0.8))