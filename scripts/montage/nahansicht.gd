class_name Nahansicht
extends PanelContainer
## Nahansicht zum Anschliessen, mit 3D-Ansicht des geoeffneten Geraets (Anschluss3D).
## Reihenfolge wie in der Werkstatt: 1. Abmanteln (nur wenn die Leitung befestigt ist),
## 2. jede Ader abisolieren, 3. Ader anklicken und in die Klemme stecken.
## Ader anklicken, dann "Lösen" = abklemmen. Unter "Liste" gibt es dieselben Schritte als Text.
## Im Verteiler (Einspeisung, FI, LS) sieht man alle Verteilergeraete und kann
## Bruecken mit H07V-K-Einzeladern legen. In der Abzweigdose setzt man Verbindungsklemmen.

const VERTEILER := ["einspeisung", "n_schiene", "pe_schiene", "fi", "ls", "schuetz", "zeitrelais", "treppenlicht"]   # alles auf der Hutschiene
const FARBNAME := {"bn": "braun", "bu": "blau", "gnye": "grün-gelb", "bk": "schwarz", "gy": "grau"}
const MAX_ADERN_SCHRAUBKLEMME := 2

var montage: Node   # montage.gd
var geraet := ""
var gruppe: Array = []
## Auswahl: {"art": "ader", "leitung": Dictionary, "index": int, "feld": "von"/"nach"} oder {"art": "klemme", "klemme": String}
var auswahl := {}
var bruecken_farbe := "bn"
enum Modus { ABMANTELN, ABISOLIEREN, ANKLEMMEN }
var modus: int = Modus.ANKLEMMEN

var ansicht3d: Anschluss3D
var _liste: Control
var _modus_knoepfe := {}

var _titel: Label
var _hinweis: Label
var _links: VBoxContainer
var _rechts: VBoxContainer
var _extra: HBoxContainer

func _ready() -> void:
	position = Vector2(560, 90)
	custom_minimum_size = Vector2(840, 0)
	add_theme_stylebox_override("panel", Stil.box(Stil.HINTERGRUND, 10, Stil.AKZENT.darkened(0.3), 1, Vector2(14, 12)))
	var v := VBoxContainer.new()
	add_child(v)
	var kopf := HBoxContainer.new()
	v.add_child(kopf)
	_titel = Label.new()
	_titel.theme_type_variation = "Titel"
	_titel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(_titel)
	var liste_knopf := Button.new()
	liste_knopf.text = "Liste"
	liste_knopf.toggle_mode = true
	liste_knopf.focus_mode = Control.FOCUS_NONE
	liste_knopf.tooltip_text = "Statt der 3D-Ansicht eine Liste der Adern und Klemmen zeigen"
	liste_knopf.toggled.connect(func(an: bool) -> void:
		_liste.visible = an
		ansicht3d.visible = not an)
	kopf.add_child(liste_knopf)
	var zu := Button.new()
	zu.text = "Schließen"
	zu.pressed.connect(func() -> void: hide())
	kopf.add_child(zu)
	_hinweis = Label.new()
	_hinweis.theme_type_variation = "Leise"
	_hinweis.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hinweis.custom_minimum_size = Vector2(810, 40)
	v.add_child(_hinweis)
	# Arbeitsschritte in der Nahansicht
	var schritte := HBoxContainer.new()
	schritte.add_theme_constant_override("separation", 6)
	v.add_child(schritte)
	for m in [[Modus.ABMANTELN, "① Abmanteln"], [Modus.ABISOLIEREN, "② Abisolieren"], [Modus.ANKLEMMEN, "③ Anklemmen"]]:
		var b := Button.new()
		b.text = m[1]
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(modus_setzen.bind(m[0]))
		var ico := _ico(m[0])
		if ico:
			b.icon = ico
			b.add_theme_constant_override("icon_max_width", 24)
		schritte.add_child(b)
		_modus_knoepfe[m[0]] = b
	var mm := SpinBox.new()
	mm.min_value = 2
	mm.max_value = 30
	mm.suffix = "mm"
	mm.tooltip_text = "Abisolierlänge (richtig: 8 bis 12 mm)"
	mm.value = montage.abisolier_mm
	mm.value_changed.connect(func(w: float) -> void:
		montage.abisolier_mm = w
		if modus == Modus.ABISOLIEREN: modus_setzen(modus))
	schritte.add_child(mm)
	_extra = HBoxContainer.new()
	schritte.add_child(_extra)
	ansicht3d = Anschluss3D.new()
	ansicht3d.geklickt.connect(_3d_klick)
	ansicht3d.ueber.connect(func(t: String) -> void:
		if t != "": _hinweis.text = t)
	v.add_child(ansicht3d)
	var spalten := HBoxContainer.new()
	spalten.size_flags_vertical = Control.SIZE_EXPAND_FILL
	spalten.visible = false
	_liste = spalten
	v.add_child(spalten)
	for i in 2:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(400, 450)
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spalten.add_child(scroll)
		var box := VBoxContainer.new()
		box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(box)
		if i == 0: _links = box
		else: _rechts = box

func oeffnen(id: String) -> void:
	geraet = id
	auswahl = {}
	var typ: String = _c().geraete[id].typ
	gruppe = []
	if typ in VERTEILER:
		for gid in _c().geraete:
			if _c().geraete[gid].typ in VERTEILER:
				gruppe.append(gid)
		_titel.text = "Nahansicht: Verteiler"
	elif typ == "abzweigdose":
		gruppe = [id]
		for gid in _c().geraete:
			if _c().geraete[gid].param.get("dose", "") == id:
				gruppe.append(gid)
		_titel.text = "Nahansicht: Abzweigdose %s" % id
	else:
		gruppe = [id]
		_titel.text = "Nahansicht: %s" % id
	show()
	_aufbauen()
	modus_setzen(modus)

func modus_setzen(m: int) -> void:
	modus = m
	auswahl = {}
	for k in _modus_knoepfe:
		_modus_knoepfe[k].button_pressed = k == m
	match m:
		Modus.ABMANTELN: _hinweis.text = "① Abmantelungswerkzeug: den grauen Mantel einer Leitung unten anklicken. Geht nur, wenn die Leitung höchstens 10 cm vor dem Gerät befestigt ist."
		Modus.ABISOLIEREN: _hinweis.text = "② Abisolierzange (%d mm): jede Ader einzeln anklicken. Richtig sind 8 bis 12 mm." % montage.abisolier_mm
		Modus.ANKLEMMEN: _hinweis.text = "③ Schraubendreher: Ader anklicken, dann die Klemme. Nur abisolierte Adern haben Kontakt."
	_aufbauen()

func _3d_klick(art: String, d: Dictionary) -> void:
	match art:
		"mantel":
			if modus != Modus.ABMANTELN:
				_hinweis.text = "Das ist der Mantel von %s. Zum Abmanteln oben „① Abmanteln“ wählen." % d.leitung.id
				return
			abmanteln(d.leitung, d.ende)
		"ader":
			if modus == Modus.ABISOLIEREN:
				abisolieren(d.leitung, d.index, d.feld)
			elif modus == Modus.ANKLEMMEN:
				_ader_gewaehlt(d.leitung, d.index, d.feld)
				_hinweis.text = "%s Ader %s gewählt. Jetzt die Klemme anklicken (oder „Ausgewählte Ader lösen“)." % [d.leitung.id, FARBNAME.get(d.leitung.adern[d.index].farbe, "")]
			else:
				_hinweis.text = "Die Leitung ist schon abgemantelt. Weiter mit „② Abisolieren“."
		"klemme":
			if modus != Modus.ANKLEMMEN:
				_hinweis.text = "Klemme %s. Zum Anschließen „③ Anklemmen“ wählen." % d.klemme
				return
			_klemme_gewaehlt(d.klemme)
		"bruecke":
			_bruecke_entfernen(d.leitung)

## Leitungsende abmanteln: nur wenn die Leitung vor dem Geraet befestigt ist
func abmanteln(l: Dictionary, ende: String) -> bool:
	if l.abgemantelt.get(ende, false):
		_hinweis.text = "%s ist hier schon abgemantelt. Weiter mit „② Abisolieren“." % l.id
		return false
	var abst := Circuit.abstand_befestigung(l, ende)
	if abst > Circuit.MAX_ENDABSTAND + 0.001:
		_hinweis.text = "%s ist vor dem Gerät nicht befestigt%s. Erst eine Iso-Schelle höchstens 10 cm vor dem Gerät setzen, dann abmanteln." % [l.id, "" if abst == INF else " (nächste Befestigung %d cm entfernt)" % int(abst * 100)]
		return false
	l.abgemantelt[ende] = true
	_hinweis.text = "%s abgemantelt. Jetzt mit „② Abisolieren“ jede Ader abisolieren." % l.id
	montage.nahansicht_geaendert()
	_aufbauen()
	return true

## Eine Ader abisolieren (Laenge aus der Abisolierzange)
func abisolieren(l: Dictionary, i: int, feld: String) -> void:
	var ende := "start" if feld == "von" else "ende"
	if not l.abgemantelt.get(ende, false):
		_hinweis.text = "Erst abmanteln! Mit der Abisolierzange kommt man nicht durch den Mantel."
		return
	var mm: float = montage.abisolier_mm
	l.adern[i]["abisoliert_" + feld] = mm
	var hinweis := ""
	if mm < Circuit.ABISOLIERLAENGE.x:
		hinweis = " Zu kurz: die Klemme fasst evtl. nur die Isolierung."
	elif mm > Circuit.ABISOLIERLAENGE.y:
		hinweis = " Zu lang: blankes Kupfer schaut aus der Klemme."
	_hinweis.text = "%s Ader %s: %d mm abisoliert.%s" % [l.id, FARBNAME.get(l.adern[i].farbe, l.adern[i].farbe), mm, hinweis]
	montage.nahansicht_geaendert()
	_aufbauen()

func _c() -> Circuit:
	return montage.circuit

func _leeren(box: Container) -> void:
	for k in box.get_children():
		k.queue_free()

func _aufbauen() -> void:
	_leeren(_links)
	_leeren(_rechts)
	_leeren(_extra)
	var typ: String = _c().geraete[geraet].typ
	if ansicht3d:
		ansicht3d.aufbauen(_c(), gruppe, auswahl, montage.ADERFARBE, montage.BAUTEILE)
	if typ == "abzweigdose":
		var b := Button.new()
		b.text = "Verbindungsklemme (5-fach) einsetzen"
		b.pressed.connect(_klemme_einsetzen)
		_extra.add_child(b)
	if typ in VERTEILER:
		var lbl := Label.new()
		lbl.text = "Brücke (H07V-K 1,5):"
		_extra.add_child(lbl)
		var ob := OptionButton.new()
		var farben := ["bn", "bk", "gy", "bu", "gnye"]
		for f in farben:
			ob.add_item(FARBNAME[f])
		ob.selected = farben.find(bruecken_farbe)
		ob.item_selected.connect(func(i: int) -> void: bruecken_farbe = farben[i])
		_extra.add_child(ob)
		var hb := Label.new()
		hb.text = "  (zwei Klemmen nacheinander anklicken)"
		_extra.add_child(hb)
	var los := Button.new()
	los.text = "Ausgewählte Ader lösen"
	los.pressed.connect(_loesen)
	_extra.add_child(los)

	# Links: Leitungsenden
	var ueber := Label.new()
	ueber.text = "Leitungen"
	_links.add_child(ueber)
	for l in _c().leitungen:
		var info: Dictionary = Circuit.LEITUNGEN[l.typ]
		if info.get("einzelader", false):
			continue
		for ende in [["start_geraet", "von", "start"], ["ende_geraet", "nach", "ende"]]:
			if l.get(ende[0], "") not in gruppe:
				continue
			var kopf := Label.new()
			kopf.text = "%s  %s%s" % [l.id, l.typ, "" if l.abgemantelt[ende[2]] else "  (noch nicht abgemantelt)"]
			_links.add_child(kopf)
			for i in l.adern.size():
				var a: Dictionary = l.adern[i]
				var b := Button.new()
				var ziel: String = a[ende[1]]
				var mm: float = a.get("abisoliert_" + ende[1], 0.0)
				b.text = "  %s  %s  ->  %s" % [FARBNAME.get(a.farbe, "Ader " + a.farbe), ("%d mm" % mm) if mm > 0 else "isoliert", ziel if ziel != "" else "frei"]
				b.alignment = HORIZONTAL_ALIGNMENT_LEFT
				b.add_theme_color_override("font_color", (montage.ADERFARBE.get(a.farbe, Stil.TEXT) as Color).darkened(0.25))
				b.toggle_mode = true
				b.button_pressed = auswahl.get("art", "") == "ader" and auswahl.leitung == l and auswahl.index == i and auswahl.feld == ende[1]
				b.pressed.connect(_ader_gewaehlt.bind(l, i, ende[1]))
				_links.add_child(b)
	# Bruecken im Verteiler
	if typ in VERTEILER:
		var bt := Label.new()
		bt.text = "Brücken"
		_links.add_child(bt)
		for l in _c().leitungen:
			if Circuit.LEITUNGEN[l.typ].get("einzelader", false) and l.start_geraet in gruppe:
				var b := Button.new()
				b.text = "  %s %s: %s <-> %s  (entfernen)" % [l.id, FARBNAME.get(l.adern[0].farbe, ""), l.adern[0].von, l.adern[0].nach]
				b.alignment = HORIZONTAL_ALIGNMENT_LEFT
				b.pressed.connect(_bruecke_entfernen.bind(l))
				_links.add_child(b)

	# Rechts: Klemmen
	for gid in gruppe:
		var g: Dictionary = _c().geraete[gid]
		var klemmen: Array = Circuit.TYPEN[g.typ]
		if klemmen.is_empty():
			continue
		var kopf := Label.new()
		kopf.text = "%s (%s)" % [gid, montage.BAUTEILE[g.typ].name if montage.BAUTEILE.has(g.typ) else "Verbindungsklemme"]
		_rechts.add_child(kopf)
		var reihe := HFlowContainer.new()
		_rechts.add_child(reihe)
		for k in klemmen:
			var kid: String = gid + ":" + k
			var belegt := _belegung(kid)
			var b := Button.new()
			b.text = "%s (%d)" % [k, belegt.size()]
			b.tooltip_text = "%s: %s" % [kid, ", ".join(belegt) if not belegt.is_empty() else "frei"]
			b.toggle_mode = true
			b.button_pressed = auswahl.get("art", "") == "klemme" and auswahl.klemme == kid
			b.pressed.connect(_klemme_gewaehlt.bind(kid))
			reihe.add_child(b)

## Liste der Adern an einer Klemme ("W1 braun")
func _belegung(kid: String) -> Array:
	var r := []
	for l in _c().leitungen:
		for a in l.adern:
			for f in ["von", "nach"]:
				if a.get(f, "") == kid:
					r.append("%s %s" % [l.id, FARBNAME.get(a.farbe, a.farbe)])
	return r

func _max_adern(kid: String) -> int:
	var typ: String = _c().geraete[kid.get_slice(":", 0)].typ
	return 1 if typ == "klemme" else MAX_ADERN_SCHRAUBKLEMME

func _ader_gewaehlt(l: Dictionary, i: int, feld: String) -> void:
	auswahl = {"art": "ader", "leitung": l, "index": i, "feld": feld}
	_aufbauen()

func _klemme_gewaehlt(kid: String) -> void:
	if auswahl.get("art", "") == "ader":
		_anklemmen(auswahl.leitung, auswahl.index, auswahl.feld, kid)
		return
	if auswahl.get("art", "") == "klemme" and _c().geraete[geraet].typ in VERTEILER and auswahl.klemme != kid:
		_bruecke_legen(auswahl.klemme, kid)
		return
	auswahl = {"art": "klemme", "klemme": kid}
	_hinweis.text = "%s: %s" % [kid, ", ".join(_belegung(kid)) if not _belegung(kid).is_empty() else "frei"]
	_aufbauen()

func _anklemmen(l: Dictionary, i: int, feld: String, kid: String) -> void:
	var a: Dictionary = l.adern[i]
	var ende := "start" if feld == "von" else "ende"
	if not l.abgemantelt[ende]:
		_hinweis.text = "Die Leitung %s ist hier noch nicht abgemantelt. Erst das Abmantelungswerkzeug benutzen." % l.id
		return
	if a.get("abisoliert_" + feld, 0.0) <= 0.0:
		_hinweis.text = "Die Ader ist noch isoliert. Erst mit der Abisolierzange abisolieren."
		return
	if _belegung(kid).size() >= _max_adern(kid) and a[feld] != kid:
		_hinweis.text = "Klemme %s ist voll (max. %d Ader(n))." % [kid, _max_adern(kid)]
		return
	a[feld] = kid
	_hinweis.text = "%s %s an %s angeklemmt." % [l.id, FARBNAME.get(a.farbe, a.farbe), kid]
	auswahl = {}
	montage.nahansicht_geaendert()
	_aufbauen()

func _loesen() -> void:
	if auswahl.get("art", "") != "ader":
		_hinweis.text = "Erst eine Ader links auswählen."
		return
	auswahl.leitung.adern[auswahl.index][auswahl.feld] = ""
	_hinweis.text = "Ader gelöst."
	auswahl = {}
	montage.nahansicht_geaendert()
	_aufbauen()

func _klemme_einsetzen() -> void:
	var n := 1
	while _c().geraete.has("%s_k%d" % [geraet, n]):
		n += 1
	var kid := "%s_k%d" % [geraet, n]
	_c().geraet_hinzufuegen(kid, "klemme", _c().geraete[geraet].pos, {"dose": geraet})
	gruppe.append(kid)
	_hinweis.text = "Verbindungsklemme %s eingesetzt." % kid
	montage.dose_neu_zeichnen(geraet)
	_aufbauen()

func _bruecke_legen(k1: String, k2: String) -> void:
	if _belegung(k1).size() >= _max_adern(k1) or _belegung(k2).size() >= _max_adern(k2):
		_hinweis.text = "Eine der Klemmen ist schon voll."
		auswahl = {}
		_aufbauen()
		return
	var n := 1
	var ids := []
	for l in _c().leitungen:
		ids.append(l.id)
	while ("B%d" % n) in ids:
		n += 1
	var g1: String = k1.get_slice(":", 0)
	var g2: String = k2.get_slice(":", 0)
	var l := {
		"id": "B%d" % n, "typ": "H07V-K 1,5",
		"punkte": [_c().geraete[g1].pos, _c().geraete[g2].pos], "schellen": [],
		"abgemantelt": {"start": true, "ende": true},
		"adern": [{"farbe": bruecken_farbe, "von": k1, "nach": k2, "abisoliert_von": 10.0, "abisoliert_nach": 10.0}],
		"start_geraet": g1, "ende_geraet": g2,
	}
	_c().leitung_hinzufuegen(l)
	_hinweis.text = "Brücke B%d (%s) von %s nach %s gelegt." % [n, FARBNAME[bruecken_farbe], k1, k2]
	auswahl = {}
	montage.nahansicht_geaendert()
	_aufbauen()

func _bruecke_entfernen(l: Dictionary) -> void:
	_c().leitungen.erase(l)
	_hinweis.text = "Brücke %s entfernt." % l.id
	montage._alles_neu_zeichnen()
	show()
	_aufbauen()

func _ico(m: int) -> Texture2D:
	var pfad := "res://grafik/werkzeuge/%s.png" % ["abmanteln", "abisolieren", "anklemmen"][m]
	return load(pfad) if ResourceLoader.exists(pfad) else null
