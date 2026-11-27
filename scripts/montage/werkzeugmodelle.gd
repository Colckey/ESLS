class_name Werkzeugmodelle
extends RefCounted
## 3D-Modelle der Werkzeuge und Materialien fuer die Bilder in der Werkzeugleiste.
## Alles selbst aus Grundkoerpern gebaut (keine fremden Grafiken). Die Werkzeuge liegen in der
## xy-Ebene, z zeigt zum Betrachter. Masse in Metern.

const ROT := Color(0.82, 0.12, 0.10)
const GELB := Color(0.98, 0.78, 0.10)
const STAHL := Color(0.70, 0.72, 0.75)
const SCHWARZ := Color(0.12, 0.12, 0.13)
const KUPFER := Color(1.0, 0.62, 0.32)

static func m(c: Color, rough := 0.5, metall := 0.0) -> StandardMaterial3D:
	return Modelle.mat(c, rough, metall)

## Zylinder von a nach b (Radius unten ra, oben rb)
static func stab(p: Node3D, a: Vector3, b: Vector3, ra: float, mat: Material, rb := -1.0, seg := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = ra
	cm.top_radius = ra if rb < 0 else rb
	cm.height = a.distance_to(b)
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	var y := (b - a).normalized()
	var x := y.cross(Vector3(0, 0, 1))
	if x.length() < 0.01:
		x = y.cross(Vector3(1, 0, 0))
	x = x.normalized()
	mi.transform = Transform3D(Basis(x, y, x.cross(y)), (a + b) / 2)
	p.add_child(mi)
	return mi

static func kugel(p: Node3D, r: float, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2
	s.radial_segments = 16
	s.rings = 8
	mi.mesh = s
	mi.material_override = mat
	mi.position = pos
	p.add_child(mi)
	return mi

## Flaches Teil aus einem 2D-Umriss, dick in z
static func platte(p: Node3D, umriss: PackedVector2Array, dicke: float, mat: Material, z := 0.0) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tri := Geometry2D.triangulate_polygon(umriss)
	for seite in [[dicke / 2, 1.0], [-dicke / 2, -1.0]]:
		for i in range(0, tri.size(), 3):
			var ids := [tri[i], tri[i + 1], tri[i + 2]] if seite[1] < 0 else [tri[i], tri[i + 2], tri[i + 1]]
			for k in ids:
				st.set_normal(Vector3(0, 0, seite[1]))
				st.add_vertex(Vector3(umriss[k].x, umriss[k].y, z + seite[0]))
	var n := umriss.size()
	var cw := Geometry2D.is_polygon_clockwise(umriss)
	for i in n:
		var a := umriss[i]
		var b := umriss[(i + 1) % n]
		var d := (b - a).normalized()
		var nor := Vector3(d.y, -d.x, 0) * (-1.0 if cw else 1.0)
		var v := [Vector3(a.x, a.y, z - dicke / 2), Vector3(b.x, b.y, z - dicke / 2), Vector3(b.x, b.y, z + dicke / 2), Vector3(a.x, a.y, z + dicke / 2)]
		var reihenfolge := [0, 2, 1, 0, 3, 2] if not cw else [0, 1, 2, 0, 2, 3]
		for k in reihenfolge:
			st.set_normal(nor)
			st.add_vertex(v[k])
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	p.add_child(mi)
	return mi

static func werkzeug(name: String) -> Node3D:
	var n := Node3D.new()
	match name:
		"auswahl": _auswahl(n)
		"bohrer": _bohrmaschine(n)
		"schelle": _schelle(n)
		"seitenschneider": _zange(n, false)
		"abisolieren": _zange(n, true)
		"abmanteln": _abmantler(n)
		"anklemmen": _schraubendreher(n)
		"zollstock": _zollstock(n)
		"wasserwaage": _wasserwaage(n)
		"crimpen": _crimpzange(n)
		"bruecke": _bruecke(n)
		"phasenschiene": _phasenschiene(n)
	return n

static func _crimpzange(n: Node3D) -> void:
	var dreh := Vector3(0.02, 0.02, 0)
	for s in [-1.0, 1.0]:
		var ende := Vector3(-0.075, -0.075, 0) + Vector3(-s, s, 0) * 0.03
		stab(n, dreh + Vector3(-0.012, -0.012, 0), ende, 0.009, m(GELB, 0.6), 0.011)
		stab(n, ende + (dreh - ende).normalized() * 0.035, ende, 0.0115, m(SCHWARZ, 0.7))
		kugel(n, 0.011, ende, m(SCHWARZ, 0.7))
	# Crimpbacken mit Sechskant-Gesenk
	var g := Node3D.new()
	g.position = dreh + Vector3(0.028, 0.028, 0)
	g.rotation.z = PI / 4
	n.add_child(g)
	Modelle.box(g, Vector3(0.05, 0.034, 0.012), Vector3.ZERO, m(Color(0.32, 0.34, 0.37), 0.35, 0.7))
	Modelle.zyl(g, 0.006, 0.014, Vector3(0.004, 0, 0), m(SCHWARZ), 6)
	Modelle.zyl(n, 0.009, 0.02, dreh, m(STAHL, 0.3, 0.8), 14)
	# Aderendhuelse (rot) im Gesenk
	stab(n, g.position + Vector3(-0.004, 0.012, 0.008), g.position + Vector3(0.012, 0.028, 0.008), 0.0045, m(Color(0.85, 0.1, 0.1), 0.45))

static func _bruecke(n: Node3D) -> void:
	var braun := m(Color(0.45, 0.25, 0.12), 0.5)
	var pts := [Vector3(-0.07, -0.04, 0), Vector3(-0.06, 0.02, 0), Vector3(-0.02, 0.05, 0), Vector3(0.02, 0.05, 0), Vector3(0.06, 0.02, 0), Vector3(0.07, -0.04, 0)]
	for i in range(pts.size() - 1):
		stab(n, pts[i], pts[i + 1], 0.0045, braun)
		kugel(n, 0.0045, pts[i + 1], braun)
	for p in [pts[0], pts[-1]]:
		stab(n, p, p + Vector3(0, -0.012, 0), 0.0065, m(Color(0.85, 0.1, 0.1), 0.45))
		stab(n, p + Vector3(0, -0.012, 0), p + Vector3(0, -0.032, 0), 0.0045, m(Color(0.82, 0.83, 0.86), 0.25, 0.8))

static func _phasenschiene(n: Node3D) -> void:
	Modelle.box(n, Vector3(0.2, 0.026, 0.012), Vector3(0, 0.01, 0), m(Color(0.93, 0.93, 0.9), 0.5))
	Modelle.box(n, Vector3(0.2, 0.008, 0.013), Vector3(0, 0.016, 0), m(Color(0.86, 0.55, 0.3), 0.3, 0.7))
	for i in 6:
		Modelle.box(n, Vector3(0.008, 0.03, 0.004), Vector3(-0.085 + i * 0.034, -0.015, 0), m(Color(0.86, 0.55, 0.3), 0.3, 0.7))

static func _auswahl(n: Node3D) -> void:
	var pfeil := PackedVector2Array([Vector2(0, 0), Vector2(0, -0.16), Vector2(0.036, -0.124), Vector2(0.062, -0.18),
		Vector2(0.086, -0.17), Vector2(0.06, -0.114), Vector2(0.11, -0.11)])
	platte(n, pfeil, 0.012, m(Color(0.97, 0.97, 0.97), 0.4))
	var rand := PackedVector2Array()
	for v in pfeil: rand.append(v)
	# schwarzer Rand: etwas groessere Platte dahinter
	var gross := PackedVector2Array()
	var mitte := Vector2(0.04, -0.1)
	for v in pfeil: gross.append(mitte + (v - mitte) * 1.12)
	platte(n, gross, 0.008, m(SCHWARZ), -0.004)

static func _bohrmaschine(n: Node3D) -> void:
	var koerper := m(Color(0.10, 0.55, 0.60), 0.45)
	stab(n, Vector3(-0.08, 0.03, 0), Vector3(0.035, 0.03, 0), 0.026, koerper, 0.022)
	kugel(n, 0.026, Vector3(-0.08, 0.03, 0), koerper)
	stab(n, Vector3(0.035, 0.03, 0), Vector3(0.068, 0.03, 0), 0.016, m(SCHWARZ, 0.6), 0.012)
	stab(n, Vector3(0.068, 0.03, 0), Vector3(0.125, 0.03, 0), 0.0035, m(STAHL, 0.3, 0.8), 0.0025)
	stab(n, Vector3(-0.035, 0.012, 0), Vector3(-0.05, -0.06, 0), 0.015, m(Color(0.2, 0.21, 0.23), 0.7))
	Modelle.box(n, Vector3(0.07, 0.028, 0.045), Vector3(-0.055, -0.078, 0), m(Color(0.25, 0.26, 0.28), 0.6))
	Modelle.box(n, Vector3(0.05, 0.006, 0.047), Vector3(-0.055, -0.062, 0), koerper)
	Modelle.box(n, Vector3(0.01, 0.018, 0.012), Vector3(-0.022, 0.0, 0), m(ROT, 0.5))

static func _schelle(n: Node3D) -> void:
	var r := 0.0045
	stab(n, Vector3(-0.045, 0, r), Vector3(0.045, 0, r), r, m(Modelle.NYM, 0.55))
	Modelle.rohrschelle(n, Vector3(0, 0, 0), r, false)
	Modelle.box(n, Vector3(0.11, 0.06, 0.004), Vector3(0, 0, -0.002), m(Color(0.86, 0.70, 0.48), 0.8))

## Zange: Seitenschneider (kurze Schneiden) oder Abisolierzange (lange Backen mit Kerben)
static func _zange(n: Node3D, abisolier: bool) -> void:
	var dreh := Vector3(0.015, 0.015, 0)
	var griff_farbe := ROT if not abisolier else Color(0.15, 0.35, 0.80)
	for s in [-1.0, 1.0]:
		var ende := Vector3(-0.07, -0.07, 0) + Vector3(-s, s, 0) * 0.025
		stab(n, dreh + Vector3(-0.012, -0.012, 0), ende, 0.0085, m(griff_farbe, 0.6), 0.0105)
		stab(n, ende + (dreh - ende).normalized() * 0.03, ende + (dreh - ende).normalized() * 0.04, 0.0112, m(GELB, 0.6))
		kugel(n, 0.0105, ende, m(griff_farbe, 0.6))
		var spitze := dreh + Vector3(0.05, 0.05, 0) + Vector3(-s, s, 0) * (0.004 if not abisolier else 0.003)
		if abisolier:
			spitze = dreh + Vector3(0.065, 0.065, 0) + Vector3(-s, s, 0) * 0.003
		stab(n, dreh, spitze, 0.0085 if not abisolier else 0.006, m(Color(0.32, 0.34, 0.37), 0.35, 0.7), 0.002)
	Modelle.zyl(n, 0.009, 0.02, dreh, m(STAHL, 0.3, 0.8), 14)
	if abisolier:
		for i in 3:
			var p := dreh + Vector3(0.022, 0.022, 0) * (1 + i * 0.55)
			Modelle.zyl(n, 0.0022 - i * 0.0005, 0.02, p, m(SCHWARZ), 8)

static func _abmantler(n: Node3D) -> void:
	var t := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.026
	tm.outer_radius = 0.04
	tm.rings = 24
	tm.ring_segments = 12
	t.mesh = tm
	t.material_override = m(Color(0.15, 0.35, 0.80), 0.5)
	t.rotation_degrees = Vector3(90, 0, 0)
	t.position = Vector3(0.0, 0.02, 0)
	n.add_child(t)
	stab(n, Vector3(0, -0.015, 0), Vector3(0, -0.10, 0), 0.012, m(GELB, 0.6), 0.013)
	kugel(n, 0.013, Vector3(0, -0.10, 0), m(GELB, 0.6))
	# Messer und Haken innen
	platte(n, PackedVector2Array([Vector2(-0.004, -0.002), Vector2(0.004, -0.002), Vector2(0.001, 0.022), Vector2(-0.001, 0.022)]), 0.003, m(STAHL, 0.25, 0.9))
	stab(n, Vector3(-0.02, 0.05, 0), Vector3(0.02, 0.05, 0), 0.004, m(STAHL, 0.3, 0.8))
	# Stueck Leitung im Werkzeug
	stab(n, Vector3(-0.06, 0.022, 0.0), Vector3(0.06, 0.022, 0.0), 0.0055, m(Modelle.NYM, 0.55))

static func _schraubendreher(n: Node3D) -> void:
	var a := Vector3(-0.085, -0.085, 0)
	var d := Vector3(1, 1, 0).normalized()
	stab(n, a, a + d * 0.09, 0.014, m(ROT, 0.55), 0.012)
	kugel(n, 0.014, a, m(ROT, 0.55))
	stab(n, a + d * 0.06, a + d * 0.075, 0.0128, m(GELB, 0.55))
	stab(n, a + d * 0.09, a + d * 0.105, 0.012, m(GELB, 0.55), 0.005)
	stab(n, a + d * 0.105, a + d * 0.2, 0.0042, m(ROT, 0.5))
	stab(n, a + d * 0.2, a + d * 0.225, 0.0032, m(STAHL, 0.25, 0.9), 0.0018)
	var spitze := Modelle.box(n, Vector3(0.007, 0.012, 0.0014), a + d * 0.23, m(STAHL, 0.25, 0.9))
	spitze.rotation.z = -PI / 4

static func _zollstock(n: Node3D) -> void:
	var punkte := [Vector3(-0.09, -0.06, 0), Vector3(0.0, -0.06, 0), Vector3(-0.05, 0.02, 0), Vector3(0.05, 0.02, 0), Vector3(0.0, 0.10, 0)]
	for i in range(punkte.size() - 1):
		var a: Vector3 = punkte[i]
		var b: Vector3 = punkte[i + 1]
		var d := (b - a).normalized()
		var g := Node3D.new()
		g.position = (a + b) / 2 + Vector3(0, 0, i * 0.003)
		g.rotation.z = atan2(d.y, d.x)
		n.add_child(g)
		var l := a.distance_to(b)
		Modelle.box(g, Vector3(l + 0.01, 0.017, 0.003), Vector3.ZERO, m(GELB, 0.5))
		for k in range(1, int(l * 100)):
			var lang := 0.007 if k % 5 == 0 else 0.004
			Modelle.box(g, Vector3(0.0006, lang, 0.0005), Vector3(-l / 2 + k * 0.01, 0.0085 - lang / 2, 0.0017), m(SCHWARZ))
		Modelle.zyl(n, 0.004, 0.008, a + Vector3(0, 0, i * 0.003), m(STAHL, 0.3, 0.8), 10)

static func _wasserwaage(n: Node3D) -> void:
	var g := Node3D.new()
	g.rotation.z = 0.35
	n.add_child(g)
	Modelle.box(g, Vector3(0.24, 0.032, 0.018), Vector3.ZERO, m(Color(0.80, 0.82, 0.85), 0.3, 0.7))
	Modelle.box(g, Vector3(0.24, 0.007, 0.0185), Vector3(0, 0.0125, 0), m(Color(0.2, 0.35, 0.75), 0.5))
	Modelle.box(g, Vector3(0.05, 0.016, 0.004), Vector3(0, -0.003, 0.009), m(Color(0.7, 0.95, 0.3), 0.15))
	Modelle.zyl(g, 0.0045, 0.002, Vector3(0, -0.003, 0.0115), m(Color(1, 1, 0.92), 0.1), 12)
	for s in [-0.012, 0.012]:
		Modelle.box(g, Vector3(0.0012, 0.016, 0.001), Vector3(s, -0.003, 0.0115), m(SCHWARZ))
	for s in [-0.1, 0.1]:
		Modelle.box(g, Vector3(0.012, 0.034, 0.019), Vector3(s, 0, 0), m(SCHWARZ, 0.7))

## Kurzes Leitungsstueck mit abgemanteltem Ende und abisolierten Adern
static func leitung(typ: String, farben: Dictionary) -> Node3D:
	var n := Node3D.new()
	var info: Dictionary = Circuit.LEITUNGEN[typ]
	var adern: Array = info.adern
	var einzel: bool = info.get("einzelader", false)
	var r := 0.0085 if adern.size() <= 3 else 0.0105
	var a := Vector3(-0.1, -0.06, 0)
	var b := Vector3(0.0, -0.005, 0)
	if not einzel:
		var mantel := Modelle.NYM if not String(typ).begins_with("Steuer") else Color(0.5, 0.52, 0.56)
		stab(n, a, b, r, m(mantel, 0.55))
		stab(n, b - (b - a).normalized() * 0.001, b, r * 1.02, m(Color(0.97, 0.97, 0.95), 0.6))
	var cnt := adern.size()
	for i in cnt:
		var f: Color = farben.get(adern[i], Color.BLACK)
		var w := (float(i) - (cnt - 1) / 2.0) * 0.45
		var start := b if not einzel else a
		var ende := b + Vector3(cos(0.5 + w), sin(0.5 + w), 0) * 0.075
		var rad := 0.0032 if not einzel else 0.0045
		var mitte := start.lerp(ende, 0.5) + Vector3(0, 0, 0.002)
		stab(n, start + Vector3(0, 0, (i - cnt / 2.0) * 0.001), mitte, rad, m(f, 0.45))
		stab(n, mitte, ende, rad, m(f, 0.45))
		stab(n, ende, ende + (ende - mitte).normalized() * 0.018, rad * 0.65, m(KUPFER, 0.3, 0.6))
	return n
