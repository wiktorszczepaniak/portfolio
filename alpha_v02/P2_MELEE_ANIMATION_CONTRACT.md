# P2 CONTRACT — Lee/Neji physical combat (NOT long range kunai)
P2 is not done until the code + Windows video prove every item below.

## Rock Lee
- Default basic attack MUST acquire targets in 85–115px melee range, never auto-throw kunai at targets 600px away.
- Action 200 / 210 / 220 from rock_lee MUGEN manifest each drives a timed 3-hit combo. Hitframes happen on corresponding strike animation frames; distinct close-range physical hitboxes with +/-32° facing arc.
- Low-green air displacement arcs/trails, synced to fists/feet. Trails fade behind actor and NEVER become projectile bolts at long range. Character physically dashes only if an attack includes movement.
- Konoha Senpu hits near, Great Whirlwind adds combo AOE, Rising Wind launches, Shadow of Dancing Leaf follows juggle, Front Lotus grabs with boss-safe limit, Drunken Fist evasive, Gates modify all motion and impact animation.
- Gate 1/3/5 costs and exhaustion, remove weights animation and speed difference. Audio: footstep/air slice/heel impact, no Naruto Rasengan SFX.

## Neji
- Default basic is Jūken palm contact 80–105px reach, actor faces target and action 200/210/220 are actual palm strikes.
- Chakra-point hit debuff: slight slow or temporary enemy jutsu interruption; boss telegraph windows unchanged except authorized stun.
- Eight Trigrams Sixty-Four Palms is a CLOSE-RANGE target-locked timed sequence using **6 visual stages** (2,4,8,16,32,64 indicated cumulatively). Mechanically distribute exactly 64 small contacts, with batched damage and sprite animation so hit callbacks still have true attack cadence; do NOT spawn 64 huge FX sprites per frame.
- Version progression: eight/sixteen/thirty-two into sixty-four; anime-only 128 as high-rank option. Proper Byakugan ring and black-white audience vignette only when ultimate is activated, not permanently obscuring gameplay.
- Kaiten is close protective spin/parry and Vacuum Palm is the rare documented SHORT-MID ranged variant (never default).
- No stolen Hinata Twin Lion Fists.
- Sound: fast physical chakra-point strikes with increasing cadence and one finisher, not generic rasengan.wav.

## Shared combat foundation
Build per-character CombatProfile: mode melee/projectile/zone; range, startup, active, recovery, auto-target prioritization, actor_action_200/210/220, queueing, hitstop, cooldown, SFX, VFX, facing lock and hitboxes. Disable global _fire_kunai for Lee and Neji rather than painting default kunai invisible while keeping ranged damage.
At 1× and 5× prevent tunnelling and double collisions. Respect boss 6% per-hit caps. Deterministic stress tests run 60 fps for 10 seconds with 10–100 targets; verify 0 damage on far isolated target >300px with only level-1 melee.
Screenshots and 8s video for each hero showing hit reaction and true 64-Palms chain.
Canonical sources: https://naruto.fandom.com/wiki/Rock_Lee ; https://naruto.fandom.com/wiki/Neji_Hy%C5%ABga ; https://naruto.fandom.com/wiki/Eight_Trigrams_Sixty-Four_Palms ; https://naruto.fandom.com/wiki/Eight_Trigrams_Vacuum_Palm.
