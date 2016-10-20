extends TextureButton

func _ready():
	set_process(true)

func _pressed():
	get_node("/root/global").addClick()
	var expr = RegEx.new()
	var re = "\\- ([a-z_ ]*) \\-"
	expr.compile(re)
	var this_thing_name = expr.get_capture(expr.find(get_node("details").get_text().to_lower())+1)
	
	if this_thing_name.to_lower() == 'chemistry':
		get_node("/root/global").add_production('gatherer', 'alien dung', 0.01)
		
	var effects = get_node("/root/global").getThingProperty(this_thing_name, 'effect')
	for effect in effects:
		if 'value' in effect.keys():
			var produces = get_node("/root/global").getThingProperty(effect['item'], 'production')
			for produce in produces:
				if produce['item'] != 'waste':
					get_node("/root/global").multiplyThingProduction(effect['item'], produce['item'], effect['value'])
	get_node("/root/global").addInventory(this_thing_name, 1)

	get_node("/root/global").setThingUnavailable(this_thing_name)
	get_node("/root/global").setThingUsed(this_thing_name)
	get_node(".").set_hidden(true)
	
	for item in get_node("/root/global").getThingProperty(this_thing_name, 'cost'):
		get_node("/root/global").subtractInventory(item["item"], item["value"])
	
	get_node("/root/global").writeToLog(str('Upgraded to ', this_thing_name, '!'))
	get_node("/root/global").log_reset()
	get_parent().get_node("log_line").set_bbcode(str('[center]', get_node("/root/global").getLogLine(), '[/center]'))

func _process(delta):
	var expr = RegEx.new()
	var re = "\\- ([a-z _]*) \\-"
	expr.compile(re)
	var this_thing_name = expr.get_capture(expr.find(get_node("details").get_text().to_lower())+1)
	if not this_thing_name.empty():
		var can_afford = true
		for item in get_node("/root/global").getThingProperty(this_thing_name, 'cost'):
			can_afford = can_afford and get_node("/root/global").getThingCount(item["item"]) >= item["value"]
		
		if can_afford:
			get_node("details").get_parent().set_disabled(false)
		else:
			get_node("details").get_parent().set_disabled(true)