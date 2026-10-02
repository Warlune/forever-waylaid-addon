local _,F=...
local function count(rows)
  local n=0;for _ in pairs(rows or {})do n=n+1 end;return n
end
function F.ReportMemory()
  local update=C_AddOns and C_AddOns.UpdateAddOnMemoryUsage or UpdateAddOnMemoryUsage
  local usage=C_AddOns and C_AddOns.GetAddOnMemoryUsage or GetAddOnMemoryUsage
  if update then pcall(update)end
  local ok,kb=false,nil
  if usage then ok,kb=pcall(usage,"WaylaidForever")end
  if ok and type(kb)=="number" then F.Print(string.format("Lua memory: %.2f MiB (textures are separate).",kb/1024))
  else F.Print("Lua memory reporting is unavailable in this client.")end
  local prices=0;for _,rows in pairs(F.char.localPrices or {})do prices=prices+count(rows)end
  F.Print("Stored personal prices: "..prices..". Advanced road engine: off.")
end
