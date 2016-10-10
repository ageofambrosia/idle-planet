
extends Control

var accum = 0
var log_accum = 0

func _ready():
	setVisibilities()
	get_node("Resources/Label").set_text(get_node("Resources").get_name())
	get_node("Buildings/Label").set_text(get_node("Buildings").get_name())
	get_node("Workers/Label").set_text(get_node("Workers").get_name())
	
	if has_node("Upgrades"):
		get_node("Upgrades").set_hidden(true)
	
	if has_node("Science"):
		get_node("Science").set_hidden(true)
		
	var children = get_children()
	for child in children:
		if child.has_node('consumption'):
			child.get_node('consumption').add_color_override("font_color", Color(1,0,0))
		if child.has_node('production'):
			child.get_node('production').add_color_override("font_color", Color(0,1,0))
			
	set_process(true)

func _process(delta):
	
	# Remove the "NEW!" flag if we're looking at the right scene
	if get_node("construction_site_button").is_disabled():
		get_node("/root/global").setNewFlag("construction site", false)
	if get_node("basecamp_button").is_disabled():
		get_node("/root/global").setNewFlag("basecamp", false)
		
	get_node("/root/global").setVisibilityAllThings()
	setVisibilities()
	
	# Set the "NEW!" flag on the other scene if necessary
	var children = get_children()
	for child in children:
		if get_node("/root/global").getThingProperty(child.get_name(), 'type') == 'resource':
			child.get_node('details').set_text(str("Get ", child.get_name()))
		if child.has_node("new_label"):
			if get_node("/root/global").getNewFlag(child.get_node('Label').get_text().to_lower()):
				child.get_node("new_label").set_text("NEW!")
				child.get_node("new_label").set_size(Vector2(20,20))
				child.get_node("new_label").add_color_override("font_color", Color(0,1,0))
	
	get_node("workers_label").set_text(str("Workers: ", get_node("/root/global").get_num_workers(), " / ", get_node("/root/global").get_max_workers()))
	
	# Every second (to fix rapid shaking), check if all the resource producing things are working or not and set rates accordingly
	accum += delta
	if accum > 1:
		accum = 0
		get_node("/root/global").setAllWorking()
		get_node("/root/global").setRates()
	
	get_node("/root/global").incrementThings(delta)
	
	# Populate inventory
	var resource_str = ""
	var building_str = ""
	var worker_str = ""
	var things = get_node("/root/global").getThings()
	for item in things["resources"]:
		if get_node("/root/global").getThingAvailable(item["name"]):
			resource_str = str(resource_str, item["name"], ": ", "%s / %2.0f" % [get_node("/root/global").getThingCountStr(item["name"]), get_node("/root/global").getThingProperty(item["name"], 'capacity')], \
							"    (", "%+2.2f" % get_node("/root/global").getThingProperty(item["name"],'rate'), " / sec)", "\n")
	for item in things["buildings"]:
		if get_node("/root/global").getThingAvailable(item["name"]):
			building_str = str(building_str, item["name"], ": ", "%2.0f" % get_node("/root/global").getThingCount(item["name"]), "\n")
	for item in things["workers"]:
		if get_node("/root/global").getThingAvailable(item["name"]):
			worker_str = str(worker_str, item["name"], ": ", "%2.0f" % get_node("/root/global").getThingCount(item["name"]), "\n")
	
	get_node("Resources/inventory").set_text(resource_str)
	get_node("Buildings/inventory").set_text(building_str)
	get_node("Workers/inventory").set_text(worker_str)
	get_node("/root/global").incrementThings(delta)
	
	if get_node("/root/global").getThingCount('water') == 0:
		# KILL ERRYBODY
		get_node("/root/global").killEverybody()
	
	if has_node("Log"):
		get_node("Log/log").clear()
		get_node("Log/log").add_text(str(get_node("/root/global").getLog(), '\n'))
		
	
	if has_node("log_line"):
		get_node("/root/global").log_accum(delta)
		if get_node("/root/global").log_time_get() > 2:
			get_node("log_line").clear()
			get_node("/root/global").log_reset()
	
	# If there's available upgrades, label them
	if has_node("Upgrades"):
		#get_node("Upgrades/details").set_text("")
		for item in things["upgrades"]:
			if get_node("/root/global").getThingAvailable(item["name"]) and get_node("/root/global").getThingProperty(item["name"], 'used') == 0:
				var effect = get_node("/root/global").getThingProperty(item["name"], 'effect')
				var cost = get_node("/root/global").getThingProperty(item["name"], 'cost')
				var lab_str = str("- ", item["name"].capitalize(), ' -\n\n')
				for c in cost:
					lab_str = str(lab_str, c['item'].capitalize(), ": ", cost[0]['value'], "\n")
				for e in effect:
					lab_str = str(lab_str, e['item'].capitalize(), "'s efficiency x ", effect[0]['value'])
				get_node("Upgrades/details").set_text(lab_str)
				get_node("Upgrades").set_hidden(false)
				get_node("/root/global").setUpgradesVisible(true)
				break
		if get_node("/root/global").getUpgradesVisible():
			get_node("upgrades_title").set_text("UPGRADES")
	# If there's available science, label them
	if has_node("Science"):
		get_node("Science/details").set_text("")
		for item in things["science"]:
			if get_node("/root/global").getThingProperty(item["name"], 'type') == 'science' and get_node("/root/global").getThingAvailable(item["name"]) and get_node("/root/global").getThingProperty(item["name"], 'used') == 0:
				var effect = get_node("/root/global").getThingProperty(item["name"], 'effect')
				var cost = get_node("/root/global").getThingProperty(item["name"], 'cost')
				var lab_str = str("- ", item["name"].capitalize(), ' -\n\n')
				for c in cost:
					lab_str = str(lab_str, c['item'].capitalize(), ": ", cost[0]['value'], "\n")
				for e in effect:
					lab_str = str(lab_str, "Allows ", e['item'].capitalize())
				get_node("Science/details").set_text(lab_str)
				get_node("Science").set_hidden(false)
				get_node("/root/global").setScienceVisible(true)
				break
		if get_node("/root/global").getScienceVisible():
			get_node("science_title").set_text("SCIENCE")
	
func setVisibilities():
	var children = get_children()
	for child in children:
		var this_thing_name = child.get_name()
		if not this_thing_name in ['Upgrades', 'Science']:
			if get_node("/root/global").getThingAvailable(this_thing_name):
				get_node(this_thing_name).set_hidden(false)
			else:
				get_node(this_thing_name).set_hidden(true)