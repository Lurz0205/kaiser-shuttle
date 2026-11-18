shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float floor_uv_y : hint_range(0.0, 1.0) = 0.76388889; // Chuẩn 550.0 / 720.0
uniform float reflection_strength : hint_range(0.0, 1.0) = 0.45;
uniform vec4 floor_tint : source_color = vec4(0.20, 0.58, 0.32, 1.0);

void fragment() {
    vec2 screen_uv = SCREEN_UV;
    float dist = screen_uv.y - floor_uv_y;
    
    if (dist > 0.001) {
        // Phản chiếu thẳng đứng qua trục sàn floor_uv_y, nén nhẹ phối cảnh 0.92
        vec2 refl_uv = vec2(screen_uv.x, floor_uv_y - dist * 0.92);
        
        // Khử răng cưa / tạo độ bóng tự nhiên cho sàn đấu
        vec2 blur_off = SCREEN_PIXEL_SIZE * 2.0;
        vec4 col = texture(screen_texture, refl_uv);
        vec4 col_l = texture(screen_texture, refl_uv - vec2(blur_off.x, 0.0));
        vec4 col_r = texture(screen_texture, refl_uv + vec2(blur_off.x, 0.0));
        vec4 col_u = texture(screen_texture, refl_uv + vec2(0.0, blur_off.y));
        vec4 refl_avg = (col * 0.4 + (col_l + col_r + col_u) * 0.2);
        
        // Độ mờ dần chuẩn GLSL (tránh undefined behavior khi edge0 > edge1)
        float fade = 1.0 - smoothstep(0.005, 0.22, dist);
        fade = clamp(fade, 0.0, 1.0);
        
        // Hòa trộn ánh phản chiếu vào màu bóng sàn thảm thi đấu
        vec3 final_rgb = mix(refl_avg.rgb, floor_tint.rgb, 0.25);
        COLOR = vec4(final_rgb, refl_avg.a * reflection_strength * fade);
    } else {
        COLOR = vec4(0.0);
    }
}
