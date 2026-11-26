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
		if Voyage.p.bag>=Voyage.capacity() or Voyage.p.drained+Voyage.p.bag>=Voyage.total():break
		game.throttle=0;game.do_scoop()
	if not check(Voyage.p.bag>0,"Remplir l’outil "+str(Voyage.p.tier)):return
	var port=game.first_port();game.player.go(port.x,port.z+.30)
	game.throttle=0;game.interact()
	check(Voyage.p.bag==0 and Voyage.p.drained>old,"Livraison créditée")
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
	var result={"passed":not failed,"checks":steps,"backend":DisplayServer.get_name(),"basin":Voyage.p.get("basin",-1),"version":ProjectSettings.get_setting("application/config/version")}
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
	check(Sound.samples.size()==27,"Présence des 27 pistes musicales, voix et effets")
	await shot("01-menu")
	menu.start_new()
	await wait_frames(5)
	game=get_tree().current_scene
	if not check(game!=null and game.name=="Game" and game.screen=="intro","Introduction du premier voyage"):end_test();return
	press(game.modal,"Prendre la cuillère")
	check(Voyage.p.tier==0 and Voyage.p.drained==0,"Première cuillère")
	game.player.go(0,83.2);game.player.yaw=-.025;game.player.pitch=-.105;game.player.orient()
	game.update_hud();await shot("02-lagon")
	var start_z=game.player.position.z
	Input.action_press("forward")
	for i in 10:
		game.player.move(.016)
	Input.action_release("forward")
	check(game.player.position.z<start_z,"Déplacement en vue subjective")
	deliver()
	if failed:end_test();return
	check(Voyage.percent(Voyage.p.drained/Voyage.total())=="0,000001 %","Premier millionième")
	check(not Voyage.buy(),"Achat refusé si solde insuffisant")
	var dry=Voyage.p.drained
	var before_y=Voyage.water_y();Voyage.tick(29)
	check(Voyage.p.drained==dry and absf(Voyage.water_y()-before_y)>.05,"Marée distincte du volume retiré")
	loot_for_market()
	check(Voyage.p.taken.size()>0 and Voyage.p.seen.size()>0,"Carnet alimenté")
	var sq=Voyage.p.drained;game.player.record();Voyage.save_now()
	Voyage.p=Voyage.blank()
	check(Voyage.continue_run() and Voyage.p.drained==sq and not Voyage.p.seen.is_empty(),"Reprise avec découvertes et cargaison")
	shop();await shot("03-boutique")
	if Voyage.cargo_value()>0:press(game.modal,"Vendre les trouvailles")
	check(Voyage.cargo_value()==0,"Vente groupée")
	game.close_panel()
	game.player.go(C.SHOP.x+1.65,C.SHOP.y+2.8);aim_at(game.world.crab.global_position+Vector3.UP*.7)
	game.hud.hide();await shot("04-bernard");game.hud.show()
	for tier in range(1,6):
		var count=0
		while Voyage.upgrade_status()!="" and count<125:
			deliver();count+=1
			if failed:end_test();return
		if not check(Voyage.upgrade_status()=="","Palier accessible "+str(tier)):end_test();return
		shop();press(game.modal,"Acheter cet outil")
		check(Voyage.p.tier==tier,"Outil acheté "+str(tier))
		game.close_panel()
		if tier==4:
			var v=Voyage.p.drained;Voyage.tick(2);check(Voyage.p.drained>v,"Éoliennes automatiques")
	if failed:end_test();return
	while not Voyage.plug_ready() and frames<50:
		deliver();frames+=1
		if failed:end_test();return
	check(Voyage.plug_ready() and Voyage.region()==5,"Toutes les zones traversées")
	game.world.refresh();game.player.go(0,2.1);game.throttle=0;game.interact()
	check(Voyage.p.finished and game.finale>=0,"Ouverture manuelle de la Bonde")
	game.finale=5.5;game.set_final_camera();game.world.animate(.016,5.5)
	await shot("05-bonde")
	game.finale=12;game._process(.05)
	check(game.screen=="finish","Écran de fin")
	var findings=Voyage.p.seen.size()
	press(game.modal,"Ouvrir le bassin suivant");await wait_frames(4)
	game=get_tree().current_scene
	check(Voyage.p.basin==1 and Voyage.p.drained==0 and not Voyage.p.finished and Voyage.p.seen.size()==findings and Voyage.power_bonus()>1,"Prestige avec conservation du carnet")
	game.pause_panel();press(game.modal,"Réglages");check(game.screen=="settings","Réglages de pause")
	press(game.modal,"Enregistrer et revenir");check(game.screen=="pause","Retour depuis les réglages")
	press(game.modal,"Album photo");check(game.screen=="album","Album accessible depuis la partie")
	press(game.modal,"Retour");check(game.screen=="pause","Retour depuis l’album")
	Voyage.save_now();Voyage.save_now()
	var path=Voyage.storage+Voyage.SAVE_NAME+".json";var damaged=FileAccess.open(path,FileAccess.WRITE);damaged.store_string("{");damaged.close()
	check(Voyage.continue_run() and Voyage.p.basin==1,"Récupération de la sauvegarde de secours")
	end_test()
