# The MDNA main menu
extends CanvasLayer


# Emitted when the user wants to start a new game
signal new_game


# The date format used for display in the save slots
const DATE_FORMAT: String = "{month}/{day}/{year} {hour}:{minute}"

# Lowest Audio level

const AUDIO_MIN: float = -50.0


# Wether the main menu can be hidden
var resumeable: bool = true

# Wether the a game can be saved
var saveable: bool = true


# Currently selected save slot (used for overwrite confirmation dialog)
var _selected_slot: int

# Wether we are saving or loading
var _is_save_mode: bool

# The currently visible save slot page
var _save_slot_page: int = 1

# The configuration of this game
var _configuration: GameConfiguration


# Default to hiding the menu
func _ready():
	$Control.hide()
	$SaveSlots.hide()
	$Options.hide()
	for child in $Control/Margin/VBox/MenuItems.get_children():
		(child as Button).connect("mouse_entered", self, "_on_menuitem_hover", [true, child])
		(child as Button).connect("mouse_exited", self, "_on_menuitem_hover", [false, child])
	var percent = _get_bus_percent("Effects")
	$Options/CenterContainer/VBox/Effects/Slider.value = percent
		
	$Options/CenterContainer/VBox/Music/Slider.value = \
		_get_bus_percent("Music")
	$Options/CenterContainer/VBox/Speech/Slider.value = \
		_get_bus_percent("Speech")


# React to the ui_menu action
func _input(event):
	if event.is_action_released("ui_menu"):
		if $SaveSlots.visible:
			$SaveSlots.hide()
		else:
			toggle()


# Handle saveable parameter
func _process(delta):
	$Control/Margin/VBox/MenuItems/Save.disabled = not saveable


# Configure the menu
func configure(configuration: GameConfiguration):
	_configuration = configuration
	
	$Control/Background.texture = configuration.menu_background
	$Control/Margin/VBox/Logo.texture = configuration.logo
	
	$SaveSlots/Background.texture = configuration.menu_saveslots_background
	$SaveSlots/VBox/HBox/Previous.texture_normal = configuration.menu_saveslots_previous_image
	$SaveSlots/VBox/HBox/Next.texture_normal = configuration.menu_saveslots_next_image
	
	$Options/Background.texture = configuration.menu_options_background
	$Options/CenterContainer/VBox/Speech/Slider.value = \
			_get_bus_percent("Speech")
	$Options/CenterContainer/VBox/Music/Slider.value = \
			_get_bus_percent("Music")
	$Options/CenterContainer/VBox/Effects/Slider.value = \
			_get_bus_percent("Effects")
	$Options/CenterContainer/VBox/Subtitles/Subtitles.pressed = \
			MdnaCore.in_game_configuration.subtitles
			
	# Apply theme
	
	$Control.theme = configuration.theme
	$Options.theme = configuration.theme
	$SaveSlots.theme = configuration.theme
	$QuitConfirm.theme = configuration.theme
	$OverwriteConfirm.theme = configuration.theme
	$RestartConfirm.theme = configuration.theme


# Toggle the display of the menu and play the menu music
func toggle():
	if resumeable:
		if MdnaCore.game_started:
			$Control/Margin/VBox/MenuItems/Resume.show()
			$Control/Margin/VBox/MenuItems/Continue.hide()
		else:
			$Control/Margin/VBox/MenuItems/Continue.show()
			$Control/Margin/VBox/MenuItems/Resume.hide()
			
			if MdnaCore.in_game_configuration.resume_state == null:
				$Control/Margin/VBox/MenuItems/Continue.disabled = true
			else:
				$Control/Margin/VBox/MenuItems/Continue.disabled = false
		
		$Control.visible = !$Control.visible
		if _configuration.menu_music != null and $Control.visible:
			Boombox.pause_music()
			$Music.stream = _configuration.menu_music
			$Music.play()
		else:
			$Music.stop()
			Boombox.resume_music()


# Resume was pressed. Toggle the menu
func _on_Resume_pressed():
	toggle()


# Quit was pressed. Show confirmation
func _on_Quit_pressed():
	$QuitConfirm.popup_centered()


# Quit was confirmed. Just quit the game
func _on_QuitConfirm_confirmed():
	get_tree().quit()


# Save was pressed. Show saveslots in save mode
func _on_Save_pressed():
	$SaveSlots/VBox/Title.text = "Save game"
	_is_save_mode = true
	_refresh_saveslots()
	$SaveSlots.show()


# Load was pressed. Show saveslots in load mode
func _on_Load_pressed():
	$SaveSlots/VBox/Title.text = "Load game"
	_is_save_mode = false
	_refresh_saveslots()
	$SaveSlots.show()
	

# Cancel was pressed. Hide saveslots
func _on_SaveLoad_Cancel_pressed():
	$SaveSlots.hide()


# A save slot was selected
func _on_slot_selected(slot: int, exists: bool):
	if _is_save_mode:
		if exists:
			# This save slot exists, show the confirmation dialog
			_selected_slot = slot
			$OverwriteConfirm.popup_centered()
		else:
			# Briefly hide the menu to snapshot a picture of the current
			# scene
			$Control.hide()
			$SaveSlots.hide()
			yield(get_tree().create_timer(1.0), "timeout")
			MdnaCore.save(slot)
			$Control.show()
			$SaveSlots.show()
			_refresh_saveslots()
	else:
		$Control.hide()
		$SaveSlots.hide()
		MdnaCore.load(slot)


# Overwrite was confirmed, just call the event handler again ignoring
# the existing save slot
func _on_OverwriteConfirm_confirmed():
	_on_slot_selected(_selected_slot, false)


# Next page was pressed
func _on_Next_pressed():
	_save_slot_page = _save_slot_page + 1
	_refresh_saveslots()


# Previous page was pressed
func _on_Previous_pressed():
	if _save_slot_page > 1:
		_save_slot_page = _save_slot_page - 1
		_refresh_saveslots()


# Options was pressed
func _on_Options_pressed():
	$Options.show()


# Return was pressed on the options screen
func _on_Return_pressed():
	$Options.hide()


# The speech slider was changed
func _on_speech_Slider_value_changed(value):
	MdnaCore.in_game_configuration.speech_db = _percent_to_db(value)
	MdnaCore.save_in_game_configuration()
	MdnaCore.set_audio_levels()
	if $Options.visible and _configuration.menu_options_speech_sample != null:
		$Speech.stream = _configuration.menu_options_speech_sample
		$Speech.play()


# The music slider was changed
func _on_music_Slider_value_changed(value):
	MdnaCore.in_game_configuration.music_db = _percent_to_db(value)
	MdnaCore.save_in_game_configuration()
	MdnaCore.set_audio_levels()


# The effects slider was changed
func _on_effects_Slider_value_changed(value):
	MdnaCore.in_game_configuration.effects_db = _percent_to_db(value)
	MdnaCore.save_in_game_configuration()
	MdnaCore.set_audio_levels()
	if $Options.visible and _configuration.menu_options_effects_sample != null:
		$Effects.stream = _configuration.menu_options_effects_sample
		$Effects.play()


# The subtitles checkbox was changed
func _on_Subtitles_toggled(button_pressed):
	MdnaCore.in_game_configuration.subtitles = button_pressed
	MdnaCore.save_in_game_configuration()
	if $Options.visible and _configuration.menu_switch_effect != null:
		$Effects.stream = _configuration.menu_switch_effect
		$Effects.play()


# Exchange the theme's font with the hover font
func _on_menuitem_hover(entered: bool, node: Button):
	if entered:
		node.add_font_override("font", _configuration.menu_hover_font)
	else:
		node.add_font_override("font", null)


# Get the current volume level in db and convert it to a slider percent
# value from the specified bus
#
# ** Arguments **
# - bus_name: The name of the bus
#
# ** Returns **
# - The slider percent from 0 (- AUDIO_MIN db) to 100 (0 db)
func _get_bus_percent(bus_name: String) -> float:
	var db = AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))
	return ((db + (AUDIO_MIN * -1)) * 100 / AUDIO_MIN) * -1


# Convert a slider percent level to db for an audiobus.
# 0 percent = -72db, 100 percent = 0 db
#
# ** Arguments **
# - percent: The percent value
#
# ** Returns **
# - The volume value in db
func _percent_to_db(percent: float) -> float:
	return ((AUDIO_MIN * -1) * percent / 100) + AUDIO_MIN


# Get the last modified timestamp in a readable date format for the
# save slots based on the format constant
#
# ** Arguments **
# - The slot file name
#
# ** Returns **
# - The last modification timestamp of the file in the date format as configured
#   in the constant
func _get_date_from_file(file: String) -> String:
	var datetime = OS.get_datetime_from_unix_time(
		File.new().get_modified_time(file)
	)
	return DATE_FORMAT.format(datetime)


# Refresh the saveslots vie
func _refresh_saveslots():
	var save_dir = Directory.new()
	save_dir.open("user://")
	
	for slot in range(0, 12):
		var save_slot = _save_slot_page + slot
		
		# Set the slot stylebox
		var slot_node = $SaveSlots/VBox/HBox/Slots.get_node(
			"Slot%d" % save_slot 
		)
		(slot_node.get_node("Slot/Panel") as Panel) \
				.add_stylebox_override(
					"panel", 
					(slot_node.get_node("Slot/Panel") as Panel).get_stylebox(
						"saveslot_panel",
						"Panel"
					)
				)
		
		var slot_panel_image: TextureButton
		var connect_signals: bool = true
		var slot_exists: bool = false
		
		if save_dir.file_exists("save_%d.png" % save_slot) and \
			save_dir.file_exists("save_%d.tres" % save_slot):
			
			# The slot is already taken. Show the saved image and date
			slot_exists = true
			
			var slot_image = Image.new()
			slot_image.load("user://save_%d.png" % save_slot)	
			var slot_image_texture = ImageTexture.new()
			slot_image_texture.create_from_image(slot_image)
			slot_panel_image = slot_node.get_node("Slot/Panel/Image")
			slot_panel_image.texture_normal = slot_image_texture
			
			(slot_node.get_node("Slot/Date") as Label).text = \
					_get_date_from_file("user://save_%d.tres" % save_slot)
		else:
			
			# The slot is free. Show an empty panel and no date
			slot_panel_image = slot_node.get_node("Slot/Panel/Image")
			slot_panel_image.texture_normal = \
					load("res://addons/mdna_core/images/empty.png")
			
			(slot_node.get_node("Slot/Date") as Label).text = ""
			if ! _is_save_mode:
				# Prohibit loading from empty slots
				connect_signals = false
			
		if connect_signals:
			# Connect the pressed signals for the slot in a clean way
			if slot_panel_image.is_connected(
				"pressed", 
				self, 
				"_on_slot_selected"
			):
				slot_panel_image.disconnect(
					"pressed", 
					self, 
					"_on_slot_selected"
				)
				
			slot_panel_image.connect(
				"pressed", 
				self, 
				"_on_slot_selected", 
				[save_slot, slot_exists]
			)


# The continue button was pressed
func _on_Continue_pressed():
	MdnaCore.load_resume()


# The New Game button was pressed
func _on_NewGame_pressed():
	if MdnaCore.in_game_configuration.resume_state != null:
		$RestartConfirm.popup_centered()
	else:
		_on_RestartConfirm_confirmed()


# Restarting the game was confirmed
func _on_RestartConfirm_confirmed():
	toggle()
	emit_signal("new_game")
