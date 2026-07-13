extends RefCounted
class_name HudThemeV2

## Structural provisional theme for HUD V2 — no external fonts.

const COLOR_BG := Color(0.06, 0.05, 0.05, 0.88)
const COLOR_BORDER := Color(0.62, 0.16, 0.12, 0.9)
const COLOR_TEXT := Color(0.94, 0.9, 0.78, 1.0)
const COLOR_TEXT_MUTED := Color(0.72, 0.68, 0.62, 1.0)
const COLOR_VERMILITE := Color(0.92, 0.22, 0.38, 1.0)
const COLOR_STYLE := Color(0.96, 0.78, 0.28, 1.0)
const COLOR_HEALTH := Color(0.22, 0.72, 0.38, 1.0)
const COLOR_BRAND := Color(0.92, 0.14, 0.06, 1.0)
const SAFE_MARGIN := 12


static func make_panel_style(corner_radius: int = 6, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = COLOR_BORDER
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = corner_radius
	style.corner_radius_top_right = corner_radius
	style.corner_radius_bottom_right = corner_radius
	style.corner_radius_bottom_left = corner_radius
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	return style


static func apply_label_cream(label: Label, size: int = 12) -> void:
	label.add_theme_color_override("font_color", COLOR_TEXT)
	label.add_theme_font_size_override("font_size", size)


static func apply_label_muted(label: Label, size: int = 11) -> void:
	label.add_theme_color_override("font_color", COLOR_TEXT_MUTED)
	label.add_theme_font_size_override("font_size", size)


static func apply_progress_fill(bar: ProgressBar, color: Color) -> void:
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_right = 3
	fill.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("fill", fill)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.1, 0.1, 0.9)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_right = 3
	bg.corner_radius_bottom_left = 3
	bar.add_theme_stylebox_override("background", bg)
