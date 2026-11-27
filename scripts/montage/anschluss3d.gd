class_name Anschluss3D
extends SubViewportContainer
## 3D-Anschlussansicht (in der Nahansicht): das Geraet ist geoeffnet, man sieht seine Klemmen.
## Die Leitungen kommen von unten. Man mantelt die Leitung ab, isoliert jede Ader ab und
## steckt sie in die Klemme. Masseinheit hier: 1 = 1 cm.
## Klicks werden ueber das Signal "geklickt" an die Nahansicht gemeldet.

signal geklickt(art: String, daten: Dictionary)   # art: "mantel", "ader", "klemme", "bruecke"
signal ueber(text: String)

const REIHE_MAX := 58.0
const KLEMMEN_ABSTAND := 2.6

var vp: SubViewport
var cam: Camera3D
var welt: Node3D
var picks := []          # [{pos, art, daten, text}]
var yaw := 0.0
var pitch := -0.32
var dist := 50.0
var ziel := Vector3.ZERO
var _drehen := false

func _init() -> void:
	stretch = true
	custom_minimum_size = Vector2(812, 450)
	mouse_filter = Control.MOUSE_FILTER_STOP
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	add_child(vp)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.86, 0.80, 0.68)   # Holz des Bretts
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1, 1, 1)
	e.ambient_light_energy = 0.45
	env.environment = e
	vp.add_child(env)
	var licht := DirectionalLight3D.new()
	licht.rotation_degrees = Vector3(-40, -25, 0)
	licht.light_energy = 0.55
	vp.add_child(licht)
	cam = Camera3D.new()
	cam.fov = 40
	vp.add_child(cam)
	welt = Node3D.new()
	vp.add_child(welt)
	_kamera()

func _kamera() -> void:
	pitch = clampf(pitch, -0.9, 0.2)
	yaw = clampf(yaw, -0.8, 0.8)
	dist = clampf(dist, 12.0, 120.0)
	var pos := ziel + Vector3(sin(yaw) * cos(pitch), sin(-pitch), cos(yaw) * cos(pitch)) * dist
	cam.transform = Transform3D(Basis.looking_at(ziel - pos, Vector3.UP), pos)

# ---------------------------------------------------------------- Aufbau

## c: Schaltung, gruppe: Geraete-IDs, auswahl: aktuelle Auswahl der Nahansicht, farben: Aderfarben
func aufbauen(c: Circuit, gruppe: Array, auswahl: Dictionary, farben: Dictionary, bauteile: Dictionary) -> void:
	for k in welt.get_children():
		k.queue_free()
	picks.clear()
	var klemme_pos := {}
	# Geraete in Reihen anordnen
	var reihen := [[]]
	var breite_reihe := 0.0
	for gid in gruppe:
		var ks: Array = Circuit.TYPEN[c.geraete[gid].typ]
		if ks.is_empty():
			continue
		var b := maxf(ks.size(), 2) * KLEMMEN_ABSTAND + 1.6
		if breite_reihe + b > REIHE_MAX and not reihen[-1].is_empty():
			reihen.append([])
			breite_reihe = 0.0
		reihen[-1].append([gid, b])
		breite_reihe += b + 1.2
	var y := 0.0
	var max_breite := 16.0
	for reihe in reihen:
		var gesamt := 0.0
		for g in reihe: gesamt += g[1] + 1.2
		max_breite = maxf(max_breite, gesamt)
		var x := -gesamt / 2
		for g in reihe:
			_geraet(c, g[0], Vector3(x + g[1] / 2, y, 0), g[1], klemme_pos, auswahl, bauteile)
			x += g[1] + 1.2
		y -= 13.0
	var unten := y + 13.0 - 9.0
	# Leitungsenden von unten
	var enden := []
	for l in c.leitungen:
		if Circuit.LEITUNGEN[l.typ].get("einzelader", false):
			continue
		for e in [["start_geraet", "von", "start"], ["ende_geraet", "nach", "ende"]]:
			if l.get(e[0], "") in gruppe:
				enden.append([l, e[1], e[2]])
	var abstand := maxf(7.0, max_breite / maxf(enden.size(), 1))
	abstand = minf(abstand, 12.0)
	var x0 := -abstand * (enden.size() - 1) / 2.0
	for i in enden.size():
		_leitungsende(enden[i][0], enden[i][1], enden[i][2], Vector3(x0 + i * abstand, unten, 0), klemme_pos, auswahl, farben)
	# Bruecken im Verteiler (H07V-K) und Phasenschiene
	for l in c.leitungen:
		var info: Dictionary = Circuit.LEITUNGEN[l.typ]
		if not info.get("einzelader", false):
			continue
		if info.get("schiene", false):
			_schiene(l, klemme_pos)
			continue
		var a: Dictionary = l.adern[0]
		if klemme_pos.has(a.von) and klemme_pos.has(a.nach):
			var p1: Vector3 = klemme_pos[a.von]
			var p2: Vector3 = klemme_pos[a.nach]
			var mitte := (p1 + p2) / 2 + Vector3(0, 0, 3.0 + p1.distance_to(p2) * 0.08)
			var pts := _kurve([p1 + Vector3(0, 0, 0.3), p1 + Vector3(0, 0, 2), mitte, p2 + Vector3(0, 0, 2), p2 + Vector3(0, 0, 0.3)])
			_schlauch(pts, 0.22, Modelle.mat(farben.get(a.farbe, Color.BLACK), 0.5))
			picks.append({"pos": mitte, "art": "bruecke", "daten": {"leitung": l}, "text": "Brücke %s: %s ↔ %s" % [l.id, a.von, a.nach]})
			for e in [["von", p1], ["nach", p2]]:
				var kp: Vector3 = e[1]
				var huelse: bool = a.get("huelse_" + e[0], false)
				if huelse:
					# Aderendhuelse: roter Kragen (1,5 mm²) und Metallhuelse in der Klemme
					Werkzeugmodelle.stab(welt, kp + Vector3(0, 0, 0.9), kp + Vector3(0, 0, 1.7), 0.36, Modelle.mat(Color(0.85, 0.1, 0.1), 0.45), 0.3)
					Werkzeugmodelle.stab(welt, kp + Vector3(0, 0, 0.0), kp + Vector3(0, 0, 0.9), 0.25, Modelle.mat(Color(0.82, 0.83, 0.86), 0.25, 0.8))
				else:
					Werkzeugmodelle.stab(welt, kp + Vector3(0, 0, 0.0), kp + Vector3(0, 0, 0.6), 0.16, Anschluss3D._kupfer())
					_markierung(kp + Vector3(0, 0, 1.7))
				picks.append({"pos": kp + Vector3(0, 0, 1.3), "art": "brueckenende", "daten": {"leitung": l, "feld": e[0]},
					"text": "Brücke %s an %s: %s" % [l.id, a[e[0]], "Aderendhülse gecrimpt" if huelse else "OHNE Aderendhülse (crimpen!)"]})
	# Zuleitung zur Hauptklemme: fest angeschlossen, kommt von links aus dem Rohr
	for gid in gruppe:
		if c.geraete[gid].typ == "einspeisung" and klemme_pos.has(gid + ":L"):
			_zuleitung(gid, klemme_pos, farben)
	# Kamera so, dass alles drauf ist
	var hoehe := -unten + 14.0
	ziel = Vector3(0, (unten - 6.0 + 9.0) / 2.0, 0)
	dist = maxf(max_breite * 1.05, hoehe * 1.3)
	_kamera()

func _geraet(c: Circuit, gid: String, pos: Vector3, breite: float, klemme_pos: Dictionary, auswahl: Dictionary, bauteile: Dictionary) -> void:
	var typ: String = c.geraete[gid].typ
	var farbe: Color = bauteile[typ].farbe if bauteile.has(typ) else Color(0.9, 0.9, 0.92, 0.9)
	if typ == "klemme":
		farbe = Color(0.85, 0.88, 0.9)
	var n := Node3D.new()
	n.position = pos
	welt.add_child(n)
	Modelle.box(n, Vector3(breite, 9.0, 2.0), Vector3(0, 0, -1.0), Modelle.mat(farbe, 0.5))
	var name: String = bauteile[typ].name if bauteile.has(typ) else "Verbindungsklemme (Wago)"
	_text(n, "%s  %s" % [gid, name], Vector3(0, 3.6, 0.05), 26, Color(0.12, 0.13, 0.16) if farbe.get_luminance() > 0.45 else Color.WHITE)
	var ks: Array = Circuit.TYPEN[typ]
	var x0 := -KLEMMEN_ABSTAND * (ks.size() - 1) / 2.0
	for i in ks.size():
		var kid := "%s:%s" % [gid, ks[i]]
		var kp := Vector3(x0 + i * KLEMMEN_ABSTAND, -0.6, 0)
		var gewaehlt: bool = auswahl.get("art", "") == "klemme" and auswahl.get("klemme", "") == kid
		var sockel_farbe := Color(0.95, 0.55, 0.12) if typ == "klemme" else Color(0.78, 0.79, 0.8)
		Modelle.box(n, Vector3(2.0, 3.6, 0.8), kp + Vector3(0, 0, 0.4), Modelle.mat(sockel_farbe, 0.4, 0.3 if typ != "klemme" else 0.0))
		var schraube := Modelle.zyl(n, 0.75, 0.4, kp + Vector3(0, 0.6, 1.0), Modelle.mat(Color(0.75, 0.76, 0.78), 0.3, 0.8), 14)
		Modelle.box(n, Vector3(1.1, 0.18, 0.1), kp + Vector3(0, 0.6, 1.25), Modelle.mat(Color(0.3, 0.3, 0.32), 0.5))
		Modelle.box(n, Vector3(1.3, 0.9, 0.3), kp + Vector3(0, -0.9, 0.75), Modelle.mat(Color(0.12, 0.12, 0.14), 0.8))   # Einfuehrung
		if gewaehlt:
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.2, 0.55, 1.0)
			m.emission_enabled = true
			m.emission = Color(0.2, 0.55, 1.0)
			schraube.material_override = m
		_text(n, ks[i], kp + Vector3(0, -2.4, 0.9), 30, Color(0.1, 0.1, 0.12))
		klemme_pos[kid] = pos + kp + Vector3(0, -0.9, 0.9)
		picks.append({"pos": pos + kp + Vector3(0, 0, 1.0), "art": "klemme", "daten": {"klemme": kid}, "text": "Klemme %s" % kid})

func _leitungsende(l: Dictionary, feld: String, ende: String, basis: Vector3, klemme_pos: Dictionary, auswahl: Dictionary, farben: Dictionary) -> void:
	var info: Dictionary = Circuit.LEITUNGEN[l.typ]
	var mantel_farbe := Modelle.NYM if not String(l.typ).begins_with("Steuer") else Color(0.5, 0.52, 0.56)
	var ab: bool = l.abgemantelt.get(ende, false)
	var r := 0.55 if info.adern.size() <= 3 else 0.68
	var oben := basis + Vector3(0, -2.0 if ab else 1.5, 0)
	_schlauch([basis + Vector3(0, -9, 0), oben], r, Modelle.mat(mantel_farbe, 0.55))
	_text_welt("%s  %s%s" % [l.id, l.typ, "" if ab else "  (Mantel)"], basis + Vector3(0, -10.3, 0.5), 24, Color(0.15, 0.15, 0.18))
	picks.append({"pos": basis + Vector3(0, -5, r), "art": "mantel", "daten": {"leitung": l, "ende": ende},
		"text": "%s %s: %s" % [l.id, l.typ, "abgemantelt" if ab else "noch ummantelt, mit dem Abmantelungswerkzeug anklicken"]})
	if not ab:
		return
	var n: int = l.adern.size()
	for i in n:
		var a: Dictionary = l.adern[i]
		var farbe: Color = farben.get(a.farbe, Color(0.1, 0.1, 0.1))
		var mat := Modelle.mat(farbe, 0.5)
		var gewaehlt: bool = auswahl.get("art", "") == "ader" and auswahl.get("leitung") == l and auswahl.get("index", -1) == i and auswahl.get("feld", "") == feld
		if gewaehlt:
			mat = StandardMaterial3D.new()
			mat.albedo_color = farbe
			mat.emission_enabled = true
			mat.emission = Color(0.2, 0.55, 1.0)
			mat.emission_energy_multiplier = 0.8
		var start := oben + Vector3((i - (n - 1) / 2.0) * 0.5, 0, 0)
		var mm: float = a.get("abisoliert_" + feld, 0.0)
		var ziel_k: String = a.get(feld, "")
		var text := "%s Ader %s%s" % [l.id, a.farbe, (", %d mm abisoliert" % mm) if mm > 0 else ", isoliert"]
		if ziel_k != "" and klemme_pos.has(ziel_k):
			var kp: Vector3 = klemme_pos[ziel_k]
			var pts := _kurve([start, start + Vector3(0, 3, 0), kp + Vector3(0, -3.5, 0.6), kp + Vector3(0, -1.2, 0.2)])
			_schlauch(pts, 0.2, mat)
			_schlauch([kp + Vector3(0, -1.2, 0.2), kp], 0.14, _kupfer())
			picks.append({"pos": pts[pts.size() / 2], "art": "ader", "daten": {"leitung": l, "index": i, "feld": feld}, "text": text + " → " + ziel_k})
		else:
			var spitze := start + Vector3((i - (n - 1) / 2.0) * 0.9, 4.5, 0.4)
			_schlauch(_kurve([start, start + Vector3(0, 2, 0), spitze]), 0.2, mat)
			if mm > 0:
				var richtung := (spitze - start).normalized()
				_schlauch([spitze - richtung * 0.05, spitze + richtung * mm / 10.0 * 1.4], 0.16, _kupfer())
			picks.append({"pos": spitze, "art": "ader", "daten": {"leitung": l, "index": i, "feld": feld}, "text": text})

func _text(n: Node3D, t: String, pos: Vector3, groesse: int, farbe: Color) -> void:
	var l := Label3D.new()
	l.text = t
	l.font_size = groesse
	l.pixel_size = 0.02
	l.modulate = farbe
	l.outline_size = 0
	l.position = pos
	n.add_child(l)

func _text_welt(t: String, pos: Vector3, groesse: int, farbe: Color) -> void:
	_text(welt, t, pos, groesse, farbe)

## Glatte Kurve durch die Punkte (Catmull-Rom)
func _kurve(p: Array) -> Array:
	var r := []
	for i in range(p.size() - 1):
		var p0: Vector3 = p[maxi(i - 1, 0)]
		var p1: Vector3 = p[i]
		var p2: Vector3 = p[i + 1]
		var p3: Vector3 = p[mini(i + 2, p.size() - 1)]
		for s in 6:
			var t := s / 6.0
			r.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t * t + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t * t * t))
	r.append(p[p.size() - 1])
	return r

## Rundes Rohr entlang beliebiger Punkte
func _schlauch(pts: Array, r: float, m: Material) -> void:
	const SEG := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		if a.distance_to(b) < 0.0001:
			continue
		var dir := (b - a).normalized()
		var hilf := Vector3(0, 0, 1) if absf(dir.z) < 0.9 else Vector3(1, 0, 0)
		var seite := dir.cross(hilf).normalized()
		var hoch := seite.cross(dir).normalized()
		for s in SEG:
			var t0 := TAU * s / SEG
			var t1 := TAU * (s + 1) / SEG
			var n0 := seite * cos(t0) + hoch * sin(t0)
			var n1 := seite * cos(t1) + hoch * sin(t1)
			for v in [[a, n0], [b, n0], [b, n1], [a, n0], [b, n1], [a, n1]]:
				st.set_normal(v[1])
				st.add_vertex(v[0] + v[1] * r)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	welt.add_child(mi)

# ---------------------------------------------------------------- Eingabe

func _naechster(maus: Vector2) -> Dictionary:
	var best := {}
	var bd := 22.0
	for p in picks:
		if cam.is_position_behind(p.pos):
			continue
		var sp := cam.unproject_position(p.pos)
		var d := sp.distance_to(maus)
		if d < bd:
			bd = d
			best = p
	return best

func _gui_input(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			var p := _naechster(mb.position)
			if not p.is_empty():
				geklickt.emit(p.art, p.daten)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			dist *= 0.9
			_kamera()
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			dist /= 0.9
			_kamera()
			accept_event()
	elif ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			yaw -= mm.relative.x * 0.006
			pitch += mm.relative.y * 0.006
			_kamera()
		elif mm.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			ziel -= Vector3(mm.relative.x, -mm.relative.y, 0) * dist * 0.0015
			_kamera()
		else:
			var p := _naechster(mm.position)
			ueber.emit(p.get("text", ""))

## Blankes Kupfer: hell und leicht leuchtend, damit man es von der braunen Ader unterscheidet
static func _kupfer() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.68, 0.38)
	m.metallic = 0.5
	m.roughness = 0.25
	m.emission_enabled = true
	m.emission = Color(0.55, 0.3, 0.1)
	return m

## Gelber Punkt ueber einem Brueckenende ohne Aderendhuelse
func _markierung(pos: Vector3) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(1.0, 0.85, 0.1)
	m.emission_enabled = true
	m.emission = Color(0.9, 0.7, 0.0)
	Werkzeugmodelle.kugel(welt, 0.42, pos, m)

## Phasenschiene: Kupferschiene ueber den Klemmen mit Zaehnen in jede Klemme
func _schiene(l: Dictionary, klemme_pos: Dictionary) -> void:
	var punkte := []
	for a in l.adern:
		for f in ["von", "nach"]:
			if klemme_pos.has(a[f]) and not (klemme_pos[a[f]] in punkte):
				punkte.append(klemme_pos[a[f]])
	if punkte.size() < 2:
		return
	punkte.sort_custom(func(x: Vector3, y: Vector3) -> bool: return x.x < y.x)
	var hoehe := 1.8
	var kupfer := Modelle.mat(Color(0.86, 0.55, 0.3), 0.3, 0.7)
	var isolierung := Modelle.mat(Color(0.55, 0.57, 0.6), 0.5)
	var a: Vector3 = punkte[0]
	var b: Vector3 = punkte[-1]
	var y := maxf(a.y, b.y) + 3.4   # ueber den Schrauben
	Modelle.box(welt, Vector3(b.x - a.x + 1.6, 1.0, 0.8), Vector3((a.x + b.x) / 2, y, hoehe), isolierung)
	Modelle.box(welt, Vector3(b.x - a.x + 1.4, 0.45, 0.85), Vector3((a.x + b.x) / 2, y + 0.1, hoehe + 0.05), kupfer)
	for p in punkte:
		# Zahn der Kammschiene steckt von oben in die Klemme
		Modelle.box(welt, Vector3(0.7, y - p.y - 2.0, 0.3), Vector3(p.x, (y + p.y + 2.0) / 2, hoehe - 0.2), kupfer)
	picks.append({"pos": Vector3((a.x + b.x) / 2, y, hoehe + 0.4), "art": "schiene", "daten": {"leitung": l},
		"text": "Phasenschiene (Kammschiene 1-polig): verbindet %d Klemmen" % punkte.size()})
	_text_welt("Phasenschiene", Vector3((a.x + b.x) / 2, y + 0.9, hoehe + 0.5), 20, Color(0.45, 0.25, 0.1))

## Zuleitung NYM-J 3x2,5 vom CEE-Stecker an L, N, PE der Hauptklemme
func _zuleitung(gid: String, klemme_pos: Dictionary, farben: Dictionary) -> void:
	var l: Vector3 = klemme_pos[gid + ":L"]
	var start := l + Vector3(-9.0, -4.5, 0)
	var knick := l + Vector3(-4.0, -4.5, 0)
	_schlauch([start, knick], 0.7, Modelle.mat(Modelle.NYM, 0.55))
	_text_welt("Zuleitung vom CEE-Stecker\n(fest angeschlossen)", start + Vector3(0, -1.6, 0.5), 18, Color(0.3, 0.3, 0.33))
	var i := 0
	for k in [["L", "bn"], ["N", "bu"], ["PE", "gnye"]]:
		var kp: Vector3 = klemme_pos.get(gid + ":" + k[0], l)
		var ab := knick + Vector3(0, (i - 1) * 0.35, 0)
		var pts := _kurve([ab, ab + Vector3(2, 0, 0), kp + Vector3(0, -3.0, 0.6), kp + Vector3(0, -1.2, 0.2)])
		_schlauch(pts, 0.22, Modelle.mat(farben.get(k[1], Color.BLACK), 0.5))
		_schlauch([kp + Vector3(0, -1.2, 0.2), kp], 0.15, Anschluss3D._kupfer())
		i += 1
