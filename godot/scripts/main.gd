extends Control

var _current_screen: Node = null

@onready var sidebar = $Sidebar
@onready var content = %Content

func _ready():
	if theme:
		theme.default_font = ThemeConfig.FONT_INTER
	
	sidebar.menu_item_selected.connect(_on_menu_item_selected)
	
	if GameManager.pending_screen:
		_load_screen(GameManager.pending_screen, "Inbox")
		GameManager.pending_screen = ""
	elif GameManager.league.is_empty():
		_load_screen("res://scenes/new_game.tscn", "NewGame")
	else:
		_load_screen("res://scenes/ui/dashboard/dashboard.tscn", "Dashboard")

func _on_menu_item_selected(path: String):
	# Determine screen name for sidebar highlighting
	var screen_name = ""
	if "dashboard.tscn" in path: screen_name = "Dashboard"
	elif "team.tscn" in path: screen_name = "Team"
	elif "calendar_screen.tscn" in path: screen_name = "CalendarScreen"
	elif "tactics.tscn" in path: screen_name = "Tactics"
	elif "training.tscn" in path: screen_name = "Training"
	elif "inbox.tscn" in path: screen_name = "Inbox"
	elif "finance.tscn" in path: screen_name = "Finance"
	
	_load_screen(path, screen_name)

func _load_screen(path: String, screen_name: String):
	if _current_screen:
		_current_screen.queue_free()
	if not ResourceLoader.exists(path):
		return
	var scene = load(path).instantiate()
	content.add_child(scene)
	_current_screen = scene
	
	sidebar.set_active_tab(screen_name)
