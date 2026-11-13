extends RefCounted
const Chambers = preload("res://game/chambers.gd")
const ORIGIN := Vector2(0,10.35)
const SPEED := 12.0
const RADIUS := 0.18
var run_id := 0
var mode := "campaign"
var chamber := 0
var seed_value := 0
var day := 0
var depth := 1
var spec: Dictionary
var ore: Array = []
var gear := {"drill":0,"echo":0,"salvage":0}
var shots := 3
var used := 0
var score := 0
var crystals := 0
var stage_crystals := 0
var best_combo := 0
var chains := 0
var ricochets := 0
var shot_combo := 0
var position := ORIGIN
var velocity := Vector2.ZERO
var shot_time := 0.0
var moving := false
var done := false
var won := false
var continued := false
var stage_ready := false
var events: Array = []

func start(id: int, kind: String, index: int, equipment: Dictionary, today: int) -> void:
	run_id=id; mode=kind; chamber=clampi(index,0,29); day=today
	gear=equipment.duplicate(true)
	seed_value=today*7919+17 if mode=="daily" else 0
	if mode=="daily": chamber=posmod(today*13,30)
	_setup()

func _setup() -> void:
	spec=Chambers.make(chamber,seed_value)
	ore=spec.ore.duplicate(true); shots=int(spec.shots); stage_crystals=0
	position=ORIGIN; velocity=Vector2.ZERO; moving=false; stage_ready=false

func launch(direction: Vector2) -> bool:
	if moving or done or stage_ready or shots<=0 or not direction.is_finite() or direction.length()<0.01:return false
	var a := clampf(atan2(direction.x,-direction.y),-1.25,1.25)
	velocity=Vector2(sin(a),-cos(a))*SPEED
	position=ORIGIN; moving=true; shots-=1; used+=1; shot_time=0; shot_combo=0
	events.append({"type":"shot","at":position})
	return true

func step(delta: float) -> void:
	if not moving or done:return
	var left := minf(delta,0.1)
	while left>0.000001 and moving:
		var dt := minf(left,1.0/120.0)
		left-=dt; shot_time+=dt; position+=velocity*dt
		var bounced := false
		if position.x < -3.78: position.x=-3.78; velocity.x=absf(velocity.x); bounced=true
		if position.x > 3.78: position.x=3.78; velocity.x=-absf(velocity.x); bounced=true
		if position.y < 0.48: position.y=0.48; velocity.y=absf(velocity.y); bounced=true
		for b in spec.bumpers:
			var offset:=position-Vector2(b.x,b.y)
			var reach:=float(b.r)+RADIUS
			if offset.length()<reach:
				var normal:=offset.normalized() if offset.length()>0.001 else Vector2.DOWN
				position=Vector2(b.x,b.y)+normal*(reach+0.002)
				if velocity.dot(normal)<0:velocity=velocity.bounce(normal);bounced=true
		if bounced:
			ricochets+=1;events.append({"type":"ricochet","at":position})
		for i in range(ore.size()):
			var c: Dictionary=ore[i]
			if int(c.hp)>0 and position.distance_to(Vector2(c.x,c.y))<0.50:
				_fracture(i)
		if position.y>10.65 or shot_time>float(spec.flight)+float(gear.drill)*0.15 or remaining()==0: recall()

func _fracture(index: int) -> void:
	var queue: Array[int]=[index]
	var broken: Array[int]=[]
	while not queue.is_empty():
		var i: int=queue.pop_front()
		if int(ore[i].hp)<=0:continue
		ore[i].hp=0;broken.append(i)
		var source:=Vector2(ore[i].x,ore[i].y)
		for j in range(ore.size()):
			if int(ore[j].hp)<=0 or queue.has(j):continue
			var radius:=1.08+float(gear.echo)*0.06
			var same:=int(ore[i].kind)==int(ore[j].kind)
			if int(ore[i].kind)==3:radius=2.1;same=true
			if same and source.distance_to(Vector2(ore[j].x,ore[j].y))<=radius:queue.append(j)
	chains=maxi(chains,broken.size())
	for i in broken:
		crystals+=1;stage_crystals+=1;shot_combo+=1
		score+=100+mini(shot_combo-1,20)*25
		events.append({"type":"gem","at":Vector2(ore[i].x,ore[i].y),"kind":int(ore[i].kind),"index":i})
	best_combo=maxi(best_combo,shot_combo)
	if broken.size()>=4:events.append({"type":"chain","at":position,"count":broken.size()})

func recall() -> void:
	if not moving:return
	moving=false;velocity=Vector2.ZERO;position=ORIGIN
	if stage_crystals>=int(spec.goal):
		if mode=="endless":stage_ready=true
		elif remaining()==0 or shots<=0:done=true;won=true
	elif shots<=0:done=true;won=false
	events.append({"type":"return","at":position})

func next_depth() -> bool:
	if not stage_ready or mode!="endless" or done:return false
	depth+=1;chamber=posmod(chamber+7,30);seed_value=depth*917+31
	_setup();return true

func bank() -> void:
	if not moving:
		done=true;won=(depth>1 or stage_ready) if mode=="endless" else stage_crystals>=int(spec.goal)
		stage_ready=false

func continue_earned() -> bool:
	if not done or won or continued:return false
	continued=true;done=false;shots=2;return true

func remaining() -> int:
	var count:=0
	for c in ore:count+=int(int(c.hp)>0)
	return count

func stars() -> int:
	if not won:return 0
	if remaining()==0:return 3
	return 2 if stage_crystals>=ceili(ore.size()*0.88) else 1

func preview(direction: Vector2) -> PackedVector2Array:
	var points:=PackedVector2Array([ORIGIN])
	var a:=clampf(atan2(direction.x,-direction.y),-1.25,1.25)
	var p:=ORIGIN
	var v:=Vector2(sin(a),-cos(a))*SPEED
	var bounces:=0
	for s in range(ceili((float(spec.flight)+float(gear.drill)*0.15)*90.0)):
		p+=v/90.0
		var bounce:=false
		if absf(p.x)>3.78:p.x=clampf(p.x,-3.78,3.78);v.x=-v.x;bounce=true
		if p.y<0.48:p.y=0.48;v.y=absf(v.y);bounce=true
		for b in spec.bumpers:
			var offset:=p-Vector2(b.x,b.y)
			if offset.length()<float(b.r)+RADIUS:
				var normal:=offset.normalized()
				p=Vector2(b.x,b.y)+normal*(float(b.r)+RADIUS+0.002)
				if v.dot(normal)<0:v=v.bounce(normal);bounce=true
		if s%3==0:points.append(p)
		if bounce:bounces+=1
		if p.y>10.4 or bounces>=4:break
	return points

func snapshot() -> Dictionary:
	var out: Dictionary={}
	for key in ["run_id","mode","chamber","seed_value","day","depth","gear","shots","used","score","crystals","stage_crystals","best_combo","chains","ricochets","shot_combo","shot_time","moving","done","won","continued","stage_ready","ore"]:out[key]=get(key)
	out.position=[position.x,position.y];out.velocity=[velocity.x,velocity.y]
	return out.duplicate(true)

static func number(value: Variant, lo: float, hi: float) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=lo and float(value)<=hi

static func valid_snapshot(d: Variant) -> bool:
	if not d is Dictionary:return false
	for key in ["run_id","chamber","seed_value","day","depth","shots","used","score","crystals","stage_crystals","best_combo","chains","ricochets","shot_combo"]:
		if not number(d.get(key),0,1e12) or float(d[key])!=floor(float(d[key])):return false
	if not d.get("mode") in ["campaign","daily","endless"] or int(d.chamber)>29 or int(d.shots)>6 or int(d.depth)<1:return false
	for key in ["moving","done","won","continued","stage_ready"]:
		if not d.get(key) is bool:return false
	if (d.moving and d.done) or (d.won and not d.done) or (d.stage_ready and (d.moving or d.done or d.mode!="endless")):return false
	if not number(d.get("shot_time"),0,10):return false
	for key in ["position","velocity"]:
		if not d.get(key) is Array or d[key].size()!=2:return false
		for n in d[key]:
			if not number(n,-100,100):return false
	if not number(d.position[0],-3.9,3.9) or not number(d.position[1],0.3,10.7):return false
	var speed:=Vector2(d.velocity[0],d.velocity[1]).length()
	if d.moving and absf(speed-SPEED)>0.01:return false
	if not d.moving and speed>0.01:return false
	if not d.get("gear") is Dictionary:return false
	for key in ["drill","echo","salvage"]:
		if not number(d.gear.get(key),0,4) or float(d.gear[key])!=floor(float(d.gear[key])):return false
	if not d.get("ore") is Array or d.ore.size()>60 or d.ore.is_empty():return false
	var expected: Dictionary=Chambers.make(int(d.chamber),int(d.seed_value))
	if expected.ore.size()!=d.ore.size():return false
	for i in range(d.ore.size()):
		var c: Variant=d.ore[i]
		if not c is Dictionary:return false
		for key in ["x","y","kind"]:
			if not number(c.get(key),-10,20) or absf(float(c[key])-float(expected.ore[i][key]))>0.001:return false
		if not number(c.get("hp"),0,1) or float(c.hp)!=floor(float(c.hp)):return false
	return true

static func restore(d: Dictionary) -> RefCounted:
	var r=load("res://game/run.gd").new()
	for key in d:
		if key not in ["position","velocity"]:r.set(key,d[key])
	r.position=Vector2(d.position[0],d.position[1]);r.velocity=Vector2(d.velocity[0],d.velocity[1])
	r.spec=Chambers.make(r.chamber,r.seed_value)
	return r
