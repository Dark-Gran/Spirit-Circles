shader_type canvas_item;

uniform float radius: hint_range(0.0, 1.0) = 0.5;
uniform float noise_strength = 0.0;

uniform sampler2D noise;

void fragment() {
	float d = distance(vec2(0.5), UV)/radius;
	vec4 target_color = texture(TEXTURE, UV);
	target_color.a = 0.0;
	d = clamp(d, 0, 1);
	COLOR = mix(texture(TEXTURE, UV), target_color, d);
	COLOR.rgb += texture(noise, UV).rgb*noise_strength;
}