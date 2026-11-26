shader_type spatial;
render_mode unshaded,cull_disabled;
uniform float lap=0.;
varying vec3 point;
void vertex(){point=VERTEX;VERTEX.y+=.0025*sin(point.x*21.+TIME*3.+lap)*sin(point.z*15.-TIME*2.);}
void fragment(){
 vec2 uv=point.xz;
 float surface=uv.y+.19*sin(uv.x*3.1+TIME*1.1)+.047*sin(uv.x*8.-TIME*1.4);
 float wash=smoothstep(-.66,.73,surface);
 float glint=(1.-smoothstep(.008,.05,abs(surface-.43)))*smoothstep(-.76,-.17,uv.x)*(1.-smoothstep(.36,.74,uv.x));
 float lip=smoothstep(.89,.98,length(uv));
 ALBEDO=mix(vec3(.045,.29,.34),vec3(.38,.71,.68),wash)+glint*vec3(.36,.29,.16)+lip*.08;
}
