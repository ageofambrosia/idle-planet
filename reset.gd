
extends Button

# member variables here, example:
# var a=2
# var b="textvar"

var new_popup = PopupMenu.new()

func _ready():
	add_child(new_popup)
	new_popup.set_size(get_viewport().get_rect().size/10)
	new_popup.set_pos(get_viewport().get_rect().size/6)
	new_popup.add_item('Are you sure? You will lose all your things!',0)
	new_popup.add_item('You\'ll also be awarded an efficiency bonus on all production of:',1)
	new_popup.add_item('  15% x number of shelters\n\n',2)
	new_popup.add_item(str("Your current production multiplier would be: ", 1 + (Globals.get('RESET_BONUS') * get_node("/root/global").getThingCount('shelter'))),3)
	new_popup.add_separator()
	new_popup.add_item('Yes',4)
	new_popup.add_item('No',5)
	new_popup.set_item_disabled(0,true)
	new_popup.set_item_disabled(1,true)
	new_popup.set_item_disabled(2,true)
	new_popup.set_item_disabled(3,true)
	pass

func _pressed():
	new_popup.show()
	new_popup.connect("item_pressed", self, "_my_button_pressed")

func _my_button_pressed(id):
	if id == 4:
		get_node("/root/global").reset()