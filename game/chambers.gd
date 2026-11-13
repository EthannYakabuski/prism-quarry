extends RefCounted
## Authored crystal maps. Every row/bumper placement is intentional; no upgrade
## or rewarded continuation is required by the baseline solution tests.
const THEMES := ["Amber Hollow", "Azure Grotto", "Violet Vault"]
const NAMES := ["First Light", "The Bank Shot", "Honeycomb", "Split Seam", "Brass Garden", "Golden Stair", "Twin Lanterns", "Copper Crown", "The Hourglass", "Heart of Amber", "Blue Arrival", "Tidal Steps", "Mirror Pool", "Ice Needles", "The Crossing", "Crystal Rain", "Blue Cathedral", "Deep Current", "The Crescent", "Heart of Azure", "Violet Door", "Royal Spiral", "Starlit Bridge", "Prism Lattice", "The Three Keys", "Orbit Chamber", "Crown Jewels", "Echo Gallery", "Final Descent", "The Prism Heart"]
const MAPS := [
 [".......","..AAA..","..AAA..","..AAA..",".......",".......","......."],
 ["AAA....","AAA....","AA.....","....BBB","....BBB",".......","......."],
 [".AAA...","AAAA...",".AAA...","...BBB.","...BBBB","...BBB.","......."],
 ["AA...BB","AAA.BBB","AA...BB",".......","..CCC..","..CCC..","......."],
 ["..AAA..",".AAAAA.","..AAA..",".......","BBB.CCC","BBB.CCC","......."],
 ["AA.....","AAA....",".AAA...","..BBB..","...BBB.","....CCC",".....CC"],
 ["AAA.BBB","AAA.BBB",".A...B.",".......",".CCC...",".CCC...","......."],
 ["A..A..A","AAAAAAA",".AAAAA.",".......",".BB.BB.",".BBBBB.","......."],
 ["AAAAAAA",".AAAAA.","..AAA..","...X...","..BBB..",".BBBBB.","BBBBBBB"],
 [".AA.AA.","AAAAAAA","AAAAAAA",".AAAAA.","..AAA..","...A...","......."],
 ["BBB....","BBBB...","BBB....","....AAA","...AAAA","....AAA","......."],
 ["BB.....","BBB....",".BBB...","..CCC..","...CCC.","....AAA",".....AA"],
 ["BBB.BBB","BBB.BBB",".......","..AAA..","..AAA..","CCC.CCC","......."],
 ["B.B.B.B","BBBBBBB","B.B.B.B",".......",".CC.CC.",".CC.CC.","......."],
 ["...B...","..BBB..","...B...","AAAXAAA","...C...","..CCC..","...C..."],
 [".B.B.B.",".BBBBB.",".......","AA...CC","AAA.CCC","AA...CC","......."],
 ["..BBB..",".BBBBB.","BB...BB","BB...BB","BB...BB",".CC.CC.","..CCC.."],
 ["BB...AA","BBB.AAA",".BBB.A.","..BBB..","C..BBB.","CCC.BBB","CC...BB"],
 [".BBBB..","BBB....","BB.....","BB..AAA","BBB.AAA",".BBBB..","......."],
 ["BBB.BBB","BBBBBBB",".BBBBB.","..BXB..","...B...",".AA.CC.",".AA.CC."],
 ["CC...CC","CCC.CCC","CC...CC",".......","..AAA..","..AAA..","..AAA.."],
 ["CCCCCCC","C.....C","C.AAA.C","C.AXA.C","C.AAA.C","C......","CCCCCC."],
 ["CC...AA","CCC.AAA","CCCCAAA",".......","..BBB..","..BBB..","......."],
 ["CCC.CCC","C.C.C.C","CCC.CCC","...X...","AAA.BBB","A.A.B.B","AAA.BBB"],
 ["AAA.BBB","AAA.BBB",".......","..CCC..","..CXC..","..CCC..","......."],
 ["..CCC..",".CC.CC.","CC...CC","C..X..C","CC...CC",".CC.CC.","..CCC.."],
 ["A..B..C","AA.BB.C","AAABBCC","..AAA..","..AAA..",".......","CCC.CCC"],
 ["CC...AA","CCC.AAA","CC...AA","..BBB..",".BBBBB.","..BBB..","......."],
 ["CCC.AAA","CCC.AAA","...X...",".BBBBB.","..BBB..","C.....C","CC...CC"],
 ["AABBCC.","AABBCCC","AAAXCCC",".ABBC..","..BC...",".A..C..","AA..CC."]
]
const BUMPERS := [[], [[0,4.8,0.55]], [], [[0,3.7,0.55]], [[-1.45,5.6,0.48],[1.45,5.6,0.48]], [[-2.1,6,0.45]], [[0,4.5,0.6]], [[0,5.2,0.45]], [[-2.8,4.4,0.35],[2.8,4.4,0.35]], [], [], [[1.7,4.1,0.45]], [[-1.8,4.3,0.42],[1.8,4.3,0.42]], [[0,5.4,0.6]], [], [[0,4.1,0.55]], [[0,3.8,0.6]], [[-1.9,4.4,0.4]], [[1.7,3.3,0.5]], [[0,7.8,0.5]], [[0,3.6,0.5]], [], [[0,5.3,0.65]], [], [[-2.4,5,0.45],[2.4,5,0.45]], [[0,3,0.4]], [[-2,5.8,0.4],[2,5.8,0.4]], [[0,3.8,0.45]], [[-2.3,5.1,0.4],[2.3,5.1,0.4]], []]

static func make(index: int, seed_value: int = 0) -> Dictionary:
	index = clampi(index,0,29)
	var ore: Array = []
	for row in range(MAPS[index].size()):
		for col in range(7):
			var ch: String = MAPS[index][row][col]
			if ch == ".": continue
			var kind := "ABCX".find(ch)
			# Later seams are separated by natural fissures. Echo upgrades can
			# bridge some gaps; the baseline drill still reaches every band.
			var fissure:=0.0
			if index>=10:
				fissure=(0.24 if row>=2 else 0.0)+(0.24 if row>=4 else 0.0)
			if index>=20:fissure+=(0.18 if row>=6 else 0.0)
			ore.append({"x":(col-3)*0.96,"y":1.4+row*0.92+fissure,"kind":kind,"hp":1})
	var bumpers: Array = []
	for b in BUMPERS[index]: bumpers.append({"x":float(b[0]),"y":float(b[1]),"r":float(b[2])})
	if seed_value != 0:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		var mirror := rng.randi_range(0,1)==1
		var shift := rng.randi_range(0,2)
		for c in ore:
			if mirror: c.x = -float(c.x)
			if int(c.kind)<3: c.kind=(int(c.kind)+shift)%3
		for b in bumpers:
			if mirror:b.x=-float(b.x)
	return {"index":index,"name":NAMES[index],"theme":index/10,"ore":ore,"bumpers":bumpers,"shots":3 if index<10 else 4,"goal":ceili(ore.size()*(0.62 if index<3 else 0.72)),"flight":2.4 if index<2 else 1.55 if index<10 else 1.35 if index<20 else 1.2,"seed":seed_value}
