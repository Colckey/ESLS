extends Node3D
## Brettmontage: Werkzeugleiste, Bohren, Bauteile setzen, Leitung ziehen,
## Iso-Schellen setzen, Seitenschneider, Pruefen, Speichern/Laden.
##
## Bedienung: linke Maustaste = Werkzeug benutzen, rechte Maustaste ziehen = Kamera schwenken,
## mittlere Maustaste ziehen = Kamera verschieben, Mausrad = Zoom, Esc = Aktion abbrechen,
## Entf = ausgewaehltes Bauteil entfernen.

const BOARD_W := 1.2
const BOARD_H := 0.9
const RASTER := 0.01          # 1 cm Fangraster
const BOHR_FANG := 0.015      # Schelle/Geraet sucht Bohrung im Umkreis von 1,5 cm

enum Werkzeug { AUSWAHL, BOHRER, BAUTEIL, LEITUNG, SCHELLE, SEITENSCHNEIDER, ABMANTELN, ABISOLIEREN, ANKLEMMEN, ZOLLSTOCK, WASSERWAAGE }

## Aderfarben fuer die Darstellung
const ADERFARBE := {
	"bn": Color(0.45, 0.25, 0.1), "bu": Color(0.1, 0.35, 0.85), "gnye": Color(0.55, 0.8, 0.1),
	"bk": Color(0.08, 0.08, 0.08), "gy": Color(0.55, 0.55, 0.55),
}

## Groesse (Breite, Hoehe, Tiefe in m), Farbe und Anzeigename je Geraetetyp
const BAUTEILE := {
	"einspeisung":     {"name": "Hauptklemme (Einspeisung)", "groesse": Vector3(0.05, 0.035, 0.035), "farbe": Color(0.45, 0.45, 0.48)},
	"n_schiene":       {"name": "N-Klemmen", "groesse": Vector3(0.06, 0.035, 0.035), "farbe": Color(0.15, 0.38, 0.85)},
	"pe_schiene":      {"name": "PE-Klemmen", "groesse": Vector3(0.05, 0.035, 0.035), "farbe": Color(0.25, 0.62, 0.25)},
	"fi":              {"name": "FI 40A/30mA", "groesse": Vector3(0.07, 0.09, 0.06), "farbe": Color(0.92, 0.92, 0.9)},
	"ls":              {"name": "LS B16", "groesse": Vector3(0.018, 0.09, 0.06), "farbe": Color(0.92, 0.92, 0.9)},
	"abzweigdose":     {"name": "Abzweigdose", "groesse": Vector3(0.085, 0.085, 0.045), "farbe": Color(0.82, 0.82, 0.78)},
	"ausschalter":     {"name": "Ausschalter", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.95, 0.95, 0.93)},
	"wechselschalter": {"name": "Wechselschalter", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.95, 0.95, 0.93)},
	"steckdose":       {"name": "Steckdose", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.95, 0.95, 0.93)},
	"lampe":           {"name": "Feuchtraumleuchte", "groesse": Vector3(0.09, 0.13, 0.055), "farbe": Color(0.35, 0.35, 0.35)},
	"kreuzschalter":   {"name": "Kreuzschalter", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.95, 0.95, 0.93)},
	"taster":          {"name": "Taster (Schließer)", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.6, 0.85, 0.6)},
	"taster_aus":      {"name": "Taster (Öffner)", "groesse": Vector3(0.08, 0.08, 0.05), "farbe": Color(0.9, 0.5, 0.5)},
	"schuetz":         {"name": "Schütz", "groesse": Vector3(0.045, 0.085, 0.08), "farbe": Color(0.85, 0.85, 0.82)},
	"zeitrelais":      {"name": "Zeitrelais (ansprechverz.)", "groesse": Vector3(0.018, 0.09, 0.06), "farbe": Color(0.8, 0.85, 0.95)},
	"treppenlicht":    {"name": "Treppenlichtautomat (TLZ)", "groesse": Vector3(0.018, 0.09, 0.06), "farbe": Color(0.8, 0.85, 0.95)},
}
## Reiheneinbaugeraete sitzen auf der Hutschiene im Verteiler (keine Bohrungen noetig)
const HUTSCHIENE := ["fi", "ls", "schuetz", "zeitrelais", "treppenlicht"]
const REIHEN := [0.17, 0.06]          # y der beiden Hutschienen
const FEST := ["netz", "x_n", "x_pe"]  # fest eingebaut, nicht loeschbar
const NACHLAUFZEIT := 30.0             # Treppenlicht, verkuerzt fuer den Unterricht
const SETZBAR := ["fi", "ls", "abzweigdose", "ausschalter", "wechselschalter", "kreuzschalter", "taster", "taster_aus",
	"steckdose", "lampe", "schuetz", "zeitrelais", "treppenlicht"]
## Bauteil-Raster links, nach Kategorien sortiert
const KATEGORIEN := [
	["Verteiler (Hutschiene)", ["fi", "ls", "schuetz", "treppenlicht", "zeitrelais"]],
	["Schalter und Taster", ["ausschalter", "wechselschalter", "kreuzschalter", "taster", "taster_aus"]],
	["Dosen und Verbraucher", ["abzweigdose", "steckdose", "lampe"]],
]
const KACHEL_NAME := {"fi": "FI-Schalter", "ls": "LS B16", "zeitrelais": "Zeitrelais", "taster": "Taster (S)",
	"taster_aus": "Taster (Ö)", "lampe": "Leuchte", "treppenlicht": "Treppenlicht"}
## Werkzeugleiste rechts in Arbeitsreihenfolge: [Werkzeug, Name, Taste]
const WERKZEUG_GRUPPEN := [
	["Vorbereiten", [[Werkzeug.AUSWAHL, "Auswahl", "1"], [Werkzeug.BOHRER, "Bohrmaschine", "2"]]],
	["Verlegen", [[Werkzeug.LEITUNG, "Leitung verlegen", "3"], [Werkzeug.SCHELLE, "Iso-Schelle", "4"],
		[Werkzeug.SEITENSCHNEIDER, "Seitenschneider", "5"]]],
	["Anschließen", [[Werkzeug.ABMANTELN, "Abmantelwerkzeug", "6"], [Werkzeug.ABISOLIEREN, "Abisolierzange", "7"],
		[Werkzeug.ANKLEMMEN, "Schraubendreher", "8"]]],
	["Messen", [[Werkzeug.ZOLLSTOCK, "Zollstock (messen)", "9"], [Werkzeug.WASSERWAAGE, "Wasserwaage", "0"]]],
]
const WERKZEUG_NAME := {Werkzeug.AUSWAHL: "Auswahl", Werkzeug.BOHRER: "Bohrmaschine", Werkzeug.BAUTEIL: "Bauteil setzen",
	Werkzeug.LEITUNG: "Leitung verlegen", Werkzeug.SCHELLE: "Iso-Schelle", Werkzeug.SEITENSCHNEIDER: "Seitenschneider",
	Werkzeug.ABMANTELN: "Abmantelungswerkzeug", Werkzeug.ABISOLIEREN: "Abisolierzange", Werkzeug.ANKLEMMEN: "Schraubendreher",
	Werkzeug.ZOLLSTOCK: "Zollstock", Werkzeug.WASSERWAAGE: "Wasserwaage"}
const KUERZEL := {"fi": "fi", "ls": "ls", "abzweigdose": "dose", "ausschalter": "s", "wechselschalter": "ws",
	"kreuzschalter": "x", "taster": "t", "taster_aus": "t0", "steckdose": "sd", "lampe": "lampe", "schuetz": "k", "zeitrelais": "kt", "treppenlicht": "tlz"}
## Kurze Erklaerung fuer Tooltips (Lernhilfe)
const ERKLAERUNG := {
	"fi": "Fehlerstrom-Schutzschalter (RCD): vergleicht Hin- und Rückstrom und schaltet bei 30 mA Differenz ab. Schützt Menschen.",
	"ls": "Leitungsschutzschalter B16: schaltet bei Überlast und Kurzschluss ab. Schützt die Leitung.",
	"schuetz": "Schütz: Spule A1/A2 zieht an und schließt die Hauptkontakte 1-2, 3-4, 5-6 und den Hilfskontakt 13-14.",
	"zeitrelais": "Zeitrelais (ansprechverzögert): schaltet 15 nach Ablauf der Zeit von 16 auf 18.",
	"treppenlicht": "Treppenlichtzeitschalter: Tasterimpuls auf T schaltet L auf den Lampenausgang, nach der Nachlaufzeit wieder aus.",
	"abzweigdose": "Abzweigdose: hier werden Leitungen mit Verbindungsklemmen (Wago) verbunden.",
	"ausschalter": "Ausschalter: verbindet L mit 1. Schaltet den Außenleiter.",
	"wechselschalter": "Wechselschalter: verbindet L entweder mit 1 oder mit 2.",
	"kreuzschalter": "Kreuzschalter: verbindet 1-3/2-4 oder gekreuzt 1-4/2-3.",
	"taster": "Taster (Schließer): verbindet L mit 1, solange er gedrückt ist.",
	"taster_aus": "Taster (Öffner): trennt L von 1, solange er gedrückt ist.",
	"steckdose": "Schutzkontakt-Steckdose: L, N und PE. Muss über einen FI geschützt sein.",
	"lampe": "Feuchtraumleuchte: L, N und PE anschließen.",
}

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
const CAM_START_DIST := 1.5
var cam_dist := CAM_START_DIST
var cam_target := Vector3.ZERO

# Szene
var geraete_knoten := {}    # id -> Node3D
var leitung_knoten := {}    # id -> Node3D
var bohr_knoten: Node3D
var vorschau: MeshInstance3D
var cursor_marker: MeshInstance3D

# UI
const PANEL_BREITE := 240
var ui_wurzel: Control
var mitte: Control
var status: Label
var werkzeug_anzeige: Label
var ergebnis: RichTextLabel
var ergebnis_karte: PanelContainer
var ergebnis_titel: Label
var kopfleiste: Control
var bauteil_kacheln := {}
var datei_dialog: FileDialog
var werkzeug_knoepfe := {}
var name_feld: LineEdit
var geladene_meta := {}
var aufgabe_id := "ausschaltung"
var _geprueft := false
var treppen_timer: Timer
var auftrag_titel: Label
var auftrag_kurz: Label
var schritte_box: HBoxContainer
var startbildschirm: Control
var auftrag_karte: Control
var grafik_knopf: Button

var mat_nym: StandardMaterial3D
var mat_steuer: StandardMaterial3D
var mat_schelle: StandardMaterial3D
var mat_bohrung: StandardMaterial3D
var mat_auswahl: StandardMaterial3D
var mat_auswahl_rahmen: StandardMaterial3D
var letztes_ergebnis := {}

func _ready() -> void:
	_materialien()
	_umgebung()
	_brett()
	_kamera()
	_ui()
	_neues_projekt()
	_auftrag_anzeigen()
	if Musterbrett.beim_start:
		Musterbrett.beim_start = false
		musterbrett_zeigen.call_deferred()

# ---------------------------------------------------------------- Aufbau

func _mat(c: Color, rough := 0.7) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _materialien() -> void:
	mat_nym = _mat(Modelle.NYM, 0.55)
	mat_steuer = _mat(Color(0.55, 0.57, 0.6), 0.6)
	mat_schelle = _mat(Color(0.97, 0.97, 0.97), 0.4)
	mat_bohrung = _mat(Color(0.12, 0.08, 0.05))
	mat_auswahl = _mat(Color(1.0, 0.75, 0.1))
	mat_auswahl.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_auswahl_rahmen = _mat(Color(0.2, 0.55, 1.0, 0.35))
	mat_auswahl_rahmen.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat_auswahl_rahmen.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _overlay(n: Node, m: Material) -> void:
	for k in n.get_children():
		if k is MeshInstance3D:
			(k as MeshInstance3D).material_overlay = m
		_overlay(k, m)

var sonne: DirectionalLight3D
var grafik_hoch := true

func _umgebung() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.90, 0.90, 0.88)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.98, 0.95)
	e.ambient_light_energy = 0.32
	env.environment = e
	add_child(env)
	sonne = DirectionalLight3D.new()
	sonne.rotation_degrees = Vector3(-38, -28, 0)
	sonne.light_energy = 0.42
	sonne.shadow_bias = 0.02
	sonne.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sonne.directional_shadow_max_distance = 3.0
	add_child(sonne)
	var fuell := DirectionalLight3D.new()
	fuell.rotation_degrees = Vector3(-10, 35, 0)
	fuell.light_energy = 0.12
	add_child(fuell)
	_grafik_setzen(grafik_hoch)

## Grafik hoch: Schatten und Kantenglaettung. Niedrig: fuer sehr schwache PCs.
func _grafik_setzen(hoch: bool) -> void:
	grafik_hoch = hoch
	sonne.shadow_enabled = hoch
	if is_inside_tree():
		get_viewport().msaa_3d = Viewport.MSAA_2X if hoch else Viewport.MSAA_DISABLED

func _brett() -> void:
	var deko := Node3D.new()
	add_child(deko)
	Modelle.brett(deko, BOARD_W, BOARD_H)
	Modelle.kabelkanal(deko, Circuit.KABELKANAL)
	Modelle.verteiler(deko, Circuit.VERTEILER_FELD, REIHEN)
	Modelle.einspeisung_cee(deko, Vector3(-0.50, -0.37, 0), Circuit.VERTEILER_FELD.position.y)
	Modelle.zusammenfassen(deko)
	_mess_knoten_anlegen()
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
	ui_wurzel = Control.new()
	ui_wurzel.theme = Stil.theme()
	ui_wurzel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_wurzel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(ui_wurzel)

	var spalte := VBoxContainer.new()
	spalte.set_anchors_preset(Control.PRESET_FULL_RECT)
	spalte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	spalte.add_theme_constant_override("separation", 0)
	ui_wurzel.add_child(spalte)

	kopfleiste = _kopfleiste()
	spalte.add_child(kopfleiste)
	spalte.add_child(_auftrag_leiste())
	var mitte_zeile := HBoxContainer.new()
	mitte_zeile.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mitte_zeile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mitte_zeile.add_theme_constant_override("separation", 0)
	spalte.add_child(mitte_zeile)
	mitte_zeile.add_child(_bauteil_panel())
	mitte = Control.new()   # freie Sicht aufs Brett, Klicks gehen durch
	mitte.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mitte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mitte_zeile.add_child(mitte)
	mitte_zeile.add_child(_werkzeug_panel())
	spalte.add_child(_statusleiste())
	mitte.add_child(_ergebnis_karte())

	treppen_timer = Timer.new()
	treppen_timer.one_shot = true
	treppen_timer.timeout.connect(_treppenlicht_aus)
	add_child(treppen_timer)
	auftrag_karte = _auftrag_karte()
	ui_wurzel.add_child(auftrag_karte)
	startbildschirm = _startbildschirm()
	ui_wurzel.add_child(startbildschirm)

	datei_dialog = FileDialog.new()
	datei_dialog.access = FileDialog.ACCESS_FILESYSTEM
	datei_dialog.filters = PackedStringArray(["*.esim ; ESLS-Projekt"])
	datei_dialog.use_native_dialog = true
	datei_dialog.file_selected.connect(_datei_gewaehlt)
	layer.add_child(datei_dialog)
	_werkzeug_waehlen(Werkzeug.AUSWAHL)

## Oben: Titel, Schuelername, Datei-Knoepfe, Pruefen (blaue Leiste)
func _kopfleiste() -> Control:
	var kopf := PanelContainer.new()
	kopf.add_theme_stylebox_override("panel", Stil.box(Stil.KOPF, 0, Stil.RAND, 0, Vector2(14, 8)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	kopf.add_child(h)
	var logo := Label.new()
	logo.text = "⚡"
	logo.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	logo.add_theme_font_size_override("font_size", 22)
	h.add_child(logo)
	var titel := Label.new()
	titel.text = "ESLS Elektro-Lernsimulation"
	titel.theme_type_variation = "KopfLabel"
	titel.add_theme_font_size_override("font_size", 19)
	h.add_child(titel)
	var unter := Label.new()
	unter.text = "Übungsbrett"
	unter.theme_type_variation = "KopfLabel"
	unter.modulate = Color(1, 1, 1, 0.7)
	h.add_child(unter)
	var platz := Control.new()
	platz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(platz)
	var name_lbl := Label.new()
	name_lbl.text = "Name"
	name_lbl.theme_type_variation = "KopfLabel"
	h.add_child(name_lbl)
	name_feld = LineEdit.new()
	name_feld.placeholder_text = "Vor- und Nachname"
	name_feld.custom_minimum_size = Vector2(180, 0)
	h.add_child(name_feld)
	for a in [["Neu", _neu_waehlen], ["Laden", _laden_dialog], ["Speichern", _speichern_dialog], ["Lehrermodus", _lehrermodus]]:
		var k := _knopf(a[0], a[1])
		k.theme_type_variation = "KopfButton"
		h.add_child(k)
	var pruefen := _knopf("✔ Prüfen", _pruefen)
	pruefen.theme_type_variation = "AkzentButton"
	pruefen.tooltip_text = "Schaltung prüfen (Taste P)"
	h.add_child(pruefen)
	return kopf

## Arbeitsblatt-Leiste: aktueller Auftrag und Arbeitsschritte
func _auftrag_leiste() -> Control:
	var leiste := PanelContainer.new()
	leiste.theme_type_variation = "Papier"
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	leiste.add_child(h)
	var icon := Label.new()
	icon.text = "📋"
	h.add_child(icon)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", -2)
	h.add_child(v)
	auftrag_titel = Label.new()
	auftrag_titel.add_theme_font_size_override("font_size", 15)
	auftrag_titel.add_theme_color_override("font_color", Stil.KOPF)
	v.add_child(auftrag_titel)
	auftrag_kurz = Label.new()
	auftrag_kurz.theme_type_variation = "Leise"
	v.add_child(auftrag_kurz)
	var lesen := _knopf("Auftrag lesen", func() -> void: auftrag_karte.visible = not auftrag_karte.visible)
	lesen.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(lesen)
	var platz := Control.new()
	platz.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(platz)
	schritte_box = HBoxContainer.new()
	schritte_box.add_theme_constant_override("separation", 4)
	h.add_child(schritte_box)
	return leiste

## Arbeitsschritte automatisch abhaken: [Name, erledigt, Hinweis]
func schritte() -> Array:
	var a := Aufgaben.finden(aufgabe_id)
	var p := circuit.kopie().pruefen()
	var anzahl := {}
	for gid in circuit.geraete:
		anzahl[circuit.geraete[gid].typ] = anzahl.get(circuit.geraete[gid].typ, 0) + 1
	var bauteile_ok := true
	if a.is_empty():
		bauteile_ok = anzahl.size() > 3
	for t in a.get("bauteile", {}):
		if anzahl.get(t, 0) < a.bauteile[t]: bauteile_ok = false
	var nym := circuit.leitungen.filter(func(l): return not Circuit.LEITUNGEN[l.typ].get("einzelader", false))
	var leitungen_ok := not nym.is_empty()
	for gid in circuit.geraete:
		var typ: String = circuit.geraete[gid].typ
		if typ in HUTSCHIENE or typ in ["einspeisung", "n_schiene", "pe_schiene", "klemme"]:
			continue
		if not nym.any(func(l): return l.get("start_geraet", "") == gid or l.get("ende_geraet", "") == gid):
			leitungen_ok = false
	var befestigt_ok: bool = leitungen_ok and not p.fehler.any(func(f): return "Schelle" in f or "befestigt" in f)
	var isoliert_ok := leitungen_ok
	for l in nym:
		if not (l.abgemantelt.start and l.abgemantelt.ende):
			isoliert_ok = false
		for ad in l.adern:
			if ad.get("abisoliert_von", 0.0) <= 0.0 or ad.get("abisoliert_nach", 0.0) <= 0.0:
				isoliert_ok = false
	var belegt := {}
	for l in circuit.leitungen:
		for ad in l.adern:
			for f in ["von", "nach"]:
				if ad.get(f, "") != "": belegt[ad[f]] = true
	var geklemmt_ok := bauteile_ok and leitungen_ok
	for gid in circuit.geraete:
		var typ: String = circuit.geraete[gid].typ
		if typ in ["lampe", "steckdose"]:
			for k in ["L", "N", "PE"]:
				if not belegt.has(gid + ":" + k): geklemmt_ok = false
		elif typ in Bewertung.SCHALTER_TYPEN or typ in HUTSCHIENE:
			var n := 0
			for k in Circuit.TYPEN[typ]:
				if belegt.has(gid + ":" + k): n += 1
			if n < 2: geklemmt_ok = false
	return [
		["Bauteile", bauteile_ok, "Alle Bauteile aus dem Auftrag gesetzt"],
		["Leitungen", leitungen_ok, "Jedes Gerät hat eine Leitung"],
		["Befestigt", befestigt_ok, "Iso-Schellen höchstens 25 cm auseinander, höchstens 10 cm vor dem Gerät"],
		["Abisoliert", isoliert_ok, "Alle Leitungsenden abgemantelt und abisoliert"],
		["Angeklemmt", geklemmt_ok, "Leuchten/Steckdosen: L, N, PE belegt. Schalter: mindestens 2 Klemmen"],
		["Geprüft", _geprueft, "Prüfen ohne Fehler und Funktion wie im Auftrag"],
	]

var _schritte_ausstehend := false

## Arbeitsschritte hoechstens einmal pro Bild neu berechnen
func _schritte_aktualisieren() -> void:
	if schritte_box == null or _schritte_ausstehend:
		return
	_schritte_ausstehend = true
	_schritte_jetzt.call_deferred()

func _schritte_jetzt() -> void:
	_schritte_ausstehend = false
	for k in schritte_box.get_children():
		k.queue_free()
	var nr := 1
	for sch in schritte():
		var chip := PanelContainer.new()
		var fertig: bool = sch[1]
		chip.add_theme_stylebox_override("panel", Stil.box(Color(0.86, 0.95, 0.88) if fertig else Color.WHITE, 12,
			Stil.GRUEN if fertig else Stil.RAND, 1, Vector2(8, 2)))
		chip.tooltip_text = sch[2]
		var l := Label.new()
		l.text = "%s %s" % ["✔" if fertig else str(nr), sch[0]]
		l.add_theme_font_size_override("font_size", 13)
		l.add_theme_color_override("font_color", Stil.GRUEN.darkened(0.2) if fertig else Stil.TEXT_LEISE)
		chip.add_child(l)
		schritte_box.add_child(chip)
		nr += 1

func _auftrag_anzeigen() -> void:
	var a := Aufgaben.finden(aufgabe_id)
	if auftrag_titel == null:
		return
	if a.is_empty():
		auftrag_titel.text = "Freies Üben"
		auftrag_kurz.text = "Ohne Auftrag: baue, was du möchtest, und prüfe die Schaltung."
		_schritte_aktualisieren()
		return
	var nr := Aufgaben.LISTE.find(a) + 1
	auftrag_titel.text = "Auftrag %d: %s" % [nr, a.titel]
	auftrag_kurz.text = a.kurz
	var t: RichTextLabel = auftrag_karte.get_meta("text")
	var txt := "[font_size=22][b]Auftrag %d: %s[/b][/font_size]\n[color=#5a6270]%d. Lehrjahr · %s[/color]\n\n%s\n\n[b]Benötigte Bauteile[/b]\n" % [nr, a.titel, a.lehrjahr, a.stufe, a.auftrag]
	for typ in a.bauteile:
		txt += "  • %d× %s\n" % [a.bauteile[typ], Aufgaben.TYP_NAME.get(typ, typ)]
	txt += "\n[b]Lernziele[/b]\n"
	for z in a.lernziele:
		txt += "  • %s\n" % z
	txt += "\n[b]Tipps[/b]\n"
	for z in a.tipps:
		txt += "  💡 %s\n" % z
	txt += "\n[b]Arbeitsablauf[/b]\n  1 Bohren · 2 Bauteile setzen (Bauplan B, Raster R, Zollstock, Wasserwaage) · 3 Leitungen verlegen · 4 Iso-Schellen (max. 10 cm vor jedem Gerät) · 5 Abmanteln · 6 Abisolieren · 7 Anklemmen (3D-Ansicht) · 8 Prüfen"
	t.text = txt
	_schritte_aktualisieren()

## Karte mit dem ganzen Auftragstext
func _auftrag_karte() -> Control:
	var k := PanelContainer.new()
	k.theme_type_variation = "Karte"
	var v := VBoxContainer.new()
	k.add_child(v)
	var t := RichTextLabel.new()
	t.bbcode_enabled = true
	t.fit_content = false
	t.scroll_active = true
	t.custom_minimum_size = Vector2(560, 500)
	v.add_child(t)
	var zu := _knopf("Verstanden", func() -> void: k.hide())
	zu.size_flags_horizontal = Control.SIZE_SHRINK_END
	zu.theme_type_variation = "AkzentButton"
	v.add_child(zu)
	k.set_meta("text", t)
	k.set_anchors_preset(Control.PRESET_CENTER)
	k.grow_horizontal = Control.GROW_DIRECTION_BOTH
	k.grow_vertical = Control.GROW_DIRECTION_BOTH
	k.hide()
	return k

## Startbildschirm: Name eintragen und Auftrag waehlen
func _startbildschirm() -> Control:
	var hg := PanelContainer.new()
	hg.set_anchors_preset(Control.PRESET_FULL_RECT)
	hg.add_theme_stylebox_override("panel", Stil.box(Color(0.93, 0.94, 0.96, 1.0), 0))
	var mitte_c := CenterContainer.new()
	hg.add_child(mitte_c)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	mitte_c.add_child(v)
	var titel := Label.new()
	titel.text = "⚡ ESLS Elektro-Lernsimulation"
	titel.add_theme_font_size_override("font_size", 30)
	titel.add_theme_color_override("font_color", Stil.KOPF)
	titel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(titel)
	var unter := Label.new()
	unter.text = "Brettmontage am Übungsbrett · für Elektroniker/innen im 1. und 2. Lehrjahr"
	unter.theme_type_variation = "Leise"
	unter.add_theme_font_size_override("font_size", 15)
	unter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(unter)
	var name_zeile := HBoxContainer.new()
	name_zeile.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(name_zeile)
	var nl := Label.new()
	nl.text = "Dein Name:"
	name_zeile.add_child(nl)
	var start_name := LineEdit.new()
	start_name.placeholder_text = "Vor- und Nachname"
	start_name.custom_minimum_size = Vector2(260, 0)
	start_name.text_changed.connect(func(t: String) -> void: name_feld.text = t)
	name_zeile.add_child(start_name)
	v.add_child(Stil.ueberschrift("Wähle deinen Auftrag"))
	var raster := GridContainer.new()
	raster.columns = 3
	raster.add_theme_constant_override("h_separation", 12)
	raster.add_theme_constant_override("v_separation", 12)
	v.add_child(raster)
	var nr := 1
	for a in Aufgaben.LISTE:
		raster.add_child(_aufgaben_karte(a, nr))
		nr += 1
	var unten := HBoxContainer.new()
	unten.alignment = BoxContainer.ALIGNMENT_CENTER
	unten.add_theme_constant_override("separation", 10)
	v.add_child(unten)
	unten.add_child(_knopf("Gespeicherte Arbeit laden", func() -> void:
		startbildschirm.hide()
		_laden_dialog()))
	unten.add_child(_knopf("Freies Üben (ohne Auftrag)", aufgabe_starten.bind("")))
	unten.add_child(_knopf("Lehrermodus", _lehrermodus))
	return hg

func _aufgaben_karte(a: Dictionary, nr: int) -> Control:
	var k := PanelContainer.new()
	k.theme_type_variation = "Karte"
	k.custom_minimum_size = Vector2(290, 150)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	k.add_child(v)
	var kopf := HBoxContainer.new()
	kopf.add_theme_constant_override("separation", 8)
	v.add_child(kopf)
	var nummer := Label.new()
	nummer.text = str(nr)
	nummer.add_theme_font_size_override("font_size", 22)
	nummer.add_theme_color_override("font_color", Stil.AKZENT)
	kopf.add_child(nummer)
	var t := Label.new()
	t.text = a.titel
	t.theme_type_variation = "Titel"
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(t)
	var chip := Label.new()
	chip.text = "%d. Lehrjahr · %s" % [a.lehrjahr, a.stufe]
	chip.add_theme_font_size_override("font_size", 12)
	chip.add_theme_color_override("font_color", Stil.GRUEN.darkened(0.2) if a.lehrjahr == 1 else Color(0.55, 0.3, 0.7))
	v.add_child(chip)
	var kurz := Label.new()
	kurz.text = a.kurz
	kurz.autowrap_mode = TextServer.AUTOWRAP_WORD
	kurz.custom_minimum_size = Vector2(260, 0)
	kurz.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(kurz)
	var teile := HBoxContainer.new()
	teile.add_theme_constant_override("separation", 2)
	v.add_child(teile)
	for typ in a.bauteile:
		var bild := grafik("bauteile/%s" % typ)
		if bild == null: continue
		var tr := TextureRect.new()
		tr.texture = bild
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(30, 30)
		tr.tooltip_text = "%d× %s" % [a.bauteile[typ], Aufgaben.TYP_NAME.get(typ, typ)]
		teile.add_child(tr)
	var los := _knopf("Auftrag starten", aufgabe_starten.bind(a.id))
	los.theme_type_variation = "AkzentButton"
	los.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(los)
	return k

func aufgabe_starten(id: String) -> void:
	aufgabe_id = id
	_neues_projekt()
	startbildschirm.hide()
	_auftrag_anzeigen()
	auftrag_karte.visible = id != ""
	_bauplan_zeichnen()

func start_ausblenden() -> void:
	startbildschirm.hide()

func _neu_waehlen() -> void:
	startbildschirm.show()

func _knopf(text: String, aktion: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE   # sonst loest die Leertaste den Knopf aus
	b.pressed.connect(aktion)
	return b

## Links: Bauteile als Kacheln, nach Kategorien sortiert
func _bauteil_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Stil.box(Stil.HINTERGRUND, 0, Stil.RAND, 0, Vector2(10, 10)))
	panel.custom_minimum_size = Vector2(PANEL_BREITE, 0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 6)
	scroll.add_child(v)
	var titel := Label.new()
	titel.text = "Bauteile"
	titel.theme_type_variation = "Titel"
	v.add_child(titel)
	v.add_theme_constant_override("separation", 4)
	for kat in KATEGORIEN:
		v.add_child(Stil.ueberschrift(kat[0]))
		var raster := GridContainer.new()
		raster.columns = 2
		raster.add_theme_constant_override("h_separation", 6)
		raster.add_theme_constant_override("v_separation", 6)
		v.add_child(raster)
		for typ in kat[1]:
			raster.add_child(_bauteil_kachel(typ))
	return panel

func _bauteil_kachel(typ: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(102, 78)
	b.tooltip_text = "%s\n%s" % [BAUTEILE[typ].name, ERKLAERUNG.get(typ, "")]
	b.pressed.connect(func() -> void:
		bauteil_typ = typ
		_werkzeug_waehlen(Werkzeug.BAUTEIL))
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 3
	v.offset_bottom = -3
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(v)
	var bild := grafik("bauteile/%s" % typ)
	if bild:
		var tr := TextureRect.new()
		tr.texture = bild
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.custom_minimum_size = Vector2(80, 52)
		tr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(tr)
	else:
		var sym := BauteilSymbol.new()
		sym.typ = typ
		sym.farbe = BAUTEILE[typ].farbe
		sym.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(sym)
	var l := Label.new()
	l.text = KACHEL_NAME.get(typ, BAUTEILE[typ].name)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 12)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(l)
	bauteil_kacheln[typ] = b
	return b

## Rechts: Werkzeuge in Arbeitsreihenfolge, mit Tastenkuerzel und Einstellungen
func _werkzeug_panel() -> Control:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Stil.box(Stil.HINTERGRUND, 0, Stil.RAND, 0, Vector2(10, 10)))
	panel.custom_minimum_size = Vector2(PANEL_BREITE, 0)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	scroll.add_child(v)
	var titel := Label.new()
	titel.text = "Werkzeuge"
	titel.theme_type_variation = "Titel"
	v.add_child(titel)
	for gruppe in WERKZEUG_GRUPPEN:
		v.add_child(Stil.ueberschrift(gruppe[0]))
		for w in gruppe[1]:
			v.add_child(_werkzeug_knopf(w[0], w[1], w[2]))
			if w[0] == Werkzeug.LEITUNG:
				var lt := OptionButton.new()
				lt.focus_mode = Control.FOCUS_NONE
				var namen: Array = Circuit.LEITUNGEN.keys()
				lt.add_theme_constant_override("icon_max_width", 26)
				for n in namen:
					var ico := grafik("leitungen/%s" % leitung_datei(n))
					if ico: lt.add_icon_item(ico, n)
					else: lt.add_item(n)
				lt.tooltip_text = "Leitungstyp"
				lt.item_selected.connect(func(i: int) -> void:
					leitung_typ = namen[i]
					_werkzeug_waehlen(Werkzeug.LEITUNG))
				v.add_child(_einrueckung(lt))
			elif w[0] == Werkzeug.ABISOLIEREN:
				var zeile := HBoxContainer.new()
				var lbl := Label.new()
				lbl.text = "Länge"
				lbl.theme_type_variation = "Leise"
				zeile.add_child(lbl)
				var mm := SpinBox.new()
				mm.min_value = 2
				mm.max_value = 30
				mm.step = 1
				mm.value = abisolier_mm
				mm.suffix = "mm"
				mm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				mm.value_changed.connect(func(wert: float) -> void:
					abisolier_mm = wert
					if werkzeug == Werkzeug.ABISOLIEREN:
						_werkzeug_waehlen(Werkzeug.ABISOLIEREN))
				zeile.add_child(mm)
				v.add_child(_einrueckung(zeile))
	v.add_child(HSeparator.new())
	v.add_child(Stil.ueberschrift("Ansicht"))
	var ansicht := _knopf("Ansicht zurücksetzen", _ansicht_zuruecksetzen)
	ansicht.tooltip_text = "Taste Pos1"
	v.add_child(ansicht)
	grafik_knopf = _knopf("Grafik: hoch", func() -> void:
		_grafik_setzen(not grafik_hoch)
		grafik_knopf.text = "Grafik: hoch" if grafik_hoch else "Grafik: niedrig (schnell)")
	grafik_knopf.tooltip_text = "Niedrig schaltet Schatten und Kantenglättung ab (für langsame PCs)"
	v.add_child(grafik_knopf)
	raster_knopf = _knopf("Raster (cm) einblenden", raster_umschalten)
	raster_knopf.toggle_mode = true
	raster_knopf.tooltip_text = "Taste R: 1-cm-Raster mit Maßzahlen vom Brettrand"
	v.add_child(raster_knopf)
	bauplan_knopf = _knopf("Bauplan einblenden", bauplan_umschalten)
	bauplan_knopf.toggle_mode = true
	bauplan_knopf.tooltip_text = "Taste B: zeigt, wo die Bauteile laut Auftrag hinkommen"
	v.add_child(bauplan_knopf)
	var hilfe := Label.new()
	hilfe.theme_type_variation = "Leise"
	hilfe.autowrap_mode = TextServer.AUTOWRAP_WORD
	hilfe.text = "Rechte Maustaste: drehen\nMittlere Maustaste: verschieben\nMausrad: zoomen  ·  P: prüfen\nR: Raster  ·  B: Bauplan\nEsc: abbrechen  ·  Entf: löschen\nLeertaste: Schalter bedienen"
	v.add_child(hilfe)
	return panel

func _einrueckung(c: Control) -> Control:
	var rand := MarginContainer.new()
	rand.add_theme_constant_override("margin_left", 14)
	rand.add_theme_constant_override("margin_bottom", 4)
	rand.add_child(c)
	return rand

## Eigene Bilder (aus den 3D-Modellen erzeugt mit tools/grafiken.gd)
const WERKZEUG_BILD := {Werkzeug.AUSWAHL: "auswahl", Werkzeug.BOHRER: "bohrer", Werkzeug.SCHELLE: "schelle",
	Werkzeug.SEITENSCHNEIDER: "seitenschneider", Werkzeug.ABMANTELN: "abmanteln", Werkzeug.ABISOLIEREN: "abisolieren",
	Werkzeug.ANKLEMMEN: "anklemmen", Werkzeug.ZOLLSTOCK: "zollstock", Werkzeug.WASSERWAAGE: "wasserwaage"}

static func grafik(name: String) -> Texture2D:
	var pfad := "res://grafik/%s.png" % name
	return load(pfad) if ResourceLoader.exists(pfad) else null

static func leitung_datei(typ: String) -> String:
	return typ.to_lower().replace(" ", "_").replace(",", "_").replace("-", "_")

func _werkzeug_knopf(w: int, text: String, taste: String) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 32)
	b.text = text
	b.add_theme_font_size_override("font_size", 14)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 36)
	var ico := grafik("werkzeuge/%s" % WERKZEUG_BILD.get(w, ""))
	if w == Werkzeug.LEITUNG:
		ico = grafik("leitungen/nym_j_3x1_5")
	if ico:
		b.icon = ico
		b.add_theme_constant_override("icon_max_width", 28)
	b.tooltip_text = "%s (Taste %s)" % [text, taste]
	b.pressed.connect(_werkzeug_waehlen.bind(w))
	var k := Label.new()
	k.text = taste
	k.theme_type_variation = "Leise"
	k.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	k.offset_left = -22
	k.offset_right = -10
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(k)
	werkzeug_knoepfe[w] = b
	return b

## Unten: aktueller Hinweis
func _statusleiste() -> Control:
	var leiste := PanelContainer.new()
	leiste.add_theme_stylebox_override("panel", Stil.box(Color(0.89, 0.91, 0.94), 0, Stil.RAND, 0, Vector2(14, 7)))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	leiste.add_child(h)
	werkzeug_anzeige = Label.new()
	werkzeug_anzeige.add_theme_color_override("font_color", Stil.AKZENT)
	h.add_child(werkzeug_anzeige)
	h.add_child(VSeparator.new())
	status = Label.new()
	status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	h.add_child(status)
	return leiste

## Pruefergebnis als Karte unten links ueber dem Brett
func _ergebnis_karte() -> Control:
	ergebnis_karte = PanelContainer.new()
	ergebnis_karte.theme_type_variation = "Karte"
	var v := VBoxContainer.new()
	ergebnis_karte.add_child(v)
	var kopf := HBoxContainer.new()
	v.add_child(kopf)
	ergebnis_titel = Label.new()
	ergebnis_titel.theme_type_variation = "Titel"
	ergebnis_titel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(ergebnis_titel)
	kopf.add_child(_knopf("Schließen", func() -> void: ergebnis_karte.hide()))
	ergebnis = RichTextLabel.new()
	ergebnis.bbcode_enabled = true
	ergebnis.custom_minimum_size = Vector2(440, 0)
	ergebnis.fit_content = true
	ergebnis.selection_enabled = true
	v.add_child(ergebnis)
	ergebnis_karte.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_MINSIZE, 12)
	ergebnis_karte.grow_vertical = Control.GROW_DIRECTION_BEGIN
	ergebnis_karte.hide()
	return ergebnis_karte

func _ergebnis_setzen(t: String, titel := "Hinweis") -> void:
	ergebnis_titel.text = titel
	ergebnis.text = t
	ergebnis_karte.visible = t != ""

func _ansicht_zuruecksetzen() -> void:
	cam_target = Vector3.ZERO
	cam_dist = CAM_START_DIST
	cam_yaw = 0.0
	cam_pitch = 0.0
	_kamera_aktualisieren()

func _lehrermodus() -> void:
	get_tree().change_scene_to_file("res://lehrer.tscn")

# ---------------------------------------------------------------- Projekt

func _neues_projekt() -> void:
	circuit = Circuit.new()
	circuit.geraet_hinzufuegen("netz", "einspeisung", Vector3(-0.525, 0.255, 0))
	circuit.geraet_hinzufuegen("x_n", "n_schiene", Vector3(-0.445, 0.255, 0))
	circuit.geraet_hinzufuegen("x_pe", "pe_schiene", Vector3(-0.37, 0.255, 0))
	geladene_meta = {}
	letztes_ergebnis = {}
	_geprueft = false
	if treppen_timer: treppen_timer.stop()
	_alles_neu_zeichnen()
	_ergebnis_setzen("")
	_status("Neues Projekt. Tipp: Erst bohren, dann Bauteile setzen. FI und LS rasten auf der Hutschiene im Verteiler ein.")

func _alles_neu_zeichnen() -> void:
	for n in geraete_knoten.values(): n.queue_free()
	for n in leitung_knoten.values(): n.queue_free()
	geraete_knoten.clear()
	leitung_knoten.clear()
	for id in circuit.geraete:
		if BAUTEILE.has(circuit.geraete[id].typ):
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
	_schritte_aktualisieren()

func _werkzeug_waehlen(w: int) -> void:
	werkzeug = w
	for k in werkzeug_knoepfe:
		werkzeug_knoepfe[k].button_pressed = (k == w)
	for t in bauteil_kacheln:
		bauteil_kacheln[t].button_pressed = (w == Werkzeug.BAUTEIL and t == bauteil_typ)
	if werkzeug_anzeige:
		werkzeug_anzeige.text = BAUTEILE[bauteil_typ].name if w == Werkzeug.BAUTEIL else WERKZEUG_NAME[w]
	verlege_start = ""
	verlege_punkte.clear()
	mess_start = null
	waage_start = ""
	if hilfs_knoten:
		for k in hilfs_knoten.get_children(): k.queue_free()
	match w:
		Werkzeug.AUSWAHL: _status("Auswahl: Bauteil anklicken, Entf entfernt es.")
		Werkzeug.BOHRER: _status("Bohrmaschine: Klick setzt eine 6-mm-Bohrung.")
		Werkzeug.BAUTEIL: _status("%s setzen: Klick auf das Brett. Unter dem Bauteil müssen 2 Bohrungen sein." % BAUTEILE[bauteil_typ].name)
		Werkzeug.LEITUNG: _status("%s: Start-Bauteil anklicken, Eckpunkte setzen, Ziel-Bauteil anklicken. Esc bricht ab." % leitung_typ)
		Werkzeug.SCHELLE: _status("Iso-Schelle: Auf die Leitung über einer Bohrung klicken (max. 25 cm Abstand).")
		Werkzeug.SEITENSCHNEIDER: _status("Seitenschneider: Leitung anklicken, um sie zu entfernen.")
		Werkzeug.ABMANTELN: _status("Abmantelungswerkzeug: Bauteil anklicken, an dem die Leitung endet. In der 3D-Ansicht dann den grauen Mantel anklicken. Vorher muss eine Iso-Schelle höchstens 10 cm vor dem Gerät sitzen.")
		Werkzeug.ANKLEMMEN: _status("Schraubendreher: Bauteil anklicken. In der 3D-Ansicht erst die Ader, dann die Klemme anklicken.")
		Werkzeug.ABISOLIEREN: _status("Abisolierzange (%d mm): Bauteil anklicken. In der 3D-Ansicht jede Ader einzeln anklicken. Richtig sind 8 bis 12 mm." % abisolier_mm)
		Werkzeug.ZOLLSTOCK: _status("Zollstock: Startpunkt anklicken, dann Endpunkt. Angezeigt wird der Abstand in cm.")
		Werkzeug.WASSERWAAGE: _status("Wasserwaage: zwei Bauteile nacheinander anklicken. Die Waage zeigt, ob sie genau waagerecht oder senkrecht zueinander sitzen.")

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
			_messen_bewegung(p)
			_hilfslinien(p)
	elif ev is InputEventMouseButton and ev.pressed:
		var mb := ev as InputEventMouseButton
		get_viewport().gui_release_focus()   # Namensfeld/Auswahllisten loslassen
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
		elif k.keycode >= KEY_0 and k.keycode <= KEY_9:
			var nr := str(k.keycode - KEY_0)
			for gruppe in WERKZEUG_GRUPPEN:
				for w in gruppe[1]:
					if w[2] == nr:
						_werkzeug_waehlen(w[0])
		elif k.keycode == KEY_P:
			_pruefen()
		elif k.keycode == KEY_R:
			raster_umschalten()
		elif k.keycode == KEY_B:
			bauplan_umschalten()
		elif k.keycode == KEY_HOME:
			_ansicht_zuruecksetzen()
		elif k.keycode == KEY_DELETE and ausgewaehlt != "":
			_geraet_entfernen(ausgewaehlt)
		elif k.keycode == KEY_SPACE and ausgewaehlt != "" and circuit.zustand.get(ausgewaehlt, {}).has("stellung"):
			var z: Dictionary = circuit.zustand[ausgewaehlt]
			z.stellung = 1 - int(z.stellung)
			_status("%s geschaltet: %s" % [ausgewaehlt, "EIN / Stellung 2" if z.stellung == 1 else "AUS / Stellung 1"])
			_pruefen()

func _klick(p: Vector3) -> void:
	if werkzeug != Werkzeug.AUSWAHL:
		_geprueft = false
	match werkzeug:
		Werkzeug.AUSWAHL: _auswaehlen(_geraet_bei(p))
		Werkzeug.BOHRER: _bohren(p)
		Werkzeug.BAUTEIL: _bauteil_setzen(p)
		Werkzeug.LEITUNG: _leitung_klick(p)
		Werkzeug.SCHELLE: _schelle_setzen(p)
		Werkzeug.SEITENSCHNEIDER: _leitung_schneiden(p)
		Werkzeug.ABMANTELN: _nahansicht_oeffnen(_geraet_bei(p), Nahansicht.Modus.ABMANTELN)
		Werkzeug.ABISOLIEREN: _nahansicht_oeffnen(_geraet_bei(p), Nahansicht.Modus.ABISOLIEREN)
		Werkzeug.ANKLEMMEN: _nahansicht_oeffnen(_geraet_bei(p), Nahansicht.Modus.ANKLEMMEN)
		Werkzeug.ZOLLSTOCK: _messen_klick(p)
		Werkzeug.WASSERWAAGE: _wasserwaage_klick(p)

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
	var vf: Rect2 = Circuit.VERTEILER_FELD
	var auf_schiene: bool = bauteil_typ in HUTSCHIENE
	if auf_schiene:
		if not vf.has_point(Vector2(p.x, p.y)):
			_status("%s ist ein Reiheneinbaugerät: Es gehört auf die Hutschiene im Verteiler (oben links)." % BAUTEILE[bauteil_typ].name)
			return
		var beste: float = REIHEN[0]
		for y in REIHEN:
			if absf(y - p.y) < absf(beste - p.y): beste = y
		p = Vector3(clampf(p.x, vf.position.x + 0.012 + g.x / 2, vf.end.x - 0.012 - g.x / 2), beste, 0)
	else:
		var r := Rect2(Vector2(p.x, p.y) - Vector2(g.x, g.y) / 2, Vector2(g.x, g.y))
		if r.intersects(vf):
			_status("Im Verteiler ist nur Platz für Reiheneinbaugeräte (FI, LS, Schütz, Relais).")
			return
		if r.intersects(Circuit.KABELKANAL):
			_status("Hier ist der Kabelkanal. Bauteil darunter setzen.")
			return
		if absf(p.x) + g.x / 2 > BOARD_W / 2 or absf(p.y) + g.y / 2 > BOARD_H / 2:
			_status("Das Bauteil passt hier nicht mehr aufs Brett.")
			return
	# Ueberschneidung mit anderen Bauteilen pruefen
	for id in circuit.geraete:
		var o: Dictionary = circuit.geraete[id]
		if not BAUTEILE.has(o.typ):
			continue
		var og: Vector3 = BAUTEILE[o.typ].groesse
		var op: Vector3 = o.pos
		if absf(op.x - p.x) < (og.x + g.x) / 2 and absf(op.y - p.y) < (og.y + g.y) / 2:
			_status("Platz ist schon belegt (%s)." % id)
			return
	# Schmale Reiheneinbaugeraete (LS) brauchen 1 Bohrung, sonst 2 (Befestigungsschrauben)
	var noetig := 0 if auf_schiene else 2
	if _bohrungen_im_rechteck(p, g) < noetig:
		_status("Erst bohren: %s braucht %d Bohrung(en) unter dem Bauteil." % [BAUTEILE[bauteil_typ].name, noetig])
		return
	var i := 1
	while circuit.geraete.has(KUERZEL[bauteil_typ] + str(i)):
		i += 1
	var neu_id: String = KUERZEL[bauteil_typ] + str(i)
	circuit.geraet_hinzufuegen(neu_id, bauteil_typ, p, {"nennstrom": 16} if bauteil_typ == "ls" else {})
	_geraet_zeichnen(neu_id)
	_status("%s gesetzt%s." % [neu_id, " (auf der Hutschiene eingerastet)" if auf_schiene else ""])

func _geraet_bei(p: Vector3) -> String:
	for id in circuit.geraete:
		var g: Dictionary = circuit.geraete[id]
		if not BAUTEILE.has(g.typ):
			continue
		var gr: Vector3 = BAUTEILE[g.typ].groesse
		var gp: Vector3 = g.pos
		if absf(gp.x - p.x) <= gr.x / 2 + 0.001 and absf(gp.y - p.y) <= gr.y / 2:
			return id
	# Schmale Geraete etwas groesser anklickbar
	for id in circuit.geraete:
		var g: Dictionary = circuit.geraete[id]
		if BAUTEILE.has(g.typ) and absf((g.pos as Vector3).x - p.x) <= 0.015 and absf((g.pos as Vector3).y - p.y) <= BAUTEILE[g.typ].groesse.y / 2:
			return id
	# Klick irgendwo in den Verteiler: Hauptklemme (Nahansicht zeigt den ganzen Verteiler)
	if Circuit.VERTEILER_FELD.has_point(Vector2(p.x, p.y)) and circuit.geraete.has("netz"):
		return "netz"
	return ""

func _auswaehlen(id: String) -> void:
	ausgewaehlt = id
	for gid in geraete_knoten:
		_overlay(geraete_knoten[gid], mat_auswahl_rahmen if gid == id else null)
	if id != "":
		var g: Dictionary = circuit.geraete[id]
		var anz := 0
		for l in circuit.leitungen:
			if l.get("start_geraet", "") == id or l.get("ende_geraet", "") == id:
				anz += 1
		_status("%s (%s), %d Leitung(en) angeschlossen. Entf entfernt es, Leertaste schaltet Schalter." % [id, BAUTEILE[g.typ].name, anz])
	else:
		_status("Nichts ausgewählt.")

func _geraet_entfernen(id: String) -> void:
	if id in FEST:
		_status("%s ist fest eingebaut und kann nicht entfernt werden." % id)
		return
	var weg := [id]
	for gid in circuit.geraete:
		if circuit.geraete[gid].param.get("dose", "") == id:
			weg.append(gid)   # Verbindungsklemmen in der Dose
	for gid in weg:
		circuit.geraete.erase(gid)
		circuit.zustand.erase(gid)
	var rest := []
	for l in circuit.leitungen:
		if l.get("start_geraet", "") not in weg and l.get("ende_geraet", "") not in weg:
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
	_status("%s (%s) von %s nach %s verlegt, %.2f m. Jetzt mit Iso-Schellen befestigen (höchstens 10 cm vor jedem Gerät, dazwischen höchstens 25 cm), danach abmanteln." % [l.id, leitung_typ, von, nach, _laenge(punkte)])

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
	_status("Schelle an %s gesetzt (%d Schellen). %s" % [l.id, l.schellen.size(), _befestigung_text(l)])

## Kurzer Hinweis, was an der Befestigung einer Leitung noch fehlt
func _befestigung_text(l: Dictionary) -> String:
	var fehlt := []
	for e in [["start", l.start_geraet], ["ende", l.ende_geraet]]:
		var d := Circuit.abstand_befestigung(l, e[0])
		if d > Circuit.MAX_ENDABSTAND + 0.001:
			fehlt.append("vor %s fehlt eine Schelle (max. 10 cm)" % e[1])
	var halt := Circuit.befestigte_abschnitte(l)
	var bis: float = halt[0][1] if not halt.is_empty() else 0.0
	for h in halt:
		if h[0] - bis > Circuit.MAX_SCHELLENABSTAND + 0.001:
			fehlt.append("Lücke über 25 cm")
			break
		bis = maxf(bis, h[1])
	if fehlt.is_empty():
		return "Leitung fertig befestigt, jetzt abmanteln."
	return "Noch: " + ", ".join(fehlt) + "."

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

## Alle Leitungsenden an einem Bauteil: [[leitung, "start"/"ende"], ...]
func _leitungsenden_am_geraet(id: String) -> Array:
	var r := []
	for l in circuit.leitungen:
		if Circuit.LEITUNGEN[l.typ].get("einzelader", false):
			continue
		if l.get("start_geraet", "") == id:
			r.append([l, "start"])
		if l.get("ende_geraet", "") == id:
			r.append([l, "ende"])
	return r

## Pro Klick wird das naechste noch nicht abgemantelte Leitungsende am Bauteil bearbeitet
func _abmanteln(p: Vector3) -> void:
	var id := _geraet_bei(p)
	if id == "":
		_status("Bauteil anklicken, an dem die Leitung endet.")
		return
	for e in _leitungsenden_am_geraet(id):
		var l: Dictionary = e[0]
		if not l.abgemantelt[e[1]]:
			if Circuit.abstand_befestigung(l, e[1]) > Circuit.MAX_ENDABSTAND + 0.001:
				_status("%s ist vor %s nicht befestigt. Erst eine Iso-Schelle höchstens 10 cm vor dem Gerät setzen." % [l.id, id])
				continue
			l.abgemantelt[e[1]] = true
			_leitung_zeichnen(l)
			_status("%s an %s abgemantelt. Jetzt die Adern abisolieren." % [l.id, id])
			return
	_status("An %s gibt es keine Leitung mehr zum Abmanteln." % id)

## Pro Klick wird das naechste abgemantelte, aber noch nicht abisolierte Leitungsende bearbeitet
func _abisolieren(p: Vector3) -> void:
	var id := _geraet_bei(p)
	if id == "":
		_status("Bauteil anklicken, an dem die Leitung endet.")
		return
	var nur_mantel := false
	for e in _leitungsenden_am_geraet(id):
		var l: Dictionary = e[0]
		var feld := "abisoliert_von" if e[1] == "start" else "abisoliert_nach"
		if l.adern.is_empty() or l.adern[0].get(feld, 0.0) > 0.0:
			continue
		if not l.abgemantelt[e[1]]:
			nur_mantel = true
			continue
		for a in l.adern:
			a[feld] = abisolier_mm
		_leitung_zeichnen(l)
		var hinweis := ""
		if abisolier_mm < Circuit.ABISOLIERLAENGE.x:
			hinweis = " Achtung: zu kurz, die Klemme fasst evtl. nur die Isolierung."
		elif abisolier_mm > Circuit.ABISOLIERLAENGE.y:
			hinweis = " Achtung: zu lang, blankes Kupfer schaut aus der Klemme."
		_status("%s an %s: Adern %d mm abisoliert.%s" % [l.id, id, abisolier_mm, hinweis])
		return
	if nur_mantel:
		_status("Erst abmanteln! Mit der Abisolierzange kommt man nicht durch den Mantel.")
	else:
		_status("An %s ist schon alles abisoliert." % id)

# ---------------------------------------------------------------- Nahansicht

var nahansicht: Nahansicht

func _nahansicht_oeffnen(id: String, modus := -1) -> void:
	if id == "":
		_status("Bauteil anklicken, an dem die Leitung endet.")
		return
	cam_target = circuit.geraete[id].pos + Vector3(0.12, 0, 0)
	cam_dist = 0.35
	cam_yaw = 0.0
	cam_pitch = 0.0
	_kamera_aktualisieren()
	if nahansicht == null:
		nahansicht = Nahansicht.new()
		nahansicht.montage = self
		ui_wurzel.add_child(nahansicht)
		nahansicht.visibility_changed.connect(func() -> void:
			if not nahansicht.visible:
				_ansicht_zuruecksetzen())
	# rechts ueber der Werkzeugleiste, links bleibt das Bauteil sichtbar
	nahansicht.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	nahansicht.offset_right = -10
	nahansicht.offset_left = -10 - nahansicht.custom_minimum_size.x
	nahansicht.offset_top = maxf(kopfleiste.size.y, 50) + 8
	if modus >= 0:
		nahansicht.modus = modus
	nahansicht.oeffnen(id)

## Wird von der Nahansicht nach jeder Aenderung aufgerufen
func nahansicht_geaendert() -> void:
	for l in circuit.leitungen:
		_leitung_zeichnen(l)
	_geprueft = false
	_schritte_aktualisieren()

# ---------------------------------------------------------------- Pruefen / Datei

const GRUEN := "#1e8a3c"
const ROT := "#c62828"
const GELB := "#a86400"

func _pruefen() -> void:
	var r := circuit.pruefen()
	letztes_ergebnis = r
	var t := "%s\n" % ("[color=%s][b]✔ Keine Fehler gefunden[/b][/color]" % GRUEN if r.ok else "[color=%s][b]✘ Fehler gefunden:[/b][/color]" % ROT)
	for a in r.ausgeloest:
		t += "[color=%s]⚡ %s hat ausgelöst[/color]\n" % [ROT, a]
	for f in r.fehler:
		t += "• %s\n" % f
	for w in r.warnungen:
		t += "[color=%s]• %s[/color]\n" % [GELB, w]
	if not r.lampen_an.is_empty():
		t += "[color=%s]💡 Leuchtet: %s[/color]\n" % [GRUEN, ", ".join(r.lampen_an)]
	if not r.steckdosen_an.is_empty():
		t += "[color=%s]🔌 Spannung an: %s[/color]\n" % [GRUEN, ", ".join(r.steckdosen_an)]
	if not r.spulen_an.is_empty():
		t += "[color=%s]Angezogen: %s[/color]\n" % [GRUEN, ", ".join(r.spulen_an)]
	# Selbstkontrolle gegen den Auftrag
	var a := Aufgaben.finden(aufgabe_id)
	var funktion_ok := false
	if not a.is_empty():
		var b := Bewertung.bewerten(circuit, null, aufgabe_id)
		funktion_ok = b.funktion_ok == true
		t += "\n[b]Auftrag „%s“[/b]\n" % a.titel
		for f in b.anforderungen:
			t += "[color=%s]• %s[/color]\n" % [ROT, f]
		t += ("[color=%s]✔ Funktion entspricht dem Auftrag (alle Schalterstellungen geprüft).[/color]\n" % GRUEN) if funktion_ok \
			else ("[color=%s]✘ Funktion passt noch nicht zum Auftrag.[/color]\n" % ROT)
		t += "Vorläufige Bewertung: [b]%d Punkte, Note %d[/b]\n" % [b.punkte, b.note]
	_ergebnis_setzen(t, "Prüfergebnis")
	_zustand_anzeigen(r)
	_geprueft = r.ok and funktion_ok
	_schritte_aktualisieren()
	# Treppenlicht: Nachlaufzeit starten
	for id in circuit.geraete:
		if circuit.geraete[id].typ == "treppenlicht" and circuit.zustand[id].get("an", false) and treppen_timer.is_stopped():
			treppen_timer.start(NACHLAUFZEIT)
			_status("Treppenlicht an. Es geht nach %d Sekunden Nachlaufzeit wieder aus." % NACHLAUFZEIT)

## Lampe leuchtet, ausgeloeste Geraete kippen, Wippen zeigen die Stellung
func _zustand_anzeigen(r: Dictionary) -> void:
	for gid in geraete_knoten:
		var typ: String = circuit.geraete[gid].typ
		Modelle.zustand_zeigen(geraete_knoten[gid], typ, circuit.zustand.get(gid, {}), gid in r.get("lampen_an", []),
			gid in r.get("ausgeloest", []), gid in r.get("spulen_an", []) or gid in r.get("steckdosen_an", []))

func _treppenlicht_aus() -> void:
	for id in circuit.geraete:
		if circuit.geraete[id].typ == "treppenlicht":
			circuit.zustand[id] = {"an": false}
	_pruefen()
	_status("Nachlaufzeit abgelaufen: Treppenlicht ist wieder aus.")

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
		var meta := geladene_meta.duplicate()
		meta["schueler"] = name_feld.text
		meta["aufgabe"] = aufgabe_id
		meta["erstellt"] = Time.get_datetime_string_from_system()
		var err := Projektdatei.speichern(circuit, pfad, meta)
		_status("Gespeichert: %s" % pfad if err == OK else "Speichern fehlgeschlagen (Fehler %d)." % err)
	else:
		var d := Projektdatei.laden(pfad)
		if d.has("fehler"):
			_status(d.fehler)
			return
		circuit = d.circuit
		geladene_meta = d.meta
		name_feld.text = d.meta.get("schueler", "")
		aufgabe_id = d.meta.get("aufgabe", aufgabe_id)
		letztes_ergebnis = {}
		_geprueft = false
		_alles_neu_zeichnen()
		_auftrag_anzeigen()
		_bauplan_zeichnen()
		_ergebnis_setzen("" if d.unveraendert else "[color=#d35400]Hinweis: Datei wurde außerhalb von ESLS verändert.[/color]")
		_status("Geladen: %s" % pfad)

# ---------------------------------------------------------------- Zeichnen

func _geraet_zeichnen(id: String) -> void:
	var g: Dictionary = circuit.geraete[id]
	var info: Dictionary = BAUTEILE[g.typ]
	var param: Dictionary = g.param.duplicate()
	if g.typ == "abzweigdose":
		var n := 0
		for gid in circuit.geraete:
			if circuit.geraete[gid].param.get("dose", "") == id: n += 1
		param["klemmen"] = n
	var knoten := Modelle.geraet(g.typ, info.groesse, param)
	knoten.position = g.pos
	if not g.typ in ["einspeisung", "n_schiene", "pe_schiene"]:
		Modelle.schild(knoten, id, info.groesse)
		Modelle.zusammenfassen(knoten)
	add_child(knoten)
	geraete_knoten[id] = knoten
	Modelle.zustand_zeigen(knoten, g.typ, circuit.zustand.get(id, {}), false, false, false)

## Abzweigdose neu zeichnen (neue Verbindungsklemme sichtbar)
func dose_neu_zeichnen(id: String) -> void:
	if geraete_knoten.has(id):
		geraete_knoten[id].queue_free()
		_geraet_zeichnen(id)
		if ausgewaehlt == id:
			_overlay(geraete_knoten[id], mat_auswahl_rahmen)

## Geraete neu zeichnen, Auswahl bleibt
func _geraete_neu_zeichnen() -> void:
	for n in geraete_knoten.values(): n.queue_free()
	geraete_knoten.clear()
	for id in circuit.geraete:
		if BAUTEILE.has(circuit.geraete[id].typ):
			_geraet_zeichnen(id)
	if ausgewaehlt != "" and geraete_knoten.has(ausgewaehlt):
		_overlay(geraete_knoten[ausgewaehlt], mat_auswahl_rahmen)
	if not letztes_ergebnis.is_empty():
		_zustand_anzeigen(letztes_ergebnis)

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
	if info.get("einzelader", false):
		# Bruecke im Verteiler: duenne Einzelader in ihrer Farbe, etwas ueber den Geraeten
		var hoch: Array = []
		for pt in l.punkte:
			hoch.append((pt as Vector3) + Vector3(0, 0, 0.064))
		tube.mesh = _rohr(hoch, 0.0015)
		tube.material_override = _mat(ADERFARBE.get(l.adern[0].farbe, Color.BLACK), 0.5)
		knoten.add_child(tube)
		add_child(knoten)
		leitung_knoten[l.id] = knoten
		return
	# Abgemantelte Enden: Mantel endet 3 cm vor dem Geraeterand, davor sieht man die bunten Adern
	var gesamt := _laenge(l.punkte)
	var schnitt := {}
	for ende in ["start", "ende"]:
		schnitt[ende] = 0.0
		if l.abgemantelt.get(ende, false):
			schnitt[ende] = minf(_rand_lauf(l, ende) + MANTEL_VOR_RAND, gesamt / 2 - 0.005)
	tube.mesh = _rohr(_teilstueck(l.punkte, schnitt.start, gesamt - schnitt.ende), r)
	tube.material_override = mat_steuer if String(l.typ).begins_with("Steuer") else mat_nym
	knoten.add_child(tube)
	for s in l.schellen:
		Modelle.rohrschelle(knoten, s, r, _senkrecht_bei(l.punkte, s))
	for ende in ["start", "ende"]:
		if l.abgemantelt.get(ende, false):
			_adern_zeichnen(knoten, l, ende, r, schnitt[ende])
	Modelle.zusammenfassen(knoten)
	add_child(knoten)
	leitung_knoten[l.id] = knoten

## Verlaeuft die Leitung an dieser Stelle senkrecht?
func _senkrecht_bei(pts: Array, p: Vector3) -> bool:
	var best := INF
	var senk := false
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d := Geometry3D.get_closest_point_to_segment(p, a, b).distance_to(p)
		if d < best:
			best = d
			senk = absf(b.y - a.y) > absf(b.x - a.x)
	return senk

const MANTEL_VOR_RAND := 0.03   # so viel Mantel wird vor dem Geraet entfernt (sichtbare Adern)

## Laufmeter vom Leitungsende bis zum Rand des Geraets (dort tritt die Leitung ins Geraet ein)
func _rand_lauf(l: Dictionary, ende: String) -> float:
	var id: String = l.start_geraet if ende == "start" else l.ende_geraet
	var g: Dictionary = circuit.geraete.get(id, {})
	if g.is_empty() or not BAUTEILE.has(g.typ):
		return 0.0
	var gr: Vector3 = BAUTEILE[g.typ].groesse
	var mitte: Vector3 = g.pos
	var feld := Rect2(mitte.x - gr.x / 2, mitte.y - gr.y / 2, gr.x, gr.y)
	var pts: Array = l.punkte.duplicate()
	if ende == "ende":
		pts.reverse()
	var lauf := 0.0
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var t := Circuit._im_rechteck(Vector2(a.x, a.y), Vector2(b.x, b.y), feld)
		if t.is_empty() or t[0] > 0.0001:
			return lauf   # Segment beginnt schon ausserhalb
		if t[1] < 0.9999:
			return lauf + a.distance_to(b) * t[1]
		lauf += a.distance_to(b)
	return lauf

## Punkt und Richtung bei Laufmeter s
func _punkt_bei(pts: Array, s: float) -> Array:
	var lauf := 0.0
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d := a.distance_to(b)
		if lauf + d >= s or i == pts.size() - 2:
			var t := clampf((s - lauf) / maxf(d, 1e-6), 0.0, 1.0)
			return [a.lerp(b, t), (b - a).normalized()]
		lauf += d
	return [pts[0], Vector3.RIGHT]

## Teil der Leitung zwischen den Laufmetern von und bis
func _teilstueck(pts: Array, von: float, bis: float) -> Array:
	if von <= 0.0 and bis >= _laenge(pts) - 0.0001:
		return pts
	var aus := [_punkt_bei(pts, von)[0]]
	var lauf := 0.0
	for i in range(pts.size() - 1):
		lauf += (pts[i] as Vector3).distance_to(pts[i + 1])
		if lauf > von and lauf < bis:
			aus.append(pts[i + 1])
	aus.append(_punkt_bei(pts, bis)[0])
	return aus

## Abgemanteltes Ende: die Adern laufen einzeln (in ihren Farben) vom Mantelende bis ins Geraet
func _adern_zeichnen(knoten: Node3D, l: Dictionary, ende: String, r: float, schnitt: float) -> void:
	var pts: Array = l.punkte.duplicate()
	if pts.size() < 2:
		return
	if ende == "ende":
		pts.reverse()
	var rand := _rand_lauf(l, ende)
	var p_mantel: Array = _punkt_bei(pts, schnitt)
	var p_rand: Array = _punkt_bei(pts, maxf(rand - 0.012, 0.0))
	var dir: Vector3 = -(p_mantel[1] as Vector3)   # Richtung zum Geraet
	var seite := dir.cross(Vector3(0, 0, 1)).normalized()
	var n: int = l.adern.size()
	for i in range(n):
		var a: Dictionary = l.adern[i]
		var versatz := seite * (float(i) - (n - 1) / 2.0) * 0.0042
		var von: Vector3 = p_mantel[0] + Vector3(0, 0, r)
		var mitte: Vector3 = von.lerp(p_rand[0] + Vector3(0, 0, r), 0.45) + versatz
		var bis: Vector3 = p_rand[0] + versatz * 1.3 + Vector3(0, 0, r + 0.002)
		var mi := MeshInstance3D.new()
		mi.mesh = _rohr([von, mitte, bis], 0.0016)
		mi.material_override = Modelle.mat(ADERFARBE.get(a.farbe, Color.BLACK), 0.5)
		knoten.add_child(mi)
	# Mantelkante etwas heller (Schnittkante)
	var kante := MeshInstance3D.new()
	kante.mesh = _rohr([p_mantel[0] - dir * 0.001, p_mantel[0] + dir * 0.0015], r * 1.04)
	kante.material_override = Modelle.mat(Color(0.97, 0.97, 0.95), 0.6)
	knoten.add_child(kante)

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

## Beispiel: komplett aufgebautes Uebungsbrett anzeigen (Lehrermodus, Screenshots)
func musterbrett_zeigen() -> void:
	startbildschirm.hide()
	Musterbrett.aufbauen(self)
	_pruefen()
	_auftrag_anzeigen()
	auftrag_karte.hide()
	ergebnis_karte.hide()
	_status("Beispiel: komplett aufgebautes Übungsbrett (Kreuzschaltung und Steckdosenkreis). Schalter mit Auswahl anklicken und Leertaste drücken.")

func ergebnis_zeigen() -> void:
	ergebnis_karte.show()

# ---------------------------------------------------------------- Messen, Raster, Bauplan

var raster_knoten: Node3D
var bauplan_knoten: Node3D
var mess_knoten: Node3D
var waage_knoten: Node3D
var hilfs_knoten: Node3D
var mess_start: Variant = null
var waage_start := ""
var raster_an := false
var bauplan_an := false
var raster_knopf: Button
var bauplan_knopf: Button

func _mess_knoten_anlegen() -> void:
	raster_knoten = Node3D.new()
	raster_knoten.visible = false
	add_child(raster_knoten)
	bauplan_knoten = Node3D.new()
	add_child(bauplan_knoten)
	mess_knoten = Node3D.new()
	add_child(mess_knoten)
	waage_knoten = Node3D.new()
	add_child(waage_knoten)
	hilfs_knoten = Node3D.new()
	add_child(hilfs_knoten)
	_raster_bauen()

static func _unbeleuchtet(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

## Linien als flache Streifen in der Brettebene: [[a, b], ...]
func _linien(p: Node3D, linien: Array, breite: float, m: Material, z := 0.0008) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for li in linien:
		var a: Vector3 = li[0]
		var b: Vector3 = li[1]
		var d := (b - a).normalized()
		var q := Vector3(-d.y, d.x, 0) * breite / 2
		var oz := Vector3(0, 0, z)
		for v in [a - q, b - q, b + q, a - q, b + q, a + q]:
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(v + oz)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = m
	p.add_child(mi)

func _text3d(p: Node3D, t: String, pos: Vector3, groesse := 22, farbe := Color(0.1, 0.2, 0.45)) -> Label3D:
	var l := Label3D.new()
	l.text = t
	l.font_size = groesse
	l.pixel_size = 0.0005
	l.modulate = farbe
	l.outline_size = 6
	l.outline_modulate = Color(1, 1, 1, 0.85)
	l.position = pos
	l.no_depth_test = true
	l.render_priority = 2
	p.add_child(l)
	return l

## Raster: 1-cm-, 5-cm- und 10-cm-Linien, Massangaben vom linken und oberen Brettrand
func _raster_bauen() -> void:
	var fein := []
	var mittel := []
	var grob := []
	var links := -BOARD_W / 2
	var oben := BOARD_H / 2
	for i in range(int(BOARD_W * 100) + 1):
		var x := links + i * 0.01
		var li := [Vector3(x, -BOARD_H / 2, 0), Vector3(x, BOARD_H / 2, 0)]
		if i % 10 == 0: grob.append(li)
		elif i % 5 == 0: mittel.append(li)
		else: fein.append(li)
	for i in range(int(BOARD_H * 100) + 1):
		var y := oben - i * 0.01
		var li := [Vector3(-BOARD_W / 2, y, 0), Vector3(BOARD_W / 2, y, 0)]
		if i % 10 == 0: grob.append(li)
		elif i % 5 == 0: mittel.append(li)
		else: fein.append(li)
	_linien(raster_knoten, fein, 0.0006, _unbeleuchtet(Color(0.1, 0.25, 0.6, 0.18)), 0.0009)
	_linien(raster_knoten, mittel, 0.0009, _unbeleuchtet(Color(0.1, 0.25, 0.6, 0.35)), 0.001)
	_linien(raster_knoten, grob, 0.0014, _unbeleuchtet(Color(0.1, 0.25, 0.6, 0.6)), 0.0011)
	for i in range(0, int(BOARD_W * 100) + 1, 10):
		_text3d(raster_knoten, str(i), Vector3(links + i * 0.01, oben - 0.012, 0.08), 32)
	for i in range(10, int(BOARD_H * 100) + 1, 10):
		_text3d(raster_knoten, str(i), Vector3(links + 0.012, oben - i * 0.01, 0.08), 32)

func raster_umschalten() -> void:
	raster_an = not raster_an
	raster_knoten.visible = raster_an
	if raster_knopf: raster_knopf.button_pressed = raster_an
	_status("Raster %s: feine Linien 1 cm, kräftig 10 cm. Zahlen = cm vom linken bzw. oberen Brettrand." % ("an" if raster_an else "aus"))

## Bauplan: wo die Bauteile laut Auftrag hinkommen (durchsichtige Umrisse)
func bauplan_umschalten() -> void:
	var a := Aufgaben.finden(aufgabe_id)
	if not a.has("bauplan"):
		_status("Für diesen Auftrag gibt es keinen Bauplan.")
		bauplan_an = false
	else:
		bauplan_an = not bauplan_an
	if bauplan_knopf: bauplan_knopf.button_pressed = bauplan_an
	_bauplan_zeichnen()

func _bauplan_zeichnen() -> void:
	for k in bauplan_knoten.get_children():
		k.queue_free()
	var a := Aufgaben.finden(aufgabe_id)
	if not a.has("bauplan"):
		bauplan_an = false
		if bauplan_knopf: bauplan_knopf.button_pressed = false
	if not bauplan_an:
		return
	var flaeche := _unbeleuchtet(Color(0.15, 0.45, 1.0, 0.18))
	var rand := _unbeleuchtet(Color(0.1, 0.35, 0.9, 0.85))
	for b in a.bauplan:
		var typ: String = b[0]
		var p := Vector3(b[1].x, b[1].y, 0)
		var g: Vector3 = BAUTEILE[typ].groesse
		var h := Vector3(g.x / 2, 0, 0)
		var v := Vector3(0, g.y / 2, 0)
		_linien(bauplan_knoten, [[p - h, p + h]], g.y, flaeche, 0.0012)
		_linien(bauplan_knoten, [[p - h - v, p + h - v], [p - h + v, p + h + v], [p - h - v, p - h + v], [p + h - v, p + h + v]], 0.0015, rand, 0.0013)
		var von_links := int(round((p.x + BOARD_W / 2) * 100))
		var von_oben := int(round((BOARD_H / 2 - p.y) * 100))
		if not typ in HUTSCHIENE:
			_text3d(bauplan_knoten, "%s\n%d | %d cm" % [KACHEL_NAME.get(typ, BAUTEILE[typ].name), von_links, von_oben], p + Vector3(0, 0, 0.002), 26)
	_status("Bauplan an: blaue Umrisse zeigen, wo die Bauteile hinkommen (Mitte: cm von links | cm von oben).")

# ---- Zollstock

func _messen_klick(p: Vector3) -> void:
	if mess_start == null:
		mess_start = p
		_zollstock_zeichnen(p, p)
		_status("Zollstock: Startpunkt gesetzt. Jetzt den Endpunkt anklicken.")
		return
	var a: Vector3 = mess_start
	mess_start = null
	_zollstock_zeichnen(a, p)
	var d := a.distance_to(p)
	_status("Gemessen: %s cm  (waagerecht %s cm, senkrecht %s cm). Nächster Klick misst neu." % [_cm(d), _cm(absf(p.x - a.x)), _cm(absf(p.y - a.y))])

func _cm(m: float) -> String:
	return ("%.1f" % (m * 100)).replace(".", ",")

## Gelber Zollstock mit cm-Strichen vom Start- zum Endpunkt
func _zollstock_zeichnen(a: Vector3, b: Vector3) -> void:
	for k in mess_knoten.get_children():
		k.queue_free()
	var z := 0.075
	var marke := _unbeleuchtet(Color(0.9, 0.15, 0.1))
	for q in [a, b]:
		_linien(mess_knoten, [[q - Vector3(0.008, 0, 0), q + Vector3(0.008, 0, 0)], [q - Vector3(0, 0.008, 0), q + Vector3(0, 0.008, 0)]], 0.0015, marke, z + 0.002)
	var d := a.distance_to(b)
	if d < 0.005:
		return
	var dir := (b - a).normalized()
	var quer := Vector3(-dir.y, dir.x, 0)
	_linien(mess_knoten, [[a, b]], 0.018, _unbeleuchtet(Color(0.98, 0.82, 0.15, 0.92)), z)
	var striche := []
	for i in range(int(d * 100) + 1):
		var p := a + dir * i * 0.01
		var lang := 0.009 if i % 10 == 0 else (0.006 if i % 5 == 0 else 0.0035)
		striche.append([p + quer * 0.009, p + quer * (0.009 - lang)])
		if i % 10 == 0 and i > 0:
			_text3d(mess_knoten, str(i), p - quer * 0.003 + Vector3(0, 0, z), 18, Color(0.1, 0.1, 0.1))
	_linien(mess_knoten, striche, 0.0008, _unbeleuchtet(Color(0.1, 0.1, 0.1)), z + 0.001)
	var mitte := (a + b) / 2 + quer * 0.03 + Vector3(0, 0, z)
	_text3d(mess_knoten, "%s cm" % _cm(d), mitte, 34, Color(0.75, 0.1, 0.05))

func _messen_bewegung(p: Vector3) -> void:
	if werkzeug == Werkzeug.ZOLLSTOCK and mess_start != null:
		_zollstock_zeichnen(mess_start, p)
		_status("Zollstock: %s cm  (waagerecht %s, senkrecht %s)" % [_cm((mess_start as Vector3).distance_to(p)), _cm(absf(p.x - mess_start.x)), _cm(absf(p.y - mess_start.y))])

# ---- Wasserwaage

func _wasserwaage_klick(p: Vector3) -> void:
	var id := _geraet_bei(p)
	if id == "":
		_status("Wasserwaage: ein Bauteil anklicken, dann ein zweites. Die Waage zeigt, ob beide genau in einer Flucht sitzen.")
		return
	if waage_start == "" or waage_start == id:
		waage_start = id
		for k in waage_knoten.get_children(): k.queue_free()
		_status("Wasserwaage an %s angelegt. Jetzt das zweite Bauteil anklicken." % id)
		return
	var a: Vector3 = circuit.geraete[waage_start].pos
	var b: Vector3 = circuit.geraete[id].pos
	var ergebnis := _wasserwaage_zeichnen(a, b)
	_status("Wasserwaage %s – %s: %s" % [waage_start, id, ergebnis])
	waage_start = ""

## Waage zwischen zwei Punkten; Rueckgabe: Text mit dem Ergebnis
func _wasserwaage_zeichnen(a: Vector3, b: Vector3) -> String:
	for k in waage_knoten.get_children():
		k.queue_free()
	var waagerecht := absf(b.x - a.x) >= absf(b.y - a.y)
	var laenge := maxf(absf(b.x - a.x) if waagerecht else absf(b.y - a.y), 0.2) + 0.06
	var versatz := (b.y - a.y) if waagerecht else (b.x - a.x)
	var mitte := (a + b) / 2
	var z := 0.08
	var n := Node3D.new()
	n.position = Vector3(mitte.x, mitte.y, z)
	n.rotation.z = 0.0 if waagerecht else PI / 2
	waage_knoten.add_child(n)
	Modelle.box(n, Vector3(laenge, 0.028, 0.012), Vector3.ZERO, Modelle.mat(Color(0.80, 0.82, 0.85), 0.3, 0.7))
	Modelle.box(n, Vector3(laenge, 0.006, 0.0125), Vector3(0, 0.011, 0.0005), Modelle.mat(Color(0.2, 0.35, 0.75), 0.5))
	Modelle.box(n, Vector3(0.05, 0.016, 0.004), Vector3(0, -0.002, 0.007), Modelle.mat(Color(0.75, 0.95, 0.3, 0.75), 0.1))
	for s in [-0.011, 0.011]:
		Modelle.box(n, Vector3(0.0012, 0.016, 0.001), Vector3(s, -0.002, 0.0095), Modelle.mat(Color(0.1, 0.1, 0.1), 0.5))
	var schief := absf(versatz) > 0.0005
	var blase := clampf(versatz * 4.0, -0.018, 0.018)
	if not waagerecht:
		blase = -blase
	Modelle.zyl(n, 0.0045, 0.002, Vector3(blase, -0.002, 0.0095), Modelle.mat(Color(1, 1, 0.9), 0.1), 12)
	var text := ""
	if not schief:
		text = "✔ genau %s" % ("waagerecht" if waagerecht else "senkrecht (lotrecht)")
	else:
		text = "✘ %s cm %s versetzt" % [_cm(absf(versatz)), "in der Höhe" if waagerecht else "zur Seite"]
	_text3d(waage_knoten, text, Vector3(mitte.x, mitte.y, z) + (Vector3(0, 0.035, 0.01) if waagerecht else Vector3(0.05, 0, 0.01)), 30,
		Color(0.1, 0.5, 0.2) if not schief else Color(0.75, 0.1, 0.05))
	return text

# ---- Hilfslinien beim Setzen

## Beim Bauteil-Setzen: Umriss an der Mausposition und Fluchtlinien zu anderen Bauteilen
func _hilfslinien(p: Vector3) -> void:
	for k in hilfs_knoten.get_children():
		k.queue_free()
	if werkzeug != Werkzeug.BAUTEIL:
		return
	var g: Vector3 = BAUTEILE[bauteil_typ].groesse
	if bauteil_typ in HUTSCHIENE:
		if not Circuit.VERTEILER_FELD.has_point(Vector2(p.x, p.y)):
			return
		var beste: float = REIHEN[0]
		for y in REIHEN:
			if absf(y - p.y) < absf(beste - p.y): beste = y
		p.y = beste
	var h := Vector3(g.x / 2, 0, 0)
	var v := Vector3(0, g.y / 2, 0)
	var m := _unbeleuchtet(Color(0.1, 0.45, 1.0, 0.9))
	_linien(hilfs_knoten, [[p - h - v, p + h - v], [p - h + v, p + h + v], [p - h - v, p - h + v], [p + h - v, p + h + v]], 0.0018, m, 0.07)
	var flucht := []
	var namen := []
	for id in circuit.geraete:
		var o: Dictionary = circuit.geraete[id]
		if not BAUTEILE.has(o.typ) or o.typ in ["einspeisung", "n_schiene", "pe_schiene"]:
			continue
		var op: Vector3 = o.pos
		if absf(op.y - p.y) < 0.004:
			flucht.append([Vector3(minf(op.x, p.x), p.y, 0), Vector3(maxf(op.x, p.x), p.y, 0)])
			namen.append("%s (gleiche Höhe, %s cm Abstand)" % [id, _cm(absf(op.x - p.x))])
		if absf(op.x - p.x) < 0.004:
			flucht.append([Vector3(p.x, minf(op.y, p.y), 0), Vector3(p.x, maxf(op.y, p.y), 0)])
			namen.append("%s (senkrecht darüber/darunter)" % id)
	if not flucht.is_empty():
		_linien(hilfs_knoten, flucht, 0.0012, _unbeleuchtet(Color(0.95, 0.35, 0.1, 0.9)), 0.07)
		_status("%s setzen – fluchtet mit %s" % [BAUTEILE[bauteil_typ].name, ", ".join(namen)])
