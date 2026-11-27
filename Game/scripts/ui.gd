extends RefCounted

const NAVY=Color("#12393f")
const DEEP=Color("#0e2c31")
const TEAL=Color("#70b8aa")
const IVORY=Color("#f6edcf")
const PALE=Color("#bcd4c6")
const GOLD=Color("#e8b768")
const RED=Color("#e69570")

static func pad(node:Control,left:int,top:int,right:int,bottom:int)->void:
	node.offset_left=left;node.offset_top=top;node.offset_right=right;node.offset_bottom=bottom

static func wide(node:Control)->void:
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

static func box_style(bg:Color,edge:Color=Color.TRANSPARENT,corner:=8,border:=1)->StyleBoxFlat:
	var s=StyleBoxFlat.new()
	s.bg_color=bg;s.border_color=edge;s.set_border_width_all(border);s.set_corner_radius_all(corner)
	s.content_margin_left=14;s.content_margin_right=14;s.content_margin_top=9;s.content_margin_bottom=9
	return s

const THEME=preload("res://resources/coast_theme.tres")
const INK=Color("#283d3c")
const PAPER=Color("#f6e5c5")

static func face(serif:=false,bold:=false)->Font:
	if serif:return preload("res://fonts/display-bold.tres") if bold else preload("res://fonts/display.tres")
	return preload("res://fonts/body-bold.tres") if bold else preload("res://fonts/body.tres")

static func text(parent:Node,word:String,size:=18,color:=IVORY,serif:=false,bold:=false)->Label:
	var l=Label.new()
	l.text=word;l.add_theme_font_override("font",face(serif,bold));l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",INK if color in [IVORY,PALE] else (Color("#8d492b") if color==GOLD else color))
	l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

static func copy(parent:Node,word:String,size:=18,color:=PALE)->Label:
	var l=text(parent,word,size,color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return l

static func vbox(parent:Node,spacing:=8)->VBoxContainer:
	var v=VBoxContainer.new();v.add_theme_constant_override("separation",spacing)
	parent.add_child(v);return v

static func hbox(parent:Node,spacing:=10)->HBoxContainer:
	var h=HBoxContainer.new();h.add_theme_constant_override("separation",spacing)
	parent.add_child(h);return h

static func card(parent:Node,_color:=NAVY,_border:=Color.TRANSPARENT)->PanelContainer:
	var p:=PanelContainer.new();p.theme=THEME;parent.add_child(p);return p

static func button(parent:Node,word:String,action:Callable,primary:=false)->Button:
	var b:=Button.new();b.text=word;b.custom_minimum_size.y=40
	b.add_theme_stylebox_override("normal",THEME.get_stylebox("pressed" if primary else "normal","Button"))
	b.add_theme_color_override("font_color",PAPER);b.add_theme_color_override("font_disabled_color",Color("#655d50"))
	var focus:=StyleBoxFlat.new();focus.draw_center=false;focus.border_color=Color("#f8bb49");focus.set_border_width_all(3)
	b.add_theme_stylebox_override("focus",focus);parent.add_child(b)
	b.pressed.connect(func():Sound.effect("click",.55);action.call());return b

static func meter(parent:Node,wide_px:=148)->ProgressBar:
	var b=ProgressBar.new();b.show_percentage=false;b.max_value=1
	b.custom_minimum_size=Vector2(wide_px,7)
	var bg=box_style(Color("#d5c7a9"),Color("#a69b80"),3,1)
	var fg=box_style(Color("#34736d"),Color.TRANSPARENT,3,0)
	for s in [bg,fg]:
		s.content_margin_left=0;s.content_margin_top=0;s.content_margin_right=0;s.content_margin_bottom=0
	b.add_theme_stylebox_override("background",bg);b.add_theme_stylebox_override("fill",fg)
	parent.add_child(b);return b

static func modal(parent:Control,title:String,eyebrow:String,w:=620,h:=555)->Dictionary:
	var scrim=ColorRect.new();scrim.color=Color(0.02,.09,.10,.73);parent.add_child(scrim);wide(scrim)
	var panel=card(scrim,Color("#173c40"),Color("#91aaa0"));panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pad(panel,-w/2,-h/2,w/2,h/2)
	var margin=MarginContainer.new();panel.add_child(margin)
	for side in ["left","right","top","bottom"]:margin.add_theme_constant_override("margin_"+side,12)
	var body=vbox(margin,8)
	text(body,eyebrow.to_upper(),12,GOLD,false,true)
	text(body,title,33,IVORY,true,true)
	var line=HSeparator.new();body.add_child(line)
	var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var inside=vbox(scroll,9);inside.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return {"root":scrim,"body":inside,"footer":hbox(body,8)}

static func slider(parent:Node,label:String,key:String,low:float,high:float,step:float,suffix:String)->void:
	var row=hbox(parent)
	var t=text(row,label,16,IVORY);t.custom_minimum_size.x=190
	var bar=HSlider.new();bar.min_value=low;bar.max_value=high;bar.step=step
	bar.value=Voyage.opt[key];bar.size_flags_horizontal=Control.SIZE_EXPAND_FILL;row.add_child(bar)
	var v=text(row,"",15,GOLD);v.custom_minimum_size.x=56
	var format_value=func(x):return str(roundi(float(x)*100))+" %" if suffix=="%" else (("%.2f"%x).replace(".",",")+suffix)
	v.text=format_value.call(bar.value)
	bar.value_changed.connect(func(x):Voyage.opt[key]=x;v.text=format_value.call(x);Sound.apply_settings())

static func toggle(parent:Node,label:String,key:String)->void:
	var c=CheckBox.new();c.text=label;c.button_pressed=Voyage.opt[key];c.add_theme_font_size_override("font_size",16);parent.add_child(c)
	c.toggled.connect(func(on):Voyage.opt[key]=on)

static func pick(parent:Node,title:String,key:String,choices:Array)->void:
	var row=hbox(parent)
	var t=text(row,title,16,IVORY);t.custom_minimum_size.x=190
	var p=OptionButton.new();p.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for choice in choices:p.add_item(choice)
	p.select(int(Voyage.opt[key]));row.add_child(p);p.item_selected.connect(func(i):Voyage.opt[key]=i)

static func options(parent:Control,back:Callable)->ColorRect:
	var m=modal(parent,"Réglages","SPOONFUL",665,640)
	var body=m.body
	slider(body,"Musique","music",0,1,.01,"%");slider(body,"Bruitages","effects",0,1,.01,"%");slider(body,"Voix de Bernard","voice",0,1,.01,"%")
	slider(body,"Ressac","ambience",0,1,.01,"%");slider(body,"Interface","ui",0,1,.01,"%")
	slider(body,"Débit du texte","text_speed",15,68,1," car/s");slider(body,"Sous-titres","text_size",18,30,1," px")
	slider(body,"Sensibilité souris","sensitivity",.25,3,.05,"×");slider(body,"Champ de vision","fov",55,100,1,"°");slider(body,"Éblouissement","glare",0,1,.01,"%")
	pick(body,"Qualité graphique","quality",["Économe","Équilibrée","Haute"]);pick(body,"Taille de fenêtre","resolution",["960 × 540","1152 × 648","1600 × 900"])
	toggle(body,"Plein écran","fullscreen");toggle(body,"Balancement de la caméra","bob");toggle(body,"Inverser la souris verticale","invert_y");toggle(body,"Sous-titres de Bernard","subtitles")
	for action in ["forward","back","left","right","use","journal","jump","photo"]:
		var caption:String={"forward":"Avancer","back":"Reculer","left":"Gauche","right":"Droite","use":"Interagir","journal":"Carnet","jump":"Sauter","photo":"Photo"}[action]
		var input:=Binding.new();input.action=action;input.caption=caption;body.add_child(input)
	var done=button(m.footer,"Enregistrer et revenir",func():Voyage.apply_options(true);Sound.apply_settings();back.call(),true)
	done.grab_focus()
	return m.root

static func album(parent:Control,back:Callable)->Control:
	var m=modal(parent,"L’album de la côte","Cartes postales",800,630)
	var path=Voyage.photo_folder()
	var entries=DirAccess.get_files_at(path)
	var photos=[]
	for entry in entries:
		if entry.get_extension().to_lower()=="png":photos.append(entry)
	photos.sort()
	photos.reverse()
	if photos.is_empty():
		copy(m.body,"Le premier plic, les épaves et le tourbillon laissent chacun une carte ici. Tu peux aussi prendre tes propres photos avec F12.",20)
	else:
		var picture=TextureRect.new()
		picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.custom_minimum_size=Vector2(500,300)
		m.body.add_child(picture)
		var label=text(m.body,"",17,GOLD)
		var cursor={"i":0}
		var show_image=func(change:int):
			cursor.i=posmod(int(cursor.i)+change,photos.size())
			var filename=str(photos[int(cursor.i)])
			var img=Image.load_from_file(path.path_join(filename))
			if img and not img.is_empty():picture.texture=ImageTexture.create_from_image(img)
			label.text=filename.get_basename().replace("-"," ")+"    ·    "+str(int(cursor.i)+1)+" / "+str(photos.size())
		show_image.call(0)
		if photos.size()>1:
			var nav=hbox(m.body,10)
			button(nav,"Précédente",show_image.bind(1));button(nav,"Suivante",show_image.bind(-1))
	button(m.footer,"Ouvrir le dossier",func():OS.shell_open(path))
	button(m.footer,"Retour",back,true).grab_focus()
	return m.root

class Binding extends Button:
	var action:String
	var caption:String
	var listening:=false
	func _ready()->void:
		refresh();pressed.connect(func():listening=true;text="Appuie sur une touche…")
	func refresh()->void:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:text=caption+"   ·   "+OS.get_keycode_string(ev.physical_keycode if DisplayServer.get_name()=="headless" else DisplayServer.keyboard_get_keycode_from_physical(ev.physical_keycode));return
	func _input(ev:InputEvent)->void:
		if listening and ev is InputEventKey and ev.pressed and not ev.echo:
			listening=false;get_viewport().set_input_as_handled()
			if ev.physical_keycode!=KEY_ESCAPE:Voyage.rebind(action,ev.physical_keycode)
			refresh()

static func atlas_tile(sheet:Texture2D,index:int,columns:int,tile_size:int)->AtlasTexture:
	var tile:=AtlasTexture.new();tile.atlas=sheet
	tile.region=Rect2((index%columns)*tile_size,floori(float(index)/columns)*tile_size,tile_size,tile_size)
	tile.filter_clip=true
	return tile
