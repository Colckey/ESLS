extends Node
## Performancetest mit dem echten, komplett aufgebauten Uebungsbrett (Musterbrett).
## F6 auf perf_test.tscn: zeigt FPS, Zeichenaufrufe und Objekte. Die Kamera faehrt langsam
## ueber das Brett. Taste G schaltet Grafik hoch/niedrig.
##
## Automatisch messen (z. B. auf dem Schul-PC, Ergebnis in der Konsole):
##   Godot.exe --path . perf_test.tscn -- --auto
## Gemessen werden 600 Bilder bei Grafik hoch und 600 bei Grafik niedrig.

const BILDER := 600

var m: Node3D
var info: Label
var auto := false
var bilder := 0
var zeit := 0.0
var phase := 0   # 0 = hoch, 1 = niedrig
var ergebnisse := []
var aufbau_ms := 0.0
var t := 0.0

func _ready() -> void:
	auto = "--auto" in OS.get_cmdline_user_args()
	m = load("res://montage.tscn").instantiate()
	add_child(m)
	var start := Time.get_ticks_usec()
	Musterbrett.aufbauen(m)
	aufbau_ms = (Time.get_ticks_usec() - start) / 1000.0
	m.start_ausblenden()
	m._pruefen()
	m.ergebnis_karte.hide()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	info = Label.new()
	info.position = Vector2(260, 110)
	info.add_theme_color_override("font_color", Color.BLACK)
	info.add_theme_color_override("font_outline_color", Color.WHITE)
	info.add_theme_constant_override("outline_size", 6)
	layer.add_child(info)

func _process(dt: float) -> void:
	t += dt
	# Kamerafahrt: einmal ueber das Brett und nah an den Verteiler
	m.cam_target = Vector3(sin(t * 0.4) * 0.35, cos(t * 0.3) * 0.15, 0)
	m.cam_dist = 0.9 + 0.5 * (0.5 + 0.5 * sin(t * 0.25))
	m.cam_yaw = sin(t * 0.2) * 0.25
	m._kamera_aktualisieren()
	var rs := RenderingServer
	info.text = "FPS: %d   Zeichenaufrufe: %d   Objekte: %d   Grafik: %s\nGPU: %s\nAufbau Musterbrett: %.0f ms   G = Grafik umschalten" % [
		Engine.get_frames_per_second(),
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_OBJECTS_IN_FRAME),
		"hoch" if m.grafik_hoch else "niedrig", RenderingServer.get_video_adapter_name(), aufbau_ms]
	if not auto:
		return
	bilder += 1
	if bilder > 30:   # Einschwingen
		zeit += dt
	if bilder == BILDER + 30:
		ergebnisse.append({"grafik": "hoch" if phase == 0 else "niedrig", "fps": (BILDER) / zeit, "ms": zeit * 1000.0 / BILDER,
			"draw_calls": rs.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)})
		bilder = 0
		zeit = 0.0
		phase += 1
		if phase == 1:
			m._grafik_setzen(false)
		else:
			print("PERF GPU: %s" % RenderingServer.get_video_adapter_name())
			print("PERF Aufbau Musterbrett: %.0f ms" % aufbau_ms)
			for e in ergebnisse:
				print("PERF Grafik %s: %.1f FPS (%.1f ms pro Bild), %d Zeichenaufrufe" % [e.grafik, e.fps, e.ms, e.draw_calls])
			get_tree().quit()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_G:
		m._grafik_setzen(not m.grafik_hoch)
