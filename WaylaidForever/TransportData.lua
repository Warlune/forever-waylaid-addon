local _,F=...
-- Independently assembled transport facts for Forever 1.60.1 (70124).
-- Coordinates are approximate dock approaches, not gangplank precision.
-- Stops are ordered cyclically; legs[i] travels from i to i+1 (wrapping).
-- Timing is an estimate, never a live departure schedule. Sources and
-- remaining verification work are recorded in data/route-research.json.
local function p(map,x,y,name,dwell)
  return {mapID=map,x=x/100,y=y/100,name=name,dwell=dwell or 60}
end
F.TransportRoutes={
  {id="ratchet-booty-bay",faction="Neutral",mode="Boat",legs={123,131},stops={
    p(1413,63.80,38.75,"Ratchet dock"),p(1434,25.67,73.09,"Booty Bay dock")}},
  {id="gromgol-durotar",faction="Horde",mode="Zeppelin",legs={111,84},stops={
    p(1434,31.17,30.45,"Grom'gol: Durotar zeppelin"),p(1411,50.47,12.69,"Durotar: Grom'gol zeppelin")}},
  {id="menethil-theramore",faction="Alliance",mode="Boat",legs={111,115},stops={
    p(1437,4.75,63.76,"Menethil: Theramore dock"),p(1445,71.73,56.66,"Theramore dock")}},
  {id="ruttheran-auberdine",faction="Alliance",mode="Boat",legs={74,77},stops={
    p(1438,54.81,97.22,"Rut'theran dock"),p(1439,33.31,39.82,"Auberdine: Rut'theran dock")}},
  {id="gromgol-tirisfal",faction="Horde",mode="Zeppelin",legs={547,550},stops={
    p(1434,31.49,29.11,"Grom'gol: Tirisfal zeppelin"),p(1420,61.92,58.91,"Tirisfal: Grom'gol zeppelin")}},
  {id="durotar-tirisfal",faction="Horde",mode="Zeppelin",legs={140,110},stops={
    p(1411,50.98,13.91,"Durotar: Tirisfal zeppelin"),p(1420,60.65,58.91,"Tirisfal: Durotar zeppelin")}},
  {id="feralas-ferry",faction="Alliance",mode="Boat",legs={30,133},stops={
    p(1444,31.01,39.51,"Feathermoon dock"),p(1444,43.12,42.76,"Forgotten Coast dock")}},
  -- This replaces the old two-stop Menethil/Auberdine boat. There is no
  -- reverse sailing around the triangle and Southshore is not optional.
  {id="menethil-southshore-auberdine",faction="Alliance",mode="Boat",legs={111,95,89},stops={
    p(1437,4.49,56.66,"Menethil: Southshore dock"),p(1424,50.66,70.44,"Southshore dock"),
    p(1439,32.34,44.13,"Auberdine: Menethil dock")}},
  {id="steamwheedle-powderfuse",faction="Neutral",mode="Boat",legs={82,83},stops={
    p(1446,68.58,23.00,"Steamwheedle Port"),p(2548,80.60,54.61,"Powderfuse Port, Riverglades")}},
  -- Either faction can physically board skycutters. Safe automatic routes
  -- avoid hostile ports: Dalaran guards currently accept Alliance Skyborne
  -- only, while Skywatcher is in Horde territory. This is a safety filter,
  -- not a claimed race restriction on boarding the vehicle.
  {id="dalaran-valanaar",faction="Alliance",raceID=95,mode="Skycutter",legs={121,140},stops={
    p(1416,12.5,51.8,"Dalaran north skycutter dock"),p(2521,65.9,83.5,"Valanaar east skycutter dock")}},
  {id="skywatcher-valanaar",faction="Horde",mode="Skycutter",legs={105,174},stops={
    p(1412,34.3,25.8,"Skywatcher Plateau, Mulgore"),p(2521,57.9,80.9,"Valanaar west skycutter dock",30)}},
  {id="auberdine-stormwind",faction="Alliance",mode="Boat",legs={82,72},stops={
    p(1439,30.53,40.88,"Auberdine: Stormwind dock"),p(1453,21.79,56.84,"Stormwind Harbor")}},
  -- Retained tram approach points; these still need in-game verification
  -- against the expanded Stormwind map. Do not replace them with city centers.
  {id="deeprun-tram",faction="Alliance",mode="Tram",legs={60,60},stops={
    p(1453,66.4,34.1,"Stormwind tram entrance"),p(1455,73,50.2,"Ironforge tram entrance")}},
}
