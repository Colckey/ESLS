class_name Aufgaben
extends RefCounted
## Lernaufgaben (Auftraege) fuer die Brettmontage.
## Jede Aufgabe hat einen Auftragstext, Lernziele, Tipps, Mindest-Bauteile und eine
## eingebaute Musterschaltung. Der Lehrermodus bewertet damit ohne eigene Musterdatei.

const LISTE := [
	{
		"id": "ausschaltung",
		"bauplan": [["fi", Vector2(-0.50, 0.17)], ["ls", Vector2(-0.45, 0.17)], ["abzweigdose", Vector2(0.10, 0.05)], ["ausschalter", Vector2(0.10, -0.25)], ["lampe", Vector2(0.40, 0.05)]],
		"titel": "Ausschaltung", "lehrjahr": 1, "stufe": "Einstieg",
		"kurz": "Eine Lampe mit einem Ausschalter schalten.",
		"auftrag": "Im Kellerraum soll eine Feuchtraumleuchte mit einem Ausschalter neben der Tür geschaltet werden. Der Stromkreis wird über FI und LS B16 im Verteiler abgesichert. Die Leitungen laufen über eine Abzweigdose.",
		"bauteile": {"fi": 1, "ls": 1, "abzweigdose": 1, "ausschalter": 1, "lampe": 1},
		"lernziele": ["Außenleiter wird geschaltet, nie der Neutralleiter", "Schaltdraht in der Abzweigdose verbinden", "Schutzleiter an der Leuchte anschließen"],
		"tipps": ["Zuleitung vom LS zur Abzweigdose: NYM-J 3x1,5", "Zum Schalter reichen L hin und Schaltdraht zurück", "In der Dose: eine Wago-Klemme je Leiter (L, N, PE, Schaltdraht)"],
	},
	{
		"id": "wechselschaltung",
		"bauplan": [["fi", Vector2(-0.50, 0.17)], ["ls", Vector2(-0.45, 0.17)], ["abzweigdose", Vector2(0.15, 0.05)], ["wechselschalter", Vector2(-0.05, -0.25)], ["wechselschalter", Vector2(0.35, -0.25)], ["lampe", Vector2(0.40, 0.20)]],
		"titel": "Wechselschaltung", "lehrjahr": 1, "stufe": "Grundlagen",
		"kurz": "Eine Lampe von zwei Stellen aus schalten.",
		"auftrag": "Im Flur soll die Deckenleuchte von beiden Enden aus geschaltet werden. Setze zwei Wechselschalter und verbinde sie über die korrespondierenden Leiter.",
		"bauteile": {"fi": 1, "ls": 1, "abzweigdose": 1, "wechselschalter": 2, "lampe": 1},
		"lernziele": ["Klemme L (Wurzel) und die korrespondierenden Klemmen 1 und 2 unterscheiden", "Korrespondierende Leiter richtig verbinden", "Funktion mit allen Schalterstellungen prüfen"],
		"tipps": ["Für drei Adern ohne Schutzleiter eignet sich NYM-O 3x1,5 oder NYM-J 5x1,5", "Die grün-gelbe Ader darf nie als korrespondierender Leiter dienen", "Jede Betätigung muss die Lampe umschalten"],
	},
	{
		"id": "kreuzschaltung",
		"bauplan": [["fi", Vector2(-0.50, 0.17)], ["ls", Vector2(-0.45, 0.17)], ["wechselschalter", Vector2(-0.05, -0.25)], ["kreuzschalter", Vector2(0.15, -0.25)], ["wechselschalter", Vector2(0.35, -0.25)], ["lampe", Vector2(0.15, 0.15)]],
		"titel": "Kreuzschaltung", "lehrjahr": 1, "stufe": "Fortgeschritten",
		"kurz": "Eine Lampe von drei Stellen aus schalten.",
		"auftrag": "Im Treppenhaus mit drei Zugängen soll eine Lampe von drei Stellen geschaltet werden: Wechselschalter, Kreuzschalter, Wechselschalter.",
		"bauteile": {"fi": 1, "ls": 1, "wechselschalter": 2, "kreuzschalter": 1, "lampe": 1},
		"lernziele": ["Kreuzschalter zwischen zwei Wechselschaltern einbauen", "Klemmen 1/2 und 3/4 am Kreuzschalter paarweise belegen"],
		"tipps": ["Der Kreuzschalter bekommt nur korrespondierende Leiter, kein L", "Prüfe alle 8 Schalterstellungen"],
	},
	{
		"id": "steckdosenkreis",
		"bauplan": [["fi", Vector2(-0.50, 0.17)], ["ls", Vector2(-0.45, 0.17)], ["steckdose", Vector2(0.00, -0.20)], ["steckdose", Vector2(0.12, -0.20)]],
		"titel": "Steckdosenkreis", "lehrjahr": 1, "stufe": "Grundlagen",
		"kurz": "Zwei Schutzkontakt-Steckdosen über FI anschließen.",
		"auftrag": "In der Werkstatt sollen zwei Schuko-Steckdosen nebeneinander installiert werden. Sie bekommen einen eigenen LS B16 und müssen über den FI (30 mA) geschützt sein. Die zweite Steckdose wird von der ersten weiter verdrahtet.",
		"bauteile": {"fi": 1, "ls": 1, "steckdose": 2},
		"ueber_fi": ["steckdose"],
		"lernziele": ["Steckdosen bis 32 A brauchen einen FI mit 30 mA (DIN VDE 0100-410)", "L, N und PE richtig anklemmen und weiterschleifen", "Querschnitt passend zum LS wählen"],
		"tipps": ["Üblich ist NYM-J 3x2,5 für Steckdosenkreise", "Pro Schraubklemme höchstens 2 Adern", "Schutzleiter immer mit anschließen"],
	},
	{
		"id": "treppenhaus",
		"bauplan": [["fi", Vector2(-0.50, 0.17)], ["ls", Vector2(-0.45, 0.17)], ["treppenlicht", Vector2(-0.43, 0.17)], ["taster", Vector2(-0.05, -0.25)], ["taster", Vector2(0.15, -0.25)], ["taster", Vector2(0.35, -0.25)], ["lampe", Vector2(0.15, 0.15)]],
		"titel": "Treppenhausschaltung", "lehrjahr": 2, "stufe": "Steuerung",
		"kurz": "Treppenlicht mit Tastern und Treppenlichtautomat.",
		"auftrag": "Im Mehrfamilienhaus soll das Treppenlicht von drei Etagen aus mit Tastern eingeschaltet werden. Ein Treppenlichtzeitschalter (TLZ) im Verteiler schaltet das Licht nach der Nachlaufzeit wieder aus.",
		"bauteile": {"fi": 1, "ls": 1, "treppenlicht": 1, "taster": 3, "lampe": 1},
		"lernziele": ["Taster parallel schalten", "Steuereingang T, Versorgung L/N und Lampenausgang am TLZ unterscheiden", "Unterschied Taster und Schalter verstehen"],
		"tipps": ["Alle Taster bekommen L und schalten auf die Klemme T", "Die Lampe hängt am Ausgang „Lampe“ des TLZ", "Taster mit Leertaste drücken und wieder loslassen"],
	},
	{
		"id": "schuetz",
		"bauplan": [["fi", Vector2(-0.50, 0.17)], ["ls", Vector2(-0.45, 0.17)], ["schuetz", Vector2(-0.50, 0.06)], ["taster", Vector2(0.05, -0.25)], ["taster_aus", Vector2(0.20, -0.25)], ["lampe", Vector2(0.35, 0.15)]],
		"titel": "Schützschaltung mit Selbsthaltung", "lehrjahr": 2, "stufe": "Steuerung",
		"kurz": "Ein Schütz mit Ein- und Aus-Taster steuern.",
		"auftrag": "Eine Maschine (hier: Lampe) wird über ein Schütz geschaltet. S1 (Schließer) schaltet ein, S0 (Öffner) schaltet aus. Das Schütz hält sich über den Hilfskontakt 13/14 selbst.",
		"bauteile": {"fi": 1, "ls": 1, "schuetz": 1, "taster": 1, "taster_aus": 1, "lampe": 1},
		"lernziele": ["Steuerstromkreis und Hauptstromkreis trennen", "Selbsthaltung über Hilfskontakt 13/14", "Öffner vor Schließer in Reihe"],
		"tipps": ["Spule A1/A2: A2 an N", "13/14 parallel zum Ein-Taster", "Hauptkontakt 1/2 schaltet die Lampe"],
	},
	{
		"id": "uebungsbrett",
		"bauplan": [["fi", Vector2(-0.50, 0.17)], ["ls", Vector2(-0.45, 0.17)], ["ls", Vector2(-0.43, 0.17)], ["abzweigdose", Vector2(0.30, 0.05)], ["lampe", Vector2(0.47, 0.22)], ["steckdose", Vector2(-0.18, -0.33)], ["steckdose", Vector2(-0.06, -0.33)], ["wechselschalter", Vector2(0.06, -0.33)], ["kreuzschalter", Vector2(0.18, -0.33)], ["wechselschalter", Vector2(0.30, -0.33)]],
		"titel": "Übungsbrett komplett", "lehrjahr": 1, "stufe": "Abschluss",
		"kurz": "Kreuzschaltung und Steckdosenkreis auf einem Brett.",
		"auftrag": "Baue das komplette Übungsbrett wie in der Werkstatt: Die Leuchte wird über eine Abzweigdose von drei Stellen geschaltet (Wechsel-, Kreuz-, Wechselschalter, LS 1). Zwei Steckdosen bekommen einen eigenen LS (LS 2). Beide Stromkreise laufen über den FI. Die Leitungen führen durch den Kabelkanal oben.",
		"bauteile": {"fi": 1, "ls": 2, "abzweigdose": 1, "wechselschalter": 2, "kreuzschalter": 1, "lampe": 1, "steckdose": 2},
		"ueber_fi": ["steckdose"],
		"lernziele": ["Mehrere Stromkreise im Verteiler aufteilen", "N- und PE-Klemmen im Verteiler nutzen", "Leitungen sauber im Kabelkanal führen"],
		"tipps": ["Im Kabelkanal und im Verteiler braucht die Leitung keine Iso-Schellen", "Schutzleiter in der Abzweigdose durchverbinden", "Erst den Verteiler verdrahten, dann die Dose"],
	},
]

const TYP_NAME := {"fi": "FI-Schalter", "ls": "LS-Schalter", "abzweigdose": "Abzweigdose", "ausschalter": "Ausschalter",
	"wechselschalter": "Wechselschalter", "kreuzschalter": "Kreuzschalter", "taster": "Taster (Schließer)",
	"taster_aus": "Taster (Öffner)", "steckdose": "Steckdose", "lampe": "Lampe", "schuetz": "Schütz",
	"zeitrelais": "Zeitrelais", "treppenlicht": "Treppenlichtautomat"}

static func finden(id: String) -> Dictionary:
	for a in LISTE:
		if a.id == id:
			return a
	return {}

# ---------------------------------------------------------------- Pruefung der Anforderungen

## Fehlende Bauteile usw.: Liste von Texten
static func anforderungen_pruefen(c: Circuit, id: String) -> Array:
	var a := finden(id)
	var r := []
	if a.is_empty():
		return r
	var anzahl := {}
	for gid in c.geraete:
		var t: String = c.geraete[gid].typ
		anzahl[t] = anzahl.get(t, 0) + 1
	for t in a.bauteile:
		if anzahl.get(t, 0) < a.bauteile[t]:
			r.append("Es fehlt: %d× %s (vorhanden: %d)." % [a.bauteile[t], TYP_NAME.get(t, t), anzahl.get(t, 0)])
	if a.has("ueber_fi"):
		var p := c.kopie().pruefen()
		for gid in p.get("steckdosen_an", []) + p.get("lampen_an", []):
			if c.geraete[gid].typ in a.ueber_fi and gid not in p.ueber_fi:
				r.append("%s ist nicht über den FI (30 mA) geschützt." % gid)
	return r

# ---------------------------------------------------------------- Musterschaltungen

static func muster(id: String) -> Circuit:
	match id:
		"ausschaltung": return _ausschaltung()
		"wechselschaltung": return _wechselschaltung()
		"kreuzschaltung": return _kreuzschaltung()
		"steckdosenkreis": return _steckdosenkreis()
		"treppenhaus": return _treppenhaus()
		"schuetz": return _schuetz()
		"uebungsbrett": return _uebungsbrett()
	return null

## Einspeisung, FI und LS sind in allen Mustern gleich
static func _verteiler(geraete: Array) -> Circuit:
	var c := Circuit.new()
	for g in [["netz", "einspeisung"], ["fi1", "fi"], ["ls1", "ls"]] + geraete:
		c.geraet_hinzufuegen(g[0], g[1], Vector3.ZERO, {"nennstrom": 16} if g[1] == "ls" else {})
	_l(c, "v", "H07V-K 1,5", [["bn", "netz:L", "fi1:L_in"]])
	_l(c, "v2", "H07V-K 1,5", [["bu", "netz:N", "fi1:N_in"]])
	_l(c, "v3", "H07V-K 1,5", [["bn", "fi1:L_out", "ls1:in"]])
	return c

static func _l(c: Circuit, id: String, typ: String, adern: Array) -> void:
	var a := []
	for x in adern:
		a.append({"farbe": x[0], "von": x[1], "nach": x[2], "abisoliert_von": 10.0, "abisoliert_nach": 10.0,
			"huelse_von": true, "huelse_nach": true})
	var s := [Vector3(0, 0, 0), Vector3(0.2, 0, 0)]
	c.leitung_hinzufuegen({"id": id, "typ": typ, "punkte": s, "schellen": s,
		"abgemantelt": {"start": true, "ende": true}, "adern": a})

static func _ausschaltung() -> Circuit:
	var c := _verteiler([["dose1", "abzweigdose"], ["s1", "ausschalter"], ["lampe1", "lampe"]])
	_l(c, "w1", "NYM-J 3x1,5", [["bn", "ls1:out", "s1:L"]])
	_l(c, "w2", "NYM-J 3x1,5", [["bn", "s1:1", "lampe1:L"], ["bu", "fi1:N_out", "lampe1:N"], ["gnye", "netz:PE", "lampe1:PE"]])
	return c

static func _wechselschaltung() -> Circuit:
	var c := _verteiler([["dose1", "abzweigdose"], ["ws1", "wechselschalter"], ["ws2", "wechselschalter"], ["lampe1", "lampe"]])
	_l(c, "w1", "NYM-J 3x1,5", [["bn", "ls1:out", "ws1:L"]])
	_l(c, "w2", "NYM-O 3x1,5", [["bk", "ws1:1", "ws2:1"], ["gy", "ws1:2", "ws2:2"]])
	_l(c, "w3", "NYM-J 3x1,5", [["bn", "ws2:L", "lampe1:L"], ["bu", "fi1:N_out", "lampe1:N"], ["gnye", "netz:PE", "lampe1:PE"]])
	return c

static func _kreuzschaltung() -> Circuit:
	var c := _verteiler([["ws1", "wechselschalter"], ["x1", "kreuzschalter"], ["ws2", "wechselschalter"], ["lampe1", "lampe"]])
	_l(c, "w1", "NYM-J 3x1,5", [["bn", "ls1:out", "ws1:L"]])
	_l(c, "w2", "NYM-O 3x1,5", [["bk", "ws1:1", "x1:1"], ["gy", "ws1:2", "x1:2"]])
	_l(c, "w3", "NYM-O 3x1,5", [["bk", "x1:3", "ws2:1"], ["gy", "x1:4", "ws2:2"]])
	_l(c, "w4", "NYM-J 3x1,5", [["bn", "ws2:L", "lampe1:L"], ["bu", "fi1:N_out", "lampe1:N"], ["gnye", "netz:PE", "lampe1:PE"]])
	return c

static func _steckdosenkreis() -> Circuit:
	var c := _verteiler([["sd1", "steckdose"], ["sd2", "steckdose"]])
	_l(c, "w1", "NYM-J 3x2,5", [["bn", "ls1:out", "sd1:L"], ["bu", "fi1:N_out", "sd1:N"], ["gnye", "netz:PE", "sd1:PE"]])
	_l(c, "w2", "NYM-J 3x2,5", [["bn", "sd1:L", "sd2:L"], ["bu", "sd1:N", "sd2:N"], ["gnye", "sd1:PE", "sd2:PE"]])
	return c

static func _treppenhaus() -> Circuit:
	var c := _verteiler([["tlz1", "treppenlicht"], ["t1", "taster"], ["t2", "taster"], ["t3", "taster"], ["lampe1", "lampe"]])
	_l(c, "v4", "H07V-K 1,5", [["bn", "ls1:out", "tlz1:L"]])
	_l(c, "v5", "H07V-K 1,5", [["bu", "fi1:N_out", "tlz1:N"]])
	_l(c, "w1", "NYM-O 3x1,5", [["bn", "ls1:out", "t1:L"], ["bk", "t1:1", "tlz1:T"]])
	_l(c, "w2", "NYM-O 3x1,5", [["bn", "t1:L", "t2:L"], ["bk", "t2:1", "t1:1"]])
	_l(c, "w3", "NYM-O 3x1,5", [["bn", "t2:L", "t3:L"], ["bk", "t3:1", "t2:1"]])
	_l(c, "w4", "NYM-J 3x1,5", [["bn", "tlz1:Lampe", "lampe1:L"], ["bu", "fi1:N_out", "lampe1:N"], ["gnye", "netz:PE", "lampe1:PE"]])
	return c

static func _schuetz() -> Circuit:
	var c := _verteiler([["s0", "taster_aus"], ["s1", "taster"], ["k1", "schuetz"], ["lampe1", "lampe"]])
	_l(c, "st", "Steuerleitung 7x1,5", [["1", "ls1:out", "s0:L"], ["2", "s0:1", "s1:L"], ["3", "s0:1", "k1:13"],
		["4", "s1:1", "k1:A1"], ["5", "k1:14", "k1:A1"]])
	_l(c, "v4", "H07V-K 1,5", [["bu", "k1:A2", "fi1:N_out"]])
	_l(c, "w", "NYM-J 5x1,5", [["bk", "ls1:out", "k1:1"], ["bn", "k1:2", "lampe1:L"], ["bu", "fi1:N_out", "lampe1:N"], ["gnye", "netz:PE", "lampe1:PE"]])
	return c

static func _uebungsbrett() -> Circuit:
	var c := _kreuzschaltung()
	c.geraet_hinzufuegen("dose1", "abzweigdose")
	c.geraet_hinzufuegen("ls2", "ls", Vector3.ZERO, {"nennstrom": 16})
	c.geraet_hinzufuegen("sd1", "steckdose")
	c.geraet_hinzufuegen("sd2", "steckdose")
	_l(c, "v4", "H07V-K 1,5", [["bn", "ls1:in", "ls2:in"]])
	_l(c, "w5", "NYM-J 3x2,5", [["bn", "ls2:out", "sd1:L"], ["bu", "fi1:N_out", "sd1:N"], ["gnye", "netz:PE", "sd1:PE"]])
	_l(c, "w6", "NYM-J 3x2,5", [["bn", "sd1:L", "sd2:L"], ["bu", "sd1:N", "sd2:N"], ["gnye", "sd1:PE", "sd2:PE"]])
	return c
