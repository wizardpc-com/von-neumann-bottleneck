extends RefCounted
## Presentation switches for the laboratory journey. The classic Home, the
## original tutorial briefing and the 40-task core journey remain available as
## fallbacks: by user argument for people, by `classic`/`core_journey` for the
## legacy suites that still verify those surfaces.

static var classic: bool = false
static var core_journey: bool = false

static func lab_home() -> bool:
	return not classic and not "--classic-hub" in OS.get_cmdline_user_args()

static func focused_tutorial() -> bool:
	return not classic and not "--classic-tutorial" in OS.get_cmdline_user_args()

static func full_journey() -> bool:
	return not core_journey and ProjectSettings.get_setting("game/full_journey", false) == true and not "--core-journey" in OS.get_cmdline_user_args()
