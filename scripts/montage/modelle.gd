class_name Modelle
extends RefCounted
## 3D-Modelle der Installationsgeraete und der festen Einbauten des Uebungsbretts
## (Holzplatte, Kabelkanal, Kleinverteiler, CEE-Einspeisung).
## Alles aus einfachen Grundkoerpern, damit es auch auf schwachen Schul-PCs fluessig laeuft.
## Koordinaten: Geraetemitte auf der Brettoberflaeche, z zeigt aus dem Brett heraus.

const WEISS := Color(0.95, 0.95, 0.93)
const REINWEISS := Color(0.93, 0.93, 0.92)
const GEHAEUSE := Color(0.50, 0.58, 0.68)      # AP-Gehaeuse blaugrau (wie am Schulbrett)
const DUNKEL := Color(0.16, 0.17, 0.19)
const METALL := Color(0.72, 0.73, 0.75)
const HEBEL := Color(0.18, 0.32, 0.62)
const NYM := Color(0.80, 0.81, 0.82)
const SCHELLE := Color(0.62, 0.64, 0.67)

static var _mats := {}

## Gemeinsam genutzte Materialien (weniger Zeichenaufrufe)
static func mat(c: Color, rough := 0.6, metall := 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [c.to_html(), rough, metall]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = rough
		m.metallic = metall
		if c.a < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mats[key] = m
	return _mats[key]

## Eigenes Material, z. B. fuer Lampenglas, das leuchten kann
static func mat_eigen(c: Color, rough := 0.4) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

static func box(p: Node3D, groesse: Vector3, pos: Vector3, m: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = groesse
	mi.mesh = bm
	mi.material_override = m
	mi.position = pos
	p.add_child(mi)
	return mi

## Zylinder, dessen Achse aus dem Brett zeigt (z)
static func zyl(p: Node3D, r: float, h: float, pos: Vector3, m: Material, seg := 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	cm.radial_segments = seg
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = m
	mi.rotation_degrees = Vector3(90, 0, 0)
	mi.position = pos
	p.add_child(mi)
	return mi

static func schrift(p: Node3D, text: String, pos: Vector3, groesse := 20, farbe := DUNKEL) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = groesse
	l.pixel_size = 0.0005
	l.modulate = farbe
	l.outline_size = 0
	l.double_sided = false
	l.position = pos
	p.add_child(l)
	return l

# ---------------------------------------------------------------- Geraete

## Baut das Modell eines Geraets. Rueckgabe-Knoten hat Metadaten fuer die Zustandsanzeige:
## "wippe" (Schalter), "hebel" (LS/FI), "glas"/"licht" (Lampe), "led" (Relais), "koerper" (Hauptteil)
static func geraet(typ: String, gr: Vector3, param := {}) -> Node3D:
	var n := Node3D.new()
	match typ:
		"einspeisung": _klemmenblock(n, gr, [Color(0.45, 0.27, 0.12), Color(0.15, 0.35, 0.8), Color(0.3, 0.65, 0.25)], ["L", "N", "PE"])
		"n_schiene": _klemmenblock(n, gr, [Color(0.15, 0.38, 0.85)], ["N"])
		"pe_schiene": _klemmenblock(n, gr, [Color(0.25, 0.62, 0.25)], ["PE"])
		"fi": _reiheneinbau(n, gr, "FI 40A\n30mA", true)
		"ls": _reiheneinbau(n, gr, "B16" if int(param.get("nennstrom", 16)) == 16 else "B%d" % int(param.get("nennstrom", 16)), false)
		"schuetz": _schuetz(n, gr)
		"zeitrelais", "treppenlicht": _relais(n, gr, "TLZ" if typ == "treppenlicht" else "KT")
		"abzweigdose": _abzweigdose(n, gr, int(param.get("klemmen", 0)))
		"ausschalter", "wechselschalter", "kreuzschalter", "taster", "taster_aus": _schalter(n, gr, typ)
		"steckdose": _steckdose(n, gr)
		"lampe": _lampe(n, gr)
		_:
			n.set_meta("koerper", box(n, gr, Vector3(0, 0, gr.z / 2), mat(WEISS)))
	return n

static func _klemmenblock(n: Node3D, gr: Vector3, farben: Array, namen: Array) -> void:
	box(n, Vector3(gr.x + 0.006, 0.008, 0.007), Vector3(0, 0, 0.0035), mat(METALL, 0.35, 0.6))  # Hutschiene
	var anz := 6 if farben.size() == 1 else 3
	var b := gr.x / anz
	var koerper: MeshInstance3D
	for i in anz:
		var f: Color = farben[i % farben.size()]
		var x := -gr.x / 2 + b * (i + 0.5)
		koerper = box(n, Vector3(b * 0.92, gr.y, gr.z), Vector3(x, 0, gr.z / 2), mat(f, 0.5))
		zyl(n, b * 0.25, 0.002, Vector3(x, gr.y * 0.28, gr.z + 0.001), mat(METALL, 0.3, 0.8), 8)   # Schraube
		zyl(n, b * 0.25, 0.002, Vector3(x, -gr.y * 0.28, gr.z + 0.001), mat(METALL, 0.3, 0.8), 8)
		if anz == 3:
			schrift(n, namen[i], Vector3(x, 0, gr.z + 0.0015), 14, Color.WHITE)
	if anz == 6:
		schrift(n, namen[0], Vector3(0, 0, gr.z + 0.0015), 16, Color.WHITE)
	n.set_meta("koerper", koerper)

## LS/FI auf der Hutschiene: Gehaeuse, erhabene Front, Kipphebel
static func _reiheneinbau(n: Node3D, gr: Vector3, text: String, fi: bool) -> void:
	box(n, Vector3(gr.x + 0.004, 0.035, 0.007), Vector3(0, 0, 0.0035), mat(METALL, 0.35, 0.6))
	var k := box(n, Vector3(gr.x * 0.97, gr.y, gr.z * 0.7), Vector3(0, 0, gr.z * 0.35), mat(REINWEISS, 0.45))
	box(n, Vector3(gr.x * 0.97, gr.y * 0.45, gr.z * 0.3), Vector3(0, 0, gr.z * 0.85), mat(REINWEISS, 0.45))
	# Klemmenschrauben oben/unten
	var anz := 2 if fi else 1
	for i in anz:
		var x := 0.0 if anz == 1 else (i - 0.5) * gr.x * 0.55
		for y in [gr.y * 0.4, -gr.y * 0.4]:
			zyl(n, 0.0028, 0.002, Vector3(x, y, gr.z * 0.7 + 0.001), mat(METALL, 0.3, 0.8), 8)
	var hebel := Node3D.new()
	hebel.position = Vector3(0, 0, gr.z)
	n.add_child(hebel)
	box(hebel, Vector3(minf(gr.x * 0.6, 0.012) if not fi else 0.02, 0.012, 0.012), Vector3(0, 0.006, 0.004), mat(HEBEL, 0.4))
	n.set_meta("hebel", hebel)
	if fi:
		zyl(n, 0.0035, 0.004, Vector3(gr.x * 0.3, -gr.y * 0.15, gr.z + 0.002), mat(Color(0.95, 0.8, 0.2), 0.4), 10)
	schrift(n, text, Vector3(0, -gr.y * 0.17 if not fi else -gr.y * 0.14, gr.z + 0.0012), 11 if not fi else 13)
	n.set_meta("koerper", k)

static func _schuetz(n: Node3D, gr: Vector3) -> void:
	box(n, Vector3(gr.x + 0.004, 0.035, 0.007), Vector3(0, 0, 0.0035), mat(METALL, 0.35, 0.6))
	var k := box(n, Vector3(gr.x, gr.y, gr.z * 0.75), Vector3(0, 0, gr.z * 0.375), mat(Color(0.55, 0.57, 0.6), 0.5))
	box(n, Vector3(gr.x * 0.8, gr.y * 0.45, gr.z * 0.25), Vector3(0, 0, gr.z * 0.87), mat(REINWEISS, 0.5))
	var led := zyl(n, 0.003, 0.003, Vector3(0, gr.y * 0.12, gr.z + 0.0015), mat_eigen(Color(0.3, 0.35, 0.3)), 10)
	schrift(n, "K", Vector3(0, -gr.y * 0.08, gr.z + 0.0012), 22)
	n.set_meta("led", led)
	n.set_meta("koerper", k)

static func _relais(n: Node3D, gr: Vector3, text: String) -> void:
	box(n, Vector3(gr.x + 0.004, 0.035, 0.007), Vector3(0, 0, 0.0035), mat(METALL, 0.35, 0.6))
	var k := box(n, Vector3(gr.x * 0.97, gr.y, gr.z * 0.8), Vector3(0, 0, gr.z * 0.4), mat(Color(0.86, 0.89, 0.95), 0.45))
	zyl(n, gr.x * 0.3, 0.004, Vector3(0, gr.y * 0.05, gr.z * 0.8 + 0.002), mat(Color(0.25, 0.3, 0.4), 0.5), 14)  # Drehknopf Zeit
	var led := zyl(n, 0.0025, 0.003, Vector3(0, gr.y * 0.25, gr.z * 0.8 + 0.0015), mat_eigen(Color(0.3, 0.35, 0.3)), 10)
	schrift(n, text, Vector3(0, -gr.y * 0.2, gr.z * 0.8 + 0.0012), 12)
	n.set_meta("led", led)
	n.set_meta("koerper", k)

## Abzweigdose ohne Deckel: man sieht die Verbindungsklemmen (Wago) darin
static func _abzweigdose(n: Node3D, gr: Vector3, klemmen: int) -> void:
	var gm := mat(GEHAEUSE, 0.6)
	var w := 0.004
	var k := box(n, Vector3(gr.x, gr.y, 0.004), Vector3(0, 0, 0.002), gm)
	box(n, Vector3(gr.x, w, gr.z), Vector3(0, gr.y / 2 - w / 2, gr.z / 2), gm)
	box(n, Vector3(gr.x, w, gr.z), Vector3(0, -gr.y / 2 + w / 2, gr.z / 2), gm)
	box(n, Vector3(w, gr.y, gr.z), Vector3(gr.x / 2 - w / 2, 0, gr.z / 2), gm)
	box(n, Vector3(w, gr.y, gr.z), Vector3(-gr.x / 2 + w / 2, 0, gr.z / 2), gm)
	# Einfuehrungstuellen
	for v in [Vector2(0, 1), Vector2(0, -1), Vector2(1, 0), Vector2(-1, 0)]:
		zyl(n, 0.007, 0.003, Vector3(v.x * (gr.x / 2 - 0.012), v.y * (gr.y / 2 - 0.012), 0.005), mat(Color(0.35, 0.37, 0.4), 0.8), 10)
	# Wago-Klemmen: transparentes Gehaeuse, orange Hebel
	for i in klemmen:
		var x := -0.022 + (i % 3) * 0.022
		var y := 0.018 - (i / 3) * 0.018
		box(n, Vector3(0.018, 0.012, 0.009), Vector3(x, y, 0.009), mat(Color(0.88, 0.9, 0.92, 0.85), 0.2))
		for j in 5:
			box(n, Vector3(0.0028, 0.008, 0.003), Vector3(x - 0.007 + j * 0.0035, y - 0.001, 0.0145), mat(Color(0.95, 0.5, 0.1), 0.5))
	n.set_meta("koerper", k)

## Schalter/Taster im AP-Gehaeuse mit Wippe (die Wippe kippt je nach Stellung)
static func _schalter(n: Node3D, gr: Vector3, typ: String) -> void:
	var k := box(n, Vector3(gr.x, gr.y, gr.z * 0.7), Vector3(0, 0, gr.z * 0.35), mat(GEHAEUSE, 0.55))
	box(n, Vector3(gr.x * 0.86, gr.y * 0.86, gr.z * 0.15), Vector3(0, 0, gr.z * 0.775), mat(Color(0.84, 0.85, 0.85), 0.5))
	var wippe := Node3D.new()
	wippe.position = Vector3(0, 0, gr.z * 0.85)
	n.add_child(wippe)
	var wf := REINWEISS
	box(wippe, Vector3(gr.x * 0.58, gr.y * 0.62, 0.008), Vector3(0, 0, 0.004), mat(Color(0.98, 0.98, 0.97), 0.3))
	var m := mat(DUNKEL, 0.6)
	match typ:
		"ausschalter":
			box(wippe, Vector3(0.012, 0.0015, 0.001), Vector3(0, gr.y * 0.18, 0.0085), m)
		"wechselschalter":
			box(wippe, Vector3(0.012, 0.0015, 0.001), Vector3(0, gr.y * 0.18, 0.0085), m)
			box(wippe, Vector3(0.012, 0.0015, 0.001), Vector3(0, -gr.y * 0.18, 0.0085), m)
		"kreuzschalter":
			var a := box(wippe, Vector3(0.014, 0.0015, 0.001), Vector3(0, gr.y * 0.17, 0.0085), m)
			a.rotation_degrees = Vector3(0, 0, 35)
			var b := box(wippe, Vector3(0.014, 0.0015, 0.001), Vector3(0, gr.y * 0.17, 0.0085), m)
			b.rotation_degrees = Vector3(0, 0, -35)
		"taster", "taster_aus":
			var c := Color(0.3, 0.7, 0.35) if typ == "taster" else Color(0.85, 0.3, 0.3)
			zyl(wippe, 0.005, 0.002, Vector3(0, gr.y * 0.15, 0.009), mat(c, 0.3), 12)
	n.set_meta("wippe", wippe)
	n.set_meta("koerper", k)

static func _steckdose(n: Node3D, gr: Vector3) -> void:
	var k := box(n, Vector3(gr.x, gr.y, gr.z * 0.7), Vector3(0, 0, gr.z * 0.35), mat(GEHAEUSE, 0.55))
	box(n, Vector3(gr.x * 0.86, gr.y * 0.86, gr.z * 0.2), Vector3(0, 0, gr.z * 0.8), mat(REINWEISS, 0.4))
	var vorne := gr.z * 0.9
	zyl(n, 0.019, 0.004, Vector3(0, 0, vorne + 0.0005), mat(Color(0.72, 0.73, 0.74), 0.6), 24)
	for x in [-0.0095, 0.0095]:
		zyl(n, 0.0025, 0.002, Vector3(x, 0, vorne + 0.002), mat(DUNKEL, 0.8), 10)
	for y in [0.017, -0.017]:
		box(n, Vector3(0.006, 0.003, 0.003), Vector3(0, y, vorne + 0.002), mat(METALL, 0.3, 0.8))
	var led := zyl(n, 0.0018, 0.002, Vector3(gr.x * 0.33, -gr.y * 0.33, vorne + 0.001), mat_eigen(Color(0.75, 0.75, 0.73)), 8)
	n.set_meta("led", led)
	n.set_meta("koerper", k)

## Ovale Feuchtraumleuchte: dunkler Sockel, Glas, Schutzgitter
static func _lampe(n: Node3D, gr: Vector3) -> void:
	var sockel := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.5
	cm.bottom_radius = 0.5
	cm.height = 0.02
	cm.radial_segments = 24
	sockel.mesh = cm
	sockel.material_override = mat(Color(0.30, 0.31, 0.33), 0.6)
	sockel.rotation_degrees = Vector3(90, 0, 0)
	sockel.scale = Vector3(gr.x, 1, gr.y)
	sockel.position = Vector3(0, 0, 0.01)
	n.add_child(sockel)
	var glas := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.5
	sm.height = 1.0
	sm.radial_segments = 24
	sm.rings = 12
	sm.is_hemisphere = true
	glas.mesh = sm
	var gm := mat_eigen(Color(0.93, 0.95, 0.97, 0.78), 0.15)
	glas.material_override = gm
	glas.rotation_degrees = Vector3(90, 0, 0)
	glas.scale = Vector3(gr.x * 0.86, gr.z * 1.4, gr.y * 0.86)
	glas.position = Vector3(0, 0, 0.02)
	n.add_child(glas)
	# Gitter: zwei Querbuegel, ein Laengsbuegel
	var gitter := mat(Color(0.38, 0.39, 0.41), 0.5)
	for y in [-gr.y * 0.18, gr.y * 0.18]:
		box(n, Vector3(gr.x * 0.8, 0.003, 0.003), Vector3(0, y, 0.02 + gr.z * 0.6), gitter)
	box(n, Vector3(0.003, gr.y * 0.7, 0.003), Vector3(0, 0, 0.02 + gr.z * 0.66), gitter)
	# Lichtschein auf dem Brett (guenstiger als eine echte Lichtquelle)
	var schein := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(gr.x * 3.2, gr.y * 2.6)
	schein.mesh = qm
	var sm2 := StandardMaterial3D.new()
	sm2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm2.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm2.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(0.5, 0.0)
	var gd := Gradient.new()
	gd.set_color(0, Color(1.0, 0.85, 0.45, 0.9))
	gd.set_color(1, Color(1.0, 0.85, 0.5, 0.0))
	gt.gradient = gd
	sm2.albedo_texture = gt
	schein.material_override = sm2
	schein.position = Vector3(0, 0, 0.0015)
	schein.visible = false
	n.add_child(schein)
	var licht := schein
	n.set_meta("glas", glas)
	n.set_meta("licht", licht)
	n.set_meta("koerper", sockel)

## Schilchen unter dem Geraet mit der Betriebsmittelkennzeichnung
static func schild(n: Node3D, text: String, gr: Vector3) -> void:
	var y := -gr.y / 2 - 0.011
	box(n, Vector3(maxf(0.026, text.length() * 0.0062), 0.011, 0.0012), Vector3(0, y, 0.0006), mat(REINWEISS, 0.7))
	schrift(n, text, Vector3(0, y, 0.0014), 16)

## Zustand sichtbar machen: Wippe kippt, LS-Hebel faellt, Lampe leuchtet, LED an
static func zustand_zeigen(n: Node3D, typ: String, z: Dictionary, leuchtet: bool, ausgeloest: bool, aktiv: bool) -> void:
	if n.has_meta("wippe"):
		var st := int(z.get("stellung", 0))
		(n.get_meta("wippe") as Node3D).rotation_degrees = Vector3(-9 if st == 1 else 9, 0, 0)
	if n.has_meta("hebel"):
		var h := n.get_meta("hebel") as Node3D
		h.position.y = -0.012 if ausgeloest else 0.0
		h.rotation_degrees = Vector3(0, 0, 0)
		for k in h.get_children():
			(k as MeshInstance3D).material_override = mat(Color(0.85, 0.15, 0.12) if ausgeloest else HEBEL, 0.4)
	if n.has_meta("glas"):
		var g := (n.get_meta("glas") as MeshInstance3D).material_override as StandardMaterial3D
		g.emission_enabled = leuchtet
		g.emission = Color(1.0, 0.85, 0.5)
		g.emission_energy_multiplier = 2.2
		g.albedo_color = Color(1.0, 0.95, 0.8, 0.92) if leuchtet else Color(0.93, 0.95, 0.97, 0.78)
		(n.get_meta("licht") as Node3D).visible = leuchtet
	if n.has_meta("led"):
		var lm := (n.get_meta("led") as MeshInstance3D).material_override as StandardMaterial3D
		lm.emission_enabled = aktiv
		lm.emission = Color(0.2, 1.0, 0.3)
		lm.emission_energy_multiplier = 1.5

# ---------------------------------------------------------------- Brett und feste Einbauten

## Holzplatte (Birke-Multiplex) als Shader: Maserung vorne, Schichten an der Kante
const HOLZ_SHADER := """
shader_type spatial;
render_mode diffuse_burley;
varying vec3 lp;
varying vec3 ln;
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float rausch(vec2 p){
	vec2 i = floor(p); vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1,0)), u.x), mix(h(i + vec2(0,1)), h(i + vec2(1,1)), u.x), u.y);
}
float fbm(vec2 p){ float s = 0.0; float a = 0.5; for (int i = 0; i < 4; i++){ s += a * rausch(p); p *= 2.03; a *= 0.5; } return s; }
void vertex(){ lp = VERTEX; ln = NORMAL; }
void fragment(){
	vec3 hell = vec3(0.88, 0.81, 0.69);
	vec3 dunkel = vec3(0.77, 0.67, 0.53);
	vec3 farbe;
	if (abs(ln.z) > 0.5) {
		float verzug = fbm(lp.xy * vec2(1.2, 2.5)) * 1.6;
		float w = fbm(vec2(lp.x * 0.9, lp.y * 26.0 + verzug));
		float ringe = smoothstep(0.55, 0.95, abs(sin(w * 14.0 + lp.y * 8.0)));
		float fleck = fbm(lp.xy * vec2(3.0, 9.0));
		farbe = mix(hell, dunkel, ringe * 0.25 + fleck * 0.15);
		farbe *= 0.975 + 0.05 * rausch(lp.xy * vec2(30.0, 700.0));
	} else {
		float lage = fract(lp.z / 0.0018);
		farbe = mix(vec3(0.86, 0.75, 0.57), vec3(0.62, 0.48, 0.32), step(0.82, lage));
	}
	ALBEDO = pow(farbe, vec3(1.1));
	ROUGHNESS = 0.82;
}
"""

static func brett(p: Node3D, breite: float, hoehe: float) -> void:
	# Wand hinter dem Brett und Werkbank darunter
	box(p, Vector3(6, 4, 0.02), Vector3(0, 0.4, -0.05), mat(Color(0.90, 0.90, 0.88), 0.95))
	box(p, Vector3(6, 0.05, 0.8), Vector3(0, -hoehe / 2 - 0.045, 0.3), mat(Color(0.52, 0.53, 0.55), 0.8))
	var b := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(breite, hoehe, 0.018)
	b.mesh = bm
	var sm := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = HOLZ_SHADER
	sm.shader = sh
	b.material_override = sm
	b.position = Vector3(0, 0, -0.009)
	p.add_child(b)

## Kabelkanal oben ueber die ganze Breite (Unterteil + Deckel)
static func kabelkanal(p: Node3D, feld: Rect2) -> void:
	var c := feld.get_center()
	var m := mat(Color(0.94, 0.94, 0.93), 0.45)
	box(p, Vector3(feld.size.x, feld.size.y, 0.03), Vector3(c.x, c.y, 0.015), m)
	box(p, Vector3(feld.size.x + 0.002, feld.size.y + 0.006, 0.006), Vector3(c.x, c.y, 0.033), mat(Color(0.97, 0.97, 0.96), 0.35))
	# Fuge des Deckels und Endkappen
	box(p, Vector3(feld.size.x, 0.0015, 0.0012), Vector3(c.x, c.y + feld.size.y * 0.3, 0.0365), mat(Color(0.82, 0.82, 0.81), 0.5))
	for x in [feld.position.x, feld.end.x]:
		box(p, Vector3(0.006, feld.size.y + 0.008, 0.038), Vector3(x, c.y, 0.019), mat(Color(0.88, 0.88, 0.87), 0.5))

## Kleinverteiler: Rueckwand, Rahmen, zwei Hutschienen
static func verteiler(p: Node3D, feld: Rect2, reihen: Array) -> void:
	var c := feld.get_center()
	box(p, Vector3(feld.size.x, feld.size.y, 0.006), Vector3(c.x, c.y, 0.003), mat(Color(0.96, 0.96, 0.95), 0.6))
	var rahmen := mat(Color(0.88, 0.89, 0.9), 0.5)
	var t := 0.012
	var tiefe := 0.07
	box(p, Vector3(feld.size.x, t, tiefe), Vector3(c.x, feld.end.y - t / 2, tiefe / 2), rahmen)
	box(p, Vector3(feld.size.x, t, tiefe), Vector3(c.x, feld.position.y + t / 2, tiefe / 2), rahmen)
	box(p, Vector3(t, feld.size.y, tiefe), Vector3(feld.position.x + t / 2, c.y, tiefe / 2), rahmen)
	box(p, Vector3(t, feld.size.y, tiefe), Vector3(feld.end.x - t / 2, c.y, tiefe / 2), rahmen)
	for y in reihen:
		box(p, Vector3(feld.size.x - 2 * t, 0.035, 0.007), Vector3(c.x, y, 0.0095), mat(METALL, 0.35, 0.6))
		# Kammschiene/Abdeckstreifen andeuten
		box(p, Vector3(feld.size.x - 2 * t, 0.004, 0.003), Vector3(c.x, y + 0.05, 0.0075), mat(Color(0.8, 0.8, 0.8), 0.5))
	schrift(p, "Kleinverteiler  ·  230/400 V", Vector3(c.x, feld.position.y + 0.006, tiefe + 0.0005), 18, Color(0.35, 0.37, 0.4))

## CEE-Stecker (rot) unten links als Einspeisung, mit Rohr hoch zum Verteiler
static func einspeisung_cee(p: Node3D, pos: Vector3, bis_y: float) -> void:
	var rot := mat(Color(0.85, 0.16, 0.12), 0.45)
	box(p, Vector3(0.06, 0.07, 0.03), pos + Vector3(0, 0, 0.015), mat(Color(0.75, 0.13, 0.1), 0.5))
	var k := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.022
	cm.bottom_radius = 0.026
	cm.height = 0.05
	cm.radial_segments = 20
	k.mesh = cm
	k.material_override = rot
	k.rotation_degrees = Vector3(-35, 0, 0)
	k.position = pos + Vector3(0, -0.035, 0.03)
	p.add_child(k)
	zyl(p, 0.018, 0.004, pos + Vector3(0, -0.05, 0.016), mat(Color(0.2, 0.2, 0.2), 0.7), 16).rotation_degrees = Vector3(55, 0, 0)
	zyl(p, 0.008, 0.002, pos + Vector3(0.012, 0.022, 0.031), mat(Color(0.95, 0.95, 0.95), 0.5), 10)
	# Installationsrohr hoch zum Verteiler
	var rohr := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.008
	rm.bottom_radius = 0.008
	var laenge := bis_y - (pos.y + 0.035)
	rm.height = laenge
	rm.radial_segments = 12
	rohr.mesh = rm
	rohr.material_override = mat(Color(0.74, 0.75, 0.77), 0.5)
	rohr.position = Vector3(pos.x, pos.y + 0.035 + laenge / 2, 0.009)
	p.add_child(rohr)
	for i in 3:
		var y := pos.y + 0.08 + i * (laenge - 0.1) / 2.0
		rohrschelle(p, Vector3(pos.x, y, 0), 0.008, true)
	schrift(p, "Einspeisung CEE 16 A", pos + Vector3(0.0, -0.05, 0.001), 18, Color(0.3, 0.3, 0.32))

## Rohr-/Iso-Schelle quer zur Leitung
static func rohrschelle(p: Node3D, pos: Vector3, r: float, senkrecht: bool) -> void:
	var quer := r * 2 + 0.008
	var g := Vector3(quer, 0.011, r * 2 + 0.003) if senkrecht else Vector3(0.011, quer, r * 2 + 0.003)
	box(p, g, pos + Vector3(0, 0, g.z / 2), mat(SCHELLE, 0.5))
	zyl(p, 0.0022, 0.0015, pos + Vector3(0, 0, g.z + 0.0007), mat(Color(0.45, 0.46, 0.48), 0.4, 0.6), 8)
