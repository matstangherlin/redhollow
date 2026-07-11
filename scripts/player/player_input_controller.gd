extends Node
class_name PlayerInputController

## Reads Input Map actions and exposes frame intentions for the player coordinator.
## Does not apply physics, animation, or world queries.

enum InputCategory {
	MOVEMENT = 1,
	COMBAT = 2,
	INTERACTION = 4,
	SPECIAL = 8,
	DEBUG = 16,
}

const GAMEPLAY_BLOCK_MASK := (
	InputCategory.MOVEMENT
	| InputCategory.COMBAT
	| InputCategory.INTERACTION
	| InputCategory.SPECIAL
)

class InputIntent:
	var move_axis: float = 0.0
	var jump_just_pressed: bool = false
	var jump_just_released: bool = false
	var attack_just_pressed: bool = false
	var dodge_just_pressed: bool = false
	var counter_just_pressed: bool = false
	var taunt_just_pressed: bool = false
	var special_just_pressed: bool = false
	var special_pressed: bool = false
	var interact_just_pressed: bool = false
	var debug_toggle_just_pressed: bool = false
	var debug_reset_just_pressed: bool = false


var jump_buffer_remaining: float = 0.0
var intents := InputIntent.new()

var move_axis: float:
	get:
		return intents.move_axis
	set(value):
		intents.move_axis = value

var jump_just_pressed: bool:
	get:
		return intents.jump_just_pressed
	set(value):
		intents.jump_just_pressed = value

var jump_just_released: bool:
	get:
		return intents.jump_just_released
	set(value):
		intents.jump_just_released = value

var attack_just_pressed: bool:
	get:
		return intents.attack_just_pressed
	set(value):
		intents.attack_just_pressed = value

var dodge_just_pressed: bool:
	get:
		return intents.dodge_just_pressed
	set(value):
		intents.dodge_just_pressed = value

var counter_just_pressed: bool:
	get:
		return intents.counter_just_pressed
	set(value):
		intents.counter_just_pressed = value

var taunt_just_pressed: bool:
	get:
		return intents.taunt_just_pressed
	set(value):
		intents.taunt_just_pressed = value

var special_just_pressed: bool:
	get:
		return intents.special_just_pressed
	set(value):
		intents.special_just_pressed = value

var special_pressed: bool:
	get:
		return intents.special_pressed
	set(value):
		intents.special_pressed = value

var interact_just_pressed: bool:
	get:
		return intents.interact_just_pressed
	set(value):
		intents.interact_just_pressed = value

var debug_toggle_just_pressed: bool:
	get:
		return intents.debug_toggle_just_pressed
	set(value):
		intents.debug_toggle_just_pressed = value

var debug_reset_just_pressed: bool:
	get:
		return intents.debug_reset_just_pressed
	set(value):
		intents.debug_reset_just_pressed = value

var _player: CharacterBody2D = null
var _blocked_categories: int = 0


func setup(player: CharacterBody2D) -> void:
	_player = player


func set_category_blocked(category: int, blocked: bool) -> void:
	if blocked:
		_blocked_categories |= category
	else:
		_blocked_categories &= ~category


func is_category_blocked(category: int) -> bool:
	return (_blocked_categories & category) != 0


func set_gameplay_input_blocked(blocked: bool) -> void:
	if blocked:
		_blocked_categories |= GAMEPLAY_BLOCK_MASK
	else:
		_blocked_categories &= ~GAMEPLAY_BLOCK_MASK


func update_jump_buffer(delta: float) -> void:
	if _player == null:
		return

	var jump_buffer_time := float(_player.get("jump_buffer_time"))
	if Input.is_action_just_pressed("jump"):
		jump_buffer_remaining = jump_buffer_time
	else:
		jump_buffer_remaining = maxf(jump_buffer_remaining - delta, 0.0)


func poll(_gameplay_input_blocked: bool = false) -> void:
	set_gameplay_input_blocked(_gameplay_input_blocked)
	_clear_intents()
	_read_debug_intents()
	_read_interaction_intents()
	_read_movement_intents()
	_read_combat_intents()
	_read_special_intents()


func reset_jump_buffer() -> void:
	jump_buffer_remaining = 0.0


func _clear_intents() -> void:
	intents.move_axis = 0.0
	intents.jump_just_pressed = false
	intents.jump_just_released = false
	intents.attack_just_pressed = false
	intents.dodge_just_pressed = false
	intents.counter_just_pressed = false
	intents.taunt_just_pressed = false
	intents.special_just_pressed = false
	intents.special_pressed = false
	intents.interact_just_pressed = false
	intents.debug_toggle_just_pressed = false
	intents.debug_reset_just_pressed = false


func _read_debug_intents() -> void:
	if is_category_blocked(InputCategory.DEBUG):
		return

	intents.debug_toggle_just_pressed = Input.is_action_just_pressed("debug_toggle")
	intents.debug_reset_just_pressed = Input.is_action_just_pressed("debug_reset")


func _read_interaction_intents() -> void:
	if is_category_blocked(InputCategory.INTERACTION):
		return

	intents.interact_just_pressed = Input.is_action_just_pressed("interact")


func _read_movement_intents() -> void:
	intents.jump_just_pressed = Input.is_action_just_pressed("jump")
	intents.jump_just_released = Input.is_action_just_released("jump")

	if is_category_blocked(InputCategory.MOVEMENT):
		return

	intents.move_axis = Input.get_axis("move_left", "move_right")


func _read_combat_intents() -> void:
	if is_category_blocked(InputCategory.COMBAT):
		return

	intents.attack_just_pressed = Input.is_action_just_pressed("attack")
	intents.dodge_just_pressed = Input.is_action_just_pressed("dodge")
	intents.counter_just_pressed = Input.is_action_just_pressed("counter")
	intents.taunt_just_pressed = Input.is_action_just_pressed("taunt")


func _read_special_intents() -> void:
	if is_category_blocked(InputCategory.SPECIAL):
		return

	intents.special_just_pressed = Input.is_action_just_pressed("special")
	intents.special_pressed = Input.is_action_pressed("special")
