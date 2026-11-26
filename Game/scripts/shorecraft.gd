extends RefCounted
const F=preload("res://scripts/forms.gd")
const S=preload("res://scripts/shore.gd")
const V=preload("res://scripts/vessels.gd")
const WOOD=Color("#92643e")
const CREAM=Color("#f2d397")
const CORAL=Color("#b85e40")
const MOSS=Color("#778854")

static func plank(p:Node3D,pos:Vector3,size:Vector3,col:Color,rot:=Vector3.ZERO)->Node3D:
	var n=F.piece(p,"box",pos,size,col,rot)
	n.material_override=V.finish(col,1.,0.)
	return n

static func crate(p:Node3D,at:Vector3,s:float)->void:
	var n=F.root(p,at)
	for j in 4:
		for k in [-1.,1.]:
			plank(n,Vector3(0,.07+j*.12,k*.32),Vector3(.81,.10,.04),WOOD.lightened(.03*j))
			plank(n,Vector3(k*.38,.07+j*.12,0),Vector3(.04,.10,.61),WOOD)
	for k in [-1.,1.]:
		for l in [-1.,1.]:plank(n,Vector3(k*.37,.23,l*.30),Vector3(.065,.49,.063),WOOD.darkened(.14))
	n.scale=Vector3.ONE*s

static func stall(shop:Node3D)->void:
	for a in [-1.,1.]:
		for b in [-1.,1.]:
			var x:float=a*1.52;var z:float=b*.86;var top:float=3.14 if b>0 else 3.6
			plank(shop,Vector3(x,top*.5,z),Vector3(.13,top,.15),WOOD.darkened(.16))
			for j in 4:F.piece(shop,"ring",Vector3(x,top-.32+j*.032,z),Vector3(.195,.095,.206),CREAM)
		plank(shop,Vector3(a*1.52,2.92,0),Vector3(.12,.13,2.05),WOOD,Vector3(.17,0,0))
	plank(shop,Vector3(0,3.09,.88),Vector3(3.34,.12,.13),WOOD)
	for i in 14:
		plank(shop,Vector3((i-6.5)*.19,.53,.59),Vector3(.186,.93,.085),WOOD.lightened(.04*(i%4)))
	for j in 7:plank(shop,Vector3(0,1.055,(j-3)*.196),Vector3(2.85,.10,.19),WOOD.lightened(.07*(j%3)))
	for j in 2:plank(shop,Vector3(0,1.28+j*.59,-.76),Vector3(2.89,.082,.47),WOOD)
	for i in 9:
		var band=SurfaceTool.new();band.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in 10:
			for uv in [Vector2(0,j),Vector2(1,j),Vector2(0,j+1),Vector2(0,j+1),Vector2(1,j),Vector2(1,j+1)]:
				var t:float=uv.y/10.;var x:float=(i+uv.x-4.5)*.386
				band.add_vertex(Vector3(x,3.66-.43*t-.39*sin(PI*t)-.12*(1.-pow(absf(x)/1.74,2)),lerpf(-1.06,1.08,t)))
		var col:Color=CREAM if i%2==0 else CORAL
		var flap:=PackedVector3Array([Vector3((i-4.5)*.386,3.14,1.08),Vector3((i-3.5)*.386,3.14,1.08),Vector3((i-3.5)*.386,2.98,1.12),Vector3((i-4.5)*.386,3.14,1.08),Vector3((i-3.5)*.386,2.98,1.12),Vector3((i-4.5)*.386,2.94,1.12)])
		for v in flap:band.add_vertex(v)
		band.generate_normals();var mesh:=MeshInstance3D.new();mesh.mesh=band.commit();mesh.material_override=V.finish(col,1.2);shop.add_child(mesh)
	crate(shop,Vector3(-1.96,0,.1),.98);crate(shop,Vector3(-1.89,.51,.08),.72)
	crate(shop,Vector3(1.0,1.11,-.16),.55)
	for i in 12:
		var x:float=(i%6-2.5)*.44
		var y:=1.35 if i<6 else 1.94
		var obj=F.root(shop,Vector3(x,y,-.73))
		var c:Color=[Color("#a76442"),Color("#619488"),Color("#d6b37e")][i%3]
		F.piece(obj,"ball",Vector3(0,.14,0),Vector3(.26,.30,.23),c)
		F.piece(obj,"tube",Vector3(0,.29,0),Vector3(.103,.13,.10),c)
		F.piece(obj,"ring",Vector3(0,.345,0),Vector3(.12,.045,.12),CREAM)
	for side in [-1.,1.]:
		var x:float=side*1.25
		V.tube(shop,[Vector3(x,3.08,.83),Vector3(x,2.70,.83)],.014,CREAM)
		F.piece(shop,"ball",Vector3(x,2.53,.83),Vector3(.22,.32,.22),Color("#ecb45d"))
		for j in 2:F.piece(shop,"cone",Vector3(x,2.40+j*.28,.83),Vector3(.32,.15,.32),WOOD)
	var panel=plank(shop,Vector3(-.61,.60,.665),Vector3(1.3,.44,.048),Color("#415d55"),Vector3(0,0,-.03))
	var name:=Label3D.new();panel.add_child(name);name.top_level=true;name.global_position=shop.global_position+Vector3(-.61,.6,.7)
	name.text="CHEZ BERNARD";name.font=preload("res://fonts/display-bold.tres");name.pixel_size=.0019;name.font_size=59;name.outline_size=0;name.modulate=CREAM

static func palm(parent:Node3D,loc:Vector2,scale_factor:float,phase:float)->void:
	var tree=F.root(parent,S.place(loc.x,loc.y));tree.scale=Vector3.ONE*scale_factor;tree.rotation.y=phase
	var prev:=Vector3.ZERO
	for i in 10:
		var t:float=(i+1)/10.;var v:=Vector3(.70*t*t,4.65*t,.16*sin(t*PI))
		var n=F.rod(tree,prev,v,lerpf(.47,.23,t),WOOD.lightened(.15*t))
		F.piece(tree,"ring",prev.lerp(v,.17),Vector3(lerpf(.49,.25,t),.105,lerpf(.49,.25,t)),Color("#a87b48"))
		prev=v
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 11:
		var a:=k*2.39996+phase;var axis:=Vector3(cos(a),0,sin(a));var side:=axis.cross(Vector3.UP)
		var length:=2.9+.75*sin(k*3.2);var bend:=1.0+.46*sin(k*1.7)
		for j in 7:
			for n in [-1.,1.]:
				var col:Color=[Color("#4d874a"),Color("#71954c"),Color("#337558"),Color("#98ab52")][(k+int(n+1))%4]
				for uv in [Vector2(j,0),Vector2(j+1,0),Vector2(j,1),Vector2(j,1),Vector2(j+1,0),Vector2(j+1,1)]:
					var t:float=uv.x/7.;var width:float=sin(t*PI)*.345
					var v:Vector3=prev+axis*(t*length)+Vector3.UP*(sin(t*PI)*bend-.80*t*t)+side*n*width*uv.y
					v.y-=width*.62*uv.y
					st.set_color(col);st.add_vertex(v)
	st.generate_normals();var leaves:=MeshInstance3D.new();leaves.mesh=st.commit()
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;leaves.material_override=mat;tree.add_child(leaves)
	for k in 3:F.piece(tree,"rock",prev+Vector3(.16*cos(k*2),-.18,.18*sin(k*2)),Vector3(.32,.41,.31),Color("#986438"))

static func pools(parent:Node3D)->void:
	for i in 9:
		var x:float=[-10,-16,19,-28,28,-39,42,-29,24][i]
		var z:float=[73,71,70,67,62,48,40,35,27][i]
		var base:=S.place(x,z,.035);var n=F.root(parent,base);var size:=1.1+fmod(i*.71,1.2)
		var pool=F.piece(n,"ball",Vector3.ZERO,Vector3(2.5*size,.060,1.16*size),Color("#4f9f93"))
		pool.rotation.y=.15
		for j in 14:
			var a:=TAU*j/14.;var dx:=cos(a)*size*1.34;var dz:=sin(a)*size*.71
			var at:=S.place(x+dx,z+dz,.10)
			var rock=F.piece(parent,"rock",at,Vector3(.49+.34*sin(j)*sin(j),.27,.48),[Color("#797b69"),Color("#a27f66"),Color("#87865d")][j%3],Vector3(.14,a,.12))
			if j%3==0:F.piece(rock,"rock",Vector3(0,.37,0),Vector3(.81,.33,.67),MOSS)
