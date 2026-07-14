extends Node2D

signal cache_used

const PLAYER_GROUP := "player"

@export var energy_amount: float = 45.0
@export var one_shot: bool = true
@export var required_narrative_flag: StringName = &"arena_vs_church_yard_complete"
@export var completion_flag_id: StringName = &"vs_red_brand_cache_used"
@export var locked_message: String = "Derrote os cultistas da arena primeiro."

@onready var interactable: Interactable = %Interactable
@onready var idle_visual: CanvasItem = %IdleVisual
@onready var used_visual: CanvasItem = %UsedVisual

var _is_used: bool = false
var _status_timer: SceneTreeTimer = null


func _ready() -> void:
	if interactable != null:
		interactable.interacted.connect(_on_interacted)
	_sync_from_progression()


func _process(_delta: float) -> void:
	if not _is_used:
		_update_visuals()


func _on_interacted(interactor: Node) -> void:
	if _is_used and one_shot:
		_show_status_message("Coração Rubro já absorvido.")
		return
	if not _is_unlocked():
		_show_status_message(locked_message)
		return

	var red_brand := _find_red_brand_component(interactor)
	if red_brand == null:
		_show_status_message("Red Brand indisponível.")
		return

	var max_energy := float(red_brand.get("max_energy"))
	var target_energy := maxf(float(red_brand.get("current_energy")), energy_amount)
	red_brand.call("set_energy", minf(target_energy, max_energy))
	_mark_used()
	_show_status_message("Coração Rubro absorvido. Use [U] na barreira.")


func _is_unlocked() -> bool:
	if required_narrative_flag == &"":
		return true

	for node in get_tree().get_nodes_in_group("progression_component"):
		var flags: Dictionary = node.get("narrative_flags")
		if bool(flags.get(String(required_narrative_flag), false)):
			return true
		if required_narrative_flag == &"arena_vs_church_yard_complete":
			return bool(flags.get("arena_church_yard_01_complete", false))
	return false


func _mark_used() -> void:
	_is_used = true
	_update_visuals()
	cache_used.emit()

	for node in get_tree().get_nodes_in_group("progression_component"):
		if node.has_method("set_narrative_flag"):
			node.call("set_narrative_flag", completion_flag_id, true)
			break


func _sync_from_progression() -> void:
	for node in get_tree().get_nodes_in_group("progression_component"):
		var flags: Dictionary = node.get("narrative_flags")
		if bool(flags.get(String(completion_flag_id), false)):
			_is_used = true
	_update_visuals()


func _update_visuals() -> void:
	var unlocked := _is_unlocked()
	if idle_visual != null:
		idle_visual.visible = unlocked and not _is_used
	if used_visual != null:
		used_visual.visible = _is_used
	if interactable != null:
		interactable.prompt_text = "Absorver Coração Rubro" if unlocked else "Selado"


func _show_status_message(message: String) -> void:
	if interactable == null:
		return

	var label := interactable.get_node_or_null("%PromptIndicator") as Label
	if label == null:
		return

	label.text = message
	label.visible = true

	if _status_timer != null and is_instance_valid(_status_timer):
		_status_timer.timeout.disconnect(_restore_prompt)

	_status_timer = get_tree().create_timer(2.6, true)
	_status_timer.timeout.connect(_restore_prompt, CONNECT_ONE_SHOT)


func _restore_prompt() -> void:
	_update_visuals()
	if interactable == null:
		return

	var label := interactable.get_node_or_null("%PromptIndicator") as Label
	if label == null:
		return

	if not _is_unlocked() or _is_used:
		label.visible = false
		return

	label.text = "[E] %s" % interactable.get_prompt_text(null)
	label.visible = true


func _find_red_brand_component(interactor: Node) -> Node:
	if interactor == null:
		return null
	return interactor.get_node_or_null("Components/RedBrandComponent")
