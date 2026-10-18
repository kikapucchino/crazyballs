# Studio playtesting, one step at a time

Complete each step before moving to the next. The project is already assembled in `dist/CloudpopCommons.rbxl` using Rojo's standard serializer. Use this binary file for build 0.1.2; no plugin or manual setup is required to open it.

## 1. Open the prototype and play one round

Open the place with **File → Open from File**, then open **View → Explorer** and **View → Output**. Press **Play (F5)**, not Run: Play creates a local player and runs the LocalScript.

Expected sequence:

1. The sky workshop appears and the game UI loads.
2. During preparation, tap either objective. Both grant 10 Pesos when completed.
3. Each drawn number becomes available on your cards. A dot and border identify a matching cell; a check identifies a stamp. Previously drawn numbers remain markable until the end of Last Call.
4. Completing any horizontal row claims that card once. The result is checked by the server automatically.
5. After ball eight, Tailwind Switch pauses draws. Choose **Preview a swap**, tap two cells on the same card, inspect the preview, then **Confirm swap**. **Cancel preview** makes no change. **Keep layout** consumes the event choice without swapping.
6. At results, check the participation/row/objective breakdown and your balance. Buy a named cosmetic only after you have enough Pesos.

Pass condition: you can finish the round, receive at most 60 Pesos, play another round, and equip a cosmetic without errors in Output. Two starting cosmetics are already owned and free to equip. Studio practice resets progress on Stop by design.

## 2. Understand the exact Explorer hierarchy

The place contains:

```text
ReplicatedStorage
└── Cloudpop                         Folder
    ├── Config                       ModuleScript
    ├── Economy                      ModuleScript
    └── GameRules                    ModuleScript
ServerScriptService
└── CloudpopServer                   Folder
    ├── GameServer                   Script
    ├── ProfileStore                 ModuleScript
    └── Workshop                     ModuleScript
StarterGui
└── CloudpopUI                       ScreenGui (ResetOnSpawn = false)
    ├── StartupStatus                TextLabel
    └── GameClient                   LocalScript
Workspace
Lighting
SoundService
```

During Play, Roblox clones `StarterGui.CloudpopUI` into `Players.<you>.PlayerGui`. Its LocalScript builds the game interface inside that ScreenGui. The server creates `ReplicatedStorage.Cloudpop.Remotes.Action` and `.State` as RemoteEvents and `Workspace.CloudpopWorkshop` as a Model. The client also creates `SoundService.SoftDrawPing` as a Sound. Do not manually duplicate these runtime instances.

The packaged startup message is visible before any modules load. Build 0.1.2 initially says **Waiting for the client script to start**. When the LocalScript begins, that changes to **Client started**, followed by the dependency being loaded. An unchanged initial message means the LocalScript has not reached initialization; check Output for compile or script-execution errors. This is different from a running client waiting for server data.

The client waits for modules and remotes with timeouts. If initialization throws, the first error line appears on screen and the full stack trace is recorded in Studio's Output panel. These diagnostics do not establish that a Studio-specific problem has been fixed until the game successfully starts there.

The authoritative deck and balances live only on the server. The client receives only the draw history and its own card/profile view. The client sends intentions, never a reward amount or price. The server checks phase, round ID, indices, ownership, and draw eligibility and rate-limits requests.

## 3. Test two players

Use Studio's **Test** controls to select **Server & Clients / Local Server**, choose **2 clients**, and start the session. Labels differ slightly by Studio version.

Verify:

- Both windows see the same newest ball and draw history.
- Each gets exactly two cards and sees only their own marks and balance.
- One player can mark manually while the other uses free Auto-mark. Auto-mark players should select an objective each round to participate.
- The event occurs in both windows. Swapping in one does not change the other's cards.
- Claiming a row does not stop other players or the shared draw.
- Buying an item twice equips it the second time without another charge.
- A late client watches the current round and receives cards in the next preparation phase.

For the first published test, configure the experience for **4 players per server** in Roblox's experience settings. The code also works solo; it never waits for a minimum group size.

## 4. Test phone and PC layouts

Use Studio's **Device Emulator** with a phone in portrait orientation, then landscape and desktop resolutions. Some narrower phones stack the cards vertically; the page scrolls.

Check that:

- Numbers are legible and tappable; ownership/mark state does not rely solely on color.
- All nine cells on both cards, the final results, and the bottom accessibility options can be reached by scrolling.
- Tailwind preview can be confirmed or canceled; cards do not commit the swap before confirmation.
- **Motion: REDUCED** stops bouncing machine balls and number-pop animation.
- **Sound: OFF** mutes the draw cue. Sound uses Roblox's built-in `electronicpingshort.wav`; verify it plays on your Studio version. No uploaded audio is required for core play.
- Auto-mark catches previously drawn matches and provides the same pattern eligibility as manual marking.

The client uses `GuiButton.Activated` for both mouse and touch. GUI respects Roblox's default safe inset. The wardrobe remains usable during rounds, and an event returns the UI to the Play tab.

## 5. Test saving in a separate private test experience

Skip this until the local game works. Unpublished Studio practice intentionally never requests DataStore access.

1. Publish a **separate private test experience** from Studio using your Roblox account. Keep its data separate from any future live game.
2. To test persistence inside Studio, enable **Studio Access to API Services** in that test experience's security settings.
3. Select `ServerScriptService.CloudpopServer.ProfileStore`. Add a **Boolean attribute** named `EnableStudioSaves`, set to `true`, and save the test place. Leave this attribute absent or false for normal local practice.
4. Play, earn Pesos, purchase a cosmetic, and change Auto-mark. Wait until the balance header says **Progress saved**, then stop.
5. Play again and verify the same balance, ownership, equipped cosmetic, and settings.
6. Also test joining through the Roblox client. Published servers always use persistence, regardless of the Studio-only attribute.

Never enable Studio API access against a live player-data experience. The DataStore is `CloudpopProfiles_v1`, keyed by `player_<UserId>`.

Persistence details:

- Session acquisition and saves use `UpdateAsync`. Only the server holding the profile's unique lease may save it.
- Autosave runs every 45 seconds. Requests retry three times with short delays.
- A session lease lasts five minutes. Mutations pause before an unrenewed lease expires; players are disconnected if saving cannot recover. An abrupt crash may require waiting for the old lease to expire before rejoining.
- Failed loads never substitute a blank live profile. Future/unknown save versions are also rejected without overwriting.
- Leaving after draws begin settles earned rewards; leaving during preparation grants nothing. Normal leave and shutdown attempt a final save and release.
- Shutdown has a bounded wait. A hard process failure or sustained DataStore outage can lose changes since the last successful save; no implementation can guarantee persistence when Roblox storage is unavailable.

This project has **no Robux purchase system**. Add one later only with guaranteed cosmetic products and server-side, idempotent receipt processing; do not reuse the Pesos remote as proof of a Robux payment.

## 6. Make one small change

Begin by changing `Config.DrawSeconds` from `5` to `4`. Test one solo round and one two-client round. Confirm both clients still see the same draw and the Tailwind event still happens after ball eight.

When editing source files in this repository, install Rojo (or run the cloud bootstrap), run `python3 tools/build_place.py`, and open the rebuilt `.rbxl` place. When editing directly in Studio, save a separate copy: rebuilding from repository source will not include those Studio-only changes. Rojo's live sync is optional.

Next development milestone: add one new target pattern with rule tests. Additional events and monetization should follow after the existing multiplayer and save checks pass in Studio.
