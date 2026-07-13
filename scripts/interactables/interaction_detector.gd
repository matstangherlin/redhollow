extends Node

const INTERACTABLE_GROUP := "interactable"
const DIALOGUE_CONTROLLER_GROUP := "dialogue_controller"

@export var scan_interval: float = 0.05

@onready var _player: CharacterBody2D = get_parent().get_parent() as CharacterBody2D
@onready var _prompt_label: Label = get_node_or_null("%InteractionPromptLabel")

var current_interactable: Interactable = null
var current_interaction_id: StringName = &""
var current_interaction_distance: float = -1.0
var current_interaction_priority: int = 0
var _scan_time_remaining: float = 0.0


func _ready() -> void:
	_scan_time_remaining = 0.0
	_refresh_focused_interactable()
	if InputDeviceManager != null:
		InputDeviceManager.device_changed.connect(_on_input_device_changed)


func _on_input_device_changed(_device_kind: int) -> void:
	_update_prompt_label()
	if current_interactable != null:
		current_interactable.set_focused(true)


func _physics_process(delta: float) -> void:
	_scan_time_remaining -= delta
	if _scan_time_remaining <= 0.0:
		_scan_time_remaining = maxf(scan_interval, 0.0)
		_refresh_focused_interactable()

	_update_prompt_label()


func try_interact() -> bool:
	if current_interactable == null or _player == null:
		return false

	if not _can_player_interact():
		return false

	if not current_interactable.can_interact(_player):
		return false

	if current_interactable.should_face_interactor():
		_face_player_toward(current_interactable.get_interaction_anchor())

	current_interactable.interact(_player)
	return true


func _refresh_focused_interactable() -> void:
	if _player == null:
		return

	var best := _find_best_interactable()
	if best == current_interactable:
		if current_interactable != null:
			current_interaction_distance = _player.global_position.distance_to(current_interactable.get_interaction_anchor())
		return

	if current_interactable != null:
		current_interactable.set_focused(false)

	current_interactable = best
	if current_interactable != null:
		current_interactable.set_focused(true)
		current_interaction_id = current_interactable.interaction_id
		current_interaction_priority = current_interactable.priority
		current_interaction_distance = _player.global_position.distance_to(current_interactable.get_interaction_anchor())
	else:
		current_interaction_id = &""
		current_interaction_priority = 0
		current_interaction_distance = -1.0


func _find_best_interactable() -> Interactable:
	if _player == null:
		return null

	var best: Interactable = null
	var best_priority := -2147483648
	var best_distance := INF

	for node in get_tree().get_nodes_in_group(INTERACTABLE_GROUP):
		var interactable := node as Interactable
		if interactable == null or not interactable.can_interact(_player):
			continue

		var distance := _player.global_position.distance_to(interactable.get_interaction_anchor())
		if distance > interactable.interaction_range:
			continue

		if interactable.priority > best_priority:
			best = interactable
			best_priority = interactable.priority
			best_distance = distance
			continue

		if interactable.priority == best_priority and distance < best_distance:
			best = interactable
			best_distance = distance

	return best


func _can_player_interact() -> bool:
	if _player == null:
		return false

	if _is_dialogue_active():
		return false

	if _player.has_method("can_interact_now"):
		return bool(_player.call("can_interact_now"))

	return true


func _is_dialogue_active() -> bool:
	for node in get_tree().get_nodes_in_group(DIALOGUE_CONTROLLER_GROUP):
		if node is DialogueController and (node as DialogueController).is_blocking_interactions():
			return true

	if _player != null and _player.has_method("is_in_dialogue"):
		return bool(_player.call("is_in_dialogue"))

	return false


func _face_player_toward(target_position: Vector2) -> void:
	if _player == null or not _player.has_method("set_facing_direction"):
		return

	var direction := signi(int(target_position.x - _player.global_position.x))
	if direction != 0:
		_player.call("set_facing_direction", direction)


func _position_prompt_label() -> void:
	if _prompt_label == null or current_interactable == null:
		return

	if _should_anchor_prompt_to_interactable():
		var anchor := current_interactable.get_interaction_anchor()
		_prompt_label.global_position = anchor + Vector2(0, -44)
		_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif _player != null:
		_prompt_label.global_position = _player.global_position + Vector2(0, -80)
		_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _should_anchor_prompt_to_interactable() -> bool:
	for node in get_tree().get_nodes_in_group(HudLayoutController.HUD_LAYOUT_GROUP):
		if node is HudLayoutController and (node as HudLayoutController).is_using_hud_v2():
			return true
	return false


func _update_prompt_label() -> void:
	if _prompt_label == null:
		return

	if current_interactable == null or not _can_player_interact():
		_prompt_label.visible = false
		_prompt_label.text = ""
		return

	_prompt_label.visible = true
	var prompt_text := ""
	if InputDeviceManager != null:
		prompt_text = InputDeviceManager.format_interaction_prompt(
			current_interactable.get_prompt_text(_player)
		)
	else:
		prompt_text = "[E] %s" % current_interactable.get_prompt_text(_player)
	_prompt_label.text = prompt_text
	_position_prompt_label()
