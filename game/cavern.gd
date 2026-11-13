extends Node3D
const PALETTES := [Color("e8aa57"),Color("55d6e8"),Color("be8ef3")]
const ORE_COLORS := [Color("ffbc48"),Color("57e7ef"),Color("cc8bff"),Color("f6f2cc")]
var camera: Camera3D
var scenery: Node3D
var ore_root: Node3D
var links: Node3D
var effects: Node3D
var trajectory: Node3D
var drill: Node3D
var ore_nodes: Array[Node3D]=[]
var theme_index:=0
var materials: Dictionary={}
var models: Dictionary={}
var reduced_motion:=false
var tint:=PALETTES[0]

func _ready() -> void:
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("07141d")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("90a9c8");env.ambient_light_energy=0.34
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=env;add_child(world)
	var key:=DirectionalLight3D.new();key.rotation_degrees=Vector3(-56,-28,0);key.light_color=Color("d9e8ff");key.light_energy=0.72;key.shadow_enabled=true;add_child(key)
	var fill:=DirectionalLight3D.new();fill.rotation_degrees=Vector3(-25,145,0);fill.light_color=Color("89dbe6");fill.light_energy=0.25;add_child(fill)
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=17.0;camera.position=Vector3(0,18,12.8);add_child(camera);camera.look_at(Vector3(0,0,0.6));camera.current=true
	for key_name in ["scenery","ore_root","links","effects","trajectory"]:
		var node:=Node3D.new();node.name=key_name;add_child(node);set(key_name,node)
	drill=Node3D.new();add_child(drill)
	var base:=CylinderMesh.new();base.top_radius=0.27;base.bottom_radius=0.31;base.height=0.2;base.radial_segments=12
	mesh(drill,base,Vector3.ZERO,Color("dcebed"),0.2)
	var rim:=TorusMesh.new();rim.inner_radius=0.22;rim.outer_radius=0.3;rim.rings=16;rim.ring_segments=8
	mesh(drill,rim,Vector3(0,0.1,0),Color("62f1ed"),1.3)
	var tip:=CylinderMesh.new();tip.top_radius=0;tip.bottom_radius=0.18;tip.height=0.5;tip.radial_segments=6
	var pointed:=mesh(drill,tip,Vector3(0,0, -0.32),Color("f3ce7c"),0.1);pointed.rotation.x=-PI/2
	_crystal(drill,Vector3(0,0.15,0),1,0.28)
	for i in range(3):
		var angle:float=i*TAU/3.0
		var tab:=box(drill,Vector3(sin(angle)*0.23,0.17,cos(angle)*0.23),Vector3(0.12,0.05,0.1),Color("e5a544"));tab.rotation.y=angle

func material(color: Color, glow: float=0.0) -> StandardMaterial3D:
	var key:=str(color)+str(glow)
	if materials.has(key):return materials[key]
	var m:=StandardMaterial3D.new();m.albedo_color=color;m.roughness=0.7;m.metallic=0.18
	if glow>0:m.emission_enabled=true;m.emission=color;m.emission_energy_multiplier=glow
	materials[key]=m;return m

func mesh(parent: Node3D, shape: Mesh, at: Vector3, color: Color, glow: float=0.0) -> MeshInstance3D:
	var obj:=MeshInstance3D.new();obj.mesh=shape;obj.material_override=material(color,glow);obj.position=at;parent.add_child(obj);return obj

func box(parent: Node3D, at: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var shape:=BoxMesh.new();shape.size=size;return mesh(parent,shape,at,color)

func world(p: Vector2, height: float=0.4) -> Vector3:return Vector3(p.x,height,p.y-5.3)

func _bounds(node: Node3D, xform: Transform3D=Transform3D.IDENTITY) -> AABB:
	var bounds:=AABB();var first:=true
	for child in node.get_children():
		if not child is Node3D:continue
		var xf:Transform3D=xform*child.transform
		if child is MeshInstance3D:
			var a: AABB=xf*child.get_aabb()
			bounds=a if first else bounds.merge(a);first=false
		var sub:=_bounds(child,xf)
		if sub.size.length()>0:bounds=sub if first else bounds.merge(sub);first=false
	return bounds

func model(path: String, at: Vector3, desired: Vector3, rotation_y: float=0.0) -> Node3D:
	if not models.has(path):models[path]=load(path)
	var packed: PackedScene=models[path]
	var obj: Node3D=packed.instantiate()
	_recolor(obj,path)
	var bound:=_bounds(obj)
	var holder:=Node3D.new();scenery.add_child(holder);holder.add_child(obj)
	var scl:=Vector3(desired.x/maxf(bound.size.x,0.01),desired.y/maxf(bound.size.y,0.01),desired.z/maxf(bound.size.z,0.01))
	obj.scale=scl;obj.position=-(bound.position+Vector3(bound.size.x/2,0,bound.size.z/2))*scl
	holder.position=at;holder.rotation.y=rotation_y
	return holder

func _recolor(node: Node3D, path: String) -> void:
	if node is MeshInstance3D:
		for i in range(node.mesh.get_surface_count()):
			var original:Material=node.get_active_material(i)
			if not original is StandardMaterial3D:continue
			var mat:StandardMaterial3D=original.duplicate()
			mat.metallic=0.0;mat.roughness=0.95
			if path.contains("/nature/rock"):
				mat.albedo_color=Color("354650") if original.resource_name=="grass" else Color("566270")
				if theme_index==1:mat.albedo_color=mat.albedo_color.lerp(Color("365c68"),0.4)
				if theme_index==2:mat.albedo_color=mat.albedo_color.lerp(Color("51465f"),0.4)
			elif path.contains("template-floor"):
				mat.albedo_color=[Color("39484a"),Color("314c57"),Color("453e56")][theme_index]
			elif path.contains("/cave/"):
				mat.albedo_color=[Color("b5a18a"),Color("829b9b"),Color("96879e")][theme_index]
			node.set_surface_override_material(i,mat)
	for child in node.get_children():
		if child is Node3D:_recolor(child,path)

func clear(node: Node) -> void:
	for child in node.get_children():node.remove_child(child);child.queue_free()

func build(run: RefCounted, skin: int=0) -> void:
	theme_index=int(run.spec.theme);tint=PALETTES[theme_index]
	for node in [scenery,ore_root,links,effects,trajectory]:clear(node)
	ore_nodes.clear()
	# A real Kenney tiled cave floor with exposed strata and irregular rock shoulders.
	for x in range(-2,3):
		for z in range(-3,4):
			model("res://assets/cave/template-floor.glb",Vector3(x*1.95,-0.28,z*1.95),Vector3(2.05,0.35,2.05),PI*float(posmod(x+z,2)))
	for side in [-1,1]:
		for z in range(-3,4):
			model("res://assets/cave/template-wall-half.glb",Vector3(side*4.75,0,z*1.9),Vector3(1.4,0.9+0.22*posmod(z,3),2.12),side*PI/2)
			model("res://assets/nature/rock_largeA.glb" if z%2==0 else "res://assets/nature/rock_largeB.glb",Vector3(side*(5.15+0.2*cos(z)),0.2,z*2.0),Vector3(2.2,1.5+0.4*posmod(z,3),2.1),z*0.6)
			if z<2:
				model("res://assets/cave/template-floor-layer.glb",Vector3(side*5.1,-0.7,z*2.2),Vector3(3.1,0.75,2.5),side*PI/2)
	for x in range(-2,3):
		model("res://assets/cave/template-wall.glb",Vector3(x*2.0,0,-6.3),Vector3(2.0,1.8,1.3),0)
		model("res://assets/nature/rock_tallA.glb",Vector3(x*2.3,-0.1,-7.0),Vector3(2.4,3.5+sin(x)*0.8,2.4),x)
	# Dark playable inset, metallic rails and etched wall bounce markers.
	box(scenery,Vector3(0,-0.29,0.15),Vector3(8.1,0.12,10.6),Color("263031").lerp(tint,0.09))
	for side in [-1,1]:
		box(scenery,Vector3(side*4.02,0.17,0.1),Vector3(0.14,0.22,10.6),Color("a27648"))
		for z in range(-5,6):
			box(scenery,Vector3(side*3.97,0.31,z),Vector3(0.16,0.05,0.2),tint)
	box(scenery,Vector3(0,0.17,-5),Vector3(8.1,0.22,0.16),Color("a27648"))
	for z in range(-5,6):
		for x in [-3.8,3.8]:
			var crack:=BoxMesh.new();crack.size=Vector3(0.36,0.008,0.024)
			var slab:=mesh(scenery,crack,Vector3(x,0.04,z+0.2),Color("5b6159"));slab.rotation.y=z
	# Warm little workshop: deck, railway, ore cart, crane and lamp fixtures.
	model("res://assets/cave/stairs.glb",Vector3(0,-0.18,6.7),Vector3(3.0,0.65,1.8),0)
	for x in [-0.95,0.95]:box(scenery,Vector3(x,0.1,7.5),Vector3(0.1,0.12,3.4),Color("777f7b"))
	for z in range(6,10):box(scenery,Vector3(0,0.02,z),Vector3(2.3,0.1,0.18),Color("795633"))
	box(scenery,Vector3(-2.7,0.45,6.3),Vector3(1.5,0.65,1.05),Color("8c653f"))
	box(scenery,Vector3(-2.7,0.83,6.3),Vector3(1.6,0.12,1.1),Color("d1a259"))
	for x in [-3.25,-2.15]:
		for z in [5.85,6.75]:
			var wheel:=CylinderMesh.new();wheel.top_radius=0.26;wheel.bottom_radius=0.26;wheel.height=0.12;wheel.radial_segments=10
			var w:=mesh(scenery,wheel,Vector3(x,0.19,z),Color("323e43"));w.rotation.z=PI/2
	for j in range(7):_crystal(scenery,Vector3(-2.7+sin(j*2.3)*0.45,0.9,6.3+cos(j*2.3)*0.25),j%3,0.42)
	box(scenery,Vector3(2.7,1.1,6.6),Vector3(0.22,2.4,0.22),Color("8d6339"))
	box(scenery,Vector3(2.2,2.2,6.6),Vector3(1.2,0.18,0.2),Color("8d6339"))
	for side in [-1,1]:
		for z in [-4.3,1.0,5.0]:
			box(scenery,Vector3(side*4.65,1.3,z),Vector3(0.16,1.1,0.16),Color("563f2d"))
			var lamp:=SphereMesh.new();lamp.radius=0.2;lamp.height=0.4;lamp.radial_segments=8;lamp.rings=4
			mesh(scenery,lamp,Vector3(side*4.65,1.9,z),Color("ffce70"),2.0)
			var light:=OmniLight3D.new();light.position=Vector3(side*4.4,2,z);light.light_color=Color("ffc277");light.light_energy=0.45;light.omni_range=3.7;scenery.add_child(light)
	for j in range(12):
		var side:=1 if j%2==0 else -1
		var z: float=-5.0+float(j)*0.85
		if theme_index==1:model("res://assets/nature/mushroom_tanGroup.glb",Vector3(side*4.45,0.5,z),Vector3(0.7,0.7,0.6),j)
		elif theme_index==2:_crystal(scenery,Vector3(side*4.5,0.6,z),2,0.7)
		else:model("res://assets/nature/plant_bushSmall.glb",Vector3(side*4.45,0.45,z),Vector3(0.65,0.45,0.6),j)
	for b in run.spec.bumpers:
		var foot:=CylinderMesh.new();foot.top_radius=b.r;foot.bottom_radius=b.r+0.07;foot.height=0.3;foot.radial_segments=12
		mesh(scenery,foot,world(Vector2(b.x,b.y),0.18),Color("786653"))
		var ring:=TorusMesh.new();ring.inner_radius=b.r-0.08;ring.outer_radius=b.r+0.03;ring.rings=16;ring.ring_segments=8
		mesh(scenery,ring,world(Vector2(b.x,b.y),0.38),Color("efc47c"),0.6)
	for c in run.ore:
		var node:=Node3D.new();ore_root.add_child(node);node.position=world(Vector2(c.x,c.y),0.05)
		var socket:=CylinderMesh.new();socket.top_radius=0.38;socket.bottom_radius=0.42;socket.height=0.1;socket.radial_segments=6
		mesh(node,socket,Vector3.ZERO,Color("434747"))
		_crystal(node,Vector3(0,0.06,0),int(c.kind),0.78)
		_crystal(node,Vector3(0.23,0.06,0.13),int(c.kind),0.35)
		ore_nodes.append(node);node.visible=int(c.hp)>0
	for i in range(run.ore.size()):
		for j in range(i+1,run.ore.size()):
			var a:Dictionary=run.ore[i];var b:Dictionary=run.ore[j]
			if a.kind!=b.kind or int(a.hp)==0 or int(b.hp)==0:continue
			var p:=Vector2(a.x,a.y);var q:=Vector2(b.x,b.y)
			if p.distance_to(q)>1.1:continue
			var vein:=BoxMesh.new();vein.size=Vector3(0.035,0.025,p.distance_to(q))
			var line:=mesh(links,vein,world((p+q)/2,0.07),ORE_COLORS[a.kind].darkened(0.5),0.2)
			line.rotation.y=-atan2(q.x-p.x,q.y-p.y)
	var drill_color:Color=[Color("62f1ed"),Color("ffbd67"),Color("cd9bff")][clampi(skin,0,2)]
	drill.get_child(1).material_override=material(drill_color,1.2)
	drill.position=world(run.position,0.42)

func _crystal(parent: Node3D, at: Vector3, kind: int, size: float) -> Node3D:
	var prism:=CylinderMesh.new();prism.top_radius=0;prism.bottom_radius=size*0.38;prism.height=size;prism.radial_segments=[3,4,6,8][kind]
	var node:=mesh(parent,prism,at+Vector3(0,size/2,0),ORE_COLORS[kind],0.12)
	node.rotation.y=0.2+kind*0.3
	return node

func sync(run: RefCounted) -> void:
	drill.position=world(run.position,0.42)
	if run.moving:drill.rotation.y=-atan2(run.velocity.x,-run.velocity.y)
	for i in range(ore_nodes.size()):ore_nodes[i].visible=int(run.ore[i].hp)>0
	if run.moving:trajectory.visible=false

func show_preview(points: PackedVector2Array) -> void:
	clear(trajectory);trajectory.visible=true
	var s:=SphereMesh.new();s.radius=0.045;s.height=0.09;s.radial_segments=6;s.rings=3
	for i in range(points.size()):
		mesh(trajectory,s,world(points[i],0.45),Color("d4f8eb") if i<30 else Color("75a59b"),0.9)

func fracture(event: Dictionary) -> void:
	var color:Color=ORE_COLORS[int(event.get("kind",0))]
	var at:=world(event.at,0.45)
	for i in range(3 if reduced_motion else 6):
		var shard:=_crystal(effects,at, int(event.get("kind",0)),0.16)
		var end:=at+Vector3(sin(i*2.4)*0.6,0.3+0.1*i,cos(i*2.4)*0.6)
		var tween:=create_tween().set_parallel(true)
		tween.tween_property(shard,"position",end,0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(shard,"scale",Vector3.ZERO,0.5)
		tween.chain().tween_callback(shard.queue_free)
	if effects.get_child_count()>180:
		for i in range(20):effects.get_child(i).queue_free()

func screen_to_board(pos: Vector2) -> Vector2:
	var origin:=camera.project_ray_origin(pos);var normal:=camera.project_ray_normal(pos)
	var distance:float=(0.42-origin.y)/normal.y
	var point:=origin+normal*distance
	return Vector2(point.x,point.z+5.3)

func board_to_screen(pos: Vector2) -> Vector2:return camera.unproject_position(world(pos,0.42))
