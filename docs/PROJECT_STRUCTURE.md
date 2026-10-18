# Minion Madness source layout

- `scenes/levels/` — current playable levels.
- `scenes/player/` — playable character scenes, including the canonical `minions.tscn`.
- `scenes/enemies/` — enemy scene variants.
- `scenes/bosses/` — arena and boss assets.
- `scenes/interactables/` — collectibles, hazards, platforms, and level exit.
- `scenes/ui/` and `scenes/audio/` — interface and audio nodes.
- `scenes/legacy/` — older gameplay scenes still referenced by regression tests; **not deleted**.
- `scripts/player/`, `scripts/enemies/`, `scripts/components/`, `scripts/interactables/`, `scripts/bosses/`, `scripts/ui/`, `scripts/systems/` — scripts by responsibility.
- `scripts/legacy/` — old scene-local GameManager scripts; not the autoload.
- `assets/backgrounds/`, `assets/sprites/`, `assets/tilesets/`, `assets/fonts/`, `assets/audio/` — non-code assets.
- `addons/` — existing third-party tools (intentionally not reorganized).
- `archive/` — unused snapshots excluded from Godot scanning with `.gdignore`.
- `tests/` — verification scripts.

The shared/autoload GameManager is `res://scripts/systems/game_manager.gd`. The old banana scoring manager is `res://scripts/legacy/game_manager.gd`. No changes to their logic were made.

**Migration scope:** Structural move and `res://` reference updates only; gameplay is not rewritten or declared tested. Existing Level 1 player Health/HurtBox deletion in the uploaded ZIP is retained.
