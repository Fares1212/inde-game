extends SceneTree
const ART=preload("res://scripts/treasure.gd")
func _initialize()->void:call_deferred("bake")
func bake()->void:
	var stage:=SubViewport.new();stage.size=Vector2i(960,800);stage.own_world_3d=true;stage.transparent_bg=true
	stage.render_target_update_mode=SubViewport.UPDATE_ALWAYS;root.add_child(stage)
	var backdrop:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_CLEAR_COLOR
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("#fff0d9");env.ambient_light_energy=.74
	backdrop.environment=env;stage.add_child(backdrop)
	var camera:=Camera3D.new();stage.add_child(camera);camera.position=Vector3(3.2,4.4,7.5);camera.look_at(Vector3.ZERO);camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=5.;camera.current=true
	var light:=DirectionalLight3D.new();stage.add_child(light);light.rotation_degrees=Vector3(-48,-36,0);light.light_energy=1.2
	var catalog:Resource=load("res://resources/mer.tres")
	for index in catalog.items.size():
		var obj:=Node3D.new();stage.add_child(obj)
		ART.make(obj,catalog.items[index])
		obj.position=camera.global_basis.x*(index%6-2.5)+camera.global_basis.y*(2.-floorf(index/6.))-Vector3.UP*.22
	for i in 5:await process_frame
	await RenderingServer.frame_post_draw
	var sheet:=stage.get_texture().get_image()
	sheet.save_png(ProjectSettings.globalize_path("res://art/market/trouvailles.png"))
	quit()
