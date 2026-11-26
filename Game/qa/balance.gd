extends Node
const S=preload("res://scripts/shore.gd")
const Coast=preload("res://scripts/coast.gd")
var report:Dictionary={}

func _ready()->void:
	call_deferred("run")

func simulate(casual:bool)->Dictionary:
	Voyage.p=Voyage.blank();Voyage.persistent=false
	var elapsed:=0.;var trip:=0;var milestones:Dictionary={};var economy:Array=[]
	var goals:Array[float]=[.01,.1,.5,1.]
	var taps:=0
	while elapsed<36000 and not Voyage.plug_ready():
		var v:=Voyage.vessel()
		var region:=Voyage.region()
		# Shortest radial walk from the available pier to the scoopable surface.
		var port:Vector2=Coast.PORTS[region]
		var angle:=port.normalized()
		var r:=port.length()
		while r>0 and S.ground(angle.x*r,angle.y*r)>Voyage.water_y()+.1:r-=.5
		var one_way:=maxf(1.,port.length()-r-3.3)
		var trip_time:=one_way*(1./4.55+1./(4.55*(1.-v.slowdown)))+ceilf(v.capacity/v.scoop)*v.stroke_seconds+.85
		trip_time+=4.5
		if casual:trip_time*=1.58 if Voyage.p.peak/Voyage.total()<.01 else (2.05 if Voyage.p.peak/Voyage.total()<.10 else 2.55)
		if casual:trip_time+=1.0
		var time_left:=trip_time
		while time_left>.001:
			var dt:=minf(2.,time_left);Voyage.tick(dt);time_left-=dt
		elapsed+=trip_time;trip+=1
		while Voyage.p.bag<Voyage.capacity()-.0001 and Voyage.scoop()>0:taps+=1
		Voyage.pour()
		if not Voyage.p.primer and Voyage.buy_primer():milestones["amorce"]=roundi(elapsed)
		if Voyage.buy():milestones["outil_"+str(Voyage.p.tier)]=roundi(elapsed)
		for goal in goals:
			var key:=str(roundi(goal*100))+"%"
			if not milestones.has(key) and Voyage.p.peak/Voyage.total()+.0000001>=goal:
				milestones[key]=roundi(elapsed);economy.append({"jalon":key,"gagne":Voyage.p.earned,"solde":Voyage.p.coins})
	return {"secondes":roundi(elapsed),"jalons":milestones,"coquilles":economy,"livraisons":trip}

func run()->void:
	report["optimal"]=simulate(false);report["exploration"]=simulate(true)
	print("SPOONFUL_BALANCE ",JSON.stringify(report))
	get_tree().quit(0 if report.optimal.jalons.has("100%") and report.exploration.jalons.has("100%") else 1)
