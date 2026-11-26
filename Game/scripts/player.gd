extends Node3D

const S=preload("res://scripts/shore.gd")
const F=preload("res://scripts/forms.gd")
var cam:Camera3D
var hand:Node3D
var model:Node3D
var model_tier:=-1
var yaw:=0.0
var pitch:=-0.11
var floor_y:=0.0
var jump_y:=0.0
var vertical:=0.0
var stride:=0.0
var footprint_at:=0.0
var right_foot:=false
var swing:=1.0
var kick:=0.0
var motion:=Vector2.ZERO
var edge_water:=false
var walking:=false
var coast
var fill_view:=0.0
var liquid:MeshInstance3D
var pouring:=false
var turn_impulse:=0.0

func setup(world)->void:
	coast=world
	cam=Camera3D.new();cam.near=.055;cam.far=285;add_child(cam);cam.current=true
	hand=Node3D.new();cam.add_child(hand)
	hand.position=Vector3(.31,-.29,-.35);hand.rotation=Vector3(-.05,-.14,-.12)
	var saved=Voyage.p.pos
	if saved is Array and saved.size()==3 and absf(float(saved[0]))<=98 and absf(float(saved[2]))<=98:
		position=S.place(float(saved[0]),float(saved[2]))
		yaw=Voyage.p.yaw;pitch=clampf(float(Voyage.p.pitch),-1.4,1.42)
	else:position=S.place(0,90.4);yaw=-.12;pitch=-.095
	floor_y=position.y
	cam.position.y=1.60
	rebuild()
	orient()
	cam.fov=Voyage.opt.fov

func rebuild()->void:
	if is_instance_valid(model):model.hide();model.queue_free()
	model=Voyage.vessel().model.instantiate();hand.add_child(model);model_tier=int(Voyage.p.tier)
	liquid=model.find_child("Liquid",true,false)
	fill_view=Voyage.p.bag/Voyage.capacity()

func orient()->void:
	rotation.y=yaw;cam.rotation.x=pitch

func mouse(delta:Vector2)->void:
	turn_impulse=clampf(turn_impulse+delta.x*.002,-.25,.25)
	var scale_s=0.0019*float(Voyage.opt.sensitivity)
	yaw=wrapf(yaw-delta.x*scale_s,-PI,PI)
	pitch=clampf(pitch-delta.y*scale_s*(-1 if Voyage.opt.invert_y else 1),-1.45,1.45)
	orient()

func animate_action(strength:=1.0)->void:
	swing=0.0;kick=strength;pouring=strength>1.03

func go(x:float,z:float)->void:
	position=S.place(x,z);floor_y=position.y;jump_y=0;vertical=0

func record()->void:
	if Voyage.p.is_empty():return
	Voyage.p.pos=[position.x,position.y,position.z];Voyage.p.yaw=yaw;Voyage.p.pitch=pitch

func move(dt:float)->void:
	if model_tier!=int(Voyage.p.tier):rebuild()
	var stick=Input.get_vector("look_left","look_right","look_up","look_down")
	if stick.length()>.05:mouse(stick*dt*1150)
	var raw=Input.get_vector("left","right","forward","back")
	motion=motion.move_toward(raw,dt*8.0)
	walking=motion.length()>.13
	var dir=Vector3(motion.x,0,motion.y).rotated(Vector3.UP,yaw)
	var w=coast.water.position.y
	var depth=w-S.ground(position.x,position.z)
	var running=Input.is_action_pressed("sprint") and walking
	var speed=7.4 if running else 4.55
	if depth>.28:speed*=.78
	speed*=1.-Voyage.vessel().slowdown*Voyage.p.bag/Voyage.capacity()
	if running and Voyage.spill(dt)>0 and footprint_at<.1:coast.splash(position+Vector3.UP*.28)
	var dest=position+dir*speed*dt
	var dist=Vector2(dest.x,dest.z)
	if dist.length()>96:
		var limit=dist.limit_length(96)
		dest.x=limit.x
		dest.z=limit.y
	var floor_target=maxf(S.ground(dest.x,dest.z),w-.95)
	floor_y=lerpf(floor_y,floor_target,1-exp(-dt*17.0))
	if Input.is_action_just_pressed("jump") and jump_y<=.006:vertical=4.6
	vertical-=dt*12.0;jump_y=maxf(0,jump_y+vertical*dt)
	if jump_y<=.0:vertical=0.0
	position=Vector3(dest.x,floor_y+jump_y,dest.z)
	var distance=dir.length()*speed*dt
	stride+=distance*2.3;footprint_at+=distance
	if footprint_at>1.0 and jump_y<=.05:
		footprint_at=0;right_foot=not right_foot
		coast.step_foot(position,yaw,right_foot)
		Sound.effect("wade" if depth>.12 else "step",.30)
	var bob=sin(stride)*.028*motion.length() if Voyage.opt.bob else 0.0
	cam.position.y=1.60+bob-(sin(swing*PI)*.035 if Voyage.opt.bob else 0.)
	cam.fov=lerpf(cam.fov,float(Voyage.opt.fov)+(2.0 if running and Voyage.opt.bob else 0),dt*5)
	swing=minf(1.0,swing+dt*2.1)
	var pulse=sin(swing*PI)*kick
	var distant:=.54 if model_tier<2 else .64
	hand.position=Vector3(.28+motion.x*.014,-.228+bob-pulse*.065,-distant-pulse*.12)
	hand.rotation=Vector3(.34-pulse*(.42 if not pouring else -.26),-.33,-.09-pulse*(1.12 if pouring else .18))
	if model_tier==5:
		# Carry the weight on the axle. Looking around leaves the wheels on the ground.
		hand.top_level=true
		var ahead:=Vector3(.43,0,-1.72).rotated(Vector3.UP,yaw)
		var track:=position+ahead
		hand.global_position=Vector3(track.x,maxf(S.ground(track.x,track.z),coast.water.position.y-.95)+.68,track.z)
		hand.global_rotation=Vector3(-pulse*.21,yaw,-pulse*(.74 if pouring else .09))
		hand.scale=Vector3.ONE*2.7
	elif hand.top_level:
		hand.top_level=false;hand.scale=Vector3.ONE
	if is_instance_valid(liquid):
		fill_view=move_toward(fill_view,Voyage.p.bag/Voyage.capacity(),dt*2.8)
		liquid.visible=fill_view>.008
		var d:Vector3=liquid.get_meta("size")
		var radius_ratio:=lerpf(float(liquid.get_meta("foot")),.936,sqrt(fill_view))
		liquid.scale=Vector3(d.x*radius_ratio,1,d.z*radius_ratio)
		liquid.position.y=d.y*lerpf(.12,.91,fill_view)
		turn_impulse=move_toward(turn_impulse,0.,dt*.9)
		liquid.rotation=Vector3(.024*sin(stride)*motion.length(),0,turn_impulse+.032*motion.x)
	record()

func faces_sun()->float:
	return maxf(0,-cam.global_basis.z.dot(coast.SUN.normalized()))
