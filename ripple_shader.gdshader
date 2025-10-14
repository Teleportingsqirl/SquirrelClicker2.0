// ripple_shader.gdshader
shader_type canvas_item;

// These are variables we will control from our GDScript
uniform vec2 click_center = vec2(0.5, 0.5); // The center of the ripple (0.5, 0.5 is the middle)
uniform float ripple_strength = 0.0;       // How strong/visible the ripple is (0.0 is invisible)
uniform float ripple_width = 0.1;          // How wide the ripple wave is

void fragment() {
	// Get the texture coordinate for the current pixel (from 0.0 to 1.0)
	vec2 uv = UV;

	// Calculate the distance of the current pixel from the ripple's center
	float distance = distance(uv, click_center);

	// If the ripple has strength, calculate the wave
	if (ripple_strength > 0.0) {
		// Create a sine wave based on the distance from the center
		// This creates the actual ripple shape.
		float ripple_wave = smoothstep(0.0, ripple_width, distance - ripple_strength) * (1.0 - smoothstep(ripple_width, ripple_width + 0.01, distance - ripple_strength));

		// Move the texture coordinates outwards based on the wave, creating the distortion
		uv += normalize(uv - click_center) * ripple_wave * 0.1;
	}

	// Set the final pixel color by sampling the original texture at the (potentially modified) coordinate
	COLOR = texture(TEXTURE, uv);
}