extends CanvasLayer
class_name CreditsScreen

signal closed

@onready var _root: Control = %CreditsRoot
@onready var _body_label: RichTextLabel = %CreditsBody
@onready var _back_button: Button = %BackButton


const CREDITS_TEXT := """[center][b]RED HOLLOW[/b]
Capítulo Zero — Beta Pública (Provisório)

[b]Direção[/b]
Equipe Red Hollow

[b]Design de Jogo[/b]
Equipe Red Hollow

[b]Programação[/b]
Equipe Red Hollow

[b]Arte[/b]
Em produção

[b]Áudio[/b]
Em produção

[b]Engine[/b]
Godot 4.7

Este build é uma beta técnica.
Créditos finais serão atualizados antes do lançamento.[/center]"""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if _root != null:
		_root.visible = false
	if _body_label != null:
		_body_label.text = CREDITS_TEXT
	if _back_button != null:
		_back_button.pressed.connect(_on_back_pressed)


func show_credits() -> void:
	visible = true
	if _root != null:
		_root.visible = true
	if _back_button != null:
		_back_button.grab_focus()


func hide_credits() -> void:
	visible = false
	if _root != null:
		_root.visible = false


func _on_back_pressed() -> void:
	hide_credits()
	closed.emit()
