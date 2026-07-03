extends PanelContainer
class_name MiniStandings

@onready var title_lbl = %Title
@onready var view_all = %ViewAll
@onready var list_container = %ListContainer
@onready var chevron_icon = %ChevronIcon
@onready var header = %Header

const TEAM_COLORS: Dictionary = {
	1: Color("#A78BFA"),
	2: Color("#10B981"),
	3: Color("#FBBF24"),
	4: Color("#3B82F6"),
	5: Color("#06B6D4"),
	6: Color("#F97316"),
	7: Color("#EC4899"),
	8: Color("#8B5CF6"),
	9: Color("#EF4444"),
	10: Color("#14B8A6"),
	11: Color("#EAB308"),
	12: Color("#6366F1"),
}

func _ready():
	_setup_styles()

func _setup_styles():
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = ThemeConfig.BG_ELEVATED
	card_style.corner_radius_top_left = 12
	card_style.corner_radius_top_right = 12
	card_style.corner_radius_bottom_left = 12
	card_style.corner_radius_bottom_right = 12
	card_style.border_color = ThemeConfig.BORDER_ACCENT_SOFT
	card_style.border_width_left = 1
	card_style.border_width_top = 1
	card_style.border_width_right = 1
	card_style.border_width_bottom = 1
	add_theme_stylebox_override("panel", card_style)

	title_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	title_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	title_lbl.add_theme_font_size_override("font_size", 11)

	view_all.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	view_all.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	view_all.add_theme_font_size_override("font_size", 9)

	chevron_icon.modulate = ThemeConfig.TEXT_MUTED

	var header_style = StyleBoxFlat.new()
	header_style.bg_color = ThemeConfig.BG_ELEVATED
	header_style.corner_radius_top_left = 12
	header_style.corner_radius_top_right = 12
	header_style.content_margin_left = 16
	header_style.content_margin_right = 16
	header_style.content_margin_top = 12
	header_style.content_margin_bottom = 12
	header.add_theme_stylebox_override("panel", header_style)

func refresh():
	for c in list_container.get_children():
		c.queue_free()

	var teams = GameManager.league.get("teams", [])
	if teams.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Nenhum dado disponivel"
		empty_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DISABLED)
		empty_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list_container.add_child(empty_lbl)
		return

	var sorted = teams.duplicate()
	sorted.sort_custom(func(a, b):
		var a_wins = a.get("wins", 0)
		var b_wins = b.get("wins", 0)
		if a_wins != b_wins:
			return a_wins > b_wins
		var a_losses = a.get("losses", 0)
		var b_losses = b.get("losses", 0)
		return a_losses < b_losses
	)

	var top6 = sorted.slice(0, min(6, sorted.size()))
	var user_id = GameManager.user_team_id

	for i in range(top6.size()):
		var t = top6[i]
		var is_user = t.get("id", 0) == user_id
		var row = _create_row(i + 1, t, is_user)
		list_container.add_child(row)

func _create_row(pos: int, t: Dictionary, is_user: bool) -> PanelContainer:
	var row = PanelContainer.new()

	var row_style = StyleBoxFlat.new()
	if is_user:
		row_style.bg_color = Color("#A78BFA22")
	else:
		row_style.bg_color = Color.TRANSPARENT
	row_style.corner_radius_top_left = 6
	row_style.corner_radius_top_right = 6
	row_style.corner_radius_bottom_left = 6
	row_style.corner_radius_bottom_right = 6
	row_style.content_margin_left = 8
	row_style.content_margin_right = 8
	row_style.content_margin_top = 8
	row_style.content_margin_bottom = 8
	row.add_theme_stylebox_override("panel", row_style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var pos_badge = PanelContainer.new()
	pos_badge.custom_minimum_size = Vector2(22, 22)
	var badge_style = StyleBoxFlat.new()
	badge_style.bg_color = Color("#10B981")
	badge_style.corner_radius_top_left = 11
	badge_style.corner_radius_top_right = 11
	badge_style.corner_radius_bottom_left = 11
	badge_style.corner_radius_bottom_right = 11
	pos_badge.add_theme_stylebox_override("panel", badge_style)

	var pos_lbl = Label.new()
	pos_lbl.text = str(pos)
	pos_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pos_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pos_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	pos_lbl.add_theme_color_override("font_color", Color.WHITE)
	pos_lbl.add_theme_font_size_override("font_size", 10)
	pos_badge.add_child(pos_lbl)

	var dot = ColorRect.new()
	dot.custom_minimum_size = Vector2(6, 6)
	var team_id = t.get("id", 0)
	dot.color = TEAM_COLORS.get(team_id, Color.WHITE)

	var team_name = t.get("name", "???")
	var team_abbr = t.get("abbreviation", "???")
	var name_lbl = Label.new()
	name_lbl.text = team_abbr + " " + team_name
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	if is_user:
		name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
		name_lbl.add_theme_color_override("font_color", Color.WHITE)
	else:
		name_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
		name_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	name_lbl.add_theme_font_size_override("font_size", 11)

	var w = t.get("wins", 0)
	var l = t.get("losses", 0)
	var wl_lbl = Label.new()
	wl_lbl.text = str(w) + "-" + str(l)
	wl_lbl.custom_minimum_size = Vector2(36, 0)
	wl_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wl_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	wl_lbl.add_theme_color_override("font_color", Color.WHITE)
	wl_lbl.add_theme_font_size_override("font_size", 11)

	var total = w + l
	var pct_str = ".000"
	if total > 0:
		pct_str = "%.3f" % (float(w) / float(total))
		pct_str = pct_str.trim_prefix("0")
	var pct_lbl = Label.new()
	pct_lbl.text = pct_str
	pct_lbl.custom_minimum_size = Vector2(40, 0)
	pct_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	pct_lbl.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	pct_lbl.add_theme_font_size_override("font_size", 11)

	hbox.add_child(pos_badge)
	hbox.add_child(dot)
	hbox.add_child(name_lbl)
	hbox.add_child(wl_lbl)
	hbox.add_child(pct_lbl)
	row.add_child(hbox)

	return row
