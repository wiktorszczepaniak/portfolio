# Shinobi Survivors V11.1 | Preflight for Astra

Prepared 2026-10-14. **This commit contains only planning/preflight text; NO visual improvements and NO Windows V11.1 EXE yet.**

## Baseline
- Source of truth: parent commit `21eea8cd8b9d9dcb77a28603ed808c3812234509`, Godot **4.5.2**, Windows 1280x720, gameplay physics 60 Hz.
- Do not modify portfolio `main`.
- In ChatGPT Library also locate `SHINOBI_V11_1_ASTRA_READY_2026-10-14.zip` (the full handoff bundle created in the current conversation); it includes the original V11 source ZIP, QA ZIP, unchanged checkpoints, sprite audit CSV, checkerboard contact sheets, SVG UI wireframes and scripts.
- The last art redesign was **not** included in V11 release. KCM is gold monochrome (33 PNGs), boss art and UI still need overhaul and new SFX were not integrated.

## Start
1. Read full `00_START/ASTRA_EXECUTION_PROMPT.md` inside handoff ZIP. It supersedes this GitHub summary.
2. Review actual contact sheets `01_AUDIT/KCM_33_FRAMES.png`, `VFX_ATTACK_SAMPLE.png`, `V11_LIVE_RENDER_REFERENCE.jpg` and mockups under `02_VISUAL_TARGETS/`.
3. From this preparatory branch create separate V11.1 implementation branch/checkpoint, run baseline regression.
4. Small P1 slice: **new working KCM idle/run/hit animation + 1 fixed Rasengan clip**, screenshot and commit. Only then complete full KCM and other VFX.
5. P2: redesign entire HUD/menus using ninja scroll / ink/paper art direction. P3: boss scene, telegraphs, SFX. P4: native Windows QA, verified Windows/source/QA ZIP.

No assertions that initial V11 test results certify V11.1. Keep all real commit SHAs, logs, screenshots and SHA256 checksums. Save after every checkpoint.
