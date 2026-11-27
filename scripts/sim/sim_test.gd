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
	_check("Nicht abisoliert -> Fehler, kein Kontakt, Lampe aus", r, not r.ok and r.lampen_an.is_empty())

	c = aufbau(); c.leitungen[2].adern[0].farbe = "bk"; r = _pruefe(c, 1)
	_check("Schwarze Ader in NYM-J 3x1,5 -> Fehler", r, not r.ok)

	c = aufbau(); c.geraete["ls1"].param.nennstrom = 20; r = _pruefe(c, 1)
	_check("LS 20A an 1,5 mm2 -> Fehler (genau einmal gemeldet)", r, not r.ok and r.fehler.size() == 1)

	c = aufbau(); c.leitungen[2].adern[0].farbe = "bu"; r = _pruefe(c, 1)
	_check("Dieselbe Ader (blau) zweimal verwendet -> Fehler", r, r.fehler.any(func(f): return "mehrfach" in f))

	c = aufbau(); c.leitungen[2].adern.append(c.leitungen[2].adern[0].duplicate()); r = _pruefe(c, 1)
	_check("Mehr Adern als die Leitung hat -> Fehler", r, r.fehler.any(func(f): return "mehrfach" in f or "nur 3" in f))

	_befestigung()
	_schuetz_selbsthaltung()
	_kreuzschaltung()
	_aufgaben()
	_treppenlicht()
	_bewertung()
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
	c.leitung_hinzufuegen(_l("w1", "NYM-J 5x1,5", [
		["bn", "fi1:L_out", "ls1:in"], ["bu", "netz:N", "fi1:N_in"], ["bk", "ls1:out", "dose_L:a"]], s))
	c.leitung_hinzufuegen(_l("w2_lampe", "NYM-J 3x1,5", [
		["bn", "dose_SR:b", "lampe1:L"], ["bu", "dose_N:b", "lampe1:N"], ["gnye", "dose_PE:b", "lampe1:PE"]], s))
	c.leitung_hinzufuegen(_l("w3_schalter", "NYM-J 5x1,5", [
		["bn", "dose_L:b", "s1:L"], ["bk", "s1:1", "dose_SR:a"]], s))
	return c

func _l(id: String, typ: String, adern: Array, schellen: Array) -> Dictionary:
	var a := []
	for x in adern:
		a.append({"farbe": x[0], "von": x[1], "nach": x[2], "abisoliert_von": 10.0, "abisoliert_nach": 10.0,
			"huelse_von": true, "huelse_nach": true})
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

## Schuetzschaltung mit Selbsthaltung: S0 (Aus-Taster), S1 (Ein-Taster), K1, Lampe ueber Hauptkontakt 1-2
func _schuetz_selbsthaltung() -> void:
	var c := Circuit.new()
	for g in [["netz", "einspeisung"], ["fi1", "fi"], ["ls1", "ls"], ["s0", "taster_aus"], ["s1", "taster"],
			["k1", "schuetz"], ["lampe1", "lampe"]]:
		c.geraet_hinzufuegen(g[0], g[1], Vector3.ZERO, {"nennstrom": 16} if g[1] == "ls" else {})
	var s := [Vector3(0, 0, 0), Vector3(0.2, 0, 0)]
	c.leitung_hinzufuegen(_l("v", "H07V-K 1,5", [["bn", "netz:L", "fi1:L_in"]], s))
	c.leitung_hinzufuegen(_l("v2", "H07V-K 1,5", [["bu", "netz:N", "fi1:N_in"]], s))
	c.leitung_hinzufuegen(_l("v3", "H07V-K 1,5", [["bn", "fi1:L_out", "ls1:in"]], s))
	c.leitung_hinzufuegen(_l("st", "Steuerleitung 7x1,5", [
		["1", "ls1:out", "s0:L"], ["2", "s0:1", "s1:L"], ["3", "s0:1", "k1:13"],
		["4", "s1:1", "k1:A1"], ["5", "k1:14", "k1:A1"], ["6", "k1:A2", "fi1:N_out"]], s))
	c.leitung_hinzufuegen(_l("w", "NYM-J 5x1,5", [
		["bk", "ls1:out", "k1:1"], ["bn", "k1:2", "lampe1:L"], ["bu", "fi1:N_out", "lampe1:N"], ["gnye", "netz:PE", "lampe1:PE"]], s))
	var r := c.pruefen()
	_check("Schütz: ohne Tastendruck aus", r, r.lampen_an.is_empty() and r.ausgeloest.is_empty())
	c.zustand["s1"].stellung = 1
	r = c.pruefen()
	_check("Schütz: S1 gedrückt -> K1 zieht an, Lampe an", r, "k1" in r.spulen_an and "lampe1" in r.lampen_an)
	c.zustand["s1"].stellung = 0
	r = c.pruefen()
	_check("Schütz: S1 losgelassen -> Selbsthaltung, Lampe bleibt an", r, "lampe1" in r.lampen_an)
	c.zustand["s0"].stellung = 1
	r = c.pruefen()
	_check("Schütz: S0 gedrückt -> K1 fällt ab, Lampe aus", r, r.lampen_an.is_empty())
	c.zustand["s0"].stellung = 0
	r = c.pruefen()
	_check("Schütz: S0 losgelassen -> bleibt aus", r, r.lampen_an.is_empty())

## Kreuzschaltung: Wechsel - Kreuz - Wechsel, jede Betaetigung schaltet die Lampe um
func _kreuzschaltung() -> void:
	var c := Circuit.new()
	for g in [["netz", "einspeisung"], ["ls1", "ls"], ["w1", "wechselschalter"], ["x1", "kreuzschalter"],
			["w2", "wechselschalter"], ["lampe1", "lampe"]]:
		c.geraet_hinzufuegen(g[0], g[1], Vector3.ZERO, {"nennstrom": 16} if g[1] == "ls" else {})
	var s := [Vector3(0, 0, 0), Vector3(0.2, 0, 0)]
	c.leitung_hinzufuegen(_l("a", "NYM-J 5x1,5", [["bn", "netz:L", "ls1:in"], ["bk", "ls1:out", "w1:L"],
		["bu", "netz:N", "lampe1:N"], ["gnye", "netz:PE", "lampe1:PE"]], s))
	c.leitung_hinzufuegen(_l("b", "NYM-J 5x1,5", [["bk", "w1:1", "x1:1"], ["gy", "w1:2", "x1:2"],
		["bn", "x1:3", "w2:1"], ["bu", "x1:4", "w2:2"]], s))
	c.leitung_hinzufuegen(_l("c", "NYM-J 3x1,5", [["bn", "w2:L", "lampe1:L"]], s))
	var an := []
	for st in [[0, 0, 0], [1, 0, 0], [1, 1, 0], [1, 1, 1]]:
		c.zustand["w1"].stellung = st[0]
		c.zustand["x1"].stellung = st[1]
		c.zustand["w2"].stellung = st[2]
		an.append("lampe1" in c.pruefen().lampen_an)
	var r := c.pruefen()
	_check("Kreuzschaltung: jede Betätigung schaltet um %s" % [an], r, an[0] != an[1] and an[1] != an[2] and an[2] != an[3])

## Kabelkanal und Verteiler halten die Leitung, gemessen wird entlang der Leitung
func _befestigung() -> void:
	var k := Circuit.KABELKANAL
	var y := k.get_center().y
	var c := aufbau()
	# Leitung laeuft 60 cm im Kanal, faellt 20 cm senkrecht zum Geraet: 1 Schelle kurz vor dem Geraet reicht
	var l: Dictionary = c.leitungen[3]
	l.punkte = [Vector3(-0.3, y, 0), Vector3(0.3, y, 0), Vector3(0.3, k.position.y - 0.17, 0)]
	l.schellen = [Vector3(0.3, k.position.y - 0.09, 0)]
	var r := _pruefe(c, 1)
	_check("Leitung im Kabelkanal braucht dort keine Schellen", r, not r.fehler.any(func(f): return "Schelle" in f or "befestigt" in f))
	l.schellen = []
	r = _pruefe(c, 1)
	_check("Ohne Schelle am Fallrohr -> Fehler", r, r.fehler.any(func(f): return "Schelle" in f))
	# 2 Schellen ueber Eck: Luftlinie 21 cm, entlang der Leitung 30 cm -> zu weit
	l.punkte = [Vector3(0, 0, 0), Vector3(0.15, 0, 0), Vector3(0.15, 0.2, 0)]
	l.schellen = [Vector3(0.0, 0, 0), Vector3(0.15, 0.15, 0)]
	r = _pruefe(c, 1)
	_check("Schellenabstand wird entlang der Leitung gemessen", r, r.fehler.any(func(f): return "Schellenabstand" in f))

## Jede eingebaute Musterschaltung ist fehlerfrei und erreicht 100 Punkte
func _aufgaben() -> void:
	for a in Aufgaben.LISTE:
		var m := Aufgaben.muster(a.id)
		var b := Bewertung.bewerten(m, null, a.id)
		_check("Aufgabe %s: Muster fehlerfrei, 100 Punkte %s" % [a.titel, b.anforderungen], {"ausgeloest": [], "lampen_an": [], "fehler": b.fehler},
			b.punkte == 100 and b.funktion_ok == true and b.anforderungen.is_empty())
	# Wechselschaltung: jede Betaetigung schaltet um
	var w := Aufgaben.muster("wechselschaltung")
	var an := []
	for st in [[0, 0], [1, 0], [1, 1], [0, 1]]:
		w.zustand["ws1"].stellung = st[0]
		w.zustand["ws2"].stellung = st[1]
		an.append("lampe1" in w.pruefen().lampen_an)
	_check("Wechselschaltung: jede Betätigung schaltet um %s" % [an], {"ausgeloest": [], "lampen_an": [], "fehler": []},
		an[0] != an[1] and an[1] != an[2] and an[2] != an[3])
	# Falsch: korrespondierender Leiter auf L statt auf 2 -> Funktion weicht ab
	var falsch := Aufgaben.muster("wechselschaltung")
	falsch.leitungen[4].adern[1].nach = "ws2:L"
	var b := Bewertung.bewerten(falsch, null, "wechselschaltung")
	_check("Wechselschaltung falsch verdrahtet -> Funktion falsch", {"ausgeloest": [], "lampen_an": [], "fehler": b.fehler}, b.funktion_ok == false)
	# Steckdosenkreis ohne FI: N vor dem FI -> FI loest aus bzw. Anforderung verletzt
	var sd := Aufgaben.muster("steckdosenkreis")
	sd.geraet_hinzufuegen("ls2", "ls", Vector3.ZERO, {"nennstrom": 16})
	sd.leitungen[3].adern[0].von = "ls2:out"
	Aufgaben._l(sd, "v9", "H07V-K 1,5", [["bn", "netz:L", "ls2:in"]])
	sd.leitungen[3].adern[1].von = "netz:N"
	b = Bewertung.bewerten(sd, null, "steckdosenkreis")
	_check("Steckdosenkreis ohne FI -> Anforderung verletzt %s" % [b.anforderungen], {"ausgeloest": [], "lampen_an": [], "fehler": b.fehler},
		b.anforderungen.any(func(f): return "FI" in f) and b.punkte < 100)
	# Fehlende Bauteile
	b = Bewertung.bewerten(aufbau(), null, "kreuzschaltung")
	_check("Ausschaltung als Kreuzschaltung abgegeben -> fehlende Bauteile", {"ausgeloest": [], "lampen_an": [], "fehler": b.anforderungen},
		b.anforderungen.size() >= 2 and b.funktion_ok == false)

## Treppenlichtautomat: Taster einschalten, Licht bleibt bis die Zeit abgelaufen ist
func _treppenlicht() -> void:
	var c := Aufgaben.muster("treppenhaus")
	var r := c.pruefen()
	_check("Treppenlicht: aus ohne Tastendruck", r, r.lampen_an.is_empty())
	c.zustand["t2"].stellung = 1
	r = c.pruefen()
	_check("Treppenlicht: Taster 2 gedrückt -> Licht an", r, "lampe1" in r.lampen_an)
	c.zustand["t2"].stellung = 0
	r = c.pruefen()
	_check("Treppenlicht: losgelassen -> bleibt an (Nachlaufzeit)", r, "lampe1" in r.lampen_an)
	c.zustand["tlz1"].an = false   # Zeit abgelaufen
	r = c.pruefen()
	_check("Treppenlicht: Zeit abgelaufen -> aus", r, r.lampen_an.is_empty())

func _bewertung() -> void:
	var muster := aufbau()
	var richtig := aufbau()
	var b := Bewertung.bewerten(richtig, muster)
	_check("Bewertung: richtige Lösung = 100 Punkte, Note 1, Funktion ok", {"ausgeloest": [], "lampen_an": [], "fehler": b.fehler},
		b.punkte == 100 and b.note == 1 and b.funktion_ok == true)
	var falsch := aufbau()
	falsch.leitungen[3].adern[1].nach = "dose_L:e"   # Schaltdraht auf L-Klemme statt Lampenklemme: Lampe bleibt immer aus
	b = Bewertung.bewerten(falsch, muster)
	_check("Bewertung: Lampe brennt dauernd -> Funktion falsch, Abzug", {"ausgeloest": [], "lampen_an": [], "fehler": b.fehler},
		b.funktion_ok == false and b.punkte <= 60)
	var tab: Dictionary = b.tabelle
	_check("Bewertung: Funktionstabelle hat 2 Zeilen (1 Schalter)", {"ausgeloest": [], "lampen_an": [], "fehler": []}, tab.zeilen.size() == 2)
