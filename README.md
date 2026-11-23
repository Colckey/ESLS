# ESLS – Elektro-Lernsimulation Brettmontage

Lernsimulation für Elektroniker-Azubis (1./2. Lehrjahr): Brettmontage mit NYM-Leitungen,
Bohrungen, Iso-Schellen, Abmanteln/Abisolieren, Anklemmen in der Nahansicht und Prüfung
mit auslösendem LS/FI. Godot 4.7, Kompatibilitäts-Renderer (läuft auf schwachen Schul-PCs).

## Starten
Godot 4.7 öffnen → Projekt importieren → `project.godot` → **F5** (Hauptszene `montage.tscn`).

## Ablauf einer Montage
1. **Bohrmaschine**: Bohrungen setzen (unter jedes Bauteil 2, unter LS/Zeitrelais 1, unter jede Schelle 1)
2. **Bauteil setzen**: Typ in der Liste wählen, aufs Brett klicken
3. **Leitung verlegen**: Leitungstyp wählen, Start-Bauteil → Eckpunkte → Ziel-Bauteil
4. **Iso-Schelle**: auf die Leitung über einer Bohrung klicken (max. 25 cm Abstand, max. 10 cm vor dem Gerät)
5. **Abmantelungswerkzeug**, dann **Abisolierzange** (Länge einstellen, richtig sind 8–12 mm): Bauteil anklicken
6. **Schraubendreher**: Bauteil anklicken → Nahansicht → Ader links, Klemme rechts anklicken
   - Verteiler (Einspeisung, FI, LS, Schütz, Zeitrelais): Brücken mit H07V-K legen (zwei Klemmen nacheinander)
   - Abzweigdose: Verbindungsklemmen einsetzen
7. **Prüfen**; Schalter mit **Auswahl** anklicken und **Leertaste** drücken
8. Namen eintragen, **Speichern** (`.esim`) – die Datei lässt sich auf jedem PC öffnen

**Lehrermodus**: Schülerdatei und optional Musterlösung öffnen → Punkte, Note, Fehlerliste, Funktionstabelle.

## Tests (Szene öffnen, F6)
- `sim_test.tscn` – Prüflogik (LS/FI, PE, Farben, Schütz, Kreuzschaltung, Bewertung, Speichern)
- `montage_test.tscn` – Montage-Werkzeuge und komplette Ausschaltung über die Nahansicht
- `perf_test.tscn` – Performancetest (FPS)

## Windows-Version bauen
Einmalig im Editor: *Editor → Exportvorlagen verwalten → Herunterladen*. Dann `build_windows.bat`
ausführen → `build\ESLS.exe` (eine Datei, ohne Installation).

Siehe auch [ROADMAP.md](ROADMAP.md) und [ENTSCHEIDUNGEN.md](ENTSCHEIDUNGEN.md).
