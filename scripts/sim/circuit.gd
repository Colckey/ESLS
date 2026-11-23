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
	"lampe":       ["L", "N", "PE"],
	"steckdose":   ["L", "N", "PE"],
	"klemme":      ["a", "b", "c", "d", "e"],   # Verbindungsklemme: alle Klemmen leitend verbunden
	"pe_schiene":  ["1", "2", "3", "4", "5", "6"],
	"n_schiene":   ["1", "2", "3", "4", "5", "6"],
}

## Leitungstypen: Adern (Farben) und Querschnitt in mm²
const LEITUNGEN := {
	"NYM-J 3x1,5": {"adern": ["bn", "bu", "gnye"], "qs": 1.5},
	"NYM-J 5x1,5": {"adern": ["bn", "bk", "gy", "bu", "gnye"], "qs": 1.5},
	"NYM-J 3x2,5": {"adern": ["bn", "bu", "gnye"], "qs": 2.5},
	"NYM-J 5x2,5": {"adern": ["bn", "bk", "gy", "bu", "gnye"], "qs": 2.5},
	"NYM-O 2x1,5": {"adern": ["bn", "bu"], "qs": 1.5},
	"Steuerleitung 7x1,5": {"adern": ["1", "2", "3", "4", "5", "6", "gnye"], "qs": 1.5},
}

## Maximaler LS-Nennstrom je Querschnitt (vereinfachte Verlegeart C, NYM auf Wand)
const MAX_LS := {1.5: 16, 2.5: 20}
const MAX_SCHELLENABSTAND := 0.25        # Meter
const ABISOLIERLAENGE := Vector2(8, 12)  # mm, erlaubter Bereich

var geraete := {}   # id -> {typ, pos, param:{}}
var leitungen := []  # [{id, typ, punkte:[Vector3], schellen:[Vector3], abgemantelt:{start,ende}, adern:[{farbe, von, nach, abisoliert_von, abisoliert_nach}]}]
var zustand := {}   # id -> {geschlossen: bool} fuer Schalter, {ausgeloest: bool} fuer LS/FI

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
	if typ in ["ausschalter", "wechselschalter"]:
		zustand[id] = {"stellung": 0}
	if typ in ["ls", "fi"]:
		zustand[id] = {"ausgeloest": false}

func leitung_hinzufuegen(l: Dictionary) -> void:
	leitungen.append(l)

func _typ(klemme: String) -> String:
	return geraete[klemme.get_slice(":", 0)]["typ"]

# --- Pruefung ---------------------------------------------------------------
## Liefert {ok, ausgeloest:[ids], fehler:[texte], warnungen:[texte], lampen_an:[ids]}
func pruefen() -> Dictionary:
	var r := {"ok": true, "ausgeloest": [], "fehler": [], "warnungen": [], "lampen_an": []}
	_montage_pruefen(r)
	_netz_pruefen(r)
	r.ok = r.fehler.is_empty() and r.ausgeloest.is_empty()
	return r

func _montage_pruefen(r: Dictionary) -> void:
	for l in leitungen:
		var info: Dictionary = LEITUNGEN[l.typ]
		# Schellenabstand entlang der Leitung
		var pts: Array = l.get("schellen", [])
		if pts.size() < 2:
			r.fehler.append("%s: Leitung ist nicht mit Iso-Schellen befestigt." % l.id)
		for i in range(pts.size() - 1):
			if (pts[i] as Vector3).distance_to(pts[i + 1]) > MAX_SCHELLENABSTAND + 0.001:
				r.fehler.append("%s: Schellenabstand über %d cm." % [l.id, int(MAX_SCHELLENABSTAND * 100)])
				break
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

func _netz_pruefen(r: Dictionary) -> void:
	_p.clear()
	var quelle := ""
	for id in geraete:
		var g: Dictionary = geraete[id]
		var z: Dictionary = zustand.get(id, {})
		match g.typ:
			"einspeisung": quelle = id
			"ls":
				if not z.ausgeloest: _union(id + ":in", id + ":out")
			"ausschalter":
				if z.stellung == 1: _union(id + ":L", id + ":1")
			"wechselschalter":
				_union(id + ":L", id + (":1" if z.stellung == 0 else ":2"))
			"klemme", "pe_schiene", "n_schiene":
				var ks: Array = TYPEN[g.typ]
				for k in ks: _union(id + ":" + k, id + ":" + ks[0])
	# FI wird NICHT vereint: Ein- und Ausgang bleiben getrennte Knoten,
	# damit man sieht, ob Hin- und Rueckstrom beide durch den FI fliessen.
	# Nur abgemantelte und abisolierte Aderenden haben Kontakt in der Klemme
	for l in leitungen:
		var am: Dictionary = l.get("abgemantelt", {})
		for a in l.adern:
			if a.get("von", "") != "" and a.get("nach", "") != "" \
					and am.get("start", false) and am.get("ende", false) \
					and a.get("abisoliert_von", 0.0) > 0.0 and a.get("abisoliert_nach", 0.0) > 0.0:
				_union(a.von, a.nach)
	if quelle == "":
		r.fehler.append("Keine Einspeisung vorhanden.")
		return
	var fi := ""
	for id in geraete:
		if geraete[id].typ == "fi" and not zustand[id].ausgeloest:
			fi = id
	var L := [_find(quelle + ":L")]
	var N := [_find(quelle + ":N")]
	var PE := _find(quelle + ":PE")
	var fi_L := ""; var fi_N := ""
	if fi != "":
		# Eingang am Netz? Dann ist der Ausgang ebenfalls Spannung fuehrend
		if _find(fi + ":L_in") == L[0] and _find(fi + ":N_in") == N[0]:
			fi_L = _find(fi + ":L_out"); fi_N = _find(fi + ":N_out")
			L.append(fi_L); N.append(fi_N)
		elif _find(fi + ":L_in") == N[0] or _find(fi + ":N_in") == L[0]:
			r.warnungen.append("FI: L und N am Eingang vertauscht.")
	# Kurzschluss L-N
	for l_ in L:
		if l_ in N:
			_ausloesen(r, l_, "Kurzschluss zwischen L und N")
			return
		if l_ == PE:
			_ausloesen(r, l_, "Erdschluss: L hat Verbindung zum Schutzleiter")
			if fi != "": r.ausgeloest.append(fi)
			return
	if fi_N != "" and fi_N == PE:
		r.ausgeloest.append(fi)
		r.fehler.append("FI löst aus: N nach dem FI ist mit PE verbunden.")
		return
	# Verbraucher
	for id in geraete:
		var g: Dictionary = geraete[id]
		if g.typ not in ["lampe", "steckdose"]:
			continue
		if _find(id + ":PE") != PE:
			r.fehler.append("%s: Schutzleiter nicht angeschlossen." % id)
		var kl := _find(id + ":L"); var kn := _find(id + ":N")
		if kl in L and kn in N:
			if fi != "" and ((kl == fi_L) != (kn == fi_N)):
				r.ausgeloest.append(fi)
				r.fehler.append("FI löst aus: Hin- und Rückleiter von %s laufen nicht beide über den FI." % id)
				return
			if g.typ == "lampe": r.lampen_an.append(id)
		elif kl in N and kn in L:
			r.fehler.append("%s: L und N vertauscht." % id)

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
