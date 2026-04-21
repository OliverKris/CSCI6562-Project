shader_type canvas_item;

uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float grid_cols = 40.0;
uniform float cell_grow_portion : hint_range(0.01, 1.0) = 0.18;
uniform float random_delay_strength : hint_range(0.0, 0.2) = 0.03;
uniform vec4 wipe_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform bool reveal_mode = false;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV;

	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 grid = vec2(grid_cols, grid_cols / aspect);

	vec2 cell = floor(uv * grid);
	vec2 local_uv = fract(uv * grid);

	// Same diagonal order for both fade out and fade in:
	// top-left -> bottom-right
	float diag = (cell.x + cell.y) / max((grid.x - 1.0) + (grid.y - 1.0), 0.0001);
	float jitter = (hash(cell) - 0.5) * 2.0 * random_delay_strength;

	float max_start = max(1.0 - cell_grow_portion, 0.0001);
	float start_time = clamp(diag * max_start + jitter, 0.0, max_start);

	float t = clamp((progress - start_time) / max(cell_grow_portion, 0.0001), 0.0, 1.0);

	// Growth inside each square also goes top-left -> bottom-right
	float filled_x = step(local_uv.x, t);
	float filled_y = step(local_uv.y, t);
	float block_progress = filled_x * filled_y;

	float alpha;

	if (!reveal_mode) {
		// Fade out:
		// black appears top-left -> bottom-right
		alpha = block_progress;
		if (progress >= 0.999) {
			alpha = 1.0;
		}
	} else {
		// Fade in:
		// transparency appears top-left -> bottom-right
		// which means black disappears in the same direction
		alpha = 1.0 - block_progress;
		if (progress <= 0.001) {
			alpha = 1.0;
		}
		if (progress >= 0.999) {
			alpha = 0.0;
		}
	}

	COLOR = vec4(wipe_color.rgb, wipe_color.a * alpha);
}