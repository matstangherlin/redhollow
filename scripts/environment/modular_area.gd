extends AreaRoot
class_name ModularArea

## Area assembled from EnvironmentKit modules. Preserves AreaRoot gameplay contract.

@export var environment_kit: EnvironmentKit
@export var area_visual_profile: AreaVisualProfile
@export var assemble_on_ready: bool = true

const STREET_KIT_PATH := "res://resources/environment/kits/chapter_zero_street_kit.tres"


func _ready() -> void:
	super._ready()
	if environment_kit == null:
		environment_kit = load(STREET_KIT_PATH) as EnvironmentKit
	if environment_kit == null:
		environment_kit = EnvironmentKitFactory.create_street_kit()
	if assemble_on_ready:
		call_deferred("_assemble")


func _assemble() -> void:
	EnvironmentKitAssembler.assemble_modules(self)


func get_environment_kit() -> EnvironmentKit:
	if environment_kit == null:
		environment_kit = EnvironmentKitFactory.create_street_kit()
	return environment_kit


func validate_kit() -> Dictionary:
	return EnvironmentKitValidator.validate_area(self)
