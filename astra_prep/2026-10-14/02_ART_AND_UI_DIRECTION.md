# UI / KCM / Boss V11.1 visual brief

Art style: coherent **Naruto Shippuden arcade pixel art** using existing acceptable Base Naruto, Kyuubi, Sage and Sennin sprite aesthetics. **Not AI painterly**, no disconnected MUGEN crop artifacts, no hard purple or black backgrounds and no smearing. Explicitly redesign Naruto's Kurama Chakra Mode, not the other acceptable forms.

## KCM
- Separate orange luminous cloak from charcoal-black clothes and seals, preserve Naruto silhouette; readable in actual 1280x720 gameplay, not only enlarged sheet.
- ALL utilized animations: idle, run/backward, jump/fall, attack/melee 3 hits, hit/block/dash/jutsu + mirrored axes and AIR ticks. Do not replace a 33-frame pack with only a couple of pretty static poses.
- Match base form height/ground anchor. Avoid RGB bleeding on pixel edges.

## UI
- Ninja scroll / handcrafted ink & parchment rather than untextured rectangles. Dark ink #172624, paper #EAD3A2, aged wood #8B6941, seal vermilion #BD513B, chakra blue #53BDD7 are draft tokens.
- Compact top HUD and bottom J/K/L/X/SHIFT slots keep battlefield clear; match wireframe SVG in preparatory ZIP where useful. Screens: menu, survivor status, gacha, upgrade picks, form branch, pause, duel loadout/HUD, victory/retry.
- Keep Polish copy and mouse/keyboard controls; all actual hitboxes moved with graphic buttons.

## Boss
- Hiruko into Sasori/Marionetki. Explicit floor/spear/poison telegraphs and fair dodge gap, counter windows, melee feedback, consistent background depth, actor pivots/hurtboxes, video of each boss phase.
- Three F combo hits need distinct, synchronized impact audio, not generic sound spam. Keep J/K/L cancel priority, double jump and Kawarimi.
- Change SFX only after hitframe hooks are known; preserve Kage Bunshin voice debounce. Boss track only if physically present and usable.

## Acceptance
Visual diff screenshots at same pose/zoom, per-frame checkerboard review, 1280x720 screens for whole UI and real boss both phases, actual Windows EXE test (headless vs GUI/audio clearly separated), repeat full original regression plus new art/SFX checks.
