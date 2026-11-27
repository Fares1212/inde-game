extends RefCounted
const UI=preload("res://scripts/ui.gd")
const INK=Color("#243e3d")
const SEA=Color("#295f59")
const CREAM=Color("#fbefcf")
const MUTED=Color("#695941")
const RUST=Color("#9a472f")

static func surface(parent:Control,bg:Color,border:Color,pad:=12)->PanelContainer:
	var pane:=PanelContainer.new();parent.add_child(pane)
	var style:=UI.box_style(bg,border,5,1)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]:style.set_content_margin(side,pad)
	pane.add_theme_stylebox_override("panel",style)
	return pane

static func words(parent:Control,value:String,size:int,ink:Color,display:=false)->Label:
	var label:=UI.text(parent,value,size,UI.IVORY,display,display)
	label.add_theme_color_override("font_color",ink)
	return label

static func page(parent:Control,coins:String)->Dictionary:
	var shade:=ColorRect.new();shade.color=Color(.05,.10,.105,.74);parent.add_child(shade);UI.wide(shade)
	var paper:=surface(shade,Color("#f5e6c6"),Color("#b49b71"),17)
	paper.theme=UI.THEME
	paper.set_anchors_and_offsets_preset(Control.PRESET_CENTER);UI.pad(paper,-437,-294,437,294)
	var page_box:=UI.vbox(paper,8)
	var header:=UI.hbox(page_box,12)
	var seal:=TextureRect.new();seal.texture=preload("res://art/ui/bernard.svg")
	seal.custom_minimum_size=Vector2(46,46);seal.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;seal.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;header.add_child(seal)
	var nameplate:=words(header,"Chez Bernard",35,INK,true);nameplate.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var purse:=surface(header,SEA,SEA,9)
	words(purse,coins+" coquilles",20,CREAM,true)
	var strip:=ColorRect.new();strip.color=Color("#ba8854");strip.custom_minimum_size.y=2;page_box.add_child(strip)
	var tabs:=UI.hbox(page_box,8)
	var body:=UI.vbox(page_box,7);body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var footer:=UI.hbox(page_box,12)
	return {"root":shade,"tabs":tabs,"body":body,"footer":footer}

static func tile(grid:GridContainer,v:VesselData,i:int,state:String,purchasable:bool,hint:String,action:Callable)->Button:
	var pane:=surface(grid,Color("#fff4d9") if state!="Locked" else Color("#eadebd"),Color("#b5a480"),6)
	pane.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var stack:=UI.vbox(pane,2)
	var plate:=TextureRect.new()
	plate.texture=UI.atlas_tile(preload("res://art/market/outils.png"),i,3,280)
	plate.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plate.custom_minimum_size=Vector2(0,101);stack.add_child(plate)
	if state=="Locked":plate.modulate=Color(.92,.90,.84)
	var title:=words(stack,v.title,19,INK,true);title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var line:=UI.hbox(stack,8)
	var cap:=words(line,Voyage.volume(v.capacity),16,MUTED);cap.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var tag:=Button.new();tag.name="Tool%d"%i;tag.text=state;tag.tooltip_text=hint
	tag.custom_minimum_size=Vector2(96,32);tag.focus_mode=Control.FOCUS_ALL
	var color:=SEA if purchasable else (RUST if state.ends_with("coq.") else Color("#6c604e"))
	for style in ["normal","hover","pressed","disabled"]:
		var tint:=color.lightened(.10) if style=="hover" else color
		tag.add_theme_stylebox_override(style,UI.box_style(tint,tint,4,0))
	for style in ["font_color","font_hover_color","font_disabled_color","font_pressed_color"]:tag.add_theme_color_override(style,CREAM)
	tag.add_theme_font_size_override("font_size",15)
	tag.disabled=not purchasable
	line.add_child(tag);tag.pressed.connect(action)
	return tag
