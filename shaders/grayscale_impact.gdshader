shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;
uniform float grayscale_amount : hint_range(0.0, 1.0) = 0.0;
uniform float contrast : hint_range(0.5, 3.0) = 1.60;
uniform vec3 tint_color : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
    vec4 col = texture(screen_texture, SCREEN_UV);
    if (grayscale_amount <= 0.001) {
        COLOR = col;
    } else {
        // 1. Đảo màu toàn bộ game (Anime Inverted Negative Impact Frame)
        vec3 inv = vec3(1.0) - col.rgb;
        
        // 2. Chuyển thành trắng đen (Monochrome Grayscale)
        float lum = dot(inv, vec3(0.299, 0.587, 0.114));
        
        // 3. Tương phản sắc nét kịch tính phong cách nét vẽ manga
        lum = clamp((lum - 0.5) * contrast + 0.5, 0.0, 1.0);
        vec3 gray = vec3(lum) * tint_color;
        
        // 4. Dramatic Vignette viền màn hình
        vec2 d = SCREEN_UV - vec2(0.5);
        float vig = clamp(1.0 - dot(d, d) * 1.6, 0.35, 1.0);
        gray *= vig;
        
        COLOR = vec4(mix(col.rgb, gray, grayscale_amount), 1.0);
    }
}
