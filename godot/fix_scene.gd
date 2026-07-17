extends SceneTree

func _init():
	var path = "res://scenes/start_screen.tscn"
	var pack = load(path)
	var scene = pack.instantiate()
	
	# 1. Background (Fundo): Make sure it's dark and textured.
	# The BackgroundGradient texture is already dark. 
	# "Precisa ser atualizado para o fundo correto (provavelmente existe uma textura de fundo com gradiente escuro e estrelas ou um Panel configurado para isso)."
	# Wait, maybe there's an actual stars/background texture?
	
	# Let's search for textures.
	
	# 2. Left Column (Texts): "Os textos principais ... estão encavalados em um quadrado cinza sólido que parece ser um placeholder."
	var silhouette = scene.get_node_or_null("PlayerSilhouette")
	if silhouette:
		silhouette.queue_free()
		scene.remove_child(silhouette)

	# 3. Card "Última Carreira" (Direita) 
	# CardPanel style box: [sub_resource type="StyleBoxFlat" id="8"] has bg_color (0.16471, 0.10196, 0.30588, 0.80) -> deep purple.
	# We need to change SubResource("8") to a soft bordered card style.
	
	# 4. Button Grid: "Atualmente estão cinza chapado. Eles devem seguir o padrão do tema escuro do projeto (fundos escuros, bordas sutis)."
	
	# 5. Top/Bottom bars icons misaligned, icons too large.
	
	var err = PackedScene.new()
	err.pack(scene)
	ResourceSaver.save(err, path)
	quit()
