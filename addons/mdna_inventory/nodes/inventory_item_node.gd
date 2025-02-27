# The inventory item
class_name InventoryItemNode
extends TextureButton


# Emitted, when a hotspot was triggered
signal triggered_hotspot

# Emitted, when another inventory item was triggered
signal triggered_inventory_item


# The corresponding resource
var item: InventoryItem


# Wether we're on touch devices
onready var _is_touch: bool = OS.has_touchscreen_ui_hint()


func configure(p_item: InventoryItem):
	item = p_item
	texture_normal = item.image_normal
	connect("pressed", self, "_on_InventoryItem_pressed")


# Handle clicks on another inventory item
func _on_InventoryItem_pressed():
	if MdnaInventory.selected_item == self:
		# On touch, selecting the same item again, deselects it
		MdnaInventory.selected_item = null
		texture_normal = item.image_normal
	elif MdnaInventory.selected_item != null:
		# Another item was triggered with the current one
		emit_signal(
			"triggered_inventory_item", 
			MdnaInventory.selected_item.item, 
			item
		)
	else:
		# Select this inventory item
		texture_normal = null
		MdnaInventory.selected_item = self
		if _is_touch:
			texture_normal = item.image_active
		else:
			Input.set_custom_mouse_cursor(item.image_normal)

