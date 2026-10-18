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
- There is currently **no Robux purchase system**, no paid randomness, no currency sales, and no paid chance boost. Pesos purchases deliver named guaranteed cosmetics. Bonus payouts/deductions and selection games are inactive in this intermediate build.
- If future Robux products are added, restrict the first version to clearly displayed guaranteed cosmetics and bundles with zero effect on cards, draw probabilities, qualification, multiplier outcomes or payouts. Even cosmetic-only paid random products would introduce additional paid-random-item requirements; this project does not implement them.
- Do not enable paid entry, paid extra cards, paid rerolls, luck boosts, increased bonus eligibility or reward multipliers under the assumption that free base cards make them acceptable. Their exact effects require a new review against both policies, not just an odds label.
- Original assets do not establish clearance to copy a proprietary bonus's distinctive presentation or use protected branding. Requested names have been preserved without claiming legal clearance. No proprietary asset extraction or exact presentation replication is included.

Before public release: settle the missing rules, review the full current Community Standards, resolve the playable-gambling concern (including any need to ask Roblox for clarification), complete the accurate experience questionnaire, and perform private Studio/client tests. A concept-changing substitute would require the creator's decision. This build does not silently replace negative bonuses with another game, and does not claim approval.
