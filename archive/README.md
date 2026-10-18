# Non-active source archive

This directory contains historical combat backups and an unused, self-referencing `bananalevel_2.tscn`. Godot must not load these snapshots as active resources because they contain duplicate scene UIDs or invalid references. The `.gdignore` file prevents Godot from scanning this folder. Do not remove `.gdignore` without first cleaning up and validating those archived assets.

The byte contents of archived original files have been preserved. Files in `scenes/legacy/` are different: they remain active project resources because existing regression tests load them.
