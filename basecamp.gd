
extends Control

var accum = 0

func _ready():
	setVisibilities()
	get_node("Resources/Label").set_text(get_node("Resources").get_name())
	get_node("Buildings/Label").set_text(get_node("Buildings").get_name())
	get_node("Workers/Label").set_text(get_node("Workers").get_name())
	
	var children = get_children()
	for child in children:
		if child.has_node('consumption'):
			child.get_node('consumption').add_color_override("font_color", Color(1,0,0))
		if child.has_node('production'):
			child.get_node('production').add_color_override("font_color", Color(0,1,0))
	set_process(true)

func _process(delta):
	
	if get_node("construction_site_button").is_disabled():
		get_node("/root/global").setNewFlag("construction site", false)
	if get_node("basecamp_button").is_disabled():
		get_node("/root/global").setNewFlag("basecamp", false)
		
	accum += delta
	get_node("/root/global").setVisibilityAllThings()
	setVisibilities()
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
	if accum > 1:
		accum = 0
		get_node("/root/global").setAllWorking()
	
	get_node("/root/global").incrementThings(delta)
	get_node("/root/global").setRates()
	
	# Populate inventory
	var resource_str = ""
	var building_str = ""
	var worker_str = ""
	var things = get_node("/root/global").getThings()
	for item in things:
		if item["type"] == "resource":
			resource_str = str(resource_str, item["name"], ": ", "%2.1f" % get_node("/root/global").getThingCount(item["name"]), \
								"    (", "%+2.2f" % get_node("/root/global").getThingProperty(item["name"],'rate'), " / sec)", "\n")
		if item["type"] == "building":
			building_str = str(building_str, item["name"], ": ", get_node("/root/global").getThingCount(item["name"]), "\n")
		if item["type"] == "worker":
			worker_str = str(worker_str, item["name"], ": ", get_node("/root/global").getThingCount(item["name"]), "\n")
	
	get_node("Resources/inventory").set_text(resource_str)
	get_node("Buildings/inventory").set_text(building_str)
	get_node("Workers/inventory").set_text(worker_str)
	get_node("/root/global").incrementThings(delta)
	
	if get_node("/root/global").getThingCount('water') == 0:
		# KILL ERRYBODY
		get_node("/root/global").killEverybody()
	
	if has_node("Log"):
		get_node("Log/log").set_text(get_node("/root/global").getLog())
	
	
func setVisibilities():
	var children = get_children()
	for child in children:
		var this_thing_name = child.get_name()
		if get_node("/root/global").getThingAvailable(this_thing_name):
			get_node(this_thing_name).set_hidden(false)
		else:
			get_node(this_thing_name).set_hidden(true)