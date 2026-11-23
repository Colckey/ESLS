class_name Projektdatei
extends RefCounted
## Speichern/Laden als .esim (ZIP mit projekt.json + pruefsumme.txt).
## Die Pruefsumme zeigt dem Lehrer, ob die Datei ausserhalb des Programms veraendert wurde.
## Hinweis: Das ist ein Manipulationshinweis, kein echter Kopierschutz.

const FORMAT_VERSION := 1
const SALZ := "ESLS-2026"   # spaeter pro Schule/Lizenz austauschbar

static func _v3(liste: Array) -> Array:
	var out := []
	for v in liste: out.append([v.x, v.y, v.z])
	return out

static func _to_v3(liste: Array) -> Array:
	var out := []
	for a in liste: out.append(Vector3(a[0], a[1], a[2]))
	return out

static func speichern(c: Circuit, pfad: String, meta := {}) -> Error:
	var leitungen := []
	for l in c.leitungen:
		var k: Dictionary = l.duplicate(true)
		k.punkte = _v3(l.get("punkte", []))
		k.schellen = _v3(l.get("schellen", []))
		leitungen.append(k)
	var geraete := {}
	for id in c.geraete:
		var g: Dictionary = c.geraete[id].duplicate(true)
		g.pos = [g.pos.x, g.pos.y, g.pos.z]
		geraete[id] = g
	var daten := {
		"format": "esls-projekt", "version": FORMAT_VERSION,
		"meta": meta, "geraete": geraete, "leitungen": leitungen, "zustand": c.zustand,
	}
	var json := JSON.stringify(daten, "  ")
	var zip := ZIPPacker.new()
	var err := zip.open(pfad)
	if err != OK: return err
	zip.start_file("projekt.json"); zip.write_file(json.to_utf8_buffer()); zip.close_file()
	zip.start_file("pruefsumme.txt"); zip.write_file((SALZ + json).sha256_text().to_utf8_buffer()); zip.close_file()
	return zip.close()

## Rueckgabe: {circuit, meta, unveraendert: bool} oder {fehler: text}
static func laden(pfad: String) -> Dictionary:
	var zip := ZIPReader.new()
	if zip.open(pfad) != OK:
		return {"fehler": "Datei kann nicht geöffnet werden."}
	var json := zip.read_file("projekt.json").get_string_from_utf8()
	var summe := zip.read_file("pruefsumme.txt").get_string_from_utf8()
	zip.close()
	var d = JSON.parse_string(json)
	if typeof(d) != TYPE_DICTIONARY or d.get("format") != "esls-projekt":
		return {"fehler": "Keine ESLS-Projektdatei."}
	if int(d.version) > FORMAT_VERSION:
		return {"fehler": "Datei stammt aus einer neueren Programmversion."}
	var c := Circuit.new()
	for id in d.geraete:
		var g: Dictionary = d.geraete[id]
		c.geraet_hinzufuegen(id, g.typ, Vector3(g.pos[0], g.pos[1], g.pos[2]), g.get("param", {}))
	for l in d.leitungen:
		l.punkte = _to_v3(l.get("punkte", []))
		l.schellen = _to_v3(l.get("schellen", []))
		c.leitung_hinzufuegen(l)
	for id in d.get("zustand", {}):
		var z: Dictionary = d.zustand[id]
		for k in z:
			if typeof(z[k]) == TYPE_FLOAT: z[k] = int(z[k])  # JSON liefert Zahlen als float
		c.zustand[id] = z
	return {"circuit": c, "meta": d.get("meta", {}), "unveraendert": (SALZ + json).sha256_text() == summe}
