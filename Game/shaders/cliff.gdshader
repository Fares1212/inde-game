shader_type spatial;
render_mode unshaded, cull_disabled;
varying vec3 wall;
varying vec3 facing;
void vertex(){wall=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;facing=NORMAL;}
void fragment(){
 float bands=sin(wall.y*3.65+sin(wall.x*.17)*.49+.17*sin(wall.z*.39));
 vec3 sand=mix(vec3(.57,.37,.29),vec3(.87,.68,.45),smoothstep(2.,10.,wall.y));
 sand=mix(sand,vec3(.96,.80,.56),smoothstep(.5,.96,bands)*.38);
 float sunlight=dot(normalize(facing),normalize(vec3(-.46,.34,-.82)));
 vec3 col=mix(sand*vec3(.69,.74,.82),sand,clamp(sunlight*.84+.54,.0,1.));
 col=mix(col,vec3(.38,.49,.40),smoothstep(.72,.90,facing.y)*.94);
 ALBEDO=mix(col,vec3(.64,.69,.64),.16);
}
