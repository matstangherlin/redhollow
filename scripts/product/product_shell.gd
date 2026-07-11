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
			await _boot_default_session()

	if _loading_screen != null:
		_loading_screen.hide_loading()
	_boot_completed = true


func _boot_new_game() -> void:
	if _vertical_slice_controller != null and _vertical_slice_controller.has_method("return_to_start"):
		_vertical_slice_controller.call("return_to_start")
	elif _save_manager != null:
		_save_manager.delete_save()
		_save_manager.create_new_save()
	await get_tree().process_frame


func _boot_continue_game() -> void:
	if _save_manager == null:
		await _boot_default_session()
		return

	if _save_manager.load_game():
		return

	push_warning(
		"ProductShell continue load failed: %s"
		% _save_manager.get_last_debug_message()
	)
	if _loading_screen != null:
		_loading_screen.hide_loading()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _boot_default_session() -> void:
	if _save_manager != null and not _save_manager.has_save():
		if _vertical_slice_controller != null and _vertical_slice_controller.has_method("return_to_start"):
			_vertical_slice_controller.call("return_to_start")
		else:
			_save_manager.create_new_save()
	await get_tree().process_frame


func return_to_main_menu_from_game() -> void:
	if GameBootState != null:
		GameBootState.return_to_main_menu = true
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)
