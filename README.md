# Football Stadium Map

A Rojo-powered football stadium with a server-authoritative multiplayer ball system. The pitch, nets, stands, barriers, and gameplay are generated from source when Play starts.

## Stadium map

- Striped grass pitch with markings, penalty boxes, full netted goals, and midfield spawn
- Four five-tier grandstands surrounding the pitch, with individual seats, concrete steps, rails, columns, and roofs
- Inner pitch barrier prevents players entering the stands; outer barrier prevents leaving the stadium

## Ball gameplay

- Small black-and-white football with procedural dark panels inspired by the supplied classic football reference
- Touch a free ball to gain server-owned possession
- Smooth non-welded dribbling keeps the ball in front of the player at ground/foot height while running and turning
- A centre-screen crosshair aims shots and passes; looking higher makes charged shots arc higher
- Hold **left click** or **F** to charge and release a shot; release is sent immediately to the server
- **Q** sends a fast, mostly-ground pass in the crosshair direction
- **E** performs a short low slide tackle with server cooldown; ball holders must pass or shoot before tackling
- Free ball rolling uses friction, bounce, collision handling, speed limiting, and a centre reset if it exits the field

## Mobile

Touch devices receive **SHOOT**, **PASS**, and **TACKLE** buttons through `ContextActionService`. The prior control/instruction panels have been removed; only the aim crosshair and temporary shot-charge bar are displayed.

## Multiplayer and security

All possession, aim handling, shots, passes, tackles, cooldowns, range checks, and out-of-bounds resets are validated by the server. Clients request actions and send only an aim vector.

## Project layout

- `src/server/init.server.luau` — stadium creation and authoritative multiplayer ball mechanics
- `src/client/init.client.luau` — crosshair, charge meter, PC/mobile input, and local slide pose
- `src/shared/FootballConfig.luau` — shared gameplay values
- `default.project.json` — valid Rojo mapping for server, client, and shared folders
