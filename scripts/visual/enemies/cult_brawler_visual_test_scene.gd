extends Control

@onready var _report_label: Label = %ReportLabel
@onready var _preview_sprite: AnimatedSprite2D = %PreviewSprite


func _ready() -> void:
	_run_and_display()
	_setup_preview()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R:
				_run_and_display()
				get_viewport().set_input_as_handled()
			KEY_1:
				_play_clip(&"idle")
			KEY_2:
				_play_clip(&"attack_startup")
			KEY_3:
				_play_clip(&"attack_active")
			KEY_4:
				_play_clip(&"death")
			KEY_5:
				_play_clip(&"stagger")


func _setup_preview() -> void:
	var profile := preload("res://resources/visual/enemies/cult_brawler_pilot_profile.tres")
	var frames := CultBrawlerSpriteFramesBuilder.build_for_profile(profile)
	if _preview_sprite == null or frames == null:
		return
	_preview_sprite.sprite_frames = frames
	_preview_sprite.offset = CultBrawlerAnimationContract.SPRITE_VISUAL_OFFSET
	_preview_sprite.play(&"idle")


func _play_clip(clip: StringName) -> void:
	if _preview_sprite != null and _preview_sprite.sprite_frames != null:
		if _preview_sprite.sprite_frames.has_animation(clip):
			_preview_sprite.play(clip)


func _run_and_display() -> void:
	var report: Dictionary = CultBrawlerAssetValidator.validate_pilot_set()
	var text := CultBrawlerAssetValidator.format_report(report)
	text += "\n\nPreview: [1] idle [2] startup [3] active [4] death [5] stagger"
	text += "\n[R] revalidar | sheets em art/characters/enemies/cult_brawler/sheets/"
	if _report_label != null:
		_report_label.text = text
	print(text)
