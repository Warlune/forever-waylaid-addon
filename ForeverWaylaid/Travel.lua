local _,F=...
local T={};F.Travel=T

local function point(map,x,y,name)
  return {mapID=map,x=x/100,y=y/100,name=name}
end
-- Classic boarding points. Costs include estimated waiting/loading time;
-- these are not live departure schedules. No summons or Forever-only ports.
-- Route pairs: Nauticus data.lua; dock coordinates: Leatrix Maps map data.
T.connections={
  {"Horde","Zeppelin",point(1411,50.9,13.9,"Durotar: Tirisfal zeppelin"),point(1420,60.7,58.8,"Tirisfal: Durotar zeppelin"),240},
  {"Horde","Zeppelin",point(1411,50.6,12.6,"Durotar: Grom'gol zeppelin"),point(1434,31.4,30.2,"Grom'gol: Durotar zeppelin"),240},
  {"Horde","Zeppelin",point(1420,61.9,59.1,"Tirisfal: Grom'gol zeppelin"),point(1434,31.6,29.1,"Grom'gol: Tirisfal zeppelin"),240},
  {"Neutral","Boat",point(1413,63.7,38.6,"Ratchet dock"),point(1434,25.9,73.1,"Booty Bay dock"),240},
  {"Alliance","Boat",point(1437,4.6,57.1,"Menethil: Auberdine dock"),point(1439,32.4,43.8,"Auberdine: Menethil dock"),240},
  {"Alliance","Boat",point(1437,5,63.5,"Menethil: Theramore dock"),point(1445,71.6,56.4,"Theramore dock"),240},
  {"Alliance","Boat",point(1439,33.2,40.1,"Auberdine: Rut'theran dock"),point(1438,54.9,96.8,"Rut'theran dock"),180},
  {"Alliance","Boat",point(1444,43.3,42.8,"Forgotten Coast dock"),point(1444,31,39.8,"Feathermoon dock"),180},
  {"Alliance","Tram",point(1453,66.4,34.1,"Stormwind tram entrance"),point(1455,73,50.2,"Ironforge tram entrance"),180},
}
local cities={
  {"Alliance",3561,10059,point(1453,49.6,86.2,"Stormwind mage tower")},
  {"Alliance",3562,11416,point(1455,25.5,8.4,"Ironforge Mystic Ward")},
  {"Alliance",3565,11419,point(1457,55.1,89.6,"Darnassus Temple of the Moon")},
  {"Horde",3567,11417,point(1454,38.7,85.5,"Orgrimmar Valley of Spirits")},
  {"Horde",3563,11418,point(1458,84.6,16.3,"Undercity Magic Quarter")},
  {"Horde",3566,11420,point(1456,22.5,16.9,"Thunder Bluff Spirit Rise")},
}
local devices={
  {18986,20219,260,point(1446,51.6,27.9,"Gadgetzan transporter")},
  {18984,20222,260,point(1452,61.2,37.6,"Everlook transporter")},
}
local function count(id)
  local fn=C_Item and C_Item.GetItemCount or GetItemCount
  return fn and fn(id,false) or 0
end
local function known(id)
  local fn=C_SpellBook and C_SpellBook.IsSpellKnown or IsSpellKnown
  return fn and fn(id) or false
end
local function remaining(start,duration,enabled)
  if type(start)~="number" or type(duration)~="number" or enabled==false or enabled==0 then return nil end
  return math.max(0,start+duration-(GetTime and GetTime() or 0))
end
function T.ItemCooldown(id)
  local fn=C_Item and C_Item.GetItemCooldown or GetItemCooldown
  if fn then return remaining(fn(id)) end
end
function T.SpellCooldown(id)
  if C_Spell and C_Spell.GetSpellCooldown then
    local info=C_Spell.GetSpellCooldown(id)
    if info then return remaining(info.startTime,info.duration,info.isEnabled) end
  elseif GetSpellCooldown then return remaining(GetSpellCooldown(id)) end
end
function T.BindName()
  local fn=GetBindLocation or (C_PlayerInfo and C_PlayerInfo.GetBindLocation)
  return fn and fn()
end
function T.RecordHome()
  local p=F.Route.Player();local name=T.BindName()
  if p and name then p.name=name;F.char.home={name=name,point=p} end
end
function T.Options()
  local result={links={},personal={},resources={}}
  local faction=UnitFactionGroup("player")
  for _,entry in ipairs(T.connections)do
    if entry[1]=="Neutral" or entry[1]==faction then
      local a,b=F.Route.World(entry[3]),F.Route.World(entry[4])
      if a and b then
        result.links[#result.links+1]={from=a,to=b,mode=entry[2],seconds=entry[5]}
        result.links[#result.links+1]={from=b,to=a,mode=entry[2],seconds=entry[5]}
      end
    end
  end
  local function personal(p,mode,id,wait,seconds,resource,uses)
    p=p and (p.wx and p or F.Route.World(p))
    if p and wait then
      result.personal[#result.personal+1]={to=p,mode=mode,id=id,wait=wait,seconds=seconds,resource=resource}
      result.resources[resource]=uses or 1
    end
  end
  local home=F.char.home
  if home and home.name==T.BindName() and count(6948)>0 then
    personal(home.point,"Hearthstone",6948,T.ItemCooldown(6948),15,"hearth")
  end
  local _,class
  if UnitClass then _,class=UnitClass("player") end
  if class=="MAGE" then
    for _,entry in ipairs(cities)do
      if entry[1]==faction then
        if known(entry[2]) and count(17031)>0 then personal(entry[4],"Teleport",entry[2],T.SpellCooldown(entry[2]),15,"runeTeleport",count(17031)) end
        if known(entry[3]) and count(17032)>0 then personal(entry[4],"Portal",entry[3],T.SpellCooldown(entry[3]),25,"runePortal",count(17032)) end
      end
    end
  end
  local rank=F.ProfessionRank and F.ProfessionRank("Engineering")
  for _,entry in ipairs(devices)do
    if count(entry[1])>0 and rank and rank>=entry[3] and known(entry[2]) then
      personal(entry[4],"Engineering teleport",entry[1],T.ItemCooldown(entry[1]),20,"engineering:"..entry[1])
    end
  end
  return result
end

function F.FlightCoverageText()
  local missing=F.MissingFlightContinents()
  if #missing==0 then return nil end
  return table.concat(missing," / ").." not scanned. Routes may not be optimal."
end
