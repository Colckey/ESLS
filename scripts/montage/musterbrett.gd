class_name Musterbrett
extends RefCounted
## Baut das komplette Uebungsbrett (Aufgabe "uebungsbrett") mit den echten Werkzeugen auf:
## bohren, Bauteile setzen, Leitungen verlegen, Iso-Schellen, abmanteln, abisolieren,
## in der Nahansicht anklemmen. Dient als Beispiel fuer Lehrer, fuer Screenshots und als Test
## fuer eine komplett fehlerfreie Montage.

const ZEILE := -0.33   # untere Geraetereihe (Unterputz-Hoehe am Brett)
const KANAL_Y := 0.38

static func aufbauen(m: Node) -> void:
	m.aufgabe_id = "uebungsbrett"
	m._neues_projekt()
	m.abisolier_mm = 10.0
	# Verteiler: FI und zwei LS rasten auf der oberen Hutschiene ein
	for g in [["fi", Vector3(-0.50, 0.17, 0)], ["ls", Vector3(-0.45, 0.17, 0)], ["ls", Vector3(-0.43, 0.17, 0)]]:
		m.bauteil_typ = g[0]
		m._bauteil_setzen(g[1])
	# Geraete auf dem Brett: vorher je zwei Bohrungen
	var plaetze := [["abzweigdose", Vector3(0.30, 0.05, 0)], ["lampe", Vector3(0.47, 0.22, 0)],
		["steckdose", Vector3(-0.18, ZEILE, 0)], ["steckdose", Vector3(-0.06, ZEILE, 0)],
		["wechselschalter", Vector3(0.06, ZEILE, 0)], ["kreuzschalter", Vector3(0.18, ZEILE, 0)],
		["wechselschalter", Vector3(0.30, ZEILE, 0)]]
	for g in plaetze:
		var p: Vector3 = g[1]
		m._bohren(p + Vector3(-0.02, -0.02, 0))
		m._bohren(p + Vector3(0.02, 0.02, 0))
		m.bauteil_typ = g[0]
		m._bauteil_setzen(p)
	# Leitungen (Punkte: Start, Eckpunkte, Ziel)
	var wege := [
		["NYM-J 3x1,5", [Vector3(-0.45, 0.17, 0), Vector3(-0.45, KANAL_Y, 0), Vector3(0.30, KANAL_Y, 0), Vector3(0.30, 0.05, 0)]],  # W1 LS1 -> Dose
		["NYM-J 5x1,5", [Vector3(0.30, 0.05, 0), Vector3(0.30, 0.07, 0), Vector3(0.06, 0.07, 0), Vector3(0.06, ZEILE, 0)]],      # W2 Dose -> ws1
		["NYM-J 5x1,5", [Vector3(0.30, 0.05, 0), Vector3(0.30, 0.03, 0), Vector3(0.18, 0.03, 0), Vector3(0.18, ZEILE, 0)]],      # W3 Dose -> x1
		["NYM-J 5x1,5", [Vector3(0.30, 0.05, 0), Vector3(0.30, ZEILE, 0)]],                                                       # W4 Dose -> ws2
		["NYM-J 3x1,5", [Vector3(0.30, 0.05, 0), Vector3(0.47, 0.05, 0), Vector3(0.47, 0.22, 0)]],                               # W5 Dose -> Leuchte
		["NYM-J 3x2,5", [Vector3(-0.43, 0.17, 0), Vector3(-0.43, KANAL_Y, 0), Vector3(-0.18, KANAL_Y, 0), Vector3(-0.18, ZEILE, 0)]],  # W6 LS2 -> sd1
		["NYM-J 3x2,5", [Vector3(-0.18, ZEILE, 0), Vector3(-0.06, ZEILE, 0)]],                                                    # W7 sd1 -> sd2
	]
	m._werkzeug_waehlen(m.Werkzeug.LEITUNG)
	for w in wege:
		m.leitung_typ = w[0]
		for p in w[1]:
			m._leitung_klick(p)
	for l in m.circuit.leitungen:
		schellen_setzen(m, l)
	# Abmanteln und abisolieren an jedem Geraet (jeder Klick bearbeitet das naechste Leitungsende)
	for id in m.circuit.geraete.keys():
		var pos: Vector3 = m.circuit.geraete[id].pos
		for i in 6:
			m._abmanteln(pos)
			m._abisolieren(pos)
	_verdrahten(m)
	m._werkzeug_waehlen(m.Werkzeug.AUSWAHL)

## Iso-Schellen ausserhalb von Kabelkanal und Verteiler: hoechstens 18 cm Abstand,
## 8 cm vor jedem Geraet, 4 cm nach dem Kanal/Verteiler. Vorher wird gebohrt.
static func schellen_setzen(m: Node, l: Dictionary) -> void:
	var pts: Array = l.punkte
	var lauf := 0.0
	var halt := []    # befestigte Bereiche [von, bis]
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var lg := a.distance_to(b)
		for feld in Circuit.BEFESTIGT:
			var ab := Circuit._im_rechteck(Vector2(a.x, a.y), Vector2(b.x, b.y), feld)
			if not ab.is_empty():
				halt.append([lauf + ab[0] * lg, lauf + ab[1] * lg])
		lauf += lg
	var gesamt := lauf
	halt.sort_custom(func(x, y): return x[0] < y[0])
	# freie Abschnitte bestimmen
	var frei := []
	var pos := 0.0
	for h in halt:
		if h[0] > pos + 0.001: frei.append([pos, h[0]])
		pos = maxf(pos, h[1])
	if pos < gesamt - 0.001: frei.append([pos, gesamt])
	for f in frei:
		var a: float = f[0] + (0.08 if f[0] < 0.001 else 0.04)
		var b: float = f[1] - (0.08 if f[1] > gesamt - 0.001 else 0.04)
		if f[1] - f[0] <= 0.2 and f[0] > 0.001 and f[1] < gesamt - 0.001:
			continue   # kurzes Stueck zwischen Verteiler und Kanal
		var stellen := []
		if b <= a:
			stellen = [(f[0] + f[1]) / 2]
		else:
			var n := int(ceil((b - a) / 0.18))
			for k in n + 1:
				stellen.append(a + (b - a) * k / maxf(n, 1))
		for t in stellen:
			var p := _punkt_bei(pts, t)
			m._bohren(p)
			m._schelle_setzen(p)

static func _punkt_bei(pts: Array, t: float) -> Vector3:
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var lg := a.distance_to(b)
		if t <= lg:
			return a.lerp(b, t / lg)
		t -= lg
	return pts[pts.size() - 1]

static func _verdrahten(m: Node) -> void:
	var w := {}
	for l in m.circuit.leitungen:
		w[l.id] = l
	m._nahansicht_oeffnen("fi1")
	var n: Nahansicht = m.nahansicht
	# Verteiler: Bruecken mit H07V-K
	for b in [["bn", "netz:L", "fi1:L_in"], ["bu", "netz:N", "fi1:N_in"], ["bn", "fi1:L_out", "ls1:in"],
			["bn", "ls1:in", "ls2:in"], ["bu", "fi1:N_out", "x_n:1"], ["gnye", "netz:PE", "x_pe:1"]]:
		n.bruecken_farbe = b[0]
		n._bruecke_legen(b[1], b[2])
	# Adern: [Leitung, Index, Ende, Klemme]   NYM-J 3x: bn bu gnye   NYM-J 5x: bn bk gy bu gnye
	var adern := [
		["W1", 0, "von", "ls1:out"], ["W1", 1, "von", "x_n:2"], ["W1", 2, "von", "x_pe:2"],
		["W6", 0, "von", "ls2:out"], ["W6", 1, "von", "x_n:3"], ["W6", 2, "von", "x_pe:3"],
	]
	_klemmen(n, w, adern)
	m._nahansicht_oeffnen("dose1")
	for i in 8:
		n._klemme_einsetzen()
	adern = [
		["W1", 0, "nach", "dose1_k1:a"], ["W2", 0, "von", "dose1_k1:b"],                                   # L zum ws1
		["W1", 1, "nach", "dose1_k2:a"], ["W5", 1, "von", "dose1_k2:b"],                                   # N
		["W1", 2, "nach", "dose1_k3:a"], ["W5", 2, "von", "dose1_k3:b"], ["W2", 4, "von", "dose1_k3:c"],  # PE durchverbinden
		["W3", 4, "von", "dose1_k3:d"], ["W4", 4, "von", "dose1_k3:e"],
		["W4", 0, "von", "dose1_k4:a"], ["W5", 0, "von", "dose1_k4:b"],                                   # Schaltdraht zur Leuchte
		["W2", 1, "von", "dose1_k5:a"], ["W3", 0, "von", "dose1_k5:b"],                                   # ws1:1 - x1:1
		["W2", 2, "von", "dose1_k6:a"], ["W3", 1, "von", "dose1_k6:b"],                                   # ws1:2 - x1:2
		["W3", 2, "von", "dose1_k7:a"], ["W4", 1, "von", "dose1_k7:b"],                                   # x1:3 - ws2:1
		["W3", 3, "von", "dose1_k8:a"], ["W4", 2, "von", "dose1_k8:b"],                                   # x1:4 - ws2:2
	]
	_klemmen(n, w, adern)
	_klemmen(n, w, [["W2", 0, "nach", "ws1:L"], ["W2", 1, "nach", "ws1:1"], ["W2", 2, "nach", "ws1:2"]])
	_klemmen(n, w, [["W3", 0, "nach", "x1:1"], ["W3", 1, "nach", "x1:2"], ["W3", 2, "nach", "x1:3"], ["W3", 3, "nach", "x1:4"]])
	_klemmen(n, w, [["W4", 0, "nach", "ws2:L"], ["W4", 1, "nach", "ws2:1"], ["W4", 2, "nach", "ws2:2"]])
	_klemmen(n, w, [["W5", 0, "nach", "lampe1:L"], ["W5", 1, "nach", "lampe1:N"], ["W5", 2, "nach", "lampe1:PE"]])
	_klemmen(n, w, [["W6", 0, "nach", "sd1:L"], ["W6", 1, "nach", "sd1:N"], ["W6", 2, "nach", "sd1:PE"],
		["W7", 0, "von", "sd1:L"], ["W7", 1, "von", "sd1:N"], ["W7", 2, "von", "sd1:PE"],
		["W7", 0, "nach", "sd2:L"], ["W7", 1, "nach", "sd2:N"], ["W7", 2, "nach", "sd2:PE"]])
	n.hide()

static func _klemmen(n: Nahansicht, w: Dictionary, liste: Array) -> void:
	for a in liste:
		n._anklemmen(w[a[0]], a[1], a[2], a[3])
