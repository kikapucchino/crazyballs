# Pass, pets, chest and records · build 0.5.0

## Auto Mark configuration

In Creator Dashboard, select this experience, create a **pass**, enable sales and set its intended base price to **60 Robux**. Copy the actual pass ID into `ReplicatedStorage.Cloudpop.Config.AutoMarkPass.Id` (source: `src/shared/Config.luau`). The distributed ID is `0`, so buying is unavailable until configured. Rebuild/reopen the package after editing repository source, or save the edited Studio place. No pass has been created or priced on your behalf.

Settings and the Robux boutique contain the official purchase button, ownership refresh and On/Off toggle. The client calls `MarketplaceService:GetProductInfoAsync(id, Enum.InfoType.GamePass)` for the platform's actual price and sale status. A difference from 60 Robux is explicitly flagged; regional/personalized prices can legitimately differ. The official prompt confirms the transaction. Price-query failure disables buying until refreshed. The server checks `UserOwnsGamePassAsync` on join, refresh and purchase completion; a client claim or purchase callback alone never grants access. Ownership is not trusted from a saved boolean. The preference persists separately.

Auto Mark marks already-called matches on both main and bonus cards, including catch-up when switched on during Drawing/LastCall. It does not change deals, premarks, multipliers, draw order or payout formulas. It can prevent missed marks and therefore improve realized line completion and bonus qualification versus a player who leaves matches unmarked. Manual marking remains free. This is a paid convenience feature, not a cosmetic; review the paid-convenience/conditional-random-reward combination before selling publicly. No participation reward remains.

## Separate Robux boutique

The physical lobby counter opens the Robux tab through a ProximityPrompt. Three named guaranteed cosmetics have previews: Legendary Frostglass (card frame), Legendary Aurora (star mark), and Legendary Moonlight (four-point star mark). Create a separate experience pass for each item, set your chosen price and place its real ID in that catalog entry's `passId`. No prices are invented for these items. All IDs are zero in the package, so they cannot be purchased yet.

The client queries actual platform prices/sale status and uses the official prompt. Server ownership is checked on join, refresh and purchase completion. `PremiumEquip` requires verified ownership; the ordinary Pesos shop cannot buy Robux entries or trust a zero catalog price. Re-equipping does not charge. No pass is created remotely by this update.

The **99-Robux three-bonus offer** means a random bonus in each of three consecutive rounds, with the requested automatic qualification exception. It is recorded as disabled configuration only: no product ID, prompt, receipt fulfillment, charge or gameplay advantage is enabled. Payout rules and the paid-random/gambling policy concern remain unresolved; see [POLICY_REVIEW.md](POLICY_REVIEW.md).

## Pets

Shop → Pets offers **Lumen Loaf, Prismote and Tide Tassel**, each a guaranteed named **500-Pesos** cosmetic with a 3D preview. Buy/equip/unequip through the server; repeat purchase requests equip without a second charge. One pet is equipped at once. Ownership and selection save in the existing session-locked profile.

Server-created anchored models carry their owner's UserId and replicate to everyone. Every client interpolates them at up to 30 updates/second, with gentle idle/movement bob and tilt. Reduced motion disables bob/tilt. Parts have collision/touch/query disabled and cast no shadows. There are no per-frame remotes, particle emitters or physics followers. The three companions are original primitive models; no franchise models, names or sounds were imported.

## Permanent free chest: gate and proposed effect

**Permanent is confirmed.** Reset type/timezone, exact strength, cap/stacking, affected bonuses and fixed/random reward remain unanswered. Consequently the shipped chest panel explains that rules are pending, and server claims cannot grant anything. No paid opening, key, reset or missed-day penalty exists.

`ChestRules` independently implements server-time rolling-24-hour and fixed-UTC-offset eligibility, one receipt per eligible claim, duplicate prevention without yielding, and saved cumulative reward units. Fixed-reset timezone configuration is currently a UTC offset, not an automatic daylight-saving calendar. Unit tests use fixture rewards; these are not production odds. Production `ClaimRulesConfirmed=false`, `EffectEnabled=false`, `ResetMode=""`, `RewardMode=""`, `RewardUnits=0`. Do not flip these flags alone to launch an upgrade: the actual probability effect is deliberately unimplemented until the requested rules are supplied. Random reward distributions are also unspecified.

Proposed implementation, subject to those decisions:

1. Generate the shared shuffled 1–60 deck first; its first 20 balls are the fixed round draw.
2. Before showing cards, each affected bonus card has disclosed probability `p` of receiving its `k` distinct numbers sampled uniformly from those first 20 balls. Otherwise deal that bonus card uniformly from 1–60 as now.
3. Reveal the assigned numbers and the effective qualification probability before drawing. Never change those numbers or the deck afterward. The qualification rule remains marking every displayed bonus number, including its fixed starting marks.

With `m` starting marks on a `k`-number card, the baseline probability of calling every remaining required number is `q = C(20,k-m) / C(60,k-m)`, conditional on that starting-mark count and perfect marking. Average over the disclosed starting-mark allocation to get the unconditional probability. The proposed mixture gives `q' = p + (1-p)q`. `p` is a forced-qualified-deal chance, **not** the same number as the final percentage-point increase `q'−q`. A permanent upgrade would increase the disclosed `p` according to a confirmed cap and stacking schedule. This changes correlation between the bonus card and pre-generated draw; it does not secretly change the shared draw. Go CRazy cannot use this until its number count exists. This proposal is not enabled or treated as accepted.

## Actual results, system chat and rolling records

Records has two separate areas:

- **Highest payout — last 24 hours** ranks positive individual transactions across live servers by actual credited Pesos, then earlier server timestamp, then transaction ID for timestamps equal to the second. It shows name, amount, source, multiplier and UTC achievement time. It never adds multiple transactions together.
- **Recent bonuses · this server** groups all recipients under each of the last four completed events. It includes signed actual amounts, multipliers and UTC times. With bonus execution still disabled, this list truthfully remains empty.

`ResultFeed.completeBonus` accepts trusted internal completed events only and rejects uncommitted results. There is no client result/record remote. The future bonus settlement controller must call it **after** all listed rewards/deductions are committed; the presentation queue forwards only such committed results. No production settlement caller enqueues events yet, so gameplay history remains empty. Main lines are not mislabeled as bonuses.

`TextChatService` default channels are enabled in the place. Clients render verified feed messages using `RBXSystem:DisplaySystemMessage`, falling back to `RBXGeneral` if needed, with the explicit **[Cloudpop System]** prefix. Rich-text metacharacters are escaped. Messages deduplicate, batch recipients, queue at most 12, and display at most one every five seconds. Old join-time messages are not replayed as fresh activity. No marks or invented wins are announced. Large recipient groups direct users to the full Records panel instead of flooding chat.

### Persistence and failure behavior

The active awards are individual completed main-card lines, labeled e.g. **Main card 1 / row1**, with the actual product of that line's multiplier cells (one without any). Each line gets its own receipt; multiple line awards are not combined into one record. At the current numeric ledger cap of one billion Pesos, only the amount actually credited is recorded. Bonus payouts must later join a durable path after signed/large-number settlement is implemented.

The profile credit and an immutable GUID payout receipt are saved together in `CloudpopProfiles_v1`. Only a successful save's snapshot enters the global indexing queue. A failed save never creates a global payout. Acknowledged receipts are removed from the local outbox and that removal saves later; a crash can replay a receipt safely. Rejoin requeues persisted receipts. Expired receipts are pruned. Studio practice and Studio API-save tests are excluded from global records.

Global metadata uses `CloudpopPayoutTransactions_v1`. Per-UTC-day OrderedDataStores `CloudpopPayoutDay_v1_<day>` index **every** successful eligible receipt by its actual Pesos amount. The current and preceding UTC-day indexes are queried with the strict rolling cutoff; this is not a midnight reset and does not retain only one winner. Queries scan ties and skip expired high-value entries before selecting a leader. A failed metadata/index write retries idempotently. Conflicting reuse of a transaction ID is rejected.

MessagingService topic `CloudpopPayouts_v1` prompts cross-server refreshes and carries deduplicated record notifications. Background processing handles at most four queued writes per five-second pump, exponential retries up to 120 seconds and minute polling as a subscription fallback. A query processes at most 20 pages per day index; exceeding that budget reports delayed records rather than claiming an incorrect winner. For a much larger experience, replace this bounded small-game index scan with a resumable query/aggregation worker. Historical indexes/metadata are retained; no destructive cleanup task is shipped.

The current valid cached leader remains visible during service failures with a delayed status. Once expired, it disappears immediately and the UI says it is refreshing until a successful query finds the next eligible record or confirms none. Only a confirmed empty query displays **“No qualifying payouts in the last 24 hours.”** The query for an announcement also checks leadership at the award's timestamp, so expiry alone cannot produce a new-win announcement. One atomic metadata claim chooses a publisher. Notifications are best-effort; outages or delayed indexing can miss a chat announcement, but cannot fabricate a payout. Only recent awards (within 120 seconds) can trigger an announcement.

Global work runs outside the round loop; a DataStore or MessagingService failure must not prevent gameplay or startup. Existing player-profile load failures still fail closed to protect saved balances.

## Tests still required inside Roblox

The cloud suite executes actual Luau controllers with mocked services and verifies gameplay, UI and persistence checks plus five place-packaging tests. It is not Studio rendering, real marketplace access or actual cross-server latency testing.

1. In a separate private test experience, configure the real pass. Verify an owner after rejoin, a nonowner, cancellation, official purchase completion, toggle On/Off, and the regional-price testing tool. No test fakes purchase success.
2. Studio two-client test: pets appear to both clients, smoothly follow through both doors, do not collide, survive respawn and disappear after unequip/leave. Use practice-only server balance edits to test all three pets; these must not create global payouts.
3. Use phone portrait/landscape emulation to navigate Shop/Settings tabs, scroll previews/settings/history and use 44-pixel buttons. Check movement controls, readable text and performance.
4. Publish a private live test copy with a separate experience/data namespace. Earn a line reward, wait for Progress saved, compare Records in two live server instances, then rejoin. Studio itself is deliberately excluded. Confirm genuine empty/failed/expired states and watch Output for service errors.
5. Once chest and bonus rules are confirmed and integrated, run end-to-end claim and completed-bonus payout/history tests. Current tests validate their independent bookkeeping and feed contracts; they do not claim these gated games are playable.
