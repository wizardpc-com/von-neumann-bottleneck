extends Node
## Synthetic UI input in an isolated copy of the macOS Test Edition.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var profile: String = str(ProjectSettings.get_setting("candidate/profile", ""))
	if not OS.has_feature("test_edition") or not profile.begins_with("PackageFeedback-Staging-") or not OS.get_user_data_dir().ends_with("/" + profile):
		fail("isolated Test Edition required")
		return
	var remote: Node = get_node("/root/RemoteFeedback")
	var phase: String = str(ProjectSettings.get_setting("qa_feedback/phase", ""))
	if phase == "delete":
		if remote.consented_endpoint != remote.endpoint:
			print("STAGING_NO_SUBMISSION")
			get_tree().quit()
			return
		remote.delete_uploaded_data()
		for attempt: int in 120:
			if remote.identity_deleted and remote.status == "deleted":
				print("STAGING_DELETED")
				get_tree().quit()
				return
			await get_tree().create_timer(0.1).timeout
		fail("deletion was not acknowledged")
		return
	if phase != "submit" or not get_node("/root/GameMode").is_test_mode() or not remote.endpoint.begins_with("https://") or remote.enabled or remote.scores_enabled:
		fail("unexpected stage configuration or sharing mode")
		return
	var moments: Node = get_node("/root/PlaytestMoments")
	moments.open_for_task("creation", "G2_intent")
	var send: Button = moments.panel.find_child("SendTaskFeedback", true, false)
	if not moments.panel.visible or send == null or send.disabled:
		fail("remote opinion form is not available")
		return
	moments.opinion.text = "SYNTHETIC VNB staging connectivity"
	send.pressed.emit()
	if moments.saved_opinion.is_empty():
		fail("opinion was not saved")
		return
	var id: String = remote.feedback_id(moments.saved_opinion)
	print("STAGING_ID ", id)
	for attempt: int in 120:
		if remote.feedback_state(id) == "sent":
			if not remote.queue.is_empty() or remote.enabled or remote.scores_enabled or not moments.opinion_status.text.contains(id):
				fail("opinion receipt or sharing state does not match")
				return
			print("STAGING_RECEIVED ", id)
			get_tree().quit()
			return
		await get_tree().create_timer(0.1).timeout
	fail("opinion was not acknowledged (" + remote.status + ")")

func fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
