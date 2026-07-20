@tool
extends PanelContainer
class_name SubstitutionSubmenu

# ═══════════════════════════════════════════════════════════
#  Signals
# ═══════════════════════════════════════════════════════════

## Emitido quando o usuário clica em um jogador reserva para efetuar a troca.
## - source_data: dicionário do jogador que será substituído (titular)
## - target_data: dicionário do jogador que entrará em quadra (reserva)
signal player_swap_requested(source_data: Dictionary, target_data: Dictionary)


# ═══════════════════════════════════════════════════════════
#  Export — referências de cena configuráveis no Inspector
#  (NUNCA construir UI em código; toda a estrutura está no .tscn)
# ═══════════════════════════════════════════════════════════

## PackedScene do card de linha do jogador reserva.
## Deve expor `setup(source: Dictionary, target: Dictionary)` e
## emitir `swap_requested(target_data: Dictionary)` ao ser clicado.
@export var candidate_row_scene: PackedScene

## Labels configurados via % unique names no .tscn.
## Resolvidos via @onready para máxima confiabilidade.
@onready var _header_label: Label = %Title
@onready var _subtitle_label: Label = %Subtitle
@onready var _context_label: Label = %PlayerOut

# ═══════════════════════════════════════════════════════════
#  Atributos privados
# ═══════════════════════════════════════════════════════════

## Container dos cards. Resolvido em update_replacement_list()
## via get_node() direto para evitar dependência de NodePath.
var _list_container: VBoxContainer

## Dicionário do jogador de origem (titular sendo substituído).
## Armazenado em setup() para uso nos callbacks de clique dos cards.
var _source_player: Dictionary = {}


# ═══════════════════════════════════════════════════════════
#  API Pública
# ═══════════════════════════════════════════════════════════

## Configura o submenu de substituição.
##
## - source_player: dicionário do jogador que será substituído
## - position: sigla da posição (ex: "PG", "SG", "SF", "PF", "C")
## - candidates: lista de dicionários com todos os jogadores do elenco
##
## Preenche os labels do cabeçalho, subtítulo e barra de contexto,
## depois filtra os candidatos pela posição e instancia os cards.
func setup(source_player: Dictionary, position: String, candidates: Array) -> void:
	_source_player = source_player

	# ── Cabeçalho │ ex: "TROCAR POSIÇÃO PG" ──
	if _header_label:
		_header_label.text = "TROCAR POSIÇÃO " + position

	# ── Subtítulo (contagem total antes do filtro) ──
	if _subtitle_label:
		_subtitle_label.text = str(candidates.size()) + " jogadores compatíveis"

	# ── Barra de contexto │ ex: "Substituindo: Marcus Silva (PG)" ──
	if _context_label:
		var player_name: String = source_player.get("name", "Jogador")
		_context_label.text = "Substituindo: " + player_name + " (" + position + ")"

	# ── Filtra e monta a lista de candidatos ──
	update_replacement_list(position, candidates)


## Filtra os candidatos pela posição e recria os cards da lista.
##
## - selected_position: posição alvo para o filtro (ex: "PG")
## - all_players: lista completa de dicionários de jogadores
##
## Regras de filtro:
## 1. Inclui jogadores cujo campo `pos` (posição principal) seja igual a selected_position
## 2. Inclui jogadores cujo campo `secondary_pos` (posição secundária) seja igual a selected_position
## 3. Remove todos os cards antigos antes de instanciar os novos
func update_replacement_list(selected_position: String, all_players: Array) -> void:
	# ── Limpa TODOS os cards existentes no list_container ──
	# Usa get_node() direto no caminho para evitar dependência de
	# _list_container cacheado (que pode falhar em @tool)
	var container := get_node_or_null("VBox/ListMargin/CandidateList") as VBoxContainer
	if container:
		for child in container.get_children():
			if is_instance_valid(child):
				child.queue_free()
		_list_container = container
	else:
		_list_container = null

	# ── Filtra: posição principal OU secundária ──
	var filtered: Array = []
	for player in all_players:
		var primary_pos: String = player.get("pos", "")
		var secondary_pos: String = player.get("secondary_pos", "")
		if primary_pos == selected_position or secondary_pos == selected_position:
			filtered.append(player)

	# ── Atualiza o subtítulo com a contagem real de compatíveis ──
	if _subtitle_label:
		_subtitle_label.text = str(filtered.size()) + " jogadores compatíveis"

	# ── Instancia os cards dos candidatos ──
	_instantiate_rows(filtered)


# ═══════════════════════════════════════════════════════════
#  Métodos Internos
# ═══════════════════════════════════════════════════════════

## Instancia um card (candidate_row_scene) para cada jogador filtrado.
## Conecta o sinal swap_requested de cada card ao callback interno,
## que por sua vez re-emite player_swap_requested com source + target.
func _instantiate_rows(players: Array) -> void:
	if not _list_container or not candidate_row_scene:
		print("[Submenu] ❌ _instantiate_rows: _list_container ou candidate_row_scene é null")
		return

	print("[Submenu] _instantiate_rows: ", players.size(), " jogadores para instanciar")

	for player in players:
		# Instancia o card a partir da PackedScene exportada
		var row: PanelContainer = candidate_row_scene.instantiate()
		_list_container.add_child(row)

		var player_name: String = player.get("name", "?")
		print("[Submenu]   → Instanciando card para: ", player_name)

		row.setup(_source_player, player)
		row.swap_requested.connect(_on_row_swap_requested)


## Callback interno acionado quando um card de candidato é clicado.
## Re-emite o sinal público player_swap_requested com os dados
## de origem (titular) e destino (reserva selecionado).
func _on_row_swap_requested(target_data: Dictionary) -> void:
	player_swap_requested.emit(_source_player, target_data)
