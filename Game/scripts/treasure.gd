extends RefCounted
const F=preload("res://scripts/forms.gd")
const V=preload("res://scripts/vessels.gd")
const BRASS=Color("#c7964e")
const EDGE=Color("#f5d79a")
const TEAL=Color("#458f91")
const DEEP=Color("#234d5b")
const PEARL=Color("#f9dfc2")
const ROSE=Color("#d87968")
const INK=Color("#4a493f")
const WOOD=Color("#985e3e")

static func ball(n:Node3D,pos:Vector3,size:Vector3,col:Color)->void:
	F.piece(n,"ball",pos,size,col,Vector3.ZERO,.19)

static func profile(n:Node3D,levels:Array,colors:Array,seg:=24)->void:
	for k in range(levels.size()-1):
		var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for j in seg:
			for v in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1)]:
				var row:Vector2=levels[k+v.x];var a:float=TAU*(j+v.y)/seg
				st.add_vertex(Vector3(row.x*cos(a),row.y,row.x*sin(a)))
		st.generate_normals()
		var mesh:=MeshInstance3D.new();mesh.mesh=st.commit()
		var mat:=F.paint(colors[mini(k,colors.size()-1)],.26).duplicate() as StandardMaterial3D
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.material_override=mat;n.add_child(mesh)

static func gem(n:Node3D,pt:Vector3,s:float,col:Color)->void:
	var stone:=F.root(n,pt)
	profile(stone,[Vector2(.015,0),Vector2(.20,.13),Vector2(.19,.22),Vector2(.105,.31),Vector2(0.,.31)],[col.darkened(.24),col,col.lightened(.22),col.lightened(.40)],7)
	stone.scale=Vector3.ONE*s

static func scallop(n:Node3D,with_pearl:bool)->void:
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in 28:
		for k in 3:
			for v in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1)]:
				var i:int=j+v.x;var t:float=(k+v.y)/3.;var a:=lerpf(-1.24,1.24,float(i)/28)
				var ridge:=.5+.5*cos(i*PI)
				st.set_color(PEARL.lerp(ROSE,.12+.37*(1.-ridge)*t))
				st.add_vertex(Vector3(sin(a)*t*.30,.06+t*t*.14+ridge*.02*t,.17-cos(a)*t*.51))
	st.generate_normals();var m:=MeshInstance3D.new();m.mesh=st.commit()
	var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.cull_mode=BaseMaterial3D.CULL_DISABLED;m.material_override=mat;n.add_child(m)
	if with_pearl:ball(n,Vector3(0,.18,-.065),Vector3.ONE*.19,Color("#f3e3ca"))

static func dial(n:Node3D,stars:bool)->void:
	F.piece(n,"tube",Vector3(0,.084,0),Vector3(.48,.13,.48),BRASS,Vector3.ZERO,.48)
	F.piece(n,"tube",Vector3(0,.155,0),Vector3(.424,.015,.424),DEEP)
	V.band(n,.232,.232,.163,.012,EDGE)
	for j in (12 if stars else 8):
		var a:=j*TAU/(12. if stars else 8.)
		F.rod(n,Vector3(.16*sin(a),.168,.16*cos(a)),Vector3(.193*sin(a),.168,.193*cos(a)),.011,EDGE)
	F.fabric(n,PackedVector3Array([Vector3(-.033,.18,0),Vector3(0,.18,-.16),Vector3(.033,.18,0)]),ROSE)
	F.fabric(n,PackedVector3Array([Vector3(-.033,.18,0),Vector3(.033,.18,0),Vector3(0,.18,.16)]),PEARL)
	ball(n,Vector3(0,.185,0),Vector3.ONE*.033,EDGE)
	if stars:
		var ring:=F.piece(n,"ring",Vector3(0,.31,0),Vector3(.62,.09,.62),BRASS,Vector3(PI*.5,0,.24),.50)
		F.rod(n,Vector3(-.19,.11,0),Vector3(.19,.51,0),.022,EDGE)

static func make(n:Node3D,item:ItemData)->void:
	var shape:=item.shape
	match shape:
		"shell","pearl":scallop(n,shape=="pearl")
		"coin","medal":
			F.piece(n,"tube",Vector3(0,.058,0),Vector3(.37,.066,.37),BRASS,Vector3.ZERO,.48)
			V.band(n,.164,.164,.095,.009,EDGE)
			# The mint stamp is a raised whelk spiral, distinct from the compass rose.
			var curl:=PackedVector3Array()
			for j in 32:
				var t:=float(j)/31.;var a:=t*TAU*1.72
				curl.append(Vector3(cos(a)*(.012+.101*t),.098,sin(a)*(.012+.085*t)))
			V.tube(n,curl,.010,EDGE)
			if shape=="medal":
				for side in [-1.,1.]:F.piece(n,"box",Vector3(.055*side,.044,-.22),Vector3(.086,.028,.29),TEAL,Vector3(0,.16*side,0))
		"bottle","flask","float":
			var vessel:=F.root(n)
			profile(vessel,[Vector2(.02,.03),Vector2(.12,.045),Vector2(.16,.14),Vector2(.15,.27),Vector2(.066,.35),Vector2(.055,.46),Vector2(.07,.47)],[DEEP,TEAL,TEAL,TEAL.lightened(.15),TEAL,EDGE],16)
			F.piece(vessel,"tube",Vector3(0,.49,0),Vector3(.108,.067,.108),WOOD)
			V.band(vessel,.153,.153,.22,.011,EDGE)
			if shape=="float":vessel.scale=Vector3(1.38,.78,1.38)
			if shape=="flask":vessel.scale=Vector3(1.05,.91,.67);gem(vessel,Vector3(0,.49,0),.42,Color("#b083ad"))
		"coral","brooch":
			for j in 7:
				var a:float=j*2.39;var tip:=Vector3(sin(a)*.19,.25+.11*(j%3),cos(a)*.13)
				V.tube(n,[Vector3(0,.03,0),tip*.59+Vector3(.017,0,0),tip],.027,ROSE if shape=="coral" else BRASS)
				ball(n,tip,Vector3.ONE*.057,PEARL if shape=="brooch" else ROSE)
			if shape=="brooch":gem(n,Vector3.ZERO,.58,TEAL)
		"cup","bell":
			if shape=="bell":
				profile(n,[Vector2(.20,.035),Vector2(.21,.065),Vector2(.14,.17),Vector2(.105,.27),Vector2(.055,.31),Vector2(0,.32)],[EDGE,BRASS,BRASS,BRASS,EDGE])
				F.piece(n,"ring",Vector3(0,.345,0),Vector3(.12,.065,.12),BRASS,Vector3(PI/2,0,0))
			else:
				profile(n,[Vector2(.08,.035),Vector2(.13,.065),Vector2(.17,.21),Vector2(.16,.25),Vector2(.148,.25),Vector2(.08,.08)],[PEARL,TEAL,TEAL,EDGE,DEEP])
				F.piece(n,"ring",Vector3(.168,.151,0),Vector3(.18,.052,.18),TEAL,Vector3(PI/2,0,0))
		"tile","soap","comb":
			F.piece(n,"box",Vector3(0,.06,0),Vector3(.43,.095,.32 if shape!="comb" else .09),TEAL if shape!="soap" else ROSE)
			if shape=="tile" and item.journal_id==13:
				for j in 6:
					var a:=TAU*j/6.
					ball(n,Vector3(cos(a)*.070,.117,sin(a)*.070),Vector3(.087,.023,.076),ROSE)
				ball(n,Vector3(0,.126,0),Vector3(.062,.026,.062),EDGE)
				n.scale=Vector3.ONE*1.36
				return
			for j in 7:
				var x:float=(j-3)*.054
				if shape=="comb":F.rod(n,Vector3(x,.072,.015),Vector3(x,.052,.204),.024,EDGE)
				elif item.journal_id==14:F.rod(n,Vector3(-.17,.11,x*.74),Vector3(.17,.11,x*.74),.012,EDGE if j%2==0 else ROSE)
				else:F.rod(n,Vector3(x-.035,.11,-.10),Vector3(x+.036,.11,.10),.012,PEARL if j%2==0 else BRASS)
		"toy":F.boat(n,Vector3(0,.12,0),.36,WOOD)
		"key","link","ring":
			var col:=EDGE if item.journal_id==16 else BRASS
			F.piece(n,"ring",Vector3(-.08,.095,0),Vector3(.29,.12,.31),col,Vector3(.27,0,0),.50)
			if shape=="key":
				F.rod(n,Vector3(.015,.095,.02),Vector3(.30,.075,.02),.049,col)
				for j in 2:F.rod(n,Vector3(.22+j*.065,.08,.02),Vector3(.22+j*.065,.08,.115-j*.025),.037,col)
			elif shape=="link":F.piece(n,"ring",Vector3(.105,.145,0),Vector3(.28,.10,.28),BRASS,Vector3(.78,0,.23),.4)
			else:gem(n,Vector3(-.19,.098,.02),.43,TEAL)
		"glass","emerald":
			gem(n,Vector3.ZERO,1.0 if shape=="glass" else 1.45,TEAL if shape=="glass" else Color("#279776"))
			if shape=="emerald":V.band(n,.241,.241,.19,.016,BRASS)
		"compass","astrolabe":dial(n,shape=="astrolabe")
		"scope":
			var telescope:=F.root(n,Vector3(-.18,.088,0));telescope.rotation.z=-1.36
			profile(telescope,[Vector2(.07,0),Vector2(.07,.18),Vector2(.10,.18),Vector2(.10,.34),Vector2(.13,.34),Vector2(.13,.49),Vector2(0,.49)],[BRASS,EDGE,WOOD,BRASS,BRASS,DEEP])
			for j in 3:V.band(telescope,.072+j*.03,.072+j*.03,.04+j*.215,.011,EDGE)
		"crown","diadem":
			V.band(n,.215,.17,.082,.027,BRASS);V.band(n,.215,.17,.12,.010,EDGE)
			for j in 7:
				var a:=TAU*j/7.;var h:=.24+.10*(.5+.5*cos(a))
				var p:=Vector3(.215*sin(a),0,.17*cos(a))
				F.fabric(n,PackedVector3Array([p+Vector3(-.055*cos(a),.11,.055*sin(a)),p+Vector3.UP*h,p+Vector3(.055*cos(a),.11,-.055*sin(a))]),BRASS)
				ball(n,p+Vector3.UP*h,Vector3.ONE*.045,PEARL)
			gem(n,Vector3(0,.12,.18),.46,ROSE if shape=="crown" else TEAL)
		"chest":
			F.piece(n,"box",Vector3(0,.14,0),Vector3(.54,.25,.34),WOOD)
			F.piece(n,"ball",Vector3(0,.258,0),Vector3(.55,.21,.35),WOOD)
			for side in [-1.,1.]:
				V.tube(n,[Vector3(side*.16,.045,.176),Vector3(side*.16,.26,.177),Vector3(side*.16,.355,.055),Vector3(side*.16,.355,-.055),Vector3(side*.16,.26,-.177),Vector3(side*.16,.045,-.177)],.022,BRASS)
			F.piece(n,"box",Vector3(0,.224,.182),Vector3(.092,.105,.027),EDGE);ball(n,Vector3(0,.23,.20),Vector3.ONE*.031,INK)
	n.scale=Vector3.ONE*1.36
