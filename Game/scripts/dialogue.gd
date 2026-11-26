extends Node

var speaker:AudioStreamPlayer
var lines:Array[Dictionary]=[]
var pending:String=""
var cursor:=0
var timer:=0.
var hold:=0.
var voice_tone:=0
var bank:Array[AudioStreamWAV]=[]
var box:PanelContainer
var line:Label
var layer:CanvasLayer
var sequence:=0

func _ready()->void:
	speaker=AudioStreamPlayer.new();speaker.bus="Voice";add_child(speaker)
	for mood in 3:
		for i in 5:
			var wave:=AudioStreamWAV.new();wave.format=AudioStreamWAV.FORMAT_16_BITS;wave.mix_rate=22050
			var length:=roundi(22050*(.056+mood*.012));var data:=PackedByteArray();data.resize(length*2)
			for j in length:
				var t:=float(j)/22050.;var u:=float(j)/length;var freq:float=[285.,188.,221.][mood]+i*19.
				var a:=TAU*freq*t*(1.+.085*u);var env:=sin(PI*u)*sin(PI*u)
				data.encode_s16(j*2,roundi(7800*env*(sin(a+.42*sin(2.*a))+.18*sin(a*2.03))))
			wave.data=data;bank.append(wave)
	layer=CanvasLayer.new();layer.layer=12;add_child(layer)
	box=PanelContainer.new();box.theme=load("res://resources/coast_theme.tres");layer.add_child(box);box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	box.offset_left=-348;box.offset_right=348;box.offset_top=-158;box.offset_bottom=-52
	box.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.hide()
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",14);box.add_child(row)
	var portrait:=TextureRect.new();portrait.texture=load("res://art/ui/bernard.svg");portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;portrait.custom_minimum_size=Vector2(64,64);row.add_child(portrait)
	var stack:=VBoxContainer.new();stack.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(stack)
	var nameplate:=Label.new();nameplate.text="BERNARD";nameplate.add_theme_font_override("font",load("res://fonts/display-bold.tres"));nameplate.add_theme_color_override("font_color",Color("#96502f"));stack.add_child(nameplate)
	line=Label.new();line.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;line.add_theme_color_override("font_color",Color("#24363a"));stack.add_child(line)
	set_process(false)

func say(message:String,mood:=0)->void:
	if message.is_empty():return
	if pending==message or (not lines.is_empty() and lines.back().text==message):return
	lines.append({"text":message,"tone":mood})
	if pending=="":next()

func next()->void:
	if lines.is_empty():clear();return
	var entry:Dictionary=lines.pop_front();pending=entry.text;voice_tone=entry.tone;cursor=0;hold=1.35;timer=0
	line.text=pending;line.visible_characters=0;line.add_theme_font_size_override("font_size",int(Voyage.opt.text_size))
	line.visible=Voyage.opt.subtitles;box.show();set_process(true)

func _process(dt:float)->void:
	if cursor>=pending.length():
		hold-=dt
		if hold<=0:next()
		return
	timer-=dt
	while timer<=0 and cursor<pending.length():
		var ch:=pending.substr(cursor,1);cursor+=1;line.visible_characters=cursor
		var delay:=1./maxf(12.,Voyage.opt.text_speed)
		if ch in [".","!","?","…",",",":"]:delay*=5.
		elif cursor==1 or pending.substr(cursor-2,1)==" ":
			sequence+=1;speaker.pitch_scale=.97+.018*(sequence%5);speaker.stream=bank[voice_tone*5+sequence%5];speaker.play()
			delay*=1.+.065*(sequence%3)
		timer+=delay

func skip()->void:
	if pending=="":return
	speaker.stop()
	if cursor<pending.length():cursor=pending.length();line.visible_characters=-1
	else:next()

func clear()->void:
	lines.clear();pending="";cursor=0;set_process(false)
	if is_instance_valid(speaker):speaker.stop()
	if is_instance_valid(box):box.hide()

func _input(e:InputEvent)->void:
	if pending!="" and ((e is InputEventKey and e.pressed and not e.echo and e.physical_keycode==KEY_TAB) or (e is InputEventJoypadButton and e.pressed and e.button_index==JOY_BUTTON_RIGHT_STICK)):
		skip();get_viewport().set_input_as_handled()
