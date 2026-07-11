extends Node

signal device_changed(device_kind: int)

enum DeviceKind {
	KEYBOARD_MOUSE,
	GAMEPAD,
}

const ACTION_PROMPT_KEYS: Dictionary = {
	"move_left": "move_left",
	"move_right": "move_right",
	"jump": "jump",
	"attack": "attack",
	"dodge": "dodge",
	"counter": "counter",
	"interact": "interact",
	"taunt": "taunt",
	"special": "special",
	"pause": "pause",
}

const GAMEPAD_BUTTON_LABELS: Dictionary = {
	JOY_BUTTON_A: "A",
	JOY_BUTTON_B: "B",
	JOY_BUTTON_X: "X",
	JOY_BUTTON_Y: "Y",
	JOY_BUTTON_LEFT_SHOULDER: "LB",
	JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JOY_BUTTON_BACK: "View",
	JOY_BUTTON_START: "Menu",
	JOY_BUTTON_LEFT_STICK: "L3",
	JOY_BUTTON_RIGHT_STICK: "R3",
	JOY_BUTTON_DPAD_UP: "D-Pad Up",
	JOY_BUTTON_DPAD_DOWN: "D-Pad Down",
	JOY_BUTTON_DPAD_LEFT: "D-Pad Left",
	JOY_BUTTON_DPAD_RIGHT: "D-Pad Right",
}

var last_device_kind: DeviceKind = DeviceKind.KEYBOARD_MOUSE
var last_joypad_id: int = 0


func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton:
		_set_device(DeviceKind.GAMEPAD, event.device)
	elif event is InputEventJoypadMotion:
		if absf((event as InputEventJoypadMotion).axis_value) < 0.25:
			return
		_set_device(DeviceKind.GAMEPAD, event.device)
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		_set_device(DeviceKind.KEYBOARD_MOUSE, -1)


func get_action_prompt(action_name: StringName, include_brackets: bool = true) -> String:
	var label := _resolve_action_label(String(action_name))
	if not include_brackets:
		return label
	return "[%s]" % label


func format_interaction_prompt(prompt_text: String) -> String:
	return "%s %s" % [get_action_prompt(&"interact"), prompt_text]


func format_dialogue_advance_prompt(is_last_line: bool) -> String:
	var advance := get_action_prompt(&"interact")
	var close := get_action_prompt(&"pause")
	if is_last_line:
		return "%s Fechar | %s Sair" % [advance, close]
	return "%s Continuar | %s Sair" % [advance, close]


func is_using_gamepad() -> bool:
	return last_device_kind == DeviceKind.GAMEPAD


func _set_device(kind: DeviceKind, joypad_id: int) -> void:
	if kind == DeviceKind.GAMEPAD:
		last_joypad_id = joypad_id
	if kind == last_device_kind:
		return
	last_device_kind = kind
	device_changed.emit(kind)


func _on_joy_connection_changed(_device: int, _connected: bool) -> void:
	if Input.get_connected_joypads().is_empty() and last_device_kind == DeviceKind.GAMEPAD:
		_set_device(DeviceKind.KEYBOARD_MOUSE, -1)


func _resolve_action_label(action_name: String) -> String:
	if last_device_kind == DeviceKind.GAMEPAD:
		return _resolve_gamepad_label(action_name)
	return _resolve_keyboard_label(action_name)


func _resolve_keyboard_label(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return action_name

	for event in InputMap.action_get_events(action_name):
		if event is InputEventKey:
			return OS.get_keycode_string((event as InputEventKey).physical_keycode)
	return action_name


func _resolve_gamepad_label(action_name: String) -> String:
	if not InputMap.has_action(action_name):
		return action_name

	for event in InputMap.action_get_events(action_name):
		if event is InputEventJoypadButton:
			var button_event := event as InputEventJoypadButton
			if GAMEPAD_BUTTON_LABELS.has(button_event.button_index):
				return String(GAMEPAD_BUTTON_LABELS[button_event.button_index])
			return "Btn %d" % button_event.button_index
		if event is InputEventJoypadMotion:
			var motion := event as InputEventJoypadMotion
			if motion.axis == JOY_AXIS_TRIGGER_RIGHT:
				return "RT"
			if motion.axis == JOY_AXIS_TRIGGER_LEFT:
				return "LT"
			if motion.axis == JOY_AXIS_LEFT_X and motion.axis_value < 0.0:
				return "L Stick"
			if motion.axis == JOY_AXIS_LEFT_X and motion.axis_value > 0.0:
				return "R Stick"

	return "Pad"
