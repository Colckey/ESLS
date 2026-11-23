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
	# Speichern / Laden
	var pfad := "user://montage_test.esim"
	_check("Speichern", Projektdatei.speichern(m.circuit, pfad) == OK)
	var d: Dictionary = Projektdatei.laden(pfad)
	_check("Laden: gleiche Bauteile, Leitungen, Bohrungen", d.has("circuit") and d.circuit.geraete.size() == 3 \
		and d.circuit.leitungen.size() == 1 and d.circuit.bohrungen.size() == m.circuit.bohrungen.size())
	# Seitenschneider
	m._leitung_schneiden(Vector3(0.2, 0.2, 0))
	_check("Seitenschneider entfernt Leitung", m.circuit.leitungen.is_empty())
	ausgabe += "\n%s" % ("ALLE TESTS OK" if fehlgeschlagen == 0 else "%d TEST(S) FEHLGESCHLAGEN" % fehlgeschlagen)
	print(ausgabe)

func _check(name: String, ok: bool) -> void:
	if not ok: fehlgeschlagen += 1
	ausgabe += "%s  %s\n" % ["OK  " if ok else "FAIL", name]
