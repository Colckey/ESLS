class_name BauteilSymbol
extends Control
## Kleines gezeichnetes Bild fuer die Bauteil- und Leitungskacheln.
## typ = Geraetetyp aus montage.gd BAUTEILE, oder "leitung" mit adern = Farbkuerzel.

var typ := ""
var farbe := Color.WHITE
var adern: Array = []
var aderfarbe := {}

const LINIE := Color(0.15, 0.15, 0.17)

func _init() -> void:
	custom_minimum_size = Vector2(56, 40)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var m := size / 2
	var f := get_theme_default_font()
	match typ:
		"leitung":
			_leitung(m)
		"fi":
			_gehaeuse(m, Vector2(34, 38))
			draw_rect(Rect2(m + Vector2(-12, -14), Vector2(10, 12)), Color(0.2, 0.2, 0.22))
			draw_circle(m + Vector2(8, -8), 4, Color(0.95, 0.75, 0.2))
			_text(f, m + Vector2(0, 12), "FI", 11)
		"ls":
			_gehaeuse(m, Vector2(14, 38))
			draw_rect(Rect2(m + Vector2(-3, -12), Vector2(6, 10)), Color(0.15, 0.3, 0.7))
			_text(f, m + Vector2(0, 12), "B", 10)
		"schuetz":
			_gehaeuse(m, Vector2(26, 38))
			draw_rect(Rect2(m + Vector2(-8, -10), Vector2(16, 12)), LINIE, false, 1.5)
			_text(f, m + Vector2(0, 13), "K", 11)
		"treppenlicht":
			_gehaeuse(m, Vector2(14, 38))
			draw_circle(m + Vector2(0, -10), 2.5, Color(0.3, 0.8, 0.35))
			_text(f, m + Vector2(0, 6), "T", 11)
		"zeitrelais":
			_gehaeuse(m, Vector2(14, 38))
			draw_arc(m + Vector2(0, -5), 5, 0, TAU, 20, LINIE, 1.5)
			draw_line(m + Vector2(0, -5), m + Vector2(0, -8), LINIE, 1.5)
			draw_line(m + Vector2(0, -5), m + Vector2(3, -5), LINIE, 1.5)
		"abzweigdose":
			_gehaeuse(m, Vector2(36, 36), 4)
			draw_arc(m, 10, 0, TAU, 28, LINIE, 1.5)
			for w in [0.785, 2.356, 3.927, 5.498]:
				draw_circle(m + Vector2(cos(w), sin(w)) * 13, 1.6, LINIE)
		"ausschalter", "wechselschalter", "kreuzschalter", "taster", "taster_aus":
			_gehaeuse(m, Vector2(36, 36), 4)
			var wippe := Color(0.82, 0.82, 0.8)
			if typ == "taster": wippe = Color(0.35, 0.75, 0.35)
			if typ == "taster_aus": wippe = Color(0.85, 0.3, 0.3)
			draw_rect(Rect2(m - Vector2(11, 11), Vector2(22, 22)), wippe)
			draw_rect(Rect2(m - Vector2(11, 11), Vector2(22, 22)), LINIE, false, 1.0)
			match typ:
				"ausschalter":
					draw_line(m + Vector2(-6, 0), m + Vector2(6, 0), LINIE, 1.5)
				"wechselschalter":
					draw_line(m + Vector2(-6, -3), m + Vector2(6, -3), LINIE, 1.5)
					draw_line(m + Vector2(-6, 3), m + Vector2(6, 3), LINIE, 1.5)
				"kreuzschalter":
					draw_line(m + Vector2(-6, -6), m + Vector2(6, 6), LINIE, 1.5)
					draw_line(m + Vector2(-6, 6), m + Vector2(6, -6), LINIE, 1.5)
				_:
					draw_arc(m, 5, 0, TAU, 20, LINIE, 1.5)
		"steckdose":
			_gehaeuse(m, Vector2(36, 36), 4)
			draw_circle(m, 12, Color(0.88, 0.88, 0.86))
			draw_arc(m, 12, 0, TAU, 28, LINIE, 1.0)
			draw_circle(m + Vector2(-5, 0), 2, LINIE)
			draw_circle(m + Vector2(5, 0), 2, LINIE)
			draw_rect(Rect2(m + Vector2(-1.5, -12), Vector2(3, 4)), Color(0.6, 0.6, 0.6))
			draw_rect(Rect2(m + Vector2(-1.5, 8), Vector2(3, 4)), Color(0.6, 0.6, 0.6))
		"lampe":
			draw_circle(m, 15, Color(0.98, 0.86, 0.45))
			draw_arc(m, 15, 0, TAU, 32, LINIE, 1.5)
			var d := 15.0 * 0.7071
			draw_line(m + Vector2(-d, -d), m + Vector2(d, d), LINIE, 1.5)
			draw_line(m + Vector2(-d, d), m + Vector2(d, -d), LINIE, 1.5)
		_:
			_gehaeuse(m, Vector2(30, 30))

func _gehaeuse(m: Vector2, g: Vector2, r := 3) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = farbe
	sb.set_corner_radius_all(r)
	sb.border_color = farbe.darkened(0.45)
	sb.set_border_width_all(1)
	draw_style_box(sb, Rect2(m - g / 2, g))

func _text(f: Font, p: Vector2, t: String, groesse: int) -> void:
	var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse).x
	draw_string(f, p + Vector2(-w / 2, groesse * 0.35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, groesse, LINIE)

## Leitung: grauer Mantel links, rechts schauen die Adern heraus
func _leitung(m: Vector2) -> void:
	var n := adern.size()
	var dicke := 3.0 if n <= 3 else 2.2
	var hoehe := n * (dicke + 1.5) + 4
	draw_rect(Rect2(Vector2(m.x - 24, m.y - hoehe / 2), Vector2(26, hoehe)), Color(0.86, 0.86, 0.84))
	for i in n:
		var y := m.y - hoehe / 2 + 3 + i * (dicke + 1.5) + dicke / 2
		var c: Color = aderfarbe.get(adern[i], Color(0.1, 0.1, 0.1))
		draw_line(Vector2(m.x + 2, y), Vector2(m.x + 20, y), c, dicke)
		draw_line(Vector2(m.x + 20, y), Vector2(m.x + 24, y), Color(0.85, 0.5, 0.25), dicke)  # Kupfer
