# Checkpoint discipline / no lost ZIP again

Never spend the entire Astra allowance on a single massive rewrite. Implement in checkpoints with user-visible verified artifacts, preserving gameplay V11.

- **P0** after baseline import/regression: commit SHA, log, baseline checksum.
- **P1** after KCM and prioritized VFX: complete altered assets, manifest checks, screenshot comparisons, source ZIP.
- **P2** after UI: all UI screen captures, keyboard/mouse activation tests, source ZIP.
- **P3** after Sasori encounter and sound: boss video and synchronized sound proof, milestone commit and source ZIP.
- **P4** Windows release: exported standalone EXE, native Windows logs/test, compare Linux, no loss of V11 test semantics; Windows ZIP + source ZIP + QA ZIP + final SHA256 file.

If task pauses or time quota ends, leave a durable checkpoint first and a handoff describing exactly which files are committed, the next execution command, what is not tested, and the link to every actually existing artifact. Never promise a ZIP without checking the file exists and opens.

GitHub `main` is the user's portfolio and MUST stay unchanged. Code work on fresh `build/shinobi-v11-1-implementation` based on this branch or V11 release.
