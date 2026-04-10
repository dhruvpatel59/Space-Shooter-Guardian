void main() {
    vec4 color = texture2D(u_texture, v_tex_coord);
    vec4 glowColor = vec4(0.5, 0.8, 1.0, 1.0); // Blue-white glow
    gl_FragColor = mix(color, glowColor, 0.2);
} 