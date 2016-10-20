
extends Button

# member variables here, example:
# var a=2
# var b="textvar"

var new_confirm = ConfirmationDialog.new()

func _ready():
	add_child(new_confirm)
	new_confirm.set_title("Are you sure?")
	if get_text() == 'REBOOT SHIP':
		new_confirm.set_text(str("You will lose all your things!\n\nBUT! You\'ll also be awarded an efficiency bonus on all production!\n\n", "Your current production multiplier would be: ", 1 + Globals.get('RESET_BONUS') * get_node("/root/global").getHoursPlayed(), "\n"))
	else:
		new_confirm.set_text(str("This will TOTALLY reset the game.\n\nYou will get ZERO bonuses and any saved progess will be lost!\n"))
	new_confirm.set_pos(Vector2(100,200))

func _pressed():
	new_confirm.show()
	new_confirm.connect("confirmed", self, "_my_button_pressed")

func _my_button_pressed():
	get_node("/root/global").setNewFlag('construction site', false)
	get_node("/root/global").setNewFlag('basecamp', false)
	if get_text() == 'REBOOT SHIP':
		get_node("/root/global").reset()
	else:
		get_node("/root/global").hard_reset()