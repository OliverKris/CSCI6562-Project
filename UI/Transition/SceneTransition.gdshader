shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float grid_size = 48.0;
uniform float cell_fill_portion : hint_range(0.01, 1.0) = 0.22;
uniform float random_delay_strength : hint_range(0.0, 0.2) = 0.035;
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;

	vec2 cell = floor(uv * grid_size);
	vec2 local_uv = fract(uv * grid_size);

	// 0 at top-left, 1 at bottom-right
	float diag = (cell.x + cell.y) / max((grid_size - 1.0) * 2.0, 0.0001);

	// slight per-cell randomness
	float jitter = (hash(cell) - 0.5) * 2.0 * random_delay_strength;

	// Important:
	// reserve the last part of the timeline for the cell to finish filling.
	float max_start = max(1.0 - cell_fill_portion, 0.0001);
	float start_time = clamp(diag * max_start + jitter, 0.0, max_start);

	float fill_t = (progress - start_time) / max(cell_fill_portion, 0.0001);
	fill_t = clamp(fill_t, 0.0, 1.0);

	// grow downward inside each cell
	float covered = step(local_uv.y, fill_t);

	// hard guarantee: once progress reaches 1, the screen is fully black
	if (progress >= 0.999) {
		covered = 1.0;
	}

	COLOR = vec4(wipe_color.rgb, wipe_color.a * covered);
}