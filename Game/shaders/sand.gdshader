shader_type spatial;
render_mode cull_disabled;
uniform float tide_level=3.4;
varying vec3 world_p;
void vertex(){world_p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
float hash2(vec2 p){return fract(sin(dot(p,vec2(57.25,113.9)))*43758.5453);}
float tex(vec2 p){vec2 q=floor(p),f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash2(q),hash2(q+vec2(1,0)),f.x),mix(hash2(q+vec2(0,1)),hash2(q+vec2(1)),f.x),f.y);}
void fragment(){
 vec2 p=world_p.xz;float y=world_p.y;
 float wash=tex(p*0.27)*0.65+tex(p*1.56)*0.25+tex(p*5.0)*0.1;
 vec3 shallow=mix(vec3(0.59,0.44,0.26),vec3(0.93,0.78,0.49),smoothstep(0.1,0.85,wash));
 vec3 seabed=mix(vec3(0.19,0.34,0.33),vec3(0.42,0.47,0.37),wash);
 vec3 col=mix(seabed,shallow,smoothstep(-5.,2.0,y+wash*0.6));
 float wet=1.0-smoothstep(tide_level-0.12,tide_level+0.72,y);col=mix(col,col*vec3(.56,.72,.78),wet*.62);
 float band=100.0;
 band=min(band,abs(y-3.4));band=min(band,abs(y-1.65));band=min(band,abs(y+0.65));band=min(band,abs(y+3.1));band=min(band,abs(y+5.9));band=min(band,abs(y+8.4));
 col=mix(col,vec3(0.85,0.79,0.62),(1.0-smoothstep(0.035,0.14,band+0.035*sin(p.x*0.86)))*0.52);
 float tile=min(abs(fract(p.x*0.48)-0.5),abs(fract(p.y*0.48)-0.5));
 float abyss=1.0-smoothstep(-6.8,-4.9,y);
 vec3 ceramic=mix(vec3(.21,.38,.43),vec3(.38,.55,.55),wash);
 ceramic=mix(vec3(0.12,0.2,0.22),ceramic,smoothstep(.012,.037,tile));
 col=mix(col,ceramic,abyss*.91);ALBEDO=col;ROUGHNESS=mix(.95,.54,wet);
}
