shader_type canvas_item;

uniform float offset : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = UV + vec2(offset, 0.0);
	COLOR = texture(TEXTURE, fract(uv));
}
