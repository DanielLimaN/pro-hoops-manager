extends Control
class_name PortraitRenderer

@onready var head_rect: TextureRect = %Head
@onready var shirt_rect: TextureRect = %Shirt
@onready var eyes_rect: TextureRect = %Eyes
@onready var eyebrows_rect: TextureRect = %Eyebrows
@onready var facial_hair_rect: TextureRect = %FacialHair
@onready var hair_rect: TextureRect = %Hair

func _ready():
	# Forçar todas as camadas a escalarem com o controle parente mantendo o pixel art centralizado e sem distorcer
	for child in get_children():
		if child is TextureRect:
			child.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			child.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			child.set_anchors_preset(PRESET_FULL_RECT)

func render_portrait(config: Dictionary) -> void:
	var skin_tone = config.get("skin_tone", "light")
	var hair_style = config.get("hair_style", "none")
	var hair_color = config.get("hair_color", "black")
	var facial_hair_style = config.get("facial_hair_style", "none")
	
	# Head
	head_rect.texture = _load_texture("res://assets/portraits/head/%s.png" % skin_tone)
	
	# Shirt
	shirt_rect.texture = _load_texture("res://assets/portraits/shirt/jersey_orange.png")
	
	# Eyes
	eyes_rect.texture = _load_texture("res://assets/portraits/eyes/base.png")
	
	# Eyebrows
	eyebrows_rect.texture = _load_texture("res://assets/portraits/eyebrows/base.png")
	
	# Facial Hair
	if facial_hair_style == "none" or facial_hair_style == null or facial_hair_style.is_empty():
		facial_hair_rect.hide()
	else:
		facial_hair_rect.texture = _load_texture("res://assets/portraits/facial_hair/%s_%s.png" % [facial_hair_style, hair_color])
		if facial_hair_rect.texture:
			facial_hair_rect.show()
		else:
			facial_hair_rect.hide()
		
	# Hair
	if hair_style == "none" or hair_style == null or hair_style.is_empty():
		hair_rect.hide()
	else:
		hair_rect.texture = _load_texture("res://assets/portraits/hair/%s_%s.png" % [hair_style, hair_color])
		if hair_rect.texture:
			hair_rect.show()
		else:
			hair_rect.hide()

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null
