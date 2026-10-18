# Studio testing · build 0.5.0

## 1. Open and play

From GitHub open `dist/CloudpopCommons-Studio.zip` → **Download raw file** → extract `CloudpopCommons.rbxl`. If that fails, use the repository home page → **Code → Download ZIP**, extract it and find the same file inside `dist/`.

In Studio choose **File → Open from File**, open the new `.rbxl`, open **View → Output**, and press **Play (F5)**, not Run. No plugin or API-service access is needed for practice. The rooms are built when Play starts, so the edit viewport does not contain the generated furniture beforehand.

You should spawn in the enclosed main hall facing the machine and presenter stage. The right-hand doorways lead to a lounge/café and separate viewing room. Walk through both doors, sit/stand, inspect the windows, and verify the second viewing screen shows the same number as the main display. All default avatar/camera controls remain in place.

Desktop cards start visible in a bottom-center horizontal tray: **two main cards on the left, four bonus entries in a 2×2 block on the right**. On touch, open Cards or equip the holder. Scroll horizontally or use Main/Bonus navigation; a short viewport also scrolls vertically rather than shrinking numbers.

## 2. One round

1. During **Starts in 15**, verify two 5×5 numbered cards. Each has 8–12 `◇` starting marks and one or two 10×/20×/50× multiplier cells. The center is numbered; cards may overlap each other, but each card contains distinct numbers.
2. At zero, a 1.5-second start cue precedes the first of twenty shared balls, four seconds apart. Starting-mark numbers can still be drawn.
3. Uncalled numbers cannot be marked. Tap `•` called numbers to mark them on either main or bonus cards; old calls remain markable through Last Call. Verified Auto Mark owners may enable catch-up for both card types.
4. Bonus starting marks total at most eight, possibly zero, with at least one unmarked space on every configured card. Coin needs three marked numbers, Duck/Pačinki four; Go CRazy's count remains pending. More than one card can qualify. Qualification does not yet launch a bonus game.
5. Every completed row, column and diagonal highlights. At results, independently total **15 × product of the multiplier cells on each completed line**, including starting-completed lines. An ordinary line is 15; a 20×/50× line is 15,000. The old card multiplier is disabled; full house has no separate extra award.
6. With no completed lines, expect zero Pesos. Repeated marks, reopening Cards and result requests must never pay again. Leaving after the first ball settles earned lines once; leaving before it pays nothing.

See `IMPLEMENTATION_STATUS.md` for the unresolved bonus rules. The current numeric balance cap is one billion Pesos; a reward at the cap credits only the available space.

## 3. Exact Explorer hierarchy

```text
ReplicatedStorage
└── Cloudpop                         Folder
    ├── Config                       ModuleScript
    ├── AudioManifest                ModuleScript
    ├── CardLayout                   ModuleScript
    ├── Economy                      ModuleScript
    ├── ChestRules                   ModuleScript
    ├── PayoutRules                  ModuleScript
    ├── PetBuilder                   ModuleScript
    ├── PatternRules                 ModuleScript
    ├── GameRules                    ModuleScript
    ├── BonusRules                   ModuleScript (calculation groundwork)
    └── ExactInteger                 ModuleScript (calculation groundwork)
ServerScriptService
└── CloudpopServer                   Folder
    ├── GameServer                   Script
    ├── ProfileStore                 ModuleScript
    ├── Workshop                     ModuleScript
    ├── LobbyPlan                    ModuleScript
    ├── PassService                  ModuleScript
    ├── PetService                   ModuleScript
    ├── PayoutStore                  ModuleScript
    ├── GlobalPayouts                ModuleScript
    ├── BonusQueue                   ModuleScript
    ├── ResultFeed                   ModuleScript
    └── CardHolder                   ModuleScript
StarterGui
└── CloudpopUI                       ScreenGui, ResetOnSpawn=false
    ├── StartupStatus                TextLabel
    ├── GameClient                   LocalScript
    ├── BonusPresentation            ModuleScript
    ├── PremiumShop                  ModuleScript
    ├── CardPanel                    ModuleScript
    ├── AudioController              ModuleScript
    ├── FeaturePanels                ModuleScript
    ├── PetEffects                   ModuleScript
    └── WorldEffects                 ModuleScript
Workspace
Lighting
SoundService
TextChatService                     Default TextChatService channels enabled
```

Runtime instances include `Cloudpop.Remotes.Action`/`State`, `Workspace.CloudpopWorkshop`, the replicated `Cards` Tool in each player's Backpack/Character, the cloned UI in PlayerGui, and local `CloudpopMusic`, `CloudpopVoice` and four effect Sounds in SoundService.

`Workshop` uses `LobbyPlan` for the three floor/ceiling extents and doorway geometry. The main and viewing readouts are `DrawDisplay.Readout.Text` and `ViewingDisplay.Readout.Text`. `Presenter` is an original static character Model. The card holder is decorative; private card numbers are only sent to their owner.

The server owns decks, fixed starting marks/multiplier cells, qualification, prices, balances and saves. Clients send intentions only. `PatternRules` expands the configured active groups; `GameRules.lineAwards` calculates distinct line rewards. Legacy card multiplier weights remain in configuration for compatibility but are disabled.

A separate runtime `PlayerGui.CloudpopBonus` ScreenGui hosts eligible-only scenes and survives respawn. Its DisplayOrder is below default Roblox touch controls. The lobby boutique's `RobuxShopPrompt` opens the Robux tab. Production bonus events remain unqueued; fixture tests cannot establish Studio visual quality.

## 4. Multiplayer and mobile

Use Studio's **Test → Server & Clients / Local Server** with two clients (labels vary by Studio version). Verify shared countdown/deadline, first-ball timing, all 20 numbers, visible avatars/holders, individual cards, independent marks, different starting marks/multiplier cells and individual bonus qualifications.

Join another client after drawing starts: it must wait for fresh cards next intermission. Reset an avatar: one holder returns and the GUI is not duplicated. Buy an owned cosmetic twice: the second action equips without charging again. Leaving before the first draw grants nothing; leaving after it settles completed lines once.

Use Device Emulator at desktop, portrait phone and landscape phone sizes. Check:

- Bottom-center tray, readable 44-pixel cell targets, horizontal main cards and the adjacent two-column bonus group.
- Horizontal/vertical scrolling and Main/Bonus navigation reveal every cell and all four bonus cards.
- Movement/jump controls work while Cards is open and closed. Phone layouts reserve the lower area; narrow landscape also reserves side margins. On short screens the large HUD hides while the tray is open; its header retains the current ball/count or countdown, and subtitles move to the top.
- Looks/Settings, three volume/mute controls, reduced motion and the creator credit remain reachable.
- The main hall, stage, lounge seating, café counter and viewing room have clear walking routes and complete walls/ceilings. Check actual collision, seat orientation, lighting, text contrast, camera clipping and performance.

Automated tests check tray geometry and collision-clear room routes, not actual rendering or touch input. These real Studio checks remain outstanding.

## 5. Presenter and sound

**This distributed build is silent:** all audio IDs are empty. It displays synchronized subtitles for the upcoming round, start, each number, last call and results. Private qualification notices do not announce a shared bonus start.

Follow [AUDIO_SETUP.md](AUDIO_SETUP.md) to supply 68 licensed human recordings and the music/effect tracks. There is no synthetic speech. Verify preloading, asset permissions, spoken-number matching, no overlap, music looping, smooth switching, ducking/restoration and individual mute settings. Bonus voice/music entries are prepared, but actual bonus-game triggering remains unfinished.

## 6. New feature setup

Follow [FEATURE_SETUP.md](FEATURE_SETUP.md) for the actual pass ID/price setup, pet testing, permanent chest status, supported system chat and separate rolling global records. Shop and Settings include Looks/Pets/Robux/Settings/Chest/Records tabs; each panel scrolls on small screens. Global records require live servers and are excluded from all Studio sessions.

## 7. Saving and rebuilding

Studio practice never calls DataStore and resets on Stop. For persistence tests use a **separate private test experience**:

1. Publish that test copy and enable **Studio Access to API Services** there.
2. Set a Boolean attribute `EnableStudioSaves=true` on `CloudpopServer.ProfileStore`.
3. Earn line-reward Pesos, purchase/equip a cosmetic and change voice volume. Wait for **Progress saved** in Settings, stop and rejoin.
4. Verify balance, ownership, style and all three volumes persist. Also test through the normal Roblox client.

The store stays `CloudpopProfiles_v1`, key `player_<UserId>`. Existing saves retain their balance/cosmetics; missing voice volume gets 0.8. Auto Mark preference, pet ownership/equipment, chest receipts and payout outbox now persist; actual pass access is verified separately. Signed/huge bonus balances are not written to this numeric version-1 ledger.

UpdateAsync, single-owner session leases, retries, 45-second autosave and close handling remain unchanged. Failed loads never become blank live profiles; mutations stop near an unrenewed lease's expiry. A crash/storage outage can lose changes since the last successful save. Do not point Studio tests at live player data.

After source edits:

```sh
python3 tools/check.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/build_place.py
```

Reopen the rebuilt place. Save Studio-only edits separately or sync them to repository source before rebuilding. The packaged `.rbxl` does not require Rojo to open.

If startup stalls, read the first Output error. Startup errors and a server-response watchdog are visible in the UI. The prior restricted `FallenPartsDestroyHeight` runtime-write bug remains fixed; that setting is saved in the place file. No cloud test substitutes for running this build in Studio.
