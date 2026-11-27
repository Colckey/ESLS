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
| 12 | Abmanteln/Abisolieren/Anklemmen in einer 3D-Anschlussansicht: Gerät anklicken, dann Mantel bzw. Ader anklicken (geändert nach Test) | Schüler sieht jedes Leitungsende einzeln und wie die Ader in die Klemme läuft | Direkt auf dem Brett klicken (vorher, war unklar) |
| 13 | Abisolieren für jede Ader einzeln (geändert nach Test) | Wie in der Praxis; Fehler „zu lang/zu kurz“ wird pro Ader bewertet | Alle Adern auf einmal (vorher) |
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
| 35 | Abmanteln geht erst, wenn die Leitung höchstens 10 cm vor dem Gerät befestigt ist (Schelle, Kanal oder Verteiler) | Gibt den Schellen einen Sinn und erzwingt die Reihenfolge verlegen → befestigen → abmanteln | Nur beim Prüfen bemängeln |
| 36 | Auf dem Brett endet der Mantel 3 cm vor dem Geräterand, die Adern sind in ihren Farben sichtbar | Man sieht sofort, welche Enden schon abgemantelt sind | Mantel bis ins Gerät |
| 37 | Zollstock, Wasserwaage, cm-Raster (R) und Bauplan (B) mit den Maßen aus dem Foto | Brett soll genau wie auf dem Bild gebaut werden können | Freie Maßlinien |
| 38 | Bilder für Bauteile, Werkzeuge und Leitungen werden aus den eigenen 3D-Modellen gerendert (`tools/grafiken.gd`), keine fremden Grafiken | Keine Lizenzprobleme, Bild und 3D-Modell sehen gleich aus | Handgezeichnete Symbole (vorher) |
| 39 | Brücken im Verteiler nur mit H07V-K; jedes Ende braucht eine gecrimpte Aderendhülse, sonst Fehler beim Prüfen | Feindrähtige Leiter ohne Hülse sind in der Praxis ein Mangel | Nur Warnung |
| 40 | Phasenschiene 1-polig (FI L_out → alle LS-Eingänge) per Knopf; zählt nicht als Ader in der Klemme | Wie im Hager-Verteiler aus der Werkstatt, schnell und ohne Brückenwirrwarr | Mehrpolige Schiene (später, mit 3-phasigen LS) |
| 41 | Zuleitung vom CEE-Stecker ist fest an L/N/PE der Hauptklemme angeschlossen (sichtbar auf dem Brett und in 3D) | Ist am Schulbrett vormontiert | Zuleitung selbst anschließen |
| 42 | Tutorial mit 14 Schritten am Steckdosenkreis, jeder Schritt hakt sich selbst ab, „Vormachen“ erledigt ihn | Einstieg ohne Lehrer, man sieht jeden Handgriff | Video |
