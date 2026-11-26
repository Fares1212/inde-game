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
var playing:=false
var finale_card:=false

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
	if Voyage.p.finished:
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
	var c=UI.card(hud,Color(.05,.17,.19,.93));c.position=Vector2(22,20)
	var vb=UI.vbox(c,2);zone_label=UI.text(vb,"Lagon",24,UI.IVORY,true,true)
	water_label=UI.text(vb,"",16,UI.PALE);region_meter=UI.meter(vb,198)
	tide_label=UI.text(vb,"",14,UI.GOLD)
	var side=UI.card(hud,Color(.05,.17,.19,.92));side.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	UI.pad(side,-221,20,-22,106);var sv=UI.vbox(side,0)
	wallet=UI.text(sv,"",21,UI.GOLD,false,true);UI.text(sv,"J  ·  Carnet   |   Échap  ·  Pause",13,UI.PALE)
	compass=UI.text(hud,"",15,UI.IVORY,false,true);compass.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);UI.pad(compass,-234,23,234,49);compass.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	for l in [compass]:
		l.add_theme_constant_override("outline_size",5);l.add_theme_color_override("font_outline_color",Color("#25464e"))
	var cross=UI.text(hud,"·",29,UI.IVORY,false,true);cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER);UI.pad(cross,-11,-20,11,20);cross.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	var bottom=UI.card(hud,Color(.05,.17,.19,.94));bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT);UI.pad(bottom,22,-113,296,-21)
	var bv=UI.vbox(bottom,1);tool_name=UI.text(bv,"",21,UI.IVORY,true,true);load_label=UI.text(bv,"",15,UI.PALE);bag_meter=UI.meter(bv,222)
	target=UI.text(hud,"",19,UI.IVORY,false,true);target.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	UI.pad(target,-345,-129,345,-92);target.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	help=UI.text(hud,"",15,UI.IVORY);help.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);UI.pad(help,-338,-67,338,-21);help.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	for l in [target,help]:l.add_theme_constant_override("outline_size",6);l.add_theme_color_override("font_outline_color",Color("#193c43"))
	message_panel=UI.card(hud,Color(.09,.22,.23,.94),UI.GOLD);message_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP);UI.pad(message_panel,-279,66,279,117)
	message=UI.text(message_panel,"",16,UI.IVORY);message.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;message.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;message_panel.hide()
	subtitle=UI.text(hud,"",17,UI.IVORY);subtitle.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);UI.pad(subtitle,-360,-195,360,-138);subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_constant_override("outline_size",5);subtitle.add_theme_color_override("font_outline_color",UI.DEEP)

func notify_text(s:String,seconds:=3.1)->void:
	message.text=s;message_panel.show();toast_left=seconds

func say(k:String)->void:
	Sound.voice(k)
	if Voyage.opt.subtitles:
		subtitle.text="Bernard  ·  « "+str(Voyage.db.voices[k])+" »"
		caption_left=clampf(float(subtitle.text.length())/16.0,3.4,8.2)

func panel(kind:String,title:String,small:String,w:=620,h:=555)->Dictionary:
	if is_instance_valid(modal):modal.hide();modal.queue_free()
	screen=kind;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	var m=UI.modal(root,title,small,w,h);modal=m.root;return m

func close_panel()->void:
	if is_instance_valid(modal):modal.hide();modal.queue_free()
	modal=null;screen=""
	canvas.visible=true
	hud.visible=not photo
	capture_mouse();update_hud()

func intro_panel()->void:
	var m=panel("intro","Un tout petit service","Au comptoir de Bernard",615,370)
	UI.copy(m.body,"« "+str(Voyage.db.voices.intro)+" »",21,UI.IVORY)
	UI.copy(m.body,"ZQSD / WASD ou flèches pour marcher. Souris pour regarder. Clic gauche au bord de l’eau, puis E au déversoir. Maj pour courir et Espace pour sauter.",16)
	UI.button(m.footer,"Prendre la cuillère",accept_intro,true).grab_focus();Sound.voice("intro")

func accept_intro()->void:
	Voyage.p.intro_done=true;Voyage.save_now();close_panel()
	notify_text("Approche la mer avec ta cuillère.",3.0)

func pause_panel()->void:
	if screen=="":player.record();Voyage.save_now()
	var m=panel("pause","Marée en pause","Journal de bord",494,480)
	UI.copy(m.body,"Bassin "+str(int(Voyage.p.basin)+1)+"  ·  "+str(Voyage.db.zones[Voyage.region()].title)+"  ·  "+Voyage.percent(Voyage.p.drained/Voyage.total())+" vidé.",17)
	UI.button(m.body,"Reprendre",close_panel,true).grab_focus()
	UI.button(m.body,"Réglages",options_panel);UI.button(m.body,"Carnet des trouvailles",book_panel);UI.button(m.body,"Commandes",controls_panel);UI.button(m.body,"Album photo",album_panel);UI.button(m.body,"Sauvegarder et revenir au port",return_menu)

func album_panel()->void:
	if is_instance_valid(modal):modal.hide();modal.queue_free()
	screen="album"
	modal=UI.album(root,pause_panel)

func controls_panel()->void:
	var m=panel("controls","Commandes","SPOONFUL",584,515)
	for row in ["ZQSD, WASD ou flèches     Marcher","Souris     Regarder","Clic gauche     Puiser ou actionner l’outil","E     Vendre, verser, ramasser ou tirer la Bonde","Maj / Espace     Courir / sauter","J     Carnet des 18 trouvailles","F2     Mode photo libre du HUD","F12     Enregistrer une photo PNG","F1     Menu de développement","Échap     Pause ou retour"]:
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
	var m=panel("book","Carnet des trouvailles",str(Voyage.p.seen.size())+" / 18 découvertes",740,620)
	for r in 6:
		UI.text(m.body,str(Voyage.db.zones[r].title),22,UI.GOLD,true,true)
		for j in 3:
			var k=r*3+j;var found=Voyage.p.seen.has(str(k));var entry=Voyage.db.finds[k]
			UI.text(m.body,entry.title if found else "— Objet encore immergé —",16,UI.IVORY if found else UI.PALE,false,found)
			if found:UI.copy(m.body,entry.lore,14)
	UI.button(m.footer,"Fermer le carnet",close_panel,true).grab_focus()

func shop_panel(greeting:=true)->void:
	var m=panel("shop","Le comptoir de Bernard","Coquilles en poche  ·  "+str(int(Voyage.p.coins)),650,540)
	UI.copy(m.body,"Le crabe ajuste l’anse de sa tasse. Sur une ardoise, il a écrit le prix du prochain outil.",16)
	var val=Voyage.cargo_value()
	var sell_button=UI.button(m.body,"Vendre les trouvailles  ·  "+str(val)+" coquilles",func():
		var got=Voyage.sell()
		if got>0:Sound.effect("coin");say("sale");shop_panel(false)
	)
	sell_button.disabled=val<=0
	if int(Voyage.p.tier)<5:
		var next=Voyage.db.tools[int(Voyage.p.tier)+1]
		UI.text(m.body,next.title,28,UI.IVORY,true,true);UI.copy(m.body,next.description)
		UI.text(m.body,"Capacité  "+Voyage.number(float(next.capacity)*Voyage.power_bonus())+"   ·   Prix  "+str(int(next.price))+" coquilles",16,UI.GOLD)
		var status=Voyage.upgrade_status()
		if status!="":UI.copy(m.body,status,16)
		var purchase=UI.button(m.body,"Acheter cet outil",func():
			if Voyage.buy():
				player.rebuild();world.refresh();Sound.effect("buy");say("buy");flash.color.a=.16;shop_panel(false)
		,true);purchase.disabled=status!=""
	else:UI.copy(m.body,"L’éponge géante est à toi. La chaîne te guidera vers la Bonde.")
	UI.button(m.footer,"Retour à la plage",close_panel).grab_focus()
	if greeting:say("shop")

func debug_panel()->void:
	var m=panel("debug","Outils de développement","F1 · Test du bassin",525,520)
	UI.button(m.body,"Ajouter 100 coquilles",func():Voyage.p.coins+=100;Voyage.save_now();debug_panel())
	UI.button(m.body,"Débloquer l’outil suivant",func():
		if Voyage.p.tier<5:Voyage.p.tier+=1;Voyage.save_now();player.rebuild();world.refresh()
		debug_panel())
	UI.button(m.body,"Découvrir la zone suivante",func():
		var r=Voyage.region();Voyage.p.drained=Voyage.total()*(float(Voyage.db.zones[r+1].units)/float(Voyage.db.basin_units)) if r<5 else Voyage.total()
		Voyage.save_now();world.refresh();close_panel())
	UI.button(m.body,"Rejoindre Bernard",func():player.go(Coast.SHOP.x,Coast.SHOP.y+2);close_panel())
	UI.button(m.body,"Rejoindre la chaîne",func():player.go(0,2.3);close_panel())
	UI.button(m.body,"Temps ×"+("1" if multiplier>1 else "10"),func():multiplier=1.0 if multiplier>1 else 10.0;debug_panel())
	UI.button(m.body,"Prendre une photo",func():close_panel();take_photo())
	UI.button(m.footer,"Revenir au jeu",close_panel,true).grab_focus()

func first_port()->Vector3:
	var n=Voyage.region()
	var best=Coast.PORTS[0]
	var d=INF
	for i in n+1:
		var pp:Vector2=Coast.PORTS[i]
		var dist=pp.distance_to(Vector2(player.position.x,player.position.z))
		if dist<d:d=dist;best=pp
	return S.place(best.x,best.y,0.45)

func focus()->Dictionary:
	var pos:Vector3=player.position
	var q=Vector2(pos.x,pos.z)
	var best={"key":"","dist":INF}
	var facing=-player.cam.global_basis.z
	for entry in world.finds:
		if not entry.node.visible:continue
		var delta=entry.p+Vector3.UP*.38-player.cam.global_position
		var dst=q.distance_to(Vector2(entry.p.x,entry.p.z))
		if dst<=2.75 and dst<best.dist and (delta.normalized().dot(facing)>.13 or dst<1.25):
			best={"key":"find","dist":dst,"entry":entry,"label":"E  ·  Ramasser "+str(Voyage.db.finds[entry.kind].title)}
	if Voyage.plug_ready() and q.length()<=4.2:return {"key":"plug","label":"E  ·  Soulever la Bonde"}
	var ds=q.distance_to(Coast.SHOP)
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
	if Voyage.scoop()>0:
		player.animate_action();world.splash(water);Sound.effect("scoop")
		throttle=.22 if int(Voyage.p.tier)>=3 else .32
		if Voyage.p.scoops==1:notify_text("Première cuillère pleine. Rejoins le déversoir.",3.6)
	elif Voyage.plug_ready():notify_text("La mer est vide. Suis la chaîne jusqu’à la Bonde.")

func interact()->void:
	if throttle>.14:return
	var dst=focus()
	match dst.key:
		"shop":shop_panel()
		"pour":
			var quantity=Voyage.pour()
			if quantity>0:
				player.animate_action(1.1);world.splash(dst.pos,true);Sound.effect("pour");throttle=.30
				if Voyage.p.drops==1:
					say("first");notify_text("Plic !   −"+Voyage.percent(quantity/Voyage.total()),5.0)
					postcard("Premier-plic")
				else:notify_text("Livraison   −"+Voyage.number(quantity)+" unités d’eau",2)
			else:notify_text("Va remplir ton outil au bord de l’eau.",2.1)
		"find":
			var e=dst.entry
			var fresh=not Voyage.p.seen.has(str(e.kind))
			if Voyage.collect(e.id,e.kind):
				e.node.visible=false;Sound.effect("coin");player.animate_action(.35)
				notify_text(("Carnet mis à jour  ·  " if fresh else "Dans la besace  ·  ")+str(Voyage.db.finds[e.kind].title));throttle=.20
		"plug":
			if Voyage.open_plug():start_finale()
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
	zone_label.text=str(row.title)+"  ·  "+str(int(Voyage.p.basin)+1)
	water_label.text="Mer retirée   "+Voyage.percent(Voyage.p.drained/Voyage.total())
	var lower=float(row.units)
	var upper=float(Voyage.db.zones[reg+1].units) if reg<5 else float(Voyage.db.basin_units)
	region_meter.value=clampf((Voyage.volume_base()-lower)/(upper-lower),0,1)
	var t=Voyage.tide()
	tide_label.text="Basse mer" if t<-.75 else ("Pleine mer" if t>.75 else ("Marée montante" if cos(Voyage.tide_phase())>0 else "Marée descendante"))
	wallet.text=str(int(Voyage.p.coins))+"  coquilles"
	tool_name.text=Voyage.db.tools[int(Voyage.p.tier)].title
	load_label.text="Cargaison  "+Voyage.number(Voyage.p.bag)+" / "+Voyage.number(Voyage.capacity())
	bag_meter.value=Voyage.p.bag/Voyage.capacity()
	action_target=focus()
	target.text=action_target.get("label","")
	if target.text=="" and sample_water().x<900 and Voyage.p.bag<Voyage.capacity():target.text=("Maintenir le clic  ·  " if Voyage.p.tier>=3 else "Clic  ·  ")+str(Voyage.db.tools[int(Voyage.p.tier)].verb)
	if Voyage.plug_ready():compass.text="BONDE  ·  "+heading_to(Vector3.ZERO);help.text="Rejoins le pied de la chaîne pour ouvrir la Bonde."
	elif Voyage.p.bag>0:compass.text="DÉVERSOIR  ·  "+heading_to(first_port());help.text="Verse ta cargaison avec E au déversoir."
	elif (int(Voyage.p.tier)<5 and Voyage.upgrade_status()=="") or Voyage.cargo_value()>=8:
		compass.text="BERNARD  ·  "+heading_to(S.place(Coast.SHOP.x,Coast.SHOP.y));help.text="Rends visite au crabe pour vendre ou changer d’outil."
	else:
		compass.text="";help.text="Marche vers l’eau. Explore la rive à marée basse." if Voyage.p.drops<3 else "E  ·  Interagir     J  ·  Carnet     F2  ·  Photo"

func start_finale()->void:
	close_panel();photo=false;hud.hide();glare.hide();player.hand.hide()
	finale=0;world.start_finale();Sound.effect("plug");Sound.voice("plug")
	end_cam=Camera3D.new();add_child(end_cam);end_cam.current=true;end_cam.fov=69
	set_final_camera()

func set_final_camera()->void:
	var t=clampf(finale/12.0,0.0,1.0)
	var a=.32+t*.75
	var d=lerpf(28,49,t)
	end_cam.position=Vector3(sin(a)*d,lerpf(12,31,t),cos(a)*d)
	end_cam.look_at(Vector3(0,-8,0))

func finish_panel()->void:
	finale=-1;hud.hide()
	var m=panel("finish","La mer d’en dessous","La Bonde est ouverte",650,493)
	UI.copy(m.body,"Le dernier navire disparaît dans le siphon. Le silence ne dure qu’une seconde. Sous cette mer, un océan plus grand attendait sa première cuillère.",21,UI.IVORY)
	UI.text(m.body,"Bassin "+str(int(Voyage.p.basin)+1)+" vidé",24,UI.GOLD,true,true)
	UI.copy(m.body,str(int(Voyage.p.drops))+" livraisons  ·  "+str(int(Voyage.p.scoops))+" puisages  ·  "+str(Voyage.p.seen.size())+" / 18 trouvailles au carnet.")
	UI.copy(m.body,"Le carnet reste à toi. Dans le prochain bassin, tes outils auront 34 % de capacité en plus.")
	UI.button(m.footer,"Ouvrir le bassin suivant",next_basin,true).grab_focus()
	UI.button(m.footer,"Revenir au menu",return_menu)

func next_basin()->void:
	if Voyage.prestige():
		playing=false;get_tree().reload_current_scene()

func postcard(moment:String,delay:=.12)->void:
	if DisplayServer.get_name()=="headless" or "--spoonful-test" in OS.get_cmdline_user_args():return
	var file=Voyage.photo_folder().path_join("Bassin-%02d-%s.png"%[int(Voyage.p.basin)+1,moment])
	if FileAccess.file_exists(file):return
	await get_tree().create_timer(delay).timeout
	if not is_inside_tree():return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(file)

func take_photo()->void:
	if DisplayServer.get_name()=="headless":return
	var old=hud.visible
	hud.hide()
	await RenderingServer.frame_post_draw
	var img=get_viewport().get_texture().get_image()
	var folder=Voyage.photo_folder()
	var name="Bassin-%02d-%s.png"%[int(Voyage.p.basin)+1,Time.get_datetime_string_from_system().replace(":","-")]
	var ok=img.save_png(folder.path_join(name))
	hud.visible=old
	if ok==OK:notify_text("Photo enregistrée dans le dossier Photos de SPOONFUL.",3.0)

func _process(dt:float)->void:
	if not playing:return
	throttle=maxf(0,throttle-dt);flash.color.a=move_toward(flash.color.a,0,dt*.8)
	if finale>=0:
		finale+=dt
		world.animate(dt,finale);set_final_camera()
		if finale>5.2 and not finale_card:
			finale_card=true;postcard("Le-tourbillon")
		if finale>=12:finish_panel()
		return
	if screen!="":
		if screen in ["intro","shop"]:world.animate(dt*.45)
		return
	world.animate(dt)
	player.move(minf(dt,.07))
	Voyage.tick(minf(dt,.18)*multiplier)
	if int(Voyage.p.tier)>=3 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and throttle<=0 and Voyage.p.bag<Voyage.capacity() and sample_water().x<900:do_scoop()
	var reg=Voyage.region()
	if reg>was_region:
		was_region=reg;world.refresh();Sound.effect("reveal");flash.color.a=.21
		notify_text(str(Voyage.db.zones[reg].title)+"  ·  "+str(Voyage.db.zones[reg].mark),6.0)
		if reg==3:
			Sound.effect("creak");postcard("Les-epaves",1.3)
	timer+=dt
	if timer>.12:timer=0;update_hud()
	toast_left=maxf(0,toast_left-dt)
	if toast_left<=0:message_panel.hide()
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
	elif e.is_action_pressed("debug_menu"):debug_panel()
	elif e.is_action_pressed("photo"):
		photo=not photo;hud.visible=not photo;player.hand.visible=not photo
	elif e is InputEventKey and e.pressed and not e.echo and e.physical_keycode==KEY_F12:take_photo()
	elif e is InputEventMouseMotion:player.mouse(e.relative)
	elif e.is_action_pressed("use"):interact()
	elif e is InputEventMouseButton and e.button_index==MOUSE_BUTTON_LEFT and e.pressed:do_scoop()

func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and playing and screen=="" and finale<0 and DisplayServer.get_name()!="headless" and not "--spoonful-test" in OS.get_cmdline_user_args():
		pause_panel()
