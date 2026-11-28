class_name Tutorial
extends PanelContainer
## Tutorial: Schritt fuer Schritt eine Steckdose anschliessen, vom Verteiler bis zum Pruefen.
## Jeder Schritt erklaert, was zu tun ist, nimmt das passende Werkzeug und hakt sich von selbst ab,
## sobald er erledigt ist. „Vormachen“ erledigt den Schritt automatisch, damit man sieht, wie es geht.

var m: Node   # montage.gd
var nr := 0
var _schritte: Array = []
var _kopf: Label
var _titel: Label
var _text: RichTextLabel
var _status: Label
var _zurueck: Button
var _vor: Button
var _warte := 0.0
var _fertig_seit := -1.0
var _zurueck_geblaettert := false
var _verschoben := false     # vom Benutzer verschoben: Position nicht mehr automatisch setzen
var _ziehen := false
var _inhalt: Array = []      # Elemente, die beim Einklappen verschwinden
var _klapp: Button

const SD_POS := Vector3(-0.18, -0.33, 0)

func _init(montage: Node) -> void:
	m = montage
	_schritte = _schritte_bauen()

func _ready() -> void:
	theme_type_variation = "Karte"
	custom_minimum_size = Vector2(380, 0)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	add_child(v)
	var kz := HBoxContainer.new()
	v.add_child(kz)
	_kopf = Label.new()
	_kopf.theme_type_variation = "Leise"
	_kopf.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_kopf.mouse_filter = Control.MOUSE_FILTER_STOP
	_kopf.mouse_default_cursor_shape = Control.CURSOR_MOVE
	_kopf.tooltip_text = "Hier festhalten und ziehen, um das Tutorial zu verschieben"
	_kopf.gui_input.connect(_kopf_eingabe)
	kz.add_child(_kopf)
	_klapp = Button.new()
	_klapp.text = "Einklappen"
	_klapp.tooltip_text = "Tutorial klein machen, damit du darunter arbeiten kannst"
	_klapp.focus_mode = Control.FOCUS_NONE
	_klapp.pressed.connect(_umklappen)
	kz.add_child(_klapp)
	var zu := Button.new()
	zu.text = "Tutorial beenden"
	zu.focus_mode = Control.FOCUS_NONE
	zu.pressed.connect(queue_free)
	kz.add_child(zu)
	_titel = Label.new()
	_titel.theme_type_variation = "Titel"
	_titel.autowrap_mode = TextServer.AUTOWRAP_WORD
	_titel.custom_minimum_size = Vector2(350, 0)
	v.add_child(_titel)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.custom_minimum_size = Vector2(350, 0)
	v.add_child(_text)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	_status.custom_minimum_size = Vector2(350, 0)
	v.add_child(_status)
	var knoepfe := HBoxContainer.new()
	knoepfe.add_theme_constant_override("separation", 6)
	v.add_child(knoepfe)
	_zurueck = Button.new()
	_zurueck.text = "◀ Zurück"
	_zurueck.focus_mode = Control.FOCUS_NONE
	_zurueck.pressed.connect(func() -> void:
		schritt_zeigen(nr - 1)
		_zurueck_geblaettert = true)
	knoepfe.add_child(_zurueck)
	var vormachen := Button.new()
	vormachen.text = "▶ Vormachen"
	vormachen.tooltip_text = "Das Programm erledigt diesen Schritt, damit du siehst, wie es geht"
	vormachen.focus_mode = Control.FOCUS_NONE
	vormachen.theme_type_variation = "AkzentButton"
	vormachen.pressed.connect(vormachen_jetzt)
	knoepfe.add_child(vormachen)
	_vor = Button.new()
	_vor.text = "Weiter ▶"
	_vor.focus_mode = Control.FOCUS_NONE
	_vor.pressed.connect(func() -> void: schritt_zeigen(nr + 1))
	knoepfe.add_child(_vor)
	_inhalt = [_titel, _text, _status, knoepfe]
	schritt_zeigen(0)

## Kopfzeile ziehen = Tutorial verschieben
func _kopf_eingabe(ev: InputEvent) -> void:
	if ev is InputEventMouseButton and ev.button_index == MOUSE_BUTTON_LEFT:
		_ziehen = ev.pressed
	elif ev is InputEventMouseMotion and _ziehen:
		_verschoben = true
		var vp := get_viewport_rect().size
		position = (position + ev.relative).clamp(Vector2.ZERO, vp - Vector2(120, 40))

func _umklappen() -> void:
	var zeigen := not _titel.visible
	for c in _inhalt:
		(c as Control).visible = zeigen
	_klapp.text = "Einklappen" if zeigen else "Ausklappen"
	reset_size()

func anzahl() -> int:
	return _schritte.size()

func schritt_zeigen(i: int) -> void:
	nr = clampi(i, 0, _schritte.size() - 1)
	_zurueck_geblaettert = false
	_fertig_seit = -1.0
	var s: Dictionary = _schritte[nr]
	_kopf.text = "Tutorial · Schritt %d von %d   (hier ziehen zum Verschieben)" % [nr + 1, _schritte.size()]
	_titel.text = s.titel
	_text.text = s.text + ("\n\n[color=#5a6270]Werkzeug: [b]%s[/b][/color]" % s.werkzeug if s.has("werkzeug") else "")
	_zurueck.disabled = nr == 0
	_vor.disabled = nr == _schritte.size() - 1
	if s.has("vorbereiten"):
		(s.vorbereiten as Callable).call()
	_status_setzen(false)

func vormachen_jetzt() -> void:
	var s: Dictionary = _schritte[nr]
	if s.has("vormachen"):
		(s.vormachen as Callable).call()
	_pruefen_jetzt()

func erledigt(i := -1) -> bool:
	var s: Dictionary = _schritte[nr if i < 0 else i]
	return (s.fertig as Callable).call()

func _status_setzen(ok: bool) -> void:
	if ok:
		_status.text = "✔ Geschafft!" + ("" if nr < _schritte.size() - 1 else " Das Tutorial ist fertig. Jetzt kannst du einen Auftrag selbst bauen.")
		_status.add_theme_color_override("font_color", Stil.GRUEN.darkened(0.2))
	else:
		_status.text = "Noch nicht erledigt. Nicht sicher? „▶ Vormachen“ zeigt es dir."
		_status.add_theme_color_override("font_color", Color(0.45, 0.47, 0.52))

func _pruefen_jetzt() -> void:
	var ok := erledigt()
	_status_setzen(ok)
	if ok and _fertig_seit < 0:
		_fertig_seit = 0.0

func _process(dt: float) -> void:
	_warte += dt
	if _warte < 0.3:
		return
	_warte = 0.0
	# Liegt die 3D-Ansicht offen, rutscht das Tutorial nach links ueber die Bauteil-Leiste
	if not _verschoben:
		var nah_offen: bool = m.nahansicht != null and m.nahansicht.visible
		position.x = 8.0 if nah_offen else float(m.PANEL_BREITE + 12)
	move_to_front()
	_pruefen_jetzt()
	if _fertig_seit >= 0.0:
		_fertig_seit += 0.3
		if _fertig_seit > 1.2 and nr < _schritte.size() - 1 and not _zurueck_geblaettert:
			schritt_zeigen(nr + 1)

# ---------------------------------------------------------------- Hilfen

func _c() -> Circuit:
	return m.circuit

func _id(typ: String) -> String:
	for gid in _c().geraete:
		if _c().geraete[gid].typ == typ:
			return gid
	return ""

## Gibt es eine Bruecke (H07V-K) zwischen k1 und einer Klemme, die mit k2 beginnt?
func _bruecke(k1: String, k2_anfang: String) -> bool:
	for l in _c().leitungen:
		var info: Dictionary = Circuit.LEITUNGEN[l.typ]
		if not info.get("feindraehtig", false):
			continue
		var a: Dictionary = l.adern[0]
		if (a.von == k1 and String(a.nach).begins_with(k2_anfang)) or (a.nach == k1 and String(a.von).begins_with(k2_anfang)):
			return true
	return false

func _schiene_ok() -> bool:
	var fi := _id("fi")
	var ls := _id("ls")
	for l in _c().leitungen:
		if Circuit.LEITUNGEN[l.typ].get("schiene", false):
			var hat_fi := false
			var hat_ls := false
			for a in l.adern:
				for f in ["von", "nach"]:
					if a[f] == fi + ":L_out": hat_fi = true
					if a[f] == ls + ":in": hat_ls = true
			if hat_fi and hat_ls:
				return true
	return false

func _alle_gecrimpt() -> bool:
	var n := 0
	for l in _c().leitungen:
		if Circuit.LEITUNGEN[l.typ].get("feindraehtig", false):
			for f in ["von", "nach"]:
				n += 1
				if not l.adern[0].get("huelse_" + f, false):
					return false
	return n >= 8

func _leitung() -> Variant:
	var ls := _id("ls")
	var sd := _id("steckdose")
	for l in _c().leitungen:
		if l.typ == "NYM-J 3x2,5" and ((l.start_geraet == ls and l.ende_geraet == sd) or (l.start_geraet == sd and l.ende_geraet == ls)):
			return l
	return null

## Feld ("von"/"nach") der Leitung am Geraet gid
func _feld(l: Dictionary, gid: String) -> String:
	return "von" if l.start_geraet == gid else "nach"

func _verteiler_ansicht() -> void:
	m.cam_target = Vector3(-0.40, 0.13, 0)
	m.cam_dist = 0.55
	m.cam_yaw = 0.0
	m.cam_pitch = 0.0
	m._kamera_aktualisieren()

func _brett_ansicht() -> void:
	m.cam_target = Vector3(-0.28, -0.02, 0)
	m.cam_dist = 1.05
	m.cam_yaw = 0.0
	m.cam_pitch = 0.0
	m._kamera_aktualisieren()

func _nah(modus: int) -> Nahansicht:
	m._nahansicht_oeffnen(_id("fi"), modus)
	return m.nahansicht

# ---------------------------------------------------------------- Schritte

func _schritte_bauen() -> Array:
	var W = m.Werkzeug
	var NM = Nahansicht.Modus
	return [
		{
			"titel": "1. FI-Schalter in den Verteiler setzen",
			"text": "Der Verteiler ist oben links. Wähle links die Kachel [b]FI-Schalter[/b] und klicke auf die [b]obere Hutschiene[/b] (die graue Metallschiene). Er rastet von selbst ein, Bohren ist im Verteiler nicht nötig.",
			"werkzeug": "Bauteil FI-Schalter",
			"vorbereiten": func() -> void:
				_verteiler_ansicht()
				m.bauteil_typ = "fi"
				m._werkzeug_waehlen(W.BAUTEIL),
			"vormachen": func() -> void:
				m.bauteil_typ = "fi"
				m._bauteil_setzen(Vector3(-0.50, 0.17, 0)),
			"fertig": func() -> bool: return _id("fi") != "",
		},
		{
			"titel": "2. LS-Schalter daneben setzen",
			"text": "Wähle [b]LS B16[/b] und setze ihn rechts neben den FI auf dieselbe Hutschiene. Der LS schützt die Leitung zur Steckdose vor Überlast und Kurzschluss.",
			"werkzeug": "Bauteil LS B16",
			"vorbereiten": func() -> void:
				m.bauteil_typ = "ls"
				m._werkzeug_waehlen(W.BAUTEIL),
			"vormachen": func() -> void:
				m.bauteil_typ = "ls"
				m._bauteil_setzen(Vector3(-0.45, 0.17, 0)),
			"fertig": func() -> bool: return _id("ls") != "",
		},
		{
			"titel": "3. Einspeisung mit dem FI verbinden (H07V-K)",
			"text": "Die Zuleitung vom CEE-Stecker ist schon an der grauen [b]Hauptklemme L, N, PE[/b] angeschlossen.\n• Mit dem [b]Schraubendreher[/b] den Verteiler anklicken, es öffnet sich die 3D-Ansicht.\n• [b]Brücke H07V-K[/b] wählen, Farbe [b]braun[/b], dann [b]Hauptklemme L[/b] und [b]FI L_in[/b] anklicken.\n• Farbe [b]blau[/b], dann [b]Hauptklemme N[/b] und [b]FI N_in[/b].",
			"werkzeug": "Schraubendreher → ④ Brücke H07V-K",
			"vorbereiten": func() -> void: m._werkzeug_waehlen(W.ANKLEMMEN),
			"vormachen": func() -> void:
				var n := _nah(NM.BRUECKE)
				var fi := _id("fi")
				if not _bruecke("netz:L", fi + ":L_in"):
					n.bruecken_farbe = "bn"
					n._bruecke_legen("netz:L", fi + ":L_in")
				if not _bruecke("netz:N", fi + ":N_in"):
					n.bruecken_farbe = "bu"
					n._bruecke_legen("netz:N", fi + ":N_in"),
			"fertig": func() -> bool: return _bruecke("netz:L", _id("fi") + ":L_in") and _bruecke("netz:N", _id("fi") + ":N_in"),
		},
		{
			"titel": "4. Phasenschiene auf FI und LS stecken",
			"text": "Statt einzelner Brücken steckt man im Verteiler eine [b]Phasenschiene[/b] (Kammschiene) auf: Sie verbindet den Ausgang [b]L[/b] des FI mit den Eingängen aller LS.\nIn der 3D-Ansicht des Verteilers auf [b]„Phasenschiene aufstecken“[/b] klicken.",
			"werkzeug": "Schraubendreher → Phasenschiene aufstecken",
			"vormachen": func() -> void:
				_nah(NM.BRUECKE).phasenschiene_aufstecken(),
			"fertig": _schiene_ok,
		},
		{
			"titel": "5. N und PE auf die Klemmen legen",
			"text": "Der Neutralleiter muss [b]hinter[/b] dem FI abgenommen werden, sonst löst der FI aus.\n• [b]Brücke[/b], Farbe [b]blau[/b]: [b]FI N_out[/b] → eine blaue [b]N-Klemme[/b].\n• Farbe [b]grün-gelb[/b]: [b]Hauptklemme PE[/b] → eine grüne [b]PE-Klemme[/b].",
			"werkzeug": "Schraubendreher → ④ Brücke H07V-K",
			"vormachen": func() -> void:
				var n := _nah(NM.BRUECKE)
				if not _bruecke(_id("fi") + ":N_out", "x_n:"):
					n.bruecken_farbe = "bu"
					n._bruecke_legen(_id("fi") + ":N_out", "x_n:1")
				if not _bruecke("netz:PE", "x_pe:"):
					n.bruecken_farbe = "gnye"
					n._bruecke_legen("netz:PE", "x_pe:1"),
			"fertig": func() -> bool: return _bruecke(_id("fi") + ":N_out", "x_n:") and _bruecke("netz:PE", "x_pe:"),
		},
		{
			"titel": "6. Aderendhülsen crimpen",
			"text": "H07V-K ist [b]feindrähtig[/b]. Ohne Aderendhülse spleißen die feinen Drähte in der Klemme auf. Deshalb kommt auf jedes Ende eine Hülse (1,5 mm² = rot), die mit der Crimpzange verpresst wird.\n[b]Aderendhülse crimpen[/b] wählen und jedes Brückenende mit dem [b]gelben Punkt[/b] anklicken.",
			"werkzeug": "Schraubendreher → ⑤ Aderendhülse crimpen",
			"vormachen": func() -> void:
				Musterbrett.alle_crimpen(_nah(NM.CRIMPEN)),
			"fertig": _alle_gecrimpt,
		},
		{
			"titel": "7. Bohren und Steckdose setzen",
			"text": "Schließe die 3D-Ansicht. Mit der [b]Bohrmaschine[/b] zwei Löcher unten links bohren (dort, wo später die Steckdose sitzt). Dann die Kachel [b]Steckdose[/b] wählen und auf die Bohrungen klicken.\nTipp: Taste [b]B[/b] zeigt den Bauplan, Taste [b]R[/b] das cm-Raster.",
			"werkzeug": "Bohrmaschine, dann Bauteil Steckdose",
			"vorbereiten": func() -> void:
				if m.nahansicht: m.nahansicht.hide()
				_brett_ansicht()
				m._werkzeug_waehlen(W.BOHRER),
			"vormachen": func() -> void:
				m._bohren(SD_POS + Vector3(-0.02, -0.02, 0))
				m._bohren(SD_POS + Vector3(0.02, 0.02, 0))
				m.bauteil_typ = "steckdose"
				m._bauteil_setzen(SD_POS),
			"fertig": func() -> bool: return _id("steckdose") != "",
		},
		{
			"titel": "8. Leitung NYM-J 3x2,5 verlegen",
			"text": "Rechts [b]Leitung verlegen[/b] und den Typ [b]NYM-J 3x2,5[/b] wählen (Steckdosen: 2,5 mm²).\nDann den [b]LS[/b] anklicken, nach oben in den [b]Kabelkanal[/b], im Kanal nach rechts, senkrecht runter und die [b]Steckdose[/b] anklicken. Jeder Klick dazwischen ist ein Eckpunkt.",
			"werkzeug": "Leitung verlegen (NYM-J 3x2,5)",
			"vorbereiten": func() -> void:
				m.leitung_typ = "NYM-J 3x2,5"
				m._werkzeug_waehlen(W.LEITUNG),
			"vormachen": func() -> void:
				var ls := _id("ls")
				var lp: Vector3 = _c().geraete[ls].pos
				var sp: Vector3 = _c().geraete[_id("steckdose")].pos
				m.leitung_typ = "NYM-J 3x2,5"
				m._leitung_anlegen(ls, _id("steckdose"), [lp, Vector3(lp.x, Musterbrett.KANAL_Y, 0), Vector3(sp.x, Musterbrett.KANAL_Y, 0), sp]),
			"fertig": func() -> bool: return _leitung() != null,
		},
		{
			"titel": "9. Leitung mit Iso-Schellen befestigen",
			"text": "Außerhalb von Kanal und Verteiler muss die Leitung befestigt werden: höchstens [b]25 cm[/b] zwischen zwei Schellen und höchstens [b]10 cm vor dem Gerät[/b]. Unter jede Schelle kommt eine Bohrung.\nBohren, dann mit der [b]Iso-Schelle[/b] auf die Leitung über der Bohrung klicken. Unten steht, was noch fehlt.",
			"werkzeug": "Bohrmaschine, dann Iso-Schelle",
			"vorbereiten": func() -> void: m._werkzeug_waehlen(W.SCHELLE),
			"vormachen": func() -> void:
				var l: Variant = _leitung()
				if l != null:
					Musterbrett.schellen_setzen(m, l)
					m._leitung_zeichnen(l),
			"fertig": func() -> bool:
				var l: Variant = _leitung()
				return l != null and m._befestigung_text(l).begins_with("Leitung fertig"),
		},
		{
			"titel": "10. Abmanteln",
			"text": "Jetzt erst darf der Mantel runter. [b]Abmantelwerkzeug[/b] nehmen und die [b]Steckdose[/b] anklicken. In der 3D-Ansicht den [b]grauen Mantel[/b] anklicken. Danach den [b]Verteiler[/b] anklicken und dort genauso abmanteln.",
			"werkzeug": "Abmantelwerkzeug",
			"vorbereiten": func() -> void: m._werkzeug_waehlen(W.ABMANTELN),
			"vormachen": func() -> void:
				var l: Variant = _leitung()
				if l == null: return
				m._nahansicht_oeffnen(_id("steckdose"), NM.ABMANTELN)
				for e in ["start", "ende"]:
					if not l.abgemantelt[e]: m.nahansicht.abmanteln(l, e),
			"fertig": func() -> bool:
				var l: Variant = _leitung()
				return l != null and l.abgemantelt.start and l.abgemantelt.ende,
		},
		{
			"titel": "11. Adern abisolieren",
			"text": "Mit der [b]Abisolierzange[/b] (Länge [b]10 mm[/b]) jede Ader einzeln anklicken, an der Steckdose und im Verteiler. Richtig sind 8 bis 12 mm: zu kurz hat keinen Kontakt, zu lang schaut blankes Kupfer heraus.",
			"werkzeug": "Abisolierzange (10 mm)",
			"vorbereiten": func() -> void:
				m.abisolier_mm = 10.0
				m._werkzeug_waehlen(W.ABISOLIEREN),
			"vormachen": func() -> void:
				var l: Variant = _leitung()
				if l == null: return
				m.abisolier_mm = 10.0
				m._nahansicht_oeffnen(_id("steckdose"), NM.ABISOLIEREN)
				for i in l.adern.size():
					for f in ["von", "nach"]:
						m.nahansicht.abisolieren(l, i, f),
			"fertig": func() -> bool:
				var l: Variant = _leitung()
				if l == null: return false
				for a in l.adern:
					for f in ["von", "nach"]:
						var mm: float = a.get("abisoliert_" + f, 0.0)
						if mm < Circuit.ABISOLIERLAENGE.x or mm > Circuit.ABISOLIERLAENGE.y: return false
				return true,
		},
		{
			"titel": "12. Im Verteiler anklemmen",
			"text": "[b]Schraubendreher[/b], Verteiler anklicken, [b]Anklemmen[/b]. Jeweils erst die Ader, dann die Klemme anklicken:\n• [b]braun[/b] → LS [b]out[/b]\n• [b]blau[/b] → eine freie [b]N-Klemme[/b]\n• [b]grün-gelb[/b] → eine freie [b]PE-Klemme[/b]",
			"werkzeug": "Schraubendreher → ③ Anklemmen",
			"vorbereiten": func() -> void:
				m._werkzeug_waehlen(W.ANKLEMMEN)
				_verteiler_ansicht(),
			"vormachen": func() -> void:
				var l: Variant = _leitung()
				if l == null: return
				var n := _nah(NM.ANKLEMMEN)
				var f := _feld(l, _id("ls"))
				n._anklemmen(l, 0, f, _id("ls") + ":out")
				n._anklemmen(l, 1, f, _freie_klemme("x_n"))
				n._anklemmen(l, 2, f, _freie_klemme("x_pe")),
			"fertig": func() -> bool:
				var l: Variant = _leitung()
				if l == null: return false
				var f := _feld(l, _id("ls"))
				return l.adern[0][f] == _id("ls") + ":out" and String(l.adern[1][f]).begins_with("x_n:") and String(l.adern[2][f]).begins_with("x_pe:"),
		},
		{
			"titel": "13. Steckdose anklemmen",
			"text": "Steckdose mit dem [b]Schraubendreher[/b] anklicken:\n• [b]braun[/b] → [b]L[/b]\n• [b]blau[/b] → [b]N[/b]\n• [b]grün-gelb[/b] → [b]PE[/b] (Schutzkontakt)",
			"werkzeug": "Schraubendreher → ③ Anklemmen",
			"vorbereiten": func() -> void:
				if m.nahansicht: m.nahansicht.hide()
				_brett_ansicht(),
			"vormachen": func() -> void:
				var l: Variant = _leitung()
				if l == null: return
				var sd := _id("steckdose")
				m._nahansicht_oeffnen(sd, NM.ANKLEMMEN)
				var f := _feld(l, sd)
				for k in [[0, "L"], [1, "N"], [2, "PE"]]:
					m.nahansicht._anklemmen(l, k[0], f, sd + ":" + k[1]),
			"fertig": func() -> bool:
				var l: Variant = _leitung()
				if l == null: return false
				var sd := _id("steckdose")
				var f := _feld(l, sd)
				return l.adern[0][f] == sd + ":L" and l.adern[1][f] == sd + ":N" and l.adern[2][f] == sd + ":PE",
		},
		{
			"titel": "14. Prüfen",
			"text": "Oben rechts auf [b]✔ Prüfen[/b] klicken (oder Taste [b]P[/b]). Wenn alles stimmt, hat die Steckdose Spannung und es gibt keine Fehler. Fehler werden mit Erklärung aufgelistet.",
			"vorbereiten": func() -> void:
				if m.nahansicht: m.nahansicht.hide(),
			"vormachen": func() -> void: m._pruefen(),
			"fertig": func() -> bool:
				var r: Dictionary = m.letztes_ergebnis
				return not r.is_empty() and r.fehler.is_empty() and r.ausgeloest.is_empty() and _id("steckdose") in r.get("steckdosen_an", []),
		},
	]

func _freie_klemme(gid: String) -> String:
	for k in Circuit.TYPEN[_c().geraete[gid].typ]:
		var kid := "%s:%s" % [gid, k]
		var belegt := false
		for l in _c().leitungen:
			for a in l.adern:
				if a.get("von", "") == kid or a.get("nach", "") == kid:
					belegt = true
		if not belegt:
			return kid
	return gid + ":6"
