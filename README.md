# Pro Hoops Simulator (Basket Manager Godot + Rust Engine)

A professional-grade, highly realistic 2D Basketball Simulation and Management Game.

This project features a **custom-built, blazing fast game engine in Rust** that handles deep tactical logic, real-time physics, and basketball rules, while a **Godot 4 frontend** beautifully renders the simulation using advanced 2D drawing techniques and smooth interpolation.

## 🚀 Features

### 🧠 High-Fidelity Simulation Engine (Rust)
- **Deep Tactical AI:** Players make decisions based on dynamic playbooks, spatial awareness, attributes, and tendencies.
- **Advanced Physics & Kinematics:** 
  - Realistic ball trajectories using Bézier curves (Chest passes go straight, bounce passes hit the floor, lob passes arc high).
  - Accurate spatial movement, locomotion, and collision avoidance (Pace & Space algorithms, pick and roll).
- **Comprehensive Ruleset:** Complete implementation of real basketball rules including 24-second shot clock, 8-second backcourt violations, turnovers, and fouls.
- **Complex State Machine:** Manages fluid transitions between game phases (`BringUp`, `Execution`, `ReboundContest`, `Inbound`, `JumpBall`).

### 🎨 Beautiful Frontend (Godot)
- **AAA Aesthetics:** Premium court rendering with hardwood textures, subtle shadows, and specular highlights.
- **Smooth Interpolation:** Godot interpolates 10-ticks-per-second backend data into buttery-smooth 60+ FPS visuals.
- **Visual Feedback:** Players visually "look" at their passing targets/hoops, and the ball leaves dynamic trajectory indicators based on its speed and arc.

## 🏗 Architecture

This project uses a hybrid architecture to combine the performance of systems programming with the ease of a modern game engine.

* **`rust/` (Backend):** Contains the `basket-ball-engine`. It runs entirely decoupled from the UI, simulating every tick, tracking stats, stamina, scores, and generating a stream of `MatchEvent`s.
* **`godot/` (Frontend):** The Godot engine consumes the Rust state (via GDExtension or FFI bindings) and renders it using the `court_2d.gd` system.

## 🛠 Prerequisites

To run this project locally, you will need:
- **[Godot Engine](https://godotengine.org/)** (v4.x)
- **[Rust](https://www.rust-lang.org/tools/install)** (`cargo`, `rustc`)

## 🎮 How to Run

1. **Compile the Rust Engine:**
   ```bash
   cd rust
   cargo build
   ```
   *(Note: For release builds, use `cargo build --release`)*

2. **Run the Godot Project:**
   - Open the Godot Editor.
   - Import the `godot/` folder as a project.
   - Hit **Play** (F5) to start the simulation!

## 🤝 Contributing
Contributions are always welcome! Whether it's adding new tactical plays to the Rust engine, improving the Godot visual effects, or fixing a bug, feel free to open a Pull Request or Issue.

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).
