class_name Circuit
extends RefCounted
## Elektrisches Modell der Brettmontage.
## Jedes Bauteil hat Klemmen ("geraet_id:klemme"). Adern verbinden Klemmen.
## Pruefen() baut daraus Knoten (Union-Find) und erkennt Kurzschluss,
## Erdschluss, FI-Fehlerstrom, fehlenden Schutzleiter, Farb- und Querschnittsfehler.

## Geraetetypen und ihre Klemmen
const TYPEN := {
	"einspeisung": ["L", "N", "PE"],
	"fi":          ["L_in", "N_in", "L_out", "N_out"],
	"ls":          ["in", "out"],
	"ausschalter": ["L", "1"],
	"wechselschalter": ["L", "1", "2"],
	"kreuzschalter": ["1", "2", "3", "4"],
	"taster":      ["L", "1"],      # Schliesser, Stellung 1 = gedrueckt
	"taster_aus":  ["L", "1"],      # Oeffner, Stellung 1 = gedrueckt (dann offen)
	"schuetz":     ["A1", "A2", "1", "2", "3", "4", "5", "6", "13", "14", "21", "22"],
	"zeitrelais":  ["A1", "A2", "15", "16", "18"],
	# Treppenlichtzeitschalter: Taster legen L auf T, dann schaltet L auf "Lampe" fuer die Nachlaufzeit
	"treppenlicht": ["L", "N", "T", "Lampe"],
	"lampe":       ["L", "N", "PE"],
	"steckdose":   ["L", "N", "PE"],
	"klemme":      ["a", "b", "c", "d", "e"],   # Verbindungsklemme: alle Klemmen leitend verbunden
	"pe_schiene":  ["1", "2", "3", "4", "5", "6"],
	"n_schiene":   ["1", "2", "3", "4", "5", "6"],
	"abzweigdose": [],   # Gehaeuse; Klemmen darin sind eigene "klemme"-Geraete
}

## Leitungstypen: Adern (Farben) und Querschnitt in mm²
const LEITUNGEN := {
	"NYM-J 3x1,5": {"adern": ["bn", "bu", "gnye"], "qs": 1.5},
	"NYM-J 5x1,5": {"adern": ["bn", "bk", "gy", "bu", "gnye"], "qs": 1.5},
	"NYM-J 3x2,5": {"adern": ["bn", "bu", "gnye"], "qs": 2.5},
	"NYM-J 5x2,5": {"adern": ["bn", "bk", "gy", "bu", "gnye"], "qs": 2.5},
	"NYM-O 2x1,5": {"adern": ["bn", "bu"], "qs": 1.5},
	"NYM-O 3x1,5": {"adern": ["bn", "bk", "gy"], "qs": 1.5},
	"Steuerleitung 7x1,5": {"adern": ["1", "2", "3", "4", "5", "6", "gnye"], "qs": 1.5},
	# Einzelader fuer die Verdrahtung im Verteiler (Bruecken), braucht keine Schellen
	"H07V-K 1,5": {"adern": ["bn", "bk", "gy", "bu", "gnye"], "qs": 1.5, "einzelader": true},
}

## Maximaler LS-Nennstrom je Querschnitt (vereinfachte Verlegeart C, NYM auf Wand)
const MAX_LS := {1.5: 16, 2.5: 20}
const MAX_SCHELLENABSTAND := 0.25        # Meter
const MAX_ENDABSTAND := 0.10             # erste/letzte Schelle hoechstens 10 cm vor Geraet/Dose
const ABISOLIERLAENGE := Vector2(8, 12)  # mm, erlaubter Bereich

## Feste Einbauten auf dem Uebungsbrett (Brettmitte = 0,0; Meter; y nach oben).
## Im Kabelkanal und im Verteiler braucht eine Leitung keine Iso-Schellen.
const KABELKANAL := Rect2(-0.58, 0.35, 1.16, 0.06)
const VERTEILER_FELD := Rect2(-0.565, -0.015, 0.31, 0.315)
const BEFESTIGT := [KABELKANAL, VERTEILER_FELD]

var geraete := {}   # id -> {typ, pos, param:{}}
var leitungen := []  # [{id, typ, punkte:[Vector3], schellen:[Vector3], abgemantelt:{start,ende}, adern:[{farbe, von, nach, abisoliert_von, abisoliert_nach}]}]
var zustand := {}
var bohrungen := []  # [Vector3] gesetzte Bohrungen auf dem Brett

# --- Union-Find -------------------------------------------------------------
var _p := {}
func _find(a: String) -> String:
	if not _p.has(a):
		_p[a] = a
	while _p[a] != a:
		_p[a] = _p[_p[a]]
		a = _p[a]
	return a
func _union(a: String, b: String) -> void:
	_p[_find(a)] = _find(b)

# --- Aufbau -----------------------------------------------------------------
func geraet_hinzufuegen(id: String, typ: String, pos := Vector3.ZERO, param := {}) -> void:
	assert(TYPEN.has(typ), "Unbekannter Typ " + typ)
	geraete[id] = {"typ": typ, "pos": pos, "param": param}
	if typ in ["ausschalter", "wechselschalter", "kreuzschalter", "taster", "taster_aus"]:
		zustand[id] = {"stellung": 0}
	if typ in ["ls", "fi"]:
		zustand[id] = {"ausgeloest": false}
	if typ in ["schuetz", "zeitrelais", "treppenlicht"]:
		zustand[id] = {"an": false}   # Spulenzustand bleibt erhalten (Selbsthaltung, Nachlaufzeit)

## Tiefe Kopie (z. B. fuer die Bewertung, damit die Schuelerdatei unveraendert bleibt)
func kopie() -> Circuit:
	var c := Circuit.new()
	c.geraete = geraete.duplicate(true)
	c.leitungen = leitungen.duplicate(true)
	c.zustand = zustand.duplicate(true)
	c.bohrungen = bohrungen.duplicate()
	return c

func leitung_hinzufuegen(l: Dictionary) -> void:
	leitungen.append(l)

func _typ(klemme: String) -> String:
	return geraete[klemme.get_slice(":", 0)]["typ"]

# --- Pruefung ---------------------------------------------------------------
## Liefert {ok, ausgeloest:[ids], fehler:[texte], warnungen:[texte], lampen_an:[ids]}
func pruefen() -> Dictionary:
	var r := {"ok": true, "ausgeloest": [], "fehler": [], "warnungen": [], "lampen_an": [], "spulen_an": [],
		"steckdosen_an": [], "ueber_fi": []}
	_montage_pruefen(r)
	_netz_pruefen(r)
	r.ok = r.fehler.is_empty() and r.ausgeloest.is_empty()
	return r

func _montage_pruefen(r: Dictionary) -> void:
	for l in leitungen:
		var info: Dictionary = LEITUNGEN[l.typ]
		if not info.get("einzelader", false):
			_befestigung_pruefen(l, r)
		# Jede Ader gibt es in der Leitung nur so oft, wie der Leitungstyp sie hat
		var gezaehlt := {}
		for a in l.adern:
			gezaehlt[a.farbe] = gezaehlt.get(a.farbe, 0) + 1
		for farbe in gezaehlt:
			if gezaehlt[farbe] > info.adern.count(farbe) and farbe in info.adern:
				r.fehler.append("%s: Ader %s ist mehrfach verwendet, %s hat nur %d davon." % [l.id, farbe, l.typ, info.adern.count(farbe)])
		if l.adern.size() > info.adern.size():
			r.fehler.append("%s: %d Adern verwendet, %s hat nur %d." % [l.id, l.adern.size(), l.typ, info.adern.size()])
		var am: Dictionary = l.get("abgemantelt", {})
		for a in l.adern:
			if a.farbe not in info.adern:
				r.fehler.append("%s: %s hat keine Ader mit Farbe %s." % [l.id, l.typ, a.farbe])
			for ende in ["von", "nach"]:
				if a.get(ende, "") == "":
					continue
				if not am.get("start" if ende == "von" else "ende", false):
					r.fehler.append("%s: Leitung nicht abgemantelt, Ader %s kann nicht angeklemmt werden." % [l.id, a.farbe])
				var lg: float = a.get("abisoliert_" + ende, 0.0)
				if lg <= 0.0:
					r.fehler.append("%s: Ader %s an %s nicht abisoliert." % [l.id, a.farbe, a[ende]])
				elif lg < ABISOLIERLAENGE.x:
					r.warnungen.append("%s: Ader %s an %s zu kurz abisoliert (%d mm)." % [l.id, a.farbe, a[ende], lg])
				elif lg > ABISOLIERLAENGE.y:
					r.fehler.append("%s: Ader %s an %s zu lang abisoliert (%d mm), blankes Kupfer sichtbar." % [l.id, a.farbe, a[ende], lg])
				# Farbregeln
				if _typ(a[ende]) == "klemme":
					continue   # Verbindungsklemme: Farbregel gilt an den Geraeten
				var kl: String = a[ende].get_slice(":", 1)
				var ist_pe := kl == "PE" or _typ(a[ende]) == "pe_schiene"
				if a.farbe == "gnye" and not ist_pe:
					r.fehler.append("%s: grün-gelbe Ader darf nur als Schutzleiter verwendet werden (%s)." % [l.id, a[ende]])
				if ist_pe and a.farbe != "gnye":
					r.fehler.append("%s: Schutzleiter an %s muss grün-gelb sein." % [l.id, a[ende]])
				var ist_n := kl in ["N", "N_in", "N_out"] or _typ(a[ende]) == "n_schiene"
				if ist_n and a.farbe != "bu":
					r.warnungen.append("%s: Neutralleiter an %s sollte blau sein." % [l.id, a[ende]])
		# Querschnitt vs. LS
		var gemeldet := {}
		for a in l.adern:
			for ende in ["von", "nach"]:
				var k: String = a.get(ende, "")
				if k != "" and _typ(k) == "ls" and not gemeldet.has(k.get_slice(":", 0)):
					var nenn: int = geraete[k.get_slice(":", 0)].param.get("nennstrom", 16)
					if nenn > MAX_LS.get(info.qs, 0):
						gemeldet[k.get_slice(":", 0)] = true
						r.fehler.append("%s: %s mm² ist mit LS %dA nicht ausreichend abgesichert." % [l.id, str(info.qs), nenn])

## Befestigung: Iso-Schellen, Kabelkanal und Verteiler halten die Leitung.
## Gemessen wird entlang der Leitung (Laufmeter), nicht in Luftlinie.
func _befestigung_pruefen(l: Dictionary, r: Dictionary) -> void:
	var gesamt := laenge(l)
	var halt := befestigte_abschnitte(l)
	if halt.is_empty():
		r.fehler.append("%s: Leitung ist nicht mit Iso-Schellen befestigt." % l.id)
		return
	if halt[0][0] > MAX_ENDABSTAND + 0.001 or gesamt - _max_ende(halt) > MAX_ENDABSTAND + 0.001:
		r.fehler.append("%s: Erste/letzte Iso-Schelle mehr als %d cm vom Gerät entfernt." % [l.id, int(MAX_ENDABSTAND * 100)])
	var bis: float = halt[0][1]
	for h in halt:
		if h[0] - bis > MAX_SCHELLENABSTAND + 0.001:
			r.fehler.append("%s: Schellenabstand über %d cm." % [l.id, int(MAX_SCHELLENABSTAND * 100)])
			break
		bis = maxf(bis, h[1])

static func laenge(l: Dictionary) -> float:
	var verlauf: Array = l.get("punkte", [])
	var gesamt := 0.0
	for i in range(verlauf.size() - 1):
		gesamt += (verlauf[i] as Vector3).distance_to(verlauf[i + 1])
	return gesamt

## Befestigte Abschnitte als [von, bis] in Laufmetern (Schellen, Kabelkanal, Verteiler), sortiert
static func befestigte_abschnitte(l: Dictionary) -> Array:
	var verlauf: Array = l.get("punkte", [])
	var halt := []
	for sp in l.get("schellen", []):
		var t := laufmeter(verlauf, sp)
		halt.append([t, t])
	var lauf := 0.0
	for i in range(verlauf.size() - 1):
		var a: Vector3 = verlauf[i]
		var b: Vector3 = verlauf[i + 1]
		var lg := a.distance_to(b)
		for feld in BEFESTIGT:
			var ab := _im_rechteck(Vector2(a.x, a.y), Vector2(b.x, b.y), feld)
			if not ab.is_empty():
				halt.append([lauf + ab[0] * lg, lauf + ab[1] * lg])
		lauf += lg
	halt.sort_custom(func(x, y): return x[0] < y[0])
	return halt

## Abstand (entlang der Leitung) vom Leitungsende "start"/"ende" bis zur naechsten Befestigung, INF wenn keine
static func abstand_befestigung(l: Dictionary, ende: String) -> float:
	var halt := befestigte_abschnitte(l)
	if halt.is_empty():
		return INF
	if ende == "start":
		return halt[0][0]
	var m := 0.0
	for h in halt: m = maxf(m, h[1])
	return laenge(l) - m

static func _max_ende(halt: Array) -> float:
	var m := 0.0
	for h in halt: m = maxf(m, h[1])
	return m

## Anteil [t0, t1] (0..1) der Strecke a-b, der im Rechteck liegt, oder [] (Liang-Barsky)
static func _im_rechteck(a: Vector2, b: Vector2, feld: Rect2) -> Array:
	var t0 := 0.0
	var t1 := 1.0
	var d := b - a
	for k in [[-d.x, a.x - feld.position.x], [d.x, feld.end.x - a.x], [-d.y, a.y - feld.position.y], [d.y, feld.end.y - a.y]]:
		var p: float = k[0]
		var q: float = k[1]
		if absf(p) < 1e-9:
			if q < 0: return []
		else:
			var t := q / p
			if p < 0: t0 = maxf(t0, t)
			else: t1 = minf(t1, t)
	return [t0, t1] if t0 <= t1 else []

## Laufmeter des Punkts p entlang des Verlaufs (naechster Punkt auf der Leitung)
static func laufmeter(verlauf: Array, p: Vector3) -> float:
	var lauf := 0.0
	var best := INF
	var best_lauf := 0.0
	for i in range(verlauf.size() - 1):
		var a: Vector3 = verlauf[i]
		var b: Vector3 = verlauf[i + 1]
		var q := Geometry3D.get_closest_point_to_segment(p, a, b)
		if q.distance_to(p) < best:
			best = q.distance_to(p)
			best_lauf = lauf + a.distance_to(q)
		lauf += a.distance_to(b)
	return best_lauf

## Kontakte von Schuetz/Zeitrelais je nach Spulenzustand
const SCHUETZ_SCHLIESSER := [["1", "2"], ["3", "4"], ["5", "6"], ["13", "14"]]
const SCHUETZ_OEFFNER := [["21", "22"]]

## Knoten aufbauen. spulen: id -> bool (Spule unter Spannung)
func _verbinden(spulen: Dictionary) -> void:
	_p.clear()
	for id in geraete:
		var g: Dictionary = geraete[id]
		var z: Dictionary = zustand.get(id, {})
		match g.typ:
			"ls":
				if not z.ausgeloest: _union(id + ":in", id + ":out")
			"ausschalter", "taster":
				if int(z.stellung) == 1: _union(id + ":L", id + ":1")
			"taster_aus":
				if int(z.stellung) == 0: _union(id + ":L", id + ":1")
			"wechselschalter":
				_union(id + ":L", id + (":1" if int(z.stellung) == 0 else ":2"))
			"kreuzschalter":
				if int(z.stellung) == 0:
					_union(id + ":1", id + ":3"); _union(id + ":2", id + ":4")
				else:
					_union(id + ":1", id + ":4"); _union(id + ":2", id + ":3")
			"schuetz":
				var an: bool = spulen.get(id, false)
				for k in (SCHUETZ_SCHLIESSER if an else SCHUETZ_OEFFNER):
					_union(id + ":" + k[0], id + ":" + k[1])
			"zeitrelais":
				# Ansprechverzoegert: nach Ablauf der Zeit schaltet 15 von 16 auf 18
				var an: bool = spulen.get(id, false)
				_union(id + ":15", id + (":18" if an else ":16"))
			"treppenlicht":
				if spulen.get(id, false): _union(id + ":L", id + ":Lampe")
			"klemme", "pe_schiene", "n_schiene":
				var ks: Array = TYPEN[g.typ]
				for k in ks: _union(id + ":" + k, id + ":" + ks[0])
	# FI wird NICHT vereint: Ein- und Ausgang bleiben getrennte Knoten,
	# damit man sieht, ob Hin- und Rueckstrom beide durch den FI fliessen.
	# Nur abgemantelte und abisolierte Aderenden haben Kontakt in der Klemme.
	for l in leitungen:
		var am: Dictionary = l.get("abgemantelt", {})
		for a in l.adern:
			if a.get("von", "") != "" and a.get("nach", "") != "" \
					and am.get("start", false) and am.get("ende", false) \
					and a.get("abisoliert_von", 0.0) > 0.0 and a.get("abisoliert_nach", 0.0) > 0.0:
				_union(a.von, a.nach)

## Spannungsfuehrende Knoten: {L:[...], N:[...], PE, fi, fi_L, fi_N, warnung}
func _quellen(quelle: String) -> Dictionary:
	var q := {"L": [_find(quelle + ":L")], "N": [_find(quelle + ":N")], "PE": _find(quelle + ":PE"),
		"fi": "", "fi_L": "", "fi_N": "", "warnung": ""}
	for id in geraete:
		if geraete[id].typ == "fi" and not zustand[id].ausgeloest:
			q.fi = id
	if q.fi != "":
		var fi: String = q.fi
		# Eingang am Netz? Dann ist der Ausgang ebenfalls Spannung fuehrend
		if _find(fi + ":L_in") == q.L[0] and _find(fi + ":N_in") == q.N[0]:
			q.fi_L = _find(fi + ":L_out")
			q.fi_N = _find(fi + ":N_out")
			q.L.append(q.fi_L)
			q.N.append(q.fi_N)
		elif _find(fi + ":L_in") == q.N[0] or _find(fi + ":N_in") == q.L[0]:
			q.warnung = "FI: L und N am Eingang vertauscht."
	return q

## Verbraucher (Lampe, Steckdose, Spulen) und ihre beiden Anschluesse
func _verbraucher() -> Array:
	var r := []
	for id in geraete:
		match geraete[id].typ:
			"lampe", "steckdose": r.append([id, id + ":L", id + ":N"])
			"schuetz", "zeitrelais": r.append([id, id + ":A1", id + ":A2"])
			"treppenlicht": r.append([id, id + ":T", id + ":N"])
	return r

func _unter_spannung(q: Dictionary, a: String, b: String) -> bool:
	var ka := _find(a)
	var kb := _find(b)
	return (ka in q.L and kb in q.N) or (ka in q.N and kb in q.L)

func _netz_pruefen(r: Dictionary) -> void:
	var quelle := ""
	for id in geraete:
		if geraete[id].typ == "einspeisung":
			quelle = id
	if quelle == "":
		r.fehler.append("Keine Einspeisung vorhanden.")
		return
	# Spulen schalten Kontakte, die wieder Spulen schalten: bis zum stabilen Zustand rechnen
	var spulen := {}
	for id in geraete:
		if geraete[id].typ in ["schuetz", "zeitrelais", "treppenlicht"] and zustand.get(id, {}).get("an", false):
			spulen[id] = true
	# Treppenlichtautomat merkt sich den Tastendruck bis die Nachlaufzeit abgelaufen ist
	var gemerkt := {}
	for id in spulen:
		if geraete[id].typ == "treppenlicht": gemerkt[id] = true
	var q := {}
	for durchlauf in 12:
		_verbinden(spulen)
		q = _quellen(quelle)
		var neu := gemerkt.duplicate()
		for v in _verbraucher():
			if geraete[v[0]].typ in ["schuetz", "zeitrelais", "treppenlicht"] and _unter_spannung(q, v[1], v[2]):
				neu[v[0]] = true
		if neu == spulen:
			break
		spulen = neu
		if durchlauf == 11:
			r.warnungen.append("Steuerung schwingt (Schütz schaltet sich selbst ein und aus).")
	for id in geraete:
		if geraete[id].typ in ["schuetz", "zeitrelais", "treppenlicht"]:
			zustand[id] = {"an": spulen.has(id)}
	if q.warnung != "":
		r.warnungen.append(q.warnung)
	var L: Array = q.L
	var N: Array = q.N
	var PE: String = q.PE
	var fi: String = q.fi
	# Kurzschluss L-N, Erdschluss L-PE
	for l_ in L:
		if l_ in N:
			_ausloesen(r, l_, "Kurzschluss zwischen L und N")
			return
		if l_ == PE:
			_ausloesen(r, l_, "Erdschluss: L hat Verbindung zum Schutzleiter")
			if fi != "": r.ausgeloest.append(fi)
			return
	if q.fi_N != "" and q.fi_N == PE:
		r.ausgeloest.append(fi)
		r.fehler.append("FI löst aus: N nach dem FI ist mit PE verbunden.")
		return
	# Verbraucher
	for v in _verbraucher():
		var id: String = v[0]
		var typ: String = geraete[id].typ
		if typ in ["lampe", "steckdose"] and _find(id + ":PE") != PE:
			r.fehler.append("%s: Schutzleiter nicht angeschlossen." % id)
		var ka := _find(v[1])
		var kb := _find(v[2])
		if _unter_spannung(q, v[1], v[2]):
			# FI: Hin- und Rueckleiter muessen beide durch den FI (oder beide nicht)
			if fi != "" and ((ka == q.fi_L or kb == q.fi_L) != (ka == q.fi_N or kb == q.fi_N)):
				r.ausgeloest.append(fi)
				r.fehler.append("FI löst aus: Hin- und Rückleiter von %s laufen nicht beide über den FI." % id)
				return
			if typ in ["lampe", "steckdose"] and ka in N and kb in L:
				r.fehler.append("%s: L und N vertauscht." % id)
			if typ == "lampe": r.lampen_an.append(id)
			elif typ == "steckdose": r.steckdosen_an.append(id)
			else: r.spulen_an.append(id)
			if fi != "" and (ka == q.fi_L or kb == q.fi_L):
				r.ueber_fi.append(id)

func _ausloesen(r: Dictionary, knoten: String, grund: String) -> void:
	var ls_ids := []
	for id in geraete:
		if geraete[id].typ == "ls" and not zustand[id].ausgeloest and _find(id + ":out") == knoten:
			ls_ids.append(id)
	if ls_ids.is_empty():
		r.fehler.append(grund + " (keine Sicherung im Stromkreis!)")
	else:
		r.ausgeloest.append_array(ls_ids)
		r.fehler.append("%s: %s löst aus." % [grund, ", ".join(ls_ids)])
