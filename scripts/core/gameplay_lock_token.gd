extends RefCounted
class_name GameplayLockToken

var id: int = -1
var reason: int = -1
var owner_id: int = 0
var session_id: int = 0
var valid: bool = false


func invalidate() -> void:
	valid = false
	id = -1
