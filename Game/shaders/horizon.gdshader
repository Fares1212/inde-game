shader_type sky;
uniform sampler2D painting : source_color, filter_linear, repeat_disable;
const vec3 sun_direction=vec3(-0.46,0.34,-0.82);
void sky(){
 vec3 view=normalize(EYEDIR);
 float azimuth=atan(view.x,-view.z)/6.2831853;
 float u=abs(fract(azimuth+.19)*2.-1.);
 float elevation=asin(clamp(view.y,-1.,1.));
 float v=clamp(.859-elevation*1.02,0.002,.997);
 vec3 painted=texture(painting,vec2(u,v)).rgb;
 painted=mix(painted,vec3(.12,.41,.56),smoothstep(.86,1.57,elevation)*.91);
 float a=max(0.,dot(view,normalize(sun_direction)));
 float disc=smoothstep(.99979,.99994,a);
 float halo=pow(a,92.)*.17;
 COLOR=mix(painted,vec3(1.,.91,.64),clamp(halo+disc,0.,1.));
}
