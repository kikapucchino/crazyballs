# Implementation status · 0.2.0

## Confirmed decisions

- Shared pool 1–60; exactly 20 unique draws; free cards.
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
| Main cards | Cards per player, winning patterns, free center yes/no, reward for a completed pattern and whether more than one pattern can pay per card. |
| Coin flip | Two exact face multipliers and probabilities. 3×/20× were examples, not an accepted distribution. |
| Duck hunt | Exact values and how many covered objects carry each value. |
| Pačinki | Exact slot values, slot counts, and probabilities. |
| Go CRazy | Qualification count, all 64 sector values, probabilities/equal sector chance, pointer behavior, any secondary choices or multiplier combinations. Is a shared spin allowed to give different pointer results to different players, or must every qualifier receive the same multiplier? |
| Negative results | Deduct saved balance or this round's earnings? Can balances be negative? What happens when funds are insufficient? |
| Coordination | Interrupt drawing or queue after ball 20? Once per player per round or retrigger? If retriggering, what creates a fresh qualification? |
| Numeric representation | Helpers currently support integer multipliers. If fractional outcomes are intended, their precision/rounding rules must also be specified. |

The timeout/departure question is answered: automatic Duck selection; common outcomes in the other bonuses. It does not need to be answered again, except for the Go CRazy pointer conflict above. Actual settlement of these outcomes cannot be enabled until values, timing and deductions exist.

## Runtime versus groundwork

The active controller executes assignment → intermission → twenty draws → last call → qualification summary → participation results → reset. Eligibility updates on each draw. It can flag all three configured bonus types independently in one round; there is no single-bonus restriction. The unconfigured Go CRazy card does not qualify from an empty number list.

**No real bonus queue runs yet.** Retrigger policy, interruption timing and bonus-resolution phases depend on the requested decisions. There is no placeholder spin that pretends to award a real outcome.

`GameRules` includes 5×5 card generation and validated marking for the future confirmed configuration. Production `Main.Confirmed` remains false and the panel shows a blank layout with an explanation. Pattern validation/rewards are unfinished. Old 3×3 cards, delivery objectives and Tailwind Switch were removed from the current flow because they are not the requested game.

`BonusRules` is a pure helper, not a live service. Its common-outcome cache and per-player receipts are scoped to a server round. Duck selection consumes a **server-owned mapping supplied by the future controller**, with automatic index selection when no answer is supplied. Mapping creation, covered-object animation, deadlines, departure settlement and persistent receipts are not integrated. Test outcome tables are fixtures only; none are production prize distributions.

`ExactInteger` computes signed decimal payouts without converting huge multipliers to floating point, and formats long values for display. Its 1024-digit guard is a technical resource limit, not a small Go CRazy design cap. Overflow is rejected before output. Balance addition, schema migration and an atomic/idempotent persistent bonus ledger must be implemented with the confirmed deduction policy. The current version-1 DataStore schema is intentionally unchanged; its normalizer caps numeric Pesos at 1,000,000,000. Do not feed huge or signed bonus amounts into that schema.

The server still pays the previous build's 20-Pesos participation reward once after a participating player has seen a draw. Opening a card panel or equipping the holder establishes participation; changing volume settings alone does not. Leaving before the first ball pays nothing. This is not a new pattern reward or bonus payout.

## Audio asset slots

All IDs in `Config.Audio` are deliberately empty. Use original audio you own or suitably licensed audio permitted in this experience; set values to `rbxassetid://<actual ID>`. Verify asset access in the published private test experience.

| Slot | Intended identity/use |
| --- | --- |
| `Music.lobby` | Gentle blue-sky rhythm, relaxed social ambience |
| `Music.coin` | Bright, compact syncopated melody for the flip/reveal |
| `Music.duck` | Playful plucked rhythm for reveal, cover and shuffle |
| `Music.pacinki` | Cascading mallet melody following the descent |
| `Music.crazy` | Layered upbeat rhythm for pointer choice and wheel reveal |
| `SFX.draw`, `mark`, `qualify`, `reveal`, `result` | Short readable feedback cues |

These are briefs, not completed compositions. The runtime calls lobby/draw/mark/qualification/result slots. Bonus music and reveal slots await bonus-presentation integration. Sequential music fading uses one Sound so two bonus tracks cannot overlap. SFX uses at most four reusable Sounds. Music/SFX volume and reduced motion are saved separately.

## Review limits

No Evolution artwork, sounds, code, logos or exact interface was imported. No third-party license notices were removed. Retaining requested bonus names does not establish trademark clearance or permission to reproduce distinctive presentations. The title's availability has not been verified.

Read [the policy review](POLICY_REVIEW.md) before choosing a public-release implementation. No public Roblox publication or moderation approval is claimed. GitHub publication distributes the source/test build only.
