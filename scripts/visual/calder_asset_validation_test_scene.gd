extends Control

@onready var _report_label: Label = %ReportLabel


func _ready() -> void:
	_run_and_display()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		_run_and_display()
		get_viewport().set_input_as_handled()


func _run_and_display() -> void:
	var report: Dictionary = CalderAssetValidator.validate_pilot_set()
	var text := CalderAssetValidator.format_report(report)
	text += "\n\n[R] revalidar | F6 cena isolada | sheets em art/characters/calder/sheets/"
	if _report_label != null:
		_report_label.text = text
	print(text)
