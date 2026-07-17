extends SceneTree

func _init():
	var path = "res://scenes/start_screen.tscn"
	var pack = load(path)
	var scene = pack.instantiate()
	
	# Fix PlayerSilhouette - Just remove it or make it transparent
	var silhouette = scene.get_node_or_null("PlayerSilhouette")
	if silhouette:
		silhouette.visible = false
		silhouette.queue_free()
		
	var err = PackedScene.new()
	err.pack(scene)
	ResourceSaver.save(err, path)
	quit()
