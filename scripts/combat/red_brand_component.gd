extends Node
class_name RedBrandComponent

signal energy_changed(current_energy: float, max_energy: float)

@export var config: RedBrandConfig = preload("res://resources/combat/red_brand_config.tres")

var current_energy: float = 0.0
var max_energy: float = 100.0
var gain_multiplier: float = 1.0


func _ready() -> void:
	_apply_config()
	reset_energy()


func reset_energy() -> void:
	if config == null:
		current_energy = 0.0
		max_energy = 100.0
		gain_multiplier = 1.0
	else:
		max_energy = maxf(config.max_energy, 0.0)
		gain_multiplier = _get_total_gain_multiplier()
		current_energy = clampf(config.arena_reset_energy, 0.0, max_energy)

	energy_changed.emit(current_energy, max_energy)


func gain_energy(amount: float, _source: StringName = &"") -> float:
	if amount <= 0.0:
		return 0.0

	var scaled_amount := amount * gain_multiplier
	var previous_energy := current_energy
	current_energy = minf(current_energy + scaled_amount, max_energy)
	var applied := current_energy - previous_energy

	if applied > 0.0:
		energy_changed.emit(current_energy, max_energy)

	return applied


func set_energy(value: float) -> void:
	current_energy = clampf(value, 0.0, max_energy)
	energy_changed.emit(current_energy, max_energy)


func consume_energy(amount: float, _reason: StringName = &"") -> bool:
	if amount <= 0.0:
		return true

	if not can_consume(amount):
		return false

	current_energy = maxf(current_energy - amount, 0.0)
	energy_changed.emit(current_energy, max_energy)
	return true


func can_consume(amount: float) -> bool:
	return amount > 0.0 and current_energy >= amount


func get_energy_ratio() -> float:
	if max_energy <= 0.0:
		return 0.0

	return clampf(current_energy / max_energy, 0.0, 1.0)


func apply_upgrade_gain_multiplier(multiplier: float) -> void:
	if config == null:
		return

	config.upgrade_gain_multiplier = maxf(multiplier, 0.0)
	gain_multiplier = _get_total_gain_multiplier()


func _apply_config() -> void:
	if config == null:
		return

	max_energy = maxf(config.max_energy, 0.0)
	gain_multiplier = _get_total_gain_multiplier()


func _get_total_gain_multiplier() -> float:
	if config == null:
		return 1.0

	return maxf(config.gain_multiplier * config.upgrade_gain_multiplier, 0.0)
