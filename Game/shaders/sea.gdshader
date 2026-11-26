shader_type spatial;
render_mode unshaded, cull_disabled, fog_disabled;
uniform sampler2D relief : filter_linear, repeat_disable;
uniform vec4 shallows : source_color = vec4(0.25,0.72,0.66,1.0);
uniform vec4 deep : source_color = vec4(0.10,0.39,0.43,1.0);
uniform float sea_level=3.4;
uniform float clock=0.0;
uniform float quality=1.0;
uniform float whirl=0.0;
uniform vec2 splash_pos=vec2(500.0);
uniform float splash_at=-10.0;
varying vec2 shore_point;
varying float tide_wave;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float brush(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1.,0.)),f.x),mix(hash(i+vec2(0.,1.)),hash(i+vec2(1.)),f.x),f.y);}
void vertex(){
 vec3 p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 shore_point=p.xz;
 tide_wave=.045*sin(p.x*.52+clock*1.18)+.034*sin(p.z*.72+.4*p.x-clock*1.45)+.019*sin(p.z*1.28+clock);
 VERTEX.y+=tide_wave-whirl*1.8*exp(-length(p.xz)*.15);
}
void fragment(){
 vec2 p=shore_point;
 float floor_y=texture(relief,clamp(p/208.+.5,0.,1.)).r*32.-15.;
 float depth=sea_level+tide_wave-floor_y;
 float pigment=brush(p*vec2(.25,1.1)+vec2(.04*clock,-.12*clock));
 float ripple=sin(p.y*1.9+.3*p.x+pigment*4.8+clock);
 float depth_mix=smoothstep(.0,8.7,max(0.,depth)+.36*pigment);
 vec3 tint=mix(shallows.rgb,deep.rgb,depth_mix);
 tint+=(pigment-.50)*vec3(.055,.095,.085);
 float ink=brush(p*vec2(.22,.93)+vec2(.07,-.15)*clock);
 float wave=smoothstep(.35,.8,ink)*(1.-smoothstep(.12,.36,abs(ripple-.4)));
 tint=mix(tint,vec3(.49,.82,.74),wave*.35);
 float foamline=abs(depth-(.15+.075*ink+.055*sin(clock*1.4+p.y)));
 float lace=(1.-smoothstep(.028,.095,foamline))*.88;
 lace+=.46*(1.-smoothstep(.032,.10,abs(depth-.43-ink*.24)))*smoothstep(.27,.75,ink);
 float dt=clock-splash_at;
 float pulse=(1.-smoothstep(.044,.13,abs(length(p-splash_pos)-dt*2.2)))*(1.-smoothstep(.0,1.6,dt))*step(0.,dt);
 vec2 viewray=normalize(p-CAMERA_POSITION_WORLD.xz+vec2(.0001));
 float glint_path=pow(max(0.,dot(viewray,normalize(vec2(-.46,-.82)))),23.);
 float sparkle=smoothstep(.60,.89,ink)*smoothstep(.3,.95,ripple)*glint_path;
 tint=mix(tint,vec3(.95,.80,.50),sparkle*.62);
 float spiral=(1.-smoothstep(.07,.30,abs(sin(length(p)*.75+atan(p.y,p.x)*4.-clock*2.))))*whirl;
 ALBEDO=mix(tint,vec3(.88,.91,.76),clamp(lace+pulse+spiral*.73,.0,1.));
}
