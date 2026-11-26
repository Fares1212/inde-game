shader_type spatial;
render_mode unshaded,cull_disabled;
uniform vec4 pigment:source_color=vec4(1.);
uniform float grain=0.;
uniform float sheen=0.;
varying vec3 local_p;
varying vec3 world_n;
void vertex(){local_p=VERTEX;world_n=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
 vec3 n=normalize(world_n);
 float light=dot(n,normalize(vec3(-.44,.81,.38)))*.5+.5;
 float fibre=sin(local_p.y*119.+sin(local_p.x*46.+local_p.z*27.)*2.3);
 float fleck=sin(dot(local_p,vec3(423.,167.,239.)))*sin(local_p.y*191.);
 float shine=smoothstep(.72,.96,abs(n.x*.54+n.y*.6+n.z*.58));
 ALBEDO=pigment.rgb*(.53+.49*light+(fibre*.046+fleck*.014)*grain)+vec3(.28,.21,.12)*sheen*shine;
}
