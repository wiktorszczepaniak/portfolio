# P6 — 60 genuine skill trees, not 480 cloned stat points

## Grid
10 trees per fighter × 8 nodes = 480 nodes. ID `<hero>.<tree_id>.<node_id>`, stable even if display names are localized. Every tree has:
- n0 discover the mechanic / unlock base technique
- n1 left stance: narrow, high-damage
- n2 right stance: wider control or defensive utility (mutually exclusive with n1)
- n3 improve n1 with unique hitbox/status
- n4 improve n2 with unique positioning/status
- n5 signature evolution activated by matching prerequisites
- n6 alternate signature or cross-tree synergy
- n7 apex: canon technique or clearly labelled original mechanical upgrade

Only signature-stage moves are standalone jutsu; the other nodes are supporting transformations of the same technique. No fake "90 independent ninjutsu" from arithmetic alone.

## Naruto: 10 trees
1. Rasengan -> Odama or point-blank stun; cross with Wind -> Rasenshuriken.
2. Fūton -> spinning blades / knockback, wind convergence.
3. Kage Bunshin -> aggressive clone rush vs support decoy, Tajū Kage Bunshin.
4. Naruto Rendan -> synced melee clones / juggle.
5. Kuchiyose -> Gamakichi small support vs larger toad zone.
6. Sage -> natural energy and Frog Kata, sage Odama.
7. Kurama -> red cloak, chakra arms, KCM and Tailed Beast Ball (form-gated).
8. Ninja Tools -> Fūma Shuriken and shadow tools.
9. Kawarimi -> safe dash or counter substitution.
10. Oiroke / trickster -> decoy and control, optional non-core branch.

## Sasuke: 10 trees
1. Chidori -> hand thrust, sharp spear or Senbon.
2. Raiton -> Chidori Nagashi radial vs sword infusion.
3. Katon Gōkakyū -> Great Fireball, flame zones.
4. Hōsenka / Great Dragon Fire -> scatter flames vs Kirin storm setup.
5. Sharingan -> perception, predict, Genjutsu.
6. Kenjutsu Kusanagi -> melee slashes and chidori-blade.
7. Lion Combo -> juggle and contact.
8. Cursed Seal -> stage1 to stage2; exclusive early timeline.
9. Amaterasu / Kagutsuchi -> black fire shape control; Mangekyō path only.
10. Susanoo -> rib shield, arms, late complete avatar where canonical.

## Kakashi: 10 trees
1. Raikiri -> single lethal line vs stagger.
2. Lightning Beast Tracking Fang -> guided hound strike.
3. Raiden -> two linked lightning clones.
4. Lightning Shadow Clone -> electric paralyzing defense.
5. Suiton -> Water Dragon, Water Wall.
6. Doton -> Earth Wall, underground ambush.
7. Ninken -> summon, tracking fang trap.
8. Copy Ninja -> sharingan counter/replicate a learned *eligible* move.
9. Kamui -> scoped targeted displacement; costly, boss-safe.
10. Shiden Purple Lightning -> **post-war, alternative** progression after Sharingan loss.

## Rock Lee: 10 trees (NO ninjutsu)
1. Strong Fist -> contact combo power vs stagger.
2. Leaf Whirlwind -> spinning melee kicks.
3. Rising Wind -> launch, juggle.
4. Leaf Gale -> trip, low sweep.
5. Shadow of Dancing Leaf -> pursuit.
6. Front Lotus -> airborne grab and pile-driver.
7. Reverse Lotus -> stronger Gates-gated combo.
8. Eight Gates -> stage gates with exhaustion and true sprites.
9. Weight Removal -> nimble movement/cancel windows.
10. Drunken Fist -> evasive unpredictable physical patterns.
All "green waves" are local displaced air/energy trails locked to attack frames, never free long-range fireballs.

## Neji: 10 trees
1. Gentle Fist -> close hand combos and chakra-seal debuff.
2. Byakugan -> near-360° target awareness and counter windows.
3. Two/Four/Eight/Sixteen Palms -> cumulative precision chain.
4. Thirty-Two/Sixty-Four Palms -> timed signature barrage with close lock.
5. One Hundred Twenty-Eight Palms -> **anime-only** evolved rush.
6. Kaiten -> short-range protective spin and projectile reflection.
7. Hakke Kūshō -> unusual short/mid shock palm.
8. Vacuum Wall Palm -> compressed double palm.
9. Tenketsu Needle -> **anime-only** pinpoint debuff.
10. Defensive Gentle Fist -> counter and anti-jutsu lockdown.
No borrowing Hinata-only Jūho Sōshiken / Twin Lion Fists.

## Gaara: 10 trees
1. Sand Shuriken -> fine grain projectiles, natural ochre palette.
2. Sand Coffin -> grab/root, control radius.
3. Sand Waterfall Funeral -> punish pinned enemies.
4. Shield of Sand -> reactive automatic protection.
5. Armour of Sand -> defense vs speed trade-off.
6. Sand Clone -> decoy and counter capture.
7. Quicksand Waterfall -> spreading sand ground/slow.
8. Sand Drizzle/Hail -> zones and hard particle storm.
9. Shukaku -> **early jinchūriki** alternate transformation.
10. Kazekage -> Sand Suspension and Desert Imperial Funeral Seal, **post-extraction** route.
Gaara's visual language is actual sand dunes, small ochre grains, granular streams, coffin hands, walls, and gusts, not gray geometry.

## Cross-tree synergies
- Naruto Kage Bunshin + Rasengan = combo helper for Ōdama, not a duplicate damage buff.
- Sasuke Great Dragon Fire + Lightning = Kirin after weather setup.
- Kakashi Lightning Clone + Raiden = screen-spanning dangerous tether with finite range.
- Lee Gates + Lotus = additional grab phase at stamina cost.
- Neji Byakugan + 64 Palms = visible chakra-point lock; Kaiten upgrades remain defensive.
- Gaara Sand Coffin + Sand Burial = execution on trapped target; armor changes slow.

## QA
Automated validation: unique class IDs, 60 tree IDs and 480 nodes, no impossible branch graphs, 15 varied abilities per class, all 90 icon references present, no NaN in scaling, every skill true hitbox/CD/anim/frame VFX/SFX, all six real form branches load available sprites. Do not mark P6 complete until headless Windows and manual UI screenshots pass.
