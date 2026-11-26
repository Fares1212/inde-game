shader_type spatial;
render_mode unshaded,cull_disabled,fog_disabled;
uniform sampler2D relief:filter_linear,repeat_disable;
uniform vec4 shallows:source_color=vec4(.32,.75,.68,1.);
uniform vec4 deep:source_color=vec4(.10,.34,.49,1.);
uniform float sea_level=3.4;uniform float clock=0.;uniform float quality=1.;uniform float whirl=0.;
uniform vec2 splash_pos=vec2(500.);uniform float splash_at=-10.;
varying vec2 p;varying float wave;varying vec3 wpos;
float hash(vec2 x){return fract(sin(dot(x,vec2(127.1,311.7)))*43758.5453);}
float swell(vec2 x){return .11*sin(x.x*.42+x.y*.35+clock*.92)+.062*sin(x.y*.79-x.x*.31-clock*1.14);}
float foam(vec2 x){vec2 c=floor(x),f=fract(x);float m=2.,s=3.;for(int j=-1;j<=1;j++){for(int i=-1;i<=1;i++){vec2 b=vec2(float(i),float(j));vec2 v=b+.23+.52*vec2(hash(c+b),hash(c+b+.34))-f;float d=dot(v,v);if(d<m){s=m;m=d;}else{s=min(s,d);}}}return sqrt(s)-sqrt(m);}
void vertex(){wpos=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;p=wpos.xz;wave=swell(p);VERTEX.y+=wave-whirl*1.65*exp(-length(p)*.19);wpos.y+=wave;}
void fragment(){
 float land=texture(relief,clamp(p/208.+.5,0.,1.)).r*32.-15.;float d=sea_level+wave-land;
 vec2 q=p*vec2(.39,.50)+vec2(clock*.07,clock*-.10);vec2 g=floor(q),f=fract(q);float tri=hash(g+step(1.-f.y,f.x)*.49);
 vec3 n=normalize(vec3(-.07*cos(p.x*.42+p.y*.35+clock)-.032*cos(p.y*.79-p.x*.31-clock),1.,-.08*cos(p.y*.79-p.x*.31-clock)));
 vec3 view=normalize(CAMERA_POSITION_WORLD-wpos);vec3 sun=normalize(vec3(-.48,.147,-.865));
 vec3 col=mix(shallows.rgb,deep.rgb,smoothstep(.0,7.,d));col=mix(vec3(.70,.82,.66),col,smoothstep(-.07,.83,d));
 col+=(tri-.5)*vec3(.085,.13,.15);float ridge=.5+.5*sin(q.y*2.4+q.x*1.2+sin(q.x*.7)*1.7);
 float stripes=pow(max(0.,dot(reflect(-sun,n),view)),26.)*smoothstep(.14,.89,ridge);
 col=mix(col,vec3(.98,.80,.53),stripes*.80);
 float noise=sin(p.x*1.7+p.y*.92+clock)*.06+sin(p.y*.81-clock)*.09;
 float edge=abs(d-.20-noise);float front=1.-smoothstep(.046,.13,edge);
 float lace=0.;if(quality>.2 && d<2.8){float cell=foam(p*1.32+vec2(clock*.24,-clock*.18));lace=(1.-smoothstep(.015,.080,cell))*smoothstep(-.05,.24,d)*(1.-smoothstep(.18,1.1,d));col+=vec3(.075,.095,.064)*(1.-smoothstep(.012,.066,cell))*exp(-max(d,0.)*.79);}
 float t=clock-splash_at;float ripple=(1.-smoothstep(.035,.11,abs(length(p-splash_pos)-t*2.2)))*(1.-smoothstep(.0,1.6,t))*step(0.,t);
 float spiral=(1.-smoothstep(.08,.35,abs(sin(length(p)*.73+atan(p.y,p.x)*4.-clock*2.))))*whirl;
 ALBEDO=mix(col,vec3(.94,.92,.78),clamp(front*.89+lace*.71+ripple+spiral*.75,0.,1.));
}
