extends RefCounted

const RAD = [0.0,5.0,14.0,23.0,34.0,45.0,55.0,64.0,72.0,77.0,82.0,90.0,104.0,150.0]
const ELEV = [-11.8,-10.95,-8.65,-7.0,-5.15,-2.9,-0.65,1.05,2.68,3.9,4.9,5.55,6.3,6.6]

static func ground(x:float,z:float)->float:
	var radius=sqrt(x*x+z*z)
	var angle=atan2(z,x)
	var r=radius+(sin(angle*3.0+0.4)*1.8+sin(angle*6.0)*0.9)*clampf(radius/20.0,0.0,1.0)
	var i=0
	while i<RAD.size()-2 and r>RAD[i+1]:i+=1
	var t=clampf((r-RAD[i])/(RAD[i+1]-RAD[i]),0,1)
	var y=lerpf(ELEV[i],ELEV[i+1],t)
	# The northern headlands open onto the same water plane as the navigable cove.
	var mouth:=smoothstep(21.,89.,-z)*(1.-smoothstep(39.,87.,absf(x+.12*z)))
	y=lerpf(y,minf(y,-9.94+.22*cos(x*.06)),mouth)
	return y+0.17*sin(x*0.16+z*0.025)*cos(z*0.155)+0.08*sin(z*0.39+x*0.12)

static func place(x:float,z:float,offset:=0.0)->Vector3:
	return Vector3(x,ground(x,z)+offset,z)

static func terrain(parent:Node3D)->Array:
	var ngrid=112
	var verts=PackedVector3Array()
	var normals=PackedVector3Array()
	var indices=PackedInt32Array()
	for j in ngrid+1:
		for i in ngrid+1:
			var x=-104.0+208.0*i/ngrid
			var z=-104.0+208.0*j/ngrid
			verts.append(place(x,z))
			normals.append(Vector3(ground(x-0.25,z)-ground(x+0.25,z),0.5,ground(x,z-0.25)-ground(x,z+0.25)).normalized())
			if i<ngrid and j<ngrid:
				var a=j*(ngrid+1)+i
				indices.append_array(PackedInt32Array([a,a+1,a+ngrid+1,a+1,a+ngrid+2,a+ngrid+1]))
	var arrays=[]
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=verts
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh=ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var sand=ShaderMaterial.new()
	sand.shader=preload("res://shaders/sand.gdshader")
	var land=MeshInstance3D.new()
	land.mesh=mesh
	land.material_override=sand
	parent.add_child(land)
	var img=Image.create_empty(192,192,false,Image.FORMAT_RF)
	for j in 192:
		for i in 192:
			var h=ground((i+0.5)/192.0*208.0-104.0,(j+0.5)/192.0*208.0-104.0)
			img.set_pixel(i,j,Color((h+15.0)/32.0,0,0))
	var sea=ShaderMaterial.new()
	sea.shader=preload("res://shaders/sea.gdshader")
	sea.set_shader_parameter("relief",ImageTexture.create_from_image(img))
	var plane=PlaneMesh.new()
	plane.size=Vector2(370,370)
	plane.subdivide_width=75
	plane.subdivide_depth=75
	var water=MeshInstance3D.new()
	water.mesh=plane
	water.material_override=sea
	water.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(water)
	return [water,sea,sand]
