# Studio testing · build 0.3.0

## 1. Open and play

From GitHub open `dist/CloudpopCommons-Studio.zip` → **Download raw file** → extract `CloudpopCommons.rbxl`. If that fails, use the repository home page → **Code → Download ZIP**, extract it and find the same file inside `dist/`.

In Studio choose **File → Open from File**, open the new `.rbxl`, open **View → Output**, and press **Play (F5)**, not Run. No plugin or API-service access is needed for practice. The rooms are built when Play starts, so the edit viewport does not contain the generated furniture beforehand.

You should spawn in the enclosed main hall facing the machine and presenter stage. The right-hand doorways lead to a lounge/café and separate viewing room. Walk through both doors, sit/stand, inspect the windows, and verify the second viewing screen shows the same number as the main display. All default avatar/camera controls remain in place.

Desktop cards start visible in a bottom-center horizontal tray: **two main cards on the left, four bonus entries in a 2×2 block on the right**. On touch, open Cards or equip the holder. Scroll horizontally or use Main/Bonus navigation; a short viewport also scrolls vertically rather than shrinking numbers.

## 2. One round

1. Confirm both 5×5 cards are dealt during **Starts in 15**, with different numbers within each card and a multiplier from 1×–20× on each. Overlap between different cards is allowed.
2. At zero the server changes to Drawing and announces the start. Its 1.5-second cue precedes the first ball; then 20 balls are drawn at four-second intervals.
3. Try clicking an uncalled number: it must not mark. A called/unmarked number shows **•**; click/tap it to change to **✓**. Earlier called numbers remain markable until LastCall ends. No automatic-mark control remains.
4. Watch the bonus cards: Coin flip needs three matches, Duck hunt and Pačinki four. Go CRazy has a visibly pending count; it must not qualify from an empty list. More than one bonus can qualify.
5. Confirm each main multiplier is unchanged from the beginning of the round. It does not multiply participation or bonus results.
6. At results, a participating player receives the existing 20-Pesos participation reward. Main pattern payouts and bonus payouts are still inactive. A valid mark or intentionally opening/equipping cards establishes participation; passive receipt of cards does not.

The center currently contains a number. Free-center treatment, winning patterns and base rewards remain unanswered; no pattern winner is declared. The unresolved Go CRazy and signed-bonus rules are documented in `IMPLEMENTATION_STATUS.md`.

## 3. Exact Explorer hierarchy

```text
ReplicatedStorage
└── Cloudpop                         Folder
    ├── Config                       ModuleScript
    ├── AudioManifest                ModuleScript
    ├── CardLayout                   ModuleScript
    ├── Economy                      ModuleScript
    ├── GameRules                    ModuleScript
    ├── BonusRules                   ModuleScript (calculation groundwork)
    └── ExactInteger                 ModuleScript (calculation groundwork)
ServerScriptService
└── CloudpopServer                   Folder
    ├── GameServer                   Script
    ├── ProfileStore                 ModuleScript
    ├── Workshop                     ModuleScript
    ├── LobbyPlan                    ModuleScript
    └── CardHolder                   ModuleScript
StarterGui
└── CloudpopUI                       ScreenGui, ResetOnSpawn=false
    ├── StartupStatus                TextLabel
    ├── GameClient                   LocalScript
    ├── CardPanel                    ModuleScript
    ├── AudioController              ModuleScript
    └── WorldEffects                 ModuleScript
Workspace
Lighting
SoundService
```

Runtime instances include `Cloudpop.Remotes.Action`/`State`, `Workspace.CloudpopWorkshop`, the replicated `Cards` Tool in each player's Backpack/Character, the cloned UI in PlayerGui, and local `CloudpopMusic`, `CloudpopVoice` and four effect Sounds in SoundService.

`Workshop` uses `LobbyPlan` for the three floor/ceiling extents and doorway geometry. The main and viewing readouts are `DrawDisplay.Readout.Text` and `ViewingDisplay.Readout.Text`. `Presenter` is an original static character Model. The card holder is decorative; private card numbers are only sent to their owner.

The server owns deck generation, multipliers, eligibility, marks, prices, balances and saves. Clients send intentions, not reward amounts or prices. Main-card multiplier weights are integers in `Config.Main.MultiplierWeights`; the default 20 equal weights give exactly 5% to each value. Changing that table is an explicit tuning change, not a spending-based adjustment.

## 4. Multiplayer and mobile

Use Studio's **Test → Server & Clients / Local Server** with two clients (labels vary by Studio version). Verify shared countdown/deadline, first-ball timing, all 20 numbers, visible avatars/holders, individual cards, independent marks, different possible main multipliers and individual bonus qualifications.

Join another client after drawing starts: it must wait for fresh cards next intermission. Reset an avatar: one holder returns and the GUI is not duplicated. Buy an owned cosmetic twice: the second action equips without charging again. Leaving before the first draw grants no participation; leaving after participation settles once.

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

## 6. Saving and rebuilding

Studio practice never calls DataStore and resets on Stop. For persistence tests use a **separate private test experience**:

1. Publish that test copy and enable **Studio Access to API Services** there.
2. Set a Boolean attribute `EnableStudioSaves=true` on `CloudpopServer.ProfileStore`.
3. Earn participation Pesos, purchase/equip a cosmetic and change voice volume. Wait for **Progress saved** in Settings, stop and rejoin.
4. Verify balance, ownership, style and all three volumes persist. Also test through the normal Roblox client.

The store stays `CloudpopProfiles_v1`, key `player_<UserId>`. Existing saves retain their balance/cosmetics; missing voice volume gets 0.8. Old automatic-mark settings are discarded. Signed/huge bonus balances are not written to this numeric version-1 ledger.

UpdateAsync, single-owner session leases, retries, 45-second autosave and close handling remain unchanged. Failed loads never become blank live profiles; mutations stop near an unrenewed lease's expiry. A crash/storage outage can lose changes since the last successful save. Do not point Studio tests at live player data.

After source edits:

```sh
python3 tools/check.py
python3 -m unittest discover -s tests -p 'test_*.py'
python3 tools/build_place.py
```

Reopen the rebuilt place. Save Studio-only edits separately or sync them to repository source before rebuilding. The packaged `.rbxl` does not require Rojo to open.

If startup stalls, read the first Output error. Startup errors and a server-response watchdog are visible in the UI. The prior restricted `FallenPartsDestroyHeight` runtime-write bug remains fixed; that setting is saved in the place file. No cloud test substitutes for running this build in Studio.
