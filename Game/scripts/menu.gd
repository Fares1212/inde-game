extends Control

const UI=preload("res://scripts/ui.gd")
const Forms=preload("res://scripts/forms.gd")
var cover:TextureRect
var menu_panel:PanelContainer
var modal:Control
var age:=0.0
var buttons:Array=[]
var play:Button
var resume:Button
var cover_mat:ShaderMaterial
var actor:Node3D
var vp:SubViewport

func _ready()->void:
	Voyage.run_active=false
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	Sound.music(true);Sound.apply_settings()
	cover=TextureRect.new();cover.texture=preload("res://art/cover.png")
	cover.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	cover.stretch_mode=TextureRect.STRETCH_SCALE;cover.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(cover)
	var shader=Shader.new();shader.code="shader_type canvas_item; uniform float ocean_time=0.0;void fragment(){vec2 p=UV;float w=smoothstep(.46,.62,p.y)*(1.-smoothstep(.78,.95,p.y));p.x+=.0015*w*sin(p.y*120.+ocean_time*1.1);p.y+=.00075*w*sin(p.x*55.+ocean_time*.68);COLOR=texture(TEXTURE,p);}"
	cover_mat=ShaderMaterial.new();cover_mat.shader=shader;cover.material=cover_mat
	menu_panel=UI.card(self,Color("#11383e"),Color("#92a392"));menu_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	UI.pad(menu_panel,25,-153,-25,-22)
	var row=UI.hbox(menu_panel,22);var content=UI.vbox(row,5);content.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	var has=Voyage.has_run()
	var title="Le prochain bassin t’attend." if has else "Une cuillère. Un océan."
	UI.text(content,title,30,UI.IVORY,true,true)
	UI.text(content,"Un conte maritime à la petite cuillère",15,UI.PALE)
	var actions=UI.hbox(content,9)
	if has:resume=UI.button(actions,"Continuer",do_continue,true);buttons.append(resume)
	play=UI.button(actions,"Nouvelle partie" if has else "Embarquer",begin,not has);buttons.append(play)
	buttons.append(UI.button(actions,"Réglages",show_options));buttons.append(UI.button(actions,"Album",show_album));buttons.append(UI.button(actions,"Crédits",credits));buttons.append(UI.button(actions,"Quitter",func():get_tree().quit()))
	buttons[0].grab_focus()
	make_actor(row)
	resized.connect(layout_cover);layout_cover()

func layout_cover()->void:
	var tex_size=Vector2(1536,1024)
	var fac=maxf(size.x/tex_size.x,size.y/tex_size.y);cover.size=tex_size*fac
	cover.position=Vector2((size.x-cover.size.x)*.5,minf(0,(size.y-cover.size.y)*.075))

func make_actor(row:HBoxContainer)->void:
	var frame=SubViewportContainer.new();frame.custom_minimum_size=Vector2(138,90);frame.stretch=true;frame.mouse_filter=Control.MOUSE_FILTER_IGNORE;row.add_child(frame)
	vp=SubViewport.new();vp.transparent_bg=true;vp.own_world_3d=true;vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS;frame.add_child(vp)
	var scene=Node3D.new();vp.add_child(scene)
	var cam=Camera3D.new();scene.add_child(cam);cam.position=Vector3(0,1.25,3.1);cam.look_at(Vector3(0,.72,0));cam.fov=35;cam.current=true
	var light=DirectionalLight3D.new();scene.add_child(light);light.rotation_degrees=Vector3(-40,20,0);light.light_energy=1.8
	var light2=OmniLight3D.new();scene.add_child(light2);light2.position=Vector3(-1.2,1,2);light2.light_color=Color("#ffdea6");light2.light_energy=1
	actor=Forms.owl_shell(scene)

func _process(dt:float)->void:
	age+=dt
	cover_mat.set_shader_parameter("ocean_time",age)
	if actor:
		actor.rotation.y=.42*sin(age*.42);actor.get_node("PinceD").rotation.z=.22*sin(age*2.1)

func clear_modal()->void:
	if is_instance_valid(modal):modal.queue_free()
	modal=null;menu_panel.visible=true
	buttons[0].grab_focus()

func leave_for_sea()->void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")

func do_continue()->void:
	if Voyage.continue_run():leave_for_sea()

func begin()->void:
	if not Voyage.has_run():start_new();return
	menu_panel.hide()
	var m=UI.modal(self,"Repartir du début ?","Journal de bord",535,300);modal=m.root
	UI.copy(m.body,"Une nouvelle partie remplacera la sauvegarde de ce voyage. Tu peux aussi continuer à explorer ton bassin actuel.")
	UI.button(m.footer,"Garder ma partie",clear_modal).grab_focus()
	UI.button(m.footer,"Recommencer",start_new)

func start_new()->void:
	Voyage.new_run();leave_for_sea()

func show_options()->void:
	menu_panel.hide();modal=UI.options(self,clear_modal)

func show_album()->void:
	menu_panel.hide();modal=UI.album(self,clear_modal)

func credits()->void:
	menu_panel.hide();var m=UI.modal(self,"Crédits","Générique",635,542);modal=m.root
	UI.copy(m.body,"SPOONFUL • Édition 1.0.0\nConcept maritime original de Fares. Affiche et panorama du ciel réalisés avec ChatGPT. Décors, personnages, effets, musique et bruitages créés pour ce jeu. Les voix utilisent une diction française synthétisée hors ligne.")
	UI.copy(m.body,"Moteur Godot 4.5.1 et composants distribués avec lui. Le texte de licence du moteur est reproduit ci-dessous.")
	UI.copy(m.body,Engine.get_license_text(),13)
	for entry in Engine.get_copyright_info():
		UI.text(m.body,str(entry.name),14,UI.GOLD)
	UI.button(m.footer,"Retour",clear_modal,true).grab_focus()

func _unhandled_input(e:InputEvent)->void:
	if e.is_action_pressed("ui_cancel") and is_instance_valid(modal):
		Voyage.apply_options();clear_modal();get_viewport().set_input_as_handled()
