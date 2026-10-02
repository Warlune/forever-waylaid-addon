local _,F=...
CompanionsForever=F
F.version="0.1.1"
F.defaults={ledgerScale=1,compassScale=1,textSize=0,highContrast=false,reduceMotion=false,debugAlliance=false}
function F.Now()return GetServerTime and GetServerTime() or time()end
function F.Print(message)
  if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffdfbc65Companions Forever:|r "..message)end
end
local function copy(value,seen)
  if type(value)~="table" then return value end
  seen=seen or {};if seen[value]then return seen[value]end
  local result={};seen[value]=result
  for key,item in pairs(value)do result[copy(key,seen)]=copy(item,seen)end
  return result
end
local function legacyPets()
  local source=type(WaylaidForeverCharDB)=="table" and WaylaidForeverCharDB.pets and WaylaidForeverCharDB or ForeverWaylaidCharDB
  return type(source)=="table" and source.pets
end
function F.ImportLegacy(replace)
  local pets=legacyPets()
  if type(pets)~="table" then return false,"Enable updated Waylaid Forever on this character and log in once to import its pets." end
  if F.char.legacyImportedAt then return false,"This character's Waylaid pets have already been imported." end
  if F.char.pets~=nil and not replace then return false,"Your current stable is kept. Use Import old pets in Settings to replace it with a backup." end
  if F.Pets.state and F.Pets.state.battle then return false,"Finish your battle before importing pets." end
  if F.char.pets then F.char.beforeLegacyImport=copy(F.char.pets)end
  F.char.pets=copy(pets)
  F.char.legacyImportedAt=F.Now()
  F.Pets.Init()
  return true,"Imported Waylaid pets, tokens, supplies and tower progress. The original save was kept."
end
function F.Initialize()
  -- Old bundled builds would run a second pet engine and answer peer messages.
  local loaded=C_AddOns and C_AddOns.IsAddOnLoaded or IsAddOnLoaded
  if loaded and ((loaded("ForeverWaylaid") and not WaylaidForeverLegacyLoader)
      or (loaded("ForeverCompanions") and not CompanionsForeverLegacyLoader)) then
    F.blocked=true
    F.Print("Install the included saved-data compatibility folders over the old addons, then restart WoW. This prevents two pet games running together.")
    return
  end
  CompanionsForeverDB=type(CompanionsForeverDB)=="table" and CompanionsForeverDB or copy(ForeverCompanionsDB) or {}
  CompanionsForeverCharDB=type(CompanionsForeverCharDB)=="table" and CompanionsForeverCharDB or copy(ForeverCompanionsCharDB) or {}
  F.db,F.char=CompanionsForeverDB,CompanionsForeverCharDB
  if type(F.db.settings)~="table" then
    F.db.settings={}
    local account=WaylaidForeverDB or ForeverWaylaidDB
    local old=type(account)=="table" and account.settings
    if type(old)=="table" then
      for key in pairs(F.defaults)do F.db.settings[key]=copy(old[key])end
    end
  end
  for key,value in pairs(F.defaults)do if F.db.settings[key]==nil then F.db.settings[key]=value end end
  if F.char.pets==nil and type(legacyPets())=="table" then
    local _,notice=F.ImportLegacy(false);F.Pets.notice=notice;F.Print(notice)
  else F.Pets.Init()end
  F.ready=true
end
local events=CreateFrame("Frame");F.events=events
events:RegisterEvent("ADDON_LOADED");events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent",function(_,event,name)
  if event=="ADDON_LOADED" and name=="CompanionsForever" then F.Initialize()
  elseif event=="PLAYER_LOGIN" and F.ready then
    F.BuildDesktop();F.ApplySettings()
    F.Print("v"..F.version.." beta — /cf to open, /cf small for the compact window.")
    if not F.char.legacyImportedAt and type(legacyPets())=="table" then
      F.Print("An older Waylaid stable is available. Settings can import it; your current stable will be backed up first.")
    end
  end
end)
SLASH_COMPANIONSFOREVER1="/cf"
SLASH_COMPANIONSFOREVER2="/companions"
SLASH_COMPANIONSFOREVER3="/fcp" -- Compatibility with existing macros.
SlashCmdList.COMPANIONSFOREVER=function(message)
  if not F.ready then F.Print("Update or disable the old bundled Waylaid Forever addon, then reload.");return end
  message=(message or ""):lower():match("^%s*(.-)%s*$")
  if message=="small" then F.Pets.ToggleCompass()
  elseif message=="settings" then F.OpenSettings()
  elseif message=="reset" then F.char.petPosition=nil;F.PlaceDesktop()
  else F.Pets.Toggle()end
end
