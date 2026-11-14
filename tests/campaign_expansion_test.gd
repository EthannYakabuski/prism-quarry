extends SceneTree
## Deterministic baseline acceptance for the 200-chamber campaign.
## Candidate coverage comes from actual Run.launch/step, not geometric guesses.
## A bounded planning search chooses angles; every reported solution is replayed
## through real Run physics and must actually finish with three stars.
const Run=preload("res://game/run.gd")
const Chambers=preload("res://game/chambers.gd")
const GEAR={"drill":0,"echo":0,"salvage":0,"focus":0,"prism":0,"combo":0}
const REPORT_PATH="res://build/evidence/campaign-expansion.json"
const FIXTURE_PATH="res://tests/fixtures/campaign_legacy_v1.json"
const MAX_SECONDS=540.0
var checks:=0
var failures:Array[String]=[]
var levels:Array=[]
var started:=0
var candidates_simulated:=0
var timed_out:=false
var source_hashes:Dictionary={}

func _initialize() -> void:call_deferred("execute")

func check(value:bool, message:String) -> void:
	checks+=1
	if not value:
		failures.append(message)
		push_error(message)

func near_equal(a:Variant,b:Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float):return absf(float(a)-float(b))<0.000000001
	if a is Array and b is Array:
		if a.size()!=b.size():return false
		for i in range(a.size()):
			if not near_equal(a[i],b[i]):return false
		return true
	if a is Dictionary and b is Dictionary:
		if a.size()!=b.size():return false
		for key in a:
			if not b.has(key) or not near_equal(a[key],b[key]):return false
		return true
	return a==b

func new_run(index:int) -> RefCounted:
	var r:=Run.new()
	r.start(index+1,"campaign",index,GEAR,20000)
	return r

func finish_shot(r:RefCounted) -> bool:
	for tick in range(720):
		if not r.moving:return true
		r.step(1.0/60.0)
		r.events.clear()
	return not r.moving

func shoot(r:RefCounted,angle:float) -> bool:
	if not r.launch(Vector2(sin(deg_to_rad(angle)),-cos(deg_to_rad(angle)))):return false
	return finish_shot(r)

func mask_for(r:RefCounted) -> int:
	var mask:=0
	for i in range(r.ore.size()):
		if int(r.ore[i].hp)==0:mask|=1<<i
	return mask

func popcount(mask:int) -> int:
	var count:=0
	while mask!=0:
		mask&=mask-1
		count+=1
	return count

func candidates(index:int,step:float,existing:Array=[]) -> Array:
	var result:Array=existing.duplicate()
	var seen_angles:Dictionary={}
	var best_masks:Dictionary={}
	for entry in result:
		seen_angles[snappedf(float(entry.angle),0.001)]=true
		best_masks[int(entry.mask)]=entry
	var count:=int(round(142.0/step))
	for i in range(count+1):
		var angle:float=-71.0+i*step
		if seen_angles.has(snappedf(angle,0.001)):continue
		var r:RefCounted=new_run(index)
		var ended:=shoot(r,angle)
		candidates_simulated+=1
		if not ended:continue
		var mask:=mask_for(r)
		if mask==0:continue
		var entry:Dictionary={"angle":angle,"mask":mask,"crystals":r.crystals,"score":r.score,"ricochets":r.ricochets}
		# Identical coverage requires only one representative angle. Prefer the
		# gentler direction, keeping routes readable and deterministic.
		if not best_masks.has(mask) or absf(angle)<absf(float(best_masks[mask].angle)):best_masks[mask]=entry
		if elapsed()>MAX_SECONDS:timed_out=true;break
	result=best_masks.values()
	result.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
		if a.crystals!=b.crystals:return int(a.crystals)>int(b.crystals)
		if absf(float(a.angle))!=absf(float(b.angle)):return absf(float(a.angle))<absf(float(b.angle))
		return float(a.angle)<float(b.angle))
	return result

func plan(candidates_list:Array,all_mask:int,budget:int) -> Array:
	var frontier:Array=[{"mask":0,"angles":[]}]
	for depth in range(budget):
		var next_states:Dictionary={}
		for state in frontier:
			for candidate in candidates_list:
				var combined:int=int(state.mask)|int(candidate.mask)
				if combined==int(state.mask):continue
				var sequence:Array=state.angles.duplicate();sequence.append(float(candidate.angle))
				if combined==all_mask:return sequence
				if not next_states.has(combined):next_states[combined]={"mask":combined,"angles":sequence,"count":popcount(combined)}
		if next_states.is_empty():break
		frontier=next_states.values()
		frontier.sort_custom(func(a:Dictionary,b:Dictionary)->bool:
			if a.count!=b.count:return int(a.count)>int(b.count)
			return str(a.angles)<str(b.angles))
		if frontier.size()>48:frontier.resize(48)
	return []

func replay(index:int,angles:Array,seeded_daily:bool=false) -> Dictionary:
	var r:RefCounted=new_run(index)
	var direction_multiplier:=1.0
	if seeded_daily:
		# 77 is the modular inverse of 13 mod 200, so this goes through the
		# real daily start path and selects each chamber exactly once.
		var today:int=20000+posmod(index*77,200)
		var base:Dictionary=r.spec
		r.start(index+1001,"daily",index,GEAR,today)
		check(r.chamber==index,"real daily selector covers chamber %d"%index)
		for i in range(base.ore.size()):
			if absf(float(base.ore[i].x))>0.001:
				direction_multiplier=-1.0 if signf(float(base.ore[i].x))!=signf(float(r.ore[i].x)) else 1.0
				break
	var shots:Array=[]
	for angle in angles:
		var actual_angle:float=float(angle)*direction_multiplier
		var before:int=r.crystals
		var before_score:int=r.score
		var before_bounces:int=r.ricochets
		if not shoot(r,actual_angle):return {"won":false,"stars":0,"reason":"launch or bounded flight failed","shots":shots}
		shots.append({"angle_degrees":actual_angle,"new_crystals":r.crystals-before,"new_score":r.score-before_score,"ricochets":r.ricochets-before_bounces})
		if r.done:break
	return {"mode":r.mode,"day":r.day,"seed":r.seed_value,"mirrored":direction_multiplier<0,"won":r.won,"stars":r.stars(),"crystals":r.crystals,"total_crystals":r.ore.size(),"score":r.score,"shots_used":r.used,"shot_budget":r.spec.shots,"best_combo":r.best_combo,"largest_chain":r.chains,"ricochets":r.ricochets,"snapshot_valid":Run.valid_snapshot(r.snapshot()),"shots":shots}

func fixed_strategy(index:int,angle:float) -> Dictionary:
	var r:RefCounted=new_run(index)
	for i in range(int(r.spec.shots)):
		if r.done:break
		if not shoot(r,angle):break
	return {"won":r.won,"stars":r.stars(),"crystals":r.crystals,"shots":r.used,"score":r.score}

func geometry_key(spec:Dictionary,coarse:bool=false) -> String:
	var variants:Array[String]=[]
	for mirror in [1.0,-1.0]:
		var ore:Array[String]=[];var bumpers:Array[String]=[]
		for c in spec.ore:
			if coarse:ore.append("%d,%d"%[roundi(float(c.x)*mirror/0.5),roundi(float(c.y)/0.5)])
			else:ore.append("%.6f,%.6f"%[float(c.x)*mirror,float(c.y)])
		for b in spec.bumpers:
			if coarse:bumpers.append("%d,%d,%d"%[roundi(float(b.x)*mirror/0.5),roundi(float(b.y)/0.5),roundi(float(b.r)/0.2)])
			else:bumpers.append("%.6f,%.6f,%.6f"%[float(b.x)*mirror,float(b.y),float(b.r)])
		ore.sort();bumpers.sort()
		variants.append(";".join(ore)+"|"+";".join(bumpers))
	variants.sort()
	return variants[0]

func validate_legacy() -> void:
	var fixture:Variant=JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	check(fixture is Dictionary and fixture.get("fixtures",[]).size()==120,"independent legacy fixture has 120 cases")
	if not fixture is Dictionary:return
	for item in fixture.fixtures:
		var mapped:int=Chambers.legacy_to_current(int(item.legacy_index))
		check(mapped==int(item.current_index),"legacy index mapping %d"%int(item.legacy_index))
		var actual:Dictionary=Chambers.make(mapped,int(item.seed))
		var ok:=true
		for key in ["name","theme","ore","bumpers","shots","goal","flight","seed"]:
			if not actual.has(key) or not near_equal(actual[key],item.spec[key]):ok=false
		check(ok,"exact preserved legacy chamber %d seed %d"%[int(item.legacy_index),int(item.seed)])
		check(int(actual.index)==mapped,"preserved chamber reports mapped index %d"%mapped)

func validate_structure() -> Dictionary:
	check(Chambers.COUNT==200 and Chambers.BIOME_SIZE==20,"200 chambers with 20 per biome")
	check(Chambers.THEMES.size()==10,"ten biome names")
	check(Chambers.NAMES.size()==200,"200 authored chamber names")
	var names:Dictionary={};var geometry:Dictionary={};var coarse:Dictionary={};var motifs:Dictionary={};var per_biome:Array=[]
	var legacy_indices:Dictionary={}
	for old in range(30):legacy_indices[Chambers.legacy_to_current(old)]=true
	for biome in range(10):per_biome.append({"biome":biome,"name":Chambers.THEMES[biome],"count":0,"motifs":{},"ore_count":0,"bumpers":0})
	for index in range(Chambers.COUNT):
		var spec:Dictionary=Chambers.make(index,0)
		check(int(spec.index)==index and int(spec.theme)==int(index/20),"index and biome mapping %d"%index)
		check(not names.has(spec.name),"unique authored name %d"%index);names[spec.name]=index
		check(spec.ore.size()>0 and spec.ore.size()<=60,"bounded crystal count %d"%index)
		check(int(spec.shots)>=3 and int(spec.shots)<=6 and float(spec.flight)>=0.6 and float(spec.flight)<=5,"bounded baseline budget %d"%index)
		check(int(spec.goal)>0 and int(spec.goal)<=spec.ore.size(),"reachable quota range %d"%index)
		var centers:Dictionary={};var bounds_ok:=true;var bumper_ok:=true;var no_buried_ore:=true;var separated_ore:=true;var separated_bumpers:=true
		for c in spec.ore:
			var key:="%.6f,%.6f"%[float(c.x),float(c.y)]
			if centers.has(key):bounds_ok=false
			centers[key]=true
			if not is_finite(float(c.x)) or not is_finite(float(c.y)) or absf(float(c.x))>3.5 or float(c.y)<0.9 or float(c.y)>9.3 or int(c.kind)<0 or int(c.kind)>3 or int(c.hp)!=1:bounds_ok=false
			if not legacy_indices.has(index):
				for b in spec.bumpers:
					if Vector2(c.x,c.y).distance_to(Vector2(b.x,b.y))<float(b.r)+0.12:no_buried_ore=false
		for b in spec.bumpers:
			if not is_finite(float(b.x)) or not is_finite(float(b.y)) or not is_finite(float(b.r)) or float(b.r)<0.15 or float(b.r)>1.2 or absf(float(b.x))+float(b.r)>3.7 or float(b.y)-float(b.r)<0.45 or float(b.y)+float(b.r)>9.3:bumper_ok=false
		for i in range(spec.ore.size()):
			for j in range(i+1,spec.ore.size()):
				if Vector2(spec.ore[i].x,spec.ore[i].y).distance_to(Vector2(spec.ore[j].x,spec.ore[j].y))<0.4:separated_ore=false
		for i in range(spec.bumpers.size()):
			for j in range(i+1,spec.bumpers.size()):
				if Vector2(spec.bumpers[i].x,spec.bumpers[i].y).distance_to(Vector2(spec.bumpers[j].x,spec.bumpers[j].y))<float(spec.bumpers[i].r)+float(spec.bumpers[j].r)+0.05:separated_bumpers=false
		check(bounds_ok,"unique finite in-board crystals %d"%index)
		check(bumper_ok,"in-board safe bumper geometry %d"%index)
		check(no_buried_ore,"new crystal centers not buried inside bumpers %d"%index)
		check(separated_ore,"crystal bodies do not overlap %d"%index)
		check(separated_bumpers,"bumper bodies do not overlap %d"%index)
		var key:=geometry_key(spec)
		check(not geometry.has(key),"physical geometry unique ignoring color and mirror %d (prior %s)"%[index,str(geometry.get(key,"none"))]);geometry[key]=index
		var seeded:Dictionary=Chambers.make(index,948)
		check(near_equal(seeded,Chambers.make(index,948)),"seeded chamber deterministic %d"%index)
		check(geometry_key(seeded)==key,"seed preserves physical layout up to mirror %d"%index)
		var isolated:Dictionary=Chambers.make(index,0)
		isolated.ore[0].hp=0;isolated.ore[0].x=99
		if not isolated.bumpers.is_empty():isolated.bumpers[0].r=99
		check(near_equal(spec,Chambers.make(index,0)),"factory returns independent deep copies %d"%index)
		coarse[geometry_key(spec,true)]=true
		var motif:String=spec.get("motif","missing")
		if not legacy_indices.has(index):motifs[motif]=true
		var biome:int=int(index/20)
		per_biome[biome].count+=1;per_biome[biome].motifs[motif]=true;per_biome[biome].ore_count+=spec.ore.size();per_biome[biome].bumpers+=spec.bumpers.size()
	check(motifs.size()>=10 and not motifs.has("missing"),"at least ten explicit new layout motifs")
	check(coarse.size()>=175,"coarse occupancy geometry is varied beyond tiny coordinate jitter")
	for biome in per_biome:
		check(biome.count==20,"twenty chambers in "+biome.name)
		check(biome.motifs.size()>=8,"at least eight motif families in "+biome.name)
	return {"exact_mirror_color_invariant_geometries":geometry.size(),"coarse_half_unit_geometries":coarse.size(),"new_motifs":motifs.keys(),"biomes":per_biome}

func elapsed() -> float:return (Time.get_ticks_msec()-started)/1000.0

func section_summary(from:int,to:int) -> Dictionary:
	var result:Dictionary={"from_chamber":from+1,"through_chamber":to,"levels":0,"solved":0,"three_stars":0,"shots_sum":0,"budget_sum":0,"max_solution_shots":0,"solution_shot_histogram":{},"multi_shot":0,"repeated_straight_wins":0,"repeated_minus70_wins":0,"crystals_sum":0,"score_sum":0}
	for item in levels:
		if int(item.index)<from or int(item.index)>=to:continue
		result.levels+=1;result.solved+=int(item.solution.won);result.three_stars+=int(item.solution.stars==3)
		result.shots_sum+=int(item.solution.get("shots_used",0));result.multi_shot+=int(int(item.solution.get("shots_used",0))>=2)
		result.budget_sum+=int(item.solution.get("shot_budget",0));result.max_solution_shots=maxi(int(result.max_solution_shots),int(item.solution.get("shots_used",0)))
		var shots_key:=str(item.solution.get("shots_used",0))
		result.solution_shot_histogram[shots_key]=int(result.solution_shot_histogram.get(shots_key,0))+1
		result.repeated_straight_wins+=int(item.straight.won);result.repeated_minus70_wins+=int(item.sweep.won)
		result.crystals_sum+=int(item.solution.get("crystals",0));result.score_sum+=int(item.solution.get("score",0))
	result.average_solution_shots=float(result.shots_sum)/maxi(1,int(result.levels))
	result.average_shot_budget=float(result.budget_sum)/maxi(1,int(result.levels))
	return result

func write_report(structure:Dictionary,complete:bool) -> void:
	var samples:Dictionary={}
	for item in levels:
		if int(item.chamber) in [1,21,101,161,200]:samples[str(item.chamber)]={"name":item.name,"angles_degrees":item.angles_degrees,"solution":item.solution}
	var biomes:Array=[]
	for biome in range(10):
		var summary:=section_summary(biome*20,(biome+1)*20);summary.name=Chambers.THEMES[biome];biomes.append(summary)
	var report:Dictionary={"checks":checks,"failures":failures,"complete":complete,"timed_out":timed_out,"elapsed_seconds":elapsed(),"candidate_shots_simulated":candidates_simulated,"baseline_gear":GEAR,"source_sha256":source_hashes,"evidence_kind":"Deterministic actual Run physics fixtures; algorithmic solvability and sampled difficulty, not human difficulty or minimum-shot proof","structure":structure,"early":section_summary(0,60),"middle":section_summary(60,140),"late":section_summary(140,200),"biome_summaries":biomes,"manual_play_samples":samples,"levels":levels}
	DirAccess.make_dir_recursive_absolute("res://build/evidence")
	var output:=FileAccess.open(REPORT_PATH,FileAccess.WRITE)
	if output==null:check(false,"could not write campaign evidence report");return
	output.store_string(JSON.stringify(report,"\t"));output.close()

func execute() -> void:
	started=Time.get_ticks_msec()
	for source in ["res://game/chambers.gd","res://game/chambers_legacy.gd","res://game/chamber_expansion_data.gd","res://game/campaign_blueprints.json","res://game/run.gd","res://game/upgrades.gd",FIXTURE_PATH,"res://tests/campaign_expansion_test.gd"]:
		source_hashes[source]=FileAccess.get_sha256(source)
	validate_legacy()
	var structure:=validate_structure()
	for index in range(Chambers.COUNT):
		var spec:Dictionary=Chambers.make(index,0)
		var all_mask:int=(1<<spec.ore.size())-1
		var options:=candidates(index,2.0)
		var angles:=plan(options,all_mask,int(spec.shots))
		var solution:=replay(index,angles)
		var resolution:=2.0
		if solution.stars!=3 and not timed_out:
			resolution=0.5;options=candidates(index,0.5,options)
			angles=plan(options,all_mask,int(spec.shots));solution=replay(index,angles)
		if solution.stars!=3 and not timed_out:
			resolution=0.25;options=candidates(index,0.25,options)
			angles=plan(options,all_mask,int(spec.shots));solution=replay(index,angles)
		check(bool(solution.won) and int(solution.stars)==3,"actual baseline three-star completion chamber %d"%(index+1))
		check(int(solution.get("shots_used",999))<=int(spec.shots),"actual solution respects shot budget chamber %d"%(index+1))
		check(bool(solution.get("snapshot_valid",false)),"valid actual solved snapshot chamber %d"%(index+1))
		var seeded:=replay(index,angles,true)
		check(bool(seeded.won) and int(seeded.stars)==3 and bool(seeded.get("snapshot_valid",false)),"actual seeded daily three-star replay chamber %d"%(index+1))
		check(int(seeded.get("score",-1))==int(solution.get("score",-2)),"mirror/color daily seed preserves solved score chamber %d"%(index+1))
		var straight:=fixed_strategy(index,0)
		var sweep:=fixed_strategy(index,-70)
		levels.append({"index":index,"chamber":index+1,"biome":int(spec.theme),"name":spec.name,"motif":spec.get("motif","legacy_authored"),"angle_resolution_degrees":resolution,"angles_degrees":angles,"solution":solution,"seeded_daily":seeded,"straight":straight,"sweep":sweep})
		if (index+1)%10==0:
			print("CAMPAIGN PROGRESS ",index+1,"/",Chambers.COUNT,"; failures=",failures.size(),"; seconds=",snappedf(elapsed(),0.1))
			write_report(structure,false)
		if timed_out or elapsed()>MAX_SECONDS:timed_out=true;check(false,"campaign solver exceeded bounded time budget");break
	var early:=section_summary(0,60);var late:=section_summary(140,200)
	check(levels.size()==200,"solver exercised every campaign chamber")
	if levels.size()==200:
		check(int(late.multi_shot)>=35,"late campaign usually needs distinct aimed shots for three stars")
		check(float(late.average_solution_shots)>=float(early.average_solution_shots)+0.25,"late sampled solution effort exceeds early campaign")
		check(int(late.repeated_straight_wins)<=20 and int(late.repeated_minus70_wins)<=20,"fixed repeated angles cannot clear most late chambers")
	for source in source_hashes:
		check(FileAccess.get_sha256(source)==source_hashes[source],"tested source stayed stable: "+source)
	write_report(structure,levels.size()==200)
	print("CAMPAIGN EXPANSION: ",checks," checks; ",failures.size()," failures; ",levels.size()," chambers; ",snappedf(elapsed(),0.1)," seconds")
	quit(0 if failures.is_empty() else 1)
