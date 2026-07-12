extends ModularArea
class_name KitModularRoom

## Pre-authored room templates using the street kit modules.

@export_enum("saloon_front", "alley_corner") var room_template: String = "saloon_front"


func _ready() -> void:
	_ensure_gameplay_folders()
	_ensure_template_exits()
	_spawn_template_if_needed()
	super._ready()
	call_deferred("_setup_background_parallax")


func _ensure_gameplay_folders() -> void:
	if get_node_or_null("Solids") == null:
		var solids := Node2D.new()
		solids.name = "Solids"
		add_child(solids)
		var ground := StaticBody2D.new()
		ground.name = "Ground"
		ground.position = Vector2(_room_width() * 0.5, 900)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(_room_width(), 48)
		shape.shape = rect
		ground.add_child(shape)
		solids.add_child(ground)

	if get_node_or_null("Spawns") == null:
		var spawns := Node2D.new()
		spawns.name = "Spawns"
		add_child(spawns)
		var spawn := AreaSpawnPoint.new()
		spawn.name = "DefaultSpawn"
		spawn.spawn_id = &"default"
		spawn.position = Vector2(80, 848)
		spawns.add_child(spawn)

	if get_node_or_null("Exits") == null:
		var exits := Node2D.new()
		exits.name = "Exits"
		add_child(exits)


func _ensure_template_exits() -> void:
	var exits := get_node_or_null("Exits") as Node2D
	if exits == null:
		return

	if room_template == "saloon_front" and exits.get_node_or_null("ToAlley") == null:
		_add_exit(exits, &"ToAlley", &"to_alley",
			"res://scenes/environment/modular/kit_room_alley_corner.tscn",
			&"default", Vector2(_room_width() - 24, 848))
		var spawns := get_node_or_null("Spawns") as Node2D
		if spawns != null and spawns.get_node_or_null("FromAlley") == null:
			var spawn := AreaSpawnPoint.new()
			spawn.name = "FromAlley"
			spawn.spawn_id = &"from_alley"
			spawn.position = Vector2(_room_width() - 80, 848)
			spawns.add_child(spawn)


func _add_exit(
	parent: Node2D,
	node_name: String,
	exit_id: StringName,
	target_scene: String,
	target_spawn: StringName,
	position: Vector2
) -> void:
	var area := AreaExit.new()
	area.name = node_name
	area.exit_id = exit_id
	area.target_scene = target_scene
	area.target_spawn_id = target_spawn
	area.position = position
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(24, 96)
	shape.shape = rect
	area.add_child(shape)
	parent.add_child(area)


func _setup_background_parallax() -> void:
	var layer := get_node_or_null("ModularLayers/LayerBackground") as Node2D
	if layer == null:
		return
	if layer.get_child_count() > 0:
		return

	var parallax := Parallax2D.new()
	parallax.name = "SkylineParallax"
	parallax.scroll_scale = Vector2(0.15, 0.05)
	parallax.z_index = -80

	var skyline := Polygon2D.new()
	skyline.color = Color(0.14, 0.11, 0.12, 1.0)
	skyline.polygon = PackedVector2Array([
		Vector2(0, 420), Vector2(80, 360), Vector2(200, 400), Vector2(320, 340),
		Vector2(_room_width(), 380), Vector2(_room_width(), 420), Vector2(0, 420),
	])
	parallax.add_child(skyline)
	layer.add_child(parallax)


func _room_width() -> float:
	return 640.0 if room_template == "saloon_front" else 560.0


func _spawn_template_if_needed() -> void:
	if get_child_count() > 0 and _has_module_markers():
		return

	var modules_root := Node2D.new()
	modules_root.name = "ModuleMarkers"
	add_child(modules_root)

	match room_template:
		"saloon_front":
			_spawn_saloon_front(modules_root)
		"alley_corner":
			_spawn_alley_corner(modules_root)
		_:
			push_warning("KitModularRoom: unknown template '%s'." % room_template)


func _has_module_markers() -> bool:
	return find_children("*", "EnvironmentModuleInstance", true, false).size() > 0


func _spawn_saloon_front(parent: Node2D) -> void:
	_add_module(parent, &"dirt_ground", Vector2(0, 876), Vector2(640, 16))
	_add_module(parent, &"wood_sidewalk", Vector2(0, 860), Vector2(640, 8))
	_add_module(parent, &"wall_wood", Vector2(120, 820))
	_add_module(parent, &"roof", Vector2(200, 760))
	_add_module(parent, &"door", Vector2(280, 820))
	_add_module(parent, &"window", Vector2(360, 780))
	_add_module(parent, &"balcony", Vector2(420, 760))
	_add_module(parent, &"sign", Vector2(240, 740))
	_add_module(parent, &"lantern", Vector2(180, 800))
	_add_module(parent, &"lamp_post", Vector2(80, 848))
	_add_module(parent, &"barrel", Vector2(520, 868))
	_add_module(parent, &"crate", Vector2(560, 868))
	_add_module(parent, &"fence", Vector2(600, 864))
	_add_module(parent, &"platform", Vector2(480, 800))


func _spawn_alley_corner(parent: Node2D) -> void:
	_add_module(parent, &"dirt_ground", Vector2(0, 876), Vector2(560, 16))
	_add_module(parent, &"wood_sidewalk", Vector2(0, 860), Vector2(400, 8))
	_add_module(parent, &"wall_stone", Vector2(100, 820))
	_add_module(parent, &"wall_stone", Vector2(300, 820))
	_add_module(parent, &"stairs", Vector2(220, 836))
	_add_module(parent, &"wagon", Vector2(400, 860))
	_add_module(parent, &"crate", Vector2(440, 868))
	_add_module(parent, &"barrel", Vector2(460, 868))
	_add_module(parent, &"fence", Vector2(500, 864))
	_add_module(parent, &"lantern", Vector2(160, 800))
	_add_module(parent, &"secret_passage", Vector2(340, 820))
	_add_module(parent, &"blocked_entrance", Vector2(60, 820))
	_add_module(parent, &"vermilite_barrier", Vector2(520, 808))


func _add_module(parent: Node2D, module_id: StringName, position: Vector2, _size: Vector2 = Vector2.ZERO) -> void:
	var marker := EnvironmentModuleInstance.new()
	marker.name = String(module_id)
	marker.module_id = module_id
	marker.position = position
	parent.add_child(marker)
