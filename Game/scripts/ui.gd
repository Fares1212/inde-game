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

static var fonts:Dictionary={}
static func face(serif:=false,bold:=false)->Font:
	var k=str(serif)+str(bold)
	if fonts.has(k):return fonts[k]
	var font=SystemFont.new()
	font.font_names=PackedStringArray(["Georgia","Noto Serif","Liberation Serif"]) if serif else PackedStringArray(["Segoe UI","Noto Sans","Helvetica Neue","Arial","Liberation Sans"])
	font.font_weight=700 if bold else 400
	fonts[k]=font
	return font

static func text(parent:Node,word:String,size:=18,color:=IVORY,serif:=false,bold:=false)->Label:
	var l=Label.new()
	l.text=word;l.add_theme_font_override("font",face(serif,bold));l.add_theme_font_size_override("font_size",size);l.add_theme_color_override("font_color",color)
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

static func card(parent:Node,color:=NAVY,border:=Color("#577875"))->PanelContainer:
	var p=PanelContainer.new();p.add_theme_stylebox_override("panel",box_style(color,border))
	parent.add_child(p);return p

static func button(parent:Node,title:String,fn:Callable,primary:=false)->Button:
	var b=Button.new();b.text=title;b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	b.custom_minimum_size=Vector2(0,43)
	b.add_theme_font_size_override("font_size",17);b.add_theme_font_override("font",face(false,true))
	var normal=GOLD if primary else Color("#20484d")
	b.add_theme_stylebox_override("normal",box_style(normal,Color("#758e81") if not primary else GOLD,6))
	b.add_theme_stylebox_override("hover",box_style(Color("#f0c986") if primary else Color("#356165"),IVORY,6))
	b.add_theme_stylebox_override("pressed",box_style(Color("#9db9a7"),GOLD,6))
	b.add_theme_stylebox_override("disabled",box_style(Color("#284448"),Color("#4c6261"),6))
	var focus=box_style(Color.TRANSPARENT,GOLD,6,2);b.add_theme_stylebox_override("focus",focus)
	b.add_theme_color_override("font_color",DEEP if primary else IVORY);b.add_theme_color_override("font_hover_color",DEEP if primary else Color.WHITE)
	b.add_theme_color_override("font_focus_color",DEEP if primary else IVORY);b.add_theme_color_override("font_disabled_color",Color("#a1b2ad"))
	parent.add_child(b);b.pressed.connect(fn);return b

static func meter(parent:Node,wide_px:=148)->ProgressBar:
	var b=ProgressBar.new();b.show_percentage=false;b.max_value=1
	b.custom_minimum_size=Vector2(wide_px,7)
	var bg=box_style(Color("#45615f"),Color.TRANSPARENT,4,0)
	var fg=box_style(TEAL,Color.TRANSPARENT,4,0)
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
	slider(body,"Musique","music",0,1,.01,"%");slider(body,"Effets et vagues","effects",0,1,.01,"%");slider(body,"Voix de Bernard","voice",0,1,.01,"%")
	slider(body,"Sensibilité souris","sensitivity",.25,3,.05,"×");slider(body,"Champ de vision","fov",55,100,1,"°");slider(body,"Éblouissement","glare",0,1,.01,"%")
	pick(body,"Qualité graphique","quality",["Économe","Équilibrée","Haute"]);pick(body,"Taille de fenêtre","resolution",["960 × 540","1152 × 648","1600 × 900"])
	toggle(body,"Plein écran","fullscreen");toggle(body,"Balancement de la caméra","bob");toggle(body,"Inverser la souris verticale","invert_y");toggle(body,"Sous-titres de Bernard","subtitles")
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
