shader_type spatial;
render_mode unshaded, cull_disabled;
uniform vec4 tint : source_color = vec4(0.43, 0.25, 0.78, 1.0);
uniform bool awake = false;
uniform bool animate = true;
void fragment() {
 vec2 p = UV * 2.0 - 1.0;
 float t = animate ? TIME * .35 : 0.0;
 float r = length(p * vec2(1.0, .75));
 float a = atan(p.y, p.x);
 float strands = pow(.5 + .5 * sin(r * 28.0 - a * 3.0 + t * 5.0), 5.0);
 float center = exp(-r * 2.5);
 vec3 base = awake ? tint.rgb : vec3(.08, .17, .20);
 ALBEDO = base * (.25 + strands * .5 + center * .5);
 EMISSION = awake ? base * (strands * .9 + center * .7) : vec3(0.0);
 ROUGHNESS = .5;
}
