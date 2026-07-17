extends SceneTree

func _init():
	# Inbox Row
	var root = MarginContainer.new()
	root.name = "DashboardInboxRow"
	
	var btn = Button.new()
	btn.name = "BackgroundButton"
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var n_style = StyleBoxEmpty.new()
	var h_style = StyleBoxFlat.new()
	h_style.bg_color = Color("#0f0720") # BG_ELEVATED
	h_style.corner_radius_top_left = 6; h_style.corner_radius_bottom_right = 6; h_style.corner_radius_top_right = 6; h_style.corner_radius_bottom_left = 6
	btn.add_theme_stylebox_override("normal", n_style)
	btn.add_theme_stylebox_override("hover", h_style)
	btn.add_theme_stylebox_override("pressed", h_style)
	btn.add_theme_stylebox_override("focus", n_style)
	root.add_child(btn)
	btn.owner = root
	
	var pad = MarginContainer.new()
	pad.name = "Padding"
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_theme_constant_override("margin_left", 16)
	pad.add_theme_constant_override("margin_right", 16)
	pad.add_theme_constant_override("margin_top", 12)
	pad.add_theme_constant_override("margin_bottom", 12)
	root.add_child(pad)
	pad.owner = root
	
	var row = HBoxContainer.new()
	row.name = "HBox"
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 16)
	pad.add_child(row)
	row.owner = root
	
	var ic_pnl = PanelContainer.new()
	ic_pnl.name = "IconPanel"
	ic_pnl.unique_name_in_owner = true
	ic_pnl.custom_minimum_size = Vector2(40, 40)
	ic_pnl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ic_pnl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ics = StyleBoxFlat.new()
	ics.bg_color = Color("#172554")
	ics.corner_radius_top_left = 8; ics.corner_radius_bottom_right = 8; ics.corner_radius_top_right = 8; ics.corner_radius_bottom_left = 8
	ic_pnl.add_theme_stylebox_override("panel", ics)
	row.add_child(ic_pnl)
	ic_pnl.owner = root
	
	var ic_c = CenterContainer.new()
	ic_c.name = "Center"
	ic_c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ic_pnl.add_child(ic_c)
	ic_c.owner = root
	
	var ic_tex = TextureRect.new()
	ic_tex.name = "Icon"
	ic_tex.unique_name_in_owner = true
	ic_tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic_tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ic_tex.custom_minimum_size = Vector2(20, 20)
	ic_tex.modulate = Color("#3B82F6")
	ic_c.add_child(ic_tex)
	ic_tex.owner = root
	
	var text_col = VBoxContainer.new()
	text_col.name = "TextCol"
	text_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(text_col)
	text_col.owner = root
	
	var title = Label.new()
	title.name = "Title"
	title.unique_name_in_owner = true
	title.text = "Message Title"
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 13)
	text_col.add_child(title)
	title.owner = root
	
	var sub = Label.new()
	sub.name = "Subtitle"
	sub.unique_name_in_owner = true
	sub.text = "Sender - preview..."
	sub.add_theme_color_override("font_color", Color("#94A3B8")) # TEXT_MUTED
	sub.add_theme_font_size_override("font_size", 12)
	text_col.add_child(sub)
	sub.owner = root
	
	var r_col = VBoxContainer.new()
	r_col.name = "RightCol"
	r_col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r_col.alignment = BoxContainer.ALIGNMENT_CENTER
	r_col.add_theme_constant_override("separation", 6)
	row.add_child(r_col)
	r_col.owner = root
	
	var t_lbl = Label.new()
	t_lbl.name = "Time"
	t_lbl.unique_name_in_owner = true
	t_lbl.text = "10:00"
	t_lbl.add_theme_color_override("font_color", Color("#94A3B8"))
	t_lbl.add_theme_font_size_override("font_size", 11)
	t_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	r_col.add_child(t_lbl)
	t_lbl.owner = root
	
	var d_pnl = PanelContainer.new()
	d_pnl.name = "UnreadDot"
	d_pnl.unique_name_in_owner = true
	d_pnl.custom_minimum_size = Vector2(6, 6)
	d_pnl.size_flags_horizontal = Control.SIZE_SHRINK_END
	var ds = StyleBoxFlat.new()
	ds.bg_color = Color("#A78BFA") # BRAND_PRIMARY
	ds.corner_radius_top_left = 3; ds.corner_radius_bottom_right = 3; ds.corner_radius_top_right = 3; ds.corner_radius_bottom_left = 3
	d_pnl.add_theme_stylebox_override("panel", ds)
	r_col.add_child(d_pnl)
	d_pnl.owner = root
	
	var pack_inbox = PackedScene.new()
	pack_inbox.pack(root)
	ResourceSaver.save(pack_inbox, "res://scenes/ui/dashboard/components/dashboard_inbox_row.tscn")
	
	# Recent Row
	var rr = MarginContainer.new()
	rr.name = "DashboardRecentRow"
	
	var rr_pad = MarginContainer.new()
	rr_pad.name = "Padding"
	rr_pad.add_theme_constant_override("margin_left", 8)
	rr_pad.add_theme_constant_override("margin_right", 8)
	rr.add_child(rr_pad)
	rr_pad.owner = rr
	
	var r_row = HBoxContainer.new()
	r_row.name = "HBox"
	r_row.add_theme_constant_override("separation", 16)
	rr_pad.add_child(r_row)
	r_row.owner = rr
	
	var badge = PanelContainer.new()
	badge.name = "ResultBadge"
	badge.unique_name_in_owner = true
	badge.custom_minimum_size = Vector2(24, 24)
	badge.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color("#06030E")
	bs.corner_radius_top_left = 6; bs.corner_radius_bottom_right = 6; bs.corner_radius_top_right = 6; bs.corner_radius_bottom_left = 6
	bs.border_width_left = 1; bs.border_width_top = 1; bs.border_width_right = 1; bs.border_width_bottom = 1
	bs.border_color = Color("#10B981") # SUCCESS
	badge.add_theme_stylebox_override("panel", bs)
	r_row.add_child(badge)
	badge.owner = rr
	
	var bl = Label.new()
	bl.name = "ResultLabel"
	bl.unique_name_in_owner = true
	bl.text = "V"
	bl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bl.add_theme_color_override("font_color", Color("#10B981"))
	bl.add_theme_font_size_override("font_size", 12)
	badge.add_child(bl)
	bl.owner = rr
	
	var ha = Label.new()
	ha.name = "HomeAwayLabel"
	ha.unique_name_in_owner = true
	ha.text = "vs"
	ha.custom_minimum_size = Vector2(16, 0)
	ha.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ha.add_theme_color_override("font_color", Color("#94A3B8"))
	ha.add_theme_font_size_override("font_size", 12)
	r_row.add_child(ha)
	ha.owner = rr
	
	var opp_lbl = Label.new()
	opp_lbl.name = "OpponentLabel"
	opp_lbl.unique_name_in_owner = true
	opp_lbl.text = "Opponent"
	opp_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	opp_lbl.add_theme_color_override("font_color", Color.WHITE)
	opp_lbl.add_theme_font_size_override("font_size", 13)
	r_row.add_child(opp_lbl)
	opp_lbl.owner = rr
	
	var score_lbl = Label.new()
	score_lbl.name = "ScoreLabel"
	score_lbl.unique_name_in_owner = true
	score_lbl.text = "0-0"
	score_lbl.add_theme_color_override("font_color", Color.WHITE)
	score_lbl.add_theme_font_size_override("font_size", 13)
	r_row.add_child(score_lbl)
	score_lbl.owner = rr
	
	var diff_lbl = Label.new()
	diff_lbl.name = "DiffLabel"
	diff_lbl.unique_name_in_owner = true
	diff_lbl.text = "+0"
	diff_lbl.custom_minimum_size = Vector2(24, 0)
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	diff_lbl.add_theme_color_override("font_color", Color("#10B981"))
	diff_lbl.add_theme_font_size_override("font_size", 12)
	r_row.add_child(diff_lbl)
	diff_lbl.owner = rr
	
	var pack_recent = PackedScene.new()
	pack_recent.pack(rr)
	ResourceSaver.save(pack_recent, "res://scenes/ui/dashboard/components/dashboard_recent_row.tscn")
	
	# Fix dashboard.tscn structure for Inbox and Recent Panel
	var db = load("res://scenes/ui/dashboard/dashboard.tscn")
	var instance = db.instantiate()
	var right_col = instance.get_node("Margin/VBox/MainGrid/RightCol")
	
	# Inbox
	var inbox = right_col.get_node("InboxPanel")
	for c in inbox.get_children():
		c.free()
	
	var in_m = MarginContainer.new()
	in_m.name = "Margin"
	in_m.add_theme_constant_override("margin_left", 32)
	in_m.add_theme_constant_override("margin_top", 24)
	in_m.add_theme_constant_override("margin_right", 32)
	in_m.add_theme_constant_override("margin_bottom", 24)
	inbox.add_child(in_m)
	in_m.owner = instance
	
	var in_v = VBoxContainer.new()
	in_v.name = "VBox"
	in_v.add_theme_constant_override("separation", 12)
	in_m.add_child(in_v)
	in_v.owner = instance
	
	var in_h = HBoxContainer.new()
	in_h.name = "Header"
	in_h.add_theme_constant_override("separation", 12)
	in_v.add_child(in_h)
	in_h.owner = instance
	
	var in_ic = TextureRect.new()
	in_ic.name = "Icon"
	in_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	in_ic.custom_minimum_size = Vector2(16, 16)
	in_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	in_ic.modulate = Color("#A78BFA")
	var tx = load("res://addons/at-icons/control/mailbox.svg")
	if tx:
		in_ic.texture = tx
	in_h.add_child(in_ic)
	in_ic.owner = instance
	
	var in_lbl = Label.new()
	in_lbl.name = "Title"
	in_lbl.text = "CAIXA DE ENTRADA"
	in_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	in_lbl.add_theme_color_override("font_color", Color("#A78BFA"))
	in_lbl.add_theme_constant_override("letter_spacing", 2)
	in_h.add_child(in_lbl)
	in_lbl.owner = instance
	
	var in_pill = Label.new()
	in_pill.name = "UnreadBadge"
	in_pill.unique_name_in_owner = true
	in_pill.text = " 12 NOVAS "
	var ps = StyleBoxFlat.new()
	ps.bg_color = Color("#EF4444")
	ps.corner_radius_top_left = 6; ps.corner_radius_bottom_right = 6; ps.corner_radius_top_right = 6; ps.corner_radius_bottom_left = 6
	in_pill.add_theme_stylebox_override("normal", ps)
	in_pill.add_theme_font_size_override("font_size", 11)
	in_h.add_child(in_pill)
	in_pill.owner = instance
	
	var in_div = ColorRect.new()
	in_div.name = "Divider"
	in_div.custom_minimum_size = Vector2(0, 1)
	in_div.color = Color("#2D1B4E")
	in_v.add_child(in_div)
	in_div.owner = instance
	
	var in_sc = ScrollContainer.new()
	in_sc.name = "Scroll"
	in_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	in_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	in_v.add_child(in_sc)
	in_sc.owner = instance
	
	var in_list = VBoxContainer.new()
	in_list.name = "InboxList"
	in_list.unique_name_in_owner = true
	in_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	in_list.add_theme_constant_override("separation", 16)
	in_sc.add_child(in_list)
	in_list.owner = instance
	
	# Recent
	var rec = right_col.get_node("RecentPanel")
	for c in rec.get_children():
		c.free()
		
	var r_m = MarginContainer.new()
	r_m.name = "Margin"
	r_m.add_theme_constant_override("margin_left", 32)
	r_m.add_theme_constant_override("margin_top", 24)
	r_m.add_theme_constant_override("margin_right", 32)
	r_m.add_theme_constant_override("margin_bottom", 24)
	rec.add_child(r_m)
	r_m.owner = instance
	
	var r_v = VBoxContainer.new()
	r_v.name = "VBox"
	r_v.add_theme_constant_override("separation", 16)
	r_m.add_child(r_v)
	r_v.owner = instance
	
	var r_h = HBoxContainer.new()
	r_h.name = "Header"
	r_v.add_child(r_h)
	r_h.owner = instance
	
	var r_lbl = Label.new()
	r_lbl.name = "Title"
	r_lbl.text = "ÚLTIMOS RESULTADOS"
	r_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_lbl.add_theme_color_override("font_color", Color("#A78BFA"))
	r_lbl.add_theme_constant_override("letter_spacing", 2)
	r_lbl.add_theme_font_size_override("font_size", 12)
	r_h.add_child(r_lbl)
	r_lbl.owner = instance
	
	var r_form = HBoxContainer.new()
	r_form.name = "FormBox"
	r_form.unique_name_in_owner = true
	r_form.add_theme_constant_override("separation", 4)
	r_h.add_child(r_form)
	r_form.owner = instance
	
	var r_div = ColorRect.new()
	r_div.name = "Divider"
	r_div.custom_minimum_size = Vector2(0, 1)
	r_div.color = Color("#2D1B4E")
	r_v.add_child(r_div)
	r_div.owner = instance
	
	var r_sc = ScrollContainer.new()
	r_sc.name = "Scroll"
	r_sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	r_sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	r_v.add_child(r_sc)
	r_sc.owner = instance
	
	var r_list = VBoxContainer.new()
	r_list.name = "RecentList"
	r_list.unique_name_in_owner = true
	r_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_list.add_theme_constant_override("separation", 24)
	r_sc.add_child(r_list)
	r_list.owner = instance
	
	var pack_db = PackedScene.new()
	pack_db.pack(instance)
	ResourceSaver.save(pack_db, "res://scenes/ui/dashboard/dashboard.tscn")

	quit()
