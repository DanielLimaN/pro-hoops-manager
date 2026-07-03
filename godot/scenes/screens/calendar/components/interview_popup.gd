extends Control

signal close_requested

var event_data: Dictionary = {}
var selected_player_id: int = 0

@onready var ctx_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/ContextLbl
@onready var feedback_lbl = $CenterContainer/ModalPanel/VBox/Body/VBox/FeedbackLbl
@onready var praise_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/Answers/PraiseBtn
@onready var criticize_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/Answers/CriticizeBtn
@onready var pro_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/Answers/ProBtn
@onready var player_select = $CenterContainer/ModalPanel/VBox/Body/VBox/PlayerSelect
@onready var confirm_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/ConfirmBtn
@onready var close_btn = $CenterContainer/ModalPanel/VBox/Body/VBox/CloseBtn

func _ready():
	var black = ThemeConfig.FONT_INTER_BLACK if ThemeConfig.get("FONT_INTER_BLACK") else ThemeConfig.FONT_INTER_EXTRABOLD
	var bold = ThemeConfig.FONT_INTER_BOLD

	$CenterContainer/ModalPanel/VBox/Header/Margin/HBox/Title.add_theme_font_override("font", black)
	ctx_lbl.add_theme_font_override("font", bold)

	praise_btn.pressed.connect(_on_praise)
	criticize_btn.pressed.connect(_on_criticize)
	pro_btn.pressed.connect(_on_pro)
	confirm_btn.pressed.connect(_on_confirm)
	close_btn.pressed.connect(_on_close)
	$Overlay.gui_input.connect(_on_overlay_input)

	player_select.visible = false
	confirm_btn.visible = false
	feedback_lbl.visible = false
	confirm_btn.disabled = true

func set_event(data: Dictionary):
	event_data = data
	var opp = data.get("description", "Pós @OPP")
	ctx_lbl.text = "Você participou de uma entrevista.\n" + opp.replace("Pós @", "Entrevista contra ")
	_populate_players()

func _populate_players():
	player_select.clear()
	player_select.add_item("Selecione um jogador...", -1)
	var team = GameManager.get_user_team()
	if team.is_empty():
		player_select.add_item("(time não encontrado)", 0)
		return
	var players = team.get("players", [])
	var idx = 1
	for p in players:
		var pid = p.get("id", 0)
		var name = p.get("first_name", "") + " " + p.get("last_name", "")
		var pos = p.get("position", "")
		player_select.add_item(name + " (" + pos + ")", pid)
		idx += 1
	player_select.selected = -1

func _on_praise():
	player_select.visible = false
	_clear_selection_states()
	praise_btn.modulate = Color(0.5, 1, 0.5, 1)
	confirm_btn.visible = true
	confirm_btn.disabled = false

func _on_criticize():
	_clear_selection_states()
	criticize_btn.modulate = Color(1, 0.5, 0.5, 1)
	player_select.visible = true
	confirm_btn.visible = false
	confirm_btn.disabled = true

func _on_pro():
	player_select.visible = false
	_clear_selection_states()
	pro_btn.modulate = Color(0.5, 0.7, 1, 1)
	confirm_btn.visible = true
	confirm_btn.disabled = false

func _clear_selection_states():
	praise_btn.modulate = Color.WHITE
	criticize_btn.modulate = Color.WHITE
	pro_btn.modulate = Color.WHITE

func _on_confirm():
	var answer_id = ""
	var target_id = 0

	if praise_btn.modulate != Color.WHITE:
		answer_id = "PRAISE_TEAM"
	elif criticize_btn.modulate != Color.WHITE:
		answer_id = "CRITICIZE_PLAYER"
		target_id = player_select.get_selected_id()
		if target_id <= 0:
			feedback_lbl.text = "Selecione um jogador para criticar."
			feedback_lbl.visible = true
			return
	else:
		answer_id = "PROFESSIONAL"

	var result = SimulationBridge.submit_interview_answer(answer_id, target_id)
	var msg = result.get("message", "Resposta registrada.")
	feedback_lbl.text = msg
	feedback_lbl.visible = true
	confirm_btn.visible = false
	confirm_btn.disabled = true
	player_select.visible = false

	EventBus.inbox_received.emit({
		"event_type": "interview_feedback",
		"title": "Entrevista Pós-Jogo",
		"body": msg,
		"severity": "info",
		"sender_role": "Departamento de Imprensa",
		"sender_name": "Assessoria de Comunicação"
	})

	if not event_data.is_empty():
		EventManager.complete_event(event_data.get("id", 0), true)

	await get_tree().create_timer(2.0).timeout
	_on_close()

func _on_close():
	emit_signal("close_requested")
	queue_free()

func _on_overlay_input(event: InputEvent):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_close()
