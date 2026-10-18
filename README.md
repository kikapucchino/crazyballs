# Cloudpop Commons · build 0.5.0

A Roblox multiplayer card party game with shared ball draws, a blue three-room observatory, collectible cosmetics and pets. The main-card game is playable solo or with friends. Bonus payout rules are still incomplete; this is a development build, not a finished public release.

## Download and play

1. Open **[CloudpopCommons-Studio.zip](dist/CloudpopCommons-Studio.zip)** → **Download raw file** → extract `CloudpopCommons.rbxl`.
2. If that fails, open the repository home page → **Code → Download ZIP**, then find `dist/CloudpopCommons.rbxl` inside.
3. Roblox Studio → **File → Open from File** → open the new `.rbxl` → **Play (F5)**.
4. Use **Cards** or equip the card-holder Tool. Desktop cards start open; touch starts collapsed. Tap matching called numbers on main and bonus cards. The tray scrolls without shrinking its 44-pixel buttons.

No plugin, API key or script copying is required. Furniture is generated when Play starts. Studio practice resets on Stop and does not need API-service permissions. Replace older downloads to see this version.

[Studio tests and Explorer hierarchy](docs/STUDIO_GUIDE.md) · [Remaining rules](docs/IMPLEMENTATION_STATUS.md) · [Passes, pets and saving](docs/FEATURE_SETUP.md) · [Audio setup](docs/AUDIO_SETUP.md) · [Policy assessment](docs/POLICY_REVIEW.md)

## Main-card rules

- Two free 5×5 numbered cards per player, plus four bonus-card entries. Numbers are distinct within each card; the center is numbered.
- Each main card starts with **8–12 random marks**. These stay fixed; their numbers can still emerge from the machine.
- Each main card has **one or two random multiplier cells**, equally likely. Each cell independently receives **10×, 20× or 50×**, with equal chances. Positions are uniformly selected without replacement.
- **Every distinct completed row, column and either diagonal pays 15 Pesos**, including lines completed by starting marks. Rewards settle once at round results, or on departure after the first draw. No flat participation/end-of-round payment remains.
- Cell multipliers multiply together **on their line** and replace the old card-wide multiplier. An ordinary line pays 15; a 10× line pays 150; a line with 20× and 50× pays 15,000. A multiplier can belong to several different winning lines. Full house has no separate extra reward.
- The server draws **20 unique numbers from 1–60**, after a shared 15-second intermission. Earlier calls remain markable through Last Call. Purchases never change the shared deck or these dealing distributions.
- **◇** = starting mark, **•** = called/unmarked, **✓** = marked. Completed lines receive a cyan outline.

Small bonus cards retain their 3/4/4-number layouts. They receive **0–8 starting marks total**, never enough to complete any one card; at least one space remains unmarked per card. Called numbers require manual marking, or verified Auto Mark. Go CRazy's qualification count remains unconfigured, so its fourth entry cannot qualify yet.

## New presentation and shop

The enclosed lobby is approximately 89% larger than the previous layout: a draw hall, social lounge with non-alcoholic café, and separate viewing room. It has 64 native seats, larger group tables, plants, original wall art, shelves, cushions, rugs, window trim, lighting and two synchronized draw screens. Normal Roblox movement, camera and controls remain available.

A separate lobby **Robux boutique** offers previews and official purchase hooks for three guaranteed legendary cosmetic passes and the intended 60-Robux Auto Mark pass. All pass IDs ship as `0`; sales remain unavailable until actual IDs are configured. Actual platform prices are queried, not fabricated. Auto Mark marks called matches on both card types and may prevent missed marks; it is a convenience upgrade, not a cosmetic.

Four original cinematic modules and a server queue are implemented and tested with fixture outcomes: coin flip, covered Duck selection, peg-board drop and a 64-sector wheel with three pointers. They are **not triggered in production yet**: bonus values/probabilities, signed settlement, Go CRazy rules and scheduling remain unresolved. No fixture values are used as real prizes.

The requested **99-Robux offer for three random bonuses over three consecutive rounds is unavailable**. Paying for random spendable rewards raises a separate gambling/paid-random policy concern; free base cards do not resolve it. See the policy assessment.

## Saving, progression and missing assets

Pesos buy clearly priced guaranteed marker/card skins and three original 500-Pesos pets. Session-locked profiles save balances, cosmetics, pets and settings with retries/autosave. Positive line payouts enter the global 24-hour records only after their profile save succeeds; Studio payouts are excluded. The current balance cap is 1,000,000,000 Pesos; only the amount actually credited is recorded.

The permanent free-chest interface and bookkeeping exist, but claims/boosts remain disabled pending reset, strength, cap, stacking and reward rules. Recent bonus history remains empty until real bonus settlement is configured.

**The package is silent.** It includes subtitles and named slots for human voice, lobby music, a bonus intro and four distinct soundtracks, but no licensed audio IDs. YouTube references are retained as references only; no recordings were downloaded, substituted or uploaded. Missing tracks stay silent. The audio controller supports sequential fades, narration ducking and separate saved volume/mute controls.

## Build and validation

```sh
bash tools/bootstrap.sh
```

With the pinned official Luau/Rojo tools already installed:

```sh
python3 tools/check.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/build_place.py
```

**119 checks passed: 114 Luau checks and five packaging tests.** Automated checks execute the actual Luau modules/controllers using mock Roblox services, including server-authoritative marking/rewards, saving failures, queue choices/timeouts, all four cinematic states, audio transitions, room routes and mobile geometry. Python tests verify source embedding, place headers, checksums and ZIP contents. **These do not constitute Roblox Studio, real Marketplace, rendered mobile or live cross-server testing.** Follow the Studio guide before public release.

`dist/` includes the binary `.rbxl`, XML `.rbxlx`, a ZIP containing the binary place, and SHA-256 checksums. GitHub publication is not Roblox publication or moderation approval. No title/trademark availability is claimed.
