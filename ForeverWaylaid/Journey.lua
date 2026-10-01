local _,F=...

function F.CommonRouteMap(a,b)
  if not a then return b end
  if not b then return a end
  local ancestors,seen={},{}
  local current=a
  for _=1,15 do
    if not current or current==0 or ancestors[current] then break end
    ancestors[current]=true
    local info=C_Map.GetMapInfo(current);current=info and info.parentMapID
  end
  current=b
  for _=1,15 do
    if not current or current==0 or seen[current] then break end
    if ancestors[current] then return current end
    seen[current]=true
    local info=C_Map.GetMapInfo(current);current=info and info.parentMapID
  end
  return a
end
