class_name UiTypography
extends RefCounted

const HEADING_FONT = preload("res://assets/fonts/interface_heading.tres")

## Logical-pixel scale: title 26, section 18, body 16, secondary/caption 14.
## Dense text must retain body >= 14 and secondary >= 13 logical pixels.
## The 1600x900 stretch canvas scales these at smaller native window sizes;
## changing that global scale requires a separate layout review.
const BODY_MIN_SIZE: int = 14
const SECONDARY_MIN_SIZE: int = 13
const SECTION_SIZE: int = 18
const SECONDARY_SIZE: int = 14
const HERO_TITLE_SIZE: int = 34
const TITLE_SIZE: int = 26
const SUBTITLE_SIZE: int = 18
const BODY_SIZE: int = 16
const CAPTION_SIZE: int = 14
const WINDOW_TITLE_SIZE: int = 18
const BUTTON_SIZE: int = 16
const CONTROL_HEIGHT: float = 42.0
const TOOL_BUTTON_HEIGHT: float = 44.0
const CONTINUE_WIDTH: float = 156.0
