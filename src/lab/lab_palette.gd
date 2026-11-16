extends RefCounted
## Shared colour tokens for the two worlds: the daylit laboratory and the dark,
## self-lit terminal inside it. See 美术风格约束 v0.1 §3–4. The room is warm and
## physical (daylight, matte surfaces, soft shadows); the terminal is cool and
## emissive. Only screens in the room borrow the terminal tokens.
## Unified default selected 2026-11-16; update these tokens when replacing artwork.

# Laboratory (outer space): warm off-white, pale stone grey, soft sky blue.
const LAB_CEILING := Color("e8eae7")
const LAB_WALL_TOP := Color("f5f6f2")
const LAB_WALL := Color("ecefe9")
const LAB_SIDE := Color("dfe7e6")
const LAB_SIDE_DEEP := Color("cdd8d8")
const LAB_FLOOR_NEAR := Color("c4cdce")
const LAB_FLOOR_FAR := Color("d9e0df")
const LAB_TRIM := Color("a8b8bc")
const LAB_LINE := Color("a0b0b4")
const LAB_INK := Color("3e4950")
const LAB_INK_SOFT := Color("737c80")
const LAB_SKY_TOP := Color("cfe2ea")
const LAB_SKY_LOW := Color("f2f0e8")
const LAB_LIGHT := Color("fffcf4")
const LAB_WARM := Color("ffe2b0")
const LAB_PLANT := Color("8fa891")
# Marker ink on the glass record board.
const LAB_MARKER := Color("4d6f86")
const DESK_TOP := Color("f0f1eb")
const DESK_EDGE := Color("dbe2df")
const DESK_SHADOW := Color(0.25, 0.24, 0.21, 0.16)

# Terminal (inner space): graphite, blue-grey, soft cyan accent.
const TERM_BODY := Color("2a333b")
const TERM_BEZEL := Color("1d252c")
const TERM_SCREEN := Color("111a21")
const TERM_SCREEN_LIFT := Color("16222b")
const TERM_PANEL := Color("1a252e")
const TERM_EDGE := Color("33434e")
const TERM_TEXT := Color("e2ebef")
const TERM_MUTED := Color("8fa3ad")
const ACCENT := Color("8fd3dc")
const ACCENT_DEEP := Color("4fa7b5")
const SIGNAL_ON := Color("ffd27a")
const GOOD := Color("9fdcb6")
# Yi's trailing text caret (yi_text_caret_*.svg is filled with this colour).
# It marks Yi's text being written; it is not a general accent or a signal.
const YI_TEXT_CURSOR := Color("f5e5bb")
# Leaving the game: a muted red, readable on both layers without neon.
const QUIT := Color("d98a84")
const QUIT_DEEP := Color("3a2526")

static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
