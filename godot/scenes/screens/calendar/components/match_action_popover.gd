extends Control

signal play_requested(match_data)
signal sim_requested(match_data)
signal close_requested

var current_match = null

@onready var close_btn = $CenterContainer/ModalPanel/VBox/Header/Margin/HBox/CloseBtn
@onready var play_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/PlayBtn
@onready var sim_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/SimBtn

@onready var home_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/Matchup/HomeCircle/Center/HomeLbl
@onready var away_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/Matchup/AwayCircle/Center/AwayLbl
@onready var date_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/InfoGrid/DateBox/DateLbl
@onready var time_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/InfoGrid/TimeBox/TimeLbl
@onready var games_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/InfoGrid/GamesBox/GamesLbl
@onready var pred_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/Prediction/Center/PredLbl
@onready var title_lbl = $CenterContainer/ModalPanel/VBox/Header/Margin/HBox/Title
@onready var vs_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/Matchup/VSBox/VSLbl
@onready var actions_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/ActionsLbl

@onready var play_t1 = $CenterContainer/ModalPanel/VBox/Body/VBox/PlayBtn/HBox/VBox/T1
@onready var sim_t1 = $CenterContainer/ModalPanel/VBox/Body/VBox/SimBtn/HBox/VBox/T1

@onready var details_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/BottomRow/DetailsBtn
@onready var analyse_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/BottomRow/AnalyseBtn

func _ready():
	close_btn.pressed.connect(_on_close)
	play_btn.pressed.connect(_on_play)
	sim_btn.pressed.connect(_on_sim)
	
	# Apply Fonts
	var bold = ThemeConfig.FONT_INTER_BOLD
	var black = ThemeConfig.FONT_INTER_BLACK if ThemeConfig.get("FONT_INTER_BLACK") else ThemeConfig.FONT_INTER_EXTRABOLD
	
	title_lbl.add_theme_font_override("font", black)
	home_lbl.add_theme_font_override("font", black)
	away_lbl.add_theme_font_override("font", black)
	vs_lbl.add_theme_font_override("font", black)
	date_lbl.add_theme_font_override("font", bold)
	time_lbl.add_theme_font_override("font", bold)
	games_lbl.add_theme_font_override("font", bold)
	pred_lbl.add_theme_font_override("font", bold)
	actions_lbl.add_theme_font_override("font", bold)
	play_t1.add_theme_font_override("font", black)
	sim_t1.add_theme_font_override("font", black)
	details_btn.add_theme_font_override("font", bold)
	analyse_btn.add_theme_font_override("font", bold)
	
	# Close on background click
	$Overlay.gui_input.connect(_on_overlay_input)

func _on_overlay_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()

func set_match(data: Dictionary):
	current_match = data
	home_lbl.text = data.get("home_abbr", "PHX")
	away_lbl.text = data.get("away_abbr", "REC")
	date_lbl.text = data.get("date", "Ter, 18 Nov")
	time_lbl.text = data.get("time", "20h00")
	games_lbl.text = str(data.get("games_until", 0))
	pred_lbl.text = "PREVISÃO: " + str(data.get("prediction", "78%")) + " VITÓRIA"

func _on_close():
	emit_signal("close_requested")
	queue_free()

func _on_play():
	emit_signal("play_requested", current_match)

func _on_sim():
	emit_signal("sim_requested", current_match)
