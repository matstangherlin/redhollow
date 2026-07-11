extends SceneTree

const DIALOGUE_PATH := "res://data/dialogues/dialogues_pt_br.json"
const VALID_ID := &"elias_church_warning"
const INVALID_ID := &"missing_dialogue_id"


func _initialize() -> void:
	var failures: PackedStringArray = PackedStringArray()
	_test_library(failures)
	_test_controller(failures)
	_test_player_input_lock(failures)

	if failures.is_empty():
		print("Dialogue tests passed.")
	else:
		for failure in failures:
			push_error(failure)
		print("Dialogue tests failed: %s" % failures.size())

	quit()


func _test_library(failures: PackedStringArray) -> void:
	var library := DialogueLibrary.new()
	if not library.load_from_file(DIALOGUE_PATH):
		failures.append("Library failed to load %s: %s" % [DIALOGUE_PATH, library.get_load_error()])
		return

	if not library.has_dialogue(VALID_ID):
		failures.append("Valid dialogue id missing from library.")

	var entry := library.get_dialogue(VALID_ID)
	if entry.is_empty():
		failures.append("Valid dialogue entry returned empty dictionary.")
		return

	if String(entry.get("speaker", "")) != "Elias":
		failures.append("Valid dialogue speaker mismatch.")

	var lines := entry.get("lines", PackedStringArray()) as PackedStringArray
	if lines.size() != 3:
		failures.append("Valid dialogue line count mismatch.")

	var missing := library.get_dialogue(INVALID_ID)
	if not missing.is_empty():
		failures.append("Invalid dialogue id should return empty dictionary.")


func _test_controller(failures: PackedStringArray) -> void:
	var controller_scene := load("res://scenes/core/dialogue_system.tscn") as PackedScene
	if controller_scene == null:
		failures.append("Failed to load dialogue system scene.")
		return

	var controller_root := controller_scene.instantiate()
	if controller_root == null:
		failures.append("Failed to instantiate dialogue system scene.")
		return

	root.add_child(controller_root)

	var controller := controller_root as DialogueController
	if controller == null:
		failures.append("Dialogue system root is not a DialogueController.")
		controller_root.queue_free()
		return

	if not controller.try_start_dialogue(VALID_ID):
		failures.append("Valid dialogue id failed to start.")
		controller_root.queue_free()
		return

	if not controller.is_active:
		failures.append("Controller should be active after valid start.")

	controller._advance_or_close()
	if controller.is_active != true:
		failures.append("Controller should remain active after first advance.")

	controller._advance_or_close()
	if controller.is_active != true:
		failures.append("Controller should remain active after second advance.")

	controller._advance_or_close()
	if controller.is_active:
		failures.append("Controller should close after final advance.")

	if not controller.try_start_dialogue(INVALID_ID):
		pass
	else:
		failures.append("Invalid dialogue id should not start.")

	if controller.is_active:
		failures.append("Controller should stay inactive after invalid id.")

	if not controller.try_start_dialogue(VALID_ID):
		failures.append("Dialogue should reopen after closing.")
	elif not controller.is_active:
		failures.append("Reopened dialogue should be active.")
	else:
		controller.close_dialogue()

	if controller.is_active:
		failures.append("Controller should close cleanly.")

	controller_root.queue_free()


func _test_player_input_lock(failures: PackedStringArray) -> void:
	var player_scene := load("res://scenes/player/player.tscn") as PackedScene
	if player_scene == null:
		failures.append("Failed to load player scene for dialogue input test.")
		return

	var player := player_scene.instantiate()
	if player == null:
		failures.append("Failed to instantiate player for dialogue input test.")
		return

	root.add_child(player)
	player.call("enter_dialogue_mode")

	if not bool(player.call("is_in_dialogue")):
		failures.append("Player should report dialogue lock while in dialogue mode.")

	if bool(player.call("can_interact_now")):
		failures.append("Player should block world interact during dialogue.")

	if bool(player.call("_can_accept_attack_input")):
		failures.append("Player should block attack input during dialogue.")

	player.call("exit_dialogue_mode")
	player.queue_free()
