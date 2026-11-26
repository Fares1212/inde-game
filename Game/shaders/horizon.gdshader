shader_type sky;
uniform vec3 daylight=vec3(1.);
float hash(vec2 p){return fract(sin(dot(p,vec2(12.71,97.31)))*43518.67);}
float soft(vec2 p){vec2 c=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(hash(c),hash(c+vec2(1,0)),f.x),mix(hash(c+vec2(0,1)),hash(c+1.),f.x),f.y);}
void sky(){
 vec3 e=normalize(EYEDIR);vec3 sun=normalize(vec3(-.48,.147,-.865));float y=max(e.y,0.);
 float sep=acos(clamp(dot(e,sun),-1.,1.));float halo=exp(-sep*3.6);
 vec3 horizon=mix(vec3(.96,.69,.55),vec3(1.,.80,.55),halo);
 vec3 top=mix(vec3(.49,.55,.72),vec3(.27,.53,.69),smoothstep(.05,.95,y));
 vec3 sky=mix(horizon,top,smoothstep(-.03,.75,e.y));
 vec2 p=e.xz/max(.09,y+.12)*1.10;float cum=soft(p*.8)*.61+soft(p*1.95)*.28+soft(p*4.9)*.11;
 float cloud=smoothstep(.54,.65,cum)*smoothstep(.03,.19,y);
 vec3 cloudcol=mix(vec3(.79,.63,.68),vec3(1.,.86,.69),smoothstep(.55,.77,cum));
 sky=mix(sky,cloudcol,cloud*.82);float rays=.025*halo*sin(atan(e.y-sun.y,e.x-sun.x)*18.);
 float facet=(hash(floor(vec2(atan(e.x,e.z),e.y)*vec2(8.,10.))+step(fract(e.y*10.),fract(atan(e.x,e.z)*8.)))-.5)*.018;
 sky+=vec3(.16,.075,.012)*halo+rays+facet;sky=mix(sky,vec3(1.,.89,.57),1.-smoothstep(.075,.077,sep));
 COLOR=sky*daylight;
}
