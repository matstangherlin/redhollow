extends CanvasLayer
class_name ConfirmationDialogView

signal confirmed
signal cancelled

@onready var _root: Control = %ConfirmRoot
@onready var _title_label: Label = %TitleLabel
@onready var _body_label: Label = %BodyLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if _root != null:
		_root.visible = false
	if _confirm_button != null:
		_confirm_button.pressed.connect(_on_confirm_pressed)
	if _cancel_button != null:
		_cancel_button.pressed.connect(_on_cancel_pressed)


func present(title_text: String, body_text: String, confirm_text: String = "Confirmar", cancel_text: String = "Cancelar") -> void:
	if _title_label != null:
		_title_label.text = title_text
	if _body_label != null:
		_body_label.text = body_text
	if _confirm_button != null:
		_confirm_button.text = confirm_text
	if _cancel_button != null:
		_cancel_button.text = cancel_text
	visible = true
	if _root != null:
		_root.visible = true
	if _confirm_button != null:
		_confirm_button.grab_focus()


func hide_dialog() -> void:
	visible = false
	if _root != null:
		_root.visible = false


func _on_confirm_pressed() -> void:
	hide_dialog()
	confirmed.emit()


func _on_cancel_pressed() -> void:
	hide_dialog()
	cancelled.emit()
