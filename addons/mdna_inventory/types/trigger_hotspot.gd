# A trigger hotspot definition resource
tool
class_name TriggerHotspot, \
		"res://addons/mdna_inventory/images/trigger_hotspot.svg"
extends Button


# Emitted when a validitem was used on the hotspot
signal item_used(item)


# The list of valid inventory items that can be used on this hotspot
var valid_inventory_items: Array = []


# Connect the required events
func _ready():
	connect("mouse_entered", self, "_on_mouse_entered")
	connect("mouse_exited", self, "_on_mouse_exited")
	connect("pressed", self, "_on_pressed")


# Set the button we're extending from to flat
func _enter_tree():
	flat = true


# If an inventory item was selected and it is in the list of valid inventory 
# items, show it as active
func _on_mouse_entered():
	if MdnaInventory.selected_item != null:
		var found = false
		
		for item in valid_inventory_items:
			if (item as InventoryItem).title == \
					MdnaInventory.selected_item.item.title:
				found = true
		
		if found:
			Input.set_custom_mouse_cursor(
				MdnaInventory.selected_item.item.image_active
			)
		else:
			Input.set_custom_mouse_cursor(
				MdnaInventory.selected_item.item.image_normal
			)
	else:
		Input.set_custom_mouse_cursor(
			MdnaInventory.configuration.use_cursor,
			Input.CURSOR_ARROW,
			MdnaInventory.configuration.use_cursor_hotspot
		)
		

# Show the normal image if an inventory item is selected and the mouse leaves
# the hotspot
func _on_mouse_exited():
	if MdnaInventory.selected_item != null:
		Input.set_custom_mouse_cursor(MdnaInventory.selected_item.item.image_normal)
	else:
		Input.set_custom_mouse_cursor(
			MdnaInventory.configuration.mouse_cursor,
			Input.CURSOR_ARROW,
			MdnaInventory.configuration.hotspot_cursor
		)


# If the selected item is in the list of valid items, emit the item_used signal
func _on_pressed():
	if MdnaInventory.selected_item != null and \
		valid_inventory_items.has(MdnaInventory.selected_item.item):
		emit_signal("item_used", MdnaInventory.selected_item.item)
	

# Return property list
func _get_property_list():
	var properties = []
	properties.append({
		"name": "valid_inventory_items",
		"type": TYPE_ARRAY,
		"hint": 24,
		"hint_string": "17/17:InventoryItem"
	})
	return properties
