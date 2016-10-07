extends Node

#The currently active scene
var currentScene = null
var max_workers = 1
var things = ""
var deps = ""
var log_str = Array()
var new = {"basecamp": false, "construction site": false}
var log_accum = 0
var upgrades_visible = false
var science_visible = false

func _ready():
	things = get_node("/root/global").getThings()
	deps = get_node("/root/global").getDependencies()
	
	get_node("/root/global").setVisibilityAllThings()
	#On load set the current scene to the last scene available
	currentScene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
	
	Globals.set("WORKERS_PER_SHELTER", 2)
	Globals.set("COST_MULTIPLIER", 1.15)
   
# create a function to switch between scenes 
func setScene(scene):
   #clean up the current scene
   currentScene.queue_free()
   #load the file passed in as the param "scene"
   var s = ResourceLoader.load(scene)
   #create an instance of our scene
   currentScene = s.instance()
   # add scene to root
   get_tree().get_root().add_child(currentScene)
 
func log_accum(delta):
	log_accum += delta

func log_time_get():
	return(log_accum)
	
func log_reset():
	log_accum = 0

func getNewFlag(scene_name):
	return new[scene_name]

func setNewFlag(scene_name, value):
	new[scene_name] = value

func setVisibilityAllThings():
	for depgroup in deps.keys():
		for item in deps[depgroup]:
			var this_thing_name = item['name']
			var this_thing_deps = item['dependencies']
			var thing_is_visible = false
			for dep in this_thing_deps:
				if get_node("/root/global").getThingCount(dep["item"]) >= dep['value']:
					thing_is_visible = true
				else:
					thing_is_visible = false
					break
				
			if thing_is_visible:
				if get_node("/root/global").getThingAvailable(this_thing_name) == false:
					if depgroup == 'buildings':
						get_node("/root/global").setNewFlag('construction site', true)
					else:
						get_node("/root/global").setNewFlag('basecamp', true)
				get_node("/root/global").setThingAvailable(this_thing_name)

func alterRate(thing_name, amount):
	for i in range(0, things["resources"].size()):
		if things["resources"][i]["name"] == thing_name.to_lower():
			things["resources"][i]["rate"] += amount

func setRates():
	for item in things["resources"]:
		get_node("/root/global").alterRate(item['name'], -get_node("/root/global").getThingProperty(item['name'], 'rate'))
		
	for item in things["buildings"]:
		if get_node("/root/global").getThingCount(item['name']) > 0 and get_node("/root/global").getThingProperty(item['name'], 'working') == 1:
			for con in item['consumption']:
				get_node("/root/global").alterRate(con['item'], -(con['value'] * get_node("/root/global").getThingCount(item['name'])))
			for prod in item['production']:
				get_node("/root/global").alterRate(prod['item'], prod['value'] * get_node("/root/global").getThingCount(item['name']))
	
	for item in things["workers"]:
		if get_node("/root/global").getThingCount(item['name']) > 0 and get_node("/root/global").getThingProperty(item['name'], 'working') == 1:
			for con in item['consumption']:
				get_node("/root/global").alterRate(con['item'], -(con['value'] * get_node("/root/global").getThingCount(item['name'])))
			for prod in item['production']:
				get_node("/root/global").alterRate(prod['item'], prod['value'] * get_node("/root/global").getThingCount(item['name']))

func killEverybody():
	for i in range(0, things["workers"].size()):
		things["workers"][i]["count"] = 0
	
	get_node("/root/global").writeToLog(str('You ran out of water! Everybody DIIIEEEED!'))

func setAllWorking():
	for item in things["buildings"]:
		for con in item['consumption']:
			if get_node("/root/global").getThingCount(con['item']) <= 0:
				get_node("/root/global").setWorking(item['name'], 0)
			else:
				get_node("/root/global").setWorking(item['name'], 1)

	for item in things["workers"]:
		for con in item['consumption']:
			if get_node("/root/global").getThingCount(con['item']) <= 0:
				get_node("/root/global").setWorking(item['name'], 0)
			else:
				get_node("/root/global").setWorking(item['name'], 1)

func incrementThings(delta):
	for item in things["resources"]:
		if get_node("/root/global").getThingCount(item['name']) < 0:
			get_node("/root/global").setInventory(item['name'], 0)
		get_node("/root/global").addInventory(item['name'], get_node("/root/global").getThingProperty(item['name'], 'rate') * delta)
		if get_node("/root/global").getThingCount(item['name']) > get_node("/root/global").getThingProperty(item['name'], 'capacity'):
			get_node("/root/global").setInventory(item['name'], get_node("/root/global").getThingProperty(item['name'], 'capacity'))

func setUpgradesVisible(b):
	upgrades_visible = b
	
func getUpgradesVisible():
	return upgrades_visible
	
func setScienceVisible(b):
	science_visible = b
	
func getScienceVisible():
	return science_visible

func getThingProperty(thing_name, property):
	for thinggroup in things.keys():
		for item in things[thinggroup]:
			if item["name"] == thing_name.to_lower():
				return item[property]
	
	return null

func multiplyThingProduction(producer, produce, mult):
	for thinggroup in ["workers", "buildings"]:
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == producer:
				for j in range(0, things[thinggroup][i]["production"].size()):
					if things[thinggroup][i]["production"][j]["item"] == produce:
						things[thinggroup][i]["production"][j]["value"] *= mult

func getThingCount(thing_name):
	for thinggroup in things.keys():
		for item in things[thinggroup]:
			if item["name"] == thing_name.to_lower():
				return round(item['count']*10)/10
	
	return 0

func getThingAvailable(thing_name):
	for thinggroup in things.keys():
		for item in things[thinggroup]:
			if item["name"] == thing_name.to_lower():
				return item['is_visible']
	
	return 1
	
func setThingAvailable(thing_name):
	for thinggroup in things.keys():
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == thing_name.to_lower():
				things[thinggroup][i]["is_visible"] = 1

func setThingUnavailable(thing_name):
	for thinggroup in things.keys():
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == thing_name.to_lower():
				things[thinggroup][i]["is_visible"] = 0

func setThingUsed(thing_name):
	for thinggroup in ["upgrades", "science"]:
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == thing_name.to_lower():
				things[thinggroup][i]["used"] = 1

func addInventory(thing_name, amount):
	for thinggroup in things.keys():
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == thing_name.to_lower():
				things[thinggroup][i]["count"] += amount

func subtractInventory(thing_name, amount):
	for thinggroup in things.keys():
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == thing_name.to_lower():
				things[thinggroup][i]["count"] -= amount

func setInventory(thing_name, amount):
	for thinggroup in things.keys():
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == thing_name.to_lower():
				things[thinggroup][i]["count"] = amount

func setWorking(thing_name, value):
	for thinggroup in ["workers", "buildings"]:
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == thing_name.to_lower():
				things[thinggroup][i]["working"] = value

func getThings():
	var file = File.new()
	file.open("res://things.json", file.READ)
	var content =  str(file.get_as_text())
	var things = Dictionary()
	things.parse_json(content)
	return(things)

func getDependencies():
	var file = File.new()
	file.open("res://dependencies.json", file.READ)
	var content =  str(file.get_as_text())
	var deps = Dictionary()
	deps.parse_json(content)
	return(deps)
	
func get_max_workers():
	return max_workers

func set_max_workers(N):
	max_workers = N

func get_num_workers():
	var N = 0
	for item in things["workers"]:
		N += item['count']
	
	return N

func thing_cost_multiplier(thing_name):
	for thinggroup in ["workers", "buildings"]:
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]['name'] == thing_name.to_lower():
				for j in range(0, things[thinggroup][i]['cost'].size()):
					things[thinggroup][i]['cost'][j]['value'] *= Globals.get("COST_MULTIPLIER")

func writeToLog(text):
	var timeDict = OS.get_time();
	var hour = timeDict.hour;
	var minute = timeDict.minute;
	var second = timeDict.second;
	log_str.push_back(str(hour, ":", minute, ":", second, " - ", text))

func getLog():
	var text
	if log_str.size() > 0:
		var text = log_str[log_str.size() - 1]
		for i in range(1, min(100,log_str.size())):
			text = str(text, "\n", log_str[log_str.size() - i - 1])
	else:
		var text = ""
	
	return text

func getLogLine():
	var text = ""
	text = str(log_str[log_str.size() - 1])
	
	return text