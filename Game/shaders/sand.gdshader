shader_type spatial;
render_mode cull_disabled;
uniform float tide_level=3.4;varying vec3 wp;varying vec3 wn;
float h(vec2 u){return fract(sin(dot(u,vec2(57.25,113.9)))*43758.5453);}
float n(vec2 p){vec2 i=floor(p),f=fract(p);f=f*f*(3.-2.*f);return mix(mix(h(i),h(i+vec2(1,0)),f.x),mix(h(i+vec2(0,1)),h(i+1.),f.x),f.y);}
float grain(vec2 p){return n(p*.62)*.6+n(p*3.2)*.26+n(p*18.)*.14;}
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;wn=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){vec3 w=pow(abs(wn),vec3(3.));w/=max(.001,w.x+w.y+w.z);
 float sand=grain(wp.zy)*w.x+grain(wp.xz)*w.y+grain(wp.xy)*w.z;
 float ripple=sin(wp.z*8.4+wp.x*3.+sand*5.+2.*n(wp.xz*.19));
 float wet=1.-smoothstep(tide_level-.26,tide_level+.77,wp.y);
 vec3 c=mix(vec3(.66,.42,.21),vec3(.99,.78,.45),sand+.12);
 c=mix(c,c*vec3(.57,.72,.79),wet*.66);c+=ripple*.026*(1.-wet*.5);
 float tile=min(abs(fract(wp.x*.5)-.5),abs(fract(wp.z*.5)-.5));vec3 ceramic=mix(vec3(.19,.32,.34),vec3(.44,.60,.54)+sand*.03,smoothstep(.011,.035,tile));
 c=mix(c,ceramic,1.-smoothstep(-7.,-4.3,wp.y));float ring=100.;
 for(int i=0;i<6;i++){float y=3.4-float(i)*2.36;ring=min(ring,abs(wp.y-y+.044*sin(wp.x)));}c=mix(c,vec3(.79,.73,.56),(1.-smoothstep(.022,.09,ring))*.42);
 ALBEDO=c;ROUGHNESS=mix(.91,.41,wet);NORMAL=normalize(NORMAL+vec3(.026*ripple,.013*(sand-.5),0.));}
