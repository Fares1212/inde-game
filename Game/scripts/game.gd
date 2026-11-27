extends Node3D

const UI=preload("res://scripts/ui.gd")
const Coast=preload("res://scripts/coast.gd")
const Pilot=preload("res://scripts/player.gd")
const S=preload("res://scripts/shore.gd")
var world
var player
var canvas:CanvasLayer
var root:Control
var hud:Control
var modal:Control
var screen:=""
var glare:ColorRect
var glare_mat:ShaderMaterial
var sunlight:=0.0
var tool_name:Label
var load_label:Label
var bag_meter:ProgressBar
var water_label:Label
var zone_label:Label
var tide_label:Label
var region_meter:ProgressBar
var wallet:Label
var help:Label
var target:Label
var message:Label
var message_panel:PanelContainer
var toast_left:=0.0
var subtitle:Label
var caption_left:=0.0
var timer:=0.0
var throttle:=0.0
var was_region:=0
var big_ship:=false
var photo:=false
var finale:=-1.0
var end_cam:Camera3D
var compass:Label
var flash:ColorRect
var multiplier:=1.0
var action_target:Dictionary={}
var cheat_access:=false
var toast_layer:CanvasLayer
var playing:=false
var finale_card:=false
var shop_tab:="vessels"
var book_tab:="items"
var diagnostic:=false
var rates:Label
var story_choice:=""
var last_coins:=-1
var notified_tier:=-1

func _ready()->void:
	if Voyage.p.is_empty() and not Voyage.continue_run():Voyage.new_run()
	world=Coast.new();add_child(world);world.build()
	player=Pilot.new();add_child(player);player.setup(world)
	was_region=Voyage.region()
	make_hud()
	Voyage.changed.connect(update_hud)
	Voyage.save_failed.connect(func(msg):notify_text(msg,7.0))
	playing=true
	Sound.music(false)
	if Voyage.p.finished and not Voyage.p.free:
		finish_panel()
	elif not Voyage.p.intro_done:
		intro_panel()
	else:
		capture_mouse();update_hud()
		if Voyage.p.drops<2:notify_text("L’eau se verse au déversoir. Les objets se vendent chez Bernard.",4.0)

func capture_mouse()->void:
	if DisplayServer.get_name()!="headless":Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func make_hud()->void:
	canvas=CanvasLayer.new();add_child(canvas)
	root=Control.new();canvas.add_child(root);UI.wide(root);root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	glare=ColorRect.new();root.add_child(glare);UI.wide(glare);glare.mouse_filter=Control.MOUSE_FILTER_IGNORE
	glare_mat=ShaderMaterial.new();glare_mat.shader=preload("res://shaders/sun.gdshader");glare.material=glare_mat
	flash=ColorRect.new();root.add_child(flash);UI.wide(flash);flash.color=Color(1,.88,.59,0);flash.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud=Control.new();root.add_child(hud);UI.wide(hud);hud.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var c=UI.card(hud);c.position=Vector2(22,20)
	var vb=UI.vbox(c,2);zone_label=UI.text(vb,"Lagon",24,UI.IVORY,true,true)
	water_label=UI.text(vb,"",19,UI.PALE);region_meter=UI.meter(vb,198)
	tide_label=UI.text(vb,"",17,UI.GOLD)
	var side=UI.card(hud,Color(.05,.17,.19,.92));side.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	UI.pad(side,-247,20,-22,106);var sv=UI.vbox(side,0)
	wallet=UI.text(sv,"",21,UI.GOLD,false,true);UI.text(sv,"Carnet  J    ·    Pause  Échap",17,UI.PALE)
	compass=UI.text(hud,"",15,UI.IVORY,false,true);compass.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);UI.pad(compass,-234,23,234,49);compass.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for l in [compass]:
		l.add_theme_constant_override("outline_size",5);l.add_theme_color_override("font_outline_color",Color("#25464e"))
	var cross=UI.text(hud,"·",25,UI.IVORY,false,true);cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER);UI.pad(cross,-11,-20,11,20);cross.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	rates=UI.text(hud,"",18,UI.IVORY);rates.position=Vector2(30,162);rates.add_theme_constant_override("outline_size",4);rates.add_theme_color_override("font_outline_color",UI.PAPER);rates.hide()
	var bottom=UI.card(hud,Color(.05,.17,.19,.94));bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);UI.pad(bottom,22,-113,296,-21)
	var bv=UI.vbox(bottom,1);tool_name=UI.text(bv,"",21,UI.IVORY,true,true);load_label=UI.text(bv,"",19,UI.PALE);bag_meter=UI.meter(bv,222)
	target=UI.text(hud,"",19,UI.IVORY,false,true);target.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	UI.pad(target,-345,-129,345,-92);target.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	help=UI.text(hud,"",15,UI.IVORY);help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);UI.pad(help,-338,-67,338,-21);help.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for l in [compass,target,help,cross]:l.add_theme_color_override("font_color",UI.IVORY);l.add_theme_constant_override("outline_size",6);l.add_theme_color_override("font_outline_color",Color("#193c43"))
	toast_layer=CanvasLayer.new();toast_layer.layer=15;add_child(toast_layer)
	var notice_root:=Control.new();toast_layer.add_child(notice_root);UI.wide(notice_root);notice_root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	message_panel=PanelContainer.new();notice_root.add_child(message_panel);message_panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	message_panel.add_theme_stylebox_override("panel",UI.box_style(Color("#234642ec"),Color("#b6a078"),5,1))
	message_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT);UI.pad(message_panel,-290,-75,-18,-20)
	message=UI.text(message_panel,"",16,UI.IVORY);message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;message.add_theme_color_override("font_color",UI.PAPER);message_panel.hide()
	subtitle=UI.text(hud,"",17,UI.IVORY);subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);UI.pad(subtitle,-360,-195,360,-138);subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_constant_override("outline_size",5);subtitle.add_theme_color_override("font_outline_color",UI.DEEP)

func notify_text(s:String,seconds:=3.1)->void:
	message.text=s;message_panel.visible=not photo;toast_left=seconds

func say(k:String)->void:
	DialogueManager.say(str(Voyage.db.voices[k]),2 if k in ["empty","plug"] else 0)

func panel(kind:String,title:String,small:String,w:=620,h:=555)->Dictionary:
	if is_instance_valid(modal):modal.hide();modal.queue_free()
	screen=kind;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var m=UI.modal(root,title,small,w,h);modal=m.root;return m

func close_panel()->void:
	DialogueManager.clear()
	if is_instance_valid(modal):modal.hide();modal.queue_free()
	modal=null;screen="";cheat_access=false
	canvas.visible=true
	hud.visible=not photo
	capture_mouse();update_hud()

func intro_panel()->void:
	var m=panel("intro","Un tout petit service","Au comptoir de Bernard",615,370)
	UI.copy(m.body,"« "+str(Voyage.db.voices.intro)+" »",21,UI.IVORY)
	UI.copy(m.body,"ZQSD / WASD ou flèches pour marcher. Souris pour regarder. Clic gauche au bord de l’eau, puis E au déversoir. Maj pour courir et Espace pour sauter.",16)
	UI.button(m.footer,"Prendre la cuillère",accept_intro,true).grab_focus();say("intro")

func accept_intro()->void:
	Voyage.p.intro_done=true;Voyage.save_now();close_panel()
	notify_text("Approche la mer avec ta cuillère.",3.0)

func pause_panel()->void:
	if screen=="":player.record();Voyage.save_now()
	DialogueManager.clear()
	var m=panel("pause","Marée en pause","Journal de bord",540,540)
	UI.copy(m.body,"La crique   ·   "+str(Voyage.db.zones[Voyage.region()].title)+"  ·  "+Voyage.percent(Voyage.p.drained/Voyage.total())+" vidé.",17)
	UI.button(m.body,"Reprendre",close_panel,true).grab_focus()
	if Voyage.p.free:UI.button(m.body,"Revenir avant le dernier choix",rewind_choice)
	UI.button(m.body,"Réglages",options_panel);UI.button(m.body,"Carnet des trouvailles",book_panel);UI.button(m.body,"Commandes",controls_panel);UI.button(m.body,"Album photo",album_panel);UI.button(m.body,"Sauvegarder et revenir au port",return_menu)

func album_panel()->void:
	if is_instance_valid(modal):modal.hide();modal.queue_free()
	screen="album"
	modal=UI.album(root,pause_panel)

func controls_panel()->void:
	var m=panel("controls","Commandes","SPOONFUL",584,515)
	for row in ["ZQSD, WASD ou flèches     Marcher","Souris     Regarder","Clic gauche     Puiser ou actionner l’outil","E     Vendre, verser, ramasser ou tirer la Bonde","Maj / Espace     Courir / sauter","J     Carnet des trouvailles","F2     Menu de triche par code","F4     Mode photo libre du HUD","F12     Enregistrer une photo PNG","F3     Débits et marée","Tab / clic stick droit     Avancer le dialogue","Manette     Sticks : marche / regard, X : interagir, RB : puiser","Échap     Pause ou retour"]:
		UI.text(m.body,row,16,UI.IVORY)
	UI.button(m.footer,"Retour",pause_panel,true).grab_focus()

func options_panel()->void:
	if is_instance_valid(modal):modal.hide();modal.queue_free()
	screen="settings";modal=UI.options(root,func():world.refresh_quality();pause_panel())

func return_menu()->void:
	player.record()
	if not Voyage.save_now():notify_text("La sauvegarde a échoué. La partie reste ouverte.",5.0);return
	Voyage.run_active=false;playing=false;get_tree().change_scene_to_file("res://scenes/Menu.tscn")

func book_panel()->void:
	var m=panel("book","Carnet de la grève",str(Voyage.p.seen.size())+" / "+str(Voyage.RULES.items.size())+" trouvailles",755,596)
	var opening:=UI.hbox(m.body,18)
	var plate:=TextureRect.new()
	plate.texture=load("res://art/carnet-bernard.jpg")
	plate.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	plate.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plate.custom_minimum_size=Vector2(208,130)
	opening.add_child(plate)
	var inscription:=UI.vbox(opening,4)
	inscription.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	UI.text(inscription,"Sur la grève",27,UI.GOLD,true)
	UI.copy(inscription,"« Ce qui revient dans les filets, on le vend. Ce qui revient dans la mémoire, on le dessine. »",19)
	UI.text(inscription,"Bernard, marchand de marée",16)
	var nav=UI.hbox(m.body,8)
	UI.button(nav,"Objets",func():book_tab="items";book_panel(),book_tab=="items")
	UI.button(nav,"Récipients",func():book_tab="vessels";book_panel(),book_tab=="vessels")
	if book_tab=="vessels":
		for i in Voyage.RULES.vessels.size():
			var v:VesselData=Voyage.RULES.vessels[i]
			UI.text(m.body,("✓  " if i<=Voyage.p.tier else "○  ")+v.title,21,UI.GOLD,true)
			UI.copy(m.body,Voyage.volume(v.capacity)+"   ·   "+v.description,18)
	else:
		for r in 6:
			UI.text(m.body,Voyage.db.zones[r].title,23,UI.GOLD,true)
			for item:ItemData in Voyage.RULES.items:
				if item.region!=r:continue
				var seen:bool=Voyage.p.seen.has(item.id)
				var row=UI.hbox(m.body,8)
				var icon:=TextureRect.new();icon.texture=UI.atlas_tile(preload("res://art/market/trouvailles.png"),item.journal_id,6,160);icon.custom_minimum_size=Vector2(40,40);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
				if not seen:icon.modulate=Color("#363c3b")
				row.add_child(icon);UI.text(row,item.title+"  ·  "+item.rarity if seen else "Encore sous la marée",18)
				if seen:UI.copy(m.body,item.lore,18)
	UI.button(m.footer,"Fermer le carnet",close_panel,true).grab_focus()

func shop_panel(_greeting:=true)->void:
	DialogueManager.clear()
	if is_instance_valid(modal):modal.hide();modal.queue_free()
	screen="shop";Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;hud.hide()
	var market=preload("res://scripts/market.gd")
	var m:Dictionary=market.page(root,Voyage.number(Voyage.p.coins));modal=m.root
	var tools_tab:=UI.button(m.tabs,"Les six outils",func():shop_tab="vessels";shop_panel(false),shop_tab=="vessels")
	var goods_tab:=UI.button(m.tabs,"Trouvailles et services",func():shop_tab="objects";shop_panel(false),shop_tab=="objects")
	if shop_tab=="vessels":
		tools_tab.grab_focus()
		var grid:=GridContainer.new();grid.columns=3;grid.add_theme_constant_override("h_separation",10);grid.add_theme_constant_override("v_separation",8);m.body.add_child(grid)
		for i in Voyage.RULES.vessels.size():
			var v:VesselData=Voyage.RULES.vessels[i]
			var owned:bool=i<=int(Voyage.p.tier)
			var open:bool=i==int(Voyage.p.tier)+1 and Voyage.p.primer and Voyage.p.peak>=v.gate*Voyage.total()
			var state:="Équipé" if i==int(Voyage.p.tier) else ("Acquis" if owned else (Voyage.number(v.price)+" coq." if open else "Locked"))
			var reason:=v.description if owned else ("Siphon requis" if not Voyage.p.primer else "Outil précédent et "+Voyage.percent(v.gate)+" de mer retirée")
			if open:reason="Acheter" if Voyage.p.coins>=v.price else "Il manque "+str(v.price-Voyage.p.coins)+" coquilles"
			market.tile(grid,v,i,state,open and Voyage.p.coins>=v.price,reason,buy_vessel.bind(i))
		if not Voyage.p.primer:
			var line:=UI.hbox(m.body,12)
			var info:=UI.text(line,"Siphon  ·  %d / 5 livraisons"%mini(5,Voyage.p.drops),17);info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			var prime:=UI.button(line,"Amorcer le siphon  ·  8 coq.",func():
				if Voyage.buy_primer():Sound.effect("buy");shop_panel(false);notify_text("Siphon installé",2.))
			prime.disabled=Voyage.p.coins<Voyage.RULES.primer_price or Voyage.p.drops<5
	else:
		goods_tab.grab_focus()
		var scroll:=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;m.body.add_child(scroll)
		m.body=UI.vbox(scroll,6);m.body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var val:=Voyage.cargo_value()
		for item:ItemData in Voyage.RULES.items:
			if Voyage.p.cargo.has(item.id):UI.text(m.body,item.title+"   × "+str(Voyage.p.cargo[item.id]),18)
		var sell=UI.button(m.body,"Vendre les trouvailles  ·  "+str(val)+" coquilles",func():
			var gain:=Voyage.sell()
			if gain>0:Sound.effect("coin");shop_panel(false);notify_text("+ %d coquilles"%gain,2.)
		,true);sell.disabled=val<=0
		if Voyage.p.seen.has("find_16") and not Voyage.p.returned:
			UI.button(m.body,"Rendre la clé du logis",func():Voyage.return_key();say("home");shop_panel(false))
		var chart:Dictionary=chart_target(true)
		if not chart.is_empty() and int(Voyage.p.marked_find)<0:
			var cost:int=12+8*Voyage.region()
			var order:=UI.button(m.body,"Acheter un repère de pêche  ·  "+str(cost)+" coquilles",func():
				if int(Voyage.p.marked_find)<0 and Voyage.p.coins>=cost:
					Voyage.p.coins-=cost;Voyage.p.marked_find=int(chart.id);Voyage.save_now()
					close_panel();notify_text("Bernard a marqué une trouvaille inconnue sur ta boussole.",4.))
			order.disabled=Voyage.p.coins<cost
		var price:int=Voyage.RULES.dike_price*(1+int(Voyage.p.dikes))
		
		var d=UI.button(m.body,"Poser une digue  ·  "+str(price)+" coquilles",func():
			if Voyage.buy_dike():Sound.effect("creak");shop_panel(false);notify_text("Digue installée",2.))
		d.disabled=Voyage.p.coins<price or Voyage.p.drained<=Voyage.p.locked+.001
	UI.button(m.footer,"Retour à la plage",close_panel)

func buy_vessel(index:int)->void:
	if index!=int(Voyage.p.tier)+1 or not Voyage.buy():return
	player.rebuild();world.refresh();Sound.effect("buy");shop_panel(false)
	notify_text("Achat  ·  "+Voyage.vessel().title,2.4)

func cheats_prompt()->void:
	cheat_access=false;DialogueManager.clear()
	var m:=panel("code","Menu de triche","Accès par code",425,292)
	var field:=LineEdit.new();field.name="CheatCode";field.secret=true;field.max_length=4
	field.placeholder_text="Code à 4 chiffres";field.custom_minimum_size.y=44;m.body.add_child(field)
	var error:=UI.text(m.body,"",16,UI.GOLD)
	var unlock:=func():
		if field.text=="1201":
			cheat_access=true;debug_panel()
		else:
			error.text="Code incorrect";field.clear();field.grab_focus()
	field.text_submitted.connect(func(_v:String):unlock.call())
	UI.button(m.footer,"Ouvrir",unlock,true);UI.button(m.footer,"Retour",close_panel)
	field.grab_focus()

func debug_panel()->void:
	if not cheat_access:return
	var m=panel("debug","Menu de triche","La crique",525,520)
	UI.button(m.body,"Ajouter 100 coquilles",func():Voyage.p.coins+=100;Voyage.save_now();debug_panel())
	UI.button(m.body,"Débloquer l’outil suivant",func():
		if Voyage.p.tier<5:Voyage.p.tier+=1;Voyage.save_now();player.rebuild();world.refresh()
		debug_panel())
	UI.button(m.body,"Découvrir la zone suivante",func():
		var r=Voyage.region();Voyage.p.drained=Voyage.total()*(float(Voyage.db.zones[r+1].units)/float(Voyage.db.basin_units)) if r<5 else Voyage.total()
		Voyage.p.peak=maxf(Voyage.p.peak,Voyage.p.drained);Voyage.save_now();world.refresh();close_panel())
	UI.button(m.body,"Rejoindre Bernard",func():player.go(Coast.SHOP.x,Coast.SHOP.y+2);close_panel())
	UI.button(m.body,"Rejoindre la chaîne",func():player.go(0,2.3);close_panel())
	UI.button(m.body,"Temps ×"+("1" if multiplier>1 else "10"),func():multiplier=1.0 if multiplier>1 else 10.0;debug_panel())
	UI.button(m.body,"Prendre une photo",func():close_panel();take_photo())
	UI.button(m.footer,"Revenir au jeu",close_panel,true).grab_focus()

func chart_target(new_order:=false)->Dictionary:
	var nearest:Dictionary={}
	var distance:=INF
	for entry in world.finds:
		if not new_order:
			if entry.id==Voyage.p.marked_find:return entry
		elif entry.node.visible and not Voyage.p.seen.has(Voyage.db.finds[entry.kind].id):
			var length:float=player.position.distance_squared_to(entry.p)
			if length<distance:distance=length;nearest=entry
	return nearest

func first_port()->Vector3:
	var n=Voyage.region()
	var best=Coast.PORTS[0]
	var d=INF
	for i in n+1:
		var pp:Vector2=Coast.PORTS[i]
		var dist=pp.distance_to(Vector2(player.position.x,player.position.z))
		if dist<d:d=dist;best=pp
	return S.place(best.x,best.y,1.29 if best==Coast.DOCK else .94)

func focus()->Dictionary:
	var pos:Vector3=player.position
	var q=Vector2(pos.x,pos.z)
	var best={"key":"","dist":INF}
	var facing=-player.cam.global_basis.z
	for entry in world.finds:
		if not entry.node.visible or not world.can_take(entry):continue
		var delta=entry.p+Vector3.UP*.38-player.cam.global_position
		var dst=q.distance_to(Vector2(entry.p.x,entry.p.z))
		if dst<=2.75 and dst<best.dist and (delta.normalized().dot(facing)>.13 or dst<1.25):
			best={"key":"find","dist":dst,"entry":entry,"label":"E  ·  Ramasser "+str(Voyage.db.finds[entry.kind].title)}
	if Voyage.plug_ready() and q.length()<=4.2:return {"key":"plug","label":"E  ·  Soulever la Bonde"}
	var ds=q.distance_to(Coast.SHOP) if world.crab.visible else INF
	if ds<3.1 and (best.key=="" or ds<best.dist):return {"key":"shop","label":"E  ·  Parler à Bernard"}
	var port=first_port();var pd=q.distance_to(Vector2(port.x,port.z))
	if pd<2.85 and (Voyage.p.bag>0 or best.key==""):
		return {"key":"pour","label":"E  ·  Verser au déversoir" if Voyage.p.bag>0 else "Déversoir  ·  Récipient vide","pos":port}
	return best

func sample_water()->Vector3:
	var pos:Vector3=player.position
	var f=-player.cam.global_basis.z;var v=Vector2(f.x,f.z).normalized()
	var probe=Vector2(pos.x,pos.z)+v*1.8
	var y=world.water.position.y
	var valid=S.ground(probe.x,probe.y)<=y+.13 or S.ground(pos.x,pos.z)<=y+.08
	return Vector3(probe.x,y,probe.y) if valid else Vector3(1000,0,1000)

func do_scoop()->void:
	if throttle>0 or Voyage.p.finished:return
	var water=sample_water()
	if water.x>900:
		var use=focus()
		if use.key in ["pour","shop","find","plug"]:interact();return
		notify_text("Approche le bord de l’eau pour puiser.",1.8);return
	if Voyage.p.bag>=Voyage.capacity():
		notify_text("Récipient plein. Dépose l’eau au déversoir indiqué.",2.1);return
	var before:float=Voyage.p.drained
	var carried:=Voyage.scoop()
	if carried>0:
		if Voyage.p.drained-before>carried+.01:world.saltworks.receive()
		world.refresh();update_hud()
		player.animate_action();world.splash(water);Sound.effect("scoop")
		throttle=Voyage.vessel().stroke_seconds
		if Voyage.p.scoops==1:notify_text("Première cuillère pleine. Rejoins le déversoir.",3.6)
	elif Voyage.plug_ready():notify_text("La mer est vide. Suis la chaîne jusqu’à la Bonde.")

func interact()->void:
	if throttle>.14:return
	var dst=focus()
	match dst.key:
		"shop":shop_panel()
		"pour":
			var before_coins:int=Voyage.p.coins
			var quantity=Voyage.pour()
			if quantity>0:
				player.animate_action(1.1);world.pour_arc(player.liquid.global_position, dst.pos);world.saltworks.receive();Sound.effect("pour");throttle=.30
				if Voyage.p.drops==1:
					say("first");notify_text("Plic !  ·  5 mL aux salines",2.5)
					postcard("Premier-plic")
				else:notify_text(Voyage.volume(quantity)+" aux salines  ·  +"+str(Voyage.p.coins-before_coins)+" coq.",2.0)
			else:notify_text("Va remplir ton outil au bord de l’eau.",2.1)
		"find":
			var e=dst.entry
			var fresh=not Voyage.p.seen.has(Voyage.db.finds[e.kind].id)
			if Voyage.collect(e.id,e.kind):
				e.node.visible=false;Sound.effect("coin");player.animate_action(.35)
				notify_text(("Carnet mis à jour  ·  " if fresh else "Dans la besace  ·  ")+str(Voyage.db.finds[e.kind].title));throttle=.20
		"plug":
			if Voyage.p.finished:finish_panel()
			else:choice_panel()
		_:do_scoop_at_context()

func do_scoop_at_context()->void:
	if sample_water().x<900:do_scoop()

func heading_to(at:Vector3)->String:
	var to=Vector2(at.x-player.position.x,at.z-player.position.z)
	var a=wrapf(atan2(-to.x,-to.y)-player.yaw,-PI,PI)
	var label="DEVANT" if absf(a)<.40 else ("DERRIÈRE" if absf(a)>2.65 else ("GAUCHE" if a>0 else "DROITE"))
	return label+"  ·  "+str(roundi(to.length()))+" m"

func update_hud()->void:
	if not is_instance_valid(hud):return
	var reg=Voyage.region()
	var row=Voyage.db.zones[reg]
	zone_label.text=str(row.title)
	var frac:float=Voyage.p.drained/Voyage.total()
	water_label.text="Mer retirée   "+Voyage.percent(frac)
	if Voyage.p.free and Voyage.p.ending!="empty":
		frac=clampf((3.62-world.water.position.y)/(3.62-Voyage.db.last_water),0.,1.)
		water_label.text="Marée libre   "+Voyage.percent(1.-frac)
		frac=1.-frac
	region_meter.step=0.;region_meter.value=frac
	var t:=Voyage.tide()
	tide_label.text="↓  Basse mer" if t<-.75 else ("↑  Pleine mer" if t>.75 else ("↗  Marée montante" if cos(Voyage.tide_phase())>0 else "↘  Marée descendante"))
	wallet.text=Voyage.number(Voyage.p.coins)+" coquilles"
	if last_coins!=int(Voyage.p.coins):
		last_coins=int(Voyage.p.coins);wallet.scale=Vector2.ONE*1.07;wallet.create_tween().tween_property(wallet,"scale",Vector2.ONE,.25)
	tool_name.text=Voyage.vessel().title
	load_label.text=Voyage.volume(Voyage.p.bag)+"  /  "+Voyage.volume(Voyage.capacity())
	bag_meter.step=0.;bag_meter.value=player.fill_view
	rates.visible=diagnostic
	if diagnostic:rates.text="Siphon × %.0f   ·   Automatique %s/s   ·   Reflux %s/s   ·   Digue %s"%[Voyage.RULES.primer_leverage if Voyage.p.primer and Voyage.p.tier==0 else Voyage.vessel().leverage,Voyage.volume(Voyage.vessel().auto_rate*(1.-Voyage.tide()*.3)),Voyage.volume(maxf(0.,cos(Voyage.tide_phase()))*Voyage.p.drained*Voyage.RULES.return_fraction_per_second),Voyage.percent(Voyage.p.locked/Voyage.total())]
	action_target=focus()
	target.text=action_target.get("label","")
	if not Voyage.p.finished and target.text=="" and sample_water().x<900 and Voyage.p.bag<Voyage.capacity():target.text=("Maintenir le clic  ·  " if Voyage.p.tier>=3 else "Clic  ·  ")+str(Voyage.db.tools[int(Voyage.p.tier)].verb)
	if action_target.key!="":
		var pos:Vector3=first_port() if action_target.key=="pour" else (world.crab.global_position+Vector3.UP if action_target.key=="shop" else (action_target.entry.p+Vector3.UP*.65 if action_target.key=="find" else world.plug.global_position+Vector3.UP))
		if not player.cam.is_position_behind(pos):
			var dims:=get_viewport().get_visible_rect().size
			var pt:Vector2=player.cam.unproject_position(pos)
			target.global_position=Vector2(clampf(pt.x-target.size.x*.5,0,maxf(0,dims.x-target.size.x)),clampf(pt.y+8,110,dims.y-175))
	else:
		var dims:=get_viewport().get_visible_rect().size;target.global_position=Vector2((dims.x-target.size.x)*.5,dims.y*.62)
	if Voyage.p.free:compass.text="";help.text="Promenade libre   ·   Échap pour retrouver le dernier choix"
	elif Voyage.plug_ready():compass.text="BONDE  ·  "+heading_to(Vector3.ZERO);help.text="Rejoins le pied de la chaîne pour ouvrir la Bonde."
	elif Voyage.p.bag>0:compass.text="";help.text="Verse avec E à la goulotte des salines." if Voyage.p.drops<2 else ""
	elif (not Voyage.p.primer and Voyage.p.drops>=5 and Voyage.p.coins>=8) or (int(Voyage.p.tier)<5 and Voyage.upgrade_status()=="") or Voyage.cargo_value()>=8:
		compass.text="BERNARD  ·  "+heading_to(S.place(Coast.SHOP.x,Coast.SHOP.y));help.text="Rends visite au crabe pour vendre ou changer d’outil."
	else:
		compass.text="";help.text="Marche vers l’eau. Explore la rive à marée basse." if Voyage.p.drops<3 else ""

	if int(Voyage.p.marked_find)>=0 and Voyage.p.bag<=0 and screen=="":
		var mark:=chart_target()
		if not mark.is_empty():
			compass.text="REPÈRE DE BERNARD  ·  "+heading_to(mark.p)
			help.text="Cherche la trouvaille au pied du repère." if mark.node.visible else "Ce repère est sous l’eau. Reviens à marée basse."

func choice_panel()->void:
	if not Voyage.plug_ready():return
	var m=panel("choice","La dernière cuillère","Au pied du treuil",640,460)
	UI.copy(m.body,"Le courant s’est tu. Il reste un peu d’eau au creux de ta main. Bernard attend sur le quai.",21)
	UI.button(m.body,"Rendre l’eau à la mer",start_finale.bind("tide"),true).grab_focus()
	UI.button(m.body,"Ouvrir la Bonde",start_finale.bind("empty"))
	if Voyage.can_home():UI.button(m.body,"Rejoindre Bernard chez lui",start_finale.bind("home"))
	UI.button(m.footer,"Revenir sur la grève",close_panel)

func start_finale(which:String)->void:
	if not Voyage.choose_ending(which):return
	story_choice=which;close_panel();photo=false;hud.hide();glare.hide();player.hand.hide()
	finale=0;finale_card=false
	if which=="empty":world.start_finale();Sound.effect("plug")
	Sound.ending(which)
	world.crab.visible=which!="empty"
	end_cam=Camera3D.new();add_child(end_cam);end_cam.current=true;end_cam.fov=63
	if which=="home":
		world.crab.global_position=S.place(Coast.DOCK.x+.9,Coast.DOCK.y+.4,.3)
	set_final_camera()

func set_final_camera()->void:
	var t:=clampf(finale/12.,0,1)
	if story_choice=="empty":
		var a:=.32+t*.75;var d:=lerpf(23.,48.,t)
		end_cam.position=Vector3(sin(a)*d,lerpf(9,25,t),cos(a)*d);end_cam.look_at(Vector3(0,-8,0))
		world.sky_env.environment.adjustment_enabled=true;world.sky_env.environment.adjustment_saturation=1.-t*.86
	else:
		var home:=story_choice=="home"
		var o:Vector3=S.place(Coast.DOCK.x,Coast.DOCK.y)
		end_cam.position=o+Vector3(2.4 if home else -2.,1.36+t*.16,2.8-t*.6)
		end_cam.look_at(o+Vector3(0,.93,-1.5) if home else o+Vector3(-16,2,-42))
		world.water.position.y=lerpf(Voyage.water_y(),3.62,smoothstep(.05,.93,t));world.sea.set_shader_parameter("sea_level",world.water.position.y)
		world.sun.light_color=Color("#ffcf92").lerp(Color("#f4b080"),t)
		if home:world.crab.global_position=o+Vector3(.9,.35,.48)
	if t>.61 and notified_tier!=-9:
		notified_tier=-9;say(story_choice)

func finish_panel()->void:
	finale=-1;hud.hide();DialogueManager.clear()
	var k:String=Voyage.p.ending
	var title:String={"tide":"La Marée","empty":"Le Grand Vide","home":"La Maison"}.get(k,"Le dernier rivage")
	var m=panel("finish",title,"Générique   ·   SPOONFUL",660,538)
	UI.copy(m.body,{"tide":"La mer reprend sa place. Sur le comptoir, Bernard pose une deuxième tasse.","empty":"Le vent tourne une page du carnet. La table est mise pour une personne.","home":"La clé est dans la serrure. À côté de toi, une petite pince se repose sur le bois."}.get(k,"Le soir descend."),22)
	UI.text(m.body,"Un conte de Fares   ·   Godot 4.5.1",19,UI.GOLD,true)
	UI.copy(m.body,"%s puisages   ·   %s coquilles gagnées   ·   %d h %02d min"%[Voyage.number(Voyage.p.scoops),Voyage.number(Voyage.p.earned),int(Voyage.p.clock/3600),int(Voyage.p.clock/60)%60])
	UI.copy(m.body,"%d / %d trouvailles   ·   %d / 3 fins découvertes"%[Voyage.p.seen.size(),Voyage.RULES.items.size(),Voyage.p.endings.size()])
	if Voyage.p.endings.size()<3:UI.copy(m.body,"Certaines choses du rivage ont encore quelqu’un qui les attend.",17)
	UI.button(m.body,"Se promener sur la même côte",free_walk,true).grab_focus()
	UI.button(m.body,"Revenir avant le dernier choix",rewind_choice)
	UI.button(m.footer,"Revenir au menu",return_menu)

func free_walk()->void:
	Voyage.p.free=true;Voyage.p.pos=[];Voyage.save_now();playing=false;get_tree().reload_current_scene()

func rewind_choice()->void:
	if Voyage.rewind():playing=false;get_tree().reload_current_scene()

func postcard(moment:String,delay:=.12)->void:
	if DisplayServer.get_name()=="headless" or "--spoonful-test" in OS.get_cmdline_user_args():return
	var file=Voyage.photo_folder().path_join("Crique-%s.png"%moment)
	if FileAccess.file_exists(file):return
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(file)

func take_photo()->void:
	if DisplayServer.get_name()=="headless":return
	var old=hud.visible
	var old_toast:=toast_layer.visible;toast_layer.hide()
	hud.hide()
	await RenderingServer.frame_post_draw
	var img=get_viewport().get_texture().get_image()
	var folder=Voyage.photo_folder()
	var name="Crique-%s.png"%Time.get_datetime_string_from_system().replace(":","-")
	var ok=img.save_png(folder.path_join(name))
	hud.visible=old;toast_layer.visible=old_toast
	if ok==OK:notify_text("Photo enregistrée dans le dossier Photos de SPOONFUL.",3.0)

func _process(dt:float)->void:
	if not playing:return
	toast_left=maxf(0,toast_left-dt)
	message_panel.visible=toast_left>0 and not photo and finale<0 and screen in ["","shop"]
	throttle=maxf(0,throttle-dt);flash.color.a=move_toward(flash.color.a,0,dt*.8)
	if finale>=0:
		finale+=dt
		world.animate(dt,finale if story_choice=="empty" else -1);set_final_camera()
		if finale>5.2 and not finale_card and story_choice=="empty":
			finale_card=true;postcard("Le-tourbillon")
		if finale>=12:finish_panel()
		return
	if screen!="":
		if screen in ["intro","shop"]:world.animate(dt*.45)
		return
	world.animate(dt)
	player.move(minf(dt,.07))
	Voyage.tick(minf(dt,.18)*multiplier)
	if int(Voyage.p.tier)>=1 and (Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_action_pressed("scoop")) and throttle<=0 and Voyage.p.bag<Voyage.capacity() and sample_water().x<900:do_scoop()
	var reg=Voyage.region()
	var bell:=floori(20.*Voyage.p.peak/Voyage.total())
	if bell>int(Voyage.p.bells):
		Voyage.p.bells=bell;Sound.layer(bell);notify_text(["Au quai, le moulin fait tourner sa première roue.","Une fenêtre bleue apparaît dans les rochers.","Bernard replie une petite carte de la côte.","Une cloche répond du fond de la crique."][bell%4],4.5)
	if reg>was_region:
		was_region=reg;world.refresh();Sound.effect("reveal");flash.color.a=.21
		notify_text(str(Voyage.db.zones[reg].title)+"  ·  "+str(Voyage.db.zones[reg].mark),6.0)
		if reg==3:
			Sound.effect("creak");postcard("Les-epaves",1.3)
	timer+=dt
	if timer>.12:timer=0;update_hud()
	caption_left=maxf(0,caption_left-dt)
	if caption_left<=0:subtitle.text=""
	var look=player.faces_sun()
	var vis=smoothstep(.65,.999,look)
	sunlight=lerpf(sunlight,vis,1-exp(-dt*5))
	glare.visible=sunlight>.002 and Voyage.opt.glare>.001
	if glare.visible:
		var px=player.cam.unproject_position(player.cam.global_position+world.SUN.normalized()*70)
		var dims=get_viewport().get_visible_rect().size
		glare_mat.set_shader_parameter("sun_uv",px/dims);glare_mat.set_shader_parameter("aspect",dims.x/dims.y)
		glare_mat.set_shader_parameter("exposure",sunlight);glare_mat.set_shader_parameter("amount",Voyage.opt.glare)

func _unhandled_input(e:InputEvent)->void:
	if not playing:return
	if finale>=0:
		if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode==KEY_F12:take_photo()
		return
	if screen!="":
		if e.is_action_pressed("ui_cancel"):
			if screen=="settings":Voyage.apply_options(true);world.refresh_quality();pause_panel()
			elif screen=="intro":accept_intro()
			elif screen=="finish":return
			elif screen in ["controls","album"]:pause_panel()
			else:close_panel()
		elif screen=="book" and e.is_action_pressed("journal"):close_panel()
		return
	if e.is_action_pressed("ui_cancel"):pause_panel()
	elif e.is_action_pressed("journal"):book_panel()
	elif e is InputEventKey and e.pressed and e.physical_keycode==KEY_F3:diagnostic=not diagnostic;update_hud()
	elif e.is_action_pressed("cheats"):cheats_prompt()
	elif e.is_action_pressed("photo"):
		photo=not photo;hud.visible=not photo;player.hand.visible=not photo
	elif e is InputEventKey and e.pressed and not e.echo and e.physical_keycode==KEY_F12:take_photo()
	elif e is InputEventMouseMotion:player.mouse(e.relative)
	elif e.is_action_pressed("use"):interact()
	elif e.is_action_pressed("scoop"):do_scoop()
	elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed:do_scoop()

func _exit_tree()->void:
	DialogueManager.clear()

func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and playing and screen=="" and finale<0 and DisplayServer.get_name()!="headless" and not "--spoonful-test" in OS.get_cmdline_user_args():
		pause_panel()
