extends SceneTree
## Screenshot einer Szene (fuer Doku): godot --path . -s tools/screenshot.gd -- <szene> <ausgabe.png> [vorbereitung]
## vorbereitung: optionaler Methodenname, der auf der Szene aufgerufen wird (z. B. demo_aufbau)

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var szene: String = args[0] if args.size() > 0 else "res://montage.tscn"
	var aus: String = args[1] if args.size() > 1 else "user://screenshot.png"
	var n: Node = load(szene).instantiate()
	root.add_child(n)
	for i in 3: await process_frame
	if args.size() > 2 and args[2] != "":
		for teil in args[2].split(","):
			if n.has_method(teil): n.call(teil)
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_viewport().get_texture().get_image().save_png(aus)
	print("Screenshot: ", aus)
	quit()
