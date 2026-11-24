class_name Stil
extends RefCounted
## Gemeinsames Aussehen der Oberflaeche (Montage, Nahansicht, Lehrermodus):
## helles, freundliches Lernprogramm: weisse Flaechen, Schulblau als Akzent,
## Gruen fuer "geschafft", abgerundete Knoepfe, gut lesbare Schrift.

const HINTERGRUND := Color(0.975, 0.977, 0.98, 0.98)
const SEITE := Color(0.93, 0.94, 0.95)
const FLAECHE := Color(1.0, 1.0, 1.0)
const FLAECHE_HELL := Color(0.92, 0.95, 1.0)
const RAND := Color(0.80, 0.83, 0.87)
const AKZENT := Color(0.12, 0.42, 0.80)
const AKZENT_DUNKEL := Color(0.86, 0.92, 1.0)
const KOPF := Color(0.09, 0.33, 0.66)
const GRUEN := Color(0.15, 0.58, 0.30)
const GELB_PAPIER := Color(1.0, 0.98, 0.90)
const TEXT := Color(0.13, 0.15, 0.19)
const TEXT_LEISE := Color(0.40, 0.43, 0.48)

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
	t.set_color("font_hover_color", "Button", AKZENT.darkened(0.2))
	t.set_color("font_pressed_color", "Button", AKZENT.darkened(0.2))
	t.set_color("font_hover_pressed_color", "Button", AKZENT.darkened(0.3))
	t.set_color("font_focus_color", "Button", TEXT)

	# Akzentknopf (z. B. "Prüfen"): gruen
	t.add_type("AkzentButton")
	t.set_type_variation("AkzentButton", "Button")
	t.set_stylebox("normal", "AkzentButton", box(GRUEN, 6, GRUEN, 0, Vector2(18, 6)))
	t.set_stylebox("hover", "AkzentButton", box(GRUEN.lightened(0.12), 6, GRUEN, 0, Vector2(18, 6)))
	t.set_stylebox("pressed", "AkzentButton", box(GRUEN.darkened(0.15), 6, GRUEN, 0, Vector2(18, 6)))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "AkzentButton", Color.WHITE)
	# Knoepfe in der blauen Kopfleiste
	t.add_type("KopfButton")
	t.set_type_variation("KopfButton", "Button")
	t.set_stylebox("normal", "KopfButton", box(Color(1, 1, 1, 0.12), 6, Color(1, 1, 1, 0.25), 1))
	t.set_stylebox("hover", "KopfButton", box(Color(1, 1, 1, 0.22), 6, Color(1, 1, 1, 0.4), 1))
	t.set_stylebox("pressed", "KopfButton", box(Color(1, 1, 1, 0.3), 6, Color(1, 1, 1, 0.5), 1))
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		t.set_color(c, "KopfButton", Color.WHITE)
	t.add_type("KopfLabel")
	t.set_type_variation("KopfLabel", "Label")
	t.set_color("font_color", "KopfLabel", Color.WHITE)

	# Eingabefelder
	t.set_stylebox("normal", "LineEdit", box(Color.WHITE, 6, RAND, 1))
	t.set_stylebox("focus", "LineEdit", box(Color.WHITE, 6, AKZENT, 2))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_color("font_placeholder_color", "LineEdit", TEXT_LEISE)
	t.set_color("caret_color", "LineEdit", AKZENT)

	# Panels
	t.set_stylebox("panel", "PanelContainer", box(HINTERGRUND, 0, RAND, 0, Vector2(12, 10)))
	t.add_type("Karte")
	t.set_type_variation("Karte", "PanelContainer")
	var karte := box(Color.WHITE, 10, RAND, 1, Vector2(16, 14))
	karte.shadow_color = Color(0, 0, 0, 0.12)
	karte.shadow_size = 8
	t.set_stylebox("panel", "Karte", karte)
	t.add_type("Papier")
	t.set_type_variation("Papier", "PanelContainer")
	t.set_stylebox("panel", "Papier", box(GELB_PAPIER, 0, Color(0.9, 0.85, 0.65), 1, Vector2(14, 6)))
	# Optionsliste, Tooltip
	t.set_stylebox("normal", "OptionButton", box(Color.WHITE, 6, RAND, 1))
	t.set_stylebox("hover", "OptionButton", box(FLAECHE_HELL, 6, AKZENT, 1))
	t.set_stylebox("pressed", "OptionButton", box(FLAECHE_HELL, 6, AKZENT, 1))
	t.set_color("font_color", "OptionButton", TEXT)
	t.set_color("font_hover_color", "OptionButton", TEXT)
	t.set_stylebox("panel", "PopupMenu", box(Color.WHITE, 6, RAND, 1, Vector2(6, 6)))
	t.set_color("font_color", "PopupMenu", TEXT)
	t.set_color("font_hover_color", "PopupMenu", AKZENT)
	t.set_stylebox("hover", "PopupMenu", box(FLAECHE_HELL, 4))
	t.set_stylebox("panel", "TooltipPanel", box(Color(0.15, 0.17, 0.22, 0.96), 6, Color(), 0, Vector2(10, 8)))
	t.set_color("font_color", "TooltipLabel", Color.WHITE)
	t.set_stylebox("normal", "SpinBox", box(Color.WHITE, 6, RAND, 1))

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
