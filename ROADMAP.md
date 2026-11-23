# ESLS – Anforderungen und Fahrplan

Status: ✅ fertig · 🔧 in Arbeit · ⬜ offen

| # | Meilenstein | Kriterien (aus Firats Anforderungen) | Status |
|---|---|---|---|
| 0 | Grundlagen | Godot 4.7, 3D im Kompatibilitätsmodus für schwache Schul-PCs, Performancetest | ✅ |
| 1 | Prüflogik & Speichern | LS fliegt bei Kurzschluss, FI bei Fehlerstrom/N-PE, PE-Prüfung, Aderfarben, Querschnitt zu LS, Abmanteln/Abisolieren nötig für Kontakt, Schellenabstand, `.esim`-Datei mit Prüfsumme, auf anderem PC ladbar | ✅ |
| 2 | Brett & Bohren | Montagebrett, Werkzeugkasten-Leiste, Bohrmaschine setzt Bohrungen, Bauteile auf Brett platzieren | 🔧 erste Version (`montage.tscn`) |
| 3 | Leitung ziehen | Kabelwahl (NYM-J 3x1,5 / 5x1,5 / 3x2,5 / 5x2,5, Steuerleitung), Leitung Punkt für Punkt verlegen, Iso-Schellen setzen, Seitenschneider zum Ablängen | 🔧 erste Version |
| 4 | Abmanteln & Abisolieren | Abmantelungswerkzeug und Abisolierzange mit Längenwahl, sichtbare Adern in Normfarben | 🔧 erste Version |
| 5 | Nahansicht Anklemmen | Kamera zoomt an Bauteil, Adern einzeln in Klemmen stecken, Schraubendreher | 🔧 erste Version (Fenster-Nahansicht) |
| 6 | Installationsgeräte 3D | FI, LS, Ausschalter, Wechsel-/Kreuzschalter, Schuko-Steckdose, Abzweigdose mit Klemmen, Lampe | ⬜ |
| 7 | Prüfen in 3D | Prüfknopf, Schalter bedienen, Lampe leuchtet, LS/FI kippen sichtbar, Fehlerliste | 🔧 Lampe leuchtet, ausgelöste Geräte rot, Leertaste schaltet |
| 8 | Steuerungstechnik | Schütz, Zeitrelais (Treppenlicht), Stromstoßschalter, Steuerleitung | ⬜ |
| 9 | Lehrermodus | Aufgaben anlegen, Schülerdatei öffnen, automatisch bewerten, Manipulationshinweis | ⬜ |
| 10 | Windows-Export | Portable .exe ohne Installation, Test auf Schulrechner | ⬜ |


## Bedienung `montage.tscn` (Hauptszene, F5)
- Werkzeug oben wählen, linke Maustaste benutzt es
- Rechte Maustaste ziehen = schwenken, mittlere = verschieben, Mausrad = Zoom
- Leitung: Start-Bauteil anklicken → Eckpunkte → Ziel-Bauteil anklicken, Esc bricht ab
- Entf löscht das ausgewählte Bauteil

Tests: `sim_test.tscn` (Prüflogik) und `montage_test.tscn` (Montage) mit F6.
Performancetest: `perf_test.tscn`.
