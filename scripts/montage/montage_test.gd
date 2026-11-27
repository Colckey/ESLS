extends Node
## Rauchtest der Montageszene ohne Maus: Bohren, Bauteile setzen, Leitung verlegen,
## Schellen setzen, Speichern/Laden. Szene montage_test.tscn mit F6 starten.

var ausgabe := ""
var fehlgeschlagen := 0

func _ready() -> void:
	var m: Node3D = load("res://montage.tscn").instantiate()
	add_child(m)
	# Ohne Bohrung darf kein Bauteil gesetzt werden
	m.bauteil_typ = "abzweigdose"
	m._bauteil_setzen(Vector3(0.0, 0.2, 0))
	_check("Bauteil ohne Bohrung wird abgelehnt", not m.circuit.geraete.has("dose1"))
	m._bohren(Vector3(-0.02, 0.18, 0)); m._bohren(Vector3(0.02, 0.22, 0))
	m._bauteil_setzen(Vector3(0.0, 0.2, 0))
	_check("Abzweigdose mit 2 Bohrungen gesetzt", m.circuit.geraete.has("dose1"))
	m.bauteil_typ = "lampe"
	m._bohren(Vector3(0.38, 0.18, 0)); m._bohren(Vector3(0.42, 0.22, 0))
	m._bauteil_setzen(Vector3(0.4, 0.2, 0))
	_check("Lampe gesetzt", m.circuit.geraete.has("lampe1"))
	# Leitung dose1 -> lampe1
	m._werkzeug_waehlen(3)  # Werkzeug.LEITUNG
	m._leitung_klick(Vector3(0.0, 0.2, 0))
	m._leitung_klick(Vector3(0.4, 0.2, 0))
	_check("Leitung W1 angelegt", m.circuit.leitungen.size() == 1 and m.circuit.leitungen[0].id == "W1")
	var l: Dictionary = m.circuit.leitungen[0]
	_check("Leitung hat 3 Adern (NYM-J 3x1,5)", l.adern.size() == 3)
	# Schelle ohne Bohrung abgelehnt, mit Bohrung gesetzt
	m._schelle_setzen(Vector3(0.1, 0.2, 0))
	_check("Schelle ohne Bohrung abgelehnt", l.schellen.is_empty())
	for x in [0.06, 0.2, 0.34]:
		m._bohren(Vector3(x, 0.2, 0))
		m._schelle_setzen(Vector3(x, 0.2, 0))
	_check("3 Schellen gesetzt", l.schellen.size() == 3)
	var r: Dictionary = m.circuit.pruefen()
	var schellenfehler := false
	for f in r.fehler:
		if "Schelle" in f: schellenfehler = true
	_check("Schellenabstand in Ordnung", not schellenfehler)
	# Abmanteln / Abisolieren
	m._abisolieren(Vector3(0.0, 0.2, 0))
	_check("Abisolieren vor Abmanteln abgelehnt", l.adern[0].abisoliert_von == 0.0)
	m._abmanteln(Vector3(0.0, 0.2, 0))
	_check("Start abgemantelt", l.abgemantelt.start and not l.abgemantelt.ende)
	m.abisolier_mm = 10.0
	m._abisolieren(Vector3(0.0, 0.2, 0))
	_check("Adern am Start 10 mm abisoliert", l.adern[2].abisoliert_von == 10.0 and l.adern[2].abisoliert_nach == 0.0)
	m._abmanteln(Vector3(0.4, 0.2, 0))
	m.abisolier_mm = 20.0
	m._abisolieren(Vector3(0.4, 0.2, 0))
	var r2: Dictionary = m.circuit.pruefen()
	_check("Zu lang abisoliert wird erst beim Anklemmen geprüft (noch keine Klemme)", r2.fehler.filter(func(f): return "zu lang" in f).is_empty())
	# Speichern / Laden
	var pfad := "user://montage_test.esim"
	_check("Speichern", Projektdatei.speichern(m.circuit, pfad) == OK)
	var d: Dictionary = Projektdatei.laden(pfad)
	_check("Laden: gleiche Bauteile, Leitungen, Bohrungen", d.has("circuit") and d.circuit.geraete.size() == 5 \
		and d.circuit.leitungen.size() == 1 and d.circuit.bohrungen.size() == m.circuit.bohrungen.size())
	# Seitenschneider
	m._leitung_schneiden(Vector3(0.2, 0.2, 0))
	_check("Seitenschneider entfernt Leitung", m.circuit.leitungen.is_empty())
	m.queue_free()
	_ausschaltung_komplett()
	_musterbrett_fehlerfrei()
	ausgabe += "\n%s" % ("ALLE TESTS OK" if fehlgeschlagen == 0 else "%d TEST(S) FEHLGESCHLAGEN" % fehlgeschlagen)
	print(ausgabe)

func _check(name: String, ok: bool) -> void:
	if not ok: fehlgeschlagen += 1
	ausgabe += "%s  %s\n" % ["OK  " if ok else "FAIL", name]

## Komplette Ausschaltung ueber die echten Werkzeug-Funktionen und die Nahansicht verdrahten
func _ausschaltung_komplett() -> void:
	var m: Node3D = load("res://montage.tscn").instantiate()
	add_child(m)
	var plaetze := {"fi": Vector3(-0.50, 0.17, 0), "ls": Vector3(-0.45, 0.17, 0), "abzweigdose": Vector3(0.0, 0.2, 0),
		"ausschalter": Vector3(0.0, -0.2, 0), "lampe": Vector3(0.4, 0.2, 0)}
	for typ in plaetze:
		var p: Vector3 = plaetze[typ]
		m._bohren(p + Vector3(-0.005, -0.01, 0)); m._bohren(p + Vector3(0.005, 0.01, 0))
		m.bauteil_typ = typ
		m._bauteil_setzen(p)
	_check("E2E: alle 5 Bauteile gesetzt", m.circuit.geraete.size() == 8)
	m._werkzeug_waehlen(3)
	for paar in [["ls", "abzweigdose"], ["abzweigdose", "ausschalter"], ["abzweigdose", "lampe"]]:
		m._leitung_klick(plaetze[paar[0]])
		m._leitung_klick(plaetze[paar[1]])
	_check("E2E: 3 Leitungen verlegt", m.circuit.leitungen.size() == 3)
	m.abisolier_mm = 10.0
	# Ohne Iso-Schelle vor dem Geraet laesst sich nicht abmanteln
	m._abmanteln(plaetze["lampe"])
	_check("E2E: Abmanteln ohne Schelle abgelehnt", not m.circuit.leitungen[2].abgemantelt.ende)
	for l in m.circuit.leitungen:
		Musterbrett.schellen_setzen(m, l)
	var befestigt := true
	for l in m.circuit.leitungen:
		if m._befestigung_text(l) != "Leitung fertig befestigt, jetzt abmanteln.":
			befestigt = false
	_check("E2E: alle Leitungen fertig befestigt", befestigt)
	for typ in plaetze:
		for i in 3:
			m._abmanteln(plaetze[typ])
			m._abisolieren(plaetze[typ])
	var alle_ok := true
	for l in m.circuit.leitungen:
		if not (l.abgemantelt.start and l.abgemantelt.ende and l.adern[0].abisoliert_von == 10.0 and l.adern[0].abisoliert_nach == 10.0):
			alle_ok = false
	_check("E2E: alle Enden abgemantelt und abisoliert", alle_ok)
	# Verteiler: Bruecken
	m._nahansicht_oeffnen("fi1")
	var n: Nahansicht = m.nahansicht
	for b in [["bn", "netz:L", "fi1:L_in"], ["bu", "netz:N", "fi1:N_in"], ["bn", "fi1:L_out", "ls1:in"]]:
		n.bruecken_farbe = b[0]
		n._bruecke_legen(b[1], b[2])
	var r0: Dictionary = m.circuit.pruefen()
	var ohne_huelse := false
	for f in r0.fehler:
		if "Aderendhülse" in f: ohne_huelse = true
	_check("E2E: Brücke ohne Aderendhülse wird bemängelt", ohne_huelse)
	Musterbrett.alle_crimpen(n)
	var w1: Dictionary = m.circuit.leitungen[0]   # ls1 -> dose1
	var w2: Dictionary = m.circuit.leitungen[1]   # dose1 -> s1
	var w3: Dictionary = m.circuit.leitungen[2]   # dose1 -> lampe1
	n._anklemmen(w1, 0, "von", "ls1:out")      # bn
	n._anklemmen(w1, 1, "von", "fi1:N_out")    # bu
	n._anklemmen(w1, 2, "von", "netz:PE")      # gnye
	# Abzweigdose: 4 Verbindungsklemmen (L, N, PE, Schaltdraht)
	m._nahansicht_oeffnen("dose1")
	for i in 4:
		n._klemme_einsetzen()
	n._anklemmen(w1, 0, "nach", "dose1_k1:a")
	n._anklemmen(w1, 1, "nach", "dose1_k2:a")
	n._anklemmen(w1, 2, "nach", "dose1_k3:a")
	n._anklemmen(w2, 0, "von", "dose1_k1:b")   # L zum Schalter
	n._anklemmen(w2, 1, "von", "dose1_k4:a")   # Schaltdraht zurueck
	n._anklemmen(w3, 0, "von", "dose1_k4:b")
	n._anklemmen(w3, 1, "von", "dose1_k2:b")
	n._anklemmen(w3, 2, "von", "dose1_k3:b")
	m._nahansicht_oeffnen("s1")
	n._anklemmen(w2, 0, "nach", "s1:L")
	n._anklemmen(w2, 1, "nach", "s1:1")
	m._nahansicht_oeffnen("lampe1")
	n._anklemmen(w3, 0, "nach", "lampe1:L")
	n._anklemmen(w3, 1, "nach", "lampe1:N")
	n._anklemmen(w3, 2, "nach", "lampe1:PE")
	m.circuit.zustand["s1"].stellung = 1
	var r: Dictionary = m.circuit.pruefen()
	_check("E2E: Lampe leuchtet, nichts ausgelöst  %s" % [r.fehler], "lampe1" in r.lampen_an and r.ausgeloest.is_empty())
	# Fehler einbauen: blauer Neutralleiter der Zuleitung in der Dose auf die L-Klemme -> Kurzschluss
	n._anklemmen(w1, 1, "nach", "dose1_k1:c")
	r = m.circuit.pruefen()
	_check("E2E: N der Zuleitung auf L-Klemme -> LS löst aus", "ls1" in r.ausgeloest)
	m._pruefen()   # Anzeige darf nicht abstuerzen
	m.queue_free()
	_werkzeuge_3d()
	_tutorial_vormachen()

## Komplettes Uebungsbrett mit allen Werkzeugen: keine Fehler, keine Warnungen, 100 Punkte
func _musterbrett_fehlerfrei() -> void:
	var m: Node3D = load("res://montage.tscn").instantiate()
	add_child(m)
	Musterbrett.aufbauen(m)
	var r: Dictionary = m.circuit.pruefen()
	_check("Musterbrett: keine Fehler %s" % [r.fehler], r.fehler.is_empty() and r.ausgeloest.is_empty())
	_check("Musterbrett: keine Warnungen %s" % [r.warnungen], r.warnungen.is_empty())
	_check("Musterbrett: Leuchte und beide Steckdosen haben Spannung", "lampe1" in r.lampen_an and r.steckdosen_an.size() == 2)
	var b := Bewertung.bewerten(m.circuit, null, "uebungsbrett")
	_check("Musterbrett: 100 Punkte, Funktion wie Auftrag %s" % [b.anforderungen], b.punkte == 100 and b.funktion_ok == true)
	m._pruefen()
	var alle := true
	for s in m.schritte():
		if not s[1]: alle = false
	_check("Musterbrett: alle Arbeitsschritte abgehakt", alle)
	# Kreuzschaltung: jede Betaetigung schaltet die Leuchte um
	var an := []
	for sch in ["ws1", "x1", "ws2"]:
		m.circuit.zustand[sch].stellung = 1 - int(m.circuit.zustand[sch].stellung)
		an.append("lampe1" in m.circuit.pruefen().lampen_an)
	_check("Musterbrett: jeder Schalter schaltet um %s" % [an], an == [false, true, false])
	m.queue_free()

## 3D-Anschlussansicht, Zollstock, Wasserwaage, Raster und Bauplan
func _werkzeuge_3d() -> void:
	var m: Node3D = load("res://montage.tscn").instantiate()
	add_child(m)
	m.start_ausblenden()
	for p in [Vector3(-0.2, 0.0, 0), Vector3(0.2, 0.0, 0)]:
		m._bohren(p + Vector3(-0.02, -0.02, 0)); m._bohren(p + Vector3(0.02, 0.02, 0))
	m.bauteil_typ = "abzweigdose"
	m._bauteil_setzen(Vector3(-0.2, 0.0, 0))
	m.bauteil_typ = "steckdose"
	m._bauteil_setzen(Vector3(0.2, 0.0, 0))
	m._werkzeug_waehlen(3)
	m._leitung_klick(Vector3(-0.2, 0.0, 0))
	m._leitung_klick(Vector3(0.2, 0.0, 0))
	var l: Dictionary = m.circuit.leitungen[0]
	m._nahansicht_oeffnen("sd1", Nahansicht.Modus.ABMANTELN)
	var n: Nahansicht = m.nahansicht
	_check("3D: Anschlussansicht offen im Modus Abmanteln", n.visible and n.modus == Nahansicht.Modus.ABMANTELN and n.ansicht3d != null)
	_check("3D: Abmanteln ohne Schelle abgelehnt", not n.abmanteln(l, "ende") and not l.abgemantelt.ende)
	n.abisolieren(l, 0, "nach")
	_check("3D: Abisolieren vor Abmanteln abgelehnt", l.adern[0].abisoliert_nach == 0.0)
	Musterbrett.schellen_setzen(m, l)
	_check("3D: Abmanteln nach Schelle möglich", n.abmanteln(l, "ende") and l.abgemantelt.ende)
	m.abisolier_mm = 10.0
	n.abisolieren(l, 1, "nach")
	_check("3D: nur die angeklickte Ader abisoliert", l.adern[1].abisoliert_nach == 10.0 and l.adern[0].abisoliert_nach == 0.0)
	n._3d_klick("mantel", {"leitung": l, "ende": "ende"})   # darf nicht abstuerzen
	n.modus_setzen(Nahansicht.Modus.ANKLEMMEN)
	n.hide()
	# Rand-Laufmeter: Leitung tritt am Rand der Steckdose (4 cm vor der Mitte) ins Geraet ein
	_check("Brett: Mantel endet am Geräterand (%.3f m)" % m._rand_lauf(l, "ende"), absf(m._rand_lauf(l, "ende") - 0.04) < 0.002)
	# Zollstock
	m._werkzeug_waehlen(m.Werkzeug.ZOLLSTOCK)
	m._klick(Vector3(-0.2, 0.0, 0))
	m._klick(Vector3(0.2, 0.0, 0))
	_check("Zollstock misst 40 cm", "40,0 cm" in m.status.text)
	# Wasserwaage
	m._werkzeug_waehlen(m.Werkzeug.WASSERWAAGE)
	m._klick(Vector3(-0.2, 0.0, 0))
	m._klick(Vector3(0.2, 0.0, 0))
	_check("Wasserwaage: beide Dosen waagerecht", "genau waagerecht" in m.status.text)
	_check("Wasserwaage: 1 cm Versatz erkannt", "1,0 cm" in m._wasserwaage_zeichnen(Vector3(0, 0, 0), Vector3(0.3, 0.01, 0)))
	# Raster und Bauplan
	m.raster_umschalten()
	_check("Raster einschaltbar", m.raster_an and m.raster_knoten.visible and m.raster_knoten.get_child_count() > 3)
	m.aufgabe_starten("uebungsbrett")
	m.bauplan_umschalten()
	_check("Bauplan zeigt die Umrisse", m.bauplan_an and m.bauplan_knoten.get_child_count() > 10)
	m.queue_free()

## Tutorial: jeder Schritt laesst sich vormachen und ist danach erledigt; am Ende hat die Steckdose Spannung
func _tutorial_vormachen() -> void:
	var m: Node3D = load("res://montage.tscn").instantiate()
	add_child(m)
	m.tutorial_starten()
	var t: Tutorial = m.tutorial
	var alle := true
	var fehlend := []
	for i in t.anzahl():
		t.schritt_zeigen(i)
		if t.erledigt():
			alle = false
			fehlend.append("%d schon vorher erledigt" % (i + 1))
		t.vormachen_jetzt()
		if not t.erledigt():
			alle = false
			fehlend.append(i + 1)
	_check("Tutorial: alle %d Schritte vormachbar %s" % [t.anzahl(), fehlend], alle)
	var r: Dictionary = m.circuit.pruefen()
	_check("Tutorial: Steckdose hat Spannung, keine Fehler %s %s" % [r.fehler, r.warnungen], r.fehler.is_empty() and r.steckdosen_an.size() == 1)
	var schiene := false
	for l in m.circuit.leitungen:
		if Circuit.LEITUNGEN[l.typ].get("schiene", false): schiene = true
	_check("Tutorial: Phasenschiene gesteckt", schiene)
	m.queue_free()
