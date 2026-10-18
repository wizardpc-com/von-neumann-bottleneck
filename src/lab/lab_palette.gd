extends RefCounted
## Shared colour tokens for the two layers of one world: the bright laboratory
## and the dark instrument terminal inside it. See 美术风格约束 v0.1 §3–4.
## Swap values here first when the art team delivers final colours.

# Laboratory (outer space): warm off-white, pale grey, soft blue.
const LAB_CEILING := Color("dfe4e6")
const LAB_WALL_TOP := Color("f2f3f1")
const LAB_WALL := Color("e6e9e8")
const LAB_SIDE := Color("d9dfe1")
const LAB_SIDE_DEEP := Color("cfd6d9")
const LAB_FLOOR_NEAR := Color("c3ccd1")
const LAB_FLOOR_FAR := Color("d6dcdf")
const LAB_TRIM := Color("bcc6cb")
const LAB_LINE := Color("aab6bc")
const LAB_INK := Color("3d4a52")
const LAB_INK_SOFT := Color("6f7d85")
const LAB_SKY_TOP := Color("cfe2ea")
const LAB_SKY_LOW := Color("eef4f3")
const LAB_LIGHT := Color("fffdf8")
const LAB_WARM := Color("ffe2b0")
const LAB_PLANT := Color("8fa891")
const DESK_TOP := Color("eef0ee")
const DESK_EDGE := Color("c9d0d2")
const DESK_SHADOW := Color(0.23, 0.29, 0.33, 0.16)

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

static func with_alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
