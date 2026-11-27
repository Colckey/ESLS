extends Control
## Lehrermodus: Schuelerdatei (.esim) oeffnen, optional Musterloesung dazu,
## automatisch bewerten (Punkte, Note, Fehlerliste, Funktionstabelle).

var schueler: Circuit
var schueler_meta := {}
var schueler_unveraendert := true
var schueler_pfad := ""
var muster: Circuit
var muster_pfad := ""

var _ausgabe: RichTextLabel
var _aufgabe_wahl: OptionButton
var _dialog: FileDialog
var _lade_muster := false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	theme = Stil.theme()
	var bg := ColorRect.new()
	bg.color = Stil.SEITE
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 16; v.offset_top = 16; v.offset_right = -16; v.offset_bottom = -16
	add_child(v)
	var titel := Label.new()
	titel.text = "⚡ ESLS Lehrermodus: Bewertung"
	titel.add_theme_font_size_override("font_size", 24)
	titel.add_theme_color_override("font_color", Stil.KOPF)
	v.add_child(titel)
	var leiste := HBoxContainer.new()
	leiste.add_theme_constant_override("separation", 8)
	v.add_child(leiste)
	for b in [["Schülerdatei öffnen", _schueler_oeffnen], ["Eigene Musterlösung (optional)", _muster_oeffnen],
			["Bewerten", _bewerten], ["Beispielbrett ansehen", _beispiel], ["Zurück zur Montage", _zurueck]]:
		var k := Button.new()
		k.text = b[0]
		k.pressed.connect(b[1])
		if b[0] == "Bewerten": k.theme_type_variation = "AkzentButton"
		leiste.add_child(k)
	var lbl := Label.new()
	lbl.text = "  Auftrag:"
	leiste.add_child(lbl)
	_aufgabe_wahl = OptionButton.new()
	_aufgabe_wahl.add_item("aus der Schülerdatei")
	for a in Aufgaben.LISTE:
		_aufgabe_wahl.add_item(a.titel)
	_aufgabe_wahl.item_selected.connect(func(_i: int) -> void: _bewerten())
	leiste.add_child(_aufgabe_wahl)
	_ausgabe = RichTextLabel.new()
	_ausgabe.bbcode_enabled = true
	_ausgabe.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ausgabe.selection_enabled = true
	v.add_child(_ausgabe)
	_ausgabe.text = "Schülerdatei (.esim) öffnen. Bewertet wird automatisch gegen den Auftrag, den der Schüler bearbeitet hat (eingebaute Musterlösung). Eine eigene Musterlösung ist optional und ersetzt den Funktionsvergleich."
	var karte := PanelContainer.new()
	karte.theme_type_variation = "Karte"
	karte.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.remove_child(_ausgabe)
	karte.add_child(_ausgabe)
	v.add_child(karte)
	_dialog = FileDialog.new()
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.filters = PackedStringArray(["*.esim ; ESLS-Projekt"])
	_dialog.use_native_dialog = true
	_dialog.file_selected.connect(_datei_gewaehlt)
	add_child(_dialog)

func _schueler_oeffnen() -> void:
	_lade_muster = false
	_dialog.popup_centered(Vector2i(800, 500))

func _muster_oeffnen() -> void:
	_lade_muster = true
	_dialog.popup_centered(Vector2i(800, 500))

func _datei_gewaehlt(pfad: String) -> void:
	var d := Projektdatei.laden(pfad)
	if d.has("fehler"):
		_ausgabe.text = "[color=tomato]%s[/color]" % d.fehler
		return
	if _lade_muster:
		muster = d.circuit
		muster_pfad = pfad
	else:
		schueler = d.circuit
		schueler_meta = d.meta
		schueler_unveraendert = d.unveraendert
		schueler_pfad = pfad
	_bewerten()

func _bewerten() -> void:
	if schueler == null:
		_ausgabe.text = "Bitte zuerst eine Schülerdatei öffnen."
		return
	var aufgabe: String = schueler_meta.get("aufgabe", "")
	if _aufgabe_wahl.selected > 0:
		aufgabe = Aufgaben.LISTE[_aufgabe_wahl.selected - 1].id
	_ausgabe.text = bericht(schueler, schueler_meta, schueler_unveraendert, muster, aufgabe)

## Bericht als BBCode-Text (auch fuer Tests nutzbar)
static func bericht(s: Circuit, meta: Dictionary, unveraendert: bool, m: Circuit, aufgabe := "") -> String:
	var b := Bewertung.bewerten(s, m, aufgabe)
	var a := Aufgaben.finden(aufgabe)
	var t := "[b]Schüler/in:[/b] %s    [b]Gespeichert:[/b] %s    [b]Auftrag:[/b] %s\n" % [meta.get("schueler", "(kein Name)"),
		meta.get("erstellt", "?"), a.get("titel", "kein Auftrag")]
	if not unveraendert:
		t += "[color=#d35400][b]Achtung: Die Datei wurde außerhalb von ESLS verändert![/b][/color]\n"
	t += "\n[font_size=22][b]Ergebnis: %d von 100 Punkten, Note %d[/b][/font_size]\n" % [b.punkte, b.note]
	if b.funktion_ok == null:
		t += "Funktion: kein Auftrag und keine Musterlösung, daher nicht verglichen.\n"
	elif b.funktion_ok:
		t += "[color=#1e8a3c]✔ Funktion entspricht %s (alle Schalterstellungen).[/color]\n" % ("der Musterlösung" if m != null else "dem Auftrag")
	else:
		t += "[color=#c62828]✘ Funktion weicht ab (-%d Punkte).[/color]\n" % Bewertung.ABZUG_FUNKTION
	if not b.anforderungen.is_empty():
		t += "\n[b]Auftrag nicht erfüllt (%d, je -%d):[/b]\n" % [b.anforderungen.size(), Bewertung.ABZUG_ANFORDERUNG]
		for f in b.anforderungen:
			t += "  • %s\n" % f
	t += "\n[b]Fehler (%d, je -%d):[/b]\n" % [b.fehler.size(), Bewertung.ABZUG_FEHLER]
	for f in b.fehler:
		t += "  • %s\n" % f
	t += "\n[b]Warnungen (%d, je -%d):[/b]\n" % [b.warnungen.size(), Bewertung.ABZUG_WARNUNG]
	for w in b.warnungen:
		t += "  • %s\n" % w
	var tab: Dictionary = b.tabelle
	t += "\n[b]Funktionstabelle[/b] (%s)\n" % ", ".join(tab.schalter)
	for z in tab.zeilen:
		var st := []
		for x in z.stellung:
			st.append(str(x))
		t += "  %s  ->  leuchtet: %s%s\n" % [" ".join(st) if not st.is_empty() else "-",
			", ".join(z.lampen) if not z.lampen.is_empty() else "nichts",
			("   [color=#d35400]ausgelöst: %s[/color]" % ", ".join(z.ausgeloest)) if not z.ausgeloest.is_empty() else ""]
	return t

func _beispiel() -> void:
	Musterbrett.beim_start = true
	get_tree().change_scene_to_file("res://montage.tscn")

func _zurueck() -> void:
	get_tree().change_scene_to_file("res://montage.tscn")

## Beispielbericht (fuer Screenshots/Vorfuehrung): Wechselschaltung mit zwei typischen Fehlern
func demo_bericht() -> void:
	schueler = Aufgaben.muster("wechselschaltung")
	schueler.leitungen[5].adern[2].nach = ""          # Schutzleiter an der Leuchte vergessen
	schueler.leitungen[5].adern[0].abisoliert_nach = 15.0   # zu lang abisoliert
	schueler_meta = {"schueler": "Max Mustermann", "erstellt": "2026-11-25T08:15:00", "aufgabe": "wechselschaltung"}
	schueler_unveraendert = true
	_bewerten()
