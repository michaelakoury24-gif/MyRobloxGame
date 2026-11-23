# Football Stadium Map

A Rojo-powered football stadium with a multiplayer-authoritative ball system. The pitch, nets, stands, barriers, and controls are generated from source when Play starts.

## Stadium map

- Striped grass pitch with markings, penalty boxes, full netted goals, and midfield spawn
- Four five-tier grandstands surrounding the pitch, with individual seats, concrete steps, rails, columns, and roofs
- Inner pitch barrier prevents players entering the stands; outer barrier prevents leaving the stadium

## Ball gameplay

- Smaller black-and-white football with raised dark panel discs for a clearer classic football pattern
- Server-owned possession: touch a free ball to gain possession
- Smooth non-welded dribbling keeps the ball at foot height and clamps it back in front after sharp turns
- Centre-screen crosshair for shot aiming; aim the crosshair above the horizon for extra shot lift
- Hold **left click** or **F** to charge and release a shot; longer holds hit harder and lift higher
- **Q** sends a fast ground pass in the aim direction
- **E** performs a short, low slide tackle with a server cooldown; tackle an opponent within range to win the ball
- Free ball rolling uses friction, bounce, collision handling, speed limiting, and a centre reset if it exits the field

## Mobile controls

Touch devices receive **SHOOT**, **PASS**, and **TACKLE** buttons through `ContextActionService`. The on-screen guide also shows every PC and mobile control.

## Multiplayer and security

All possession, shooting, passing, tackling, cooldown, range, and out-of-bounds checks run on the server. Clients only request an action and provide an aim direction; the server validates it before moving the ball.

## Project layout

- `src/server/init.server.luau` — stadium creation and authoritative multiplayer ball mechanics
- `src/client/init.client.luau` — PC/mobile controls, charge meter, and HUD
- `src/shared/FootballConfig.luau` — shared gameplay values
- `default.project.json` — valid Rojo mapping for server, client, and shared folders
