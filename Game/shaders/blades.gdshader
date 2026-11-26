shader_type spatial;
render_mode cull_disabled;
uniform vec4 blade : source_color;
void vertex(){
	vec3 origin=MODEL_MATRIX[3].xyz;
	float bend=(VERTEX.y+.5)*(VERTEX.y+.5);
	VERTEX.x+=bend*(.22*sin(TIME*1.9+origin.z*.33)+.08*sin(TIME*3.1+origin.x*.44));
}
void fragment(){ALBEDO=blade.rgb;ROUGHNESS=.86;}
