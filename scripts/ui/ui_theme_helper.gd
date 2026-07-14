extends RefCounted
class_name UiThemeHelper

static func style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.08, 0.94)
	style.border_color = Color(0.58, 0.24, 0.16, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.35)
	style.shadow_size = 6
	panel.add_theme_stylebox_override("panel", style)


static func style_dialogue_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.07, 0.06, 0.94)
	style.border_color = Color(0.62, 0.34, 0.18, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(14)
	style.shadow_color = Color(0.02, 0.01, 0.01, 0.4)
	style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style)


static func style_dim(color_rect: ColorRect) -> void:
	color_rect.color = Color(0.03, 0.02, 0.04, 0.82)


static func style_title_label(label: Label) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.68, 1.0))
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_outline_color", Color(0.18, 0.05, 0.04, 0.85))
	label.add_theme_constant_override("outline_size", 3)


static func style_body_label(label: Label) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.78, 1.0))
	label.add_theme_font_size_override("font_size", 16)


static func style_menu_button(button: Button) -> void:
	if button == null:
		return
	button.custom_minimum_size = Vector2(320, 44)
	button.add_theme_font_size_override("font_size", 18)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.12, 0.09, 0.09, 0.92)
	normal.border_color = Color(0.48, 0.20, 0.14, 0.95)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	normal.set_content_margin_all(10)
	var hover := normal.duplicate()
	hover.bg_color = Color(0.20, 0.10, 0.09, 0.95)
	hover.border_color = Color(0.78, 0.32, 0.18, 1.0)
	var pressed := normal.duplicate()
	pressed.bg_color = Color(0.28, 0.12, 0.10, 0.98)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.add_theme_color_override("font_color", Color(0.92, 0.88, 0.78, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.92, 0.78, 1.0))


static func style_end_card_labels(title: Label, body: Label) -> void:
	style_title_label(title)
	if title != null:
		title.add_theme_font_size_override("font_size", 28)
	style_body_label(body)
	if body != null:
		body.add_theme_font_size_override("font_size", 15)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
