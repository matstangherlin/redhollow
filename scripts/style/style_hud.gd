extends CanvasLayer

const FEEDBACK_VISIBLE_TIME := 1.35
const TAUNT_LINE_VISIBLE_TIME := 2.75

@onready var rank_label: Label = %RankLabel
@onready var score_label: Label = %ScoreLabel
@onready var progress_bar: ProgressBar = %RankProgressBar
@onready var multiplier_label: Label = %MultiplierLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var taunt_line_label: Label = %TauntLineLabel
@onready var taunt_line_panel: PanelContainer = get_node_or_null("%TauntLinePanel")
@onready var red_brand_bar: ProgressBar = %RedBrandBar
@onready var red_brand_value_label: Label = %RedBrandValueLabel
@onready var brand_charge_label: Label = %BrandChargeLabel

var _style_manager: Node = null
var _red_brand_component: Node = null
var _feedback_timer: float = 0.0
var _taunt_line_timer: float = 0.0


func _process(delta: float) -> void:
	if _feedback_timer > 0.0:
		_feedback_timer = maxf(_feedback_timer - delta, 0.0)
		if _feedback_timer <= 0.0 and feedback_label != null:
			feedback_label.text = ""

	if _taunt_line_timer > 0.0:
		_taunt_line_timer = maxf(_taunt_line_timer - delta, 0.0)
		if _taunt_line_timer <= 0.0:
			if taunt_line_label != null:
				taunt_line_label.text = ""
			if taunt_line_panel != null:
				taunt_line_panel.visible = false


func show_taunt_line(phrase: String) -> void:
	if taunt_line_label == null:
		return

	taunt_line_label.text = "\"%s\"" % phrase
	if taunt_line_panel != null:
		taunt_line_panel.visible = true
	_taunt_line_timer = TAUNT_LINE_VISIBLE_TIME


func bind_red_brand_component(red_brand_component: Node) -> void:
	if _red_brand_component != null and _red_brand_component.has_signal("energy_changed"):
		if _red_brand_component.is_connected("energy_changed", Callable(self, "_on_red_brand_changed")):
			_red_brand_component.disconnect("energy_changed", Callable(self, "_on_red_brand_changed"))

	_red_brand_component = red_brand_component
	if _red_brand_component == null:
		return

	_red_brand_component.connect("energy_changed", Callable(self, "_on_red_brand_changed"))
	_refresh_red_brand()


func show_brand_charge(is_visible: bool) -> void:
	if brand_charge_label == null:
		return

	if not is_visible:
		brand_charge_label.text = ""


func update_brand_charge(charge_time: float, preview_level: int) -> void:
	if brand_charge_label == null:
		return

	if preview_level <= 0:
		brand_charge_label.text = "Charging... %.2fs" % charge_time
	elif preview_level == 1:
		brand_charge_label.text = "Breaker Lv1 ready (%.2fs)" % charge_time
	else:
		brand_charge_label.text = "Breaker MAX ready (%.2fs)" % charge_time


func _on_red_brand_changed(_current_energy: float, _max_energy: float) -> void:
	_refresh_red_brand()


func _refresh_red_brand() -> void:
	if _red_brand_component == null:
		return

	var current_energy := float(_red_brand_component.get("current_energy"))
	var max_energy := float(_red_brand_component.get("max_energy"))
	var ratio := 0.0
	if _red_brand_component.has_method("get_energy_ratio"):
		ratio = float(_red_brand_component.call("get_energy_ratio"))

	if red_brand_bar != null:
		red_brand_bar.value = ratio * 100.0

	if red_brand_value_label != null:
		red_brand_value_label.text = "%.0f / %.0f" % [current_energy, max_energy]


func bind_style_manager(style_manager: Node) -> void:
	if _style_manager != null and _style_manager.has_signal("style_changed"):
		if _style_manager.is_connected("style_changed", Callable(self, "_on_style_changed")):
			_style_manager.disconnect("style_changed", Callable(self, "_on_style_changed"))
	if _style_manager != null and _style_manager.has_signal("style_feedback"):
		if _style_manager.is_connected("style_feedback", Callable(self, "_on_style_feedback")):
			_style_manager.disconnect("style_feedback", Callable(self, "_on_style_feedback"))

	_style_manager = style_manager
	if _style_manager == null:
		return

	_style_manager.connect("style_changed", Callable(self, "_on_style_changed"))
	_style_manager.connect("style_feedback", Callable(self, "_on_style_feedback"))
	_refresh_from_manager()


func _on_style_changed(_style_score: float, _style_rank: StringName) -> void:
	_refresh_from_manager()


func _on_style_feedback(message: String, amount: float) -> void:
	if feedback_label == null:
		return

	if is_zero_approx(amount):
		feedback_label.text = message
	else:
		var sign_prefix := "+" if amount > 0.0 else ""
		feedback_label.text = "%s (%s%.0f)" % [message, sign_prefix, amount]

	_feedback_timer = FEEDBACK_VISIBLE_TIME


func _refresh_from_manager() -> void:
	if _style_manager == null:
		return

	var score := float(_style_manager.get("style_score"))
	var rank := StringName(_style_manager.get("style_rank"))
	var multiplier := float(_style_manager.call("get_reward_multiplier"))
	var progress := float(_style_manager.call("get_rank_progress"))

	if rank_label != null:
		rank_label.text = String(rank)

	if score_label != null:
		score_label.text = "%.0f" % score

	if progress_bar != null:
		progress_bar.value = progress * 100.0

	if multiplier_label != null:
		multiplier_label.text = "Reward x%.2f" % multiplier
