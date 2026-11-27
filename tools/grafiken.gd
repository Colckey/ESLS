extends SceneTree
## Erzeugt die Bilder fuer Bauteile, Werkzeuge und Leitungen aus den eigenen 3D-Modellen.
## Aufruf (mit Grafik, z. B. xvfb-run unter Linux):
##   godot --rendering-driver opengl3 --path . -s tools/grafiken.gd
## Ergebnis: res://grafik/bauteile/*.png, res://grafik/werkzeuge/*.png, res://grafik/leitungen/*.png

const GROESSE := 256
const AUS := 128

var vp: SubViewport
var cam: Camera3D
var halter: Node3D

func _initialize() -> void:
	vp = SubViewport.new()
	vp.size = Vector2i(GROESSE, GROESSE)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(1, 1, 1)
	env.environment.ambient_light_energy = 0.45
	vp.add_child(env)
	var sonne := DirectionalLight3D.new()
	sonne.light_energy = 0.75
	vp.add_child(sonne)
	sonne.look_at_from_position(Vector3(-0.4, 0.8, 1.0), Vector3.ZERO, Vector3.UP)
	var fuell := DirectionalLight3D.new()
	fuell.light_energy = 0.25
	vp.add_child(fuell)
	fuell.look_at_from_position(Vector3(0.8, -0.3, 0.6), Vector3.ZERO, Vector3.UP)
	cam = Camera3D.new()
	cam.fov = 26
	vp.add_child(cam)
	halter = Node3D.new()
	vp.add_child(halter)
	for d in ["bauteile", "werkzeuge", "leitungen"]:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://grafik/" + d))
	var montage_skript: Script = load("res://scripts/montage/montage.gd")
	var bauteile: Dictionary = montage_skript.get_script_constant_map()["BAUTEILE"]
	var aderfarbe: Dictionary = montage_skript.get_script_constant_map()["ADERFARBE"]
	for typ in bauteile:
		var gr: Vector3 = bauteile[typ].groesse
		await _bild(Modelle.geraet(typ, gr, {"klemmen": 3} if typ == "abzweigdose" else {}), "res://grafik/bauteile/%s.png" % typ)
	for w in ["auswahl", "bohrer", "schelle", "seitenschneider", "abmanteln", "abisolieren", "anklemmen", "zollstock", "wasserwaage", "crimpen", "bruecke", "phasenschiene"]:
		await _bild(Werkzeugmodelle.werkzeug(w), "res://grafik/werkzeuge/%s.png" % w, w != "auswahl")
	for typ in Circuit.LEITUNGEN:
		await _bild(Werkzeugmodelle.leitung(typ, aderfarbe), "res://grafik/leitungen/%s.png" % _dateiname(typ))
	print("Grafiken fertig")
	quit()

static func _dateiname(typ: String) -> String:
	return typ.to_lower().replace(" ", "_").replace(",", "_").replace("-", "_")

func _bild(modell: Node3D, pfad: String, schraeg := true) -> void:
	for k in halter.get_children():
		k.free()
	halter.add_child(modell)
	if modell.has_meta("licht"):
		(modell.get_meta("licht") as Node3D).visible = false   # Leuchtschein nicht mit abbilden
	halter.rotation = Vector3(-0.35, 0.3, 0) if schraeg else Vector3.ZERO
	# Kamera auf die Huelle des Modells ausrichten
	await process_frame
	var huelle := _huelle(modell)
	var mitte := huelle.get_center()
	var radius := huelle.size.length() / 2
	var abstand := radius / sin(deg_to_rad(cam.fov / 2)) * 1.0
	cam.look_at_from_position(mitte + Vector3(0, 0, abstand), mitte, Vector3.UP)
	cam.near = abstand / 20
	cam.far = abstand * 4
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	var roh := vp.get_texture().get_image()
	roh.convert(Image.FORMAT_RGBA8)
	# auf den sichtbaren Teil zuschneiden, quadratisch mit etwas Rand
	var r := roh.get_used_rect()
	var kante := int(maxf(r.size.x, r.size.y) * 1.08) + 2
	var img := Image.create(kante, kante, false, Image.FORMAT_RGBA8)
	img.blit_rect(roh, r, Vector2i((kante - r.size.x) / 2, (kante - r.size.y) / 2))
	img.resize(AUS, AUS, Image.INTERPOLATE_LANCZOS)
	img.save_png(pfad)
	print("  ", pfad)

func _huelle(n: Node3D) -> AABB:
	var h := AABB()
	var erst := true
	for k in n.find_children("*", "MeshInstance3D", true, false):
		var mi := k as MeshInstance3D
		if not mi.is_visible_in_tree():
			continue
		var a := mi.global_transform * mi.get_aabb()
		if erst: h = a
		else: h = h.merge(a)
		erst = false
	return h
