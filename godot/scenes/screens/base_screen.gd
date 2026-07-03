extends MarginContainer
class_name BaseScreen

@export var screen_title: String = "Título"

@onready var topbar = %TopBar
@onready var content_area = %ContentArea

func _ready():
	if topbar:
		topbar.screen_title = screen_title
