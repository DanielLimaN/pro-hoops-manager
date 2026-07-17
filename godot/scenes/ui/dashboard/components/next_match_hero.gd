extends PanelContainer

signal simulate_requested

func _ready() -> void:
	%SimBtn.pressed.connect(func(): emit_signal("simulate_requested"))

func setup(data: Dictionary) -> void:
	var day = data.get("day", 1)
	var month = data.get("month", 1)
	var hour = data.get("hour", 20)
	var min = data.get("minute", 0)
	var months = ["JAN", "FEV", "MAR", "ABR", "MAI", "JUN", "JUL", "AGO", "SET", "OUT", "NOV", "DEZ"]
	%DateLabel.text = "%d %s • %dh%02d" % [day, months[month - 1], hour, min]

	var user_team = GameManager.user_team_id
	var home_id = data.get("home_team_id", 0)
	var away_id = data.get("away_team_id", 0)
	var is_home = home_id == user_team
	%HaPill.text = " CASA " if is_home else " FORA "

	var league_teams = GameManager.league.teams
	var ht = _find_team(league_teams, home_id)
	var at = _find_team(league_teams, away_id)

	%HomeAbbr.text = ht.get("abbreviation", "H") if ht else "H"
	%AwayAbbr.text = at.get("abbreviation", "A") if at else "A"
	%HomeName.text = ht.get("name", "HOME").to_upper() if ht else "HOME"
	%AwayName.text = at.get("name", "AWAY").to_upper() if at else "AWAY"
	
	%HomeRecord.text = str(ht.get("wins", 0)) + "V - " + str(ht.get("losses", 0)) + "D" if ht else ""
	%AwayRecord.text = str(at.get("wins", 0)) + "V - " + str(at.get("losses", 0)) + "D" if at else ""

	%Prediction.text = "Previsão: 58% V"

func _find_team(teams: Array, id: int) -> Dictionary:
	for t in teams:
		if t.get("id", -1) == id: return t
	return {}
