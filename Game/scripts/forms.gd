extends RefCounted

static var meshes := {}
static var paints := {}

static func paint(color: Color, metal := 0.0, emission := 0.0) -> StandardMaterial3D:
	var key=color.to_html()+str(metal)+":"+str(emission)
	if paints.has(key): return paints[key]
	var m=StandardMaterial3D.new()
	m.albedo_color=color
	m.roughness=0.82 if metal<0.1 else 0.38
	m.metallic=metal
	if emission>0:
		m.emission_enabled=true
		m.emission=color
		m.emission_energy_multiplier=emission
	paints[key]=m
	return m

static func root(parent: Node3D, pos := Vector3.ZERO) -> Node3D:
	var n=Node3D.new()
	parent.add_child(n)
	n.position=pos
	return n

static func primitive(kind: String) -> Mesh:
	if meshes.has(kind): return meshes[kind]
	var m: PrimitiveMesh
	match kind:
		"box": m=BoxMesh.new()
		"ball":
			var s=SphereMesh.new()
			s.radial_segments=14
			s.rings=6
			m=s
		"rock":
			var s=SphereMesh.new()
			s.radial_segments=7
			s.rings=3
			m=s
		"ring":
			var t=TorusMesh.new()
			t.inner_radius=0.34
			t.outer_radius=0.5
			t.rings=20
			t.ring_segments=7
			m=t
		_:
			var c=CylinderMesh.new()
			c.height=1.0
			c.top_radius=0.5 if kind=="tube" else (0.0 if kind=="cone" else 0.36)
			c.bottom_radius=0.5
			c.radial_segments=14
			c.rings=0
			m=c
	meshes[kind]=m
	return m

static func piece(parent: Node3D,kind:String,pos:Vector3,size:Vector3,col:Color,angles:=Vector3.ZERO,metal:=0.0) -> MeshInstance3D:
	var n=MeshInstance3D.new()
	n.mesh=primitive(kind)
	n.material_override=paint(col,metal)
	parent.add_child(n)
	n.position=pos
	n.rotation=angles
	n.scale=size
	return n

static func rod(parent:Node3D,a:Vector3,b:Vector3,width:float,color:Color) -> MeshInstance3D:
	var d=b-a
	var n=piece(parent,"tube",(a+b)*0.5,Vector3(width,d.length(),width),color)
	n.quaternion=Quaternion(Vector3.UP,d.normalized())
	return n

static func triangles(verts:PackedVector3Array)->ArrayMesh:
	var st=SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for v in verts: st.add_vertex(v)
	st.generate_normals()
	return st.commit()

static func fabric(parent:Node3D,pts:PackedVector3Array,col:Color)->MeshInstance3D:
	var n=MeshInstance3D.new()
	n.mesh=triangles(pts)
	var m=paint(col).duplicate()
	m.cull_mode=BaseMaterial3D.CULL_DISABLED
	n.material_override=m
	parent.add_child(n)
	return n

static func hull_mesh() -> Mesh:
	if meshes.has("hull"):return meshes.hull
	var verts=PackedVector3Array()
	var rows=[]
	for pair in [[-1.0,0.04],[-0.65,0.75],[0.05,1.0],[0.67,0.72],[1.0,0.025]]:
		var x=float(pair[0])
		var w=float(pair[1])
		rows.append([Vector3(x,0.12+absf(x)*0.1,-w*0.36),Vector3(x,-0.21,w*-0.21),Vector3(x,-0.34,0),Vector3(x,-0.21,w*0.21),Vector3(x,0.12+absf(x)*0.1,w*0.36)])
	for i in range(rows.size()-1):
		for j in 4:
			verts.append_array(PackedVector3Array([rows[i][j],rows[i][j+1],rows[i+1][j],rows[i+1][j],rows[i][j+1],rows[i+1][j+1]]))
		verts.append_array(PackedVector3Array([rows[i][0],rows[i+1][0],rows[i][4],rows[i][4],rows[i+1][0],rows[i+1][4]]))
	meshes.hull=triangles(verts)
	return meshes.hull

static func boat(parent:Node3D,pos:Vector3,s:float,col:Color,rigged:=true)->Node3D:
	var n=root(parent,pos)
	var hull=MeshInstance3D.new()
	hull.mesh=hull_mesh()
	var hullpaint=paint(col).duplicate()
	hullpaint.cull_mode=BaseMaterial3D.CULL_DISABLED
	hull.material_override=hullpaint
	n.add_child(hull)
	piece(n,"box",Vector3(0,0.13,0),Vector3(1.26,0.06,0.43),Color("#c98f5e"))
	if rigged:
		rod(n,Vector3(0.03,0.1,0),Vector3(0.08,1.85,0),0.055,Color("#694b3e"))
		rod(n,Vector3(-0.73,0.25,0),Vector3(0.08,1.8,0),0.016,Color("#675b4c"))
		rod(n,Vector3(0.08,1.35,0),Vector3(0.83,0.24,0),0.012,Color("#675b4c"))
		fabric(n,PackedVector3Array([Vector3(0.04,1.67,0.02),Vector3(-0.74,0.37,0.04),Vector3(-0.16,0.31,0.095),Vector3(0.04,1.67,0.02),Vector3(-0.16,0.31,0.095),Vector3(0.0,0.33,0.04)]),Color("#eddeb1"))
		fabric(n,PackedVector3Array([Vector3(0.12,1.37,-0.01),Vector3(0.17,0.42,-0.01),Vector3(0.78,0.33,0.08)]),Color("#c87655"))
	n.scale=Vector3.ONE*s
	return n

static func owl_shell(parent:Node3D)->Node3D:
	var n=root(parent)
	var shell=Color("#67aaaa")
	piece(n,"ball",Vector3(0,0.67,-0.16),Vector3(1.32,1.02,1.16),shell,Vector3(0,0,0.23))
	piece(n,"ring",Vector3(-0.67,0.77,-0.20),Vector3(0.65,0.58,0.50),shell,Vector3(PI/2,0,0))
	piece(n,"ring",Vector3(0.26,0.90,0.19),Vector3(0.80,0.68,0.80),Color("#f4e3b9"),Vector3(0.96,0,-0.31))
	for i in 6:
		var a=float(i)*TAU/6.0
		piece(n,"ball",Vector3(0.53*cos(a),0.76+0.30*sin(a),0.23),Vector3(0.13,0.12,0.07),Color("#f3d990"))
	var head=root(n,Vector3(0,0.49,0.42))
	head.name="Face"
	piece(head,"ball",Vector3.ZERO,Vector3(0.94,0.50,0.63),Color("#ca643e"))
	for side in [-1.0,1.0]:
		var h=Vector3(0.24*side,0.42,0.19)
		rod(head,Vector3(0.19*side,0.06,0.16),h,0.08,Color("#d88845"))
		piece(head,"ball",h,Vector3(0.22,0.25,0.21),Color("#f9d48e"))
		piece(head,"ball",h+Vector3(0,0.025,0.089),Vector3(0.115,0.14,0.065),Color("#14312e"))
		piece(head,"ball",h+Vector3(-0.027,0.061,0.12),Vector3.ONE*0.043,Color.WHITE)
		for i in 3:
			var z=0.24-i*0.22
			var joint=Vector3(side*(0.58+i*0.07),0.32,z)
			rod(n,Vector3(side*0.27,0.43,z-0.03),joint,0.115,Color("#c97643"))
			rod(n,joint,joint+Vector3(side*0.19,-0.30,0.13),0.085,Color("#cb7443"))
		var claw=root(n,Vector3(side*0.58,0.49,0.59))
		claw.name="PinceD" if side>0 else "PinceG"
		piece(claw,"ball",Vector3.ZERO,Vector3(0.43,0.32,0.34),Color("#d6693d"))
		for offset in [-0.10,0.10]:
			piece(claw,"cone",Vector3(offset,0.14,0.10),Vector3(0.15,0.26,0.15),Color("#e89050"),Vector3(0.48,0,-offset*2.4))
	return n

static func bowl(parent:Node3D,w:float,h:float,length:float,p:Vector3,mat:Color)->Node3D:
	var v=PackedVector3Array()
	for j in 16:
		var a=TAU*j/16.0
		var b=TAU*(j+1)/16.0
		var u=Vector3(w*cos(a),h,length*sin(a))
		var z=Vector3(w*cos(b),h,length*sin(b))
		v.append_array(PackedVector3Array([Vector3.ZERO,u*0.55+Vector3.DOWN*h*0.28,z*0.55+Vector3.DOWN*h*0.28,u*0.55+Vector3.DOWN*h*0.28,u,z,z,u*0.55+Vector3.DOWN*h*0.28,z*0.55+Vector3.DOWN*h*0.28]))
	var n=fabric(parent,v,mat)
	n.position=p
	return n

static func tool(parent:Node3D,tier:int)->Node3D:
	var n=root(parent)
	var brass=Color("#c99656")
	var silver=Color("#cddcda")
	var teal=Color("#397f7d")
	var wood=Color("#925f41")
	match tier:
		0,1:
			rod(n,Vector3(0,-0.13,0.12),Vector3(0,0.10,-0.32),0.038 if tier==0 else 0.055,wood if tier==1 else silver)
			bowl(n,0.097 if tier==0 else 0.17,0.047 if tier==0 else 0.11,0.15 if tier==0 else 0.18,Vector3(0,0.12,-0.42),silver if tier==0 else brass)
		2:
			bowl(n,0.19,0.29,0.19,Vector3(0,-0.21,-0.23),teal)
			piece(n,"ring",Vector3(0,0.09,-0.23),Vector3(0.41,0.13,0.41),silver)
			piece(n,"ring",Vector3(0,0.12,-0.23),Vector3(0.42,0.11,0.39),brass,Vector3(PI/2,0,0))
		3,4:
			piece(n,"tube",Vector3(0,-0.035,-0.29),Vector3(0.25,0.43,0.25),teal,Vector3(0.45,0,-0.14))
			rod(n,Vector3(0,0.11,-0.34),Vector3(0,0.34,-0.46),0.055,silver)
			rod(n,Vector3(-0.16,0.33,-0.46),Vector3(0.16,0.33,-0.46),0.065,wood)
			piece(n,"ring",Vector3(0.13,-0.07,-0.26),Vector3(0.26,0.11,0.26),brass,Vector3(0,0,PI/2))
			if tier==4:
				for j in 4:
					var a=j*PI/2
					piece(n,"box",Vector3(0.135*cos(a),0.08+0.135*sin(a),-0.55),Vector3(0.21,0.08,0.025),Color("#ede1b7"),Vector3(0,0,a))
		5:
			piece(n,"box",Vector3(0,0.0,-0.25),Vector3(0.46,0.26,0.46),Color("#e8b954"),Vector3(0.14,0.2,0.12))
			for i in 13:
				var a=i*2.39996
				piece(n,"rock",Vector3(0.19*cos(a),0.11+0.04*sin(a*2.0),-0.25+0.19*sin(a)),Vector3(0.07,0.035,0.065),Color("#b88c42"))
	return n
