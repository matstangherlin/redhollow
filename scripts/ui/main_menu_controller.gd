extends Control
class_name MainMenuController

const GAME_SCENE := "res://scenes/demo/vertical_slice_greybox.tscn"

@onready var _new_game_button: Button = %NewGameButton
@onready var _continue_button: Button = %ContinueButton
@onready var _options_button: Button = %OptionsButton
@onready var _credits_button: Button = %CreditsButton
@onready var _quit_button: Button = %QuitButton
@onready var _status_label: Label = %StatusLabel
@onready var _options_menu: OptionsMenu = %OptionsMenu
@onready var _credits_screen: CreditsScreen = %CreditsScreen
@onready var _confirmation_dialog: ConfirmationDialogView = %ConfirmationDialog
@onready var _loading_screen: LoadingScreen = %LoadingScreen

var _pending_new_game: bool = false


func _ready() -> void:
	if GameBootState != null:
		GameBootState.set_active_manifest_path(ContentManifest.PATH_BETA_DEMO)
	UiThemeHelper.style_title_label(get_node_or_null("%TitleLabel") as Label)
	_connect_buttons()
	_refresh_continue_state()
	if _options_menu != null:
		_options_menu.closed.connect(_on_submenu_closed)
	if _credits_screen != null:
		_credits_screen.closed.connect(_on_submenu_closed)
	if _confirmation_dialog != null:
		_confirmation_dialog.confirmed.connect(_on_confirmation_confirmed)
		_confirmation_dialog.cancelled.connect(_on_confirmation_cancelled)
	if _new_game_button != null:
		_new_game_button.grab_focus()


func _connect_buttons() -> void:
	if _new_game_button != null:
		_new_game_button.pressed.connect(_on_new_game_pressed)
	if _continue_button != null:
		_continue_button.pressed.connect(_on_continue_pressed)
	if _options_button != null:
		_options_button.pressed.connect(_on_options_pressed)
	if _credits_button != null:
		_credits_button.pressed.connect(_on_credits_pressed)
	if _quit_button != null:
		_quit_button.pressed.connect(_on_quit_pressed)


func _refresh_continue_state() -> void:
	var inspection := _inspect_save_slot()
	var enabled := String(inspection.get("status", "none")) == "valid"
	if _continue_button != null:
		_continue_button.disabled = not enabled
	if _status_label != null:
		_status_label.text = String(inspection.get("message", ""))


func _inspect_save_slot() -> Dictionary:
	return SaveManager.inspect_slot()


func _on_new_game_pressed() -> void:
	var inspection := _inspect_save_slot()
	if String(inspection.get("status", "none")) == "valid":
		_pending_new_game = true
		if _confirmation_dialog != null:
			_confirmation_dialog.present(
				"Iniciar novo jogo?",
				"Isso substituirá o progresso salvo atual. Deseja continuar?",
				"Novo Jogo",
				"Cancelar"
			)
		return
	_start_new_game()


func _on_continue_pressed() -> void:
	var inspection := _inspect_save_slot()
	var status := String(inspection.get("status", "none"))
	if status == "corrupted":
		_set_status("Save corrompido. Inicie um novo jogo.")
		return
	if status == "incompatible":
		_set_status("Save incompatível com esta versão.")
		return
	if status != "valid":
		return

	if GameBootState != null:
		GameBootState.set_continue_game()
	_start_game_scene()


func _on_options_pressed() -> void:
	if _options_menu != null:
		_options_menu.show_options()


func _on_credits_pressed() -> void:
	if _credits_screen != null:
		_credits_screen.show_credits()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_submenu_closed() -> void:
	if _new_game_button != null:
		_new_game_button.grab_focus()


func _on_confirmation_confirmed() -> void:
	if _pending_new_game:
		_pending_new_game = false
		_start_new_game()


func _on_confirmation_cancelled() -> void:
	_pending_new_game = false


func _start_new_game() -> void:
	if GameBootState != null:
		GameBootState.set_new_game()
	_start_game_scene()


func _start_game_scene() -> void:
	if GameBootState != null and GameBootState.get_active_manifest() != null:
		var manifest := GameBootState.get_active_manifest()
		var shell_path := manifest.game_shell_scene_path
		if not shell_path.is_empty() and ResourceLoader.exists(shell_path):
			if _loading_screen != null:
				_loading_screen.show_loading("Iniciando...")
			get_tree().change_scene_to_file(shell_path)
			return
	if _loading_screen != null:
		_loading_screen.show_loading("Iniciando...")
	get_tree().change_scene_to_file(GAME_SCENE)


func _set_status(message: String) -> void:
	if _status_label != null:
		_status_label.text = message
