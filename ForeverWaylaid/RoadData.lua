local _,F=...
-- Manually traced from fully revealed Forever 1.60.1.69893 map art at
-- https://warcraftforever.games/maps (reviewed 2026-10-01).
-- These are approximate road centerlines, not collision or elevation data.
-- Identical coordinates mark intentional junctions. Never join nearby
-- points merely because they look close across a wall or mountain.
F.roadData={lines={},coverage={1454,1411,1420}}
-- Reuse the reviewed gate crossings as coarse waypoints when an endpoint
-- misses the street network. Do not infer gates from nearby coordinates.
F.roadData.cityExits={
  [1454]="Orgrimmar south gate",
  [1453]="Stormwind - Elwynn gate",
  [1455]="Dun Morogh - Ironforge gate",
  [1457]="Darnassus - Teldrassil gate",
}
local function line(map,name,points)
  local result={name=name,points={},faction=map==1454 and "Horde" or "Both"}
  for _,p in ipairs(points)do result.points[#result.points+1]={map,p[1],p[2]}end
  F.roadData.lines[#F.roadData.lines+1]=result
end
line(1454,"Valley of Strength: south gate",{
  {48.0,94.6},{49.2,92.0},{50.2,89.7},{50.1,85.6},{50.0,81.1},
  {52.0,79.1},{53.0,75.8},{52.7,72.0},{51.0,68.3},{49.1,65.1},
})
line(1454,"Valley of Strength: western street",{
  {50.0,81.1},{48.9,76.8},{47.6,73.6},{45.0,71.7},{44.8,68.4},{47.0,65.7},{49.1,65.1},
})
line(1454,"The Drag",{
  {49.1,65.1},{49.8,62.2},{52.0,60.0},{56.0,59.0},{58.8,56.2},
  {60.0,52.6},{60.5,47.0},{60.2,42.0},{61.7,38.2},{64.0,35.6},
})
line(1454,"Valley of Spirits road",{
  {44.8,68.4},{42.0,71.3},{38.0,73.1},{34.0,74.3},{30.0,73.0},
  {28.5,68.5},{27.6,61.9},{26.4,59.0},{24.0,57.6},{20.5,59.0},{17.4,62.0},
})
line(1454,"Valley of Wisdom road",{
  {44.8,68.4},{41.2,65.2},{39.5,59.2},{38.2,54.2},{38.6,49.0},
  {40.5,44.0},{42.0,41.5},{42.5,38.0},{42.0,34.0},
})
line(1411,"Orgrimmar approach",{
  {45.5,11.7},{45.9,14.0},{46.1,15.4},{46.7,19.8},{47.3,24.7},{48.2,27.5},
  {51.0,30.4},{52.2,33.2},{52.5,38.2},{52.4,42.2},{52.6,43.9},
})
-- The city exit is the only explicit connection between these two maps.
F.roadData.lines[#F.roadData.lines+1]={name="Orgrimmar south gate",faction="Horde",points={{1454,48.0,94.6},{1411,45.5,11.7}}}
line(1411,"Zeppelin tower approach",{{46.1,15.4},{47.6,16.8},{48.8,16.5},{50.0,14.7},{50.7,14.5}})
-- The open forecourt also has a northern approach. The player's in-game
-- screenshot at 46.5,13.9 exposed the missing connection and southward detour.
-- Keep this explicit local connection; do not infer shortcuts elsewhere.
line(1411,"Zeppelin forecourt approach",{{45.9,14.0},{46.5,13.9},{47.5,13.9},{48.6,14.0},{50.0,14.7}})
-- Tower ramps are not legible in the zone artwork: the last yards to the
-- boarding point remain an unverified approach, never a claimed stair path.
line(1411,"Razor Hill road",{
  {52.6,43.9},{52.3,46.4},{52.7,51.5},{52.8,54.9},{54.0,59.7},
  {53.8,62.0},{52.5,66.3},{51.3,68.1},
})
line(1411,"Road to the Barrens bridge",{
  {52.6,43.9},{50.5,44.9},{48.7,44.4},{47.0,42.8},{44.2,42.0},
  {41.5,43.1},{39.4,42.8},{37.2,43.3},{35.2,42.5},{34.0,42.4},
})
line(1411,"Valley of Trials approach",{{51.3,68.1},{49.3,68.1},{47.0,67.0},{44.5,68.0},{42.5,67.5}})
line(1420,"Brill to Lordaeron approach",{
  {60.0,51.3},{61.4,53.1},{61.9,54.3},{63.1,55.4},{63.7,57.5},
  {63.7,59.3},{62.6,61.4},{60.3,63.5},{57.4,64.2},{56.5,65.6},
  {56.1,68.4},{55.6,71.9},
})
line(1420,"Tirisfal zeppelin approach",{{62.6,61.4},{62.4,60.3},{60.9,60.3},{60.7,59.7}})
line(1420,"Road to the Bulwark",{
  {63.7,59.3},{67.0,60.0},{70.1,62.4},{72.7,64.5},{75.4,67.8},
  {78.0,70.7},{80.3,71.6},{82.6,70.8},{85.2,70.6},
})
line(1420,"Brill western road",{
  {60.0,51.3},{57.7,51.5},{55.9,52.1},{54.1,53.9},{51.1,57.3},
  {49.9,57.8},{47.8,57.6},{45.5,56.7},{44.0,55.2},{43.1,54.3},{43.1,52.8},
})
line(1420,"Agamand Mills road",{{43.1,52.8},{43.1,50.3},{42.8,46.9},{45.0,45.5},{47.3,42.8},{48.5,39.8},{49.2,36.2}})
line(1420,"Western farm road",{{43.1,50.3},{39.2,49.7},{36.2,49.0},{33.0,47.7},{29.8,47.3},{27.5,48.7},{25.7,50.1},{24.2,50.1},{22.5,48.4}})
