shader_type canvas_item;

const vec2 center = vec2(0.5, 0.5);
const float radius = 0.5;

uniform float blur_start: hint_range(0, 0.5) = 0.3;
uniform float blur = 5.0;
uniform float ramp_factor = 4.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (pow(UV.x - center.x, 2) + pow(UV.y - center.y, 2) > pow(blur_start, 2)) {
		float d = sqrt(pow(center.x-UV.x, 2)+pow(center.y-UV.y, 2))-blur_start;
		float alpha_change = pow(1.0-d*blur, ramp_factor);
		if (alpha_change > 0.0) {
			COLOR.a *= alpha_change;
		} else {
			COLOR.a = 0.0;
		}
	}
}