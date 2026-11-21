shader_type canvas_item;

// ==========================================================
// LIQUID GLASS SHADER (Inspired by ybouane/liquidglass)
// Physical glass refraction, chromatic aberration & specular rim
// ==========================================================

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float glass_tint_opacity : hint_range(0.0, 1.0) = 0.82;
uniform vec4 glass_tint_color : source_color = vec4(0.06, 0.09, 0.14, 1.0);
uniform float corner_radius : hint_range(0.0, 0.5) = 0.08;
uniform float refraction_strength : hint_range(0.0, 0.08) = 0.025;
uniform float chromatic_aberration : hint_range(0.0, 0.04) = 0.012;
uniform float rim_light_intensity : hint_range(0.0, 2.0) = 0.95;
uniform vec4 rim_light_color : source_color = vec4(0.85, 0.95, 1.0, 1.0);

// Signed distance function to a rounded rectangle
float rounded_box_sdf(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + vec2(r);
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void fragment() {
    vec2 uv = UV;
    vec2 p = uv - vec2(0.5);
    vec2 half_size = vec2(0.5);
    
    // Compute distance to edge
    float d = rounded_box_sdf(p, half_size, corner_radius);
    
    // Discard pixels outside rounded corners
    if (d > 0.0) {
        discard;
    }
    
    // Calculate normal from SDF gradient for physical glass refraction
    float eps = 0.01;
    float dx = rounded_box_sdf(p + vec2(eps, 0.0), half_size, corner_radius) - rounded_box_sdf(p - vec2(eps, 0.0), half_size, corner_radius);
    float dy = rounded_box_sdf(p + vec2(0.0, eps), half_size, corner_radius) - rounded_box_sdf(p - vec2(0.0, eps), half_size, corner_radius);
    vec2 normal = normalize(vec2(dx, dy));
    
    // Distance from edge factor (for edge effects)
    float edge_factor = smoothstep(-0.06, 0.0, d);
    
    // Refraction UV offset
    vec2 refract_offset = normal * edge_factor * refraction_strength;
    
    // Chromatic aberration (RGB channel splitting)
    vec2 uv_r = SCREEN_UV + refract_offset * (1.0 + chromatic_aberration);
    vec2 uv_g = SCREEN_UV + refract_offset;
    vec2 uv_b = SCREEN_UV + refract_offset * (1.0 - chromatic_aberration);
    
    float bg_r = textureLod(screen_texture, uv_r, 1.5).r;
    float bg_g = textureLod(screen_texture, uv_g, 1.5).g;
    float bg_b = textureLod(screen_texture, uv_b, 1.5).b;
    vec3 ref_color = vec3(bg_r, bg_g, bg_b);
    
    // Tint with glass body
    vec3 final_color = mix(ref_color, glass_tint_color.rgb, glass_tint_opacity);
    
    // Specular Rim Light & Fresnel glow at the edge
    vec2 light_dir = normalize(vec2(0.3, -1.0)); // Top light source
    float specular = pow(max(dot(-normal, light_dir), 0.0), 3.0) * edge_factor * rim_light_intensity;
    float rim = pow(edge_factor, 1.5) * 0.7;
    
    final_color += (rim_light_color.rgb * (specular + rim));
    
    // Inner subtle border highlight
    float border = smoothstep(-0.008, -0.002, d);
    final_color += vec3(0.25, 0.35, 0.5) * border;

    COLOR = vec4(final_color, 1.0);
}
