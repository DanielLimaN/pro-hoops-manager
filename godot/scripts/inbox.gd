extends Control

@onready var topbar_scene = preload("res://scenes/components/topbar.tscn")
const InboxItem = preload("res://scenes/ui/components/inbox_item.tscn")

var _msg_list: VBoxContainer

func _ready():
	EventBus.day_completed.connect(_on_day_completed)
	for c in get_children():
		c.queue_free()

	var bg = ColorRect.new()
	bg.color = ThemeConfig.BG_APP
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 24)
	margin.add_child(vbox)

	_build_top_bar(vbox)

	var content = HBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 16)
	vbox.add_child(content)

	_build_center_col(content)
	_build_right_col(content)

func _build_top_bar(parent: Node):
	var tb = topbar_scene.instantiate()
	tb.set_title("CAIXA DE ENTRADA")
	parent.add_child(tb)

func _build_center_col(parent: Node):
	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.size_flags_stretch_ratio = 1.0
	vb.add_theme_constant_override("separation", 24)

	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_msg_list = VBoxContainer.new()
	_msg_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_msg_list.add_theme_constant_override("separation", 8)

	var raw_msgs = GameManager.get_inbox()
	for r in raw_msgs:
		var unread = not r.get("read", false)
		var icon = "N"
		var color = ThemeConfig.BRAND_PRIMARY
		var role = str(r.get("sender_role", "")).to_lower()
		var tags = []

		if "coach" in role or "treinador" in role or "player" in role or "jogador" in role:
			icon = "?"
			color = ThemeConfig.WARNING
			if r.get("action_required", false):
				tags.append("AÇÃO")
		elif "med" in role or "médic" in role:
			icon = "+"
			color = ThemeConfig.DANGER
			tags.append("URGENTE")
		elif "diretor" in role or "presid" in role or "board" in role:
			icon = "$"
			color = ThemeConfig.SUCCESS

		var sender_name = r.get("sender_name", "")
		var subject = r.get("subject", "")
		var body_preview = "" + sender_name + ": " + str(r.get("date_received", ""))
		_msg_list.add_child(_create_msg_row(sender_name, subject, body_preview, tags, color, unread, icon))

	scroll.add_child(_msg_list)
	vb.add_child(scroll)
	parent.add_child(vb)

func _create_msg_row(sender: String, title: String, desc: String, tags: Array, color: Color, unread: bool, icon: String) -> PanelContainer:
	var p = PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s = StyleBoxFlat.new()
	s.bg_color = ThemeConfig.BG_SURFACE if unread else Color(0, 0, 0, 0)
	s.border_width_bottom = 1
	s.border_color = ThemeConfig.BORDER_SUBTLE
	p.add_theme_stylebox_override("panel", s)

	if unread:
		var hl_wrap = Control.new()
		hl_wrap.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		p.add_child(hl_wrap)
		var hl = ColorRect.new()
		hl.custom_minimum_size = Vector2(3, 0)
		hl.color = ThemeConfig.BRAND_PRIMARY
		hl.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
		hl_wrap.add_child(hl)

	var m = MarginContainer.new()
	m.add_theme_constant_override("margin_left", 24)
	m.add_theme_constant_override("margin_right", 24)
	m.add_theme_constant_override("margin_top", 16)
	m.add_theme_constant_override("margin_bottom", 16)
	p.add_child(m)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 16)
	m.add_child(hb)

	var ic = PanelContainer.new()
	ic.custom_minimum_size = Vector2(40, 40)
	ic.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var sic = StyleBoxFlat.new()
	sic.bg_color = Color(0, 0, 0, 0)
	sic.border_width_left = 2
	sic.border_width_right = 2
	sic.border_width_top = 2
	sic.border_width_bottom = 2
	sic.border_color = color
	sic.corner_radius_top_left = 20
	sic.corner_radius_bottom_right = 20
	sic.corner_radius_bottom_left = 20
	sic.corner_radius_top_right = 20
	ic.add_theme_stylebox_override("panel", sic)

	var lic = Label.new()
	lic.text = icon
	lic.add_theme_color_override("font_color", color)
	lic.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lic.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ic.add_child(lic)
	hb.add_child(ic)

	if unread:
		var dot = Panel.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.position = Vector2(36, 0)
		var sdot = StyleBoxFlat.new()
		sdot.bg_color = ThemeConfig.BRAND_PRIMARY
		sdot.corner_radius_top_left = 4
		sdot.corner_radius_bottom_right = 4
		sdot.corner_radius_bottom_left = 4
		sdot.corner_radius_top_right = 4
		dot.add_theme_stylebox_override("panel", sdot)
		ic.add_child(dot)

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 4)

	var head = HBoxContainer.new()
	var lsend = Label.new()
	lsend.text = sender
	lsend.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	lsend.add_theme_font_size_override("font_size", 11)
	head.add_child(lsend)

	var spc = Control.new()
	spc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(spc)

	var st_ic = TextureRect.new()
	st_ic.texture = load("res://addons/at-icons/control/star.svg")
	st_ic.custom_minimum_size = Vector2(12, 12)
	st_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	st_ic.modulate = ThemeConfig.WARNING
	head.add_child(st_ic)

	var ltime = Label.new()
	ltime.text = desc
	ltime.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	ltime.add_theme_font_size_override("font_size", 9)
	ltime.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	head.add_child(ltime)
	vb.add_child(head)

	var ltit = Label.new()
	ltit.text = title
	ltit.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	ltit.add_theme_font_size_override("font_size", 13)
	vb.add_child(ltit)

	if tags.size() > 0:
		var htag = HBoxContainer.new()
		htag.add_theme_constant_override("separation", 8)
		for t in tags:
			var tc = ThemeConfig.DANGER
			var pt = PanelContainer.new()
			var st = StyleBoxFlat.new()
			st.bg_color = Color(0, 0, 0, 0)
			st.border_width_left = 1
			st.border_width_right = 1
			st.border_width_top = 1
			st.border_width_bottom = 1
			st.border_color = tc
			st.corner_radius_top_left = 4
			st.corner_radius_bottom_right = 4
			st.corner_radius_bottom_left = 4
			st.corner_radius_top_right = 4
			pt.add_theme_stylebox_override("panel", st)
			var mt = MarginContainer.new()
			mt.add_theme_constant_override("margin_left", 6)
			mt.add_theme_constant_override("margin_right", 6)
			pt.add_child(mt)
			var lt = Label.new()
			lt.text = t
			lt.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
			lt.add_theme_font_size_override("font_size", 9)
			lt.add_theme_color_override("font_color", tc)
			mt.add_child(lt)
			htag.add_child(pt)
		vb.add_child(htag)

	hb.add_child(vb)
	return p

func _build_right_col(parent: Node):
	var raw_msgs = GameManager.get_inbox()
	if raw_msgs.is_empty():
		return
	var r = raw_msgs[0]

	var vb = VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vb.size_flags_stretch_ratio = 1.8
	vb.add_theme_constant_override("separation", 20)

	var panel = PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = ThemeConfig.BG_SURFACE
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_top_right = 12
	panel.add_theme_stylebox_override("panel", panel_style)

	var inner_margin = MarginContainer.new()
	inner_margin.add_theme_constant_override("margin_left", 24)
	inner_margin.add_theme_constant_override("margin_right", 24)
	inner_margin.add_theme_constant_override("margin_top", 24)
	inner_margin.add_theme_constant_override("margin_bottom", 24)

	var inner_vb = VBoxContainer.new()
	inner_vb.add_theme_constant_override("separation", 16)
	inner_vb.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var tag_header = HBoxContainer.new()
	tag_header.add_theme_constant_override("separation", 8)

	var sender_role = str(r.get("sender_role", ""))
	var tag_color = ThemeConfig.WARNING
	if "med" in sender_role or "médic" in sender_role:
		tag_color = ThemeConfig.DANGER
	elif "diretor" in sender_role or "presid" in sender_role:
		tag_color = ThemeConfig.SUCCESS

	var tag_badge = PanelContainer.new()
	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = tag_color
	tag_style.corner_radius_top_left = 4
	tag_style.corner_radius_bottom_right = 4
	tag_style.corner_radius_bottom_left = 4
	tag_style.corner_radius_top_right = 4
	tag_badge.add_theme_stylebox_override("panel", tag_style)

	var tag_margin = MarginContainer.new()
	tag_margin.add_theme_constant_override("margin_left", 8)
	tag_margin.add_theme_constant_override("margin_right", 8)
	var tag_label = Label.new()
	tag_label.text = sender_role
	tag_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	tag_label.add_theme_font_size_override("font_size", 10)
	tag_label.add_theme_color_override("font_color", Color.WHITE)
	tag_margin.add_child(tag_label)
	tag_badge.add_child(tag_margin)
	tag_header.add_child(tag_badge)

	var actions_label = Label.new()
	actions_label.text = "5 AÇÕES DISPONÍVEIS"
	actions_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	actions_label.add_theme_font_size_override("font_size", 10)
	actions_label.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	tag_header.add_child(actions_label)

	var tag_sp = Control.new()
	tag_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tag_header.add_child(tag_sp)
	inner_vb.add_child(tag_header)

	var subject_label = Label.new()
	subject_label.text = r.get("subject", "")
	subject_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	subject_label.add_theme_font_size_override("font_size", 28)
	subject_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	subject_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inner_vb.add_child(subject_label)

	var sender_hb = HBoxContainer.new()
	sender_hb.add_theme_constant_override("separation", 12)

	var avatar = PanelContainer.new()
	avatar.custom_minimum_size = Vector2(48, 48)
	var avatar_style = StyleBoxFlat.new()
	avatar_style.bg_color = ThemeConfig.BRAND_PRIMARY
	avatar_style.corner_radius_top_left = 24
	avatar_style.corner_radius_bottom_right = 24
	avatar_style.corner_radius_bottom_left = 24
	avatar_style.corner_radius_top_right = 24
	avatar.add_theme_stylebox_override("panel", avatar_style)

	var avatar_letter = Label.new()
	avatar_letter.text = str(r.get("sender_name", "?"))[0]
	avatar_letter.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	avatar_letter.add_theme_font_size_override("font_size", 20)
	avatar_letter.add_theme_color_override("font_color", Color.WHITE)
	avatar_letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar_letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_child(avatar_letter)
	sender_hb.add_child(avatar)

	var sender_vb = VBoxContainer.new()
	var sender_name_label = Label.new()
	sender_name_label.text = r.get("sender_name", "")
	sender_name_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	sender_name_label.add_theme_font_size_override("font_size", 14)
	sender_name_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	sender_vb.add_child(sender_name_label)

	var sender_meta = Label.new()
	sender_meta.text = r.get("sender_email", "") + " · " + str(r.get("date_received", ""))
	sender_meta.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	sender_meta.add_theme_font_size_override("font_size", 12)
	sender_meta.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	sender_vb.add_child(sender_meta)
	sender_hb.add_child(sender_vb)

	var ovr_label = Label.new()
	ovr_label.text = "OVR"
	ovr_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	ovr_label.add_theme_font_size_override("font_size", 11)
	ovr_label.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	sender_hb.add_child(ovr_label)

	inner_vb.add_child(sender_hb)

	var body_label = Label.new()
	body_label.text = r.get("body", "")
	body_label.add_theme_font_override("font", ThemeConfig.FONT_INTER)
	body_label.add_theme_font_size_override("font_size", 14)
	body_label.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inner_vb.add_child(body_label)

	var stats_box = PanelContainer.new()
	var stats_style = StyleBoxFlat.new()
	stats_style.bg_color = Color(0, 0, 0, 0)
	stats_style.border_width_left = 1
	stats_style.border_width_right = 1
	stats_style.border_width_top = 1
	stats_style.border_width_bottom = 1
	stats_style.border_color = ThemeConfig.BORDER_SUBTLE
	stats_style.corner_radius_top_left = 8
	stats_style.corner_radius_bottom_right = 8
	stats_style.corner_radius_bottom_left = 8
	stats_style.corner_radius_top_right = 8
	stats_box.add_theme_stylebox_override("panel", stats_style)

	var stats_margin = MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 16)
	stats_margin.add_theme_constant_override("margin_right", 16)
	stats_margin.add_theme_constant_override("margin_top", 12)
	stats_margin.add_theme_constant_override("margin_bottom", 12)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 4
	stats_grid.add_theme_constant_override("h_separation", 24)
	stats_grid.add_theme_constant_override("v_separation", 12)

	var stat_headers = ["MIN", "PTS", "REB", "AST"]
	var stat_values = [str(r.get("minutes", 0)), str(r.get("points", 0)), str(r.get("rebounds", 0)), str(r.get("assists", 0))]
	for i in range(4):
		var svb = VBoxContainer.new()
		svb.add_theme_constant_override("separation", 2)
		var sh = Label.new()
		sh.text = stat_headers[i]
		sh.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		sh.add_theme_font_size_override("font_size", 10)
		sh.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
		svb.add_child(sh)
		var sv = Label.new()
		sv.text = stat_values[i]
		sv.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		sv.add_theme_font_size_override("font_size", 20)
		sv.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
		svb.add_child(sv)
		stats_grid.add_child(svb)

	stats_margin.add_child(stats_grid)
	stats_box.add_child(stats_margin)
	inner_vb.add_child(stats_box)

	if r.get("action_required", false):
		var actions_header = Label.new()
		actions_header.text = "AÇÕES DISPONÍVEIS"
		actions_header.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		actions_header.add_theme_font_size_override("font_size", 14)
		actions_header.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
		inner_vb.add_child(actions_header)

		var action_grid = GridContainer.new()
		action_grid.columns = 4
		action_grid.add_theme_constant_override("h_separation", 8)
		action_grid.add_theme_constant_override("v_separation", 8)

		var actions = [
			{ "label": "ACEITAR", "color": ThemeConfig.SUCCESS, "icon": "check" },
			{ "label": "NEGOCIAR", "color": ThemeConfig.WARNING, "icon": "refresh" },
			{ "label": "RECUSAR", "color": ThemeConfig.DANGER, "icon": "x" },
			{ "label": "ADIAR", "color": ThemeConfig.INFO, "icon": "clock" },
		]
		for a in actions:
			var action_card = PanelContainer.new()
			var ac_style = StyleBoxFlat.new()
			ac_style.bg_color = Color(0, 0, 0, 0)
			ac_style.border_width_left = 1
			ac_style.border_width_right = 1
			ac_style.border_width_top = 1
			ac_style.border_width_bottom = 1
			ac_style.border_color = a["color"]
			ac_style.corner_radius_top_left = 8
			ac_style.corner_radius_bottom_right = 8
			ac_style.corner_radius_bottom_left = 8
			ac_style.corner_radius_top_right = 8
			action_card.add_theme_stylebox_override("panel", ac_style)

			var ac_margin = MarginContainer.new()
			ac_margin.add_theme_constant_override("margin_left", 12)
			ac_margin.add_theme_constant_override("margin_right", 12)
			ac_margin.add_theme_constant_override("margin_top", 8)
			ac_margin.add_theme_constant_override("margin_bottom", 8)

			var ac_vb = VBoxContainer.new()
			ac_vb.add_theme_constant_override("separation", 4)
			ac_vb.custom_minimum_size = Vector2(100, 60)

			var ac_icon = Label.new()
			ac_icon.text = a["icon"]
			ac_icon.add_theme_color_override("font_color", a["color"])
			ac_icon.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
			ac_icon.add_theme_font_size_override("font_size", 14)
			ac_vb.add_child(ac_icon)

			var ac_label = Label.new()
			ac_label.text = a["label"]
			ac_label.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
			ac_label.add_theme_font_size_override("font_size", 11)
			ac_label.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
			ac_vb.add_child(ac_label)

			ac_margin.add_child(ac_vb)
			action_card.add_child(ac_margin)
			action_grid.add_child(action_card)

		inner_vb.add_child(action_grid)

	inner_margin.add_child(inner_vb)
	panel.add_child(inner_margin)
	vb.add_child(panel)
	parent.add_child(vb)

func _on_day_completed(summary: Dictionary):
	var events = summary.get("events", [])
	for evt in events:
		var item = InboxItem.instantiate()
		item.set_data(evt)
		_msg_list.add_child(item)
		_msg_list.move_child(item, 0)
