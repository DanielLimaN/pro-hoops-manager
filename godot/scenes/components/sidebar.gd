extends Panel

@export var active_tab: String = ""
signal menu_item_selected(path: String)

@onready var nav_container: VBoxContainer = %NavContainer
@onready var initials_lbl: Label = %Initials
@onready var name_lbl: Label = %NameLbl
@onready var team_lbl: Label = %TeamLbl

func _ready():
	_init_labels()
	_init_nav_buttons()
	update_badges()
	if active_tab != "":
		set_active_tab(active_tab)

func _init_nav_buttons():
	for btn in nav_container.get_children():
		if btn is Button:
			btn.pressed.connect(func():
				var path = btn.get_meta("nav_path", "")
				if path != "":
					emit_signal("menu_item_selected", path)
			)

func _init_labels():
	initials_lbl.text = _get_initials()
	name_lbl.text = _get_coach_name()
	team_lbl.text = _get_team_name()
	if team_lbl.text.length() > 22:
		team_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _get_initials() -> String:
	if GameManager.league.is_empty() or not GameManager.league.has("coach_name"):
		return "GM"
	var name = GameManager.league.coach_name
	var parts = name.split(" ", false)
	if parts.size() >= 2:
		return parts[0][0] + parts[1][0]
	return name.left(2).to_upper()

func _get_coach_name() -> String:
	if GameManager.league.is_empty() or not GameManager.league.has("coach_name"):
		return "General Manager"
	return GameManager.league.coach_name

func _get_team_name() -> String:
	if GameManager.league.is_empty() or not GameManager.league.has("user_team_name"):
		return "Meu Time"
	return GameManager.league.user_team_name

func set_active_tab(screen_name: String):
	for btn in nav_container.get_children():
		if btn is Button:
			if btn.get_meta("nav_screen", "") == screen_name:
				btn.button_pressed = true

func update_badges():
	var elenco_badge = nav_container.get_node_or_null("NavElenco/BadgeContainer")
	var inbox_badge = nav_container.get_node_or_null("NavCaixadeEntrada/BadgeContainer")
	
	if elenco_badge:
		# TODO: Conectar com GameManager para checar se há notificações de elenco (ex: lesões, treinos)
		var has_team_notifications = false
		elenco_badge.visible = has_team_notifications
		
	if inbox_badge:
		# TODO: Conectar com o sistema de Inbox/Mensagens para checar não lidas
		var unread_messages = 0
		inbox_badge.visible = unread_messages > 0
		var lbl = inbox_badge.get_node_or_null("BadgeMargin/BadgeLabel")
		if lbl and unread_messages > 0:
			lbl.text = str(unread_messages)
