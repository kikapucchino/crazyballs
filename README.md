# Cloudpop Commons · build 0.4.0

A Roblox multiplayer party-game work in progress with a walkable three-room observatory, six card panels per player, shared ball draws, and a stage presenter. Main patterns and bonus payouts still await the creator's remaining rules; this is not a finished release.

## Download and play

1. Open **[CloudpopCommons-Studio.zip](dist/CloudpopCommons-Studio.zip)** → GitHub's **Download raw file** → extract `CloudpopCommons.rbxl`.
2. If that fails, use the repository home page → **Code → Download ZIP**, extract it, and find `dist/CloudpopCommons.rbxl`.
3. Roblox Studio → **File → Open from File** → open the new `.rbxl` → **Play (F5)**.
4. Explore the draw hall, social lounge/café and viewing room. Equip **Cards** or use its button. On desktop the cards start open; touch devices start collapsed to leave movement controls available.
5. Two free 5×5 main cards appear before the shared **15-second countdown** ends. Each has a fixed **1×–20× multiplier**. Tap called numbers to mark them. **•** means called/unmarked; **✓** means marked.
6. Follow the shared draw through **20 unique numbers from 1–60**. Coin flip, Duck hunt, Pačinki and Go CRazy appear in a **2×2 group beside the main cards**. Narrow screens scroll without shrinking the number buttons.

The packaged place needs no plugin, API key or manual script copying. Scenery is created when Play starts. Studio practice is temporary and requires no API-service permission. Replace old downloaded copies to see this update.

[Studio testing and Explorer hierarchy](docs/STUDIO_GUIDE.md) · [Remaining rules](docs/IMPLEMENTATION_STATUS.md) · [Supplying licensed human voice/music](docs/AUDIO_SETUP.md) · [Policy review](docs/POLICY_REVIEW.md)

## New in 0.4.0

- Server-verified Auto Mark pass with official purchase flow, actual price/mismatch display and saved toggle. Set its real ID before sales are available.
- Three original 500-Pesos pets with 3D previews, collect/equip/unequip, saved ownership and visible smooth following.
- Permanent free-chest interface and tested claim/save bookkeeping. Claims and probability effects remain gated by the unanswered reset/reward/boost rules.
- Supported system chat, grouped last-four-bonus history and a persistent cross-server rolling 24-hour highest-payout panel. Only committed positive payouts enter the global record; Studio transactions are excluded.

See **[feature configuration and limitations](docs/FEATURE_SETUP.md)** for exact pass setup, chest proposal, persistence design, policy implications and live testing steps.

## Included gameplay and presentation

- Fully enclosed draw hall, social lounge and separate viewing room, with floors, ceilings, glazed exterior walls, open interior doorways, trim, lights, furniture, seating and exterior island/sea views.
- Presenter stage and original character, central ball machine, main draw screen, second live viewing screen and a furnished **non-alcoholic Sky Café**.
- Normal Roblox avatars, camera, movement, chat and backpack controls. A replicated card-holder Tool survives respawn without duplicates.
- Bottom-center horizontal main cards with an adjacent 2×2 bonus group. Mobile uses navigation/scrolling and 44-pixel number targets; movement areas are reserved.
- Exactly two distinct-number main cards plus one entry for each of the four bonuses. Go CRazy's numbers remain pending its unconfirmed qualification count.
- Server-assigned main-card multipliers fixed at deal time: **each integer 1–20 has a 5% chance**. Relative weights are editable in `Config.Main.MultiplierWeights`; purchases/behavior do not alter them.
- Free manual marking plus the newly requested optional permanent Auto Mark pass integration (intended 60 Robux). The real pass ID remains unconfigured; owners are server-verified and actual platform pricing is displayed.
- One server deadline for the 15-second countdown; drawing starts automatically at zero with the shared start cue, followed by the first ball after that cue's 1.5-second slot. Twenty balls follow at four-second intervals.
- Queued presenter announcements/subtitles, an explicit recording manifest for all 60 numbers and transition/bonus names, separate music/voice/effects volumes and mute controls, preload handling and voice ducking.
- Existing server-authoritative cosmetic purchases, participation reward, session-locked saving, retries, autosave, late joins and shutdown handling remain in place.

**No recordings are included.** Every voice/music/effect asset slot is empty. Subtitles work; the distributed build is silent. No synthetic speech or recognizable-person imitation is used. The music engine loops a supplied lobby track, switches a single music channel for bonuses, and ducks it while a loaded human recording plays.

## What remains unfinished

The creator confirmed **two main cards + four bonus cards = six cards**. Winning patterns, free-center treatment and base pattern rewards remain unanswered. All 25 cells currently receive numbers for dealing/marking; no free-center privilege or pattern payout is applied. A tested reward helper multiplies an eligible main-card base reward once by that card's multiplier, but is not called until pattern/base rules exist. It never multiplies participation or bonus rewards.

Coin/Duck/Pačinki qualification counts (3/4/4), signed bounds and names are preserved. Their presentation/selection games, queue execution and payouts remain inactive because distributions, negative-balance rules and timing/retriggering are unconfirmed. Go CRazy's 64 segments and three pointers are recorded, but its qualification count, sector values/probabilities and pointer-result rules are still missing. Existing bonus calculation helpers remain tested; they are not finished playable bonuses.

The current build pays only the existing 20-Pesos participation reward. Main multipliers do not change it. Main marking or intentionally opening/equipping cards establishes participation; joining and leaving before the first ball pays nothing. Guaranteed cosmetics retain their displayed prices. There are no wagers, paid entry, paid chance boosts, transfers or cash-out. Auto Mark uses the official Robux prompt only after a real pass ID is supplied.

The referenced layout screenshot was unavailable, so the implementation follows the written layout. Actual Studio visual/touch/multiplayer tests, licensed audio and resolution of the previously documented gambling-policy concerns are still required.

## Build and checks

```sh
bash tools/bootstrap.sh
```

This installs pinned official Luau and Rojo tooling with verification, runs tests and builds the Studio artifacts. With tools already installed:

```sh
python3 tools/check.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/build_place.py
```

**99 checks pass: 94 Luau checks and 5 packaging tests.** They cover pass ownership, pet purchases, chest duplicates, durable payout publication, cross-server notifications, ties/expiry, truthful system messages and the earlier gameplay. They execute actual modules/controllers with mock Roblox services, sample thousands of decks/cards, verify fixed multipliers/manual marks/shared deadlines, test audio queueing/ducking and save failure cases, and check enclosure geometry plus a collision-clear route into each room. Geometry and UI-coordinate tests do not replace Studio rendering, real avatar navigation, network latency, touch controls or asset-permission testing.

`dist/` contains `.rbxl`, `.rbxlx`, a ZIP containing the binary place, and SHA-256 sidecars. Optional Rojo live sync uses `default.project.json`.
