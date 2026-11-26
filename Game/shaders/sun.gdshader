shader_type canvas_item;
render_mode unshaded;
uniform vec2 sun_uv=vec2(0.5);
uniform float exposure=0.0;
uniform float amount=0.6;
uniform float aspect=1.777;
void fragment(){
 vec2 d=(UV-sun_uv)*vec2(aspect,1.0);
 float r=max(length(d),0.001);
 float a=atan(d.y,d.x);
 float beam=pow(0.5+0.5*sin(a*19.0+0.5*sin(a*7.0)),9.0)*0.58+pow(0.5+0.5*sin(a*31.0-1.0),16.0)*0.42;
 float atten=exp(-r*3.8);
 float disk=1.0-smoothstep(.022,.032,r);
 float glow=atten*(0.23+0.20*beam)+0.32*exp(-r*15.0);
 COLOR=vec4(mix(vec3(1.0,.80,.46),vec3(1.0,.96,.79),disk),clamp(disk*.92+glow,0.0,0.94)*exposure*amount);
}
