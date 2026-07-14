extends Node
class_name ProductShell

const MAIN_MENU_SCENE := "res://scenes/product/main_menu.tscn"

@onready var _pause_menu: PauseMenuController = $PauseMenu
@onready var _loading_screen: LoadingScreen = $LoadingScreen

var _save_manager: SaveManager = null
var _lock_manager: GameplayLockManager = null
var _vertical_slice_controller: Node = null

var _boot_completed: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var game_root := get_parent()
	if game_root != null:
		_save_manager = game_root.get_node_or_null("%SaveManager") as SaveManager
		_lock_manager = game_root.get_node_or_null("GameplayLockManager") as GameplayLockManager
		_vertical_slice_controller = game_root.get_node_or_null("VerticalSliceController")
	if _pause_menu != null and _lock_manager != null:
		_pause_menu.bind_lock_manager(_lock_manager)
	if _lock_manager != null:
		_lock_manager.enable_debug_panic_unlock = false
	call_deferred("_run_boot_sequence")


func _run_boot_sequence() -> void:
	if _loading_screen != null:
		_loading_screen.show_loading("Preparando jogo...")

	await get_tree().process_frame
	await get_tree().process_frame

	var boot_mode := GameBootState.BootMode.NONE
	if GameBootState != null:
		boot_mode = GameBootState.consume_boot_mode()

	match boot_mode:
		GameBootState.BootMode.NEW_GAME:
			await _boot_new_game()
		GameBootState.BootMode.CONTINUE:
			await _boot_continue_game()
		_:
			await _boot_editor_fallback_session()

	if _loading_screen != null:
		_loading_screen.hide_loading()
	_boot_completed = true
	_notify_playtest_recorder(boot_mode)


func _notify_playtest_recorder(boot_mode: GameBootState.BootMode) -> void:
	var game_root := get_parent()
	if game_root == null:
		return
	var recorder := game_root.get_node_or_null("BetaPlaytestRecorder")
	if recorder == null or not recorder.has_method("note_boot"):
		return
	var label := "NONE"
	match boot_mode:
		GameBootState.BootMode.NEW_GAME:
			label = "NEW_GAME"
		GameBootState.BootMode.CONTINUE:
			label = "CONTINUE"
		_:
			label = "EDITOR_FALLBACK"
	recorder.call("note_boot", label)


func _boot_new_game() -> void:
	if _vertical_slice_controller != null and _vertical_slice_controller.has_method("return_to_start"):
		_vertical_slice_controller.call("return_to_start", true)
	elif _save_manager != null:
		_save_manager.archive_and_clear_slot()
		_save_manager.create_new_save(true)
	await get_tree().process_frame


func _boot_continue_game() -> void:
	if _save_manager == null:
		push_warning("ProductShell CONTINUE failed — SaveManager missing.")
		_return_to_menu_after_boot_failure()
		return

	if _save_manager.load_game():
		return

	push_warning(
		"ProductShell continue load failed: %s"
		% _save_manager.get_last_debug_message()
	)
	_return_to_menu_after_boot_failure()


func _boot_editor_fallback_session() -> void:
	# No GameBootState intent (editor / direct greybox run).
	# Never auto-load disk save. Keep slot untouched; start playable street defaults.
	push_warning(
		"ProductShell started without NEW_GAME/CONTINUE — editor fallback: street session, no auto-load."
	)
	if _vertical_slice_controller != null and _vertical_slice_controller.has_method("return_to_start"):
		_vertical_slice_controller.call("return_to_start", false)
	elif _save_manager != null:
		_save_manager.create_new_save(false)
	await get_tree().process_frame


func _return_to_menu_after_boot_failure() -> void:
	if _loading_screen != null:
		_loading_screen.hide_loading()
	if GameBootState != null:
		GameBootState.return_to_main_menu = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func return_to_main_menu_from_game() -> void:
	if GameBootState != null:
		GameBootState.return_to_main_menu = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
