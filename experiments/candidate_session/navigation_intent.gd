extends RefCounted
## One-shot presentation destination. Never a completion or save authority.
static var pending_review: String = ""

static func take_review() -> String:
	var value: String = pending_review
	pending_review = ""
	return value
