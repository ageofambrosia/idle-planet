
extends Control

var accum = 0
var log_accum = 0
var master_accum = 0
var delta_diff = 0
var save_pause = false

func _ready():
	setVisibilities()
	get_node("Resources/Label").set_text(get_node("Resources").get_name())
	get_node("Buildings/Label").set_text(get_node("Buildings").get_name())
	get_node("Workers/Label").set_text(get_node("Workers").get_name())
	
	if has_node("Upgrades"):
		get_node("Upgrades").set_hidden(true)
	if has_node("Upgrades1"):
		get_node("Upgrades1").set_hidden(true)
	if has_node("Upgrades2"):
		get_node("Upgrades2").set_hidden(true)
	if has_node("Science"):
		get_node("Science").set_hidden(true)
	if has_node("Science1"):
		get_node("Science1").set_hidden(true)
	if has_node("Science2"):
		get_node("Science2").set_hidden(true)
		
	var children = get_children()
	for child in children:
		if child.has_node('consumption'):
			child.get_node('consumption').add_color_override("font_color", Color(1,0,0))
		if child.has_node('production'):
			child.get_node('production').add_color_override("font_color", Color(0,1,0))
	set_process(true)

func _process(delta):
	master_accum += delta
	accum += delta
	delta_diff += delta
	if master_accum > 0.1:
		master_accum = 0
		get_node("/root/global").addSecondsPlayed(delta_diff)
		get_node("time_label").set_text(str(get_node("/root/global").getTimePlayed(), '\nClicks: ', get_node("/root/global").getClicks()))
		get_node("/root/global").set_max_workers(get_node("/root/global").getThingCount('shelter') * Globals.get("WORKERS_PER_SHELTER") + 1)
		
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
				else:
					child.get_node("new_label").set_text("")
		
		get_node("workers_label").set_text(str("Workers: ", get_node("/root/global").get_num_workers(), " / ", get_node("/root/global").get_max_workers()))
		
		get_node("/root/global").incrementThings(delta_diff)
		
		# Every second (to fix rapid shaking), check if all the resource producing things are working or not and set rates accordingly
		if accum > 1:
			accum = 0
			get_node("/root/global").setAllWorking()
			get_node("/root/global").setRates()
			var metal_found = get_node("/root/global").metalFound()
			if metal_found >= 1:
				get_node("/root/global").writeToLog(str("Your woodcutters found ", metal_found, " metal!"))
				get_node("/root/global").addInventory('metal', metal_found)
				get_node("/root/global").log_reset()
				if has_node("log_line"):
					get_node("log_line").set_bbcode(str('[center]', get_node("/root/global").getLogLine(), '[/center]'))
		
		get_node("/root/global").setMetalProb(Globals.get("METAL_PROB") * get_node("/root/global").getThingProperty('metal detection', 'count'))
		
		# Populate inventory
		var resource_str = ""
		var building_str = ""
		var worker_str = ""
		var things = get_node("/root/global").getThings()
		for item in things["resources"]:
			if get_node("/root/global").getThingAvailable(item["name"]):
				resource_str = str(resource_str, item["name"].replace('_', ' ').capitalize(), ": ", "%s / %s" % [get_node("/root/global").getThingCountStr(item["name"]), get_node("/root/global").getThingCapacity(item["name"])], \
								"    (", "%+2.2f" % get_node("/root/global").getThingProperty(item["name"],'rate'), " / sec)", "\n")
		for item in things["buildings"]:
			if get_node("/root/global").getThingAvailable(item["name"]):
				building_str = str(building_str, item["name"].replace('_', ' ').capitalize(), ": ", "%2.0f" % get_node("/root/global").getThingCount(item["name"]), "\n")
		for item in things["workers"]:
			if get_node("/root/global").getThingAvailable(item["name"]):
				worker_str = str(worker_str, item["name"].replace('_', ' ').capitalize(), ": ", "%2.0f" % get_node("/root/global").getThingCount(item["name"]), "\n")
		
		get_node("Resources/inventory").set_bbcode(resource_str)
		get_node("Buildings/inventory").set_bbcode(building_str)
		get_node("Workers/inventory").set_bbcode(worker_str)
		
		if get_node("/root/global").getThingCount('water') == 0:
			# KILL ERRYBODY
			get_node("/root/global").killEverybody()
		
		if has_node("Log"):
			get_node("Log/log").clear()
			get_node("Log/log").add_text(str(get_node("/root/global").getLog(), '\n'))
			
		
		if has_node("log_line"):
			get_node("/root/global").log_accum(delta_diff)
			if get_node("/root/global").log_time_get() > 5:
				get_node("log_line").clear()
				get_node("/root/global").log_reset()
		
		# If there's available upgrades, label them
		var curr_node = 'Upgrades'
		var any_upgrades = false
		if has_node("Upgrades"):
			for item in things["upgrades"]:
				if get_node("/root/global").getThingAvailable(item["name"]) and get_node("/root/global").getThingProperty(item["name"], 'used') == 0:
					any_upgrades = true
					var effect = get_node("/root/global").getThingProperty(item["name"], 'effect')
					var cost = get_node("/root/global").getThingProperty(item["name"], 'cost')
					var lab_str = str("- ", item["name"].capitalize(), ' -\n\n')
					for c in cost:
						lab_str = str(lab_str, c['item'].capitalize(), ": ", c['value'], "\n")
					for e in effect:
						lab_str = str(lab_str, e['item'].capitalize(), "'s efficiency x ", e['value'])
					get_node(str(curr_node, "/details")).set_text(lab_str)
					get_node(curr_node).set_hidden(false)
					get_node("/root/global").setUpgradesVisible(true)
					
					if curr_node == 'Upgrades2':
						break
					if curr_node == 'Upgrades1':
						curr_node = 'Upgrades2'
					if curr_node == 'Upgrades':
						curr_node = 'Upgrades1'
						
			if !any_upgrades:
				get_node("Upgrades").set_hidden(true)
				get_node("Upgrades1").set_hidden(true)
				get_node("Upgrades2").set_hidden(true)
				
			if get_node("/root/global").getUpgradesVisible():
				get_node("upgrades_title").set_text("UPGRADES")
	
		
		# If there's available science, label them
		var curr_node = 'Science'
		var any_science = false
		if has_node("Science"):
			get_node("Science/details").set_text("")
			for item in things["science"]:
				if get_node("/root/global").getThingProperty(item["name"], 'type') == 'science' and get_node("/root/global").getThingAvailable(item["name"]) and get_node("/root/global").getThingProperty(item["name"], 'used') == 0:
					any_science = true
					var effect = get_node("/root/global").getThingProperty(item["name"], 'effect')
					var cost = get_node("/root/global").getThingProperty(item["name"], 'cost')
					var lab_str = str("- ", item["name"].capitalize(), ' -\n\n')
					for c in cost:
						lab_str = str(lab_str, c['item'].capitalize(), ": ", c['value'], "\n")
					for e in effect:
						lab_str = str(lab_str, e['item'].capitalize(), "'s efficiency x ", e['value'])
					lab_str = str(lab_str, "\n", item["notes"])
					get_node(str(curr_node, "/details")).set_text(lab_str)
					get_node(curr_node).set_hidden(false)
					get_node("/root/global").setScienceVisible(true)
					if curr_node == 'Science2':
						break
					if curr_node == 'Science1':
						curr_node = 'Science2'
					if curr_node == 'Science':
						curr_node = 'Science1'
						
			if !any_science:
				get_node("Science").set_hidden(true)
				get_node("Science1").set_hidden(true)
				get_node("Science2").set_hidden(true)
				
			if get_node("/root/global").getScienceVisible():
				get_node("science_title").set_text("SCIENCE")
		
		var timeDict = OS.get_time();
		var minute = timeDict.minute;
		var second = timeDict.second;
		if minute % 5 == 0 and second == 0 and not save_pause:
			save_pause = true
			get_node("/root/global").savegame()
		if minute % 5 == 0 and second == 1:
			save_pause = false
		delta_diff = 0
	
func setVisibilities():
	var children = get_children()
	for child in children:
		var this_thing_name = child.get_name()
		if not this_thing_name in ['Upgrades', 'Upgrades1', 'Upgrades2', 'Science', 'Science1', 'Science2']:
			if get_node("/root/global").getThingAvailable(this_thing_name):
				get_node(this_thing_name).set_hidden(false)
			else:
				get_node(this_thing_name).set_hidden(true)