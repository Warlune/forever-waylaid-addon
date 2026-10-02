local waylaid=...
local oldAccount,oldCharacter=ForeverWaylaidDB,ForeverWaylaidCharDB
local function loadAddon()
  local C={}
  for _,name in ipairs({'Core','Style','PetData','Pets','PetProgression','PetUI','Desktop'})do
    assert(loadfile('ForeverCompanions/'..name..'.lua'))('ForeverCompanions',C)
  end
  return C
end
-- Standalone login must work with no Waylaid save, UI or namespace.
ForeverWaylaidDB=nil;ForeverWaylaidCharDB=nil
ForeverCompanionsDB=nil;ForeverCompanionsCharDB=nil
local C=loadAddon()
C.events.scripts.OnEvent(nil,'ADDON_LOADED','ForeverCompanions')
C.events.scripts.OnEvent(nil,'PLAYER_LOGIN')
assert(C.ready and C.char~=waylaid.char and C.db~=waylaid.db)
assert(C.Pets.state.tokens==25 and #C.Pets.state.pets==0)
assert(C.Pets.Rescue());local pet=C.Pets.Active()
pet.level=19;pet.best=17;pet.xp=8;pet.age=1234;pet.health=62
C.Pets.state.tokens=93;C.Pets.state.inventory.food=7;C.Pets.state.packs[2]=1
C.Pets.state.share=true
local legacy=C.char.pets
-- Import uses a deep copy, preserving every field without advancing the old engine.
ForeverWaylaidDB={settings={textSize=16,highContrast=true,peerSharing=true}}
ForeverWaylaidCharDB={pets=legacy}
ForeverCompanionsDB=nil;ForeverCompanionsCharDB=nil
C=loadAddon();C.Initialize()
local imported=C.Pets.Active()
assert(imported~=pet and imported.level==19 and imported.best==17 and imported.xp==8 and imported.health==62)
assert(C.char.pets~=legacy and C.char.pets.inventory~=legacy.inventory)
assert(C.Pets.state.tokens==93 and C.Pets.state.inventory.food==7 and C.Pets.state.packs[2]==1 and C.Pets.state.share)
assert(C.char.legacyImportedAt and C.db.settings.textSize==16 and C.db.settings.highContrast and C.db.settings.peerSharing==nil)
imported.level=20;C.Pets.state.tokens=81;C.Initialize()
assert(C.Pets.Active().level==20 and C.Pets.state.tokens==81 and pet.level==19 and legacy.tokens==93,'Reload never re-imports or edits the source')
assert(not C.ImportLegacy(true),'One-time import cannot roll back earned progress')
-- Installing standalone first does not authorize replacing that new progress later.
ForeverCompanionsDB=nil;ForeverCompanionsCharDB=nil;ForeverWaylaidCharDB=nil
C=loadAddon();C.Initialize();assert(C.Pets.Rescue());C.Pets.Active().level=5
local started=C.char.pets
ForeverWaylaidCharDB={pets=legacy};C.Initialize()
assert(C.char.pets==started and not C.char.legacyImportedAt and not C.ImportLegacy(false))
assert(C.ImportLegacy(true));assert(C.Pets.Active().level==19)
assert(C.char.beforeLegacyImport~=started and C.char.beforeLegacyImport.pets[1].level==5)
-- Old combined releases must not run a second companion engine alongside this one.
local oldLoaded,oldMarker=IsAddOnLoaded,ForeverWaylaidCompanionsSplit
IsAddOnLoaded=function(name)return name=='ForeverWaylaid'end;ForeverWaylaidCompanionsSplit=nil
local blocked=loadAddon();blocked.Initialize()
assert(blocked.blocked and not blocked.ready and not blocked.Pets.state)
assert(pcall(blocked.Pets.events.scripts.OnEvent,nil,'PARTY_KILL','me','enemy'))
IsAddOnLoaded=oldLoaded;ForeverWaylaidCompanionsSplit=oldMarker
ForeverWaylaidDB=oldAccount;ForeverWaylaidCharDB=oldCharacter
ForeverCompanions=C
C.events.scripts.OnEvent(nil,'PLAYER_LOGIN')
C.db.settings.textSize=0;C.db.settings.highContrast=false
local wasExpanded=waylaid.char.navExpanded
waylaid.char.navExpanded=true
C.Pets.ToggleCompass(true)
assert(waylaid.char.navExpanded and C.compass~=waylaid.compass,'Companion display cannot replace the route map')
waylaid.OpenCompanions(true);assert(not C.char.navPets,'Optional Waylaid shortcut targets standalone compact view')
waylaid.OpenCompanions();assert(C.Pets.window:IsShown())
C.Pets.window:Hide();waylaid.char.navExpanded=wasExpanded
local font=waylaid.db.settings.textSize;C.db.settings.textSize=16;C.ApplySettings()
assert(waylaid.db.settings.textSize==font,'Companion settings are independent')
C.OpenSettings();assert(C.settings and C.dropdowns.textSize)
C.settings:Hide();C.db.settings.textSize=0;C.ApplySettings()
print('PASS: independent companion login, deep-copy legacy migration, reload persistence, backup before replacement, old-build guard and optional launchers')
return C
