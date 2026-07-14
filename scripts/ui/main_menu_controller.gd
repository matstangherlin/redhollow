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

enum ConfirmIntent {
	NONE,
	NEW_GAME_OVERWRITE,
	NEW_GAME_AFTER_CORRUPT,
}

var _confirm_intent: ConfirmIntent = ConfirmIntent.NONE


func _ready() -> void:
	if GameBootState != null:
		GameBootState.set_active_manifest_path(ContentManifest.PATH_BETA_DEMO)
	UiThemeHelper.style_title_label(get_node_or_null("%TitleLabel") as Label)
	UiThemeHelper.style_body_label(_status_label)
	for button in [_new_game_button, _continue_button, _options_button, _credits_button, _quit_button]:
		UiThemeHelper.style_menu_button(button)
	var dim := get_node_or_null("Background") as ColorRect
	if dim != null:
		dim.color = Color(0.045, 0.035, 0.05, 1.0)
	_connect_buttons()
	_refresh_continue_state()
	_start_menu_music()
	if _options_menu != null:
		_options_menu.closed.connect(_on_submenu_closed)
	if _credits_screen != null:
		_credits_screen.closed.connect(_on_submenu_closed)
	if _confirmation_dialog != null:
		_confirmation_dialog.confirmed.connect(_on_confirmation_confirmed)
		_confirmation_dialog.cancelled.connect(_on_confirmation_cancelled)
	if _new_game_button != null:
		_new_game_button.grab_focus()


func _start_menu_music() -> void:
	var existing := get_tree().get_first_node_in_group(MusicController.MUSIC_CONTROLLER_GROUP)
	var music: MusicController = existing as MusicController
	if music == null:
		music = MusicController.new()
		music.name = "MenuMusicController"
		add_child(music)
	music.play_slot(MusicSlotId.MENU)


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
	var status := String(inspection.get("status", "none"))
	var enabled := status == "valid"
	if _continue_button != null:
		_continue_button.disabled = not enabled
	if _status_label != null:
		_status_label.text = String(inspection.get("message", ""))


func _inspect_save_slot() -> Dictionary:
	return SaveManager.inspect_slot(
		SaveManager.DEFAULT_SLOT_ID,
		ContentManifest.PATH_BETA_DEMO
	)


func _on_new_game_pressed() -> void:
	var inspection := _inspect_save_slot()
	var status := String(inspection.get("status", "none"))
	if status == "none":
		_start_new_game()
		return

	if status == "corrupted":
		_confirm_intent = ConfirmIntent.NEW_GAME_AFTER_CORRUPT
		if _confirmation_dialog != null:
			_confirmation_dialog.present(
				"Save corrompido",
				"O progresso salvo não pôde ser lido. O backup existente não será sobrescrito agora. Deseja iniciar um Novo Jogo? O save anterior será arquivado.",
				"Novo Jogo",
				"Cancelar"
			)
		return

	_confirm_intent = ConfirmIntent.NEW_GAME_OVERWRITE
	if _confirmation_dialog != null:
		_confirmation_dialog.present(
			"Iniciar novo jogo?",
			"Isso arquivará e substituirá o progresso salvo atual. Deseja continuar?",
			"Novo Jogo",
			"Cancelar"
		)


func _on_continue_pressed() -> void:
	var inspection := _inspect_save_slot()
	var status := String(inspection.get("status", "none"))
	if status == "corrupted":
		_set_status(String(inspection.get("message", "Save corrompido. Inicie um Novo Jogo.")))
		_offer_new_game_after_problem()
		return
	if status == "incompatible":
		_set_status(String(inspection.get("message", "Save incompatível com esta versão.")))
		_offer_new_game_after_problem()
		return
	if status != "valid":
		return

	if GameBootState != null:
		GameBootState.set_continue_game()
	_start_game_scene()


func _offer_new_game_after_problem() -> void:
	_confirm_intent = ConfirmIntent.NEW_GAME_AFTER_CORRUPT
	if _confirmation_dialog != null:
		_confirmation_dialog.present(
			"Não foi possível continuar",
			"O save não pode ser carregado. Deseja iniciar um Novo Jogo? O arquivo anterior será arquivado com segurança.",
			"Novo Jogo",
			"Cancelar"
		)


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
	if _confirm_intent == ConfirmIntent.NONE:
		return
	_confirm_intent = ConfirmIntent.NONE
	_start_new_game()


func _on_confirmation_cancelled() -> void:
	_confirm_intent = ConfirmIntent.NONE


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
