extends Node
## Selbsttest der Schaltungslogik. Szene sim_test.tscn oeffnen und F6 druecken.
## Ergebnis erscheint im Fenster und in der Ausgabe.

var ausgabe := ""
var fehlgeschlagen := 0

func _ready() -> void:
	var c: Circuit
	var r: Dictionary

	c = aufbau(); r = _pruefe(c, 1)
	_check("Ausschaltung korrekt, Schalter EIN -> Lampe leuchtet", r, r.ok and "lampe1" in r.lampen_an)

	c = aufbau(); r = _pruefe(c, 0)
	_check("Ausschaltung korrekt, Schalter AUS -> Lampe aus", r, r.ok and r.lampen_an.is_empty())

	c = aufbau(); c.leitungen[2].adern[1].nach = "lampe1:L"; r = _pruefe(c, 1)
	_check("L und N an der Lampe gebrueckt -> LS loest aus", r, "ls1" in r.ausgeloest)

	c = aufbau(); c.leitungen[2].adern[2].nach = ""; r = _pruefe(c, 1)
	_check("PE an der Lampe vergessen -> Fehler", r, not r.ok and r.ausgeloest.is_empty())

	c = aufbau(); c.leitungen[0].adern[1].von = "netz:N"; r = _pruefe(c, 1)
	_check("N der Lampe vor dem FI angeklemmt -> FI loest aus", r, "fi1" in r.ausgeloest)

	c = aufbau(); c.leitungen[1].adern[0].abisoliert_von = 0.0; r = _pruefe(c, 1)
	_check("Nicht abisoliert -> Fehler", r, not r.ok)

	c = aufbau(); c.geraete["ls1"].param.nennstrom = 20; r = _pruefe(c, 1)
	_check("LS 20A an 1,5 mm2 -> Fehler", r, not r.ok)

	_speichern_laden()
	ausgabe += "\n%s" % ("ALLE TESTS OK" if fehlgeschlagen == 0 else "%d TEST(S) FEHLGESCHLAGEN" % fehlgeschlagen)
	print(ausgabe)
	var lbl := Label.new(); lbl.text = ausgabe; lbl.position = Vector2(10, 10); add_child(lbl)

func _pruefe(c: Circuit, schalter: int) -> Dictionary:
	c.zustand["s1"].stellung = schalter
	return c.pruefen()

func _check(name: String, r: Dictionary, ok: bool) -> void:
	if not ok: fehlgeschlagen += 1
	ausgabe += "%s  %s\n      -> ausgelöst: %s, Lampen an: %s, Fehler: %s\n" % [
		"OK  " if ok else "FAIL", name, r.ausgeloest, r.lampen_an, r.fehler]

## Referenzaufbau: Einspeisung -> FI -> LS B16 -> Klemme in Abzweigdose -> Ausschalter -> Lampe
func aufbau() -> Circuit:
	var c := Circuit.new()
	for g in [["netz", "einspeisung"], ["fi1", "fi"], ["ls1", "ls"], ["dose_L", "klemme"],
			["dose_N", "klemme"], ["dose_PE", "klemme"], ["dose_SR", "klemme"], ["s1", "ausschalter"], ["lampe1", "lampe"]]:
		c.geraet_hinzufuegen(g[0], g[1], Vector3.ZERO, {"nennstrom": 16} if g[1] == "ls" else {})
	# Verteilerverdrahtung (Einzeladern, vereinfacht als eine "Leitung")
	var s := [Vector3(0, 0, 0), Vector3(0.2, 0, 0)]
	c.leitung_hinzufuegen(_l("verteiler", "NYM-J 3x1,5", [
		["bn", "netz:L", "fi1:L_in"], ["bu", "fi1:N_out", "dose_N:a"], ["gnye", "netz:PE", "dose_PE:a"]], s))
	c.leitung_hinzufuegen(_l("w1", "NYM-J 3x1,5", [
		["bn", "fi1:L_out", "ls1:in"], ["bu", "netz:N", "fi1:N_in"], ["bk", "ls1:out", "dose_L:a"]], s))
	c.leitung_hinzufuegen(_l("w2_lampe", "NYM-J 3x1,5", [
		["bn", "dose_SR:b", "lampe1:L"], ["bu", "dose_N:b", "lampe1:N"], ["gnye", "dose_PE:b", "lampe1:PE"]], s))
	c.leitung_hinzufuegen(_l("w3_schalter", "NYM-J 3x1,5", [
		["bn", "dose_L:b", "s1:L"], ["bk", "s1:1", "dose_SR:a"]], s))
	return c

func _l(id: String, typ: String, adern: Array, schellen: Array) -> Dictionary:
	var a := []
	for x in adern:
		a.append({"farbe": x[0], "von": x[1], "nach": x[2], "abisoliert_von": 10.0, "abisoliert_nach": 10.0})
	return {"id": id, "typ": typ, "punkte": schellen, "schellen": schellen,
		"abgemantelt": {"start": true, "ende": true}, "adern": a}

func _speichern_laden() -> void:
	var pfad := "user://test.esim"
	var c := aufbau(); c.zustand["s1"].stellung = 1
	var err := Projektdatei.speichern(c, pfad, {"schueler": "Test"})
	var d := Projektdatei.laden(pfad)
	var ok: bool = err == OK and d.has("circuit") and d.unveraendert and "lampe1" in d.circuit.pruefen().lampen_an
	if not ok: fehlgeschlagen += 1
	ausgabe += "%s  Speichern und Laden (.esim) ergibt dieselbe Schaltung\n" % ("OK  " if ok else "FAIL")
