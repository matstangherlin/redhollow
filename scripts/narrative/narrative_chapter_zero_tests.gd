extends HeadlessSuiteRunner

const TestHelpers := preload("res://scripts/tests/test_helpers.gd")

const VS_MAIN := "res://scenes/demo/vertical_slice_greybox.tscn"
const OBJECTIVES_PATH := "res://data/narrative/chapter_zero_objectives.json"
const EVENTS_PATH := "res://data/narrative/chapter_zero_events.json"
const DIALOGUE_PATH := "res://data/dialogues/dialogues_pt_br.json"

const REQUIRED_DIALOGUES: Array[String] = [
	"cz_elias_opening",
	"cz_street_statue",
	"cz_partner_medallion",
	"cz_order_document",
	"cz_vermilite_reaction",
	"cz_partner_diary_page",
	"cz_deacon_intro",
]


func _run_suite() -> void:
	var suite := TestHelpers.begin_suite(get_tree(), "narrative_chapter_zero_tests")
	var failures: PackedStringArray = PackedStringArray()

	_test_objectives_data(failures)
	_test_events_data(failures)
	_test_objective_tracker_flow(failures)
	_test_demo_narrative_nodes(failures)
	_test_chapter_zero_dialogues(failures)
	await _test_narrative_director_conditions(failures)

	suite.finish(failures, 6)


func _test_objectives_data(failures: PackedStringArray) -> void:
	var library := ObjectiveLibrary.new()
	if not library.load_from_file(OBJECTIVES_PATH):
		failures.append("Chapter zero objectives JSON failed to load.")
		return

	var objectives := library.get_objectives()
	if objectives.size() < 8:
		failures.append("Expected at least 8 chapter zero objectives.")

	var first: Dictionary = objectives[0]
	if String(first.get("id", "")) != "cz_obj_opening":
		failures.append("First objective should be cz_obj_opening.")


func _test_events_data(failures: PackedStringArray) -> void:
	if not FileAccess.file_exists(EVENTS_PATH):
		failures.append("Chapter zero events JSON missing.")
		return

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(EVENTS_PATH))
	if typeof(parsed) != TYPE_DICTIONARY:
		failures.append("Chapter zero events JSON invalid.")
		return

	var events: Dictionary = (parsed as Dictionary).get("events", {})
	for required_event in [
		"cz_evt_met_elias",
		"cz_evt_partner_clue",
		"cz_evt_order_doc",
		"cz_evt_partner_evidence",
		"cz_evt_barrier_broken",
	]:
		if not events.has(required_event):
			failures.append("Missing narrative event: %s." % required_event)


func _test_objective_tracker_flow(failures: PackedStringArray) -> void:
	var tracker := ObjectiveTracker.new()
	if not tracker.load_objectives():
		failures.append("ObjectiveTracker failed to load objectives.")
		return

	var flags: Dictionary = {}
	var seen_opening: Array[bool] = [false]
	tracker.objective_changed.connect(
		func(objective_id: String, _title: String, _text: String) -> void:
			if objective_id == "cz_obj_opening":
				seen_opening[0] = true
	)
	tracker.refresh_from_flags(flags)
	if not seen_opening[0]:
		failures.append("ObjectiveTracker should start on cz_obj_opening.")

	flags[String(ChapterZeroFlags.MET_ELIAS)] = true
	flags[String(ChapterZeroFlags.STREET_STATUE_OBSERVED)] = true
	flags[String(ChapterZeroFlags.PARTNER_CLUE_FOUND)] = true
	flags[String(ChapterZeroFlags.STREET_BRAWLER_DEFEATED)] = true

	var seen_gunslinger: Array[bool] = [false]
	tracker.objective_changed.connect(
		func(objective_id: String, _title: String, _text: String) -> void:
			if objective_id == "cz_obj_gunslinger":
				seen_gunslinger[0] = true
	)
	tracker.refresh_from_flags(flags)
	if not seen_gunslinger[0]:
		failures.append("ObjectiveTracker should advance to gunslinger objective after street flags.")


func _test_demo_narrative_nodes(failures: PackedStringArray) -> void:
	var demo := load(VS_MAIN) as PackedScene
	if demo == null:
		failures.append("vertical_slice_greybox must load for narrative node contract.")
		return

	var root := demo.instantiate()
	for path in [
		"NarrativeDirector",
		"ObjectiveHud",
		"VerticalSliceController/ChapterZeroFinale",
	]:
		if root.get_node_or_null(path) == null:
			failures.append("Demo scene missing narrative node: %s." % path)
	root.queue_free()


func _test_chapter_zero_dialogues(failures: PackedStringArray) -> void:
	var library := DialogueLibrary.new()
	if not library.load_from_file(DIALOGUE_PATH):
		failures.append("Dialogue library failed to load for chapter zero contract.")
		return

	for dialogue_id in REQUIRED_DIALOGUES:
		if not library.has_dialogue(StringName(dialogue_id)):
			failures.append("Missing chapter zero dialogue id: %s." % dialogue_id)


func _test_narrative_director_conditions(failures: PackedStringArray) -> void:
	var test_root := Node.new()
	root.add_child(test_root)

	var progression := await TestHelpers.mount_progression(test_root, get_tree())
	var director := NarrativeDirector.new()
	test_root.add_child(director)
	await TestHelpers.await_frames(get_tree(), 2)

	(progression as ProgressionComponent).set_narrative_flag(
		ChapterZeroFlags.RED_BRAND_CACHE_USED,
		true
	)

	var conditions := {"requires_flags_any": ["vs_red_brand_cache_used"]}
	if not director.meets_dialogue_conditions(conditions):
		failures.append("NarrativeDirector should allow Vermilite dialogue after Red Brand cache.")

	(progression as ProgressionComponent).set_narrative_flag(ChapterZeroFlags.MET_ELIAS, true)
	conditions = {"excludes_flags": ["cz_met_elias"]}
	if director.meets_dialogue_conditions(conditions):
		failures.append("NarrativeDirector should block dialogue when excluded flag is set.")

	test_root.queue_free()
	await TestHelpers.await_frames(get_tree(), 1)
