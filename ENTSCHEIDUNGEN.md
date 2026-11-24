# Entscheidungen zum Prüfen (von Claude getroffen)

Bitte kurz durchsehen. Alles lässt sich leicht ändern.

| # | Entscheidung | Warum | Alternative |
|---|---|---|---|
| 1 | Bauteile brauchen Bohrungen darunter: 2 für Dosen/Schalter/Lampe; FI/LS/Schütz/Relais rasten ohne Bohrung auf der Hutschiene ein | Wie in der Berufsschule: erst anzeichnen und bohren, dann schrauben | Bohrungen nur optisch, ohne Pflicht |
| 2 | Iso-Schellen nur über einer Bohrung (Fangradius 1,5 cm) | Schellen werden geschraubt bzw. genagelt | Schellen frei setzbar |
| 3 | Max. 25 cm Schellenabstand, erste/letzte Schelle max. 10 cm vor Gerät/Dose | Übliche Herstellerangabe für NYM auf Putz | Werte pro Aufgabe einstellbar (Lehrermodus) |
| 4 | Leitungen werden nur waagerecht/senkrecht verlegt (rechtwinklig) | Installationszonen nach DIN 18015-3 | Freie Verlegung |
| 5 | 1-cm-Fangraster auf dem Brett | Leichter sauber zu arbeiten | Feineres Raster oder frei |
| 6 | Kontakt in der Klemme nur, wenn die Leitung abgemantelt UND die Ader abisoliert ist | Wie in echt | – |
| 7 | 1,5 mm² max. LS 16 A, 2,5 mm² max. LS 20 A (vereinfacht, Verlegeart C) | Lehrstoff 1. Lehrjahr | Genaue Tabelle nach DIN VDE 0298-4 |
| 8 | Einspeisung (CEE unten links, Hauptklemme im Verteiler) sowie N- und PE-Klemmen sind fest eingebaut | Wie am Schulbrett | Lehrer platziert sie |
| 9 | Einen FI pro Brett (für die Fehlerstromprüfung) | Reicht für Lehrjahr 1/2 | Mehrere FIs (später) |
| 10 | Speicherdatei `.esim` (ZIP mit JSON + Prüfsumme) | Läuft auf jedem PC, Lehrer sieht Manipulation | – |
| 11 | Godot 4.7 statt 4.3 | Ist bei dir installiert | – |
| 12 | Abmanteln/Abisolieren: Bauteil anklicken, jeder Klick bearbeitet die nächste Leitung dort | Mehrere Leitungen enden am selben Punkt, so gibt es keine Verwechslung | Leitungsende einzeln anklicken (später, wenn Leitungen am Gehäuserand einführen) |
| 13 | Abisolieren gilt für alle Adern einer Leitung gleichzeitig | Schneller; Fehler „zu lang/zu kurz“ wird trotzdem bewertet | Jede Ader einzeln (später in der Nahansicht) |
| 14 | Nahansicht als Fenster rechts, Kamera zoomt auf das Bauteil | Läuft sicher auf schwachen PCs, gut lesbar | Klemmen direkt im 3D-Modell anklicken (späterer Ausbau) |
| 15 | Verteiler = Einspeisung + FI + alle LS gemeinsam; Verdrahtung darin mit H07V-K-Brücken | Wie ein Kleinverteiler in der Schule | Eigene Hutschiene als Bauteil |
| 16 | Schraubklemme max. 2 Adern, Verbindungsklemme (Wago) 1 Ader pro Steckplatz | Herstellerangaben üblich | – |
| 17 | Schalter bedienen: Bauteil mit „Auswahl“ anklicken, Leertaste schaltet und prüft sofort | Einfach für den Anfang | Eigenes Werkzeug „Bedienen“ |
| 18 | Schütz und Zeitrelais sitzen im Verteiler (Hutschiene) und erscheinen in dessen Nahansicht | Praxisüblich | Eigene Steuerungsplatte |
| 19 | Zeitrelais vorerst ansprechverzögert ohne echte Zeit: beim Prüfen gilt die Zeit als abgelaufen | Statische Prüfung reicht für Verdrahtungsfehler | Zeitlauf mit Uhr (später, für Treppenlicht) |
| 20 | Taster werden per Leertaste gedrückt/losgelassen (zweimal drücken) | Einfach | Taste gedrückt halten |
| 21 | Treppenlichtautomat (Klemmen L, N, T, Lampe) mit 30 s Nachlaufzeit; Stromstoßschalter noch nicht drin | 30 s statt 3 min, damit man im Unterricht nicht wartet | Zeit einstellbar |
| 22 | Bewertung: Start 100 Punkte, -10 je Fehler, -3 je Warnung, -40 wenn die Funktion nicht zur Musterlösung passt; Note nach IHK-Schlüssel (92/81/67/50/30) | Transparent und für Lehrer nachvollziehbar | Gewichtung pro Aufgabe einstellbar |
| 23 | Funktionsvergleich: alle Schalterstellungen werden durchprobiert; verglichen wird die Anzahl leuchtender Lampen und ob etwas auslöst, Schalter werden über alle Zuordnungen gleichen Typs abgeglichen | Schüler dürfen Bauteile anders benennen/anordnen | Exakter Vergleich pro Lampe |
| 24 | Schülername wird beim Speichern in die Datei geschrieben (Feld „Name“) | Lehrer sieht, von wem die Datei ist | Anmeldung |
| 25 | Windows-Export als eine einzige portable .exe (PCK eingebettet), Testszenen werden nicht mit exportiert | Einfach per USB-Stick verteilbar | Installer |
| 26 | Brettmaße 1,2 m × 0,9 m mit festem Kabelkanal oben und Kleinverteiler oben links | Wie das Übungsbrett aus dem Foto | Lehrer stellt Einbauten pro Aufgabe ein |
| 27 | Im Kabelkanal und im Verteiler braucht eine Leitung keine Schellen; Abstände werden entlang der Leitung gemessen (nicht Luftlinie) | Realistisch; über Eck zählt der echte Weg | – |
| 28 | Eine Ader darf in einer Leitung nur so oft vorkommen, wie der Leitungstyp sie hat (sonst Fehler „mehrfach verwendet“) | Erkennt manipulierte Dateien und Logikfehler | – |
| 29 | Neue Leitung NYM-O 3x1,5 (bn, bk, gy) für korrespondierende Leiter | Grün-gelb darf nie als Außenleiter dienen | NYM-J 5x1,5 |
| 30 | Sieben eingebaute Aufträge mit Musterschaltung; Bewertung: zusätzlich -15 je fehlendem Bauteil/Anforderung | Lehrer braucht keine eigene Musterdatei | Eigene Aufträge im Programm anlegen (später) |
| 31 | Steckdosen müssen im Steckdosen-Auftrag über den FI laufen (Anforderung) | DIN VDE 0100-410: Steckdosen bis 32 A mit RCD 30 mA | – |
| 32 | Helles Design mit Schulblau, grüner Prüfen-Knopf, Startbildschirm mit Auftragskarten | Soll wie ein Lernprogramm für die Schule aussehen | Dunkles Design (vorher) |
| 33 | Grafik „hoch“ (Schatten, 2× Kantenglättung) ist Standard, „niedrig“ per Knopf rechts | Schöner auf normalen PCs, schaltbar für sehr alte | Automatisch nach FPS umschalten |
| 34 | Teile eines Geräts mit gleichem Material werden zu einem Mesh zusammengefasst | Halbiert die Zeichenaufrufe (979 → 573 beim fertigen Brett) | – |
