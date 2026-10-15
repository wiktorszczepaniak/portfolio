# P0 MUGEN ASSET AUDIT | 2026-10-15

Actual JSON manifests of six playable MUGEN heroes were read from GitHub. An ACTION is a MUGEN animation; sprite existence does not prove a complete jutsu.

| Pack | Sprite keys | Actions | Idle frames | Attack 200 frames |
|---|---:|---:|---:|---:|
| naruto_base | 38 | 12 | 6 | 4 |
| naruto_kyubi | 25 | 12 | 3 | 4 |
| naruto_sage | 31 | 12 | 6 | 4 |
| naruto_sennin | 31 | 12 | 6 | 4 |
| naruto_kcm | 20 | 12 | 4 | 4 |
| sasuke | 24 | 9 | 2 | 5 |
| kakashi | 28 | 9 | 3 | 4 |
| rock_lee | 34 | 9 | 6 | 4 |
| neji | 42 | 9 | 6 | 5 |
| gaara | 39 | 9 | 6 | 4 |

**Core finding:** all five non-Naruto classes only have one imported MUGEN actor pack each. Sasuke's idle in baseline was same sprite 9876_0 mirrored every 2 ticks; P1 fixes. Other hero awakenings cannot become real silhouettes with a shader tint. New sprite packs / animations are mandatory.

Other source: user Library folder contains the original 431 MB Naruto-MUGEN archive. It may include additional forms, but this must be verified through actual SFF / AIR / ACT extraction, matching action IDs, palette handling and asset provenance. Never assume the form is included simply because base actor exists.

Asset acceptance:
* correct MUGEN AIR axes, fixed alpha crop, stable mirroring and feet anchor;
* at least 5 animated usable actions per form (idle/run/attack/hurt/dash) and preferably 9;
* true hitframes matching collision and SFX, native resolution 1280x720 previews;
* every scroll icon uniquely references matching jutsu and correct hero;
* no placeholder geometric VFX for already claimed finished technique.

Architecture points: scripts/mugen_actor.gd handles flipping; scripts/game.gd has shared class basic shot; scripts/core/jutsu_registry.gd relabels Naruto-oriented common slots; scripts/combat/alpha_abilities.gd uses shared generic patterns; scripts/shinobi_ui.gd uses Naruto fallback artwork; scripts/combat/ninja_fx.gd originally paints grey triangle sand.
