extends CanvasLayer
class_name PauseMenuController

signal resumed
signal requested_main_menu

const MAIN_MENU_SCENE := "res://scenes/product/main_menu.tscn"

@onready var _root: Control = %PauseRoot
@onready var _resume_button: Button = %ResumeButton
@onready var _options_button: Button = %OptionsButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _options_menu: OptionsMenu = %OptionsMenu
@onready var _confirmation_dialog: ConfirmationDialogView = %ConfirmationDialog

var _lock_manager: GameplayLockManager = null
var _pause_token: GameplayLockToken = null
var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if _root != null:
		_root.visible = false
	if _resume_button != null:
		_resume_button.pressed.connect(_on_resume_pressed)
	if _options_button != null:
		_options_button.pressed.connect(_on_options_pressed)
	if _main_menu_button != null:
		_main_menu_button.pressed.connect(_on_main_menu_pressed)
	if _options_menu != null:
		_options_menu.closed.connect(_on_options_closed)
	if _confirmation_dialog != null:
		_confirmation_dialog.confirmed.connect(_on_main_menu_confirmed)
		_confirmation_dialog.cancelled.connect(_on_main_menu_cancelled)


func bind_lock_manager(manager: GameplayLockManager) -> void:
	_lock_manager = manager


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if _is_open:
			close_pause()
		elif can_open_pause():
			open_pause()
		get_viewport().set_input_as_handled()


func can_open_pause() -> bool:
	if _lock_manager == null:
		return false
	if _is_open:
		return false
	if _lock_manager.has_lock(GameplayLockManager.LockReason.DEATH):
		return false
	if _lock_manager.has_lock(GameplayLockManager.LockReason.LOADING):
		return false
	if _lock_manager.has_lock(GameplayLockManager.LockReason.AREA_TRANSITION):
		return false
	if _lock_manager.has_lock(GameplayLockManager.LockReason.COMPLETION):
		return false
	if _lock_manager.has_lock(GameplayLockManager.LockReason.DIALOGUE):
		return false
	return true


func open_pause() -> void:
	if not can_open_pause() or _lock_manager == null:
		return

	_pause_token = _lock_manager.acquire_lock(GameplayLockManager.LockReason.PAUSE, self)
	_is_open = true
	visible = true
	if _root != null:
		_root.visible = true
	if _resume_button != null:
		_resume_button.grab_focus()


func close_pause() -> void:
	if not _is_open:
		return

	if _lock_manager != null and _pause_token != null and _pause_token.valid:
		_lock_manager.release_lock(_pause_token)
	_pause_token = null
	_is_open = false
	visible = false
	if _root != null:
		_root.visible = false
	resumed.emit()


func is_pause_open() -> bool:
	return _is_open


func _on_resume_pressed() -> void:
	close_pause()


func _on_options_pressed() -> void:
	if _options_menu != null:
		_options_menu.show_options()


func _on_options_closed() -> void:
	if _is_open and _resume_button != null:
		_resume_button.grab_focus()


func _on_main_menu_pressed() -> void:
	if _confirmation_dialog != null:
		_confirmation_dialog.present(
			"Voltar ao menu?",
			"O progresso não salvo desde o último checkpoint pode ser perdido.",
			"Menu Principal",
			"Cancelar"
		)


func _on_main_menu_confirmed() -> void:
	close_pause()
	if GameBootState != null:
		GameBootState.return_to_main_menu = true
	requested_main_menu.emit()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _on_main_menu_cancelled() -> void:
	if _is_open and _main_menu_button != null:
		_main_menu_button.grab_focus()
