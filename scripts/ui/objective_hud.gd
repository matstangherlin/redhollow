extends CanvasLayer
class_name ObjectiveHud

@onready var _panel: PanelContainer = %ObjectivePanel
@onready var _title_label: Label = %ObjectiveTitle
@onready var _body_label: Label = %ObjectiveBody


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _panel != null:
		_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	update_objective("", "Capítulo Zero", "Fale com Elias na rua de Red Hollow.")


func update_objective(_objective_id: String, title: String, text: String) -> void:
	if _title_label != null:
		_title_label.text = title
	if _body_label != null:
		_body_label.text = text
	visible = not text.is_empty()
