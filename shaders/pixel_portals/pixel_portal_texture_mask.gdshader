shader_type spatial;
render_mode unshaded;

/** Size of the pixel blocks used for quantization */
uniform float pixel_size : hint_range(0.0, 100.0) = 10.0;
/** Resolution of the viewport/texture */
uniform vec2 resolution = vec2(512.0, 512.0);

group_uniforms texture_settings;
/** Texture for the wall */
uniform sampler2D wall_texture : hint_default_white, repeat_enable;
/** Background color for the wall between layers when no texture is visible */
uniform vec4 wall_background : source_color = vec4(0.0, 0.0, 0.0, 0.0);
/** Should the texture repeat or clamp at the edges */
uniform bool texture_repeat = true;
/** Should the texture be flipped horizontally on alternating layers */
uniform bool texture_horizontal_flip_variation = true;
/** Should the texture be flipped vertically on alternating layers */
uniform bool texture_vertical_flip_variation = true;
/** How the texture variations are applied across layers (None - only use the first variation, Alternate - cycle through variations on each layer) */
uniform int texture_vary_mode: hint_enum("None", "Alternate") = 1;
/** Number of texture variations stacked vertically in the texture (0 or 1 means no variations) */
uniform int texture_variations = 1;
/** Texture offset between layers */
uniform vec2 texture_layer_offset = vec2(30.0, 30.0);
/** How should the texture color be combined with layer color settings */
uniform int texture_color_combine: hint_enum("Mult", "Add", "RGBMix", "HSVMix") = 0;

group_uniforms mask_settings;
/** Mask texture for the wall */
uniform sampler2D wall_texture_mask : hint_default_white, repeat_enable;
/** Starting threshold for the mask (0-1) */
uniform float mask_start_threshold = 0.0;
/** Ending threshold for the mask (0-1) */
uniform float mask_end_threshold = 1.0;
/** Range of the mask (0-1) */
uniform float mask_range = 0.0;
/** Whether the mask threshold is incremental */
uniform bool mask_threshold_incremental = false;
/** Mask threshold shift between layers */
uniform float mask_layer_increment = 0.1;
/** Influence the mask threshold blending curve (1.0 = linear) when not incremental */
uniform float mask_threshold_falloff: hint_range(0.1, 10.0) = 1.0;
/** Helper parameter for animating open/close of the portal. Modifies the mask threshold */
uniform float mask_threshold_scale : hint_range(0.0, 1.0) = 1.0;

group_uniforms transparency;
/** Should the last layer be transparent? */
uniform bool last_layer_transparent = false;
/** Should the first layer be transparent? */
uniform bool first_layer_transparent = false;
/** Type of transparency transition between layers [Off - no transparency, Mid|Start|End - specified layer is most opaque] */
uniform int transparency_transition: hint_enum("Off", "Mid", "Start", "End") = 0;
/** Influence the transparency blending curve (1.0 = linear) */
uniform float transparency_falloff: hint_range(0.1, 10.0) = 1.0;

group_uniforms dithered_rim;
/** Add a rim to the portal */
uniform bool rim = true;
/** Radius of the rim */
uniform float rim_radius: hint_range(0.0, 10.0) = 0.1;
/** Cyclic additional variation of the radius between layers based on TIME */
uniform bool vary_radius = true;
/** Proportional variation amount (percentage of the layers radius) */
uniform float radius_variation = 0.1;
/** Speed of the variation change */
uniform float radius_speed_variation = 1.0;
/** Offset applied to the dither pattern lookup */
uniform ivec2 dither_offset = ivec2(2, 0);
/** Size of the dither matrix to use (2x2, 4x4, or 8x8) */
uniform int bayer_size : hint_enum("2x2", "4x4", "8x8") = 2;
/** Whether to interpolate the radius calculation for smoother edges */
uniform bool interpolate = true;
/** Controls how quickly the dither pattern density changes (blend border size) */
uniform float falloff: hint_range(0.1, 10.0) = 2.5;

/** Make outlines visible */
uniform bool enable_outlines = true;
/** Make thick outlines (doubles) */
uniform bool outlines_double = true;
/** Outline color */
uniform vec4 outline_color: source_color = vec4(0.0, 0.0, 0.0, 1.0);

group_uniforms color;
/** Define how many layers are needed to cycle between color_one and color_two, 0 takes all layers */
uniform int color_repeat_layer = 0;
/** Layer offset for the color cycle */
uniform int color_offset_layer = 0;
/** First of the blending colors for the hole borders */
uniform vec3 color_one: source_color = vec3(1.0, 1.0, 1.0);
/** Second of the blending colors for the hole borders */
uniform vec3 color_two: source_color = vec3(0.0, 0.0, 0.0);
/** Influence the color blending curve (1.0 = linear) */
uniform float color_falloff: hint_range(0.1, 10.0) = 1.0;
/** Type of color transition between layers [RGBMix - mix rgb colors, HSVMix - mix HSV colors (hue shift)] */
uniform int color_transition: hint_enum("RGBMix", "HSVMix") = 0;

group_uniforms glow;
/** Define how many layers are needed to cycle between full glow and no glow */
uniform int glow_repeat_layer = 0;
/** Layer offset for the glow cycle */
uniform int glow_offset_layer = 0;
/** Glow strength */
uniform float glow = 0.0;
/** Influence the glow blending curve (1.0 = linear) */
uniform float glow_falloff: hint_range(0.1, 10.0) = 1.0;

group_uniforms hole;
/** Defines the maximum depth of the parallax layers */
uniform float depth_amount = 1.0;
/** Number of layers */
uniform int layers = 12;
/** Variation offset between layers */
uniform float radius_variation_offset = 1.0;
/** Randomize an additional offset between layers (to avoid a wave pattern) */
uniform bool radius_random_offset = true;
/** Center of the circular effect in UV coordinates */
uniform vec2 center = vec2(0.5, 0.5);
/** Define how many layers are needed to cycle between rotation values, 0 takes all layers */
uniform int rotation_repeat_layer = 0;
/** Layer offset for the rotation cycle */
uniform int rotation_offset_layer = 0;
/** Rotation strength */
uniform float rotation = 0.0;

#include "dither.gdshaderinc"
#include "pixel_portal_base.gdshaderinc"

const vec2 neighbors[8] = vec2[](
	vec2(-1.0, 0.0),
	vec2(1.0, 0.0),
	vec2(0.0, -1.0),
	vec2(0.0, 1.0),
	vec2(-1.0, -1.0),
	vec2(1.0, 1.0),
	vec2(1.0, -1.0),
	vec2(-1.0, 1.0)
);

void fragment() {
	float rotate_width = float(int(rotation_repeat_layer == 0) * layers + rotation_repeat_layer);
	float color_width = float(int(color_repeat_layer == 0) * layers + color_repeat_layer);
	float glow_width = float(int(glow_repeat_layer == 0) * layers + glow_repeat_layer);
	float value = 0.0;
	vec4 texture_color = vec4(1.0);
	vec2 uv_step = pixel_size / resolution;
	int visible_layer = -1;
	
	float radius_random_offset_value = float(radius_random_offset);
	ivec2 i_texture_size = textureSize(wall_texture, 0);
	i_texture_size = ivec2(i_texture_size.x, i_texture_size.y / texture_variations);
	vec2 texture_size = vec2(float(i_texture_size.x), float(i_texture_size.y));
	vec2 pixel_grid_size = resolution / pixel_size;
	vec2 center_offset_cells = floor((pixel_grid_size - texture_size) * 0.5 + 0.5);
	vec2 uv_centering_offset = center_offset_cells * uv_step;
	vec2 uv_texture_range = pixel_grid_size / texture_size;
	vec2 rotated_uv = UV - uv_centering_offset;
	bool background = false;
	int alternative = 0;
	
	for(int i = 0; i < layers; i++) {
		int current_alternative = int(mod(float(i), float(texture_variations))) * int(texture_vary_mode > 0) + alternative * int(texture_vary_mode == 0);
		float t = float(i) / float(layers);
		float depth = t * depth_amount;
		vec2 circle_uv = UV + parallax(depth, NORMAL, TANGENT, VIEW);
		bool flip_x = mod(float(i), 2.0) == 0.0 && texture_horizontal_flip_variation;
		bool flip_y = mod(floor(float(i) / (1.0 + float(texture_horizontal_flip_variation))), 2.0) == 0.0 && texture_vertical_flip_variation;
		float rotation_value = get_cyclic_value_negative(i, rotation_offset_layer, rotate_width);
		rotation_value = TIME * rotation * rotation_value;
		circle_uv = rotate_uv(circle_uv, rotation_value);
		circle_uv = vec2(
			mix(circle_uv.x, 1.0 - circle_uv.x, float(flip_x)),
			mix(circle_uv.y, 1.0 - circle_uv.y, float(flip_y))
		);
		circle_uv -= uv_centering_offset;
		vec2 texture_uv = ((circle_uv * resolution) / pixel_size + texture_layer_offset * float(visible_layer));
		texture_uv = mod(texture_uv, vec2(i_texture_size)) * float(texture_repeat) + vec2(clamp(texture_uv.x, 0.0, texture_size.x - 1.0), clamp(texture_uv.y, 0.0, texture_size.y - 1.0)) * float(!texture_repeat);
		vec4 mask_color = texelFetch(wall_texture_mask, ivec2(texture_uv) + ivec2(0, i_texture_size.y * current_alternative), 0);
		vec2 uv_range = circle_uv + uv_centering_offset - vec2(0.5);

		float mask_threshold_low = float(mask_threshold_incremental) * (mask_start_threshold + (float(i) * mask_layer_increment));
		mask_threshold_low += float(!mask_threshold_incremental) * (mask_start_threshold + (mask_end_threshold - mask_start_threshold) * pow(float(i)/float(layers - 1), mask_threshold_falloff)) / max(mask_threshold_scale, 0.0001);
		float mask_threshold_high = mask_threshold_low + mask_range;
		float mask_value = mask_color.r;
		bool has_mask_range = mask_range > 0.0;
		bool mask_threshold_reached = mask_threshold_high >= mask_value;
		bool within_mask_range = mask_threshold_reached && mask_threshold_low <= mask_value;
		bool out_of_texture_bounds = abs(uv_range.x) > 0.5 / uv_texture_range.x || abs(uv_range.y) > 0.5 / uv_texture_range.y;
		bool force_last_layer = !last_layer_transparent && i == layers - 1;
		bool threshold_reached = out_of_texture_bounds || mask_threshold_reached || force_last_layer;

		bool changed = value == 0.0 && threshold_reached;
		background = (changed && has_mask_range && !within_mask_range) || (!changed && background);
		value = max(value, float(threshold_reached && changed) * (float(i + 1) / float(layers + 1)));
		visible_layer = i * int(changed) + visible_layer * int(!changed);
		rotated_uv = rotated_uv * float(!changed) + circle_uv * float(changed);
		alternative = current_alternative * int(changed) + alternative * int(!changed);
	}
	if (background) {
		texture_color = wall_background;
	} else {
		vec2 texture_uv = ((rotated_uv * resolution) / pixel_size + texture_layer_offset * float(visible_layer));
		texture_uv = mod(texture_uv, vec2(i_texture_size)) * float(texture_repeat) + vec2(clamp(texture_uv.x, 0.0, texture_size.x - 1.0), clamp(texture_uv.y, 0.0, texture_size.y - 1.0)) * float(!texture_repeat);
		texture_color = texelFetch(wall_texture, ivec2(texture_uv) + ivec2(0, i_texture_size.y * alternative), 0);
	}
	int diff_count = 0;
	float rim_value = 0.0;
	vec2 dither_offset_uv = vec2(float(dither_offset.x), float(dither_offset.y)) * uv_step;
	vec2 dither_phase_compensation = dither_offset_uv * (0.5 - 0.25 * float(interpolate));
	if (rim && visible_layer == 0) {
		float random_value = 1.0 - radius_random_offset_value + random(0) * float(layers) * radius_random_offset_value;
		float radius_vary_modifier = (1.0 + radius_variation * sin((TIME + random_value) * radius_speed_variation) * float(vary_radius));
		rim_value = double_dither(rotated_uv + uv_centering_offset - dither_phase_compensation, rim_radius * radius_vary_modifier, uv_step) * 4.0;
		rim_value = step(2.0, rim_value);
		rim_value = max(rim_value, 0);
	}

	if (enable_outlines && visible_layer == 0 && rim_value >= 1.0) {
		int double = 1 + int(outlines_double);
		float random_value = 1.0 - radius_random_offset_value + random(0) * float(layers) * radius_random_offset_value;
		float radius_vary_modifier = (1.0 + radius_variation * sin((TIME + random_value) * radius_speed_variation) * float(vary_radius));
		for(int n = 0; n < 4 * double; n++) {
			vec2 neighbor_uv = rotated_uv + uv_step * neighbors[n];
			rim_value = double_dither(neighbor_uv + uv_centering_offset - dither_phase_compensation, rim_radius * radius_vary_modifier, uv_step) * 4.0;
			rim_value = step(2.0, rim_value);
			rim_value = max(rim_value, 0);
			diff_count += int(rim_value < 1.0);
		}
	}
	
	float value_transparent = abs(get_transparent_value(value, float(layers), transparency_transition));
	if (diff_count > 0) {
		ALBEDO = vec3(outline_color.rgb);
		ALPHA = (1.0 - float(transparency_transition > 0) * pow(value_transparent, transparency_falloff)) * outline_color.a;
	} else {
		if ((visible_layer == 0 && first_layer_transparent && (rim_value < 1.0 || !rim)) || (value == 1.0 && last_layer_transparent) || value == 0.0) discard;
		float value_color = get_cyclic_value(int(value * float(layers)), color_offset_layer, color_width);
		float value_glow = glow * pow(get_cyclic_value(int(value * float(layers)), glow_offset_layer, glow_width), glow_falloff);
		vec3 color_hsv = get_color_combined(color_one.rgb, color_two.rgb, color_transition, pow(value_color, color_falloff));
		ALBEDO = get_color_combined_texture(texture_color.rgb, color_hsv, texture_color_combine, 0.5) * (1.0 + value_glow);
		ALPHA = (1.0 - float(transparency_transition > 0) * pow(value_transparent, transparency_falloff)) * texture_color.a;
	}
	
}
