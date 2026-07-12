# Context Menu Component — Visual & Implementation Spec

## Overview

A right-click context menu (Windows-style popup) for use on **starter player rows** in the team roster. Built with standard Godot Control nodes—no custom `_draw()` calls.

**Files created:**
- `res://scenes/ui/components/context_menu.gd` — script + full programmatic UI
- `res://scenes/ui/components/context_menu.tscn` — scene root

---

## Visual Design

```
┌─────────────────────────────────┐  ← 180px wide, auto-height
│                                 │
│  SUBSTITUIR                     │  ← 9px Bold, TEXT_MUTED (#94A3B8), letter-spacing 1
│                                 │
│  ⇄  PG (2 disponíveis)         │  ← 13px, white, icon #94A3B8
│  🧑  Reservas (5 disponíveis)   │
│                                 │
│  ─────────────────────────────  │  ← 1px BORDER_SUBTLE (#1F1432)
│                                 │
│  ↗  Ver Perfil Completo         │
│                                 │
└─────────────────────────────────┘
```

### Specs

| Property          | Value                        |
|-------------------|------------------------------|
| Width             | 180px (can grow with text)   |
| Corner radius     | 8px (all corners)            |
| Background        | `BG_SURFACE` (#0F0720)       |
| Border            | 1px `BORDER_SUBTLE` (#1F1432)|
| Shadow            | black at 60%, 24px size, 4px Y offset |
| Item height       | ~28px (5px pad top/bottom + 18px label) |
| Item radius       | 6px (inner highlight area)   |
| Item hover bg     | `BRAND_PRIMARY` at ~13% alpha (#A78BFA22) |
| Item text         | 13px, `FONT_INTER`, white    |
| Section header    | 9px, `FONT_INTER_BOLD`, `TEXT_MUTED`, letter_spacing 1 |
| Divider           | 1px `BORDER_SUBTLE`, 8px horizontal margin |
| Icon size         | 14×14px, `TEXT_MUTED` color  |

---

## Node Tree (Scene Structure)

```
ContextMenu (PanelContainer)        ← custom_minimum_size.x = 180, mouse_filter = PASS
├── [Backdrop] (Control)            ← full rect, MOUSE_FILTER_STOP, catches outside clicks
│   (added first so it's behind the panel)
│
└── MenuVBox (VBoxContainer)        ← separation = 0
    │
    ├── [Header Margin] (MarginContainer)  ← L:12, R:12, T:10, B:4
    │   └── HeaderLabel (Label)            ← "SUBSTITUIR"
    │
    ├── MenuItem_Same (PanelContainer)     ← MOUSE_FILTER_STOP
    │   └── HBoxContainer                  ← separation = 8
    │       ├── Icon (TextureRect)         ← arrow_right_arrow_left.svg
    │       └── Label                      ← "PG (2 disponíveis)"
    │   └── ClickOverlay (Button)          ← flat, full rect, emits action
    │
    ├── MenuItem_Bench (PanelContainer)    ← same structure
    │   └── HBoxContainer
    │       ├── Icon (TextureRect)         ← human.svg
    │       └── Label                      ← "Reservas (5 disponíveis)"
    │   └── ClickOverlay (Button)
    │
    ├── [Divider Margin] (MarginContainer) ← L:8, R:8, T:4, B:4
    │   └── Divider (ColorRect)            ← 1px tall, color = BORDER_SUBTLE
    │
    ├── MenuItem_Profile (PanelContainer)
    │   └── HBoxContainer
    │       ├── Icon (TextureRect)         ← arrow_up_right.svg
    │       └── Label                      ← "Ver Perfil Completo"
    │   └── ClickOverlay (Button)
    │
    └── [Bottom Pad] (MarginContainer)     ← B:4
```

> **Why two layers for each item?**
> The `PanelContainer` holds a normal + hover `StyleBoxFlat` (swapped via `mouse_entered`/`mouse_exited`), and a child `Button` (flat, full-rect) handles clicks. This avoids fighting Button's built-in style states and gives full control over the rounded highlight shape.

---

## Menu Item Behavior

| Event              | Reaction                                    |
|--------------------|---------------------------------------------|
| Mouse enter item   | bg → `#A78BFA22` (6px radius), cursor → hand|
| Mouse exit item    | bg → transparent                            |
| Click item         | emit `menu_item_selected(id, data)`, then `queue_free()` |
| Click outside      | backdrop catches `MOUSE_BUTTON_LEFT` → `closed.emit()`, `queue_free()` |
| Press ESC          | (optional: add via shortcut in consuming screen) |

---

## Signals

```gdscript
signal menu_item_selected(action_id: String, player_data: Dictionary)
signal closed()
```

### `action_id` values

| action_id       | Meaning                                     |
|-----------------|---------------------------------------------|
| `"same_position"` | Filter player list to same position       |
| `"bench"`         | Filter player list to bench players       |
| `"view_profile"`  | Navigate to player's full profile screen  |

---

## How to Use (Integration Guide)

### 1. Detect Right-Click on a Starter Row

In `team.gd` (or wherever starter cards/rows are built), connect `gui_input` on the starter player's Control:

```gdscript
# Inside the loop that builds starter player rows:
var starter_ctrl = Control.new()  # or existing PanelContainer
starter_ctrl.gui_input.connect(_on_starter_gui_input.bind(player_data))
```

### 2. Handler That Opens the Menu

```gdscript
const CONTEXT_MENU = preload("res://scenes/ui/components/context_menu.tscn")

var _context_menu: PanelContainer = null

func _on_starter_gui_input(event: InputEvent, player_data: Dictionary):
    if event is InputEventMouseButton \
       and event.pressed \
       and event.button_index == MOUSE_BUTTON_RIGHT:
        # Close any existing menu first
        if _context_menu:
            _context_menu.queue_free()
            _context_menu = null
        
        # Calculate position: global mouse position
        var pos = get_global_mouse_position()
        # Clamp to viewport so menu doesn't go off-screen
        var vp_size = get_viewport_rect().size
        pos.x = min(pos.x, vp_size.x - 190)
        pos.y = min(pos.y, vp_size.y - 150)
        pos.x = max(pos.x, 10)
        pos.y = max(pos.y, 10)
        
        var menu = CONTEXT_MENU.instantiate()
        menu.global_position = pos
        menu.set_menu_data(
            player_data,
            player_data.get("pos", "PG"),
            _count_same_position(player_data.get("pos", "PG")),
            _count_bench_players()
        )
        menu.menu_item_selected.connect(_on_context_menu_action)
        menu.closed.connect(func():
            _context_menu = null
        )
        add_child(menu)
        _context_menu = menu
```

### 3. Action Handler

```gdscript
func _on_context_menu_action(action_id: String, player_data: Dictionary):
    match action_id:
        "same_position":
            _apply_filter("pos", player_data.get("pos", ""))
        "bench":
            _apply_filter("bench", "")
        "view_profile":
            _open_player_profile(player_data)
```

### 4. Optional: Close on ESC

In `_input(event)` of your screen:

```gdscript
func _input(event: InputEvent):
    if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
        if _context_menu:
            _context_menu.queue_free()
            _context_menu = null
```

---

## Menu Positioning (Off-Screen Clamping)

Always clamp `global_position` so the menu fits within the viewport:

```gdscript
var vp = get_viewport_rect().size
var pos = get_global_mouse_position()
pos.x = clamp(pos.x, 8, vp.x - 196)   # 180 + 16 margin
pos.y = clamp(pos.y, 8, vp.y - 160)   # estimated max height
menu.global_position = pos
```

---

## Icons Used

| Icon name               | Path                                              |
|-------------------------|---------------------------------------------------|
| `arrow_right_arrow_left` | `res://addons/at-icons/control/arrow_right_arrow_left.svg` |
| `human`                 | `res://addons/at-icons/control/human.svg`         |
| `arrow_up_right`        | `res://addons/at-icons/control/arrow_up_right.svg` |

All load via `ResourceLoader.exists()` with graceful fallback if missing.

---

## Theme Dependencies (via ThemeConfig autoload)

| Constant             | Hex        | Used For                     |
|----------------------|------------|------------------------------|
| `BG_SURFACE`         | `#0F0720`  | Menu background              |
| `BORDER_SUBTLE`      | `#1F1432`  | Menu border + divider        |
| `BORDER_ACCENT_SOFT` | `#A78BFA66`| Item hover bg (13% opacity)  |
| `TEXT_PRIMARY`       | `#FFFFFF`  | Item labels                  |
| `TEXT_MUTED`         | `#94A3B8`  | Header label                 |
| `FONT_INTER`         | —          | Item text (13px)             |
| `FONT_INTER_BOLD`    | —          | Header text (9px)            |

---

## Testing Checklist

- [ ] Right-click opens menu at cursor position
- [ ] Menu does not overflow viewport edges
- [ ] Hover highlights item with purple tint
- [ ] Click item emits correct `action_id` + `player_data`
- [ ] Click outside closes menu
- [ ] Menu items show correct dynamic counts ("PG (2 disponíveis)")
- [ ] Divider renders as thin line
- [ ] Consistent 28px item height
- [ ] Shadows render correctly on transparent canvas
