extends RefCounted
## Explicit normal acquisition after a busy window; never reclaims a stopped owner.
const Lease = preload("res://experiments/candidate_session/writer_lease.gd")

static func attempt(save_path: String, expected_digest: String, reader: Callable) -> Dictionary:
	if not reader.is_valid(): return {"ok":false,"reason":"unreadable","lease":null}
	var lease: RefCounted = Lease.new(save_path)
	if not lease.held: return {"ok":false,"reason":"busy","lease":null}
	var saved: Variant = reader.call(save_path)
	if not saved is Dictionary or not saved.get("ok") is bool or not saved.ok or not saved.get("digest") is String:
		lease.release()
		return {"ok":false,"reason":"unreadable","lease":null}
	var digest: String = saved.digest
	# Files uses an empty digest only for a safely absent, non-interrupted profile.
	var trusted: bool = (saved.get("empty") is bool and saved.empty and digest.is_empty()) if digest.is_empty() else (digest.length() == 64 and digest.is_valid_hex_number(false))
	if not trusted:
		lease.release()
		return {"ok":false,"reason":"unreadable","lease":null}
	if digest != expected_digest:
		lease.release()
		return {"ok":false,"reason":"changed","lease":null}
	return {"ok":true,"reason":"","lease":lease}
