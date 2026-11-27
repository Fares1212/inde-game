extends Node3D

const F=preload("res://scripts/forms.gd")
const Craft=preload("res://scripts/shorecraft.gd")
const V=preload("res://scripts/vessels.gd")
const STONE=Color("#ad9d83")
const BRASS=Color("#cc915a")
const IRON=Color("#37595b")
const FLOW=Color("#63cbd0")
const WOOD=Color("#8a5e40")
var wheel:Node3D
var ribbon:MeshInstance3D
var bed:MeshInstance3D
var fall:MeshInstance3D
var current:=0.0
var elapsed:=0.0

static func beam(n:Node3D,a:Vector3,b:Vector3,w:float,h:float,c:Color)->void:
	var timber:=Craft.plank(n,(a+b)*.5,Vector3(w,h,a.distance_to(b)),c)
	timber.look_at(timber.global_position+(b-a).normalized(),Vector3.UP)

static func intake(n:Node3D,at:Vector3)->void:
	# A perforated copper strainer and a flared hollow lip leave the outlet visible.
	var collar:=F.root(n,at)
	for i in 20:
		var a:=TAU*i/20.;var b:=TAU*(i+1)/20.
		var top:=Vector3(cos(a)*.43,0,sin(a)*.43)
		var next:=Vector3(cos(b)*.43,0,sin(b)*.43)
		var foot:=Vector3(cos(a)*.16,-.28,sin(a)*.16)
		var end:=Vector3(cos(b)*.16,-.28,sin(b)*.16)
		F.fabric(collar,PackedVector3Array([top,next,foot,foot,next,end]),BRASS.darkened(.18) if i%3==0 else BRASS)
	V.band(collar,.435,.435,.008,.021,IRON)
	for j in range(-2,3):
		var x:=j*.058;var z:=sqrt(.155*.155-x*x)
		F.rod(collar,Vector3(x,-.26,-z),Vector3(x,-.26,z),.019,IRON)

func build()->void:
	# The long race falls from the intake at x=0 into the walled salt pan.
	var start:=Vector3(0,1.03,0)
	var end:=Vector3(-3.46,.69,0)
	for x in [0.,-1.55,-3.18]:
		for z in [-.29,.29]:
			Craft.plank(self,Vector3(x,.35,z),Vector3(.11,.93,.11),WOOD)
		F.rod(self,Vector3(x-.24,.24,-.29),Vector3(x+.08,.74,-.29),.08,WOOD)
	beam(self,start+Vector3(0,-.13,0),end+Vector3(0,-.13,0),.67,.095,WOOD)
	for z in [-.30,.30]:
		beam(self,start+Vector3(0,-.014,z),end+Vector3(0,-.014,z),.074,.24,WOOD)
		beam(self,start+Vector3(0,.11,z),end+Vector3(0,.11,z),.08,.022,BRASS)
	for i in 5:
		var pt:=start.lerp(end,float(i)/4.)
		for z in [-.343,.343]:F.piece(self,"ball",pt+Vector3(0,.015,z),Vector3(.042,.042,.026),BRASS)
	intake(self,start+Vector3(0,.26,0))
	# The smaller intakes share this copper riser into the head of the race.
	V.tube(self,[Vector3(0,.18,0),Vector3(.34,.18,0),Vector3(.43,.30,0),Vector3(.43,1.22,0),Vector3(.35,1.37,0),Vector3(.19,1.37,0),Vector3(.14,1.31,0)],.056,BRASS)
	for level in [.36,.71,1.09]:F.piece(self,"tube",Vector3(.43,level,0),Vector3(.15,.047,.15),IRON)

	ribbon=F.piece(self,"box",start.lerp(end,.5)+Vector3(0,-.061,0),Vector3(3.5,.027,.41),FLOW,Vector3(0,0,.098))
	fall=F.piece(self,"box",Vector3(-3.5,.49,0),Vector3(.07,.43,.38),FLOW,Vector3(0,0,-.16))
	# Mortared perimeter, salt crystals and a short sluice wheel identify the saltern.
	var middle:=Vector3(-4.45,0,0)
	Craft.plank(self,middle+Vector3.UP*.17,Vector3(2.5,.26,2.02),STONE.darkened(.17))
	for side in [-1.,1.]:
		for j in 5:
			F.piece(self,"box",middle+Vector3((j-2)*.53,.37,side*.99),Vector3(.518,.38,.20),STONE.lightened(.045*(j%3)))
		for j in 4:
			F.piece(self,"box",middle+Vector3(side*1.24,.37,(j-1.5)*.46),Vector3(.18,.38,.452),STONE.darkened(.02*(j%3)))
	bed=F.piece(self,"box",middle+Vector3.UP*.315,Vector3(2.31,.025,1.79),Color("#5aa9a2"))
	for j in 13:
		var x:=sin(3.73*j)*.45;var z:=cos(2.16*j)*.63
		F.piece(self,"rock",middle+Vector3(-.62+x,.36,z),Vector3(.19+.04*(j%3),.14,.22),Color("#e9dec2"),Vector3(.17,j*.83,.09))
	var drain:=Vector3(-5.22,.323,.50)
	F.piece(self,"tube",drain,Vector3(.41,.031,.41),IRON)
	for j in range(-2,3):
		var x:=j*.051
		F.rod(self,drain+Vector3(x,.02,-.13),drain+Vector3(x,.02,.13),.020,BRASS)
	wheel=F.root(self,Vector3(-2.88,.76,.54))
	F.rod(self,Vector3(-2.88,.76,-.38),Vector3(-2.88,.76,.72),.09,IRON)
	for side in [-.10,.10]:
		F.piece(wheel,"ring",Vector3(0,0,side),Vector3(.87,.095,.87),WOOD,Vector3(PI*.5,0,0))
	for j in 10:
		var a:=TAU*j/10.
		var arm:=Vector3(cos(a),sin(a),0)
		F.rod(wheel,Vector3.ZERO,arm*.42,.042,BRASS)
		Craft.plank(wheel,arm*.43,Vector3(.145,.055,.32),WOOD.lightened(.18),Vector3(0,0,a))
	plaque(self,Vector3(-1.35,1.43,-.39))
	ribbon.hide();fall.hide()

static func plaque(parent:Node3D,p:Vector3)->void:
	for dx in [-.50,.50]:Craft.plank(parent,p+Vector3(dx,-.37,0),Vector3(.063,.75,.074),WOOD)
	F.piece(parent,"box",p,Vector3(1.70,.39,.085),IRON,Vector3(0,0,-.015))
	var nameplate:=Label3D.new();parent.add_child(nameplate)
	nameplate.position=p+Vector3(0,0,.052);nameplate.text="←  SALINES"
	nameplate.font=preload("res://fonts/display-bold.tres");nameplate.font_size=48;nameplate.pixel_size=.0043
	nameplate.modulate=Color("#fff0c4");nameplate.outline_size=0

func receive()->void:
	current=2.25

func advance(dt:float)->void:
	elapsed+=dt
	current=maxf(0.,current-dt)
	wheel.rotation.z-=dt*(3.6*minf(current,1.)+.04)
	var front:=clampf((2.25-current-.08)/.45,0.,1.)
	var tail:=clampf((.63-current)/.52,0.,1.)
	ribbon.visible=current>0. and front>tail
	ribbon.scale.x=maxf(.005,3.50*(front-tail))
	var center:float=(front+tail)*.5
	ribbon.position=Vector3(-3.46*center,.969-.34*center,0)
	fall.visible=current>.08 and current<1.69
	ribbon.scale.z=.36+.055*sin(elapsed*15.)
	bed.position.y=.315+.16*clampf(float(Voyage.p.saltwater_ml)/2400000.,0.,1.)
