extends CanvasLayer
class_name LoadingScreen

signal finished

@onready var _root: Control = %LoadingRoot
@onready var _status_label: Label = %StatusLabel
@onready var _progress_bar: ProgressBar = %ProgressBar


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if _root != null:
		_root.visible = false


func show_loading(status_text: String = "Carregando...") -> void:
	visible = true
	if _root != null:
		_root.visible = true
	if _status_label != null:
		_status_label.text = status_text
	if _progress_bar != null:
		_progress_bar.value = 0.0


func set_progress(value: float, status_text: String = "") -> void:
	if _progress_bar != null:
		_progress_bar.value = clampf(value, 0.0, 100.0)
	if not status_text.is_empty() and _status_label != null:
		_status_label.text = status_text


func hide_loading() -> void:
	visible = false
	if _root != null:
		_root.visible = false
	finished.emit()


func run_bootstrap_steps(steps: Array) -> void:
	show_loading("Carregando...")
	var total := maxi(steps.size(), 1)
	for index in range(steps.size()):
		var step: Dictionary = steps[index]
		var status := String(step.get("status", "Carregando..."))
		set_progress((float(index) / float(total)) * 100.0, status)
		var callable: Callable = step.get("action", Callable())
		if callable.is_valid():
			await callable.call()
		await get_tree().process_frame
	set_progress(100.0, "Pronto.")
	await get_tree().process_frame
	hide_loading()
