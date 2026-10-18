# Roblox policy review · 18 October 2026

This review separates explicit official requirements from judgments about the requested mechanics. It is not Roblox approval.

## Official sources read

The current official `Roblox/creator-docs` repository was retrieved at commit [`70a0110fee0c0900103e545fcaee69a8bd2a942f`](https://github.com/Roblox/creator-docs/commit/70a0110fee0c0900103e545fcaee69a8bd2a942f), dated 17 October 2026:

- [Content maturity → Unplayable gambling content](https://create.roblox.com/docs/production/promotion/content-maturity#unplayable-gambling-content) ([reviewed source](https://github.com/Roblox/creator-docs/blob/70a0110fee0c0900103e545fcaee69a8bd2a942f/content/en-us/production/promotion/content-maturity.md)).
- [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items) ([reviewed source](https://github.com/Roblox/creator-docs/blob/70a0110fee0c0900103e545fcaee69a8bd2a942f/content/en-us/production/monetization/paid-random-items.md)).
- [PolicyService](https://create.roblox.com/docs/reference/engine/classes/PolicyService), including `ArePaidRandomItemsRestricted`.

The environment's network proxy rejected direct access to the [Community Standards](https://about.roblox.com/community-standards) pages. Their complete current wording was not independently retrieved. The statements below are grounded in the current official creator documentation above, not an assertion that inaccessible pages were read.

## Confirmed requirements

The maturity documentation says:

> Gambling is the practice of exchanging real-world money, Robux, or in-game items of value for a game of chance. While games cannot contain playable gambling content, including simulated gambling, you can depict unplayable gambling content, such as showing a casino or people playing cards that players cannot bet on or play.

An age/maturity label does not authorize playable simulated gambling. Real-world cash-out is not the only relevant factor.

The paid-random-items documentation covers random virtual rewards purchased directly with Robux **or indirectly with Robux-purchasable currency/items**. Its examples include keys, rerolls and probability modifiers such as luck boosts and pity systems. Applicable paid random items require disclosure of all possible outcomes and actual numerical probabilities before purchase, with updated odds for modifiers and dynamic pools. Regional/per-player restrictions must be respected through `PolicyService:GetPolicyInfoForPlayerAsync`, including `ArePaidRandomItemsRestricted`. The maturity/compliance questionnaire also asks about paid random items. A restriction must be enforced by the server, not merely hidden in the UI.

The paid-random-items page says randomized rewards earned through actions that do not involve payment of Robux or in-game currency do not require that policy's odds disclosure. **This exception is not an exception to the gambling prohibition.**

## Assessment and uncertainty for this project

- Free cards, no wagers/entry payments, no cash-out, and no transfers remove several risk factors. They do not, by themselves, establish that the full requested chance-based multiplier experience is allowed.
- **Negative random multipliers that deduct already-earned Pesos raise a specific gambling concern:** the player exposes currency with cosmetic purchasing utility to chance-based loss. Calling that currency fictional, making cards free, or retaining a nonnegative floor does not automatically resolve the concern.
- Deducting only round earnings instead of a saved balance changes the mechanics but does not automatically establish compliance. The unanswered rules are necessary to assess this distinction; no substitution is silently made.
- Coin/wheel/peg-board formats alone do not establish a complete policy determination. The playable reward/loss system, access, presentation, value exchanged and monetization all matter. This review cannot certify the requested final collection of mechanics as compliant.
- Build 0.3.0 adds free main-card multipliers with disclosed uniform 1×–20× probabilities. Their pattern payouts are not active. No purchase changes the multiplier distribution; adding paid cards, paid multipliers or access later would require a fresh review. This free distribution is not a claim of approval for the final reward system.
- Build 0.4.0 adds the explicitly requested permanent Auto Mark pass integration. Its ID is unconfigured, so this package cannot sell it yet. There is no currency sale or paid chance boost. Pesos purchases deliver named guaranteed cosmetics/pets. Bonus payouts/deductions and selection games remain inactive.
- The latest explicit Auto Mark request changes the earlier cosmetic-only monetization scope. Further paid upgrades must receive their own exact-effect assessment. Even cosmetic-only paid random products introduce additional paid-random-item requirements; this project does not implement them.
- Do not enable paid entry, paid extra cards, paid rerolls, luck boosts, increased bonus eligibility or reward multipliers under the assumption that free base cards make them acceptable. Their exact effects require a new review against both policies, not just an odds label.
- Original assets do not establish clearance to copy a proprietary bonus's distinctive presentation or use protected branding. Requested names have been preserved without claiming legal clearance. No proprietary asset extraction or exact presentation replication is included.

Before public release: settle the missing rules, review the full current Community Standards, resolve the playable-gambling concern (including any need to ask Roblox for clarification), complete the accurate experience questionnaire, and perform private Studio/client tests. A concept-changing substitute would require the creator's decision. This build does not silently replace negative bonuses with another game, and does not claim approval.

## Assessment of the new pass and permanent free chest

The official [passes documentation](https://create.roblox.com/docs/production/monetization/passes) describes one-time Robux purchases for privileges. [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing) requires a dynamic client price display; its single-item example uses `GetProductInfoAsync`. These pages and paid-random-items were retrieved again from the pinned official revision above for this update. The pass UI uses that API and the official prompt rather than treating the intended 60 Robux as every player's actual price.

**Auto Mark's exact effect:** it marks valid called matches and catches up when enabled. It does not change card generation, draws, multipliers, bonus eligibility tracking or payout formulas. It is a guaranteed convenience privilege, not a cosmetic and not a random item sale. It can reduce missed marks, so if pattern payouts are later enabled, it can improve a user's practical completion rate compared with leaving matches unmarked. Therefore do not describe it as having no possible effect on realized winnings. Whether the final paid convenience plus chance-based Pesos rewards falls under additional gambling/paid-random restrictions depends on the finished mechanics; the current docs are not a specific ruling approving this combination. Pattern and bonus payouts remain inactive. Review that combination before enabling them or selling the pass publicly; do not rely on free cards alone.

**Permanent free chest:** neither claims nor their probability effect is enabled yet. The proposed pre-deal correlation method and exact `q' = p + (1-p)q` calculation are explained in [FEATURE_SETUP.md](FEATURE_SETUP.md). Strength, cap, stacking, targets, reset and reward distribution are unconfirmed. It would change bonus qualification odds, so those effects must be plainly disclosed rather than described as purely cosmetic. Permanence itself is not a policy exception.

The paid-random-item policy explicitly exempts odds disclosure for rewards earned through actions with no Robux or in-game-currency payment. A truly free daily claim with no paid keys, resets, skips or currency-purchased openings appears outside that paid-purchase trigger. That is an assessment of the described free access, not moderation approval; the proposed actual qualification odds should still be disclosed for transparency. If any future Robux purchase directly or indirectly buys/accelerates the upgrade or improves random outcomes, the policy's paid-modifier disclosure and per-player restrictions may apply. No such sale is implemented.

The gambling concern is separate and remains: increasing access to a bonus that can randomly deduct saved Pesos does not become acceptable merely because its upgrade is free. Negative-outcome handling is still unspecified, so this build keeps bonus deductions and probability effects disabled rather than assuming compliance or silently substituting another mechanic. Guaranteed 500-Pesos pets are named purchases with previews, no hatching/randomness and no gameplay effects.
