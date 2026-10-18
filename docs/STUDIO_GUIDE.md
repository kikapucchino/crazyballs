# Studio testing · build 0.2.0

## 1. Open the packaged place

On GitHub, open `dist/CloudpopCommons-Studio.zip` and use **Download raw file**, then extract `CloudpopCommons.rbxl`. If the file-download button fails, use the repository's **Code → Download ZIP**, extract that download, and find `dist/CloudpopCommons.rbxl`.

In Roblox Studio, choose **File → Open from File**, select the new `.rbxl`, open **View → Output**, and press **Play (F5)**. Use Play rather than Run so Roblox creates your avatar and runs the client UI. No plugin or API-service access is needed for this local practice test.

The lobby is built on Play, not pre-rendered in the editing viewport. Expect a navy/blue observatory, central machine, draw display, tables/seats, normal camera and a small HUD. The Cards panel starts collapsed. Walk with normal Roblox controls. Equip **Cards** in the backpack or click **Cards**; open **Bonuses** to see your free qualifying numbers.

Main shows a blank **5×5** preview because its card count/pattern/center/reward rules remain unconfirmed. Go CRazy likewise has a pending qualification entry. These are explicit unfinished areas, not a failed data load.

Follow a full round: 0/20 → 20/20, numbers in 1–60 with no duplicates, then a result notification. Opening cards during the round counts toward the existing 20-Pesos participation reward. Bonus matches are automatic and qualifiers are shown individually; no bonus payout currently runs. Choose a guaranteed cosmetic in Looks once affordable. Studio practice resets all changes on Stop by design.

## 2. Explorer hierarchy

```text
ReplicatedStorage
└── Cloudpop                         Folder
    ├── Config                       ModuleScript
    ├── Economy                      ModuleScript
    ├── GameRules                    ModuleScript
    ├── BonusRules                   ModuleScript (calculation groundwork)
    └── ExactInteger                 ModuleScript (calculation groundwork)
ServerScriptService
└── CloudpopServer                   Folder
    ├── GameServer                   Script
    ├── ProfileStore                 ModuleScript
    ├── Workshop                     ModuleScript
    └── CardHolder                   ModuleScript
StarterGui
└── CloudpopUI                       ScreenGui, ResetOnSpawn=false
    ├── StartupStatus                TextLabel
    ├── GameClient                   LocalScript
    ├── AudioController              ModuleScript
    └── WorldEffects                 ModuleScript
Workspace
Lighting
SoundService
```

Runtime additions:

- `ReplicatedStorage.Cloudpop.Remotes.Action` and `.State`: RemoteEvents.
- `Workspace.CloudpopWorkshop`: the lobby Model, including `DrawDisplay.Readout.Text`, `DrawnBall.BallNumber.Text`, `AirChamber`, 16 `DecorativeBall` parts, seats and `WelcomeMat` SpawnLocation.
- `Players.<player>.Backpack.Cards`: Tool with Handle and two SurfaceGuis. Equipping moves it to Character. Everyone sees the same decorative holder; private card data is not placed on it.
- `Players.<player>.PlayerGui.CloudpopUI`: HUD, CardPanel, four pages, toolbar and notifications.
- `SoundService.CloudpopMusic` and four `CloudpopEffect` Sounds on each client.

Scripts create these runtime objects; do not manually duplicate them. Scenery is server replicated; machine motion is cheap cosmetic client animation. Number generation, marking eligibility, qualification, balances, prices and saving are server-controlled. Snapshots omit future draws, other players' cards and hidden bonus mappings.

The earlier `FallenPartsDestroyHeight` startup bug remains fixed: that Studio-restricted property is serialized in `default.project.json`, never assigned by a running game script. Remotes are now created before scenery. The startup label displays initializer errors, and a server-response watchdog exposes a prolonged wait. Always read Output's first server error if initialization stalls; Linux checks cannot rule out every Studio runtime issue.

## 3. Test multiplayer, late join and respawn

Use Studio **Test → Server & Clients / Local Server**, choose **2 clients**, and start. Exact menu labels vary by Studio release.

Check these outcomes:

- Both avatars can walk, see one another, sit and stand without a scripted camera takeover.
- Equip a holder in one client and see it from the other. Reset that avatar; the holder returns once, and the HUD is not duplicated.
- Both clients see the same ball at each draw and the same 20-number history. Cards and qualification progress are personal.
- You may qualify for more than one bonus type. Pending Go CRazy never qualifies from zero numbers.
- A client joining after drawing starts receives no current-round qualifying numbers and gets fresh cards next intermission.
- Opening cards and leaving before the first draw gives no participation reward. Leaving after participating and seeing a draw settles the reward once.
- Buying an owned cosmetic again equips it without another charge; settings and cosmetics never change draw odds.
- Main-card/pattern and bonus-selection tests remain pending their implementation; do not mistake the helper tests for active bonus gameplay.

Solo play does not wait for additional users. Four-player private tests are a reasonable first multiplayer target; configure server size separately in Roblox's experience settings.

## 4. Test mobile and accessibility

Use Studio's Device Emulator for portrait phone, landscape phone and desktop. Verify the collapsed HUD leaves most of the lobby visible, Roblox controls remain usable, and the central toolbar avoids the movement stick/jump corners. An opened panel scrolls. Short landscape layouts put the panel centrally and temporarily hide the HUD behind it; closing restores it.

Check all four tabs, 25 preview cells, bonus progress, wardrobe and volume buttons. Main cells should show a check as well as color when marked after main rules are implemented. Bonus matches already use check marks. Try reduced motion: decorative animation and draw-ball bounce should stop. Automatic marking is free and will catch previous main-card matches when main cards are enabled.

Music and SFX volumes are independent and saved. **The distributed build has no filled audio asset IDs**, so silence is expected. See `IMPLEMENTATION_STATUS.md` for licensed-audio slots and the separate future bonus-music identities.

Real touch targets, camera sightlines, frame rate, text scaling and core-UI overlap require this manual check; they were not verified by a Roblox renderer in the cloud environment.

## 5. Test reliable saving privately

Only do this after local play works. Use a **separate private test experience**, not live player data.

1. Publish your test copy using Studio.
2. Enable **Studio Access to API Services** for that private test experience.
3. Add a Boolean attribute `EnableStudioSaves=true` to `ServerScriptService.CloudpopServer.ProfileStore`.
4. Play, participate, buy/equip a cosmetic and change volume. Open Settings and wait for **Progress saved**.
5. Stop and play again; verify balance, ownership, equipped style, volumes and reduced motion persist.
6. Also join using the normal Roblox client. Published servers use persistence regardless of the Studio-only attribute.

With the attribute absent/false, Studio never calls DataStore, including in an unpublished place. The store remains `CloudpopProfiles_v1`, key `player_<UserId>`. Old saves keep their cosmetics and balance; new volume fields receive defaults. Large signed bonus balances are not stored in this schema.

Saving uses UpdateAsync, one session lease per player, three retries, 45-second autosave and a final close attempt. A five-minute lease prevents two servers overwriting each other. Mutations stop near an unrenewed lease's expiry; a failed initial load never becomes a blank live profile. Shutdown has a bounded wait. A crash or sustained storage outage may lose changes since the last successful save; reliable handling is not a guarantee against unavailable storage.

## 6. Edit and rebuild

Source files map to the Explorer locations above. After a repository edit, run `python3 tools/check.py`, `python3 -m unittest discover -s tests -p 'test_*.py'`, and `python3 tools/build_place.py`; reopen the rebuilt place. Optional Rojo live sync uses `default.project.json`.

Save Studio-only edits to a separate copy or sync them into source. Rebuilding from GitHub source cannot include changes made only in a local Studio file.

There is no Robux receipt system yet. Do not treat any Pesos remote as proof of payment. Resolve [remaining rules](IMPLEMENTATION_STATUS.md) and [policy concerns](POLICY_REVIEW.md) before implementing or publishing the final bonus game.
