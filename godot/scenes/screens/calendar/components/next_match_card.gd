extends PanelContainer
class_name NextMatchCard

@onready var date_lbl = %DateLbl
@onready var tag_text = %TagText
@onready var comp_tag = %CompTag
@onready var home_abbr = %HomeAbbr
@onready var home_name = %HomeName
@onready var home_record = %HomeRecord
@onready var home_badge = %HomeBadge
@onready var away_abbr = %AwayAbbr
@onready var away_name = %AwayName
@onready var away_record = %AwayRecord
@onready var away_badge = %AwayBadge
@onready var home_away_badge = %HomeAwayBadge
@onready var badge_text = %BadgeText
@onready var vs_lbl = %VSLbl
@onready var pred_lbl = %PredLabel
@onready var pred_value = %PredValue
@onready var pred_row = %PredictionRow
@onready var bars = [
	%Bar0, %Bar1, %Bar2, %Bar3, %Bar4
]
@onready var play_btn = %PlayBtn
@onready var date_icon = %DateIcon

var _match_data: Dictionary = {}

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

	date_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	date_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_SECONDARY)
	date_lbl.add_theme_font_size_override("font_size", 11)

	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = Color("#3B82F628")
	tag_style.border_color = Color("#3B82F660")
	tag_style.border_width_left = 1
	tag_style.border_width_top = 1
	tag_style.border_width_right = 1
	tag_style.border_width_bottom = 1
	tag_style.corner_radius_top_left = 4
	tag_style.corner_radius_top_right = 4
	tag_style.corner_radius_bottom_left = 4
	tag_style.corner_radius_bottom_right = 4
	comp_tag.add_theme_stylebox_override("panel", tag_style)

	tag_text.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	tag_text.add_theme_color_override("font_color", ThemeConfig.INFO)
	tag_text.add_theme_font_size_override("font_size", 8)
	tag_text.add_theme_constant_override("letter_spacing", 1)

	var home_badge_style = StyleBoxFlat.new()
	home_badge_style.bg_color = ThemeConfig.BRAND_DEEP
	home_badge_style.border_color = ThemeConfig.BRAND_DARK
	home_badge_style.border_width_left = 2
	home_badge_style.border_width_top = 2
	home_badge_style.border_width_right = 2
	home_badge_style.border_width_bottom = 2
	home_badge_style.corner_radius_top_left = 28
	home_badge_style.corner_radius_top_right = 28
	home_badge_style.corner_radius_bottom_left = 28
	home_badge_style.corner_radius_bottom_right = 28
	home_badge.add_theme_stylebox_override("panel", home_badge_style)

	home_abbr.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	home_abbr.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	home_abbr.add_theme_font_size_override("font_size", 14)
	home_abbr.add_theme_constant_override("letter_spacing", 0.5)

	home_name.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	home_name.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	home_name.add_theme_font_size_override("font_size", 11)
	home_name.add_theme_constant_override("letter_spacing", 0.5)

	home_record.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	home_record.add_theme_color_override("font_color", ThemeConfig.BRAND_PRIMARY)
	home_record.add_theme_font_size_override("font_size", 9)

	var away_badge_style = StyleBoxFlat.new()
	away_badge_style.bg_color = Color("#DC2626")
	away_badge_style.border_color = Color("#7F1D1D")
	away_badge_style.border_width_left = 2
	away_badge_style.border_width_top = 2
	away_badge_style.border_width_right = 2
	away_badge_style.border_width_bottom = 2
	away_badge_style.corner_radius_top_left = 28
	away_badge_style.corner_radius_top_right = 28
	away_badge_style.corner_radius_bottom_left = 28
	away_badge_style.corner_radius_bottom_right = 28
	away_badge.add_theme_stylebox_override("panel", away_badge_style)

	away_abbr.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	away_abbr.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	away_abbr.add_theme_font_size_override("font_size", 14)
	away_abbr.add_theme_constant_override("letter_spacing", 0.5)

	away_name.add_theme_font_override("font", ThemeConfig.FONT_INTER_EXTRABOLD)
	away_name.add_theme_color_override("font_color", ThemeConfig.TEXT_PRIMARY)
	away_name.add_theme_font_size_override("font_size", 11)
	away_name.add_theme_constant_override("letter_spacing", 0.5)

	away_record.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	away_record.add_theme_color_override("font_color", ThemeConfig.TEXT_MUTED)
	away_record.add_theme_font_size_override("font_size", 9)

	var badge_bg = StyleBoxFlat.new()
	badge_bg.bg_color = ThemeConfig.BRAND_PRIMARY
	badge_bg.corner_radius_top_left = 3
	badge_bg.corner_radius_top_right = 3
	badge_bg.corner_radius_bottom_left = 3
	badge_bg.corner_radius_bottom_right = 3
	home_away_badge.add_theme_stylebox_override("panel", badge_bg)

	badge_text.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	badge_text.add_theme_color_override("font_color", Color("#0B0514"))
	badge_text.add_theme_font_size_override("font_size", 8)
	badge_text.add_theme_constant_override("letter_spacing", 1)

	vs_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	vs_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DISABLED)
	vs_lbl.add_theme_font_size_override("font_size", 18)
	vs_lbl.add_theme_constant_override("letter_spacing", 1)

	var pred_style = StyleBoxFlat.new()
	pred_style.bg_color = Color("#0B0514AA")
	pred_style.corner_radius_top_left = 8
	pred_style.corner_radius_top_right = 8
	pred_style.corner_radius_bottom_left = 8
	pred_style.corner_radius_bottom_right = 8
	pred_row.add_theme_stylebox_override("panel", pred_style)

	pred_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	pred_lbl.add_theme_color_override("font_color", ThemeConfig.TEXT_DISABLED)
	pred_lbl.add_theme_font_size_override("font_size", 8)
	pred_lbl.add_theme_constant_override("letter_spacing", 1)

	pred_value.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	pred_value.add_theme_font_size_override("font_size", 11)

	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = ThemeConfig.BRAND_DEEP
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	btn_style.border_color = ThemeConfig.BRAND_PRIMARY
	btn_style.border_width_left = 1
	btn_style.border_width_top = 1
	btn_style.border_width_right = 1
	btn_style.border_width_bottom = 1
	play_btn.add_theme_stylebox_override("normal", btn_style)

	var h_style = btn_style.duplicate()
	h_style.bg_color = ThemeConfig.BRAND_PRIMARY
	play_btn.add_theme_stylebox_override("hover", h_style)
	play_btn.add_theme_stylebox_override("pressed", h_style)

	play_btn.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)

	date_icon.modulate = ThemeConfig.TEXT_SECONDARY

	play_btn.pressed.connect(_on_play)

func setup(data: Dictionary) -> void:
	_match_data = data
	var home = data.get("home_team", {})
	var away = data.get("away_team", {})
	var is_home = data.get("is_home", true)
	var pred = data.get("prediction", 0.5)
	var is_playoff = data.get("is_playoff", false)

	var day_names = ["DOM", "SEG", "TER", "QUA", "QUI", "SEX", "SAB"]
	var month_names = [
		"Janeiro", "Fevereiro", "Marco", "Abril",
		"Maio", "Junho", "Julho", "Agosto",
		"Setembro", "Outubro", "Novembro", "Dezembro"
	]

	var day = data.get("day", 1)
	var month = data.get("month", 1)
	var year = data.get("year", 2025)
	var time_str = data.get("time", "20h00")

	var weekday = _compute_weekday(year, month, day)
	var day_name = day_names[weekday] if weekday >= 0 and weekday < day_names.size() else "???"
	var month_name = month_names[month - 1] if month >= 1 and month <= 12 else "???"

	date_lbl.text = "%s, %d de %s - %s" % [day_name, day, month_name, time_str]

	if is_playoff:
		var phase = data.get("phase_label", "PLAYOFFS")
		tag_text.text = phase
		tag_text.add_theme_color_override("font_color", ThemeConfig.WARNING)
		var tag_style = StyleBoxFlat.new()
		tag_style.bg_color = Color("#FBBF2428")
		tag_style.border_color = Color("#FBBF2460")
		tag_style.border_width_left = 1
		tag_style.border_width_top = 1
		tag_style.border_width_right = 1
		tag_style.border_width_bottom = 1
		tag_style.corner_radius_top_left = 4
		tag_style.corner_radius_top_right = 4
		tag_style.corner_radius_bottom_left = 4
		tag_style.corner_radius_bottom_right = 4
		comp_tag.add_theme_stylebox_override("panel", tag_style)
	else:
		tag_text.text = "LIGA"
		tag_text.add_theme_color_override("font_color", ThemeConfig.INFO)

	var home_team_abbr = home.get("abbr", "???")
	var home_team_name = home.get("name", "???")
	var home_w = home.get("wins", 0)
	var home_l = home.get("losses", 0)
	var home_pos = home.get("position", 0)

	var away_team_abbr = away.get("abbr", "???")
	var away_team_name = away.get("name", "???")
	var away_w = away.get("wins", 0)
	var away_l = away.get("losses", 0)
	var away_pos = away.get("position", 0)

	if is_home:
		home_abbr.text = home_team_abbr
		home_name.text = home_team_name
		home_record.text = "%d-%d - %do" % [home_w, home_l, home_pos]
		away_abbr.text = away_team_abbr
		away_name.text = away_team_name
		away_record.text = "%d-%d - %do" % [away_w, away_l, away_pos]
		badge_text.text = "CASA"
	else:
		home_abbr.text = away_team_abbr
		home_name.text = away_team_name
		home_record.text = "%d-%d - %do" % [away_w, away_l, away_pos]
		away_abbr.text = home_team_abbr
		away_name.text = home_team_name
		away_record.text = "%d-%d - %do" % [home_w, home_l, home_pos]
		badge_text.text = "FORA"

	_setup_prediction(pred)

func _setup_prediction(pred: float) -> void:
	var active_bars = roundi(pred * 5.0)
	active_bars = clampi(active_bars, 0, 5)

	if pred >= 0.8:
		pred_value.text = "Vitoria quase certa"
		pred_value.add_theme_color_override("font_color", ThemeConfig.SUCCESS)
	elif pred >= 0.6:
		pred_value.text = "Vitoria provavel"
		pred_value.add_theme_color_override("font_color", ThemeConfig.SUCCESS)
	elif pred >= 0.4:
		pred_value.text = "Jogo equilibrado"
		pred_value.add_theme_color_override("font_color", ThemeConfig.WARNING)
	elif pred >= 0.2:
		pred_value.text = "Derrota provavel"
		pred_value.add_theme_color_override("font_color", ThemeConfig.DANGER)
	else:
		pred_value.text = "Derrota quase certa"
		pred_value.add_theme_color_override("font_color", ThemeConfig.DANGER)

	var green = ThemeConfig.SUCCESS
	var dark = Color("#2D1B4E")
	for i in range(5):
		if i < active_bars:
			bars[i].color = green
		else:
			bars[i].color = dark

func _compute_weekday(year: int, month: int, day: int) -> int:
	var date = {"year": year, "month": month, "day": day, "hour": 12, "minute": 0, "second": 0}
	var unix = Time.get_unix_time_from_datetime_dict(date)
	var dt = Time.get_datetime_dict_from_unix_time(unix)
	return dt.get("weekday", 0)

func _on_play() -> void:
	if _match_data.is_empty():
		get_tree().change_scene_to_file("res://scenes/match.tscn")
		return
	var home_id = _match_data.get("home_team_id", 1)
	var away_id = _match_data.get("away_team_id", 2)
	GameManager.pending_home_id = home_id
	GameManager.pending_away_id = away_id
	get_tree().change_scene_to_file("res://scenes/match.tscn")
