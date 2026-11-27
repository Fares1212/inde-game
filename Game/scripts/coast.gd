extends Node3D

const F=preload("res://scripts/forms.gd")
const S=preload("res://scripts/shore.gd")
const SUN=Vector3(-.48,.147,-.865)
const Craft=preload("res://scripts/shorecraft.gd")
const DOCK=Vector2(-7.2,84.5)
const SHOP=Vector2(6.8,83.3)
const PORTS=[Vector2(-7.2,84.5),Vector2(-12,79),Vector2(-13,73),Vector2(-14,65),Vector2(-15,55),Vector2(-15,43)]
const RADII=[74.6,65.9,56.0,46.0,34.0,19.0]
var rng=RandomNumberGenerator.new()
var water:MeshInstance3D
var sea:ShaderMaterial
var sand:ShaderMaterial
var sun:DirectionalLight3D
var sky_env:WorldEnvironment
var crab:Node3D
var lantern:MeshInstance3D
var lamp_material:StandardMaterial3D
var shipwrecks:Array=[]
var foliage:Array=[]
var finds:Array=[]
var saltworks:=preload("res://scripts/saltworks.gd").new()
var ports:Array=[]
var huts:Array=[]
var turbines:Array=[]
var signs:Array=[]
var feet:Array=[]
var foot_i:=0
var splashes:Array=[]
var spl_i:=0
var flock:MultiMeshInstance3D
var plug:Node3D
var chain:Node3D
var fleet_paint:ShaderMaterial
var finale_fleet:Node3D
var elapsed:=0.0
var current_region:=-1
var last_ui_tick:=-1
var reel:=0.0
var active_tier:=-1
var mirror:Node3D
var test_small:=false

func build() -> void:
	rng.seed=int(Voyage.p.seed)
	make_sky()
	var surf=S.terrain(self)
	water=surf[0];sea=surf[1];sand=surf[2]
	make_scenery()
	make_beach()
	for spec in [[-14.,80.,1.18,.1],[13.,80.,1.44,1.8],[18.,75.,1.14,2.5],[23.,72.,1.52,-.4],[-28.,66.,.98,1.1],[34.,71.,1.46,.8],[-19.,87.,1.49,.5],[12.,89.,1.1,1.0]]:
		Craft.palm(self,Vector2(spec[0],spec[1]),spec[2],spec[3])
	Craft.pools(self)
	make_props()
	make_finds()
	make_plug()
	make_traces()
	refresh()
	refresh_quality()

func make_sky() -> void:
	sky_env=WorldEnvironment.new()
	var env=Environment.new()
	var sk=Sky.new()
	var mat=ShaderMaterial.new()
	mat.shader=preload("res://shaders/horizon.gdshader")
	sk.radiance_size=Sky.RADIANCE_SIZE_128
	sk.sky_material=mat
	env.sky=sk
	env.background_mode=Environment.BG_SKY
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color("#d2e3dd")
	env.ambient_light_energy=0.59
	env.reflected_light_source=Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure=0.91
	env.fog_enabled=true
	env.fog_sky_affect=0.0
	env.fog_light_color=Color("#a9cbc4")
	env.fog_density=0.00135
	sky_env.environment=env
	add_child(sky_env)
	sun=DirectionalLight3D.new()
	add_child(sun)
	sun.look_at(-SUN.normalized(),Vector3.UP)
	sun.light_color=Color("#ffe1aa")
	sun.light_energy=.83
	sun.light_specular=.35
	sun.light_angular_distance=0.7
	sun.directional_shadow_max_distance=35
	sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.shadow_bias=.045;sun.shadow_normal_bias=1.1;sun.shadow_blur=1.45

func refresh_quality()->void:
	sun.shadow_enabled=int(Voyage.opt.quality)>0
	sea.set_shader_parameter("quality",float(Voyage.opt.quality))

func wind_paint(col:Color)->ShaderMaterial:
	var mat:=ShaderMaterial.new();mat.shader=preload("res://shaders/blades.gdshader")
	mat.set_shader_parameter("blade",col)
	return mat

func batch(kind:String,ts:Array,col:Color,shadows:=false)->MultiMeshInstance3D:
	var mm=MultiMesh.new()
	mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.mesh=F.primitive(kind)
	mm.instance_count=ts.size()
	for i in ts.size():mm.set_instance_transform(i,ts[i])
	var obj=MultiMeshInstance3D.new()
	obj.multimesh=mm
	obj.material_override=F.paint(col)
	obj.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(obj)
	return obj

func tf(pos:Vector3,size:Vector3,yaw:=0.0,lean:=0.0)->Transform3D:
	return Transform3D(Basis.from_euler(Vector3(lean,yaw,0)).scaled_local(size),pos)

func make_headlands()->void:
	var tri=SurfaceTool.new()
	tri.begin(Mesh.PRIMITIVE_TRIANGLES)
	for island in 17:
		var a=float(island)*TAU/17.0+.17
		if sin(a*3.2+.35)>.28:continue
		var center=Vector2(cos(a),sin(a))*rng.randf_range(103,117)
		var face=Vector2(-sin(a),cos(a))
		var side=Vector2(cos(a),sin(a))
		var length=rng.randf_range(14,30)
		var width=rng.randf_range(6,12)
		var lift=rng.randf_range(5,12)
		var rows=[]
		for k in 12:
			var t=TAU*k/12.0
			var outline=face*(cos(t)*length*rng.randf_range(.88,1.09))+side*(sin(t)*width*rng.randf_range(.86,1.14))
			var cap=lift*(.69+.25*cos(t*2.0+a)+rng.randf_range(-.08,.13))
			var row=[]
			for j in 4:
				var v=center+outline*[1.2,1.0,.97,.83][j]+face*j*.26
				row.append(Vector3(v.x,[-.6,4.95,5.3+cap*.44,5.5+cap][j],v.y))
			rows.append(row)
		for k in 12:
			var arow=rows[k]
			var brow=rows[(k+1)%12]
			for j in 3:
				var normal=(arow[j+1]-arow[j]).cross(brow[j]-arow[j]).normalized()
				if normal.dot(Vector3(arow[j].x-center.x,0,arow[j].z-center.y))<0:normal=-normal
				for v in [arow[j],arow[j+1],brow[j],brow[j],arow[j+1],brow[j+1]]:
					tri.set_normal(normal);tri.add_vertex(v)
			for v in [arow[3],Vector3(center.x,5.6+lift*.84,center.y),brow[3]]:
				tri.set_normal(Vector3.UP);tri.add_vertex(v)
	var cliffs=MeshInstance3D.new()
	cliffs.mesh=tri.commit()
	var paint=ShaderMaterial.new();paint.shader=preload("res://shaders/cliff.gdshader")
	cliffs.material_override=paint;cliffs.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(cliffs)

func make_scenery()->void:
	make_headlands()
	var rocks=[[],[],[]]
	var reeds=[]
	for i in 215:
		var angle=rng.randf()*TAU
		var rad=rng.randf_range(15,97)
		var x=rad*cos(angle);var z=rad*sin(angle)
		if absf(x)<9 and z>0:continue
		var s=rng.randf_range(0.4,2.65)
		rocks[i%3].append(tf(S.place(x,z,0.12),Vector3(s*1.28,s*0.62,s),angle,0.13*sin(i)))
		if rad<57 and rad>35:
			for j in 3:reeds.append(tf(S.place(x+0.5*j,z,0.88),Vector3(0.19,1.8+0.26*j,0.10),angle+0.4*j,0.22*sin(i+j)))
	for i in 3:batch("rock",rocks[i],[Color("#8a8170"),Color("#68867e"),Color("#bd9575")][i])
	batch("rock",reeds,Color("#517b62")).material_override=wind_paint(Color("#517b62"))
	var coral=[]
	for i in 72:
		var a=rng.randf()*TAU;var r=rng.randf_range(53,68)
		var x=cos(a)*r;var z=sin(a)*r
		if absf(x)<6 and z>0:continue
		for j in 3:coral.append(tf(S.place(x+j*0.17,z,0.43+j*0.07),Vector3(0.18,0.89+j*0.1,0.17),a+0.5*j,(j-1)*0.43))
	batch("rock",coral,Color("#cd7c60"))
	var birds=[]
	for i in 12:
		var pos=Vector3(rng.randf_range(-43,43),rng.randf_range(10,15),rng.randf_range(-45,-12))
		for s in [-1,1]:birds.append(tf(pos+Vector3(s*0.28,0,0),Vector3(0.65,0.072,0.14),0.1,0))
	flock=batch("rock",birds,Color("#eee6d0"))
	var tower=F.root(self,S.place(-63,-60))
	for i in 4:F.piece(tower,"taper",Vector3(0,1.3+i*2.32,0),Vector3(3.8-i*.30,2.65,3.8-i*.30),Color("#eddfb3") if i%2==0 else Color("#af5d48"))
	lantern=F.piece(tower,"tube",Vector3(0,10.2,0),Vector3(2.35,1.65,2.35),Color("#dcab6d"))
	lamp_material=lantern.material_override.duplicate()
	lamp_material.emission_enabled=true;lamp_material.emission=Color("#ffdf95")
	lantern.material_override=lamp_material
	F.piece(tower,"cone",Vector3(0,11.65,0),Vector3(3.55,1.55,3.55),Color("#8c5340"))

func signpost(p:Vector3,title:String,color:Color)->void:
	F.piece(self,"tube",p+Vector3(0,0.85,0),Vector3(0.12,1.7,0.12),Color("#8e6b4f"))
	F.piece(self,"box",p+Vector3(0,1.72,0),Vector3(2.25,0.64,0.13),color)
	var label=Label3D.new()
	label.text=title
	label.font_size=45
	label.pixel_size=0.0039
	label.outline_size=3
	label.modulate=Color("#fff0c8")
	add_child(label)
	label.position=p+Vector3(0,1.73,0.082)
	label.visibility_range_end=36
	signs.append(label)

func make_beach()->void:
	var dockp=S.place(DOCK.x,DOCK.y)
	add_child(saltworks)
	saltworks.position=dockp
	saltworks.build()
	var shop=F.root(self,S.place(SHOP.x,SHOP.y))
	Craft.stall(shop)
	crab=F.owl_shell(shop)
	crab.position=Vector3(0,1.16,0.05)
	crab.rotation.y=.27
	crab.scale=Vector3.ONE*.85
	crab.visible=not (Voyage.p.free and Voyage.p.ending=="empty")
	if Voyage.p.free and Voyage.p.ending=="empty":
		sky_env.environment.adjustment_enabled=true;sky_env.environment.adjustment_saturation=.24
	var marker=F.root(self,S.place(-7.0,73.2,.38))
	F.piece(marker,"ball",Vector3.ZERO,Vector3(.52,.74,.52),Color("#bc5942"))
	F.piece(marker,"tube",Vector3(0,.08,0),Vector3(.49,.12,.49),Color("#efe0af"))
	F.piece(marker,"tube",Vector3(0,.64,0),Vector3(.055,.88,.055),Color("#976545"))
	var dunes=[]
	var pebbles=[]
	for k in 26:
		var side=-1 if k%2==0 else 1
		var x=side*rng.randf_range(3.2,18)
		var z=rng.randf_range(77.8,87)
		if Vector2(x,z).distance_to(SHOP)<3:continue
		for j in 7:
			var lean=rng.randf_range(-.55,.55)
			var q=S.place(x+rng.randf_range(-.32,.32),z+rng.randf_range(-.28,.28),.25)
			dunes.append(tf(q,Vector3(.052,.46+rng.randf()*.48,.075),rng.randf()*TAU,lean))
		pebbles.append(tf(S.place(x+.45,z-.35,.05),Vector3(.25,.12,.31),rng.randf()*TAU))
	batch("cone",dunes,Color("#7a894e")).material_override=wind_paint(Color("#7a894e"))
	batch("rock",pebbles,Color("#b79776"))
	var previous=dockp
	for j in range(1,PORTS.size()):
		var q:Vector2=PORTS[j]
		var at=S.place(q.x,q.y)
		var pipe=F.root(self,at)
		Craft.crate(pipe,Vector3(.47,0,-.08),.68)
		F.rod(pipe,Vector3(0,.14,0),Vector3(0,.68,0),.26,Color("#8f6350"))
		saltworks.intake(pipe,Vector3(0,.94,0))
		var outlet:Vector3=previous-at+Vector3(0,.18,0)
		F.rod(pipe,Vector3(0,.18,0),outlet,.22,Color("#608c83"))
		var direction:Vector3=outlet-Vector3(0,.18,0)
		for k in 4:
			var pt:=Vector3(0,.18,0)+direction*((k+.5)/4.)
			var axis:=direction.normalized()*.035
			F.rod(pipe,pt-axis,pt+axis,.266,Color("#b88954"))
		ports.append(pipe)
		previous=at
	for i in 5:
		var pos=S.place(10.8+i*2.9,74.5-i*1.7)
		var hut=F.root(self,pos)
		F.piece(hut,"taper",Vector3(0,0.48,0),Vector3(1.48,0.99,1.28),Color("#cba881"))
		F.piece(hut,"cone",Vector3(0,1.27,0),Vector3(2.1,1.0,1.85),[Color("#60938a"),Color("#bd7960"),Color("#d5ac66")][i%3])
		F.piece(hut,"ball",Vector3(0,0.37,0.61),Vector3(0.49,0.53,0.08),Color("#3b6868"))
		var dweller=F.owl_shell(hut)
		dweller.scale=Vector3.ONE*0.32
		dweller.position=Vector3(0.61,0.02,0.79)
		huts.append(hut)
	for i in 3:
		var t=F.root(self,S.place(-11-i*4,67-i*2))
		F.piece(t,"taper",Vector3(0,2.6,0),Vector3(0.46,5.2,0.46),Color("#ab8b65"))
		var rotor=F.root(t,Vector3(0,5.15,0.18))
		for j in 4:
			var arm=F.root(rotor)
			arm.rotation.z=j*PI/2
			F.piece(arm,"box",Vector3(0.12,0.98,0),Vector3(0.51,1.8,0.08),Color("#efddae"),Vector3(0.02,0.18,0.09))
		turbines.append(rotor)
		t.visible=false

func make_props()->void:
	for i in 11:
		var a=0.91+i*2.399
		var r=31.0+fmod(i*6.3,26.0)
		var pos=S.place(cos(a)*r,sin(a)*r)
		var boat=F.boat(self,pos,2.1+fmod(i*0.7,2.7),[Color("#6d5649"),Color("#825947"),Color("#497270")][i%3],i%4!=2)
		boat.rotation.y=a+0.4
		shipwrecks.append({"outline":hull_outline(boat),"node":boat,"floor":pos.y,"phase":a,"s":boat.scale.x})
	for i in 15:
		var a=0.25+i*2.40
		var r=8+fmod(i*3.61,20)
		var n=F.piece(self,"box",S.place(cos(a)*r,sin(a)*r,0.03),Vector3(2.05,.14,2.05),Color("#84a6a0") if i%2 else Color("#adb5a0"),Vector3(0,a,0))
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func make_finds()->void:
	for reg in 6:
		for j in 11:
			# Historical positions, IDs and RNG draws stay stable for old saves.
			var a:=PI*.5+(j-5)*.24+rng.randf_range(-.055,.055)
			var r:float=RADII[reg]+rng.randf_range(-1.3,1.6)
			var q:=Vector2(cos(a)*r,sin(a)*r)
			if reg==0 and j<3:q=[Vector2(1.35,77.3),Vector2(-5.5,76.3),Vector2(4.0,75.6)][j]
			add_find(reg*16+j,reg*3+j%3,q,rng.randf()*TAU)
	for k in range(18,Voyage.RULES.items.size()):
		var reg:int=Voyage.RULES.items[k].region
		for j in 2:
			var angle:=1.12+float(k%2)*.89+float(j)*.30
			var r:float=RADII[reg]+1.2-float(j)*.74
			add_find(1000+k*2+j,k,Vector2(cos(angle),sin(angle))*r,angle+.37*j)

func add_find(id:int,kind:int,point:Vector2,heading:float)->void:
	var n:=F.root(self,S.place(point.x,point.y,.045))
	preload("res://scripts/treasure.gd").make(n,Voyage.RULES.items[kind])
	n.rotation.y=heading
	finds.append({"node":n,"id":id,"kind":kind,"r":Voyage.RULES.items[kind].region,"p":n.position})

func can_take(entry:Dictionary)->bool:
	var item:ItemData=Voyage.RULES.items[entry.kind]
	return Voyage.p.peak>=item.reveal_ml and entry.p.y>=Voyage.water_y()-.10 and not Voyage.p.taken.has(str(entry.id)) and not (entry.kind==16 and Voyage.p.seen.has(item.id))

func make_plug()->void:
	plug=F.root(self,S.place(0,0,0.1))
	F.piece(plug,"tube",Vector3(0,.22,0),Vector3(4.1,.48,4.1),Color("#4e554b"))
	F.piece(plug,"ring",Vector3(0,.48,0),Vector3(4.7,.66,4.7),Color("#b49361"))
	F.piece(plug,"ring",Vector3(0,.78,0),Vector3(1.0,.8,1.1),Color("#bc9561"),Vector3(PI/2,0,0))
	chain=F.root(self,S.place(0,0,0.82))
	var pulley=F.root(self,S.place(0,0))
	for side in [-1.,1.]:
		F.rod(pulley,Vector3(side*3,0,-1.),Vector3(side*.82,8.,0),.34,Color("#83684a"))
	F.rod(pulley,Vector3(-1.25,7.9,0),Vector3(1.25,7.9,0),.3,Color("#76664e"))
	F.piece(pulley,"ring",Vector3(0,7.75,0),Vector3(1.1,.34,1.1),Color("#aa8d55"),Vector3(PI/2,0,0))
	for i in 9:
		var y=i*.87
		F.piece(chain,"ring",Vector3(sin(y*.065)*minf(2.1,y*.06),y,0.0),Vector3(.58,.47,1.12),Color("#6b7365"),Vector3(PI/2,0.0 if i%2==0 else PI/2,0))
	finale_fleet=F.root(self)
	finale_fleet.visible=false

func start_finale()->void:
	if finale_fleet.get_child_count()>0:return
	var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D
	mm.use_custom_data=true
	mm.custom_aabb=AABB(Vector3(-75,-25,-75),Vector3(150,55,150))
	var v=PackedVector3Array([Vector3(-1,0,-.3),Vector3(1,0,0),Vector3(-.76,0,.37),Vector3(-1,0,-.3),Vector3(-.2,-.30,0),Vector3(1,0,0),Vector3(-.76,0,.37),Vector3(1,0,0),Vector3(-.2,-.30,0),Vector3(.0,.83,0),Vector3(-.62,.11,0),Vector3(.0,.11,0)])
	mm.mesh=F.triangles(v)
	mm.instance_count=2080
	for i in mm.instance_count:
		var angle=fmod(i*.381966+0.02,1.0)
		var radius=sqrt((i+.5)/float(mm.instance_count))
		mm.set_instance_transform(i,Transform3D.IDENTITY)
		mm.set_instance_custom_data(i,Color(angle,radius,rng.randf(),1.0))
	var fleet=MultiMeshInstance3D.new()
	fleet.multimesh=mm
	fleet_paint=ShaderMaterial.new()
	fleet_paint.shader=preload("res://shaders/fleet.gdshader")
	fleet_paint.set_shader_parameter("relief",sea.get_shader_parameter("relief"))
	fleet.material_override=fleet_paint
	fleet.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	finale_fleet.add_child(fleet);finale_fleet.visible=true

func make_traces()->void:
	var mat=ShaderMaterial.new();mat.shader=preload("res://shaders/foot.gdshader")
	var plane=PlaneMesh.new();plane.size=Vector2(.23,.45)
	for i in 76:
		var n=MeshInstance3D.new();n.mesh=plane;n.material_override=mat;n.visible=false
		n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(n);feet.append({"n":n,"at":-50.0})
	for i in 32:
		var n=F.piece(self,"ball",Vector3.ZERO,Vector3.ONE*0.06,Color("#b6e1d5"))
		n.visible=false;n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		splashes.append({"n":n,"v":Vector3.ZERO,"life":0.0})

func step_foot(at:Vector3,yaw:float,right:bool)->void:
	var lateral=Vector3(cos(yaw),0,-sin(yaw))*(0.115 if right else -0.115)
	var p=at+lateral
	if S.ground(p.x,p.z)<water.position.y-.03:return
	var mark=feet[foot_i];foot_i=(foot_i+1)%feet.size()
	mark.n.position=S.place(p.x,p.z,.035)
	var normal=Vector3(S.ground(p.x-.2,p.z)-S.ground(p.x+.2,p.z),.4,S.ground(p.x,p.z-.2)-S.ground(p.x,p.z+.2)).normalized()
	var front=Vector3(-sin(yaw),0,-cos(yaw)).slide(normal).normalized()
	mark.n.basis=Basis.looking_at(front,normal)
	mark.n.visible=true;mark.at=elapsed

func splash(pos:Vector3,large:=false)->void:
	sea.set_shader_parameter("splash_pos",Vector2(pos.x,pos.z))
	sea.set_shader_parameter("splash_at",elapsed)
	for j in (13 if large else 7):
		var drop=splashes[spl_i];spl_i=(spl_i+1)%splashes.size()
		drop.erase("delay");drop.erase("impact")
		drop.n.position=pos+Vector3.UP*.13;drop.n.visible=true
		drop.life=rng.randf_range(.30,.68)
		drop.v=Vector3(rng.randf_range(-1.4,1.4),rng.randf_range(1.3,3.6),rng.randf_range(-1.4,1.4))

func pour_arc(start:Vector3,finish:Vector3)->void:
	# Stagger ballistic droplets from the vessel lip to the mouth of the spillway.
	const FLIGHT:=.38
	for i in 12:
		var drop:Dictionary=splashes[spl_i];spl_i=(spl_i+1)%splashes.size()
		var delay:float=i*.018
		drop.n.position=start
		drop.n.visible=false
		drop["delay"]=delay
		drop["impact"]=finish
		drop.life=FLIGHT
		drop.v=(finish-start)/FLIGHT+Vector3.UP*(4.*FLIGHT)+Vector3(rng.randf_range(-.09,.09),0,rng.randf_range(-.09,.09))
	sea.set_shader_parameter("splash_pos",Vector2(finish.x,finish.z))
	sea.set_shader_parameter("splash_at",elapsed+FLIGHT)

func refresh()->void:
	var next_region=Voyage.region()
	if current_region!=next_region:
		sea.set_shader_parameter("shallows",Color(str(Voyage.db.zones[next_region].tint)).darkened(.13))
		sea.set_shader_parameter("deep",Color("#246887").lerp(Color("#313f56"),next_region/5.))
	current_region=next_region
	for i in ports.size():ports[i].visible=i+1<=current_region
	for i in huts.size():huts[i].visible=i<current_region
	for rotor in turbines:rotor.get_parent().visible=int(Voyage.p.tier)>=4
	water.position.y=Voyage.water_y()
	for find in finds:
		find.node.visible=can_take(find)
	plug.visible=current_region==5
	active_tier=Voyage.p.tier

func animate(dt:float,ending:float=-1.0)->void:
	elapsed+=dt
	saltworks.advance(dt)
	var y=Voyage.water_y()
	water.position.y=y
	sea.set_shader_parameter("sea_level",y);sea.set_shader_parameter("clock",elapsed)
	sand.set_shader_parameter("tide_level",y)
	var tick=int(elapsed*3)
	if tick!=last_ui_tick or active_tier!=Voyage.p.tier:
		last_ui_tick=tick;refresh()
		for mark in feet:
			if mark.n.visible and (elapsed-mark.at>39 or mark.n.position.y<y-.015):mark.n.visible=false
	for d in splashes:
		if d.life<=0:continue
		if d.get("delay",0.)>0:
			d.delay-=dt
			continue
		d.n.visible=true
		d.life-=dt;d.n.position+=d.v*dt;d.v.y-=8.0*dt
		if d.life<=0:d.n.visible=false
	for boat in shipwrecks:
		var n=boat.node
		var axle:Vector3=n.basis.x.normalized()*float(boat.s)*.65
		var bow=S.ground(n.position.x+axle.x,n.position.z+axle.z)
		var stern=S.ground(n.position.x-axle.x,n.position.z-axle.z)
		var bottom=maxf(bow,stern)+float(boat.s)*.20
		var wet=clampf((y-bottom)/.9,0,1)
		n.position.y=maxf(bottom,y+sin(elapsed*1.36+boat.phase)*.12)
		n.rotation.z=lerpf(clampf(atan2(bow-stern,axle.length()*2.),-.21,.21),sin(elapsed*.92+boat.phase)*.04,wet)
	crab.position.y=1.16+sin(elapsed*2.55)*.035
	var camera:=get_viewport().get_camera_3d()
	var head:Node3D=crab.get_node("Face")
	var look_angle:=.12*sin(elapsed*1.5)
	if is_instance_valid(camera) and crab.global_position.distance_to(camera.global_position)<12.:
		var local:=crab.to_local(camera.global_position)
		look_angle=clampf(atan2(local.x,local.z),-.54,.54)
	head.rotation.y=lerp_angle(head.rotation.y,look_angle,1.-exp(-dt*5.))
	for eye:Node3D in head.get_children():
		if eye.has_meta("blinks"):
			eye.scale.y=1.-.91*exp(-pow((fmod(elapsed+.32,4.7)-.11)/.064,2.))
	lamp_material.emission_energy_multiplier=.18+3.8*pow(maxf(0.,cos(elapsed*1.56)),25.)
	crab.get_node("PinceD").rotation.z=.22*sin(elapsed*2.0)
	for rotor in turbines:
		if rotor.get_parent().visible:rotor.rotate_z(dt*(1.55+.42*Voyage.tide()))
	flock.rotation.y=.11*sin(elapsed*.10)
	flock.position.y=.46*sin(elapsed*.91)
	if ending>=0.0:
		var t=clampf(ending/12.0,0,1)
		if fleet_paint:fleet_paint.set_shader_parameter("progress",t)
		plug.position.y=-11.7+sin(t*PI)*4.0
		chain.rotation.z=sin(ending*1.8)*.027
		sea.set_shader_parameter("whirl",sin(t*PI)*1.3)

static func hull_outline(boat:Node3D)->PackedVector2Array:
	# Use the same cross sections as the rendered hull, projected onto the sea.
	var outline:=PackedVector2Array()
	for v in [Vector2(-1.,-.015),Vector2(-.65,-.27),Vector2(.05,-.36),Vector2(.67,-.259),Vector2(1.,-.009),Vector2(1.,.009),Vector2(.67,.259),Vector2(.05,.36),Vector2(-.65,.27),Vector2(-1.,.015)]:
		outline.append(Vector2(boat.position.x,boat.position.z)+(v*boat.scale.x).rotated(-boat.rotation.y))
	return outline

func slide_past_boats(start:Vector3,desired:Vector3)->Vector3:
	const RADIUS:=.39
	var at:=Vector2(start.x,start.z)
	var motion:=Vector2(desired.x-start.x,desired.z-start.z)
	var pieces:=maxi(1,ceili(motion.length()/.20))
	for step in pieces:
		at+=motion/pieces
		for boat in shipwrecks:
			var center:Vector3=boat.node.position
			if at.distance_squared_to(Vector2(center.x,center.z))>pow(float(boat.s)+.8,2):continue
			var poly:PackedVector2Array=boat.outline
			var best:=INF
			var near:=at
			var outward:=Vector2.RIGHT
			for i in poly.size():
				var a:=poly[i];var b:=poly[(i+1)%poly.size()]
				var edge:=Geometry2D.get_closest_point_to_segment(at,a,b)
				var dist:=edge.distance_squared_to(at)
				if dist<best:
					best=dist;near=edge;outward=Vector2(b.y-a.y,a.x-b.x).normalized()
			var inside:=Geometry2D.is_point_in_polygon(at,poly)
			if inside or best<RADIUS*RADIUS:
				var normal:Vector2=(at-near).normalized() if not inside and best>.000001 else outward
				at=near+normal*(RADIUS+.001)
	return Vector3(at.x,desired.y,at.y)
