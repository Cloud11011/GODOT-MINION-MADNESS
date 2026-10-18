# Minion Madness — Folder & Resource-Path Reorganization

## Source state
- Source: uploaded `FIXFILESFOLDERS.zip`, `feature/player-combat` worktree snapshot.
- Source branch according to uploaded Git HEAD: `feature/player-combat`.
- The user's removal of `Minions/Health` and `Minions/HurtBox` from Level 1 **is preserved**, not repaired in this structural pass.
- **No game mechanics, scene positioning, or existing autoload definitions were deliberately changed.**

## Changes made
- Relocated 138 source items (including import metadata and script UID sidecars); one exact duplicate Minion scene was removed.
- Updated references inside 56 first-party scene/script/import/test files, including `res://` literal paths.
- Preserved `.gd.uid` files with their scripts and `.import` sidecars with original asset textures/audio.
- Updated explicit paths used by `main_menu.gd`, `game_manager.gd`, `scripts/minions.gd`, `scripts/node_2d.gd`, `player.gd`, `tests/combat_regression.gd`, plus `.tscn` and `.import` resources.
- Preserved all supported `uid://` identifiers for original scenes, scripts and autoloads.
- Removed the redundant byte-identical `scenes/minions.tscn` in favor of canonical `scenes/player/minions.tscn` (original was identical to `scripts/minions.tscn`).
- Moved a self-referencing, otherwise unused `bananalevel_2.tscn` to `archive/unused/` unchanged.
- Moved original combat backup files into `archive/legacy_combat_fix_backup/` unchanged, with `archive/.gdignore` to prevent duplicate UID scanning.
- Left addon directories untouched and excluded `.git` metadata from the delivery archive to preserve your existing Git branches, remote, and stashes.

## Static checks
- 197 `res://` reference occurrences scanned across active project configuration, scripts, scenes and import sidecars.
- No active reference to a relocated old path remains in first-party resources.
- No duplicate scene UID among the active first-party scenes (archive is ignored).
- Remaining **pre-existing** missing referenced destinations: `res://game_over.tscn` and `res://win_screen.tscn` in the GameManager. These are not created or redirected because no corresponding scenes exist in your uploaded project.
- Godot runtime/editor verification **not performed** in this environment. Reimport and test in Godot 4.7.x locally before committing or merging.

## Separate gameplay problems not addressed
- Level 1 Minions player health nodes were deleted in the supplied ZIP, and the reusable Minion scene does not yet contain replacements. Restore those as part of your P1 player work **before treating the game as stable**.
- Level 2 and boss arena still need the same reusable player/HUD functionality.
- The older `scripts/legacy/game_manager.gd` and current autoload `scripts/systems/game_manager.gd` are different scripts; no methods or score behavior were merged.
- The dormant `scenes/legacy/main_game.tscn` is retained because the combat regression script still opens it.

## Safest application route
1. Keep Godot closed and preserve your current local Git branch/stashes.
2. Extract this package **outside** your existing Godot repo.
3. Create a dedicated refactor branch with `git switch -c refactor/project-structure` from your `feature/player-combat` branch (local changes follow the new branch).
4. Run the accompanying `APPLY_TO_EXISTING_REPO.ps1` from the extracted package against your existing repo. It performs an exact-source hash preflight and creates an external backup before any file moves. It will refuse to run on `main`.
5. Reopen Godot, wait for asset reimport, inspect Debugger errors, and run existing tests when applicable.
6. Inspect `git status` / `git diff --stat` and commit only after confirming gameplay references. Coordinate before merging a sweeping structural rename with teammates.

See `docs/MIGRATION_MANIFEST.json` for every exact old→new path and baseline SHA-256 checks.
