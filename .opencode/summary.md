# Pro Hoops Simulator — Summary

## Objective
Simulação/gestão de basquete em Godot 4.7 + Rust GDExtension. Interface rica com tema dark, dashboard, elenco, finanças, treino e match simulation 2D.

## Completed

### Phase 1 — Finance Engine ✅
- `rust/src/engine/params.rs` — 48 GameParams carregados do SQLite
- `rust/src/engine/finance.rs` — `process_weekly_finances()`, `process_game_finances()`, `process_season_prizes()`, `generate_sponsors()`
- `rust/src/engine/types.rs` — `TeamFinances`, `Transaction`, `Sponsor` structs
- `rust/src/bridge/engine_class.rs` — `get_finances()`, `get_player_salary_details()` bridges
- `rust/src/engine/systems.rs` — `process_weekly_team_systems()` processa treino, moral, stamina, lesões semanalmente
- `godot/scripts/autoload/game_manager.gd` — `get_finances()`, `get_player_salary_details()`, `get_game_params()`, `set_game_param()` wrappers
- `godot/scripts/finance.gd` — UI financeira conectada à engine (KPIs, salary cap, receitas/despesas)

### Phase 2 — Training + Morale + Stamina + Injuries ✅
- `rust/src/engine/systems.rs` — `process_training()`, `update_morale_after_game()`, `stamina_after_game()`, `process_game_recovery()`, `check_injuries()`
- `rust/src/engine/team.rs` — `set_training_intensity()`, `get_training_intensity()`, `get_training_status()` + testes
- `godot/scripts/training.gd` — Botões de intensidade conectados via `GameManager.set_training_intensity()`

### Phase 3 — GDScript ↔ Engine Connection ✅
- **`godot/scripts/team.gd`**:
  - `_load_roster` engine branch: key mapping corrigido para `position`, `overall`, `attributes`, `injury_days → status`, `height_cm → height_str`
  - `_build_kpis`: OVR médio, idade média, salário total (via finances), química — todos calculados da engine
- **`godot/scripts/dashboard.gd`**:
  - `_populate_stats`: PPG e OPP computados do schedule (jogos realizados do time do usuário)
- **`godot/scripts/player_profile.gd`**: já usava chaves corretas (`overall`, `attributes`)
- **`godot/scripts/finance.gd`**: já bem conectado com `get_finances()`, `get_salary_total()`

## Active

### Tests
- **Rust:** 17/17 testes passando (finance, params, systems, db, match_simulator)
- **Godot:** Editor não disponível para teste visual (AppTranslatado removido), mas sintaxe GDScript revisada manualmente

## Next Move (sugerido)
1. **GDExtension build** — compilar `.gdextension` e testar no Godot
2. **Match flow** — conectar match.tscn + court_2d.gd ao `sim_tick()` da engine
3. **Save/Load** — finalizar persistência com save/load funcional
4. **Roster editing** — implementar drag & drop de rotação, trocas, contratações

## Relevant Files

### Bridge (Rust ↔ Godot)
- `rust/src/bridge/engine_class.rs` — `BasketballEngine` GDExtension class
- `rust/src/bridge/convert.rs` — `player_to_dict()`, `team_to_dict()`, `league_to_dict()`

### Engine (Rust)
- `rust/src/engine/types.rs` — `Team`, `Player`, `PlayerAttributes`, `TeamFinances`, `GameParams`
- `rust/src/engine/params.rs` — 48 GameParams + JSON roundtrip
- `rust/src/engine/finance.rs` — weekly/game/season finances, sponsors
- `rust/src/engine/systems.rs` — training, morale, stamina, injuries
- `rust/src/engine/team.rs` — intensity, training_status
- `rust/src/engine/match_simulator.rs` — match simulation
- `rust/src/db/schema.rs` — SQLite schema (teams, players, settings, career_save)
- `rust/src/db/mod.rs` — DB operations

### GDScript (Godot)
- `godot/scripts/autoload/game_manager.gd` — Singleton bridge
- `godot/scripts/autoload/event_manager.gd` — Season events
- `godot/scripts/autoload/theme_config.gd` — Dark theme config
- `godot/scripts/team.gd` — Elenco screen
- `godot/scripts/dashboard.gd` — Dashboard screen
- `godot/scripts/finance.gd` — Finanças screen
- `godot/scripts/training.gd` — Treino screen
- `godot/scripts/player_profile.gd` — Perfil do jogador
- `godot/scripts/court_2d.gd` — Quadra 2D draw/match visualization

## Architecture

- **Godot 4.7**, GDScript, 1920×1080, gl_compatibility
- **Engine:** Rust GDExtension (`BasketballEngine`, RefCounted) em `rust/src/`
- **Autoloads:** GameManager, EventBus, SimulationController, EventManager, ThemeConfig
- **UI:** Tema escuro programático (StyleBoxFlat), componentes em `scenes/ui/components/`
- **2D:** `court_2d.gd` com `_draw()`, interpolação suave via `lerp()`
- **DB:** SQLite via `rusqlite`
- **Telas:** `BaseScreen` (MarginContainer) com `%TopBar` + `%ContentArea`
