extends Node

signal changed
signal notice(message: String)
signal save_failed(message: String)

const RULES=preload("res://resources/mer.tres")
const Inventory=preload("res://scripts/item_inventory.gd")
const SAVE_NAME = "voyage"
var db: Dictionary = {}
var p: Dictionary = {}
var opt := {"music":0.58,"effects":0.8,"voice":0.8,"sensitivity":1.0,"fov":76.0,"quality":1,"glare":0.65,"bob":true,"fullscreen":false,"resolution":1,"subtitles":true,"invert_y":false,"text_speed":34.0,"text_size":21.0,"ambience":.68,"ui":.72,"bindings":{}}
var storage := "user://"
var persistent := true
var menu_fresh := false
var checkpoint := 0.0
var autosave_retry := false
var save_warning := false
var run_active := false

func _ready() -> void:
	if "--spoonful-test" in OS.get_cmdline_user_args() or "--spoonful-balance" in OS.get_cmdline_user_args():
		storage = "user://verification/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(storage))
	db = JSON.parse_string(FileAccess.get_file_as_string("res://Data/basins.json"))
	db.tools=RULES.vessels
	db.finds=RULES.items
	db.basin_units=RULES.millilitres
	db.tide_seconds=RULES.tide_seconds
	var settings: Dictionary = read_json("reglages")
	for key in opt:
		if settings.has(key) and (typeof(settings[key]) == typeof(opt[key]) or (typeof(opt[key]) in [TYPE_INT,TYPE_FLOAT] and typeof(settings[key]) in [TYPE_INT,TYPE_FLOAT])):
			opt[key] = settings[key]
	opt.music = clampf(opt.music,0,1)
	opt.effects = clampf(opt.effects,0,1)
	opt.voice = clampf(opt.voice,0,1)
	opt.sensitivity = clampf(opt.sensitivity,0.25,3.0)
	opt.fov = clampf(opt.fov,55,100)
	opt.glare = clampf(opt.glare,0.0,1.0)
	opt.quality = clampi(int(opt.quality),0,2)
	opt.resolution = clampi(int(opt.resolution),0,2)
	for act in {"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE,"use":KEY_E,"journal":KEY_J,"photo":KEY_F2,"debug_menu":KEY_F1}:
		var keys={"forward":KEY_W,"back":KEY_S,"left":KEY_A,"right":KEY_D,"sprint":KEY_SHIFT,"jump":KEY_SPACE,"use":KEY_E,"journal":KEY_J,"photo":KEY_F2,"debug_menu":KEY_F1}
		if not InputMap.has_action(act): InputMap.add_action(act)
		var key := InputEventKey.new()
		key.physical_keycode = int(opt.bindings.get(act,keys[act]))
		InputMap.action_add_event(act,key)
	for pair in [["forward",KEY_UP],["back",KEY_DOWN],["left",KEY_LEFT],["right",KEY_RIGHT]]:
		var key := InputEventKey.new()
		key.physical_keycode=pair[1]
		InputMap.action_add_event(pair[0],key)
	for pair in [["left",JOY_AXIS_LEFT_X,-1],["right",JOY_AXIS_LEFT_X,1],["forward",JOY_AXIS_LEFT_Y,-1],["back",JOY_AXIS_LEFT_Y,1],["look_left",JOY_AXIS_RIGHT_X,-1],["look_right",JOY_AXIS_RIGHT_X,1],["look_up",JOY_AXIS_RIGHT_Y,-1],["look_down",JOY_AXIS_RIGHT_Y,1]]:
		if not InputMap.has_action(pair[0]):InputMap.add_action(pair[0],.18)
		var axis:=InputEventJoypadMotion.new();axis.axis=pair[1];axis.axis_value=pair[2];InputMap.action_add_event(pair[0],axis)
	for pair in [["use",JOY_BUTTON_X],["scoop",JOY_BUTTON_RIGHT_SHOULDER],["jump",JOY_BUTTON_A],["journal",JOY_BUTTON_Y],["photo",JOY_BUTTON_BACK],["sprint",JOY_BUTTON_LEFT_SHOULDER],["ui_cancel",JOY_BUTTON_START]]:
		if not InputMap.has_action(pair[0]):InputMap.add_action(pair[0])
		var b:=InputEventJoypadButton.new();b.button_index=pair[1];InputMap.action_add_event(pair[0],b)
	apply_display(false)

func blank() -> Dictionary:
	return {"schema":2,"basin":0,"marked_find":-1,"primer":false,"walk_time":0.0,"locked":0.0,"peak":0.0,"ending":"","endings":{},"returned":false,"free":false,"earned":0,"dikes":0,"bells":0,"trip_id":str(Time.get_unix_time_from_system()),"tier":0,"coins":0,"bag":0.0,"drained":0.0,"clock":0.0,"cargo":{},"seen":{},"taken":{},"drops":0,"scoops":0,"sales":0,"finished":false,"pos":[],"yaw":0.0,"pitch":-0.11,"seed":7129,"intro_done":false,"save_time":0,"visits":0}

func new_run() -> void:
	p = blank()
	run_active = true
	checkpoint=0
	save_now()

func valid_run(d: Dictionary) -> bool:
	return int(d.get("schema",0)) in [1,2] and d.has("drained") and d.has("tier") and d.has("basin") and d.get("seen",{}) is Dictionary and d.get("taken",{}) is Dictionary and d.get("cargo",{}) is Dictionary

func decode_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var f=FileAccess.open(path,FileAccess.READ)
	if f==null: return {}
	var json=JSON.new()
	if json.parse(f.get_as_text())!=OK: return {}
	return json.data if json.data is Dictionary else {}

func read_json(stem: String) -> Dictionary:
	for ext in [".json",".bak",".tmp"]:
		var d=decode_file(storage+stem+ext)
		if not d.is_empty() and (stem!=SAVE_NAME or valid_run(d)): return d
	return {}

func has_run() -> bool:
	return not read_json(SAVE_NAME).is_empty()

func continue_run() -> bool:
	var from_disk=read_json(SAVE_NAME)
	if from_disk.is_empty(): return false
	if int(from_disk.schema)==1:
		if not write_json("voyage-v1-original",from_disk):return false
		from_disk=migrate(from_disk)
	p=blank()
	for key in p:
		if from_disk.has(key): p[key]=from_disk[key]
	p.tier=clampi(int(p.tier),0,5)
	p.basin=0
	p.peak=maxf(p.drained,p.peak)
	p.coins=maxi(0,int(p.coins))
	p.drained=clampf(float(p.drained),0.0,total())
	p.bag=clampf(float(p.bag),0.0,capacity())
	run_active=true
	return true

func write_json(stem: String,d: Dictionary) -> bool:
	var base=ProjectSettings.globalize_path(storage+stem)
	var file=FileAccess.open(base+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(d))
	file.flush()
	var err=file.get_error()
	file.close()
	if err!=OK or decode_file(base+".tmp").is_empty(): return false
	var keep=decode_file(base+".json")
	if not keep.is_empty() and (stem!=SAVE_NAME or valid_run(keep)):
		if FileAccess.file_exists(base+".bak"): DirAccess.remove_absolute(base+".bak")
		if DirAccess.rename_absolute(base+".json",base+".bak")!=OK: return false
	elif FileAccess.file_exists(base+".json"):
		if DirAccess.remove_absolute(base+".json")!=OK: return false
	return DirAccess.rename_absolute(base+".tmp",base+".json")==OK

func save_now() -> bool:
	if p.is_empty() or not persistent: return false
	p.save_time=int(Time.get_unix_time_from_system())
	var ok=write_json(SAVE_NAME,p)
	autosave_retry=not ok
	if not ok and not save_warning:
		save_warning=true
		save_failed.emit("Écriture impossible. Vérifie l’espace libre dans le dossier de sauvegarde.")
	if ok: save_warning=false
	return ok

func apply_display(resize := false) -> void:
	if DisplayServer.get_name()=="headless": return
	if opt.fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if resize:
			var sizes=[Vector2i(960,540),Vector2i(1152,648),Vector2i(1600,900)]
			var work=DisplayServer.screen_get_usable_rect().size
			DisplayServer.window_set_size(sizes[int(opt.resolution)].min(work))
	get_viewport().scaling_3d_scale=[0.72,0.9,1.0][int(opt.quality)]
	get_viewport().msaa_3d=Viewport.MSAA_2X if int(opt.quality)==2 else Viewport.MSAA_DISABLED

func apply_options(resize := false) -> void:
	write_json("reglages",opt)
	apply_display(resize)

func migrate(old:Dictionary)->Dictionary:
	var d:=blank()
	for key in ["coins","tier","clock","taken","drops","scoops","sales","pos","yaw","pitch","seed","intro_done","visits"]:
		if old.has(key):d[key]=old[key]
	var level:=clampi(int(d.tier),0,5)
	var cycle:=clampi(int(old.get("basin",0)),0,100)
	var old_capacity:float=[1.,1600.,70000.,1100000.,3600000.,9500000.][level]*pow(1.34,cycle)
	d.bag=clampf(float(old.get("bag",0))/maxf(1.,round(old_capacity)),0,1)*RULES.vessels[level].capacity
	d.drained=clampf(float(old.drained)/(1e8*pow(1.55,cycle)),0,1)*total()
	if old.get("finished",false):d.drained=total();d.tier=5
	d.peak=d.drained;d.primer=level>0 or cycle>0;d.earned=int(d.coins)
	for field in ["seen","cargo"]:
		for index in old.get(field,{}):
			if str(index).is_valid_int() and int(index)>=0 and int(index)<RULES.items.size():
				d[field][RULES.items[int(index)].id]=old[field][index]
	return d

func vessel()->VesselData:
	return RULES.vessels[int(p.tier)]

func total()->float:return RULES.millilitres
func capacity()->float:return vessel().capacity
func volume_base()->float:return p.drained

func spill(dt:float)->float:
	if p.bag<=0 or p.finished:return 0
	var lost:=minf(p.bag,p.bag*vessel().spill_rate*dt)
	p.bag-=lost
	return lost

func buy_primer()->bool:
	if p.primer or p.coins<RULES.primer_price or p.drops<5:return false
	p.coins-=RULES.primer_price;p.primer=true;save_now();changed.emit();return true

func buy_dike()->bool:
	var cost:int=RULES.dike_price*(1+int(p.dikes))
	if p.coins<cost or p.drained<=p.locked+.001:return false
	p.coins-=cost;p.locked=p.drained;p.dikes+=1;save_now();changed.emit();return true

func region() -> int:
	var i:=0
	for row in db.zones:
		if float(p.peak)+0.000001>=float(row.units): i=int(row.depth)
	return i

func tide_phase() -> float:
	return float(p.clock)*TAU/float(db.tide_seconds)+0.45

func tide() -> float:
	return sin(tide_phase())

func base_water_y() -> float:
	var i:=0
	for z in db.zones:
		if p.drained>=z.units:i=z.depth
	var a=db.zones[i]
	var b=db.zones[i+1] if i<5 else {"units":db.basin_units,"water":db.last_water}
	var t=clampf((volume_base()-float(a.units))/(float(b.units)-float(a.units)),0,1)
	return lerpf(float(a.water),float(b.water),t if i==5 else t*.72)

func water_y() -> float:
	if p.free and p.ending!="empty":
		# The returning sea uncovers the entire coast again once per promenade cycle.
		var phase:float=float(p.get("walk_time",0.))*TAU/280.
		return lerpf(float(db.last_water),3.62,(cos(phase)+1.)*.5)
	var dryness=clampf((1.0-float(p.drained)/total())*7.0,0,1)
	return base_water_y()+0.63*tide()*dryness

func tick(dt: float) -> void:
	if p.is_empty():return
	if p.finished:
		if p.free:p["walk_time"]=float(p.get("walk_time",0.))+dt
		return
	p.clock+=dt
	if not plug_ready():
		var backflow:=maxf(0,cos(tide_phase()))*float(p.drained)*RULES.return_fraction_per_second
		p.drained=clampf(p.drained+dt*(vessel().auto_rate*(1.-tide()*.3)-backflow),p.locked,total())
		p.peak=maxf(p.drained,p.peak)
	checkpoint+=dt
	if checkpoint>14.0:
		checkpoint=0
		save_now()

func scoop() -> float:
	if p.finished: return 0.0
	var amount=minf(capacity()-p.bag,minf(total()-p.drained-p.bag,vessel().scoop))
	if amount<=0: return 0.0
	p.bag+=amount
	p.scoops+=1
	changed.emit()
	return amount

func pour() -> float:
	if p.bag<=0 or p.finished: return 0.0
	var pressure:float=RULES.primer_leverage if p.tier==0 and p.primer else vessel().leverage
	var moved=minf(p.bag*pressure,total()-p.drained)
	if moved>0:
		var reward:=roundi(vessel().delivery*float(p.bag)/capacity())
		p.coins+=reward;p.earned+=reward
		p.drained=minf(total(),p.drained+moved)
		p.peak=maxf(p.peak,p.drained)
		p.drops+=1
	p.bag=0.0
	save_now()
	changed.emit()
	return moved

func collect(id: int,kind: int) -> bool:
	if kind<0 or kind>=RULES.items.size() or (kind==16 and p.seen.has("find_16")) or not Inventory.take(p,id,RULES.items[kind]):return false
	if int(p.marked_find)==id:p.marked_find=-1
	save_now();changed.emit();return true

func cargo_value()->int:return Inventory.sale_value(p.cargo,RULES.items)

func sell() -> int:
	var value=cargo_value()
	if value<=0: return 0
	p.coins+=value;p.earned+=value
	p.sales+=1
	var keepsake:bool=p.cargo.has("find_16") and not p.returned
	p.cargo={"find_16":1} if keepsake else {}
	save_now()
	changed.emit()
	return value

func upgrade_status() -> String:
	if int(p.tier)>=5: return "Tous les outils sont à toi."
	var next=db.tools[int(p.tier)+1]
	if not p.primer:return "Amorce d’abord le siphon au comptoir."
	if p.peak/total()+0.000000001<float(next.gate): return "À découvrir après "+percent(float(next.gate))+" de vidange."
	if p.coins<int(next.price): return "Il manque "+str(int(next.price)-int(p.coins))+" coquilles."
	return ""

func buy() -> bool:
	if upgrade_status()!="": return false
	p.coins-=int(db.tools[int(p.tier)+1].price)
	p.tier+=1
	save_now()
	changed.emit()
	return true

func plug_ready() -> bool:
	return p.tier>=5 and p.drained>=total()-0.001

func return_key()->bool:
	if p.returned or not p.seen.has("find_16"):return false
	p.returned=true;p.cargo.erase("find_16");save_now();changed.emit();return true

func can_home()->bool:return p.returned and p.seen.size()==RULES.items.size()

func choose_ending(which:String)->bool:
	if not plug_ready() or p.finished or which not in ["tide","empty","home"] or (which=="home" and not can_home()):return false
	if not write_json("dernier-rivage",p):return false
	p.ending=which;p.finished=true;p.free=false;p.endings[which]=true;p.bag=0
	save_now();changed.emit();return true

func rewind()->bool:
	var last:=read_json("dernier-rivage")
	if last.is_empty() or last.get("trip_id","")!=p.trip_id:return false
	var endings:Dictionary=p.endings.duplicate()
	p=last;p.endings=endings;p.finished=false;p.free=false;p.ending="";save_now();return true

func percent(ratio:float)->String:
	if ratio>0 and ratio<.00001:return "< 0,001 %"
	var fmt:="%.3f" if ratio<.001 and ratio>0 else "%.2f"
	return (fmt%(ratio*100.)).replace(".",",")+" %"

func number(value:float)->String:
	var s:=str(roundi(value))
	var i:=s.length()-3
	while i>0:s=s.insert(i," ");i-=3
	return s

func volume(ml:float)->String:
	if ml<1000.:return number(ml)+" mL"
	if ml<1000000.:return ("%.2f"%(ml/1000.)).trim_suffix("0").trim_suffix("0").trim_suffix(".").replace(".",",")+" L"
	return ("%.2f"%(ml/1000000.)).replace(".",",")+" m³"

func rebind(action:String,code:int)->void:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:InputMap.action_erase_event(action,event)
	var key:=InputEventKey.new();key.physical_keycode=code;InputMap.action_add_event(action,key)
	opt.bindings[action]=code;apply_options()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and run_active: save_now()

func photo_folder()->String:
	var path=ProjectSettings.globalize_path(storage+"Photos/")
	DirAccess.make_dir_recursive_absolute(path)
	return path
