extends Panel

@export var active_tab: String = ""
signal menu_item_selected(path: String)

func _ready():
	_setup_sidebar_visuals()
	_setup_sidebar_icons()
	_connect_buttons()
	if active_tab != "":
		set_active_tab(active_tab)

func _connect_buttons():
	%DashboardBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/ui/dashboard/dashboard.tscn"))
	%TeamBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/team.tscn"))
	%CalendarBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/screens/calendar/calendar_screen.tscn"))
	%TacticBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/tactics.tscn"))
	%TrainingBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/training.tscn"))
	%InboxBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/inbox.tscn"))
	%TransferBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/ui/dashboard/dashboard.tscn"))
	%FinanceBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/finance.tscn"))
	%StatsBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/ui/dashboard/dashboard.tscn"))
	%TrophyBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/ui/dashboard/dashboard.tscn"))
	%RestartBtn.pressed.connect(_on_restart)
	%SettingsBtn.pressed.connect(func(): emit_signal("menu_item_selected", "res://scenes/ui/dashboard/dashboard.tscn"))

func set_active_tab(screen_name: String):
	var active_style = StyleBoxFlat.new()
	active_style.bg_color = ThemeConfig.BG_ELEVATED
	active_style.corner_radius_top_left = 8; active_style.corner_radius_top_right = 8
	active_style.corner_radius_bottom_left = 8; active_style.corner_radius_bottom_right = 8
	active_style.content_margin_left = 12
	active_style.content_margin_right = 12
	active_style.content_margin_top = 10
	active_style.content_margin_bottom = 10
	
	var default_style = StyleBoxEmpty.new()
	default_style.content_margin_left = 12
	default_style.content_margin_right = 12
	default_style.content_margin_top = 10
	default_style.content_margin_bottom = 10
	
	var all_btns = [
		%DashboardBtn, %TeamBtn, %CalendarBtn, %TacticBtn, %TrainingBtn,
		%InboxBtn, %TransferBtn, %FinanceBtn, %StatsBtn, %TrophyBtn,
		%RestartBtn, %SettingsBtn
	]
	
	for btn in all_btns:
		btn.add_theme_stylebox_override("normal", default_style)
	
	var target = null
	match screen_name:
		"Dashboard": target = %DashboardBtn
		"Team": target = %TeamBtn
		"CalendarScreen": target = %CalendarBtn
		"Tactics": target = %TacticBtn
		"Training": target = %TrainingBtn
		"Inbox": target = %InboxBtn
		"Finance": target = %FinanceBtn
	
	if target:
		target.add_theme_stylebox_override("normal", active_style)

func _on_restart():
	GameManager.reset_career()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _setup_sidebar_visuals():
	var sidebar_style = StyleBoxFlat.new()
	sidebar_style.bg_color = Color("#0B0514")
	sidebar_style.border_color = Color("#1A0B2E")
	sidebar_style.border_width_right = 1
	sidebar_style.content_margin_left = 16
	sidebar_style.content_margin_right = 16
	add_theme_stylebox_override("panel", sidebar_style)
	
	$SidebarVBox.add_theme_constant_override("separation", 4)
	$SidebarVBox/Logo.visible = false
	
	var header = Control.new()
	header.custom_minimum_size = Vector2(240, 80)
	header.clip_contents = true
	
	var ball = TextureRect.new()
	ball.texture = load("res://assets/images/basketball_glow.svg")
	ball.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ball.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ball.custom_minimum_size = Vector2(120, 120)
	ball.position = Vector2(-42, 14)
	header.add_child(ball)
	
	var text_vbox = VBoxContainer.new()
	text_vbox.position = Vector2(55, 22)
	text_vbox.size = Vector2(160, 50)
	text_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	text_vbox.add_theme_constant_override("separation", -4)
	
	var t1 = Label.new()
	t1.text = "PRO HOOPS"
	t1.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	t1.add_theme_font_size_override("font_size", 18)
	t1.add_theme_color_override("font_color", Color.WHITE)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var t2 = Label.new()
	t2.text = "MANAGER"
	t2.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	t2.add_theme_font_size_override("font_size", 13)
	t2.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	t2.add_theme_constant_override("letter_spacing", 3)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	text_vbox.add_child(t1)
	text_vbox.add_child(t2)
	header.add_child(text_vbox)
	
	$SidebarVBox.add_child(header)
	$SidebarVBox.move_child(header, 0)
	
	var profile = HBoxContainer.new()
	profile.name = "ProfileBox"
	profile.add_theme_constant_override("separation", 12)
	
	var avatar = PanelContainer.new()
	avatar.custom_minimum_size = Vector2(40, 40)
	var av_style = StyleBoxFlat.new()
	av_style.bg_color = ThemeConfig.BRAND_DEEP
	av_style.corner_radius_top_left = 20; av_style.corner_radius_top_right = 20
	av_style.corner_radius_bottom_left = 20; av_style.corner_radius_bottom_right = 20
	avatar.add_theme_stylebox_override("panel", av_style)
	
	var av_lbl = Label.new()
	av_lbl.text = "GM"
	av_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	av_lbl.add_theme_font_size_override("font_size", 16)
	av_lbl.add_theme_color_override("font_color", Color.WHITE)
	av_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(av_lbl)
	
	var p_info = VBoxContainer.new()
	p_info.alignment = BoxContainer.ALIGNMENT_CENTER
	p_info.add_theme_constant_override("separation", -2)
	
	var p_name = Label.new()
	p_name.text = "Daniel Lima"
	p_name.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	p_name.add_theme_font_size_override("font_size", 14)
	p_name.add_theme_color_override("font_color", Color.WHITE)
	
	var p_role = Label.new()
	p_role.text = "General Manager"
	p_role.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	p_role.add_theme_font_size_override("font_size", 12)
	p_role.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	
	p_info.add_child(p_name)
	p_info.add_child(p_role)
	
	profile.add_child(avatar)
	profile.add_child(p_info)
	
	var p_pad = MarginContainer.new()
	p_pad.add_theme_constant_override("margin_top", 16)
	p_pad.add_theme_constant_override("margin_bottom", 16)
	p_pad.add_child(profile)
	
	$SidebarVBox.add_child(p_pad)

func _setup_sidebar_icons():
	var btn_config = [
		{"n": %DashboardBtn, "i": "grid_coarse", "b": 3},
		{"n": %TeamBtn, "i": "human", "b": 0},
		{"n": %CalendarBtn, "i": "calendar", "b": 1},
		{"n": %TacticBtn, "i": "clipboard", "b": 0},
		{"n": %TrainingBtn, "i": "weight", "b": 0},
		{"n": %InboxBtn, "i": "envelope", "b": 12},
		{"n": %TransferBtn, "i": "arrow_right_arrow_left", "b": 0},
		{"n": %FinanceBtn, "i": "coins", "b": 0},
		{"n": %StatsBtn, "i": "bar_graph", "b": 0},
		{"n": %TrophyBtn, "i": "trophy", "b": 0},
		{"n": %RestartBtn, "i": "rotate", "b": 0},
		{"n": %SettingsBtn, "i": "cog", "b": 0}
	]
	
	for c in btn_config:
		var b = c["n"]
		b.icon = load("res://addons/at-icons/control/" + c["i"] + ".svg")
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 22)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_override("font", ThemeConfig.FONT_INTER)
		b.add_theme_font_size_override("font_size", 16)
		b.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.add_theme_color_override("font_pressed_color", ThemeConfig.BRAND_PRIMARY)
		b.add_theme_color_override("font_focus_color", Color.WHITE)
		b.add_theme_constant_override("h_separation", 12)
		
		if c["b"] > 0:
			_add_badge(b, c["b"])

func _add_badge(btn: Button, count: int):
	var badge = PanelContainer.new()
	var bs = StyleBoxFlat.new()
	bs.bg_color = ThemeConfig.BRAND_PRIMARY
	bs.corner_radius_top_left = 10; bs.corner_radius_top_right = 10
	bs.corner_radius_bottom_left = 10; bs.corner_radius_bottom_right = 10
	badge.add_theme_stylebox_override("panel", bs)
	
	var lbl = Label.new()
	lbl.text = str(count)
	lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	lbl.add_theme_font_size_override("font_size", 10)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 6)
	m.add_theme_constant_override("margin_right", 6)
	m.add_theme_constant_override("margin_top", 2)
	m.add_theme_constant_override("margin_bottom", 2)
	m.add_child(lbl)
	
	badge.add_child(m)
	
	var h = HBoxContainer.new()
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.alignment = BoxContainer.ALIGNMENT_END
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var pm = MarginContainer.new()
	pm.add_theme_constant_override("margin_right", 8)
	pm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pm.add_child(badge)
	
	h.add_child(pm)
	btn.add_child(h)
