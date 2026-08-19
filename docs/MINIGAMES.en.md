# What changed in each of the 15 minigames

*[中文版本](MINIGAMES.md)*

This document answers three questions for every minigame in the rotation: **what was adapted to fit
8 players**, **whether scoring changed**, and **what was deliberately left alone**.

Two principles run through all fifteen:

1. **Four players or fewer plays vanilla.** In most minigames, not a single line of this mod
   executes below five players.
2. **Change the layout, not the game.** Only two minigames had their mechanics genuinely altered
   (Escalator Pit and Knife at the Office) — both are explained below, with the reason. Everything
   else is either "spread four positions into eight" or a change to how points are weighted.

> Headings use the game's **internal** minigame names, which may not match the display names in
> your language.

---

## First, scoring: why some minigames had to change and others did not

The scoring pipeline is vanilla — this mod does not touch it:

```
minigame produces player_scores[player]
  x 85              <- a global constant, identical for every minigame
  -> round score -> minigame total -> added to the session total
```

**The key fact: vanilla has no normalisation by player count and no catch-up mechanic.** That means
each minigame's own scoring algorithm decides how much it is worth in an 8-player session. Vanilla
uses three:

| Family | Algorithm | What happens with more players |
| --- | --- | --- |
| **A — placement** | The i-th player eliminated scores i; the survivor scores the player count | **Scales automatically** (max 4 at four players, max 8 at eight) |
| **B — accumulation** | +1 point per objective completed | **Does not scale** — worth relatively half as much in an 8-player session |
| **C — special** | Chisel Gauntlet only: starts at the player count, subtracts the survivor count each round | Scales automatically |

Family A: Disco Dodge, Burn Recycle, DVD Roomba, Junk Platform, Spine Breaker, Train Race,
Forklift Certified.
Family B: Duck Hunt, Escalator Pit, Exploding Collar Race, Green Pea, Knife at the Office,
Manufacture Gun, Smoke Break.

**Every decision below was made per minigame — there is no blanket adjustment.** Converting all of
family B to family A would flatten fifteen different rhythms into one, and multiplying everything by
a constant would distort each minigame's own pacing along with it.

---

## The fifteen

### Junk Platform

**Adaptation.** Every player stands on a physical platform of their own, so this is not an
"add another spawn point" case: one platform is a collision volume, the visual mesh, a damage
indicator ring, a crusher and an alarm speaker — five groups of nodes, all duplicated out to eight.
The four original corners are untouched; the four new platforms sit at the 45-degree bearings on a
22.5-unit radius. The camera is unchanged.

**Scoring — changed.** Vanilla's family-A formula leaves a permanent 2-point gap between first and
second place, which becomes conspicuous across eight players. The survivor now scores the number of
players eliminated, making every step worth exactly 1.

**Debris recycling — new in 1.2.** Vanilla's *only* recycler is "the debris fell off the platform",
so anything that comes to rest on top of one leaves circulation permanently; once 40 pieces are
stuck, nothing drops for the rest of the round. Eight players hit that ceiling fast, because every
player is a spawn point — one tick drops eight pieces. Debris that has been **stationary for over a
minute is now actively recycled and dropped again**. The 40-piece cap is unchanged; it is simply no
longer occupied by pieces that will never move.

### Chisel Gauntlet

**Adaptation.** Seats come from a hard-coded table of four rotations, and the fifth player runs off
the end of it. The table now holds eight entries: **the first four are byte-for-byte the original**
(0, 180, 90, -90 degrees) and the new four are the 45-degree bearings between them. No new geometry
was needed — every player already stands on a circle of radius 8 and is distinguished only by which
way they face.

**Scoring — unchanged.** Family C already scales with the player count.

### Manufacture Gun

**Adaptation.** Three things. First, the eight workstation positions were **placed by hand** — two
generated layouts were tried and rejected. Second, a start-of-round check uses a physics query to
confirm nobody spawned inside solid geometry, and nudges them clear if they did. Third — and this is
the one that matters — **the number of parts scales with the roster.**

That third point is not cosmetic. Parts are consumed once and never respawn, and this minigame has
**no time limit of any kind**: it ends only when one player is left standing. The 26 shipped parts
are not enough for eight players to each build a weapon, and two survivors who can never build one
means **a round that never ends.**

**Scoring — formula unchanged.** What changed is the weapon: cooldown and blast radius are tuned
down slightly at high player counts, because a single weapon sweeps a much larger share of a crowded
arena.

### Spine Breaker

**Adaptation.** Spawn points now come from a **pool of 25**, of which the first N are used (10 at
four players, all 25 at eight). The mod's generic spawn-expansion path was deliberately not used
here: it places new points at the midpoint between existing ones, and the four original points
surround the structure in the centre of the arena — half of those midpoints land inside a hole cut
out of the navigation mesh. Eight-player sessions also run **two devices** instead of one, with a
retirement rule so a single device does not chase the same player forever.

**Scoring — changed** to placement-based, with a uniform step of 1 at every player count.

### Disco Dodge

**Adaptation.** Spawn points only — nothing else. This minigame very nearly supports eight players
as shipped: the tile grid is generated from a row and column count and self-centres, and symbol
assignment, tile selection and scoring all iterate over the tiles rather than over players.

**Scoring — unchanged** (family A, already scales).

### Duck Hunt

**Adaptation.** Vanilla is one hunter plus N-1 ducks, so the duck count already tracks the roster.
The real blocker was that the scene ships **three duck spawn markers**, and the fourth duck runs off
the end. Extra markers are now created at runtime and **deliberately not baked into the scene** —
the marker list gets shuffled, so baking them in would change where ducks spawn in four-player
games too.

**Mechanics — changed.** Six or more players run **two hunters**. One hunter against seven ducks was
lopsided in testing, so the mod preserves vanilla's roughly one-hunter-per-three-ducks ratio instead
of its literal hunter count. Supporting changes: magazine size and firing interval are tuned across
five player-count brackets, hip-fire spread was added, and the role reveal screen colour-codes
whether your bracket is buffed, nerfed or neutral.

**Scoring — changed** to placement-based (step of 2). This minigame also carries its own weighting
factor in the session total (x0.5 by default, x0.8 at six players), because its number of sub-rounds
is player count divided by hunters per round — a different relationship to roster size than any
other minigame has.

### Smoke Break

**Adaptation.** Seats go from four to eight, inserted into the gaps along the existing arc. The hard
part was not array lengths: **the art was authored by hand for four fixed seats**, in five separate
places (blood decals, smoke particles, revolver rotations and more), each of which had to be
extended to match. Final seat positions were tuned by hand.

**Scoring — changed** to placement-based. See [Not fully verified](#not-fully-verified).

### Exploding Collar Race

**Adaptation.** Spawn points, and essentially nothing else. Mines are generated procedurally across
the arena polygon at a minimum spacing, so their count follows the area rather than the roster, and
the file contains no other fixed-length array indexed by player. The eight spawn points were placed
by hand.

**Scoring — changed** to placement-based (finish placement plus a full-health bonus), then weighted
at **x0.75**. Placement scoring roughly doubled what this minigame was worth, and it runs three
rounds; without the trim it would overshadow the rest of the rotation. See
[Not fully verified](#not-fully-verified).

### Green Pea

**Adaptation.** Four seats become eight. **The original four are untouched**; two new seats are
inserted on each side of the table. Chair meshes, blood decal groups and the eating animation's
seat mapping were all extended to match, and cans sitting where the new seats go are cleared.

**Scoring — changed** to placement-based, by finishing order. See
[Not fully verified](#not-fully-verified).

### DVD Roomba

**Adaptation.** Spawn points, four to eight, computed by this minigame rather than by the generic
path — the generic midpoint algorithm produces two coincident points on this arena. The new four sit
on a radius-5 circle, interleaved with the originals.

**Scoring — changed** to placement-based. See [Not fully verified](#not-fully-verified).

### Escalator Pit

**Adaptation — the largest in the mod.** Vanilla ships four escalator lanes; this runs **eight in one
arena**. The handrails are a single sculpted mesh spanning two lanes each and cannot be split, which
locks the cloning step to two lanes at a time. The backdrop and platform therefore have to be
stretched by the same factor — without it the four outer players stand off the edge of the platform —
and the arena lights have to be cloned along with it, because the ambient light is pure black and an
uncloned arena is a void.

A "two arenas, four players each" version was built and worked, but the two groups could never see
each other, and the whole approach was scrapped. **Eight players competing in one shared arena, all
visible to one another, is the trade this mod makes.**

**Mechanics — changed.** Vanilla's escalator speeds up to track the fastest player, which at eight
players means somebody can always hold the pace and the round drags. It now runs at a **fixed speed
that ramps with time** (0.35 at the start, +0.03 per second, capped at 2.0), turning the minigame
into a pure endurance test.

**Scoring — changed** to placement by survival order (step of 2). See
[Not fully verified](#not-fully-verified).

### Train Race

**Adaptation.** Eight spawn points, repositioned so none overlap. A disconnect hole was also
plugged: vanilla does not add a disconnecting player to the eliminated list, so they score nothing
while the total is still computed from the starting roster.

**Scoring — unchanged** apart from that disconnect fix. See
[Not fully verified](#not-fully-verified).

### Knife at the Office

**Adaptation and mechanics.** This minigame has a structural flaw that **deadlocks at eight
players**. The syringe appears on the Nth search of the round, where N scales with the roster — but
containers can only be searched once, and there are a fixed number of them. At eight players there
is roughly a coin-flip chance that **every container is exhausted before the syringe appears**, and
since the hunt phase never begins, no timer exists to break the deadlock. The threshold is now
derived from the actual container count at runtime, so it is always reachable.

Sessions of 5-8 players also get a **second syringe**, preserving vanilla's one-infected-per-four
ratio. There is only one way to wire that in: **the hunt phase is deferred until both syringes have
been found**, because vanilla disables searching globally the moment the first one turns up. The
first finder is infected immediately but not revealed; both syringes must be in hand before the
reveal happens. The survivor indicator lights were extended to eight.

**Scoring — changed**: +2 for surviving. See [Not fully verified](#not-fully-verified).

### Forklift Certified

**Adaptation.** Each player *owns* a delivery bay here, and vanilla ships four. Rather than adding
bays, eight players play as **four teams of two** sharing the original four. The round structure is
therefore identical to vanilla's — four teams eliminated down to one, three rounds.

**Scoring — unchanged.**

### Burn Recycle

**Adaptation.** Vanilla arranges four stations by rotating each player 90 degrees, which wraps at the
fifth player — players 5-8 land exactly on top of players 1-4. Stations are now placed every **45
degrees**, with the odd-numbered ones **pushed 2 units outward** to form an inner ring of four and an
outer ring of four. The push is necessary: the shipped art already fills the ring at four stations,
so eight in a single ring makes the consoles intersect.

Supporting changes: the conveyors are shortened and re-centred for the new layout (with the UV step
scaled to match, or the belt visibly rolls slower than the cargo on it); the surrounding walls and
the central incinerator are hidden above four players so the arena stays readable; and a parts
leaderboard appears in the corner at the end of each round, because each player can only see the
scoreboard at their own station.

**Scoring — unchanged** (already placement-based).

---

## Behaviour at four players or fewer

**Gameplay is unaffected.** In minigames that gate on player count, no mod code runs at four or
fewer.

**A few visual differences remain.** Some arena expansions are not gated, so you will see the extra
chairs, platforms or spawn markers in a 2-4 player session. Known cases: Green Pea, Junk Platform,
DVD Roomba, Spine Breaker, Chisel Gauntlet, and the survivor indicators in Knife at the Office.
**None of them affect play — they are only visible.**

The briefing screen and the end-of-round scoreboard use the 8-row layout at every player count
(scaled down to fit eight lines).

---

## Not fully verified

Entries linking here mean **the scoring change itself has not been checked number-by-number on a
live session**.

The reason is specific: these minigames cannot be measured with idle bots. Bots do not smoke, do not
eat, and standing still in Exploding Collar Race simply gets them harvested — the logs read
"everyone scored zero" no matter how many times you run it. Verifying each one properly costs a full
eight-human session.

**Their adaptation work — whether eight players can actually get in and play — has been verified on
live sessions.** What has not been confirmed is that the resulting point spread is complete and free
of duplicates. A glance at the settlement line in the log during a real session confirms it.

---

## Infrastructure changes (not specific to any minigame)

- Multiplayer cap raised from 4 to 8, including lobby seats, a second row of chairs, and the
  character preview slots
- The briefing screen and the 3D end-of-round scoreboard extended from 4 rows to 8, scaled down to
  fit
- The intermission invite buttons extended to 8 and aligned to their rows
- A generic spawn-point top-up for minigames that do not manage their own
- A `+overtime` suffix on the version string, so modded and unmodded clients cannot join each other
