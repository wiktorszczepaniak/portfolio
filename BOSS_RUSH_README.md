# SHINOBI // BOSS RUSH — Alpha 01.1

Playable vertical slice (Godot 4.5+), independent of Shinobi Survivors. Current encounter: **Naruto Uzumaki vs. Zabuza Momochi**, three boss phases, persistent two-stage chakra transformation, manual dodge and bullet hell patterns.

## Start
1. Open `project/project.godot` in Godot 4.5+.
2. Run the project (`F6` from main scene, or `F5` from editor).
3. In the menu, use `A/D` to pick unlocked starting Naruto forms, `Enter` to fight. Win unlocks a new starting form automatically. Save data is stored in `user://boss_rush_save.cfg`.

### Controls
| Input | Action |
|--|--|
| WASD / arrows | Move |
| Z (hold) / left mouse (hold) | Rasengan volleys, aimed at Zabuza |
| Shift (hold) | Precision / focus movement and hitbox indicator |
| X | Kawarimi-style dash with brief invulnerability (1.8s CD) |
| C | Shadow clone support, 8s, costs 22 chakra (18s CD) |
| Q | Evolve one form stage (0→1→2) at 90 chakra. Form persists; activation clears bullets and grants an 8s burst |
| Space | Rasengan ultimate, 9s cooldown and 35 chakra cost |
| Esc / P | Pause |

### Zabuza phases
- Phase 1, **Executioner** (100%–64%): rotating rings, fan volleys, aimed attacks.
- Phase 2, **Hidden Mist** (64%–26%): mist rolls in, spiral fire, Suiton walls and tracking shots.
- Phase 3, **Demon of the Mist** (<26%): high-density mixed spirals, escalating angular pressure and demon aura.

### Unlock progression
One clear: **Kyuubi Naruto** starting variant, two clears: **Sage Naruto**, three clears: **KCM Naruto**, then replay for scores/grazes. For Base Naruto, Q at 90 chakra awakens Kyuubi Sign; a second Q at 90 chakra unlocks One-Tail Cloak. Both stages persist for the rest of the fight. Starting-form variants are separate selectable Naruto forms, not additional heroes. **Sasuke, Sakura, Kakashi and future bosses are on the roadmap, not falsely presented as playable content in this version.**

### Design limitations (alpha)
- Currently 1 encounter, 4 Naruto-form starting slots (not four different playable characters), no independently playable Sasuke/Sakura/Kakashi yet.
- Assets sourced from user's MUGEN/Zabuza archive and prior Shinobi Survivors V12.1 sources. **Fan-game art/audio may have separate third-party rights; do not treat them as open licensed.**
- Bullet pattern architecture was inspired by the MIT-licensed [Pew Pew Pew: Danger Zone!](https://github.com/foosel/pew-pew-pew-danger-zone); the scripts in this project were newly implemented and do not redistribute the original code/assets.
- Main deliverable is an **editable Godot 4 source project**, not a precompiled Windows executable. Packaging for Windows requires Godot export templates and an export run.

### QA
- Alpha 01.1 caps clone volleys, adds two in-fight transformations, and increases Zabuza health to 9000 HP for longer phases. Balance is not yet play-tested.
- Static QA: verify referenced textures and sounds, resource paths, script callbacks, number of boss phases, ZIP CRC.
- Godot runtime smoke (when Godot executable available): `godot --headless --path project --import`, then `godot --headless --path project --quit-after 480 -- --qa-smoke` and `godot --headless --path project --quit-after 480 -- --qa-logic` (spawns encounter and exits with `QA_SMOKE_PASS` after six seconds).
- This does not replace a human balance/visual/audio playtest.

## Roadmap
P0: working alpha Naruto × Zabuza; P1: combat polish, sprite timing, real water dragons/4th Zabuza attack family; P2: **Sasuke/Kakashi/Sakura** genuinely playable, each with distinct form tree and jutsu; P3: Kisame and Itachi encounters; P4: Pain, save profiles, achievements and true Windows release.

## Continuity
A dedicated GitHub branch for this project was created at `wiktorszczepaniak/portfolio`, branch `game/boss-rush-zabuza-alpha-20261015`, forked from V12.1. Main portfolio untouched. Source ZIP exists independently, so it can later migrate to a standalone `shinobi-boss-rush` repository.
