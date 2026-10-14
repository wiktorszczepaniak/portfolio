# Preflight asset findings from V11 source

Offline extraction/audit of original V11 source conducted 2026-10-14.

- 659 PNG under project/assets; 14 MUGEN-style manifests.
- All manifest sprite referenced paths/actions/declared dimensions are valid in this pass: **0 ERROR**.
- 50 automatically flagged PNG candidates for checking alpha / dark-or-purple artifacts; note these include intentional fully opaque ground backgrounds and some legitimate purple water/poison. They are NOT 50 confirmed bugs.
- Existing `assets/mugen/naruto_kcm`: 33 sprite PNG, existing manifest; current KCM visually too uniformly bright gold and needs a redesigned readable cloth/chakra silhouette.
- `assets/ui`: 24 PNG. Layouts drawn primarily by `scripts/shinobi_ui.gd` and `scripts/duel/duel_hud.gd`; when moving buttons, also move custom mouse hitboxes.
- `scripts/game.gd` loads `assets/v9/rasengan_sheet_%02d.png` and replaces earlier rasengan sequence when present. Fix the *active* VFX source; editing `assets/vfx/rasengan_*.png` alone may not affect the game.
- `scripts/combat/combat_art.gd` uses `assets/v10` and `assets/boss_sasori`; effect names reused in different renderers.
- `v9/water_burst_*.png` and `v9/waterrune_*.png` show potential unwanted rectangular fragments on visual checkerboard, requiring actual runtime inspection. `v10/chakra_arm_*.png` appears bright yellow rather than new KCM orange/black.
- V11 `scripts/duel/boss_duel.gd` loads boss BGM `res://assets/v8/miniboss_arcade.wav`. Do not claim new music was added without verifying the bytes and playback.
- `scripts/core/audio_director.gd`: 2 voice players, 4 SFX players, global 6 second clone.wav cooldown. Preserve clone spam protection.
- **Original QA V11**: Linux/Windows suites reported 10209+23+1295 passes and headless exported EXE boot, but no manual exported Windows GUI/audio playthrough.

Use the preparatory ZIP for CSV-level file names, all-frame contact sheets, target SVGs, and cue sheet.
