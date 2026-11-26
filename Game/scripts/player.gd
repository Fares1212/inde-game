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
var fov_now:=75.0

func setup(world)->void:
	coast=world
	cam=Camera3D.new();cam.near=.055;cam.far=285;add_child(cam);cam.current=true
	hand=Node3D.new();cam.add_child(hand)
	hand.position=Vector3(.31,-.29,-.35);hand.rotation=Vector3(-.05,-.14,-.12)
	var saved=Voyage.p.pos
	if saved is Array and saved.size()==3 and absf(float(saved[0]))<=98 and absf(float(saved[2]))<=98:
		position=S.place(float(saved[0]),float(saved[2]))
		yaw=Voyage.p.yaw;pitch=clampf(float(Voyage.p.pitch),-1.4,1.42)
	else:position=S.place(0,83.2)
	floor_y=position.y
	cam.position.y=1.60
	rebuild()
	orient()
	cam.fov=Voyage.opt.fov

func rebuild()->void:
	if is_instance_valid(model):model.hide();model.queue_free()
	model=F.tool(hand,int(Voyage.p.tier));model_tier=int(Voyage.p.tier)

func orient()->void:
	rotation.y=yaw;cam.rotation.x=pitch

func mouse(delta:Vector2)->void:
	var scale_s=0.0019*float(Voyage.opt.sensitivity)
	yaw=wrapf(yaw-delta.x*scale_s,-PI,PI)
	pitch=clampf(pitch-delta.y*scale_s*(-1 if Voyage.opt.invert_y else 1),-1.45,1.45)
	orient()

func animate_action(strength:=1.0)->void:
	swing=0.0;kick=strength

func go(x:float,z:float)->void:
	position=S.place(x,z);floor_y=position.y;jump_y=0;vertical=0

func record()->void:
	if Voyage.p.is_empty():return
	Voyage.p.pos=[position.x,position.y,position.z];Voyage.p.yaw=yaw;Voyage.p.pitch=pitch

func move(dt:float)->void:
	if model_tier!=int(Voyage.p.tier):rebuild()
	var raw=Input.get_vector("left","right","forward","back")
	motion=motion.move_toward(raw,dt*8.0)
	walking=motion.length()>.13
	var dir=Vector3(motion.x,0,motion.y).rotated(Vector3.UP,yaw)
	var w=coast.water.position.y
	var depth=w-S.ground(position.x,position.z)
	var running=Input.is_action_pressed("sprint") and walking
	var speed=7.4 if running else 4.55
	if depth>.28:speed*=.78
	if Voyage.p.tier==2 and Voyage.p.bag>0:speed*=.94
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
	cam.position.y=1.60+bob
	cam.fov=lerpf(cam.fov,float(Voyage.opt.fov)+(2.0 if running and Voyage.opt.bob else 0),dt*5)
	swing=minf(1.0,swing+dt*2.1)
	var pulse=sin(swing*PI)*kick
	hand.position=Vector3(.31+cos(stride*.5)*.012*motion.length(),-.29+bob*.65-pulse*.12,-.35-pulse*.12)
	hand.rotation=Vector3(-.05-pulse*.58,-.14,-.12+pulse*.18)
	record()

func faces_sun()->float:
	return maxf(0,-cam.global_basis.z.dot(coast.SUN.normalized()))
