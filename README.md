# Football Stadium Map

The project now builds a self-contained football pitch map when Play starts.

## Map features

- Full striped grass football pitch with touchlines, halfway line, penalty boxes, goals, and centre spot
- Two five-tier grandstands with colourful seating and roofs
- Four tall, transparent, collidable barriers around the map perimeter
- Midfield spawn point on the pitch
- No island terrain, baseplate, floating islands, waterfall, or football-game UI

`src/server/init.server.luau` clears the prior terrain/map and creates the stadium directly in `Workspace`.
