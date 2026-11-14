extends SceneTree
## One-time preservation fixture, captured before the 200-chamber expansion.
## Refuses to overwrite an existing canonical fixture.
func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var destination:="res://tests/fixtures/campaign_legacy_v1.json"
	if FileAccess.file_exists(destination):
		push_error("Legacy fixture already exists; refusing to replace independent evidence")
		quit(2);return
	var chambers=load("res://game/chambers.gd")
	var fixtures:Array=[]
	for index in range(30):
		for seed_value in [0,1,158380017,948]:
			fixtures.append({"legacy_index":index,"current_index":index+int(index/10)*10,"seed":seed_value,"spec":chambers.make(index,seed_value)})
	var source:="res://game/chambers.gd"
	var report:Dictionary={"schema_version":1,"purpose":"Independent pre-expansion 30-chamber fixtures; expected values must not be regenerated from expanded content","source_sha256":FileAccess.get_sha256(source),"seeds":[0,1,158380017,948],"fixtures":fixtures}
	var file:=FileAccess.open(destination,FileAccess.WRITE)
	if file==null:push_error("Cannot write legacy fixture");quit(1);return
	file.store_string(JSON.stringify(report,"\t"));file.close()
	print("LEGACY FIXTURE CAPTURED ",fixtures.size()," cases; source SHA256 ",report.source_sha256)
	quit()
