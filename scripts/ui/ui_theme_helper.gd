extends RefCounted
class_name UiThemeHelper

static func style_panel(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.09, 0.94)
	style.border_color = Color(0.55, 0.22, 0.16, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(18)
	panel.add_theme_stylebox_override("panel", style)


static func style_dim(color_rect: ColorRect) -> void:
	color_rect.color = Color(0.03, 0.03, 0.05, 0.78)


static func style_title_label(label: Label) -> void:
	label.add_theme_color_override("font_color", Color(0.95, 0.88, 0.72, 1.0))
	label.add_theme_font_size_override("font_size", 32)


static func style_body_label(label: Label) -> void:
	label.add_theme_color_override("font_color", Color(0.82, 0.82, 0.86, 1.0))
	label.add_theme_font_size_override("font_size", 16)


static func style_menu_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(320, 44)
	button.add_theme_font_size_override("font_size", 18)
