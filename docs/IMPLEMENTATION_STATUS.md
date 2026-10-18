# Implementation status · 0.3.0

## Confirmed decisions

- Shared pool 1–60; exactly 20 unique draws; free cards.
- Each player receives two main cards and one of each bonus: six entries total.
- Main grid stays 5×5. A 25-distinct-number full card cannot finish with only 20 draws.
- Four separate bonus cards, with exact names Coin flip, Duck hunt, Pačinki, Go CRazy.
- Qualification counts: 3, 4, 4, and **unconfirmed** respectively.
- Signed multiplier bounds: −50…+50, −100…+100, −200…+200; no analogous small design cap for Go CRazy.
- Initial base: 20 Pesos × multiplier.
- Duck hunt is a reveal/cover/shuffle/choose game. An unanswered choice or departure must still get a server-picked result.
- Coin flip and Pačinki use a common server-selected multiplier for qualified players, including nonresponders. Go CRazy shared-result semantics need reconciliation with its later pointer-choice description.
- Latest Go CRazy specification: 64-segment wheel, three selectable prize pointers; the stop at the selected pointer determines the multiplier.
- Original blue architecture/assets; normal Roblox controls; discreet credit “Created by Kikapucchino”.

## Required answers before dependent gameplay can be finished

| Area | Still unspecified |
| --- | --- |
| Main cards | Winning patterns, free center yes/no, base reward for a completed pattern and whether more than one pattern can pay per card. Card count is confirmed as two. |
| Coin flip | Two exact face multipliers and probabilities. 3×/20× were examples, not an accepted distribution. |
| Duck hunt | Exact values and how many covered objects carry each value. |
| Pačinki | Exact slot values, slot counts, and probabilities. |
| Go CRazy | Qualification count, all 64 sector values, probabilities/equal sector chance, pointer behavior, any secondary choices or multiplier combinations. Is a shared spin allowed to give different pointer results to different players, or must every qualifier receive the same multiplier? |
| Negative results | Deduct saved balance or this round's earnings? Can balances be negative? What happens when funds are insufficient? |
| Coordination | Interrupt drawing or queue after ball 20? Once per player per round or retrigger? If retriggering, what creates a fresh qualification? |
| Numeric representation | Helpers currently support integer multipliers. If fractional outcomes are intended, their precision/rounding rules must also be specified. |

The timeout/departure question is answered: automatic Duck selection; common outcomes in the other bonuses. It does not need to be answered again, except for the Go CRazy pointer conflict above. Actual settlement of these outcomes cannot be enabled until values, timing and deductions exist.

## Runtime versus groundwork

The active controller executes assignment → synchronized 15-second intermission → drawing/start cue → twenty draws → last call → qualification summary → participation results → reset. The start cue occupies 1.5 seconds after countdown zero. Cards and fixed multipliers are assigned before countdown begins. Eligibility updates on each draw. It can flag all three configured bonus types independently in one round; there is no single-bonus restriction. The unconfigured Go CRazy card does not qualify from an empty number list.

**No real bonus queue runs yet.** Retrigger policy, interruption timing and bonus-resolution phases depend on the requested decisions. There is no placeholder spin that pretends to award a real outcome.

`GameRules` now deals two 5×5 cards with no repeated numbers inside a card. All 25 cells are currently numbered; the unanswered free-center decision is not treated as a final rule. Manual server-validated marks are active, including after a previous draw. Main pattern validation and payouts remain disabled pending center/pattern/base-reward decisions. Auto-mark was explicitly removed by the new specification; legacy saved settings and requests cannot re-enable it.

Each card independently receives an integer multiplier from 1 through 20. `Config.Main.MultiplierWeights` contains 20 weights of 1: each result has probability 1/20 = 5%. To change odds, edit the corresponding nonnegative integer weights; probability is weight divided by their sum. The sum must be positive. This table is the sole distribution; spending/player behavior is never an input. Multipliers do not change mid-round and are disclosed before the first draw.

`claimMainReward` provides one-time multiplication of a server-determined eligible main-card base reward. Its tests use fixture base rewards only. It is not called by the live controller while base rewards and pattern eligibility remain unconfirmed, and does not multiply participation or bonus results.

`BonusRules` is a pure helper, not a live service. Its common-outcome cache and per-player receipts are scoped to a server round. Duck selection consumes a **server-owned mapping supplied by the future controller**, with automatic index selection when no answer is supplied. Mapping creation, covered-object animation, deadlines, departure settlement and persistent receipts are not integrated. Test outcome tables are fixtures only; none are production prize distributions.

`ExactInteger` computes signed decimal payouts without converting huge multipliers to floating point, and formats long values for display. Its 1024-digit guard is a technical resource limit, not a small Go CRazy design cap. Overflow is rejected before output. Balance addition, schema migration and an atomic/idempotent persistent bonus ledger must be implemented with the confirmed deduction policy. The current version-1 DataStore schema is intentionally unchanged; its normalizer caps numeric Pesos at 1,000,000,000. Do not feed huge or signed bonus amounts into that schema.

The server still pays the previous build's 20-Pesos participation reward once after a participating player has seen a draw. A successful manual mark, intentionally opening cards, or equipping the holder establishes participation; changing volume settings alone does not. Merely receiving the default visible panel does not establish participation. Leaving before the first ball pays nothing. This is not a new pattern reward or bonus payout.

## Audio and presenter

See [AUDIO_SETUP.md](AUDIO_SETUP.md) for all 68 required human-voice recordings, music/effect slots, exact manifest fields, timing limits, consent/licensing and asset-permission setup. The stage character and spoken-announcement/subtitle controller are implemented; recordings are not. This build has working subtitles and intentionally silent asset slots.

One music Sound loops the current track; a sequential transition swaps it without stacking tracks. A separate voice Sound consumes the server's announcement IDs, expires outdated cues and temporarily reduces music to 22% of the selected music volume. Voice mute prevents ducking. Failed/unloaded voice assets use subtitles, never delayed speech for an old ball. Music, voice and effect volumes/mutes are separate and saved. Bonus-name cues and soundtrack slots are prepared but are not triggered by individual qualification; real shared bonus-start integration awaits bonus execution.

The enclosed three-room model, presenter and café are built with original primitives. Layout/geometry tests cover floors, ceilings, perimeter glazing, collision-clear routes, desktop tray arrangement and mobile target sizes. Actual rendered visual quality, sound, avatar movement and mobile control overlap require Studio playtesting.

## Review limits

No Evolution artwork, sounds, code, logos or exact interface was imported. No third-party license notices were removed. Retaining requested bonus names does not establish trademark clearance or permission to reproduce distinctive presentations. The title's availability has not been verified.

Read [the policy review](POLICY_REVIEW.md) before choosing a public-release implementation. No public Roblox publication or moderation approval is claimed. GitHub publication distributes the source/test build only.
