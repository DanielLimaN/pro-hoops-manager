use godot::prelude::*;

mod engine;
mod ai;
mod db;
mod state;
mod bridge;
mod worker;

struct BasketBallExtension;

#[gdextension]
unsafe impl ExtensionLibrary for BasketBallExtension {}
