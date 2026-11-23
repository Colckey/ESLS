class_name Nahansicht
extends PanelContainer
## Nahansicht zum Anklemmen. Links: Leitungsenden mit ihren Adern. Rechts: Klemmen.
## Ader anklicken, dann Klemme anklicken = anklemmen. Ader anklicken, dann "Lösen" = abklemmen.
## Im Verteiler (Einspeisung, FI, LS) sieht man alle Verteilergeraete und kann
## Bruecken mit H07V-K-Einzeladern legen. In der Abzweigdose setzt man Verbindungsklemmen.

const VERTEILER := ["einspeisung", "fi", "ls"]
const FARBNAME := {"bn": "braun", "bu": "blau", "gnye": "grün-gelb", "bk": "schwarz", "gy": "grau"}
const MAX_ADERN_SCHRAUBKLEMME := 2

var montage: Node   # montage.gd
var geraet := ""
var gruppe: Array = []
## Auswahl: {"art": "ader", "leitung": Dictionary, "index": int, "feld": "von"/"nach"} oder {"art": "klemme", "klemme": String}
var auswahl := {}
var bruecken_farbe := "bn"

var _titel: Label
var _hinweis: Label
var _links: VBoxContainer
var _rechts: VBoxContainer
var _extra: HBoxContainer

func _ready() -> void:
	position = Vector2(560, 90)
	custom_minimum_size = Vector2(700, 560)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.11, 0.13, 0.93)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(12)
	add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	add_child(v)
	var kopf := HBoxContainer.new()
	v.add_child(kopf)
	_titel = Label.new()
	_titel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kopf.add_child(_titel)
	var zu := Button.new()
	zu.text = "Schließen"
	zu.pressed.connect(func() -> void: hide())
	kopf.add_child(zu)
	_hinweis = Label.new()
	_hinweis.autowrap_mode = TextServer.AUTOWRAP_WORD
	_hinweis.custom_minimum_size = Vector2(670, 40)
	v.add_child(_hinweis)
	_extra = HBoxContainer.new()
	v.add_child(_extra)
	var spalten := HBoxContainer.new()
	spalten.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(spalten)
	for i in 2:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(330, 420)
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
		_titel.text = "Nahansicht: Verteiler (%s)" % ", ".join(gruppe)
	elif typ == "abzweigdose":
		gruppe = [id]
		for gid in _c().geraete:
			if _c().geraete[gid].param.get("dose", "") == id:
				gruppe.append(gid)
		_titel.text = "Nahansicht: Abzweigdose %s" % id
	else:
		gruppe = [id]
		_titel.text = "Nahansicht: %s" % id
	_hinweis.text = "Ader links anklicken, dann eine Klemme rechts. Nur abgemantelte und abisolierte Adern lassen sich anklemmen."
	show()
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
				b.add_theme_color_override("font_color", montage.ADERFARBE.get(a.farbe, Color.WHITE).lightened(0.3))
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
