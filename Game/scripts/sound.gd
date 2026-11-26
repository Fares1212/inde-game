extends Node

var samples:Dictionary={}
var effects:Array=[]
var slots:=0
var song:AudioStreamPlayer
var sea:AudioStreamPlayer
var speech:AudioStreamPlayer
var rng=RandomNumberGenerator.new()
var muted_test:=false

func _ready()->void:
	rng.seed=89573
	muted_test=DisplayServer.get_name()=="headless"
	for name in ["Music","SFX","Voice","Ambience"]:
		if AudioServer.get_bus_index(name)<0:AudioServer.add_bus();AudioServer.set_bus_name(AudioServer.bus_count-1,name)
	for j in 10:
		var player=AudioStreamPlayer.new();add_child(player);player.bus="SFX";effects.append(player)
	song=AudioStreamPlayer.new();song.bus="Music";add_child(song)
	sea=AudioStreamPlayer.new();sea.bus="Ambience";add_child(sea)
	speech=AudioStreamPlayer.new();speech.bus="Voice";add_child(speech)
	for k in ["theme","surf","scoop0","scoop1","scoop2","scoop3","pour0","pour1","step0","step1","step2","wade0","wade1","coin0","coin1","buy0","reveal0","creak0","plug0","click0"]:
		var path="res://audio/generated/"+k+".ogg"
		if ResourceLoader.exists(path):samples[k]=load(path)
	for k in Voyage.db.voices:
		var path="res://audio/generated/vo_"+str(k)+".ogg"
		if ResourceLoader.exists(path):samples["vo_"+k]=load(path)
	apply_settings()

func apply_settings()->void:
	if not is_instance_valid(song):return
	for k in {"Music":"music","SFX":"effects","Voice":"voice","Ambience":"effects"}:
		var bus=AudioServer.get_bus_index(k)
		var opt_key={"Music":"music","SFX":"effects","Voice":"voice","Ambience":"effects"}[k]
		var vol=float(Voyage.opt[opt_key])
		AudioServer.set_bus_mute(bus,vol<=.005)
		AudioServer.set_bus_volume_db(bus,linear_to_db(maxf(.0001,vol)))

func music(menu:bool)->void:
	if muted_test:return
	for entry in [[song,"theme",-5.0 if menu else -13.0],[sea,"surf",-15.0 if menu else -6.0]]:
		var player:AudioStreamPlayer=entry[0];player.volume_db=entry[2]
		if samples.has(entry[1]) and not player.playing:
			var stream=samples[entry[1]]
			stream.loop=true;player.stream=stream;player.play()

func effect(which:String,level:=1.0)->void:
	if muted_test:return
	var n={"step":3,"wade":2,"scoop":4,"pour":2,"coin":2}.get(which,1)
	var k=which+str(rng.randi_range(0,n-1))
	if not samples.has(k):return
	var player:AudioStreamPlayer=effects[slots];slots=(slots+1)%effects.size()
	player.stream=samples[k];player.pitch_scale=rng.randf_range(.92,1.08);player.volume_db=linear_to_db(level*rng.randf_range(.87,1.0));player.play()

func voice(k:String)->void:
	if muted_test or float(Voyage.opt.voice)<.005:return
	if samples.has("vo_"+k):
		speech.stop();speech.stream=samples["vo_"+k];speech.play()

func stop_all()->void:
	for player in effects+[song,sea,speech]:
		if is_instance_valid(player):
			player.stop()
			player.stream=null
	samples.clear()

func _exit_tree()->void:
	stop_all()
