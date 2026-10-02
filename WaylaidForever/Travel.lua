local _,F=...
local T={};F.Travel=T

local function point(map,x,y,name)
  return {mapID=map,x=x/100,y=y/100,name=name}
end
-- Build complete journeys around each directed transport loop. Staying on
-- board through an intermediate port pays its dwell, not another wait for
-- a new boat. Paths keep intermediate ports for directions and map display.
function T.PublicLinks(faction)
  local links={}
  local raceID
  if UnitRace then local _,_,id=UnitRace("player");raceID=id end
  for _,route in ipairs(F.TransportRoutes)do
    if (route.faction=="Neutral" or route.faction==faction) and (not route.raceID or route.raceID==raceID) then
      local points,cycle,valid={},0,true
      for i,stop in ipairs(route.stops)do
        points[i]=F.Route.World(stop)
        if not points[i] then valid=false end
        cycle=cycle+route.legs[i]+stop.dwell
      end
      -- A missing map conversion must not silently remove a stop from a loop.
      if valid then
        local n=#route.stops
        for start=1,n do
          local at,ride,via=start,0,{}
          for _=1,n-1 do
            ride=ride+route.legs[at]
            at=at%n+1
            local copy={};for i,p in ipairs(via)do copy[i]=p end
            links[#links+1]={from=points[start],to=points[at],mode=route.mode,
              routeID=route.id,via=copy,boardingWait=cycle/2,rideSeconds=ride,
              seconds=cycle/2+ride+10,estimated=true}
            via[#via+1]=points[at]
            ride=ride+route.stops[at].dwell
          end
        end
      end
    end
  end
  return links
end
function T.ViaText(detail)
  local names={}
  for _,p in ipairs(detail and detail.via or {})do names[#names+1]=p.name end
  return #names>0 and ("Stay aboard via "..table.concat(names,", ")) or nil
end
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
  result.links=T.PublicLinks(faction)
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
