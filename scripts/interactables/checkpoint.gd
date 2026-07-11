extends Node2D

signal checkpoint_activated(
	checkpoint_id: StringName,
	checkpoint_position: Vector2,
	interactor: Node,
	restore_health: bool,
	restore_red_brand: bool
)

const CHECKPOINT_GROUP := "checkpoints"

@export var checkpoint_id: StringName = &""
@export var prompt_text: String = "Activate checkpoint"
@export var restore_health: bool = true
@export var restore_red_brand: bool = false

@onready var interactable: Interactable = %Interactable
@onready var active_visual: CanvasItem = %ActiveVisual
@onready var idle_visual: CanvasItem = %IdleVisual


func _ready() -> void:
	add_to_group(CHECKPOINT_GROUP)
	if interactable != null:
		interactable.prompt_text = prompt_text
		interactable.interacted.connect(_on_interacted)
	_update_visual(false)


func _on_interacted(interactor: Node) -> void:
	if checkpoint_id == &"":
		push_warning("Checkpoint activated without checkpoint_id.")
		return

	_update_visual(true)
	checkpoint_activated.emit(
		checkpoint_id,
		global_position,
		interactor,
		restore_health,
		restore_red_brand
	)


func restore_active_state(is_active: bool) -> void:
	_update_visual(is_active)


func _update_visual(is_active: bool) -> void:
	if active_visual != null:
		active_visual.visible = is_active
	if idle_visual != null:
		idle_visual.visible = not is_active
