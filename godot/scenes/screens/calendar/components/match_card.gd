extends PanelContainer
class_name MatchCard

@onready var time_lbl = $Margin/VBox/TopRow/TimeLbl
@onready var comp_tag = $Margin/VBox/TopRow/CompTag
@onready var opp_lbl = $Margin/VBox/OppLbl
@onready var score_lbl = $Margin/VBox/ScoreLbl

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(match_data: Dictionary):
	time_lbl.text = match_data.get("time", "")
	time_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BOLD)
	
	var comp = match_data.get("competition", "LIGA")
	comp_tag.text = comp
	comp_tag.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	
	if comp == "LIGA":
		comp_tag.add_theme_color_override("font_color", ThemeConfig.INFO)
	else:
		comp_tag.add_theme_color_override("font_color", ThemeConfig.WARNING)
		
	var is_home = match_data.get("is_home", true)
	var prefix = "vs" if is_home else "@"
	var opp_abbr = match_data.get("away_abbr", "OPP") if is_home else match_data.get("home_abbr", "OPP")
	opp_lbl.text = "%s %s" % [prefix, opp_abbr]
	opp_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
	
	var played = match_data.get("played", false)
	var won = match_data.get("win", false)
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6; style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6; style.corner_radius_bottom_right = 6
	style.border_width_left = 1; style.border_width_top = 1; style.border_width_right = 1; style.border_width_bottom = 1
	
	if played:
		var home_score = match_data.get("score_home", 0)
		var away_score = match_data.get("score_away", 0)
		score_lbl.text = "%d-%d" % [home_score, away_score]
		score_lbl.show()
		score_lbl.add_theme_font_override("font", ThemeConfig.FONT_INTER_BLACK)
		
		if won:
			style.bg_color = Color("#064E3B") # Dark green
			style.border_color = ThemeConfig.SUCCESS
			score_lbl.add_theme_color_override("font_color", ThemeConfig.SUCCESS)
		else:
			style.bg_color = Color("#450A0A") # Dark red
			style.border_color = ThemeConfig.DANGER
			score_lbl.add_theme_color_override("font_color", ThemeConfig.DANGER)
	else:
		score_lbl.hide()
		style.bg_color = Color("#172554") # Dark blue
		style.border_color = ThemeConfig.INFO
		
	add_theme_stylebox_override("panel", style)
