extends Node

#The currently active scene
var currentScene = null
var max_workers = 1
var things_original = ""
var deps_original = ""
var things = ""
var deps = ""
var log_str = Array()
var new = {"basecamp": false, "construction site": false}
var log_accum = 0
var upgrades_visible = false
var science_visible = false
var cost_multiplier_dev = 1
var num_resets = 0
var vals = [1e24, 1e21, 1e18, 1e15, 1e12, 1e9, 1e6, 1e3]
var units = ['Y', 'Z', 'E', 'P', 'T', 'B', 'M', 'k']
var rate_mult = 1
var metal_prob = 0
var metal_max = -1
var seconds_played = 0
var clicks = 0

func _ready():
	randomize()
	
	if num_resets == 0:
		things_original = get_node("/root/global").readThings("res://things.json")
	
	var savegame = File.new()
	if savegame.file_exists("user://savegame.save"):
		things = get_node("/root/global").readThings("user://savegame.save")
	else:
		things = get_node("/root/global").readThings("res://things.json")

	if savegame.file_exists("user://time.save"):
		var file = File.new()
		file.open("user://time.save", file.READ)
		seconds_played = str2var(str(file.get_as_text()))

	if savegame.file_exists("user://clicks.save"):
		var file = File.new()
		file.open("user://clicks.save", file.READ)
		clicks = str2var(str(file.get_as_text()))

	deps = get_node("/root/global").getDependencies()
	
	get_node("/root/global").mult_costs()
	get_node("/root/global").setVisibilityAllThings()
	#On load set the current scene to the last scene available
	currentScene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
	
	setMetalMax(getThingProperty('metal', 'capacity')/2)
	
	Globals.set("WORKERS_PER_SHELTER", 2)
	Globals.set("BARN_CAPACITY_MULTIPLIER", 1.5)
	Globals.set("WAREHOUSE_CAPACITY_MULTIPLIER", 2)
	Globals.set("LIBRARY_CAPACITY_MULTIPLIER", 1.1)
	Globals.set("FACTORY_PRODUCTION_MULTIPLIER", 1.05)
	Globals.set("COST_MULTIPLIER", 1.15)
	Globals.set("RESET_BONUS", 0.15)
	Globals.set("METAL_PROB", 0.01)
   
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
	
func setMetalProb(val):
	metal_prob = val
	
func setMetalMax(val):
	metal_max = val

func metalFound():
	var amount_found = rand_range(1, metal_max)
	var did_find = rand_range(0, 1) > (1 - metal_prob)
	if did_find:
		return round(amount_found)
	else:
		return 0

func addSecondsPlayed(val):
	seconds_played += val

func addClick():
	clicks += 1

func getTimePlayed():
	var s = seconds_played
	var m = floor(s / 60)
	var h = floor(m / 60)
	
	m = int(m) % 60
	s = int(s) % 60
	return str('Playing time: %02d:%02d:%02d' % [h, m, s])

func getSecondsPlayed():
	return(seconds_played)

func getHoursPlayed():
	return(floor(seconds_played/60/60))

func getClicks():
	return clicks

func reset():
	num_resets += 1
	# One bonus multiplier for each hour played
	rate_mult = 1 + Globals.get('RESET_BONUS') * getHoursPlayed()
	get_node("/root/global").writeToLog(str("Reset game! Your bonus efficiency multiplier is now ", rate_mult))
	things = str2var( var2str( things_original ) )
	for thinggroup in ['workers', 'buildings']:
		for i in range(0, things[thinggroup].size()):
			for j in range(0, things[thinggroup][i]['production'].size()):
				if things[thinggroup][i]['production'][j]['item'] != 'waste':
					things[thinggroup][i]['production'][j]['value'] *= rate_mult
	get_node("/root/global").mult_costs()
	get_node("/root/global").setUpgradesVisible(false)
	get_node("/root/global").setScienceVisible(false)

func hard_reset():
	num_resets = 0
	clicks = 0
	seconds_played = 0
	var savegame = Directory.new()
	savegame.remove("user://savegame.save")
	savegame.remove("user://time.save")
	savegame.remove("user://clicks.save")
	get_node("/root/global").setUpgradesVisible(false)
	get_node("/root/global").setScienceVisible(false)
	get_node("/root/global")._ready()

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

func setRate(thing_name, amount):
	for i in range(0, things["resources"].size()):
		if things["resources"][i]["name"] == thing_name.to_lower():
			things["resources"][i]["rate"] = amount

func savegame():
	var savedir = Directory.new()
	savedir.remove("user://savegame.save")
	savedir.remove("user://time.save")
	var savegame = File.new()
	savegame.open("user://savegame.save", File.WRITE)
	var things = get_node("/root/global").getThings()
	things = var2str(things)
	savegame.store_string(things);
	savegame.close()
	
	savegame.open("user://time.save", File.WRITE)
	var tmp = var2str(seconds_played)
	savegame.store_string(tmp);
	savegame.close()
	
	savegame.open("user://clicks.save", File.WRITE)
	var tmp = var2str(clicks)
	savegame.store_string(tmp);
	savegame.close()
	
	get_node("/root/global").writeToLog('Game saved!')
	
func setRates():
	for item in things["resources"]:
		get_node("/root/global").setRate(item['name'], 0)
		
	for thinggroup in ["buildings", "workers"]:
		for item in things[thinggroup]:
			if get_node("/root/global").getThingProperty(item['name'], 'working') == 1:
				for prod in item['production']:
					get_node("/root/global").alterRate(prod['item'], prod['value'] * get_node("/root/global").getThingCount(item['name']))
			for con in item['consumption']:
					get_node("/root/global").alterRate(con['item'], -(con['value'] * get_node("/root/global").getThingCount(item['name'])))

func killEverybody():
	for i in range(0, things["workers"].size()):
		if things["workers"][i]["name"] != 'you':
			things["workers"][i]["count"] = 0
	
	get_node("/root/global").writeToLog(str('You ran out of water! EVERYBODY (except you) DIED!'))

func setAllWorking():
	for thinggroup in ['buildings', 'workers']:
		for item in things[thinggroup]:
			for con in item['consumption']:
				if get_node("/root/global").getThingProperty(item['name'], 'is_visible') and get_node("/root/global").getThingCount(con['item']) <= con['value']:
					get_node("/root/global").setWorking(item['name'], 0)
					break
				else:
					get_node("/root/global").setWorking(item['name'], 1)
					

func incrementThings(delta):
	for item in things["resources"]:
		var rate = get_node("/root/global").getThingProperty(item['name'], 'rate')
		get_node("/root/global").addInventory(item['name'], rate * delta)

func setUpgradesVisible(b):
	upgrades_visible = b
	
func getUpgradesVisible():
	return upgrades_visible
	
func setScienceVisible(b):
	science_visible = b
	
func getScienceVisible():
	return science_visible

func mult_costs():
	for thinggroup in things.keys():
		for i in range(0, things[thinggroup].size()):
			if "cost" in things[thinggroup][i].keys():
				for j in range(0, things[thinggroup][i]["cost"].size()):
					things[thinggroup][i]["cost"][j]["value"] *= cost_multiplier_dev

func getThingProperty(thing_name, property):
	for thinggroup in things.keys():
		for item in things[thinggroup]:
			if item["name"] == thing_name.to_lower():
				if property in item.keys():
					return item[property]
	
	return null

func add_production(worker, production_item, rate):
	get_node("/root/global").setThingAvailable(production_item)
	for item in things['workers']:
		if item["name"] == worker.to_lower():
			var new_item = {'item': production_item, 'value': rate}
			item["production"].push_back(new_item)

func multiplyAllBuildingsProduction(mult):
	for i in range(0, things["buildings"].size()):
		for j in range(0, things["buildings"][i]["production"].size()):
			things["buildings"][i]["production"][j]["value"] *= mult

func multiplyThingProduction(producer, produce, mult):
	for thinggroup in ["workers", "buildings"]:
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == producer:
				for j in range(0, things[thinggroup][i]["production"].size()):
					if things[thinggroup][i]["production"][j]["item"] == produce:
						things[thinggroup][i]["production"][j]["value"] *= mult

func getThingCapacity(thing_name):
	for thinggroup in things.keys():
		for item in things[thinggroup]:
			if item["name"] == thing_name.to_lower():
				var curr_val = round(item['capacity']*10)/10
				var s = ""
				for i in range(0, vals.size()):
					if curr_val > vals[i]:
						s = str('%2.1f' % (round(10*curr_val/vals[i])/10), units[i])
						return s
				
				s = str('%2.1f' % curr_val)
				return s
	
	return 0

func getThingCountStr(thing_name):
	for thinggroup in things.keys():
		for item in things[thinggroup]:
			if item["name"] == thing_name.to_lower():
				var curr_val = round(item['count']*10)/10
				var s = ""
				for i in range(0, vals.size()):
					if curr_val > vals[i]:
						s = str('%2.1f' % (round(10*curr_val/vals[i])/10), units[i])
						return s
				
				s = str('%2.1f' % curr_val)
				return s
	
	return 0
	
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
	if amount < 0:
		get_node("/root/global").subtractInventory(thing_name, -amount)
	else :
		for thinggroup in things.keys():
			for i in range(0, things[thinggroup].size()):
				if things[thinggroup][i]["name"] == thing_name.to_lower():
					var cap = get_node("/root/global").getThingProperty(things[thinggroup][i]["name"], 'capacity')
					if typeof(cap) == TYPE_NIL:
						cap = 3e38
					if things[thinggroup][i]["count"] >= cap:
						things[thinggroup][i]["count"] = cap
					else:
						things[thinggroup][i]["count"] += amount

func subtractInventory(thing_name, amount):
	for thinggroup in things.keys():
		for i in range(0, things[thinggroup].size()):
			if things[thinggroup][i]["name"] == thing_name.to_lower():
				if things[thinggroup][i]["count"] <= 0:
					things[thinggroup][i]["count"] = 0
				else:
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

func readThings(savefile):
	var file = File.new()
	file.open(savefile, file.READ)
	var content =  str(file.get_as_text())
	var things = Dictionary()
	things.parse_json(content)
	return(things)

func getThings():
	return things

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

func increase_capacities(mult, building_name):
	for i in range(0, things['resources'].size()):
		if building_name in ['barn', 'warehouse']:
			if !things['resources'][i]['name'] == 'science':
				things['resources'][i]['capacity'] *= mult
		if building_name == 'library':
			if things['resources'][i]['name'] == 'science':
				things['resources'][i]['capacity'] *= mult
	setMetalMax(getThingProperty('metal', 'capacity')/2)

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
	log_str.push_back("%02d:%02d:%02d - %s" % [hour, minute, second, text])

func getLog():
	var text = ""
	if log_str.size() > 0:
		text = log_str[log_str.size() - 1]
		for i in range(1, min(500,log_str.size())):
			text = str(text, "\n", log_str[log_str.size() - i - 1])
	else:
		text = ""
		
	return text

func getLogLine():
	var text = ""
	text = str(log_str[log_str.size() - 1])
	
	return text
	