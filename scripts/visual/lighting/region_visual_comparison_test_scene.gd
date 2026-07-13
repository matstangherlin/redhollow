extends Control

const ThemeFactory := preload("res://scripts/visual/lighting/chapter_zero_street_theme_factory.gd")
const PresentationScene := preload("res://scenes/environment/chapter_zero/street_art_presentation.tscn")

const STATE_ORDER: Array[CorruptionVisualState.State] = [
	CorruptionVisualState.State.NORMAL,
	CorruptionVisualState.State.VERMILITE_NEAR,
	CorruptionVisualState.State.RED_RESONANCE,
	CorruptionVisualState.State.MOL_KHAR_APPEARANCE,
]

@onready var _state_label: Label = %StateLabel
@onready var _palette_label: Label = %PaletteLabel
@onready var _preview_root: Node2D = %PreviewRoot

var _presentation: StreetArtPresentation = null
var _controller: RegionVisualController = null
var _state_index: int = 0


func _ready() -> void:
	_spawn_preview()
	_apply_state_index(0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT:
				_apply_state_index(_state_index - 1)
				get_viewport().set_input_as_handled()
			KEY_RIGHT:
				_apply_state_index(_state_index + 1)
				get_viewport().set_input_as_handled()
			KEY_1:
				_apply_state_index(0)
				get_viewport().set_input_as_handled()
			KEY_2:
				_apply_state_index(1)
				get_viewport().set_input_as_handled()
			KEY_3:
				_apply_state_index(2)
				get_viewport().set_input_as_handled()
			KEY_4:
				_apply_state_index(3)
				get_viewport().set_input_as_handled()


func _spawn_preview() -> void:
	if _preview_root == null:
		return
	_presentation = PresentationScene.instantiate() as StreetArtPresentation
	if _presentation == null:
		return
	_presentation.build_on_ready = false
	_presentation.region_theme = ThemeFactory.build()
	_preview_root.add_child(_presentation)
	_presentation.position = Vector2(0, 0)
	_presentation.build_layers()
	_controller = _presentation.get_region_visual_controller()


func _apply_state_index(index: int) -> void:
	_state_index = posmod(index, STATE_ORDER.size())
	var state := STATE_ORDER[_state_index]
	if _controller != null:
		_controller.transition_to_state(state, 0.35)
	_update_labels(state)


func _update_labels(state: CorruptionVisualState.State) -> void:
	var theme := ThemeFactory.build()
	var state_resource := theme.get_state_resource(state)
	var profile := theme.get_lighting_profile(state)
	if _state_label != null and state_resource != null:
		_state_label.text = "Estado: %s — %s" % [state_resource.state_name, state_resource.description]
	if _palette_label != null and profile != null:
		_palette_label.text = (
			"Modulate %s | Sat %.2f | Verm energy %.2f | Vignette %.2f | Distortion %.2f\n"
			% [
				str(profile.canvas_modulate),
				profile.environment_saturation,
				profile.vermilite_accent_energy,
				profile.vignette_strength,
				profile.distortion_strength,
			]
		)
