class_name Stil
extends RefCounted
## Gemeinsames Aussehen der Oberflaeche (Montage, Nahansicht, Lehrermodus):
## dunkle Panels, Akzentfarbe Orange, abgerundete Knoepfe.

const HINTERGRUND := Color(0.11, 0.12, 0.14, 0.97)
const FLAECHE := Color(0.17, 0.18, 0.21)
const FLAECHE_HELL := Color(0.23, 0.25, 0.29)
const RAND := Color(0.27, 0.29, 0.33)
const AKZENT := Color(0.98, 0.66, 0.16)
const AKZENT_DUNKEL := Color(0.30, 0.22, 0.08)
const TEXT := Color(0.92, 0.93, 0.95)
const TEXT_LEISE := Color(0.62, 0.65, 0.70)

static var _theme: Theme

static func box(farbe: Color, radius := 6, rand := Color(0, 0, 0, 0), rand_breite := 0, innen := Vector2(10, 6)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = farbe
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = innen.x
	sb.content_margin_right = innen.x
	sb.content_margin_top = innen.y
	sb.content_margin_bottom = innen.y
	if rand_breite > 0:
		sb.border_color = rand
		sb.set_border_width_all(rand_breite)
	return sb

static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 15

	# Knoepfe
	t.set_stylebox("normal", "Button", box(FLAECHE, 6, RAND, 1))
	t.set_stylebox("hover", "Button", box(FLAECHE_HELL, 6, RAND.lightened(0.2), 1))
	t.set_stylebox("pressed", "Button", box(AKZENT_DUNKEL, 6, AKZENT, 2))
	t.set_stylebox("hover_pressed", "Button", box(AKZENT_DUNKEL.lightened(0.08), 6, AKZENT, 2))
	t.set_stylebox("disabled", "Button", box(FLAECHE.darkened(0.3), 6))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", AKZENT.lightened(0.3))
	t.set_color("font_hover_pressed_color", "Button", AKZENT.lightened(0.4))
	t.set_color("font_focus_color", "Button", TEXT)

	# Akzentknopf (z. B. "Prüfen")
	t.add_type("AkzentButton")
	t.set_type_variation("AkzentButton", "Button")
	t.set_stylebox("normal", "AkzentButton", box(AKZENT, 6, AKZENT, 0, Vector2(16, 6)))
	t.set_stylebox("hover", "AkzentButton", box(AKZENT.lightened(0.15), 6, AKZENT, 0, Vector2(16, 6)))
	t.set_stylebox("pressed", "AkzentButton", box(AKZENT.darkened(0.15), 6, AKZENT, 0, Vector2(16, 6)))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "AkzentButton", Color(0.1, 0.08, 0.05))

	# Eingabefelder
	t.set_stylebox("normal", "LineEdit", box(Color(0.08, 0.09, 0.10), 6, RAND, 1))
	t.set_stylebox("focus", "LineEdit", box(Color(0.08, 0.09, 0.10), 6, AKZENT, 1))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_LEISE)
	t.set_color("caret_color", "LineEdit", AKZENT)

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(HINTERGRUND, 0, RAND, 0, Vector2(12, 10)))
	t.add_type("Karte")
	t.set_type_variation("Karte", "PanelContainer")
	t.set_stylebox("panel", "Karte", box(HINTERGRUND, 10, RAND, 1, Vector2(14, 12)))

	# Texte
	t.set_color("font_color", "Label", TEXT)
	t.add_type("Ueberschrift")
	t.set_type_variation("Ueberschrift", "Label")
	t.set_font_size("font_size", "Ueberschrift", 13)
	t.set_color("font_color", "Ueberschrift", AKZENT)
	t.add_type("Titel")
	t.set_type_variation("Titel", "Label")
	t.set_font_size("font_size", "Titel", 19)
	t.add_type("Leise")
	t.set_type_variation("Leise", "Label")
	t.set_font_size("font_size", "Leise", 13)
	t.set_color("font_color", "Leise", TEXT_LEISE)
	t.set_color("default_color", "RichTextLabel", TEXT)

	# Trennlinien
	var linie := StyleBoxLine.new()
	linie.color = RAND
	linie.thickness = 1
	t.set_stylebox("separator", "HSeparator", linie)
	var linie_v := StyleBoxLine.new()
	linie_v.color = RAND
	linie_v.thickness = 1
	linie_v.vertical = true
	t.set_stylebox("separator", "VSeparator", linie_v)

	# Scrollbalken schmal
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0), 4, Color(), 0, Vector2(3, 0)))
	t.set_stylebox("grabber", "VScrollBar", box(RAND, 4, Color(), 0, Vector2(3, 0)))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(FLAECHE_HELL.lightened(0.2), 4, Color(), 0, Vector2(3, 0)))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(AKZENT, 4, Color(), 0, Vector2(3, 0)))
	_theme = t
	return t

## Kleine Abschnittsueberschrift in Grossbuchstaben
static func ueberschrift(text: String) -> Label:
	var l := Label.new()
	l.text = text.to_upper()
	l.theme_type_variation = "Ueberschrift"
	return l
