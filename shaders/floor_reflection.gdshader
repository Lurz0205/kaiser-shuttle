shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float floor_y : hint_range(400.0, 650.0) = 550.0;
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.35;
uniform float blur_level : hint_range(0.0, 4.0) = 1.2;
uniform vec4 floor_tint : source_color = vec4(0.20, 0.58, 0.32, 1.0);

void fragment() {
    vec2 screen_uv = SCREEN_UV;
    float floor_uv_y = floor_y * SCREEN_PIXEL_SIZE.y;
    float dist = screen_uv.y - floor_uv_y;
    
    if (dist > 0.0) {
        // Vertical mirror across floor_y with perspective compression (0.92)
        vec2 refl_uv = vec2(screen_uv.x, floor_uv_y - dist * 0.92);
        
        // Multi-tap soft blur for glossy tournament court sheen
        vec4 col = textureLod(screen_texture, refl_uv, blur_level);
        vec4 col_l = textureLod(screen_texture, refl_uv - vec2(SCREEN_PIXEL_SIZE.x * 2.5, 0.0), blur_level);
        vec4 col_r = textureLod(screen_texture, refl_uv + vec2(SCREEN_PIXEL_SIZE.x * 2.5, 0.0), blur_level);
        vec4 refl_avg = (col * 0.5 + (col_l + col_r) * 0.25);
        
        // Vertical fade out as reflection gets deeper/further below floor
        float fade = smoothstep(0.18, 0.005, dist);
        
        // Glossy highlight blend with BWF tournament green court color
        vec3 final_rgb = mix(refl_avg.rgb, floor_tint.rgb, 0.32);
        COLOR = vec4(final_rgb, refl_avg.a * reflection_strength * fade);
    } else {
        COLOR = vec4(0.0);
    }
}
