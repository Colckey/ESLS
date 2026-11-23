extends Node3D
## Performancetest: Montagebrett mit Bauteilen, NYM-Leitungen, Iso-Schellen,
## Bohrungen und gefuehrter Kamera. Keine Spiellogik.
## Tasten: Mausrad = Zoom, rechte Maustaste ziehen = Kamera schwenken,
## G = Grafik niedrig/hoch, 1-3 = Kameraposition, L = 20 weitere Leitungen (Stresstest)

const BOARD_W := 1.2   # Meter
const BOARD_H := 0.8
const BOARD_D := 0.018

var cam: Camera3D
var cam_yaw := 0.0
var cam_pitch := -0.15
var cam_dist := 1.3
var cam_target := Vector3(0, 0, 0)
var low_gfx := false
var info: Label
var cable_count := 0
var rng := RandomNumberGenerator.new()

var mat_board: StandardMaterial3D
var mat_nym: StandardMaterial3D
var mat_clip: StandardMaterial3D
var mat_device: StandardMaterial3D
var mat_hole: StandardMaterial3D

func _ready() -> void:
	rng.seed = 42
	_make_materials()
	_make_environment()
	_make_board()
	_make_devices()
	_make_demo_cables()
	_make_camera()
	_make_ui()

func _mat(c: Color, rough := 0.8) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	return m

func _make_materials() -> void:
	mat_board = _mat(Color(0.78, 0.66, 0.48))      # Holzplatte
	mat_nym = _mat(Color(0.88, 0.88, 0.86), 0.6)   # NYM grau-weiss
	mat_clip = _mat(Color(0.95, 0.95, 0.95), 0.5)  # Iso-Schelle
	mat_device = _mat(Color(0.93, 0.93, 0.9), 0.4) # Geraete
	mat_hole = _mat(Color(0.2, 0.15, 0.1))

func _make_environment() -> void:
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.22, 0.24, 0.27)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.75, 0.75, 0.78)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 0.9
	sun.shadow_enabled = false   # keine Echtzeitschatten -> schwache GPUs
	add_child(sun)

func _box(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	return mi

func _make_board() -> void:
	_box(Vector3(BOARD_W, BOARD_H, BOARD_D), Vector3(0, 0, -BOARD_D / 2), mat_board)
	# Bohrraster (nur Markierungen)
	for x in range(-5, 6):
		for y in range(-3, 4):
			var h := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 0.003
			cm.bottom_radius = 0.003
			cm.height = 0.001
			cm.radial_segments = 8
			h.mesh = cm
			h.material_override = mat_hole
			h.rotation_degrees = Vector3(90, 0, 0)
			h.position = Vector3(x * 0.1, y * 0.1, 0.0005)
			add_child(h)

func _make_devices() -> void:
	# Kleinverteiler mit Hutschiene (FI + LS)
	_box(Vector3(0.30, 0.22, 0.09), Vector3(-0.38, 0.22, 0.045), _mat(Color(0.9, 0.9, 0.88)))
	_box(Vector3(0.07, 0.09, 0.07), Vector3(-0.46, 0.22, 0.125), mat_device)  # FI
	_box(Vector3(0.018, 0.09, 0.07), Vector3(-0.40, 0.22, 0.125), mat_device) # LS
	_box(Vector3(0.018, 0.09, 0.07), Vector3(-0.38, 0.22, 0.125), mat_device) # LS
	# Abzweigdose
	_box(Vector3(0.085, 0.085, 0.045), Vector3(0.05, 0.22, 0.0225), _mat(Color(0.85, 0.85, 0.82)))
	# Schalter, Steckdose (AP), Lampenfassung
	_box(Vector3(0.08, 0.08, 0.05), Vector3(0.05, -0.2, 0.025), mat_device)
	_box(Vector3(0.08, 0.08, 0.05), Vector3(-0.2, -0.2, 0.025), mat_device)
	var lamp := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.035
	cm.bottom_radius = 0.045
	cm.height = 0.06
	cm.radial_segments = 16
	lamp.mesh = cm
	lamp.material_override = _mat(Color(0.3, 0.3, 0.3))
	lamp.rotation_degrees = Vector3(90, 0, 0)
	lamp.position = Vector3(0.42, 0.22, 0.03)
	add_child(lamp)

func _make_demo_cables() -> void:
	_cable([Vector3(-0.23, 0.22, 0), Vector3(0.0, 0.22, 0)])            # Verteiler -> Dose
	_cable([Vector3(0.1, 0.22, 0), Vector3(0.38, 0.22, 0)])             # Dose -> Lampe
	_cable([Vector3(0.05, 0.17, 0), Vector3(0.05, -0.15, 0)])           # Dose -> Schalter
	_cable([Vector3(-0.38, 0.1, 0), Vector3(-0.38, -0.05, 0), Vector3(-0.2, -0.05, 0), Vector3(-0.2, -0.15, 0)]) # -> Steckdose

## NYM-Leitung als Rohr entlang der Punkte (auf dem Brett), mit Iso-Schellen alle ~25 cm
func _cable(pts: Array) -> void:
	const R := 0.0045   # NYM 3x1,5 ca. 9 mm Durchmesser
	const SEG := 8
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(pts.size() - 1):
		var a: Vector3 = pts[i] + Vector3(0, 0, R)
		var b: Vector3 = pts[i + 1] + Vector3(0, 0, R)
		var dir := (b - a).normalized()
		var side := dir.cross(Vector3(0, 0, 1)).normalized()
		var up := side.cross(dir).normalized()
		for s in range(SEG):
			var t0 := TAU * s / SEG
			var t1 := TAU * (s + 1) / SEG
			var n0 := side * cos(t0) + up * sin(t0)
			var n1 := side * cos(t1) + up * sin(t1)
			for v in [[a, n0], [b, n0], [b, n1], [a, n0], [b, n1], [a, n1]]:
				st.set_normal(v[1])
				st.add_vertex(v[0] + v[1] * R)
		# Schellen
		var length := a.distance_to(b)
		var n := maxi(1, int(length / 0.25))
		for k in range(n + 1):
			var p := a.lerp(b, float(k) / n)
			var clip := _box(Vector3(0.012, 0.012, 0.012), p, mat_clip)
			clip.scale = Vector3(1, 1, 1) if absf(dir.x) > 0.5 else Vector3(1.6, 0.8, 1)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat_nym
	add_child(mi)
	cable_count += 1

func _make_camera() -> void:
	cam = Camera3D.new()
	cam.fov = 45
	add_child(cam)
	_update_camera()

func _update_camera() -> void:
	cam_pitch = clampf(cam_pitch, -0.6, 0.6)
	cam_yaw = clampf(cam_yaw, -0.6, 0.6)   # gefuehrt: nur vor dem Brett
	cam_dist = clampf(cam_dist, 0.25, 2.0)
	var offs := Vector3(sin(cam_yaw) * cos(cam_pitch), sin(-cam_pitch), cos(cam_yaw) * cos(cam_pitch)) * cam_dist
	cam.position = cam_target + offs
	cam.look_at(cam_target)

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	info = Label.new()
	info.position = Vector2(10, 10)
	info.add_theme_color_override("font_color", Color.WHITE)
	layer.add_child(info)

func _process(_d: float) -> void:
	info.text = "FPS: %d   Leitungen: %d   Grafik: %s\nGPU: %s\nRechte Maus = schwenken, Rad = Zoom, 1-3 = Ansicht, G = Grafik, L = +20 Leitungen" % [
		Engine.get_frames_per_second(), cable_count, "niedrig" if low_gfx else "hoch",
		RenderingServer.get_video_adapter_name()]

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventMouseMotion and (ev.button_mask & MOUSE_BUTTON_MASK_RIGHT):
		cam_yaw -= ev.relative.x * 0.004
		cam_pitch += ev.relative.y * 0.004
		_update_camera()
	elif ev is InputEventMouseButton and ev.pressed:
		if ev.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_dist *= 0.9
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_dist /= 0.9
		_update_camera()
	elif ev is InputEventKey and ev.pressed:
		match ev.keycode:
			KEY_1: cam_target = Vector3.ZERO; cam_dist = 1.3; cam_yaw = 0; cam_pitch = -0.15
			KEY_2: cam_target = Vector3(-0.42, 0.22, 0.12); cam_dist = 0.3; cam_yaw = 0; cam_pitch = 0  # Nahansicht Verteiler
			KEY_3: cam_target = Vector3(0.05, 0.22, 0.04); cam_dist = 0.25; cam_yaw = 0; cam_pitch = 0  # Nahansicht Abzweigdose
			KEY_G: _toggle_gfx()
			KEY_L: _stress()
		_update_camera()

func _toggle_gfx() -> void:
	low_gfx = not low_gfx
	var vp := get_viewport()
	vp.msaa_3d = Viewport.MSAA_DISABLED if low_gfx else Viewport.MSAA_2X
	vp.scaling_3d_scale = 0.66 if low_gfx else 1.0

func _stress() -> void:
	for i in range(20):
		var y := rng.randf_range(-0.35, 0.35)
		var x0 := rng.randf_range(-0.55, 0.0)
		_cable([Vector3(x0, y, 0), Vector3(x0 + rng.randf_range(0.1, 0.5), y, 0)])
