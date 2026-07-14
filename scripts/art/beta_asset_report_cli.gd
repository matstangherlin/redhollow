extends SceneTree

## Headless CLI: print beta asset manifesto report to stdout (+ optional user:// copy).
## Usage:
##   godot --headless --path . --script res://scripts/art/beta_asset_report_cli.gd

const Report := preload("res://scripts/art/beta_asset_report.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var text := Report.format_text()
	print(text)
	var written := Report.write_to_user("user://beta_asset_report.txt")
	if not written.is_empty():
		print("")
		print("Also wrote: %s" % written)
	quit(0)
