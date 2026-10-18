# Cloudpop Commons

A playable Roblox prototype about shared sky draws, satisfying stamps, and a cozy wind-powered workshop. Built for solo play and small multiplayer sessions, with mobile and PC controls.

## First step: play in Roblox Studio

1. Download **[dist/CloudpopCommons.rbxl](dist/CloudpopCommons.rbxl)** to a Windows or macOS computer with Roblox Studio.
2. In Studio, choose **File → Open from File** and open it.
3. Press **Play (F5)**. The workshop and interface are created when the server starts.
4. Choose either delivery objective, mark matching numbers, and complete a horizontal row. Try **Auto-mark** and the **Tailwind Switch** preview.
5. Let the round finish. Verify the reward breakdown, then spend earned Pesos in **Cosmetic wardrobe**.

The place contains its `CloudpopUI` directly in `StarterGui`, including a visible startup screen. Build **0.1.2** is produced by Rojo's standard Roblox serializer; download the binary `.rbxl` rather than an older hand-built XML file. No plugin is needed to open it. The client reports startup stages, waits for dependencies with timeouts, and displays initialization errors. The `.rbxlx` download is also regenerated with Rojo for compatibility.

No plugin, external models, API key, or paid asset is needed. An unpublished place runs in **Studio practice**: balances and cosmetics reset when the session stops. Do not enable cloud saving just to try the game.

**Start with this one playtest.** Then follow [the Studio guide](docs/STUDIO_GUIDE.md) for two-client testing, touch layouts, and persistence.

## Included

- Two free, different-layout 3×3 cards per player; the pair always shares at least one number.
- One server-shuffled deck, numbers 1–24 without replacement, with 18 draws per round.
- Any horizontal row completes a card. Both cards can earn their reward, and no player ends the round for others.
- Two equally rewarded objectives: five distinct marked numbers, or one number marked on both cards.
- Tailwind Switch: once per round, preview and confirm a two-cell swap on one card, or keep the layout. Marks follow numbers.
- 20 Pesos for active participation, 15 per completed card, and 10 for the objective; maximum 60 per round.
- Six named cosmetics, including the two defaults. The other markers cost 60 Pesos; card skins cost 150. All purchases grant the displayed item and equip it.
- A responsive, scrollable UI, touch-friendly card buttons, non-color mark indicators, free automatic marking, reduced motion, and a local sound toggle.
- An original primitive-built workshop and locally animated machine. The decorative balls do not control outcomes.
- Server authority over card generation, draws, marks, event choices, completion, balances, ownership, and prices.
- DataStore profiles with `UpdateAsync`, session leases, retries, autosave, leave settlement, and shutdown saves. Studio saves require explicit opt-in.

A round currently takes **140 seconds**, including a 12-second preparation phase, 90 seconds of draws, an 18-second event, 8 seconds for final marks, and 12 seconds of results. Joining after draws begin means spectating until the next deal. A valid manual mark or an objective/event/settings choice establishes participation. Auto-mark alone does not farm rewards. Leaving before any number is drawn grants nothing.

## What comes later

This is the first playable slice, not a launch-complete experience. Additional target patterns and bonus events, station decorations, a fully modeled Pip mascot, custom audio, and Robux cosmetic products are postponed. There are no Robux prompts, paid advantages, random paid products, wagering, trades, or transfers.

The title's availability is unverified. Review the current Roblox policies and experience questionnaire before publication; this project does not establish moderation approval.

## Project structure

```text
src/shared/Config.luau                 Tuning, objectives, and cosmetic catalog
src/shared/GameRules.luau              Card, mark, pattern, swap, and reward rules
src/shared/Economy.luau                Profile normalization and cosmetic purchases
src/server/ProfileStore.luau           Persistence and session ownership
src/server/Workshop.luau              Original lobby built from primitives
src/server/GameServer.server.luau      Round loop and validated remote requests
src/client/GameClient.client.luau      Responsive UI and decorative animation
default.project.json                  Optional Rojo project
tools/build_place.py                  Standard Rojo place builder wrapper
tools/install_rojo.py                 Verified, pinned Rojo installer for cloud Linux
tests/                                Rules, persistence, server, and packaging checks
dist/CloudpopCommons.rbxl              Open directly in Roblox Studio
```

Exact Explorer locations and every test step are in [docs/STUDIO_GUIDE.md](docs/STUDIO_GUIDE.md). The complete Luau code lives in the files above; no code needs to be copied out of chat.

## Build and checks

With Python 3 and Rojo installed, rebuild both place formats after editing a script:

```sh
python3 tools/build_place.py
python3 -m unittest discover -s tests -p 'test_*.py'
```

The cloud setup installs the official Luau CLI from a pinned source commit and Rojo 7.5.1 from its upstream release, verifies Rojo's archive checksum, and runs all checks:

```sh
bash tools/bootstrap.sh
```

That requires Git, Make, a C++ compiler, Python 3, and HTTPS access to GitHub. It puts development tools outside the checkout in `/workspace/.cloudpop-tools`; override `CLOUDPOP_TOOLS_DIR` on another machine. Alternatively install the official Luau CLI yourself and run:

```sh
LUAU_BIN=/path/to/luau LUAU_COMPILE_BIN=/path/to/luau-compile python3 tools/check.py
```

The tests execute the real rule modules, the real persistence module against a mock DataStore, and the actual server controller and client initializer against simulated Roblox services. They test client startup and missing dependencies, malformed/stale requests, duplicate rewards, card distribution, swaps, profile conflicts, failed saves, late joins, and leaving. They do **not** substitute for Roblox Studio's renderer, networking, or live DataStore tests.

Both `.rbxl` and `.rbxlx` embed all source and have SHA-256 files beside them. Rojo handles script and instance serialization. Open the latest rebuilt output after source changes. `rojo serve` with `default.project.json` provides an optional live-sync workflow. You need Rojo to build from source; you do not need it to open and play the packaged place.
