extends Node

const S=preload("res://scripts/shore.gd")
const C=preload("res://scripts/coast.gd")
var failed:=false
var steps:=0
var frames:=0
var folder:=""
var game
var render:=false

func _ready()->void:
	folder=OS.get_environment("SPOONFUL_QA_DIR")
	if folder=="":folder=ProjectSettings.globalize_path("user://verification/results")
	DirAccess.make_dir_recursive_absolute(folder)
	render=DisplayServer.get_name()!="headless" and "--screenshots" in OS.get_cmdline_user_args()
	call_deferred("run")

func check(condition:bool,msg:String)->bool:
	steps+=1
	if not condition:
		failed=true
		push_error("SPOONFUL CHECK "+str(steps)+": "+msg)
	return condition

func wait_frames(n:=3)->void:
	for i in n:await get_tree().process_frame

func shot(label:String)->void:
	if not render:return
	await wait_frames(3)
	await RenderingServer.frame_post_draw
	var img=get_viewport().get_texture().get_image()
	check(img.get_width()>=900 and img.get_height()>=500,"Taille du rendu")
	check(img.save_png(folder+"/"+label+".png")==OK,"Capture "+label)

func button_named(node:Node,word:String)->Button:
	for child in node.get_children():
		if child is Button and str(child.text).begins_with(word):return child
		var hit=button_named(child,word)
		if hit:return hit
	return null

func press(node:Node,word:String)->bool:
	var b=button_named(node,word)
	if not check(b!=null and not b.disabled,"Bouton disponible : "+word):return false
	b.pressed.emit()
	return true

func aim_at(pos:Vector3)->void:
	var vec=pos-game.player.cam.global_position
	game.player.yaw=atan2(-vec.x,-vec.z)
	game.player.pitch=atan2(vec.y,Vector2(vec.x,vec.z).length())
	game.player.orient()

func seek_water()->void:
	var r=float(C.RADII[Voyage.region()])
	var ok=false
	for j in 82:
		var z=maxf(.6,r+5.0-j*.9)
		game.player.go(.3,z)
		game.player.yaw=0;game.player.pitch=-.25;game.player.orient()
		if game.sample_water().x<900:ok=true;break
	check(ok,"Rivage accessible pour l’outil "+str(Voyage.p.tier))

func deliver()->void:
	seek_water()
	var old=Voyage.p.drained
	for j in 16:
		if Voyage.p.bag>=Voyage.capacity() or Voyage.p.drained>=Voyage.total():break
		game.throttle=0;game.do_scoop()
	if not check(Voyage.p.bag>0,"Remplir l’outil "+str(Voyage.p.tier)):return
	var before_pour:float=Voyage.p.drained
	check(before_pour>old,"Le volume baisse au puisage")
	var port=game.first_port();game.player.go(port.x,port.z+.30)
	game.throttle=0;game.interact()
	check(Voyage.p.bag==0 and Voyage.p.drained==before_pour and game.world.saltworks.current>0,"Livraison créditée")
	game.world.refresh()

func loot_for_market()->void:
	game.world.refresh()
	for entry in game.world.finds:
		if not entry.node.visible:continue
		game.player.go(entry.p.x,entry.p.z+.32);aim_at(entry.p+Vector3.UP*.22);game.throttle=0
		var before=Voyage.p.taken.size()
		game.interact()
		if Voyage.p.taken.size()>before:
			check(not Voyage.collect(entry.id,entry.kind),"Même objet non dupliqué")
			if Voyage.cargo_value()>=50:break

func shop()->void:
	game.player.go(C.SHOP.x,C.SHOP.y+.50)
	aim_at(game.world.crab.global_position);game.throttle=0;game.interact()
	check(game.screen=="shop","Ouverture de la boutique")

func end_test()->void:
	var result={"passed":not failed,"checks":steps,"backend":DisplayServer.get_name(),"basin":Voyage.p.get("basin",-1),"endings":Voyage.p.get("endings",{}).size(),"version":ProjectSettings.get_setting("application/config/version")}
	var file=FileAccess.open(folder+"/result.json",FileAccess.WRITE)
	if file:file.store_string(JSON.stringify(result));file.close()
	print(("SPOONFUL_QA_FAIL " if failed else "SPOONFUL_QA_PASS ")+JSON.stringify(result))
	Sound.stop_all()
	await get_tree().create_timer(.18).timeout
	get_tree().quit(1 if failed else 0)

func run()->void:
	for e in [".json",".bak",".tmp"]:
		var path=ProjectSettings.globalize_path(Voyage.storage+Voyage.SAVE_NAME+e)
		if FileAccess.file_exists(path):DirAccess.remove_absolute(path)
	await wait_frames(5)
	var menu=get_tree().current_scene
	if not check(menu!=null and menu.name=="Menu","Démarrage du menu"):end_test();return
	check(Sound.samples.size()>=20,"Banque de bruitages et ambiance")
	await shot("01-menu")
	menu.start_new()
	await wait_frames(5)
	game=get_tree().current_scene
	if not check(game!=null and game.name=="Game" and game.screen=="intro","Introduction du premier voyage"):end_test();return
	press(game.modal,"Prendre la cuillère")
	check(Voyage.p.tier==0 and Voyage.p.drained==0,"Première cuillère")
	game.player.go(0,90.4);game.player.yaw=-.12;game.player.pitch=-.095;game.player.orient()
	game.update_hud();await shot("02-lagon")
	game.toast_left=0;game.hud.hide();await shot("outil-0-vide");game.player.hand.hide()
	await shot("00-cote")
	game.hud.show();game.player.hand.show()
	var start_z=game.player.position.z
	Input.action_press("forward")
	for i in 10:
		game.player.move(.016)
	Input.action_release("forward")
	check(game.player.position.z<start_z,"Déplacement en vue subjective")
	game.world.refresh()
	check(not game.world.finds.any(func(entry):return entry.node.visible),"Objets enfouis au début")
	test_boats()
	test_cheats()
	deliver()
	if failed:end_test();return
	check(Voyage.p.drained==5 and Voyage.volume(Voyage.p.drained)=="5 mL","Première cuillère de cinq millilitres")
	check(game.region_meter.value==Voyage.p.drained/Voyage.total(),"Jauge globale")
	check(game.world.finds[0].node.visible and not game.world.finds[1].node.visible,"Première coquille découverte au premier puisage")
	check(not Voyage.collect(1,1),"Trésor sous le seuil inaccessible")
	game.player.go(C.DOCK.x-1.80,C.DOCK.y+3.05);aim_at(game.world.saltworks.global_position+Vector3(-1.82,.72,0))
	DialogueManager.clear();game.toast_left=0;game.hud.hide();game.player.hand.hide();game.world.saltworks.receive();game.world.saltworks.advance(.69)
	await shot("salines");game.hud.show();game.player.hand.show()
	loot_for_market();shop()
	for number in 6:
		var cell:Button=game.modal.find_child("Tool%d"%number,true,false)
		check(cell!=null and cell.is_visible_in_tree(),"Les six récipients au comptoir")
		if number>0:check(cell.disabled and cell.text=="Locked","Verrou visible")
	await shot("comptoir-locked")
	game.shop_tab="objects";game.shop_panel(false)
	var at_sale:float=Voyage.p.drained
	if Voyage.cargo_value()>0:press(game.modal,"Vendre les trouvailles")
	check(Voyage.cargo_value()==0 and Voyage.p.drained==at_sale,"La vente ne retire aucune eau")
	game.close_panel();game.shop_tab="vessels"
	while Voyage.p.drops<8:deliver()
	shop();press(game.modal,"Amorcer le siphon");game.close_panel()
	check(Voyage.p.primer,"Siphon amorcé")
	for i in range(1,6):
		# Exercise purchases on either side of their gate. Pacing uses the separate timed simulator.
		var v:VesselData=Voyage.db.tools[i]
		Voyage.p.drained=v.gate*Voyage.total();Voyage.p.peak=Voyage.p.drained;Voyage.p.coins=v.price-1
		check(not Voyage.buy(),"Solde insuffisant")
		Voyage.p.coins=v.price
		shop()
		if i==1:await shot("comptoir-prix")
		var control:Button=game.modal.find_child("Tool%d"%i,true,false)
		check(control!=null and not control.disabled and control.text.contains(str(v.price)),"Prix d’achat affiché")
		control.pressed.emit();game.close_panel()
		check(Voyage.p.tier==i and is_instance_valid(game.player.liquid),"Récipient ouvert et eau du modèle")
		game.player.kick=0;game.player.swing=1
		game.player.go(0,82);game.player.yaw=0;game.player.pitch=-.46 if i==5 else -.16;game.player.orient()
		for j in 3:game.player.move(.05)
		Voyage.p.bag=0;game.player.fill_view=0;game.player.move(.01)
		game.hud.hide();await shot("outil-%d-vide"%i)
		Voyage.p.bag=Voyage.capacity()*.64;game.player.fill_view=.64;game.player.move(.01)
		check(game.player.liquid.visible,"Eau visible en main")
		await shot("outil-%d-plein"%i);game.hud.show()
		Voyage.p.bag=0;deliver()
		if failed:end_test();return
	game.player.go(C.SHOP.x+.6,C.SHOP.y+4.3);aim_at(game.world.crab.global_position+Vector3.UP*.55)
	game.hud.hide();game.player.hand.hide();await shot("04-bernard");game.hud.show();game.player.hand.show()
	shop();await shot("03-boutique");game.close_panel()
	Voyage.p.drained=Voyage.total();Voyage.p.peak=Voyage.total();game.world.refresh()
	game.player.go(0,2);game.throttle=0;game.interact();check(game.screen=="choice","Dernier choix")
	check(not Voyage.choose_ending("home"),"Secret protégé")
	for k in ["tide","empty","home"]:
		if k=="home":
			game.close_panel();game.world.refresh()
			for found in game.world.finds:
				if not found.node.visible or Voyage.p.seen.has(Voyage.db.finds[found.kind].id):continue
				game.player.go(found.p.x,found.p.z+.16);aim_at(found.p+Vector3.UP*.2)
				game.throttle=0;game.interact()
			check(Voyage.p.seen.size()==30,"Les 30 trouvailles peuvent être ramassées sur le terrain")
			shop();game.shop_tab="objects";game.shop_panel(false)
			if Voyage.cargo_value()>0:press(game.modal,"Vendre les trouvailles")
			check(Voyage.p.cargo.has("find_16"),"La clé reste dans la besace après la vente")
			press(game.modal,"Rendre la clé")
			check(Voyage.can_home(),"Carnet complet et clé rendue sur la côte")
			game.close_panel();game.book_panel();await shot("05-carnet");game.close_panel()
			game.player.go(0,2);game.throttle=0;game.interact()
		game.start_finale(k);check(Voyage.p.ending==k,"Fin choisie")
		game.finale=6.5;game._process(.01);await shot("fin-"+k)
		game.finale=12;game._process(.03);check(game.screen=="finish","Générique")
		if k=="home":
			press(game.modal,"Se promener");await wait_frames(5);game=get_tree().current_scene
			check(Voyage.p.free and game.screen=="","Exploration libre")
			game.pause_panel()
		press(game.modal,"Revenir avant");await wait_frames(5);game=get_tree().current_scene
		check(not Voyage.p.finished and Voyage.plug_ready() and Voyage.p.endings.has(k),"Reprise du choix sur la même mer")
	check(Voyage.p.endings.size()==3,"Trois fins sur une côte")
	var legacy={"schema":1,"tier":2,"basin":1,"drained":77500000.0,"bag":46900.0,"coins":81,"seen":{"2":true},"cargo":{"2":1},"taken":{"2":true}}
	var old_v2:=Voyage.blank()
	old_v2.schema=2;old_v2.drained=100.;old_v2.bag=5.
	var v3:=Voyage.restore_state(old_v2)
	check(v3.schema==3 and v3.drained==105. and v3.bag==5. and Voyage.restore_state(v3).drained==105.,"Migration unique de la cargaison V2")
	var migrated:=Voyage.migrate(legacy)
	check(is_equal_approx(migrated.drained/Voyage.total(),.5) and migrated.seen.has("find_02") and migrated.coins==81 and migrated.bag==4250,"Migration de progression V1")
	game.pause_panel();press(game.modal,"Réglages");press(game.modal,"Enregistrer et revenir");check(game.screen=="pause","Réglages")
	Voyage.save_now();Voyage.save_now()
	var damaged=FileAccess.open(Voyage.storage+Voyage.SAVE_NAME+".json",FileAccess.WRITE);damaged.store_string("{");damaged.close()
	check(Voyage.continue_run() and Voyage.p.endings.size()==3,"Sauvegarde de secours")
	end_test()

func test_boats()->void:
	for dry in [false,true]:
		Voyage.p.drained=Voyage.total() if dry else 0.
		game.world.animate(.016)
		for vessel in game.world.shipwrecks:
			var boat:Node3D=vessel.node
			var center:=Vector2(boat.position.x,boat.position.z)
			# Approach port and starboard while holding the normal forward control.
			for side in [-1.,1.]:
				var from:=center+Vector2(0,side*(float(vessel.s)*.45+1.2)).rotated(-boat.rotation.y)
				game.player.go(from.x,from.y);game.player.motion=Vector2.ZERO
				game.player.yaw=atan2(from.x-center.x,from.y-center.y);game.player.orient()
				Input.action_press("forward")
				for step in 55:game.player.move(.035)
				Input.action_release("forward")
				var end:=Vector2(game.player.position.x,game.player.position.z)
				check((end-center).dot(from-center)>0 and not Geometry2D.is_point_in_polygon(end,vessel.outline),"Coque solide des deux côtés, mer basse ou haute")
	Voyage.p.drained=0.;Voyage.p.peak=0.;game.world.refresh()

func test_cheats()->void:
	var input:=InputEventKey.new();input.physical_keycode=KEY_F1;input.pressed=true
	game._unhandled_input(input);check(game.screen=="","F1 ne contourne pas le code")
	input.physical_keycode=KEY_F4;game._unhandled_input(input);check(game.photo,"F4 active le mode photo");game._unhandled_input(input)
	input.physical_keycode=KEY_F2;game._unhandled_input(input)
	check(game.screen=="code","F2 ouvre la saisie du code")
	var entry:LineEdit=game.modal.find_child("CheatCode",true,false)
	entry.text="1200";entry.text_submitted.emit(entry.text);check(game.screen=="code" and not game.cheat_access,"Mauvais code refusé")
	entry.text="1201";entry.text_submitted.emit(entry.text);check(game.screen=="debug" and game.cheat_access,"Code 1201 reconnu")
	press(game.modal,"Revenir au jeu");game.debug_panel();check(game.screen=="","Fermeture relocke le menu")
