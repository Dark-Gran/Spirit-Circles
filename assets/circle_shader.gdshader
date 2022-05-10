shader_type canvas_item;

const vec2 center = vec2(0.5, 0.5);
const float radius = 0.5;

const float gradient_start = 0.3;
const float blur = 5.0;
const float ramp_factor = 4.0;

void fragment() {
	COLOR = texture(TEXTURE, UV);
	if (pow(UV.x - center.x, 2) + pow(UV.y - center.y, 2) > pow(gradient_start, 2)) {
		float dist = sqrt(pow(center.x-UV.x, 2)+pow(center.y-UV.y, 2))-gradient_start;
		COLOR.a *= pow(1.0-dist*blur, ramp_factor);
	}
}