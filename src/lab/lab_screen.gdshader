shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D display_texture : source_color, filter_linear;
uniform vec4 screen_bounds;
varying vec2 display_uv;

void vertex() {
	display_uv = (VERTEX.xy - screen_bounds.xy) / screen_bounds.zw;
	display_uv.y = 1.0 - display_uv.y;
}

void fragment() {
	ALBEDO = texture(display_texture, display_uv).rgb;
}
