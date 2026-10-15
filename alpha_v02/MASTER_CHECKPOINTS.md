# SHINOBI SURVIVORS — ALPHA 0.2 MASTER PLAN
Date: 2026-10-15. Baseline: ALPHA 0.1 commit d61bab68 (working Windows CI). Portfolio main untouched.
STATUS LEGEND: [x] committed & verified, [~] implemented but waiting for native Windows QA, [ ] not yet implemented. Never mark [x] purely on a plan.

## Current verified baseline and defects
- 6 MUGEN actor packs, 36 trees × 7 nodes=252 named talents, 8 Naruto-centric attack slots reused per character; 2 path awakenings for each but non-Naruto actor_pack() stays original. 36 skill signatures are mostly shared pattern handlers.
- Main speed only 1,1.5,2.0, with single variable large physics dt per frame. At x5 use fixed simulation substeps to prevent tunnelling.
- ESC pause lacks Exit to main (survival & duel).
- Sasuke manifest action '0' flips horizontal every 2 ticks; remove flip from idle, preserve controlled facing.
- ninja_fx.gd sand branch paints gray triangles. Sand needs tan/ochre particles, cohesive trails, collision readable.
- The upgrade selection UI fills many cards with Naruto or geometric placeholders; jutsu_registry uses Naruto IDs and re-labels, not class-unique IDs.
- Rock Lee and Neji share auto kunai shot engine; change to close melee hitboxes + startup/active/recovery matched to sprite action and player facing; only unlock canonical short-mid techniques with proper visual projectiles.
- Existing 6x6x7 tree grid repeats damage/tempo/guard/projectile and can rapidly max out. UI nodes too small.
- Awakening paths for 5 other heroes aren't real sprite swaps. Resolved via MUGEN audit/export per form and truthful lore gating.

## Milestones; complete in order and persist GitHub SHA, QA, and visible screenshots each time
- [x] P0: inspect source + 6 MUGEN manifests, confirm defects, gather lore with provenance.
- [x] P1: usability + obvious art defects: 1/1.5/2/3/4/5x simulation with fixed substeps, return to menu in survivals and Sasori, Sasuke idle mirror, Gaara real sand render, deterministic tests + Windows zip.
- [ ] P2: **combat engine**: physical melee Lee / Neji (hitboxes, combo & true recovery), 64 Palms timed burst based on anime + counter/tenketsu debuff, Lee green air trails from real strikes, no full-screen thrown shapes at level 1; impact SFX attached to actual active frames.
- [ ] P3: class IDs: split 8 Naruto-centric engine abilities into 6-class catalog, canonical jutsu naming, data-driven cooldown/mana/range/hitframe/hitbox/targeting/special statuses. Guarantee non-Naruto never receives Naruto icons, form names or frog abilities by accident.
- [ ] P4: create/retrieve/extract **class-specific MUGEN art** including .sff/.air/.act palettes; every active skill gets explicit art_ref and owner; reject placeholder icon entries at packaging; new sand, lightning, fire, Byakugan, Lee green air trails, wind variants. Contact sheets & 1280x720 previews mandatory.
- [ ] P5: build documented transformation routes, matching full animated sprites (idle, 20 run, 200 attack, 5000 hit, dash, fall) rather than tint; gain form-dependent skills+silhouette. No Shukaku-jinchuriki timeline for post-extraction Gaara, no Mangekyo + Curse Seal crossover in the same route.
- [ ] P6: expand 36×7=252 to **60 trees ×8=480 nodes**, ten thematic trees for EACH of six heroes, branch exclusivity and synergies; attach at least **90 canon/anime/game-labelled ability variants** (15 per hero), not 90 copies of generic AoE. Each scroll displays source-accurate icon, readable animation, rarity, prerequisite, status effect and path preview.
- [ ] P7: animation/UI overhaul: full-screen talent constellation with pan/zoom, 2x icon scale, unique scroll icons with high contrast, form cards with real character idle animation and potential preview, balanced HUD and text sizes.
- [ ] P8: pacing & balance: increase XP needed 10–15% as first pass, gate rare/ultimate skills by time/form, no excessive rapid unlocks, combos with high-skill ceiling, fair boss/mini-boss pacing and attack caps; benchmark Naruto/Lee/Neji/Gaara first.
- [ ] P9: gameplay structure: test menu and boss menu transitions, save/load skill build, death/retry, fixed RNG QA seed, training room for all jutsu/form phases, collision + sound tests at x1/x5, no crashes at high enemy density, scroll duplicate elimination.
- [ ] P10: final QA/release: original 10k+ tests, all six class unique-jutsu tests and 90 spell casts, raw Windows game QA including real GUI screenshots/audio, 10-minute no-crash soak and 30-minute x5 testing. Art cannot be marked done if only shader/tint is changed. Windows EXE + source zip + QA zip + sha256, stored in Library and GitHub artifact. Do not modify main.

## Additional inferred fixes
1. Future upgrade cards must show only playable-class-relevant skills; avoid changing display names while hit logic remains Naruto's.
2. Ultimates need target lock/warning and boss caps, otherwise giant AoE damages both phases.
3. Anim clips need fixed sprites/origins and alpha backgrounds, no placeholder geometry or AI smear, test loop/idle orientation for all 6.
4. Distinct physical attack audio and hitflash for each class (punch, palm, lightning, fire, sand).
5. No skipped high-speed collisions; cap VFX/pool to preserve frame rate.
6. Proper scene cleanup when returning to menu from survival/duel.
7. Explicit lore status: Canon manga / Anime-only / Game-only / Original gameplay variant. Exclude borrowed jutsu from other characters.
8. Each milestone source commit + screenshot before moving on; no untested claims.

## P1 acceptance
- Press SPACE cycles NORMAL→1.5→2→3→4→5→NORMAL; clickable HUD.
- x5 uses substeps <=1/60, mission clock runs 5× in 1 minute real time within tolerance, collision regression.
- ESC pauses. Menu button works in survival AND Sasori (including intro), preserving choice of hero; no stuck audio.
- Sasuke action0 never toggles facing due to frame flip. Gaara's sand never paints gray/black triangles.
- Windows native Godot import + CLI checks + executable smoke all pass, ZIP downloaded verified.

## References
See ALPHA_V02_CANONICAL_JUTSU_CATALOG.md and inline provenance. Fan game implementation: source art rights and attribution should be checked before distributing outside private prototype.

## P1 VERIFIED CHECKPOINT | 2026-10-15
- GitHub Actions Windows Godot 4.5.2 run: https://github.com/wiktorszczepaniak/portfolio/actions/runs/38678803753 (completed SUCCESS)
- Tested executable, alpha class suite, alpha abilities, class jutsu, dedicated P1 QA, native Windows render and source archive.
- Code SHA under test: 15bbb720a423ebfec7dbc640b4ce46a8acb84705; later commits on this branch are planning and asset-audit docs only.
- Artifact ID 11947062248, GitHub Actions artifact 'shinobi-windows-and-QA', expiring 2026-10-25. Source/game.zip/QA kept in artifact.
- Follow-up: P2 is NOT complete, nor is the 90-jutsu catalog implemented. Existing Gaara attacks have ochre particulate VFX but the full sand art pack remains P4. Five non-Naruto transformed sprite packs remain P5.
