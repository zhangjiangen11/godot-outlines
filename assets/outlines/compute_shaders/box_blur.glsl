#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba16, set = 0, binding = 0) uniform restrict readonly image2D input_image;
layout(rgba16, set = 1, binding = 0) uniform restrict writeonly image2D output_image;
layout(std430, set = 2, binding = 0) buffer restrict readonly BlurRadiusBuffer { int radius; } brb;
layout(std430, set = 3, binding = 0) buffer restrict readonly DirectionBuffer { bool direction; } db;

void main() {
	ivec2 image_size = imageSize(input_image);
	ivec2 current_position = ivec2(gl_GlobalInvocationID.xy);

	vec3 color_sum = vec3(0.0f);
	int color_count = 0;
	float alpha_sum = 0.0f;
	int alpha_count = 0;

	for (int i = -brb.radius; i <= brb.radius; i++) {
		ivec2 check_position = ivec2(
			current_position.x + (db.direction ? i : 0),
			current_position.y + (db.direction ? 0 : i)
		);

		// The position to check is outside the input image
		if (check_position.x < 0 || check_position.y < 0 || check_position.x >= image_size.x || check_position.y >= image_size.y) {
			continue;
		}

		vec4 check_pixel = imageLoad(input_image, check_position);

		if (check_pixel.a > 0.0f) {
			color_sum += check_pixel.xyz;
			color_count++;
		}

		alpha_sum += check_pixel.a;
		alpha_count++;
	}

	imageStore(output_image, current_position, vec4(color_sum / float(color_count), alpha_sum / float(alpha_count)));
}
