extends SceneTree
## Evaluate real model payout functions against the completed 200-level solver receipt.
const Profile=preload("res://game/profile.gd")
const Run=preload("res://game/run.gd")
const Upgrades=preload("res://game/upgrades.gd")
const Chambers=preload("res://game/chambers.gd")
func _initialize() -> void:call_deferred("execute")
func execute() -> void:
	var source:="res://build/evidence/campaign-expansion.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--campaign-report="):source=argument.trim_prefix("--campaign-report=")
	var campaign:Variant=Profile.read_json(source)
	if not campaign is Dictionary or not campaign.get("complete",false) or not campaign.get("failures",["missing"]).is_empty() or campaign.get("levels",[]).size()!=Chambers.COUNT:
		push_error("A complete passing 200-level baseline solver report is required.");quit(2);return
	var rows:Array=[];var totals:Dictionary={"legacy_salvage0":0,"new_salvage0":0,"legacy_salvage4":0,"new_salvage4":0,"new_salvage12":0}
	for level in campaign.levels:
		var solution:Dictionary=level.solution
		if not solution.won or solution.stars!=3:push_error("Baseline solution missing");quit(2);return
		var run:=Run.new();run.start(int(level.index)+1,"campaign",int(level.index),{},20000)
		run.crystals=int(solution.crystals);run.score=int(solution.score);run.used=int(solution.shots_used);run.won=true;run.done=true
		var row:Dictionary={"chamber":level.chamber,"crystals":run.crystals,"score":run.score,"shots_used":run.used,
			"legacy_salvage0":Profile.legacy_completion_coins(run,0,false),"new_salvage0":Profile.completion_coins(run,0,false),
			"legacy_salvage4":Profile.legacy_completion_coins(run,4,false),"new_salvage4":Profile.completion_coins(run,4,false),"new_salvage12":Profile.completion_coins(run,12,false)}
		assert(row.new_salvage0<=int(row.legacy_salvage0/4) and row.new_salvage12<=int(row.legacy_salvage4/4))
		rows.append(row)
		for key in totals:totals[key]+=int(row[key])
	var prices:Dictionary={};var all_cost:=0
	for key in Upgrades.KEYS:
		var tiers:Array=[];var sum:=0
		for rank in range(Upgrades.cap(key)):tiers.append(Upgrades.price(key,rank));sum+=Upgrades.price(key,rank)
		prices[key]={"title":Upgrades.title(key),"tiers":tiers,"all_tiers_cost":sum,"maximum_effect":Upgrades.effect_label(key,12)};all_cost+=sum
	var segments:Array=[]
	for span in [[0,20],[90,110],[180,200]]:
		var sum:=0;var minimum:=1000000;var maximum:=0
		for i in range(span[0],span[1]):sum+=rows[i].new_salvage0;minimum=mini(minimum,rows[i].new_salvage0);maximum=maxi(maximum,rows[i].new_salvage0)
		segments.append({"from_chamber":span[0]+1,"through_chamber":span[1],"base_ore_total":sum,"base_ore_mean":sum/float(span[1]-span[0]),"minimum":minimum,"maximum":maximum})
	var balanced:=simulate(rows,false);var focused:=simulate(rows,true)
	var report:Dictionary={"result":"PASS - actual payout functions applied to recorded baseline 3-star solutions","campaign_report_sha256":FileAccess.get_sha256(source),"campaign_source_sha256":campaign.get("source_sha256",{}),"levels":Chambers.COUNT,
		"comparison":"Same recorded crystals, score, win and daily entitlement. Historical salvage is capped at its legal rank4. New salvage5-12 retains20.625%-25% of that capped historical total. Every per-run integer payout is <=floor(legacy/4).",
		"totals":totals,"segments":segments,"upgrades":prices,"all_72_ranks_cost":all_cost,"login_cycle":[10,13,16,19,22,25,28],"quest_coins_each":Profile.QUEST_COINS,
		"balanced_purchase_benchmark":balanced,"focused_drill_benchmark":focused,
		"benchmark_scope":"Fresh player, first login gift only, one baseline 3-star clear per level; no ads, replays, daily or quest income. Recorded score/crystals held fixed, even after upgrades; this is spending analysis, not another physics simulation.","rows":rows}
	var file:=FileAccess.open("res://build/evidence/economy-expansion.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	print("ECONOMY REPORT: ",JSON.stringify({"levels":Chambers.COUNT,"totals":totals,"all_ranks_cost":all_cost,"segments":segments,"balanced":balanced,"focused":focused}))
	quit(0)

func simulate(rows:Array, focused:bool) -> Dictionary:
	var gear:=Upgrades.normalize({});var coins:=Profile.login_reward(1);var first_purchase:=0;var full_drill:=0;var checkpoints:Array=[]
	for i in range(rows.size()):
		var run:=Run.new();run.crystals=rows[i].crystals;run.score=rows[i].score;run.used=rows[i].shots_used;run.won=true
		coins+=Profile.completion_coins(run,int(gear.salvage),false)
		while true:
			var choice:="";var cost:=1000000
			for key in (["drill"] if focused else Upgrades.KEYS):
				var next:=Upgrades.price(key,int(gear[key]))
				if next>0 and next<cost:choice=key;cost=next
			if choice.is_empty() or cost>coins:break
			coins-=cost;gear[choice]+=1
			if first_purchase==0:first_purchase=i+1
			if int(gear.drill)==12 and full_drill==0:full_drill=i+1
		if i+1 in [20,100,200]:checkpoints.append({"after_chamber":i+1,"coins":coins,"ranks":gear.duplicate(true)})
	return {"first_purchase_after_chamber":first_purchase,"drill_rank12_after_chamber":full_drill,"final_coins":coins,"final_ranks":gear,"checkpoints":checkpoints}
