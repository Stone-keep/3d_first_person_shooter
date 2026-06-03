shader_type spatial;
render_mode unshaded;
stencil_mode write, compare_always, 1;

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

#include "pixel_portal_base.gdshaderinc"

void fragment() {
	float rotate_width = float(int(rotation_repeat_layer == 0) * layers + rotation_repeat_layer);
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
	vec2 texture_uv = ((rotated_uv * resolution) / pixel_size + texture_layer_offset * float(visible_layer));
	texture_uv = mod(texture_uv, vec2(i_texture_size)) * float(texture_repeat) + vec2(clamp(texture_uv.x, 0.0, texture_size.x - 1.0), clamp(texture_uv.y, 0.0, texture_size.y - 1.0)) * float(!texture_repeat);
	texture_color = texelFetch(wall_texture, ivec2(texture_uv) + ivec2(0, i_texture_size.y * alternative), 0);
	float texture_alpha = texture_color.a;
	if (background) texture_alpha = wall_background.a;
	
	float transparent_value = get_transparent_value(value, float(layers), transparency_transition);
	if (((visible_layer != -1 || !last_layer_transparent) && ((visible_layer == 0 && first_layer_transparent) || (texture_alpha == 1.0 && (transparent_value == 1.0 || transparent_value < 0.0)) || texture_alpha == 0.0))) discard;
	ALBEDO = vec3(1.0);
	ALPHA = 1.0;
}
