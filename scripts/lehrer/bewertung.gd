class_name Bewertung
extends RefCounted
## Bewertung fuer den Lehrermodus:
## 1. Montage- und Sicherheitspruefung (Fehler/Warnungen aus Circuit.pruefen)
## 2. Funktionstabelle: alle Schalterstellungen durchprobieren
## 3. Optional: Vergleich mit der Musterloesung des Lehrers

const ABZUG_FEHLER := 10
const ABZUG_WARNUNG := 3
const ABZUG_FUNKTION := 40
const ABZUG_ANFORDERUNG := 15

const SCHALTER_TYPEN := ["ausschalter", "wechselschalter", "kreuzschalter", "taster", "taster_aus"]

## Funktionstabelle: {schalter:[ids], zeilen:[{stellung:[0/1..], lampen:[ids], ausgeloest:[ids]}]}
static func tabelle(original: Circuit) -> Dictionary:
	var schalter := []
	for id in original.geraete:
		if original.geraete[id].typ in SCHALTER_TYPEN:
			schalter.append(id)
	schalter.sort()
	var zeilen := []
	var n := schalter.size()
	if n > 8:
		n = 8   # max. 256 Kombinationen
	for maske in range(1 << n):
		var c := original.kopie()
		for id in c.zustand:
			if c.zustand[id].has("ausgeloest"): c.zustand[id].ausgeloest = false
			if c.zustand[id].has("an"): c.zustand[id].an = false
		var stellung := []
		for i in n:
			var st := (maske >> i) & 1
			c.zustand[schalter[i]].stellung = st
			stellung.append(st)
		var r := c.pruefen()
		var lampen: Array = r.lampen_an.duplicate()
		lampen.sort()
		var dosen: Array = r.get("steckdosen_an", []).duplicate()
		dosen.sort()
		zeilen.append({"stellung": stellung, "lampen": lampen, "steckdosen": dosen, "ausgeloest": r.ausgeloest})
	return {"schalter": schalter.slice(0, n), "zeilen": zeilen}

## Vergleicht zwei Funktionstabellen. Schalter werden ueber alle Zuordnungen gleichen Typs
## probiert (Schueler kann andere Namen/Reihenfolge haben). Verglichen wird pro Zeile
## die Anzahl leuchtender Lampen und ob etwas ausloest.
static func gleiche_funktion(schueler: Circuit, muster: Circuit) -> bool:
	var ts := tabelle(schueler)
	var tm := tabelle(muster)
	if ts.schalter.size() != tm.schalter.size():
		return false
	var typen_s: Array = ts.schalter.map(func(id): return schueler.geraete[id].typ)
	var typen_m: Array = tm.schalter.map(func(id): return muster.geraete[id].typ)
	for perm in _permutationen(range(ts.schalter.size())):
		var passt := true
		for i in perm.size():
			if typen_s[perm[i]] != typen_m[i]:
				passt = false
		if not passt:
			continue
		var alle_gleich := true
		for zm in tm.zeilen:
			# Stellung des Musters auf die Schalter des Schuelers uebertragen
			var maske := 0
			for i in perm.size():
				maske |= int(zm.stellung[i]) << perm[i]
			var zs: Dictionary = ts.zeilen[maske]
			if zs.lampen.size() != zm.lampen.size() or zs.ausgeloest.is_empty() != zm.ausgeloest.is_empty() \
					or zs.get("steckdosen", []).size() != zm.get("steckdosen", []).size():
				alle_gleich = false
				break
		if alle_gleich:
			return true
	return false

static func _permutationen(elemente: Array) -> Array:
	if elemente.size() <= 1:
		return [elemente.duplicate()]
	var r := []
	for i in elemente.size():
		var rest := elemente.duplicate()
		var e = rest.pop_at(i)
		for p in _permutationen(rest):
			r.append([e] + p)
	return r

## Gesamtbewertung: {punkte (0-100), note (1-6), fehler, warnungen, anforderungen, funktion_ok (bool oder null), tabelle}
## aufgabe: id aus Aufgaben.LISTE. Ohne eigene Musterloesung wird die eingebaute Musterschaltung verwendet.
static func bewerten(schueler: Circuit, muster: Circuit = null, aufgabe := "") -> Dictionary:
	var c := schueler.kopie()
	var r := c.pruefen()
	var anforderungen := Aufgaben.anforderungen_pruefen(schueler, aufgabe)
	var punkte: int = 100 - ABZUG_FEHLER * r.fehler.size() - ABZUG_WARNUNG * r.warnungen.size() \
		- ABZUG_ANFORDERUNG * anforderungen.size()
	if muster == null and aufgabe != "":
		muster = Aufgaben.muster(aufgabe)
	var funktion_ok = null
	if muster != null:
		funktion_ok = gleiche_funktion(schueler, muster)
		if not funktion_ok:
			punkte -= ABZUG_FUNKTION
	punkte = clampi(punkte, 0, 100)
	return {"punkte": punkte, "note": note(punkte), "fehler": r.fehler, "warnungen": r.warnungen,
		"anforderungen": anforderungen, "funktion_ok": funktion_ok, "tabelle": tabelle(schueler)}

## IHK-uebliche Notenskala
static func note(punkte: int) -> int:
	if punkte >= 92: return 1
	if punkte >= 81: return 2
	if punkte >= 67: return 3
	if punkte >= 50: return 4
	if punkte >= 30: return 5
	return 6
