extends RefCounted
## Shared workshop prices and bounded model effects. Rank zero is the base game.
const KEYS := ["drill","echo","salvage","focus","prism","combo"]
const BASE_PRICES := {"drill":30,"echo":35,"salvage":40,"focus":30,"prism":35,"combo":40}
const TITLES := {"drill":"Longburn drill","echo":"Echo lens","salvage":"Salvage rig","focus":"Focus tip","prism":"Prism resonator","combo":"Combo calibrator"}
const DESCRIPTIONS := {
	"drill":"Keep the drill in flight longer before it returns.",
	"echo":"Link matching crystals across wider gaps.",
	"salvage":"Recover more ore per crystal. Later ranks also improve the haul's payout rate.",
	"focus":"Catch crystals with a wider contact margin.",
	"prism":"Let white prisms fracture crystals farther away.",
	"combo":"Earn more points from every crystal in a cascade."
}

static func cap(key:String) -> int:return 12 if key in KEYS else 0
static func bounded(rank:int) -> int:return clampi(rank,0,12)
static func price(key:String, rank:int) -> int:
	if key not in KEYS or rank<0 or rank>=cap(key):return 0
	return int(BASE_PRICES[key])+15*rank+3*rank*rank
static func title(key:String) -> String:return TITLES.get(key,key)
static func description(key:String) -> String:return DESCRIPTIONS.get(key,"")
static func normalize(gear:Dictionary) -> Dictionary:
	var out:Dictionary={}
	for key in KEYS:out[key]=bounded(int(gear.get(key,0)))
	return out
static func flight_bonus(rank:int) -> float:
	rank=bounded(rank);return min(rank,4)*0.15+max(rank-4,0)*0.06
static func echo_radius(rank:int) -> float:
	rank=bounded(rank);return 1.08+min(rank,4)*0.06+max(rank-4,0)*0.025
static func hit_radius(rank:int) -> float:return 0.50+bounded(rank)*0.01
static func prism_radius(rank:int) -> float:return 2.1+bounded(rank)*0.045
static func combo_multiplier(rank:int) -> float:return 1.0+bounded(rank)*0.01
## /4000: 20% through legacy rank4, then +0.625 percentage points per rank.
static func reward_numerator(rank:int) -> int:return 800+25*maxi(bounded(rank)-4,0)
static func effect_label(key:String, rank:int) -> String:
	match key:
		"drill":return "+%.2f seconds flight"%flight_bonus(rank)
		"echo":return "%.2f m matching reach"%echo_radius(rank)
		"salvage":return "Crystal salvage x%.2f"%((2.0+mini(bounded(rank),4))*reward_numerator(rank)/1600.0)
		"focus":return "%.2f m contact margin"%hit_radius(rank)
		"prism":return "%.2f m prism reach"%prism_radius(rank)
		"combo":return "+%d%% crystal score"%bounded(rank)
	return ""
static func next_effect_label(key:String, rank:int) -> String:
	return "Maximum rank" if rank>=cap(key) else effect_label(key,rank+1)
