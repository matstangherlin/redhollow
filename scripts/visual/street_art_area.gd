extends AreaRoot
class_name StreetArtArea

## Art variant of the street: identical gameplay, presentation swapped.

const ART_PRESENTATION_SCENE := preload("res://scenes/environment/chapter_zero/street_art_presentation.tscn")
const GREYBOX_VISUAL_GROUP := "street_greybox_visual"

@export var show_greybox_visuals: bool = false
@export var show_art_presentation: bool = true

var _art_presentation: StreetArtPresentation = null
var _greybox_tagged: bool = false


func _ready() -> void:
	super._ready()
	call_deferred("_apply_visual_mode")


func _apply_visual_mode() -> void:
	_tag_greybox_visuals()
	_set_greybox_visible(show_greybox_visuals)
	if show_art_presentation and _art_presentation == null:
		_art_presentation = ART_PRESENTATION_SCENE.instantiate() as StreetArtPresentation
		if _art_presentation != null:
			add_child(_art_presentation)
			move_child(_art_presentation, 0)
	elif _art_presentation != null:
		_art_presentation.visible = show_art_presentation


func set_visual_mode(use_art: bool) -> void:
	show_art_presentation = use_art
	show_greybox_visuals = not use_art
	_apply_visual_mode()


func get_art_presentation() -> StreetArtPresentation:
	return _art_presentation


func _tag_greybox_visuals() -> void:
	if _greybox_tagged:
		return
	_greybox_tagged = true
	for node in find_children("*", "Polygon2D", true, false):
		if node is Polygon2D and not node.is_in_group(GREYBOX_VISUAL_GROUP):
			node.add_to_group(GREYBOX_VISUAL_GROUP)
	for node in find_children("*", "Label", true, false):
		if node.name in ["AreaLabel", "GuideLabel", "TutorialDodgeLabel", "GunslingerPrompt", "DuoPrompt", "SecretLabel", "ExitLabel"]:
			if not node.is_in_group(GREYBOX_VISUAL_GROUP):
				node.add_to_group(GREYBOX_VISUAL_GROUP)


func _set_greybox_visible(visible_state: bool) -> void:
	for node in get_tree().get_nodes_in_group(GREYBOX_VISUAL_GROUP):
		if is_ancestor_of(node):
			node.visible = visible_state
