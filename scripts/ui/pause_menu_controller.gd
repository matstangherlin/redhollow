extends CanvasLayer
class_name PauseMenuController

signal resumed
signal requested_main_menu

const MAIN_MENU_SCENE := "res://scenes/product/main_menu.tscn"

@onready var _root: Control = %PauseRoot
@onready var _resume_button: Button = %ResumeButton
@onready var _options_button: Button = %OptionsButton
@onready var _controls_button: Button = %ControlsButton
@onready var _main_menu_button: Button = %MainMenuButton
@onready var _options_menu: OptionsMenu = %OptionsMenu
@onready var _confirmation_dialog: ConfirmationDialogView = %ConfirmationDialog
@onready var _controls_panel: Control = %ControlsPanel
@onready var _controls_reference_label: Label = %ControlsReferenceLabel
@onready var _controls_back_button: Button = %ControlsBackButton

var _lock_manager: GameplayLockManager = null
var _pause_token: GameplayLockToken = null
var _is_open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if _root != null:
		_root.visible = false
	var panel := get_node_or_null("PauseRoot/Panel") as PanelContainer
	if panel != null:
		UiThemeHelper.style_panel(panel)
	var dim := get_node_or_null("PauseRoot/Dim") as ColorRect
	if dim != null:
		UiThemeHelper.style_dim(dim)
	UiThemeHelper.style_title_label(get_node_or_null("PauseRoot/Panel/VBox/Title") as Label)
	for button in [_resume_button, _options_button, _controls_button, _main_menu_button, _controls_back_button]:
		UiThemeHelper.style_menu_button(button)
	if _resume_button != null:
		_resume_button.pressed.connect(_on_resume_pressed)
	if _options_button != null:
		_options_button.pressed.connect(_on_options_pressed)
	if _controls_button != null:
		_controls_button.pressed.connect(_on_controls_pressed)
	if _main_menu_button != null:
		_main_menu_button.pressed.connect(_on_main_menu_pressed)
	if _options_menu != null:
		_options_menu.closed.connect(_on_options_closed)
	if _confirmation_dialog != null:
		_confirmation_dialog.confirmed.connect(_on_main_menu_confirmed)
		_confirmation_dialog.cancelled.connect(_on_main_menu_cancelled)
	if _controls_back_button != null:
		_controls_back_button.pressed.connect(_on_controls_back_pressed)
	if _controls_reference_label != null:
		_controls_reference_label.text = ControlsTutorialOverlay.get_controls_reference()
		UiThemeHelper.style_body_label(_controls_reference_label)


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
	_set_controls_panel_visible(false)
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
	_set_controls_panel_visible(false)
	resumed.emit()


func is_pause_open() -> bool:
	return _is_open


func _on_resume_pressed() -> void:
	close_pause()


func _on_options_pressed() -> void:
	if _options_menu != null:
		_options_menu.show_options()


func _on_controls_pressed() -> void:
	_set_controls_panel_visible(true)
	if _controls_back_button != null:
		_controls_back_button.grab_focus()


func _on_controls_back_pressed() -> void:
	_set_controls_panel_visible(false)
	if _controls_button != null:
		_controls_button.grab_focus()


func _set_controls_panel_visible(is_visible: bool) -> void:
	if _controls_panel != null:
		_controls_panel.visible = is_visible
	if _root == null:
		return
	var panel := _root.get_node_or_null("Panel")
	if panel != null:
		panel.visible = not is_visible


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
