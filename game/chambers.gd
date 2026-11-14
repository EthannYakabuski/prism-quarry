extends RefCounted
## Ten twenty-chamber biomes. Original geometry and seeded behavior are frozen.
const COUNT := 200
const BIOME_SIZE := 20
const THEMES := ["Amber Hollow","Azure Grotto","Violet Vault","Copper Foundry","Jade Canopy","Frostglass Caverns","Ember Rift","Moonstone Archive","Obsidian Crown","Prismatic Depths"]
const Legacy = preload("res://game/chambers_legacy.gd")
const Expansion = preload("res://game/chamber_expansion_data.gd")
const NAMES = Expansion.NAMES

static func legacy_to_current(index: int) -> int:
	var old_index := clampi(index, 0, 29)
	return old_index + (old_index / 10) * 10

static func make(index: int, seed_value: int = 0) -> Dictionary:
	index = clampi(index, 0, COUNT - 1)
	var biome := index / BIOME_SIZE
	var local := index % BIOME_SIZE
	var spec: Dictionary
	if biome < 3 and local < 10:
		spec = Legacy.make(biome * 10 + local, seed_value)
		spec.index = index
		spec.biome_local = local
		spec.motif = "legacy_%02d" % (biome * 10 + local)
		spec.authored_id = "legacy-%02d" % (biome * 10 + local + 1)
		return spec
	spec = Expansion.LEVELS[index].duplicate(true)
	if seed_value != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var mirror := rng.randi_range(0, 1) == 1
		var color_shift := rng.randi_range(0, 2)
		for crystal in spec.ore:
			if mirror: crystal.x = -float(crystal.x)
			if int(crystal.kind) < 3:
				crystal.kind = (int(crystal.kind) + color_shift) % 3
		for bumper in spec.bumpers:
			if mirror: bumper.x = -float(bumper.x)
	spec.seed = seed_value
	return spec
