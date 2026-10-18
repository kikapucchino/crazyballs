# Cloudpop Commons · build 0.2.0

A Roblox multiplayer lobby with shared ball draws, free bonus cards, a compact HUD, and an equippable card holder. **This is an intermediate playable build, not the completed bonus game.** Unspecified rules remain disabled rather than being invented.

## Download and open

1. Open **[CloudpopCommons-Studio.zip](dist/CloudpopCommons-Studio.zip)** and click GitHub's **Download raw file** button. Extract `CloudpopCommons.rbxl`.
2. If that download fails, go to the repository home page → **Code → Download ZIP**. Extract it and find `dist/CloudpopCommons.rbxl`.
3. In Roblox Studio: **File → Open from File** → choose `CloudpopCommons.rbxl` → **Play (F5)**.
4. Walk around, sit at a table, equip **Cards** from your backpack, or press the compact **Cards** button. Open **Bonuses** to follow your qualifying numbers.
5. Watch the machine draw exactly **20 unique balls from 1–60**. Opening your cards during the round counts toward the existing **20-Pesos participation reward**. You can spend earned Pesos on the displayed guaranteed cosmetics.

No plugin, API key, external model, paid asset, or manual script copying is needed. The scenery appears when Play starts. Studio practice uses temporary profiles and requires no publishing or API-service setting. Download a fresh copy to replace an older build; this does not update places you have already opened in Studio.

[Studio testing and exact Explorer hierarchy](docs/STUDIO_GUIDE.md) · [Unresolved rules and implementation status](docs/IMPLEMENTATION_STATUS.md) · [Official policy review](docs/POLICY_REVIEW.md)

## Implemented

- Original navy/blue/ice observatory with tables, eight usable seats, paths, planting details, open canopy, central animated machine and large shared draw display. Normal Roblox avatars, camera and movement are retained.
- Compact HUD, current ball, 0/20–20/20 counter, recent balls, Pesos, collapsible cards, four bonus-card entries, cosmetic shop, saved volume/accessibility settings and discreet creator credit.
- A server-created, non-droppable card-holder Tool visible to other players. Equipping it opens your cards; respawn grants it again.
- One authoritative shuffled 60-number pool per round, exactly 20 draws, automatic individual bonus matching, late-join spectators, fresh cards next round, and multiple simultaneous qualifications.
- Three-number Coin flip card, four-number Duck hunt card, four-number Pačinki card; Go CRazy entry is explicitly pending its qualification count.
- A 5×5 main-card UI and validated marking component. **No main cards are currently dealt:** count, winning patterns, free-center choice and pattern rewards need confirmation.
- Original participation reward and six guaranteed Pesos cosmetics; no wagers, paid entry, Robux prompts, paid randomness, currency transfer or cash-out.
- Existing session-locked DataStore saving, failure handling, retries, autosave, leave settlement and shutdown handling. Old volume-less profiles receive defaults.
- Audio controller with separate volumes, four effect voices and one music voice with sequential fades. **Audio asset slots are empty; this build is silent.**

A preview round lasts approximately 110 seconds: 12 seconds of intermission, 80 seconds of draws, 8 seconds of last call, and 10 seconds of results. This timing does not decide whether future bonuses interrupt or follow the draw.

## Explicitly unfinished

**No bonus animations, bonus selection UI, queued bonus execution, or bonus payouts are active.** The four cards track eligibility only. Coin/Duck/Pačinki signed bounds are preserved in configuration. Tested calculation helpers support shared Coin/Pačinki outcomes, Duck automatic fallback, exact signed integer multiplication by 20 and duplicate computation receipts; they are not integrated with balance mutation or persistent bonus receipts.

Go CRazy's **64 segments and 3 selectable prize pointers** are recorded. Sector values/probabilities, qualification count, choice versus shared-result semantics, secondary choices, and multiplier composition remain unconfirmed. Its playable wheel is not implemented.

Main pattern wins, negative deductions, bonus timing/retriggering and the large-balance schema migration await decisions. Changing a configuration flag alone does not implement these systems. Existing version-1 saves remain compatible and use the existing nonnegative, bounded numeric ledger; huge/signed bonus amounts are never written to it.

The two layout-reference screenshots mentioned in the pasted specification were unavailable. This build follows the written blue-lobby requirements and does not claim an exact reference-image match. Custom licensed music, Robux cosmetic products and real Studio visual/mobile/multiplayer validation remain outstanding.

## Build and verify

```sh
bash tools/bootstrap.sh
```

This installs pinned official Luau and Rojo tools with checksum verification, checks the source, and rebuilds the place. Tools live outside the checkout under `/workspace/.cloudpop-tools` (override `CLOUDPOP_TOOLS_DIR` elsewhere). With tools already installed:

```sh
python3 tools/check.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/build_place.py
```

Current validation: **48 Luau checks + 5 packaging tests**. These execute actual modules/controllers against mock Roblox services and test unique draws, synchronization, qualification, malformed requests, signed bounds, exact arithmetic, idempotence, startup, tools, audio, session conflicts and save failures. They do not replace Roblox Studio's renderer, networking, audio permissions, mobile emulator or live DataStore tests.

The build creates `.rbxl`, `.rbxlx`, a ZIP containing the binary place, and SHA-256 sidecars in `dist/`. Rojo serializes every script into the proper service. Optional live-sync configuration is in `default.project.json`.
