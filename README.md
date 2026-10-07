# SustainableIsland — Godot game

A small, single-player 2D island-management game built on your supplied Godot account project. Manage a 14-day tourism season, create local jobs, and protect the island's forest and reef. Includes original editable SVG artwork and three WAV sound effects.

## Start playing

1. Extract the ZIP into a new folder (keep your original project as a backup).
2. In **Godot 4.5.1**, choose **Import** and select `project.godot`.
3. Wait for assets to import, then press **F5**.
4. On your existing login screen, choose **Play offline as guest**, then **Continue island**.
5. Close the tutorial, click a location, and use its management buttons.

You do not need a database or internet connection for guest play. The project uses the Compatibility renderer, a 1920 × 1080 design canvas, and a default 1280 × 720 window. Resize the window as needed. This package contains the editable Godot project, not a prebuilt Windows executable.

## How to play

- Start with 1,800 coins, a staffed guesthouse, and three actions per day.
- Click a map location to inspect it. Faded buildings are construction sites.
- Build or upgrade a facility, then **Assign team** to open it. An unstaffed facility earns nothing and provides no services.
- Each building change, team assignment/release, or quick action uses one action.
- **Quick actions** offers waste collection, emergency water/energy, and cultural workshops.
- Select the forest or reef to fund conservation directly.
- **Next Day** welcomes visitors, pays wages and other costs, and applies waste and resource effects. Remaining actions do not carry over.
- **Journal** shows recent decisions. **Season goals** shows progress. Escape closes a dialog or returns to the menu.
- Sound can be toggled from the top bar; this preference is remembered.

### A useful opening strategy

Day 1: build the market, assign its team, build recycling. Day 2: staff recycling, build Heritage House, assign its team. Day 3: build clean utilities, assign its team, and protect the forest. This creates eight jobs. Review the daily results before expanding further.

### Season goal

At the end of day 14, meet all five requirements: rating at least 70, at least eight local jobs, marine health at least 65, forest health at least 65, and at least 700 coins. The season also ends early if income plus remaining funds cannot pay operating costs.

### Simplified simulation rules

- Accommodation capacity: 8 visitors per active guesthouse level; 16 per active hotel level.
- Income: 20 coins per visitor, plus 7 per market level and 4 per Heritage House level when staffed.
- Expenses: 6 coins per assigned worker, 10 per constructed building level, plus 20 daily utility costs. Closed buildings still require maintenance.
- Waste: one unit per visitor; each active recycling level removes 12 daily.
- Water/energy: 20 natural refill daily plus 20 per active utilities level; each visitor uses 2 water and 1 energy. Values stay between 0 and 100.
- Waste damages habitat health; low supplies and poor cleanliness reduce satisfaction. Hotel construction removes six forest points per level.
- Daily events: holiday demand on day 4; a storm on day 7; drought on day 10; a cultural festival on day 12.
- Impact = average damage to marine and forest health. Lower is better.
- Rating = average of marine health, forest health, satisfaction, jobs as a percentage of 12, and financial stability (`min(100, coins / 15)`). Higher is better.

All values are fictional teaching mechanics, not real environmental measurements. Employment models headcounts and wages, not every dimension of decent work. No purchases or real money are involved.

## Accounts and saves

Your login, account creation, password-recovery screens, Supabase configuration, and original prototype scripts are retained. Successful login/account creation now opens the new game menu. Login feedback is displayed on-screen. **Remember email** stores the login identifier only; passwords and authentication tokens are not written to disk.

Local progress automatically saves after actions, daily updates, exploration, and returning to the menu. Each authenticated account has its own local file, separate from the guest save. One guest save is shared by guest users on that device. Local saves are stored in Godot's `user://` directory as `island_<profile-hash>.json`.

**Save / cloud sync** saves locally and, for signed-in users, uploads a snapshot to Supabase. Cloud synchronization is explicit, not automatic after every move. The menu checks for a newer cloud save by its saved timestamp. Avoid playing the same account on two devices simultaneously; this is a basic timestamp-based sync, not a merge system.

### Enable the new cloud save table

1. Open your own Supabase project's SQL Editor.
2. Run `supabase/migrations/20261007_island_saves.sql` once.
3. Log in to the game, play, and click **Save / cloud sync**.
4. Check the on-screen success or error message.

The migration adds a separate `island_saves` table and owner-only row-level security policies. It does not alter your existing `player_progress` table. No live database changes were made while preparing this project.

For a completely new Supabase project, apply your original `20260921_initial_schema.sql` before the new migration and set the URL/publishable key in `autoloads/Supabase.gd`. Never use a service-role key in a shipped game.

**Existing backend limitations:** the supplied username login calls `get_email_from_username`, but that RPC is not defined in the supplied migration. Email login does not need it. Use email login unless your deployed backend already supports username lookup. Password recovery uses your existing Supabase email flow; its redirect/reset destination still needs to be configured in Supabase. Live signup, login, email delivery and authenticated cloud operations were not verified against your service.

If the service is unavailable or the new table has not been created, guest mode and local saves still work. A failed cloud sync keeps your local save. Network requests time out after 12 seconds.

## Project organization

- `scenes/Game.tscn` — new game entry scene.
- `scripts/IslandScreen.gd` — HUD, management controls, tutorial and daily reports.
- `scripts/IslandMap.gd` — clickable map, building states, boat and visitor animation.
- `scripts/IslandUI.gd` — reusable interface styling.
- `autoloads/IslandGame.gd` — rules, objectives, local saving, and cloud coordination.
- `scripts/MainMenu.gd` — continue, new season, return to login.
- `autoloads/Supabase.gd` — your existing auth code plus a separate game-save request helper.
- `assets/island/` — editable vector assets.
- `assets/audio/` — short synthesized feedback sounds.
- `tests/` — Godot regression tests.
- `scenes/Main.tscn`, `scripts/Main.gd`, `GameData.gd`, `GameState.gd` — your original seasonal prototype, retained for reference. Normal Play uses `Game.tscn` instead.

To adjust costs, workforce, season length or game difficulty, edit `IslandGame.gd`. Replace any SVG with another asset using the same filename or change its reference in `IslandMap.gd`. New scenes use source paths, not another machine's resource UID cache.

## Verification

Tested with the official Godot 4.5.1 Linux editor. Run from a terminal:

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . res://tests/TestRunner.tscn
```

The tests cover action limits, employment, staffing, visitor capacity, insufficient funds, save restoration, malformed save rejection, per-profile paths, a balanced winning season, an unmanaged losing season, bankruptcy, finished-season restrictions, and instantiation of all active screens.

Tests use a dedicated `automated_test` profile. They do not contact Supabase or create real accounts. For export, install the matching Godot export templates and add your desired platform in **Project → Export**. Desktop is the tested target; web/mobile export and browser Supabase CORS behavior are not validated.

Godot references: [Saving games](https://docs.godotengine.org/en/4.5/tutorials/io/saving_games.html), [Importing images](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_images.html).
