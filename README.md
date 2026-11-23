# Football Free Play

A Rojo-powered Roblox football (soccer) game. Press Play to load a full grass pitch with line markings, goals, stands, floodlights, a physical ball, scoreboards, and respawning player pads.

## Controls

| Control | Action |
| --- | --- |
| **WASD** / thumbstick | Move (standard Roblox controls) |
| **Shift** / RUN touch button | Sprint |
| **Q** / PASS touch button | Ground pass |
| **E** / KICK touch button | Lofted kick |
| **F** or left mouse click / SHOOT touch button | Power shot |

Move within **10 studs** of the ball to play it. The server owns the ball and validates kick range and rate, so scoring and ball movement stay consistent in multiplayer. A ball that leaves the ground resets to the centre; shots into either goal update both the in-world and HUD scoreboards.

## Get the changes into Roblox Studio

### Live-sync workflow (recommended)

1. Install the [Rojo CLI](https://rojo.space/docs/v7/getting-started/installation/) and the **Rojo** Studio plugin if they are not installed already.
2. Open a terminal at this repository's root (the folder containing `default.project.json`) and run:

   ```bash
   rojo serve
   ```

   Leave this command running while you work. Rojo will print a local server address, normally `http://localhost:34872`.
3. Open your existing place (`MyRobloxGame.rbxl`) in Roblox Studio, or open a new Baseplate place.
4. In Studio, use **Plugins → Rojo → Connect** and select the running Rojo server. Confirm the sync prompt.
5. The football field should now be visible in **Edit** mode under `Workspace → FootballPitch`. It remains in place while playing as a permanent, collidable field floor.
6. Press **Play**. The full `FootballStadium` gameplay layer adds goal scoring, ball physics, HUD, and controls on top of the field.
7. Use **File → Publish to Roblox As…** (or **Publish to Roblox**) once you are happy with the game.

> Keep `rojo serve` open when editing the `.luau` files. Saving a source file syncs it to Studio automatically; stop and start Play mode again to recreate the full runtime stadium from the updated script.

### Build a standalone Studio place

If you do not want live sync, build the Rojo project first:

```bash
rojo build -o "FootballFreePlay.rbxlx" default.project.json
```

Then open `FootballFreePlay.rbxlx` in Roblox Studio and publish it. The generated `.rbxlx` file is intentionally ignored by Git.

## Project layout

- `src/server/init.server.luau` — creates the pitch and stadium, ball physics, secure kick validation, spawning, scoring, and resets.
- `src/client/init.client.luau` — creates the HUD, keyboard/mouse/touch controls, sprinting, and ball-distance hint.
- `src/shared/GameConfig.luau` — shared field dimensions and gameplay tuning.
- `default.project.json` — Rojo data model mapping.

## Tuning

To adjust field size, ball control radius, kick speed, or sprint speed, edit `src/shared/GameConfig.luau`. Both client and server load the same values on the next Rojo sync / test session.
