extends Node3D
## Brettmontage: Werkzeugleiste, Bohren, Bauteile setzen, Leitung ziehen,
## Iso-Schellen setzen, Seitenschneider, Pruefen, Speichern/Laden.
##
## Bedienung: linke Maustaste = Werkzeug benutzen, rechte Maustaste ziehen = Kamera schwenken,
## mittlere Maustaste ziehen = Kamera verschieben, Mausrad = Zoom, Esc = Aktion abbrechen,
## Entf = ausgewaehltes Bauteil entfernen.

const BOARD_W := 1.2
const BOARD_H := 0.8
const RASTER := 0.01          # 1 cm Fangraster
const BOHR_FANG := 0.015      # Schelle/Geraet sucht Bohrung im Umkreis von 1,5 cm

enum Werkzeug { AUSWAHL, BOHRER, BAUTEIL, LEITUNG, SCHELLE, SEITENSCHNEIDER, ABMANTELN, ABISOLIEREN }

## Aderfarben fuer die Darstellung
const ADERFARBE := {
	"bn": Color(0.45, 0.25, 0.1), "bu": Color(0.1, 0.35, 0.85), "gnye": Color(0.55, 0.8, 0.1),
	"bk": Color(0.08, 0.08, 0.08), "gy": Color(0.55, 0.55, 0.55),
}

## Groesse (Breite, Hoehe, Tiefe in m), Farbe und Anzeigename je Geraetetyp
const BAUTEILE := {
	"einspeisung":     {"name": "Einspeisung", "groesse": Vector3(0.10, 0.08, 0.05), "farbe": Color(0.25, 0.25, 0.28)},
	"fi":              {"name": "FI 40A/30mA", "groesse": Vector3(0.07, 0.09, 0.07), "farbe": Color(0.92, 0.92, 0.9)},
	"ls":              {"name": "LS B16", "groesse": Vector3(0.018, 0.09, 0.07), "farbe": Color(0.92, 0.92, 0.9)},
	"abzweigdose":     {"name": "Abzweigdose", "groesse": Vector3(0.085, 0.085, 0.045), "farbe": Color(0.82, 0.82, 0.78)},
	"ausschalter":     {"name": "Ausschalter", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.95, 0.95, 0.93)},
	"wechselschalter": {"name": "Wechselschalter", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.95, 0.95, 0.93)},
	"steckdose":       {"name": "Steckdose", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.95, 0.95, 0.93)},
	"lampe":           {"name": "Lampenfassung", "groesse": Vector3(0.09, 0.09, 0.06), "farbe": Color(0.35, 0.35, 0.35)},
}
const SETZBAR := ["fi", "ls", "abzweigdose", "ausschalter", "wechselschalter", "steckdose", "lampe"]
const KUERZEL := {"fi": "fi", "ls": "ls", "abzweigdose": "dose", "ausschalter": "s", "wechselschalter": "ws", "steckdose": "sd", "lampe": "lampe"}

var circuit := Circuit.new()
var werkzeug: int = Werkzeug.AUSWAHL
var bauteil_typ := "fi"
var leitung_typ := "NYM-J 3x1,5"
var ausgewaehlt := ""
var abisolier_mm := 10.0

# Leitung, die gerade verlegt wird
var verlege_start := ""
var verlege_punkte: Array = []

# Kamera
var cam: Camera3D
var cam_yaw := 0.0
var cam_pitch := 0.0
var cam_dist := 1.25
var cam_target := Vector3.ZERO

# Szene
var geraete_knoten := {}    # id -> Node3D
var leitung_knoten := {}    # id -> Node3D
var bohr_knoten: Node3D
var vorschau: MeshInstance3D
var cursor_marker: MeshInstance3D

# UI
var status: Label
var ergebnis: RichTextLabel
var datei_dialog: FileDialog
var werkzeug_knoepfe := {}

var mat_nym: StandardMaterial3D
var mat_steuer: StandardMaterial3D
var mat_schelle: StandardMaterial3D
var mat_bohrung: StandardMaterial3D
var mat_auswahl: StandardMaterial3D

func _ready() -> void:
	_materialien()
	_umgebung()
	_brett()
	_kamera()
	_ui()
	_neues_projekt()

# ---------------------------------------------------------------- Aufbau

func _mat(c: Color, rough := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _materialien() -> void:
	mat_nym = _mat(Color(0.88, 0.88, 0.86), 0.6)
	mat_steuer = _mat(Color(0.55, 0.57, 0.6), 0.6)
	mat_schelle = _mat(Color(0.97, 0.97, 0.97), 0.4)
	mat_bohrung = _mat(Color(0.12, 0.08, 0.05))
	mat_auswahl = _mat(Color(1.0, 0.75, 0.1))
	mat_auswahl.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _umgebung() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.22, 0.24, 0.27)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.78)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-35, 25, 0)
	sonne.light_energy = 0.9
	add_child(sonne)

func _brett() -> void:
	var brett := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(BOARD_W, BOARD_H, 0.018)
	brett.mesh = bm
	brett.material_override = _mat(Color(0.78, 0.66, 0.48))
	brett.position = Vector3(0, 0, -0.009)
	add_child(brett)
	bohr_knoten = Node3D.new()
	add_child(bohr_knoten)
	vorschau = MeshInstance3D.new()
	vorschau.material_override = mat_auswahl
	add_child(vorschau)
	cursor_marker = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.004
	sm.height = 0.008
	cursor_marker.mesh = sm
	cursor_marker.material_override = mat_auswahl
	add_child(cursor_marker)

func _kamera() -> void:
	cam = Camera3D.new()
	cam.fov = 45
	add_child(cam)
	_kamera_aktualisieren()

func _kamera_aktualisieren() -> void:
	cam_pitch = clampf(cam_pitch, -0.6, 0.6)
	cam_yaw = clampf(cam_yaw, -0.6, 0.6)
	cam_dist = clampf(cam_dist, 0.15, 2.0)
	cam_target.x = clampf(cam_target.x, -BOARD_W / 2, BOARD_W / 2)
	cam_target.y = clampf(cam_target.y, -BOARD_H / 2, BOARD_H / 2)
	var offs := Vector3(sin(cam_yaw) * cos(cam_pitch), sin(-cam_pitch), cos(cam_yaw) * cos(cam_pitch)) * cam_dist
	cam.position = cam_target + offs
	cam.look_at(cam_target)

func _ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var zeilen := VBoxContainer.new()
	zeilen.position = Vector2(8, 8)
	layer.add_child(zeilen)
	var leiste := HBoxContainer.new()
	leiste.add_theme_constant_override("separation", 6)
	zeilen.add_child(leiste)
	var leiste2 := HBoxContainer.new()
	leiste2.add_theme_constant_override("separation", 6)
	zeilen.add_child(leiste2)

	for w in [[Werkzeug.AUSWAHL, "Auswahl"], [Werkzeug.BOHRER, "Bohrmaschine"], [Werkzeug.BAUTEIL, "Bauteil setzen"],
			[Werkzeug.LEITUNG, "Leitung verlegen"], [Werkzeug.SCHELLE, "Iso-Schelle"], [Werkzeug.SEITENSCHNEIDER, "Seitenschneider"],
			[Werkzeug.ABMANTELN, "Abmantelungswerkzeug"], [Werkzeug.ABISOLIEREN, "Abisolierzange"]]:
		var b := Button.new()
		b.text = w[1]
		b.toggle_mode = true
		b.pressed.connect(_werkzeug_waehlen.bind(w[0]))
		leiste.add_child(b)
		werkzeug_knoepfe[w[0]] = b

	var bt := OptionButton.new()
	for t in SETZBAR:
		bt.add_item(BAUTEILE[t].name)
	bt.item_selected.connect(func(i: int) -> void:
		bauteil_typ = SETZBAR[i]
		_werkzeug_waehlen(Werkzeug.BAUTEIL))
	leiste2.add_child(bt)

	var lt := OptionButton.new()
	var namen: Array = Circuit.LEITUNGEN.keys()
	for n in namen:
		lt.add_item(n)
	lt.item_selected.connect(func(i: int) -> void:
		leitung_typ = namen[i]
		_werkzeug_waehlen(Werkzeug.LEITUNG))
	leiste2.add_child(lt)

	var lbl_mm := Label.new()
	lbl_mm.text = "Abisolierlänge:"
	leiste2.add_child(lbl_mm)
	var mm := SpinBox.new()
	mm.min_value = 2
	mm.max_value = 30
	mm.step = 1
	mm.value = abisolier_mm
	mm.suffix = "mm"
	mm.value_changed.connect(func(v: float) -> void: abisolier_mm = v)
	leiste2.add_child(mm)

	for a in [["Prüfen", _pruefen], ["Speichern", _speichern_dialog], ["Laden", _laden_dialog], ["Neu", _neues_projekt]]:
		var b := Button.new()
		b.text = a[0]
		b.pressed.connect(a[1])
		leiste2.add_child(b)

	status = Label.new()
	status.position = Vector2(8, 80)
	status.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(status)

	ergebnis = RichTextLabel.new()
	ergebnis.position = Vector2(8, 108)
	ergebnis.size = Vector2(520, 300)
	ergebnis.bbcode_enabled = true
	ergebnis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ergebnis)

	datei_dialog = FileDialog.new()
	datei_dialog.access = FileDialog.ACCESS_FILESYSTEM
	datei_dialog.filters = PackedStringArray(["*.esim ; ESLS-Projekt"])
	datei_dialog.use_native_dialog = true
	datei_dialog.file_selected.connect(_datei_gewaehlt)
	layer.add_child(datei_dialog)
	_werkzeug_waehlen(Werkzeug.AUSWAHL)

# ---------------------------------------------------------------- Projekt

func _neues_projekt() -> void:
	circuit = Circuit.new()
	circuit.geraet_hinzufuegen("netz", "einspeisung", Vector3(-0.5, 0.3, 0))
	_alles_neu_zeichnen()
	ergebnis.text = ""
	_status("Neues Projekt. Tipp: Erst bohren, dann Bauteile setzen.")

func _alles_neu_zeichnen() -> void:
	for n in geraete_knoten.values(): n.queue_free()
	for n in leitung_knoten.values(): n.queue_free()
	geraete_knoten.clear()
	leitung_knoten.clear()
	for id in circuit.geraete:
		_geraet_zeichnen(id)
	for l in circuit.leitungen:
		_leitung_zeichnen(l)
	_bohrungen_zeichnen()
	ausgewaehlt = ""
	verlege_start = ""
	verlege_punkte.clear()
	_vorschau_zeichnen(Vector3.ZERO)

func _status(t: String) -> void:
	status.text = t

func _werkzeug_waehlen(w: int) -> void:
	werkzeug = w
	for k in werkzeug_knoepfe:
		werkzeug_knoepfe[k].button_pressed = (k == w)
	verlege_start = ""
	verlege_punkte.clear()
	match w:
		Werkzeug.AUSWAHL: _status("Auswahl: Bauteil anklicken, Entf entfernt es.")
		Werkzeug.BOHRER: _status("Bohrmaschine: Klick setzt eine 6-mm-Bohrung.")
		Werkzeug.BAUTEIL: _status("%s setzen: Klick auf das Brett. Unter dem Bauteil müssen 2 Bohrungen sein." % BAUTEILE[bauteil_typ].name)
		Werkzeug.LEITUNG: _status("%s: Start-Bauteil anklicken, Eckpunkte setzen, Ziel-Bauteil anklicken. Esc bricht ab." % leitung_typ)
		Werkzeug.SCHELLE: _status("Iso-Schelle: Auf die Leitung über einer Bohrung klicken (max. 25 cm Abstand).")
		Werkzeug.SEITENSCHNEIDER: _status("Seitenschneider: Leitung anklicken, um sie zu entfernen.")
		Werkzeug.ABMANTELN: _status("Abmantelungswerkzeug: Leitungsende am Bauteil anklicken.")
		Werkzeug.ABISOLIEREN: _status("Abisolierzange (%d mm): abgemanteltes Leitungsende anklicken. Richtig sind 8 bis 12 mm." % abisolier_mm)

# ---------------------------------------------------------------- Eingabe

func _brett_punkt(maus: Vector2) -> Variant:
	var ursprung := cam.project_ray_origin(maus)
	var richtung := cam.project_ray_normal(maus)
	var p: Variant = Plane(Vector3(0, 0, 1), 0.0).intersects_ray(ursprung, richtung)
	if p == null:
		return null
	var v: Vector3 = p
	if absf(v.x) > BOARD_W / 2 or absf(v.y) > BOARD_H / 2:
		return null
	return Vector3(snappedf(v.x, RASTER), snappedf(v.y, RASTER), 0.0)

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion:
		var mm := ev as InputEventMouseMotion
		if mm.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			cam_yaw -= mm.relative.x * 0.004
			cam_pitch += mm.relative.y * 0.004
			_kamera_aktualisieren()
		elif mm.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			cam_target -= Vector3(mm.relative.x, -mm.relative.y, 0) * 0.0008 * cam_dist
			_kamera_aktualisieren()
		var p: Variant = _brett_punkt(mm.position)
		cursor_marker.visible = p != null
		if p != null:
			cursor_marker.position = p
			_vorschau_zeichnen(p)
	elif ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist *= 0.9
			_kamera_aktualisieren()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist /= 0.9
			_kamera_aktualisieren()
		elif mb.button_index == MOUSE_BUTTON_LEFT:
			var p: Variant = _brett_punkt(mb.position)
			if p != null:
				_klick(p)
	elif ev is InputEventKey and ev.pressed:
		var k := ev as InputEventKey
		if k.keycode == KEY_ESCAPE:
			verlege_start = ""
			verlege_punkte.clear()
			_vorschau_zeichnen(Vector3.ZERO)
			_status("Abgebrochen.")
		elif k.keycode == KEY_DELETE and ausgewaehlt != "":
			_geraet_entfernen(ausgewaehlt)

func _klick(p: Vector3) -> void:
	match werkzeug:
		Werkzeug.AUSWAHL: _auswaehlen(_geraet_bei(p))
		Werkzeug.BOHRER: _bohren(p)
		Werkzeug.BAUTEIL: _bauteil_setzen(p)
		Werkzeug.LEITUNG: _leitung_klick(p)
		Werkzeug.SCHELLE: _schelle_setzen(p)
		Werkzeug.SEITENSCHNEIDER: _leitung_schneiden(p)
		Werkzeug.ABMANTELN: _abmanteln(p)
		Werkzeug.ABISOLIEREN: _abisolieren(p)

# ---------------------------------------------------------------- Werkzeuge

func _bohren(p: Vector3) -> void:
	for b in circuit.bohrungen:
		if (b as Vector3).distance_to(p) < 0.008:
			_status("Hier ist schon eine Bohrung.")
			return
	circuit.bohrungen.append(p)
	_bohrungen_zeichnen()
	_status("Bohrung gesetzt (%d insgesamt)." % circuit.bohrungen.size())

func _bohrungen_im_rechteck(mitte: Vector3, groesse: Vector3) -> int:
	var n := 0
	for b in circuit.bohrungen:
		var v: Vector3 = b
		if absf(v.x - mitte.x) <= groesse.x / 2 and absf(v.y - mitte.y) <= groesse.y / 2:
			n += 1
	return n

func _bauteil_setzen(p: Vector3) -> void:
	var g: Vector3 = BAUTEILE[bauteil_typ].groesse
	# Ueberschneidung mit anderen Bauteilen pruefen
	for id in circuit.geraete:
		var o: Dictionary = circuit.geraete[id]
		var og: Vector3 = BAUTEILE[o.typ].groesse
		var op: Vector3 = o.pos
		if absf(op.x - p.x) < (og.x + g.x) / 2 and absf(op.y - p.y) < (og.y + g.y) / 2:
			_status("Platz ist schon belegt (%s)." % id)
			return
	# Schmale Reiheneinbaugeraete (LS) brauchen 1 Bohrung, sonst 2 (Befestigungsschrauben)
	var noetig := 1 if bauteil_typ == "ls" else 2
	if _bohrungen_im_rechteck(p, g) < noetig:
		_status("Erst bohren: %s braucht %d Bohrung(en) unter dem Bauteil." % [BAUTEILE[bauteil_typ].name, noetig])
		return
	var i := 1
	while circuit.geraete.has(KUERZEL[bauteil_typ] + str(i)):
		i += 1
	var id: String = KUERZEL[bauteil_typ] + str(i)
	circuit.geraet_hinzufuegen(id, bauteil_typ, p, {"nennstrom": 16} if bauteil_typ == "ls" else {})
	_geraet_zeichnen(id)
	_status("%s gesetzt." % id)

func _geraet_bei(p: Vector3) -> String:
	for id in circuit.geraete:
		var g: Dictionary = circuit.geraete[id]
		var gr: Vector3 = BAUTEILE[g.typ].groesse
		var gp: Vector3 = g.pos
		# Schmale Geraete etwas groesser anklickbar
		if absf(gp.x - p.x) <= maxf(gr.x, 0.03) / 2 and absf(gp.y - p.y) <= gr.y / 2:
			return id
	return ""

func _auswaehlen(id: String) -> void:
	ausgewaehlt = id
	for gid in geraete_knoten:
		var n: Node3D = geraete_knoten[gid]
		(n.get_child(0) as MeshInstance3D).material_overlay = mat_auswahl if gid == id else null
	if id != "":
		var g: Dictionary = circuit.geraete[id]
		var anz := 0
		for l in circuit.leitungen:
			if l.get("start_geraet", "") == id or l.get("ende_geraet", "") == id:
				anz += 1
		_status("%s (%s), %d Leitung(en) angeschlossen. Entf entfernt es." % [id, BAUTEILE[g.typ].name, anz])
	else:
		_status("Nichts ausgewählt.")

func _geraet_entfernen(id: String) -> void:
	if id == "netz":
		_status("Die Einspeisung kann nicht entfernt werden.")
		return
	circuit.geraete.erase(id)
	circuit.zustand.erase(id)
	var rest := []
	for l in circuit.leitungen:
		if l.get("start_geraet", "") != id and l.get("ende_geraet", "") != id:
			rest.append(l)
	circuit.leitungen = rest
	_alles_neu_zeichnen()
	_status("%s und angeschlossene Leitungen entfernt." % id)

## Rechtwinklige Verlegung: naechster Punkt liegt waagerecht oder senkrecht zum letzten
func _rechtwinklig(von: Vector3, nach: Vector3) -> Vector3:
	if absf(nach.x - von.x) >= absf(nach.y - von.y):
		return Vector3(nach.x, von.y, 0)
	return Vector3(von.x, nach.y, 0)

func _leitung_klick(p: Vector3) -> void:
	var g := _geraet_bei(p)
	if verlege_start == "":
		if g == "":
			_status("Leitung muss an einem Bauteil beginnen.")
			return
		verlege_start = g
		verlege_punkte = [circuit.geraete[g].pos]
		_status("Start: %s. Eckpunkte setzen, dann Ziel-Bauteil anklicken." % g)
		return
	var letzter: Vector3 = verlege_punkte[verlege_punkte.size() - 1]
	if g != "" and g != verlege_start:
		var ziel: Vector3 = circuit.geraete[g].pos
		if absf(ziel.x - letzter.x) > 0.001 and absf(ziel.y - letzter.y) > 0.001:
			verlege_punkte.append(_rechtwinklig(letzter, ziel))
		verlege_punkte.append(ziel)
		_leitung_anlegen(verlege_start, g, verlege_punkte.duplicate())
		verlege_start = ""
		verlege_punkte.clear()
		_vorschau_zeichnen(Vector3.ZERO)
		return
	var neu := _rechtwinklig(letzter, p)
	if neu.distance_to(letzter) > 0.005:
		verlege_punkte.append(neu)

func _leitung_anlegen(von: String, nach: String, punkte: Array) -> void:
	var i := 1
	while _leitung_mit_id("W%d" % i) != null:
		i += 1
	var adern := []
	for farbe in Circuit.LEITUNGEN[leitung_typ].adern:
		adern.append({"farbe": farbe, "von": "", "nach": "", "abisoliert_von": 0.0, "abisoliert_nach": 0.0})
	var l := {
		"id": "W%d" % i, "typ": leitung_typ, "punkte": punkte, "schellen": [],
		"abgemantelt": {"start": false, "ende": false}, "adern": adern,
		"start_geraet": von, "ende_geraet": nach,
	}
	circuit.leitung_hinzufuegen(l)
	_leitung_zeichnen(l)
	_status("%s (%s) von %s nach %s verlegt, %.2f m. Jetzt mit Iso-Schellen befestigen." % [l.id, leitung_typ, von, nach, _laenge(punkte)])

func _leitung_mit_id(id: String) -> Variant:
	for l in circuit.leitungen:
		if l.id == id:
			return l
	return null

func _laenge(punkte: Array) -> float:
	var s := 0.0
	for i in range(punkte.size() - 1):
		s += (punkte[i] as Vector3).distance_to(punkte[i + 1])
	return s

## Naechster Punkt auf einer Leitung: [leitung, punkt, abstand, laufmeter]
func _naechste_leitung(p: Vector3) -> Array:
	var best := [null, Vector3.ZERO, INF, 0.0]
	for l in circuit.leitungen:
		var lauf := 0.0
		var pts: Array = l.punkte
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var q := Geometry3D.get_closest_point_to_segment(p, a, b)
			var d := q.distance_to(p)
			if d < best[2]:
				best = [l, q, d, lauf + a.distance_to(q)]
			lauf += a.distance_to(b)
	return best

func _schelle_setzen(p: Vector3) -> void:
	var n := _naechste_leitung(p)
	if n[0] == null or n[2] > 0.02:
		_status("Keine Leitung in der Nähe.")
		return
	var q: Vector3 = n[1]
	var hat_bohrung := false
	for b in circuit.bohrungen:
		if (b as Vector3).distance_to(q) <= BOHR_FANG:
			hat_bohrung = true
	if not hat_bohrung:
		_status("Unter der Schelle fehlt eine Bohrung.")
		return
	var l: Dictionary = n[0]
	for s in l.schellen:
		if (s as Vector3).distance_to(q) < 0.02:
			_status("Hier sitzt schon eine Schelle.")
			return
	l.schellen.append(q)
	# Schellen entlang der Leitung sortieren (fuer die Abstandspruefung)
	l.schellen.sort_custom(func(x: Vector3, y: Vector3) -> bool:
		return _laufmeter(l, x) < _laufmeter(l, y))
	_leitung_zeichnen(l)
	_status("Schelle an %s gesetzt (%d Schellen)." % [l.id, l.schellen.size()])

func _laufmeter(l: Dictionary, p: Vector3) -> float:
	var lauf := 0.0
	var best := INF
	var best_lauf := 0.0
	var pts: Array = l.punkte
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var q := Geometry3D.get_closest_point_to_segment(p, a, b)
		if q.distance_to(p) < best:
			best = q.distance_to(p)
			best_lauf = lauf + a.distance_to(q)
		lauf += a.distance_to(b)
	return best_lauf

func _leitung_schneiden(p: Vector3) -> void:
	var n := _naechste_leitung(p)
	if n[0] == null or n[2] > 0.02:
		_status("Keine Leitung in der Nähe.")
		return
	var l: Dictionary = n[0]
	circuit.leitungen.erase(l)
	if leitung_knoten.has(l.id):
		leitung_knoten[l.id].queue_free()
		leitung_knoten.erase(l.id)
	_status("%s entfernt." % l.id)

## Leitungsende in der Naehe: [leitung, "start"/"ende"] oder [null, ""]
func _leitungsende_bei(p: Vector3) -> Array:
	var best: Array = [null, ""]
	var best_d := 0.06
	for l in circuit.leitungen:
		var pts: Array = l.punkte
		for ende in [["start", pts[0]], ["ende", pts[pts.size() - 1]]]:
			var d := (ende[1] as Vector3).distance_to(p)
			if d < best_d:
				best_d = d
				best = [l, ende[0]]
	return best

func _abmanteln(p: Vector3) -> void:
	var e := _leitungsende_bei(p)
	if e[0] == null:
		_status("Kein Leitungsende in der Nähe (Bauteil anklicken, an dem die Leitung endet).")
		return
	var l: Dictionary = e[0]
	if l.abgemantelt[e[1]]:
		_status("%s ist an diesem Ende schon abgemantelt." % l.id)
		return
	l.abgemantelt[e[1]] = true
	_leitung_zeichnen(l)
	_status("%s abgemantelt (%s). Jetzt die Adern abisolieren." % [l.id, l.get(e[1] + "_geraet", "")])

func _abisolieren(p: Vector3) -> void:
	var e := _leitungsende_bei(p)
	if e[0] == null:
		_status("Kein Leitungsende in der Nähe.")
		return
	var l: Dictionary = e[0]
	if not l.abgemantelt[e[1]]:
		_status("Erst abmanteln! Mit der Abisolierzange kommt man nicht durch den Mantel.")
		return
	var feld := "abisoliert_von" if e[1] == "start" else "abisoliert_nach"
	for a in l.adern:
		a[feld] = abisolier_mm
	_leitung_zeichnen(l)
	var hinweis := ""
	if abisolier_mm < Circuit.ABISOLIERLAENGE.x:
		hinweis = " Achtung: zu kurz, die Klemme fasst evtl. nur die Isolierung."
	elif abisolier_mm > Circuit.ABISOLIERLAENGE.y:
		hinweis = " Achtung: zu lang, blankes Kupfer schaut aus der Klemme."
	_status("%s: Adern %d mm abisoliert.%s" % [l.id, abisolier_mm, hinweis])

# ---------------------------------------------------------------- Pruefen / Datei

func _pruefen() -> void:
	var r := circuit.pruefen()
	var t := "[b]Prüfergebnis:[/b] %s\n" % ("[color=lime]in Ordnung[/color]" if r.ok else "[color=tomato]Fehler gefunden[/color]")
	for a in r.ausgeloest:
		t += "[color=orange]>> %s hat ausgelöst[/color]\n" % a
	for f in r.fehler:
		t += "• %s\n" % f
	for w in r.warnungen:
		t += "[color=yellow]• %s[/color]\n" % w
	if not r.lampen_an.is_empty():
		t += "[color=lime]Leuchtet: %s[/color]\n" % ", ".join(r.lampen_an)
	ergebnis.text = t

var _dialog_speichern := true
func _speichern_dialog() -> void:
	_dialog_speichern = true
	datei_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	datei_dialog.current_file = "brettmontage.esim"
	datei_dialog.popup_centered(Vector2i(800, 500))

func _laden_dialog() -> void:
	_dialog_speichern = false
	datei_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	datei_dialog.popup_centered(Vector2i(800, 500))

func _datei_gewaehlt(pfad: String) -> void:
	if _dialog_speichern:
		if not pfad.ends_with(".esim"):
			pfad += ".esim"
		var err := Projektdatei.speichern(circuit, pfad, {"erstellt": Time.get_datetime_string_from_system()})
		_status("Gespeichert: %s" % pfad if err == OK else "Speichern fehlgeschlagen (Fehler %d)." % err)
	else:
		var d := Projektdatei.laden(pfad)
		if d.has("fehler"):
			_status(d.fehler)
			return
		circuit = d.circuit
		_alles_neu_zeichnen()
		ergebnis.text = "" if d.unveraendert else "[color=orange]Hinweis: Datei wurde außerhalb von ESLS verändert.[/color]"
		_status("Geladen: %s" % pfad)

# ---------------------------------------------------------------- Zeichnen

func _geraet_zeichnen(id: String) -> void:
	var g: Dictionary = circuit.geraete[id]
	var info: Dictionary = BAUTEILE[g.typ]
	var gr: Vector3 = info.groesse
	var knoten := Node3D.new()
	knoten.position = g.pos
	var mi := MeshInstance3D.new()
	if g.typ == "lampe":
		var cm := CylinderMesh.new()
		cm.top_radius = gr.x * 0.4
		cm.bottom_radius = gr.x / 2
		cm.height = gr.z
		cm.radial_segments = 16
		mi.mesh = cm
		mi.rotation_degrees = Vector3(90, 0, 0)
	else:
		var bm := BoxMesh.new()
		bm.size = gr
		mi.mesh = bm
	mi.position = Vector3(0, 0, gr.z / 2)
	mi.material_override = _mat(info.farbe, 0.4)
	knoten.add_child(mi)
	var lbl := Label3D.new()
	lbl.text = id
	lbl.font_size = 24
	lbl.pixel_size = 0.0006
	lbl.modulate = Color.BLACK if g.typ != "einspeisung" else Color.WHITE
	lbl.outline_size = 0
	lbl.position = Vector3(0, 0, gr.z + 0.001)
	knoten.add_child(lbl)
	add_child(knoten)
	geraete_knoten[id] = knoten

func _bohrungen_zeichnen() -> void:
	for c in bohr_knoten.get_children():
		c.queue_free()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.003
	cm.bottom_radius = 0.003
	cm.height = 0.001
	cm.radial_segments = 10
	for b in circuit.bohrungen:
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = mat_bohrung
		mi.rotation_degrees = Vector3(90, 0, 0)
		mi.position = (b as Vector3) + Vector3(0, 0, 0.0005)
		bohr_knoten.add_child(mi)

func _leitung_zeichnen(l: Dictionary) -> void:
	if leitung_knoten.has(l.id):
		leitung_knoten[l.id].queue_free()
	var knoten := Node3D.new()
	var info: Dictionary = Circuit.LEITUNGEN[l.typ]
	# Aussendurchmesser grob nach Aderzahl/Querschnitt
	var r := 0.0045 if info.adern.size() <= 3 else 0.0055
	if info.qs >= 2.5:
		r += 0.0008
	var tube := MeshInstance3D.new()
	tube.mesh = _rohr(l.punkte, r)
	tube.material_override = mat_steuer if String(l.typ).begins_with("Steuer") else mat_nym
	knoten.add_child(tube)
	for s in l.schellen:
		var sm := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.014, 0.014, r * 2 + 0.003)
		sm.mesh = bm
		sm.material_override = mat_schelle
		sm.position = (s as Vector3) + Vector3(0, 0, r)
		knoten.add_child(sm)
	_adern_zeichnen(knoten, l, "start", r)
	_adern_zeichnen(knoten, l, "ende", r)
	add_child(knoten)
	leitung_knoten[l.id] = knoten

## Abgemanteltes Ende: Adern faechern 4 cm vor dem Geraet auf, abisolierte Spitzen in Kupfer
func _adern_zeichnen(knoten: Node3D, l: Dictionary, ende: String, r: float) -> void:
	if not l.abgemantelt.get(ende, false):
		return
	var pts: Array = l.punkte
	if pts.size() < 2:
		return
	var spitze: Vector3 = pts[0] if ende == "start" else pts[pts.size() - 1]
	var davor: Vector3 = pts[1] if ende == "start" else pts[pts.size() - 2]
	var dir := (spitze - davor).normalized()
	var seite := dir.cross(Vector3(0, 0, 1)).normalized()
	var feld := "abisoliert_von" if ende == "start" else "abisoliert_nach"
	var n: int = l.adern.size()
	var kupfer := _mat(Color(0.85, 0.5, 0.25), 0.3)
	for i in range(n):
		var a: Dictionary = l.adern[i]
		var versatz := seite * (float(i) - (n - 1) / 2.0) * 0.006
		var von := spitze - dir * 0.05 + Vector3(0, 0, r)
		var bis := spitze - dir * 0.012 + versatz + Vector3(0, 0, r + 0.004)
		var mi := MeshInstance3D.new()
		mi.mesh = _rohr([von, bis], 0.0014)
		mi.material_override = _mat(ADERFARBE.get(a.farbe, Color.BLACK), 0.5)
		knoten.add_child(mi)
		var mm: float = a.get(feld, 0.0)
		if mm > 0.0:
			var cu := MeshInstance3D.new()
			cu.mesh = _rohr([bis, bis + dir * mm / 1000.0], 0.0009)
			cu.material_override = kupfer
			knoten.add_child(cu)

## Rohr entlang der Punkte (auf dem Brett aufliegend)
func _rohr(punkte: Array, r: float) -> ArrayMesh:
	const SEG := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(punkte.size() - 1):
		var a: Vector3 = (punkte[i] as Vector3) + Vector3(0, 0, r)
		var b: Vector3 = (punkte[i + 1] as Vector3) + Vector3(0, 0, r)
		if a.distance_to(b) < 0.0001:
			continue
		var dir := (b - a).normalized()
		var seite := dir.cross(Vector3(0, 0, 1)).normalized()
		var oben := seite.cross(dir).normalized()
		for s in range(SEG):
			var t0 := TAU * s / SEG
			var t1 := TAU * (s + 1) / SEG
			var n0 := seite * cos(t0) + oben * sin(t0)
			var n1 := seite * cos(t1) + oben * sin(t1)
			for v in [[a, n0], [b, n0], [b, n1], [a, n0], [b, n1], [a, n1]]:
				st.set_normal(v[1])
				st.add_vertex(v[0] + v[1] * r)
	return st.commit()

func _vorschau_zeichnen(maus: Vector3) -> void:
	if werkzeug != Werkzeug.LEITUNG or verlege_start == "" or verlege_punkte.is_empty():
		vorschau.mesh = null
		return
	var pts := verlege_punkte.duplicate()
	pts.append(_rechtwinklig(pts[pts.size() - 1], maus))
	vorschau.mesh = _rohr(pts, 0.003)
