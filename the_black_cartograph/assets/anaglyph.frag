vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords) {
    float constant_add = 0.06;
    vec4 OC = Texel(tex, texture_coords);
    vec4 Side0 = Texel(tex, texture_coords) * vec4(texture_coords.x + constant_add, texture_coords.y, 0, 0);
    vec4 Side1 = Texel(tex, texture_coords) * vec4(texture_coords.x - constant_add, texture_coords.y, 0, 0);
    if(Side0.x > 0.0){
        return vec4(1., 1., 0., 0.5);
    }
    if(Side1.x > 0.0) {
        return vec4(0., 1., 1., 0.5);
    }
    if(OC.a > 0.0) {
        return OC;
    }
}
