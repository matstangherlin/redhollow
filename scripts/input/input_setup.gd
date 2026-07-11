extends Node

## Ensures gamepad mappings exist for beta shell actions.


func _ready() -> void:
	_register_gamepad_mappings()


func _register_gamepad_mappings() -> void:
	_add_button(&"jump", JOY_BUTTON_A)
	_add_button(&"attack", JOY_BUTTON_X)
	_add_button(&"dodge", JOY_BUTTON_B)
	_add_button(&"counter", JOY_BUTTON_Y)
	_add_button(&"interact", JOY_BUTTON_A)
	_add_button(&"taunt", JOY_BUTTON_RIGHT_SHOULDER)
	_add_button(&"pause", JOY_BUTTON_START)
	_add_key(&"pause", KEY_ESCAPE)

	_add_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_button(&"move_left", JOY_BUTTON_DPAD_LEFT)
	_add_button(&"move_right", JOY_BUTTON_DPAD_RIGHT)

	_add_axis(&"special", JOY_AXIS_TRIGGER_RIGHT, 1.0)


func _add_button(action: StringName, button_index: int) -> void:
	if not InputMap.has_action(action):
		return
	if _has_joy_button(action, button_index):
		return
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action, event)


func _add_key(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		return
	if _has_key(action, keycode):
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	InputMap.action_add_event(action, event)


func _add_axis(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		return
	if _has_joy_axis(action, axis, axis_value):
		return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)


func _has_joy_button(action: StringName, button_index: int) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == button_index:
			return true
	return false


func _has_key(action: StringName, keycode: Key) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == keycode:
			return true
	return false


func _has_joy_axis(action: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			if motion.axis == axis and is_equal_approx(motion.axis_value, axis_value):
				return true
	return false
