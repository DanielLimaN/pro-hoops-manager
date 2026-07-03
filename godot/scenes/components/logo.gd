extends BoxContainer
class_name ProHoopsLogo

@export_enum("vertical", "horizontal") var variant: String = "horizontal":
	set(val):
		variant = val
		_update_layout()

@export_enum("light", "dark-purple", "deep-blue", "primary-blue", "violet", "mono-white", "mono-black", "mono-grey", "sidebar") var theme_name: String = "light":
	set(val):
		theme_name = val
		_update_theme()

@export var logo_size: float = 64.0:
	set(val):
		logo_size = max(val, 32.0)
		_update_layout()

@export var show_text: bool = true:
	set(val):
		show_text = val
		_update_layout()

@onready var mark: TextureRect = $Mark
@onready var text_container: VBoxContainer = $TextContainer
@onready var title: Label = $TextContainer/Title
@onready var subtitle: Label = $TextContainer/Subtitle

func _ready():
	_update_layout()
	_update_theme()

func _update_layout():
	if not is_inside_tree(): return
	
	mark.custom_minimum_size = Vector2(logo_size, logo_size)
	text_container.visible = show_text
	
	if variant == "vertical":
		vertical = true
		text_container.alignment = BoxContainer.ALIGNMENT_CENTER
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		text_container.add_theme_constant_override("separation", 2)
	else:
		vertical = false
		text_container.alignment = BoxContainer.ALIGNMENT_CENTER
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		text_container.add_theme_constant_override("separation", 0)
		
	var font_scale = logo_size / 100.0
	var f_size = max(14, int(24 * font_scale))
	title.add_theme_font_size_override("font_size", f_size)
	subtitle.add_theme_font_size_override("font_size", f_size)
	title.add_theme_constant_override("line_spacing", -2)

func _update_theme():
	if not is_inside_tree(): return
	
	var title_c = Color("#0B0514")
	var sub_c = Color("#0B0514")
	var mark_tex = "res://assets/images/logo_mark_default.svg"
	
	match theme_name:
		"light":
			pass
		"dark-purple", "deep-blue":
			title_c = Color("#FFFFFF")
			sub_c = Color("#A78BFA")
		"primary-blue", "violet":
			title_c = Color("#FFFFFF")
			sub_c = Color("#FFFFFF")
		"mono-white":
			title_c = Color("#FFFFFF")
			sub_c = Color("#FFFFFF")
			mark_tex = "res://assets/images/logo_mark_mono_white.svg"
		"mono-black":
			title_c = Color("#000000")
			sub_c = Color("#000000")
			mark_tex = "res://assets/images/logo_mark_mono_black.svg"
		"mono-grey":
			title_c = Color("#64748B")
			sub_c = Color("#64748B")
			mark_tex = "res://assets/images/logo_mark_mono_grey.svg"
		"sidebar":
			title_c = Color("#FFFFFF")
			sub_c = Color("#A78BFA")
			mark_tex = "res://assets/images/logo_mark_default.svg"
			
	title.add_theme_color_override("font_color", title_c)
	subtitle.add_theme_color_override("font_color", sub_c)
	mark.texture = load(mark_tex)
