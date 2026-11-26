extends Node

signal changed
signal notice(message: String)
signal save_failed(message: String)

const SAVE_NAME = "voyage"
var db: Dictionary = {}
var p: Dictionary = {}
var opt := {"music":0.58,"effects":0.8,"voice":0.8,"sensitivity":1.0,"fov":76.0,"quality":1,"glare":0.65,"bob":true,"fullscreen":false,"resolution":1,"subtitles":true,"invert_y":false}
var storage := "user://"
var persistent := true
var menu_fresh := false
var checkpoint := 0.0
var autosave_retry := false
var save_warning := false
var run_active := false

func _ready() -> void:
	if "--spoonful-test" in OS.get_cmdline_user_args():
		storage = "user://verification/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(storage))
	db = JSON.parse_string(FileAccess.get_file_as_string("res://Data/basins.json"))
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
		key.physical_keycode = keys[act]
		InputMap.action_add_event(act,key)
	for pair in [["forward",KEY_UP],["back",KEY_DOWN],["left",KEY_LEFT],["right",KEY_RIGHT]]:
		var key := InputEventKey.new()
		key.physical_keycode=pair[1]
		InputMap.action_add_event(pair[0],key)
	apply_display(false)

func blank(cycle := 0) -> Dictionary:
	return {"schema":1,"basin":cycle,"tier":0,"coins":0,"bag":0.0,"drained":0.0,"clock":0.0,"cargo":{},"seen":{},"taken":{},"drops":0,"scoops":0,"sales":0,"finished":false,"pos":[],"yaw":0.0,"pitch":-0.11,"seed":7129+cycle*1187,"intro_done":false,"save_time":0,"visits":0}

func new_run() -> void:
	p = blank()
	run_active = true
	checkpoint=0
	save_now()

func valid_run(d: Dictionary) -> bool:
	return int(d.get("schema",0))==1 and d.has("drained") and d.has("tier") and d.has("basin") and d.get("seen",{}) is Dictionary and d.get("taken",{}) is Dictionary and d.get("cargo",{}) is Dictionary

func decode_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var f=FileAccess.open(path,FileAccess.READ)
	if f==null: return {}
	var raw=JSON.parse_string(f.get_as_text())
	return raw if raw is Dictionary else {}

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
	p=blank()
	for key in p:
		if from_disk.has(key): p[key]=from_disk[key]
	p.tier=clampi(int(p.tier),0,5)
	p.basin=clampi(int(p.basin),0,100)
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
	get_viewport().screen_space_aa=Viewport.SCREEN_SPACE_AA_DISABLED if int(opt.quality)==0 else Viewport.SCREEN_SPACE_AA_FXAA

func apply_options(resize := false) -> void:
	write_json("reglages",opt)
	apply_display(resize)

func total() -> float:
	return float(db.basin_units)*pow(float(db.prestige_growth),int(p.basin))

func power_bonus() -> float:
	return pow(float(db.prestige_capacity)+1.0,int(p.basin))

func capacity() -> float:
	return maxf(1.0,round(float(db.tools[int(p.tier)].capacity)*power_bonus()))

func volume_base() -> float:
	return float(p.drained)*float(db.basin_units)/total()

func region() -> int:
	var i:=0
	for row in db.zones:
		if volume_base()+0.000001>=float(row.units): i=int(row.depth)
	return i

func tide_phase() -> float:
	return float(p.clock)*TAU/float(db.tide_seconds)+0.45

func tide() -> float:
	return sin(tide_phase())

func base_water_y() -> float:
	var i=region()
	var a=db.zones[i]
	var b=db.zones[i+1] if i<5 else {"units":db.basin_units,"water":db.last_water}
	var t=clampf((volume_base()-float(a.units))/(float(b.units)-float(a.units)),0,1)
	return lerpf(float(a.water),float(b.water),t)

func water_y() -> float:
	var dryness=clampf((1.0-float(p.drained)/total())*7.0,0,1)
	return base_water_y()+0.63*tide()*dryness

func tick(dt: float) -> void:
	if p.is_empty() or p.finished: return
	p.clock+=dt
	if int(p.tier)>=4:
		p.drained=minf(total(),p.drained+dt*float(db.tools[int(p.tier)].auto_rate)*power_bonus()*(1.05-0.30*tide()))
	checkpoint+=dt
	if checkpoint>14.0:
		checkpoint=0
		save_now()

func scoop() -> float:
	if p.finished: return 0.0
	var amount=minf(capacity()-p.bag,minf(total()-p.drained-p.bag,round(float(db.tools[int(p.tier)].scoop)*power_bonus())))
	if amount<=0: return 0.0
	p.bag+=amount
	p.scoops+=1
	changed.emit()
	return amount

func pour() -> float:
	if p.bag<=0 or p.finished: return 0.0
	var moved=minf(p.bag,total()-p.drained)
	if moved>0:
		p.coins+=maxi(1,int(round(float(db.tools[int(p.tier)].delivery)*moved/capacity())))
		p.drained=minf(total(),p.drained+moved)
		p.drops+=1
	p.bag=0.0
	save_now()
	changed.emit()
	return moved

func collect(id: int,kind: int) -> bool:
	var k=str(kind)
	if p.taken.has(str(id)) or kind<0 or kind>=db.finds.size(): return false
	p.taken[str(id)]=true
	p.seen[k]=true
	p.cargo[k]=int(p.cargo.get(k,0))+1
	save_now()
	changed.emit()
	return true

func cargo_value() -> int:
	var value:=0
	for k in p.cargo:
		if str(k).is_valid_int() and int(k)>=0 and int(k)<db.finds.size(): value+=int(db.finds[int(k)].value)*int(p.cargo[k])
	return value

func sell() -> int:
	var value=cargo_value()
	if value<=0: return 0
	p.coins+=value
	p.sales+=1
	p.cargo={}
	save_now()
	changed.emit()
	return value

func upgrade_status() -> String:
	if int(p.tier)>=5: return "Tous les outils sont à toi."
	var next=db.tools[int(p.tier)+1]
	if volume_base()+0.00001<float(next.gate): return "À découvrir après "+percent(float(next.gate)/float(db.basin_units))+" de vidange."
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

func open_plug() -> bool:
	if not plug_ready() or p.finished: return false
	p.finished=true
	p.bag=0.0
	save_now()
	changed.emit()
	return true

func prestige() -> bool:
	if not p.finished: return false
	var seen: Dictionary=p.seen.duplicate(true)
	var basin=int(p.basin)+1
	p=blank(basin)
	p.seen=seen
	p.intro_done=true
	save_now()
	changed.emit()
	return true

func percent(ratio: float) -> String:
	var n=clampf(ratio,0,1)*100.0
	var s=("%.6f"%n) if n>0 and n<0.01 else ("%.2f"%n)
	return s.replace(".",",")+" %"

func number(value: float) -> String:
	if value>=1000000: return ("%.2f M"%(value/1000000.0)).replace(".",",")
	if value>=1000: return ("%.1f k"%(value/1000.0)).replace(".",",")
	return str(int(round(value)))

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and run_active: save_now()
