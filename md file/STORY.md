# Story and design: Chronicles of the Signal

Phase 2 draft. Everything here is a proposal; edit freely. Items marked **(decide)** are open choices.

---

## Premise

The city of **Vantage** runs on **the Signal**, a network that carries everyone's memories, money and identity. Six months ago the Signal went quiet in the lower districts. People forgot who they were. The **Grid** (the Digital Memory Grid) is where those memories ended up: a ghost copy of the city that lines up with the real streets.

## The player

A **Runner**, a courier who can "phase" between the Physical World and the Grid. They wake in an alley with no memory of their own name, only the ability to swap worlds (Space) and break into terminals.

## What the Signal is

A living archive. Whoever controls it controls what the city remembers. The **Curator** (the antagonist, an AI/corporation) is deleting memories to keep the city docile. Each hacked terminal frees a piece of memory.

## Beats (8)

1. **Wake up.** Runner wakes in Static Row with no memory. The Fixer finds them. Teaches: Space swaps worlds.
2. **First crossing.** A wall exists only in the real world. Swap to the Grid, cross, hack the terminal, open the gate. (Built.)
3. **First fragment.** A memory fragment sits in the Grid only. It shows a face the Runner almost knows.
4. **The relay.** The Fixer explains the gate leads to the relay tower; the Curator's trace is tightening.
5. **Trace.** The Curator starts hunting the Runner (threat appears, drains Signal Integrity).
6. **The Archive.** District 02: a vault of deleted memories. The Runner learns they once worked for the Curator.
7. **Choice.** Restore the city's memories (and lose their own) or keep them and let the Curator win. **(decide)**
8. **Ending.** Short end screen with "play again".

## Districts

| # | Name | Teaches | Status |
|---|---|---|---|
| 01 | **Static Row** | Moving, talking, swapping worlds, one-world walls, hacking, doors, pickups, levers, timed gates | Built |
| 02 | **The Archive** | Combining worlds under pressure: alternating shelves, three keys, a timed gate with a drone shortcut, the Curator's core and the final choice | Built |
| 03 | **Relay Tower** (optional) | Timed doors, boss-style finale | Stretch |

Keep the first release to Districts 01 and 02.

## Threat **(decide)**

Recommendation: **trace drones in the Grid only**. Simple patrol paths that cost Signal Integrity on contact, safe in the Physical World. This reuses the existing "signal lost" reboot and gives a reason to swap back.

## Tone and dialogue style

- Noir cyberpunk, dry and short. Lines of one or two sentences.
- Characters speak in plain language, with a few wire/signal metaphors ("ghost in the wire", "dead air").
- No long exposition: one idea per dialogue box.
- Speaker labels in caps: FIXER, DOOR, SYSTEM.

## Characters

- **The Runner** (player): silent protagonist.
- **The Fixer**: gruff guide, physical world only. Knows more than they say.
- **The Curator**: voice only, appears on terminals as SYSTEM messages.

## Ending (decided for the demo)

At the Curator's core the Runner learns they once carried out the deletions. Two endings, set in `flags["ending"]`:

- **Restore:** the city's memories return, the Runner forgets themselves.
- **Keep:** the Archive stays sealed, the Runner remembers but the Curator keeps deleting.
