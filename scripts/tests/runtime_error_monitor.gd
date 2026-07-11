extends RefCounted
class_name RuntimeErrorMonitor

## Captures engine errors and warnings during headless test runs.
## Expected messages must be registered explicitly via allow_contains().

class CaptureLogger extends Logger:
	var _monitor: RefCounted
	var _mutex: Mutex = Mutex.new()

	func _init(monitor: RefCounted) -> void:
		_monitor = monitor

	func _log_message(message: String, error: bool) -> void:
		_mutex.lock()
		_monitor._record_message(message, error)
		_mutex.unlock()

	func _log_error(
		function: String,
		file: String,
		line: int,
		code: String,
		rationale: String,
		editor_notify: bool,
		error_type: int,
		script_backtraces: Array[ScriptBacktrace]
	) -> void:
		_mutex.lock()
		_monitor._record_error(
			function,
			file,
			line,
			code,
			rationale,
			error_type,
			script_backtraces
		)
		_mutex.unlock()


const KIND_WARNING := "warning"
const KIND_ERROR := "error"
const KIND_SCRIPT := "script"
const KIND_MESSAGE := "message"

var _logger: CaptureLogger
var _allowed_patterns: PackedStringArray = PackedStringArray()
var _unexpected_issues: Array[Dictionary] = []
var _allowed_issues: Array[Dictionary] = []


func install() -> void:
	if _logger != null:
		return
	_logger = CaptureLogger.new(self)
	OS.add_logger(_logger)


func uninstall() -> void:
	if _logger == null:
		return
	OS.remove_logger(_logger)
	_logger = null


func allow_contains(fragment: String) -> void:
	if fragment.is_empty():
		return
	if not _allowed_patterns.has(fragment):
		_allowed_patterns.append(fragment)


func get_unexpected_issues() -> Array[Dictionary]:
	return _unexpected_issues.duplicate()


func get_allowed_issues() -> Array[Dictionary]:
	return _allowed_issues.duplicate()


func has_unexpected_issues() -> bool:
	return not _unexpected_issues.is_empty()


func unexpected_count() -> int:
	return _unexpected_issues.size()


func allowed_count() -> int:
	return _allowed_issues.size()


func _record_message(message: String, error: bool) -> void:
	var kind := KIND_MESSAGE
	if error:
		kind = KIND_ERROR
	_register_issue(kind, message, {})


func _record_error(
	function: String,
	file: String,
	line: int,
	code: String,
	rationale: String,
	error_type: int,
	script_backtraces: Array[ScriptBacktrace]
) -> void:
	var kind := KIND_ERROR
	if error_type == 1:
		kind = KIND_WARNING
	elif error_type == 2:
		kind = KIND_SCRIPT

	var parts: PackedStringArray = PackedStringArray()
	if not rationale.is_empty():
		parts.append(rationale)
	if not code.is_empty():
		parts.append(code)
	if not function.is_empty():
		parts.append(function)
	if not file.is_empty():
		parts.append(file)

	var message := " ".join(parts)
	var details := {
		"function": function,
		"file": file,
		"line": line,
		"code": code,
		"rationale": rationale,
		"error_type": error_type,
		"backtrace_count": script_backtraces.size(),
	}
	_register_issue(kind, message, details)


func _register_issue(kind: String, message: String, details: Dictionary) -> void:
	var issue := {
		"kind": kind,
		"message": message,
		"details": details,
	}
	if _is_allowed(message):
		_allowed_issues.append(issue)
	else:
		_unexpected_issues.append(issue)


func _is_allowed(message: String) -> bool:
	for pattern in _allowed_patterns:
		if message.contains(pattern):
			return true
	return false
