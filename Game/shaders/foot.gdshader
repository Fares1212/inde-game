shader_type spatial;
render_mode unshaded,cull_disabled,depth_draw_never;
void fragment(){
 vec2 p=(UV-0.5)*2.0;
 float heel=length((p-vec2(0.0,0.47))*vec2(2.05,2.4));
 float toe=length((p-vec2(-0.04,-0.23))*vec2(1.45,1.55));
 float lip=1.0-smoothstep(0.66,1.0,min(heel,toe));
 ALBEDO=vec3(0.24,0.235,0.18);ALPHA=lip*0.49;
}
