extends RefCounted
class_name GameVersion

## Canonical version identifiers for Red Hollow beta builds.
## Keep in sync with export presets and docs/SAVE_COMPATIBILITY.md.

const GAME_VERSION := "0.2.0-beta.rc1"
const BUILD_CHANNEL := "rc1-closed"
const BUILD_NAME_PREFIX := "red-hollow"
const DISPLAY_NAME := "Red Hollow — Chapter Zero Beta RC1"
## Calendar build stamp (UTC date of packaging). Not a Steam build id.
const BUILD_NUMBER := "20260713.rc1"

## Mirrors SaveData.CURRENT_SAVE_VERSION — do not bump without migration plan.
const SAVE_FORMAT_VERSION := 1

## Mirrors SettingsData.CURRENT_SETTINGS_VERSION.
const SETTINGS_FORMAT_VERSION := 1


static func get_build_name(git_short_hash: String = "unknown", debug: bool = false) -> String:
	var suffix := "debug" if debug else "release"
	return "%s-%s-%s-%s" % [BUILD_NAME_PREFIX, GAME_VERSION, git_short_hash, suffix]


static func get_version_label() -> String:
	return "%s (%s · %s)" % [DISPLAY_NAME, GAME_VERSION, BUILD_CHANNEL]


static func get_build_number() -> String:
	return BUILD_NUMBER
