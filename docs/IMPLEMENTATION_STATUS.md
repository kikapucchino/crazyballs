# Implementation status · 0.5.0

## Confirmed and active

Two free 5×5 main cards and four bonus entries; shared pool 1–60, twenty unique calls, fifteen-second countdown. The center remains numbered, with no extra free space. Each main card has 8–12 permanent starting marks and one or two randomly positioned 10×/20×/50× cells. Counts and values use uniform choices. Starting numbers remain in the machine's draw pool.

All five rows, five columns and two diagonals can pay once each: **15 Pesos × the product of multiplier cells on that line**. Cell multipliers replace the old 1×–20× card multiplier; ordinary lines have factor one. Starting-completed lines pay identically. Full house has no separate extra reward. Rewards settle at round end or departure after at least one shared draw. No participation or flat round-completion payment remains. Rewards and validation run on the server; repeated client requests cannot award again.

The small Coin/Duck/Pačinki cards have 3/4/4 numbers. They share a uniformly chosen total of 0–8 starting marks allocated randomly subject to leaving one unmarked space per card. Calls do not mark automatically for nonowners. Manual bonus marking rejects uncalled numbers, stale rounds, invalid indices and duplicates. Verified Auto Mark covers both main and bonus cards. Qualification records once per card and never qualifies an empty Go CRazy entry.

The enlarged, enclosed blue lobby has three rooms, 64 native seats, group tables, café, original decorations and a physical Robux boutique. Three legendary cosmetic passes and intended 60-Robux Auto Mark use actual price queries and server ownership checks, but IDs are unconfigured. Guaranteed Pesos cosmetics/pets and saved settings remain operational in Studio practice/live profiles as appropriate.

## Bonus groundwork versus live gameplay

`PatternRules` supports rows, columns, both diagonals and full house through one validator. Active groups are shown before drawing; completed cells are outlined.

`BonusQueue` accepts only trusted server-prepared events with an eligible roster, outcome tables and a settlement function. It serializes intro/preview/choice/animation/reveal phases; rejects spectator, expired and duplicate choices; chooses automatically on timeout/departure; and publishes only validated committed results. Duck preview values must be a permutation of its private final mapping. The wheel requires 64 values, three distinct pointer offsets and one authoritative shared stop.

`BonusPresentation` implements four original fullscreen procedural scenes: flipping coin, Duck reveal/cover/shuffle/selection, animated peg-board drop, and 64-sector wheel/three pointer selection. Only eligible players see them. The normal HUD restores between active and inactive presentation; queue transitions do not overlap. Touch controls remain above the presentation; camera/CoreGui/movement are unchanged. Choices are 44 pixels tall, with scrolling, countdown and reduced motion. Tests run fixture events through the actual modules, not through a live Roblox renderer.

**No production event is enqueued and no bonus pays yet.** The future settlement caller must durably commit rewards before reporting them as committed; the presentation queue itself is not a currency ledger. Fixtures are not configured production probabilities. `BonusRules` and `ExactInteger` retain tested signed/large-integer calculations. Actual signed/huge balance migration, atomic bonus receipts and departure settlement need the rules below. Do not pass such results into the current nonnegative numeric profile (cap 1,000,000,000).

## Remaining decisions and external configuration

| Area | Still needed |
| --- | --- |
| Coin flip | Two exact face multipliers and probabilities, within −50…+50. |
| Duck hunt | Exact values and object counts, within −100…+100. |
| Pačinki | Slot values/counts and probabilities, within −200…+200. |
| Go CRazy | Qualification count, 64 sector values/probabilities, three pointer offsets, secondary choices/combinations if any. Clarify whether a common spin may pay different selected-pointer results, versus the earlier requirement that everyone receives the same multiplier. |
| Negative outcomes | Saved balance or round earnings; negative balances allowed; insufficient-funds treatment. Integer helpers exist; any fractional precision/rounding would need specifying. |
| Scheduling | Interrupt draws or queue after ball 20; once per card/round or retrigger and its reset rule. |
| Permanent free chest | Reset/timezone, exact boost, cap/stacking, affected bonuses and fixed/random reward. Permanence is already confirmed. |
| Passes | Real experience-owned pass IDs and actual configured prices. The intended Auto Mark base price is 60 Robux. |
| Audio | Licensed/permitted Roblox IDs for the requested music and human narration. |

Duck nonresponse/departure fallback is already confirmed. Coin/Pačinki should use common server outcomes. Do not re-ask main-card count, line rewards, multiplier replacement, payment of starting lines, or small-card mark limits; those are implemented.

The 99-Robux request is understood as one bonus in each of three consecutive rounds, each randomly selected, with permission to fully premark its qualification card. **No purchase or automatic qualification is enabled.** Its paid access to random spendable rewards conflicts with the documented gambling concern and needs resolution in addition to the missing payout tables. No charge occurs for an unimplemented product.

## Audio and release limits

The requested lobby/intro YouTube links are reference metadata only. Six music slots cover lobby, a nonlooping bonus intro and four looping bonus tracks. One music Sound fades out before changing tracks; missing IDs stay silent. Human narration ducks music to 22% of its selected volume, with independent music/voice/effects settings. Bonus scene music routing is implemented, but production scene triggering and bonus-name voice start integration remain dependent on bonus execution. All 68 human-voice slots are empty; subtitles work.

[Studio tests](STUDIO_GUIDE.md), [configuration](FEATURE_SETUP.md), [audio](AUDIO_SETUP.md) and [policy assessment](POLICY_REVIEW.md) describe the remaining checks. No Studio rendering, real marketplace transaction, real-device performance, public Roblox publication, trademark clearance or moderation approval is claimed.
