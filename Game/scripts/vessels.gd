extends RefCounted
const F=preload("res://scripts/forms.gd")
const DARK=Color("#423b34")
const COPPER=Color("#ba6940")
const LIP=Color("#efc47a")
const IRON=Color("#52636a")
const OAK=Color("#a66d3c")
const ENAMEL=Color("#386f70")
static var paints:Dictionary={}

static func finish(c:Color,grain:float=0.,metal:float=0.)->ShaderMaterial:
	var key:=c.to_html()+str(grain)+str(metal)
	if not paints.has(key):
		var m:=ShaderMaterial.new()
		m.shader=preload("res://shaders/craft.gdshader")
		m.set_shader_parameter("pigment",c);m.set_shader_parameter("grain",grain);m.set_shader_parameter("sheen",metal)
		paints[key]=m
	return paints[key]

static func tube(parent:Node3D, pts:PackedVector3Array,r:float,c:Color,grain:=0.)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in range(pts.size()-1):
		var d:Vector3=(pts[k+1]-pts[k]).normalized()
		var side:Vector3=d.cross(Vector3.FORWARD if absf(d.z)<.94 else Vector3.UP).normalized()
		var up:Vector3=d.cross(side)
		for j in 10:
			for corner in [Vector2i(0,j),Vector2i(1,j),Vector2i(0,j+1),Vector2i(0,j+1),Vector2i(1,j),Vector2i(1,j+1)]:
				var angle:float=corner.y*TAU/10.
				var n:Vector3=side*cos(angle)+up*sin(angle)
				st.set_normal(n);st.add_vertex(pts[k+corner.x]+n*r)
	var part:=MeshInstance3D.new();part.mesh=st.commit();part.material_override=finish(c,grain,.33 if grain==0 else .04);parent.add_child(part)

static func band(parent:Node3D,rx:float,rz:float,y:float,r:float,col:Color)->void:
	var pts:=PackedVector3Array()
	for j in 49:pts.append(Vector3(rx*cos(TAU*j/48),y,rz*sin(TAU*j/48)))
	tube(parent,pts,r,col)

static func shell(parent:Node3D,rx:float,rz:float,h:float,foot:float,colour:Color,wood:bool)->void:
	var ring:Array[Vector2]=[Vector2(.001,0),Vector2(foot,.04),Vector2((foot+1.)*.52,.52),Vector2(1.,.97),Vector2(1.,1.),Vector2(.946,1.),Vector2(.94,.94),Vector2((foot+.92)*.50,.50),Vector2(maxf(.02,foot-.07),.10),Vector2(.001,.10)]
	var palette:Array[Color]=[colour,colour.lightened(.055),colour.darkened(.06),colour.lightened(.027)]
	for row in range(ring.size()-1):
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in 40:
			for pair in [Vector2i(row,j),Vector2i(row+1,j),Vector2i(row,j+1),Vector2i(row,j+1),Vector2i(row+1,j),Vector2i(row+1,j+1)]:
				var a:float=TAU*pair.y/40.;var v:Vector2=ring[pair.x]
				var normal:=Vector3(cos(a)/rx,(ring[row].x-ring[row+1].x)/maxf(.001,absf(ring[row+1].y-ring[row].y))*rx/h,sin(a)/rz).normalized()
				if row>=5:normal=-normal
				if row==4:normal=Vector3.UP
				st.set_normal(normal)
				var plank:Color=palette[(j/2)%4] if wood else colour
				if row>=5:plank=plank.darkened(.23)
				if row==4:plank=LIP if not wood else plank.lightened(.22)
				st.set_color(plank);st.add_vertex(Vector3(rx*v.x*cos(a),v.y*h,rz*v.x*sin(a)))
		var section:=MeshInstance3D.new();section.mesh=st.commit()
		var paint:=StandardMaterial3D.new();paint.vertex_color_use_as_albedo=true;paint.cull_mode=BaseMaterial3D.CULL_DISABLED;paint.roughness=.74 if wood else .36;paint.metallic=.14 if not wood else 0.
		section.material_override=paint;parent.add_child(section)
	band(parent,rx,rz,h,.006 if h<.12 else .009,LIP if not wood else DARK)
	if wood:
		for j in 18:
			var a:=TAU*j/18.
			tube(parent,[Vector3(rx*foot*cos(a),.012,rz*foot*sin(a)),Vector3(rx*.999*cos(a),h*.98,rz*.999*sin(a))],.0017,DARK)

static func bail(n:Node3D,rx:float,rz:float,h:float)->void:
	var pts:=PackedVector3Array()
	for j in 23:
		var a:=PI*j/22.;pts.append(Vector3(rx*1.035*cos(a),h*.80+rx*.91*sin(a),-.38*rz*sin(a)))
	tube(n,pts,.009,IRON)
	tube(n,pts.slice(8,15),.018,OAK,1.)
	for side in [-1.,1.]:
		F.piece(n,"ball",Vector3(side*rx*1.025,h*.80,0),Vector3(.030,.045,.045),LIP)

static func glove(parent:Node3D,grip:Vector3,side:float,size_factor:float)->void:
	# A thumb and four curved leather fingers meet the actual handle.
	var wrist:=F.root(parent,grip)
	wrist.scale=Vector3.ONE*size_factor
	var leather:=Color("#b07b52")
	var indigo:=Color("#355b6b")
	var hand:=Vector3(side*.034,-.014,.018)
	F.piece(wrist,"ball",hand,Vector3(.073,.058,.098),leather,Vector3(.16,0,side*.19))
	for j in 4:
		var z:=float(j-2)*.017
		tube(wrist,[Vector3(side*.042,.005,z),Vector3(side*.018,.021,z-.002),Vector3(-side*.007,.013,z-.005),Vector3(-side*.015,-.004,z-.003)],.009,leather)
	tube(wrist,[hand+Vector3(0,.016,.024),Vector3(side*.014,.026,.041),Vector3(-side*.007,.015,.020)],.013,leather)
	var elbow:=Vector3(side*.68,-.48,1.10)
	F.rod(wrist,hand+Vector3(side*.020,-.013,.052),elbow,.076,indigo)
	F.rod(wrist,hand+Vector3(side*.015,-.009,.041),hand+Vector3(side*.038,-.023,.083),.082,Color("#537c80"))

static func build(n:Node3D,tier:int)->void:
	var widths:Array[float]=[.072,.117,.155,.14,.197,.164]
	var depths:Array[float]=[.101,.125,.153,.156,.147,.165]
	var heights:Array[float]=[.034,.076,.211,.20,.136,.273]
	var feet:Array[float]=[.03,.09,.74,.80,.71,.82]
	var rx:=widths[tier];var rz:=depths[tier];var h:=heights[tier]
	var body:=Node3D.new();n.add_child(body);body.position.y=-h*.59;body.position.z=-.07
	var colours:Array[Color]=[Color("#a7b8ba"),COPPER,OAK,Color("#ab613c"),Color("#af7a49"),Color("#91603f")]
	shell(body,rx,rz,h,feet[tier],colours[tier],tier in [2,4,5])
	if tier<2:
		var handle:=PackedVector3Array([Vector3(0,h*.77,rz*.80),Vector3(.013,h*1.1,rz*1.13),Vector3(.055,h*1.38,.25),Vector3(.15,.045,.43)])
		tube(body,handle,.010 if tier==0 else .014,IRON)
		tube(body,handle.slice(2),.019 if tier==0 else .025,OAK,1.)
		for t in [.14,.86]:
			var joint:Vector3=handle[2].lerp(handle[3],t)
			F.piece(body,"ball",joint+Vector3.UP*.017,Vector3(.009,.005,.012),LIP)
	elif tier==2:bail(body,rx,rz,h)
	elif tier==3:
		tube(body,[Vector3(rx*.8,h*.79,.02),Vector3(rx*1.44,h*1.10,.01),Vector3(rx*1.55,h*.58,.02),Vector3(rx*.85,h*.25,.02)],.015,COPPER)
		tube(body,[Vector3(-rx*.68,h*.25,-.02),Vector3(-rx*1.40,h*.64,-.07),Vector3(-rx*1.86,h*1.08,-.12)],.028,LIP)
		var rose:=F.piece(body,"ball",Vector3(-rx*1.86,h*1.08,-.12),Vector3(.087,.046,.080),COPPER)
		rose.rotation.z=.65
		for j in 9:
			var a:=TAU*j/9.
			F.piece(rose,"ball",Vector3(.28*cos(a),.39,.28*sin(a)),Vector3.ONE*.083,DARK)
	elif tier==4:
		for side in [-1.,1.]:
			var pts:=PackedVector3Array()
			for j in 17:
				var a:=PI*j/16.
				pts.append(Vector3(side*rx*(.93+.25*sin(a)),h*(.72+.34*sin(a)),rz*.40*cos(a)))
			tube(body,pts,.014,Color("#cda976"),1.)
	else:
		for side in [-1.,1.]:
			var x:float=side*rx*.80
			tube(body,[Vector3(x,-.035,-.11),Vector3(x,-.035,.16),Vector3(x,.061,.45)],.017,OAK,1.)
			F.piece(body,"tube",Vector3(side*rx*1.13,-.025,.073),Vector3(.13,.038,.13),DARK,Vector3(0,0,PI/2))
			F.piece(body,"ball",Vector3(side*rx*1.26,-.025,.073),Vector3.ONE*.028,LIP)
	if tier>=2:
		for t in [.18,.78]:
			var w:=lerpf(feet[tier],1.,t)
			band(body,rx*w,rz*w,h*t,.006,IRON if tier!=3 else LIP)
	if tier<2:glove(body,Vector3(.107,.045,.35),1.,1.)
	elif tier==2:glove(body,Vector3(.018,h*.80+rx*.90,-.38*rz),1.,.78)
	elif tier==3:glove(body,Vector3(rx*1.5,h*.77,.02),1.,.89)
	elif tier==4:
		for side in [-1.,1.]:glove(body,Vector3(side*rx*1.18,h*1.06,0),side,.80)
	var water:=MeshInstance3D.new()
	var disc:=CylinderMesh.new();disc.height=.006;disc.top_radius=1.;disc.bottom_radius=1.;disc.radial_segments=48
	water.mesh=disc;water.name="Liquid";body.add_child(water)
	var m:=ShaderMaterial.new();m.shader=preload("res://shaders/vessel_water.gdshader");water.material_override=m
	water.set_meta("size",Vector3(rx,h,rz));water.set_meta("foot",feet[tier]);water.visible=false
