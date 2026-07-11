extends RefCounted
class_name FeedbackUiHelper

## Optional UI audio hook without hard scene coupling.


static func play_navigate(tree: SceneTree) -> void:
	_play(tree, AudioEventId.UI_NAVIGATE)


static func play_confirm(tree: SceneTree) -> void:
	_play(tree, AudioEventId.UI_CONFIRM)


static func _play(tree: SceneTree, event_id: StringName) -> void:
	if tree == null:
		return
	for node in tree.get_nodes_in_group(AudioManager.AUDIO_MANAGER_GROUP):
		if node is AudioManager:
			(node as AudioManager).play_ui(event_id)
			return

	for node in tree.get_nodes_in_group(CombatFeedbackDirector.FEEDBACK_DIRECTOR_GROUP):
		if node is CombatFeedbackDirector:
			(node as CombatFeedbackDirector).play_ui(event_id)
			return
