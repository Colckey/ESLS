# Entscheidungen zum Prüfen (von Claude getroffen)

Bitte kurz durchsehen. Alles lässt sich leicht ändern.

| # | Entscheidung | Warum | Alternative |
|---|---|---|---|
| 1 | Bauteile brauchen Bohrungen darunter: 2 für Dosen/Schalter/Lampe, 1 für einen LS | Wie in der Berufsschule: erst anzeichnen und bohren, dann schrauben | Bohrungen nur optisch, ohne Pflicht |
| 2 | Iso-Schellen nur über einer Bohrung (Fangradius 1,5 cm) | Schellen werden geschraubt bzw. genagelt | Schellen frei setzbar |
| 3 | Max. 25 cm Schellenabstand, erste/letzte Schelle max. 10 cm vor Gerät/Dose | Übliche Herstellerangabe für NYM auf Putz | Werte pro Aufgabe einstellbar (Lehrermodus) |
| 4 | Leitungen werden nur waagerecht/senkrecht verlegt (rechtwinklig) | Installationszonen nach DIN 18015-3 | Freie Verlegung |
| 5 | 1-cm-Fangraster auf dem Brett | Leichter sauber zu arbeiten | Feineres Raster oder frei |
| 6 | Kontakt in der Klemme nur, wenn die Leitung abgemantelt UND die Ader abisoliert ist | Wie in echt | – |
| 7 | 1,5 mm² max. LS 16 A, 2,5 mm² max. LS 20 A (vereinfacht, Verlegeart C) | Lehrstoff 1. Lehrjahr | Genaue Tabelle nach DIN VDE 0298-4 |
| 8 | Einspeisung ist fest oben links und kann nicht gelöscht werden | Jede Aufgabe braucht eine Einspeisung | Lehrer platziert sie |
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
| 21 | Stromstoßschalter und Treppenlichtautomat noch nicht drin | Brauchen echte Zeit-/Flankenlogik | Nächster Ausbauschritt |
| 22 | Bewertung: Start 100 Punkte, -10 je Fehler, -3 je Warnung, -40 wenn die Funktion nicht zur Musterlösung passt; Note nach IHK-Schlüssel (92/81/67/50/30) | Transparent und für Lehrer nachvollziehbar | Gewichtung pro Aufgabe einstellbar |
| 23 | Funktionsvergleich: alle Schalterstellungen werden durchprobiert; verglichen wird die Anzahl leuchtender Lampen und ob etwas auslöst, Schalter werden über alle Zuordnungen gleichen Typs abgeglichen | Schüler dürfen Bauteile anders benennen/anordnen | Exakter Vergleich pro Lampe |
| 24 | Schülername wird beim Speichern in die Datei geschrieben (Feld „Name“) | Lehrer sieht, von wem die Datei ist | Anmeldung |
| 25 | Windows-Export als eine einzige portable .exe (PCK eingebettet), Testszenen werden nicht mit exportiert | Einfach per USB-Stick verteilbar | Installer |
