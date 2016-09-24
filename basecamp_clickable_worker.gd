extends TextureButton

func _ready():
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("details").set_text(this_thing_name)
	
	set_process(true)

func _pressed():
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("/root/global").addInventory(this_thing_name, 1)
	
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
	
	cost_str = str(cost_str, "\n")
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'production'):
		cost_str = str(cost_str, item['item'].capitalize(), ": +", round(item['value']*100)/100, " / sec\n")
	
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'consumption'):
		cost_str = str(cost_str, item['item'].capitalize(), ": -", round(item['value']*100)/100, " / sec\n")
	
	get_node("details").set_text(str(this_thing_name, ": ", get_node("/root/global").getThingCount(this_thing_name), "\n\n", cost_str))