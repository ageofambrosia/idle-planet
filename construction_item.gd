extends TextureButton

func _ready():
	set_process(true)

func _pressed():
	get_node("/root/global").addClick()
	var this_thing_name = str(get_node("details").get_parent().get_name())
	get_node("/root/global").addInventory(this_thing_name, 1)
	var s = ''
	if this_thing_name[0].to_upper() in ['A', 'E', 'I', 'O', 'U']:
		s = 'n'
	get_node("/root/global").writeToLog(str('Built a', s, ' ', this_thing_name.replace('_', ' '), '!'))
	get_node("/root/global").log_reset()
	get_parent().get_node("log_line").set_bbcode(str('[center]', get_node("/root/global").getLogLine(), '[/center]'))
	
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'cost'):
		get_node("/root/global").subtractInventory(item["item"], item["value"])
	
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'production'):
		get_node("/root/global").setThingAvailable(item["item"])
	
	if this_thing_name.to_lower() == 'barn':
		get_node("/root/global").increase_capacities(Globals.get("BARN_CAPACITY_MULTIPLIER"), this_thing_name.to_lower())
	if this_thing_name.to_lower() == 'warehouse':
		get_node("/root/global").increase_capacities(Globals.get("WAREHOUSE_CAPACITY_MULTIPLIER"), this_thing_name.to_lower())
	if this_thing_name.to_lower() == 'library':
		get_node("/root/global").increase_capacities(Globals.get("LIBRARY_CAPACITY_MULTIPLIER"), this_thing_name.to_lower())
	if this_thing_name.to_lower() == 'factory':
		get_node("/root/global").multiplyAllBuildingsProduction(Globals.get("FACTORY_PRODUCTION_MULTIPLIER"))
	
	get_node("/root/global").thing_cost_multiplier(this_thing_name)
	
	if this_thing_name.to_lower() == "spaceship":
		var new_node = Label.new() 
		new_node.set_scale(Vector2(3,3))
		new_node.set_text("YOU WON")
		new_node.set_pos(get_viewport().get_rect().size/2)
		get_parent().add_child(new_node)

		get_node("/root/global").writeToLog('YOU WON')

func _process(delta):
	# Do we have the necessary resources for this building?
	var this_thing_name = str(get_node("details").get_parent().get_name())
	var can_afford = true
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'cost'):
		can_afford = can_afford and get_node("/root/global").getThingCount(item["item"]) >= item["value"]
	
	if can_afford:
		get_node("details").get_parent().set_disabled(false)
	else:
		get_node("details").get_parent().set_disabled(true)
	
	var cost_str = ""
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'cost'):
		cost_str = str(cost_str, item['item'].capitalize(), ": ", round(item['value']*100)/100, "\n")
	get_node("details").set_text(str(this_thing_name.replace('_', ' '), "\n", cost_str))
	
	var prod_str = ""
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'production'):
		prod_str = str(prod_str, item['item'].capitalize(), ": +", round(item['value']*100)/100, " / sec\n")
	var note = get_node("/root/global").getThingProperty(this_thing_name, 'notes')
	if note.length() > 0:
		prod_str = str(prod_str, note, "\n")
	get_node("production").set_text(str(prod_str))
	get_node("production").set_pos(get_node("details").get_pos()+Vector2(0,get_node("details").get_size()[1]*0.8))
	
	var cons_str = ""
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'consumption'):
		cons_str = str(cons_str, item['item'].capitalize(), ": -", round(item['value']*100)/100, " / sec\n")
	get_node("consumption").set_text(str(cons_str))
	get_node("consumption").set_pos(get_node("production").get_pos()+Vector2(0,get_node("production").get_size()[1]*0.75))

