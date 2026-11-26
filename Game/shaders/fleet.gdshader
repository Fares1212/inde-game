shader_type spatial;
render_mode cull_disabled, unshaded;
uniform sampler2D relief : filter_linear, repeat_disable;
uniform float progress=0.0;
varying vec3 pigment;
void vertex(){
 float angle=INSTANCE_CUSTOM.x*6.2831853;
 float original_r=INSTANCE_CUSTOM.y*62.+3.;
 float j=INSTANCE_CUSTOM.z;
 float r=original_r*(1.-.985*pow(progress,1.55));
 angle+=progress*progress*(4.5+28./(1.+r*.085))+j*.22;
 vec2 center=vec2(cos(angle),sin(angle))*r;
 float ground=textureLod(relief,clamp(center/208.+.5,0.,1.),0.).r*32.-15.;
 float sink=5.*smoothstep(.82,1.,progress)*(1.-smoothstep(1.,7.,r));
 vec3 boat=VERTEX*(.33+.65*j);
 float roll=.12*sin(j*45.+progress*18.)+progress*.86;
 boat.yz=mat2(vec2(cos(roll),sin(roll)),vec2(-sin(roll),cos(roll)))*boat.yz;
 float heading=angle+1.9+progress*.25;
 boat.xz=mat2(vec2(cos(heading),sin(heading)),vec2(-sin(heading),cos(heading)))*boat.xz;
 VERTEX=vec3(center.x,ground+.29+.19*j-sink,center.y)+boat;
 pigment=VERTEX.y-ground>.50 ? mix(vec3(.95,.83,.60),vec3(.87,.54,.33),j) : mix(vec3(.24,.32,.32),vec3(.55,.32,.21),j);
}
void fragment(){ALBEDO=pigment;}
