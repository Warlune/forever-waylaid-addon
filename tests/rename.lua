local W,C=...
local keys={'ForeverWaylaidDB','ForeverWaylaidCharDB','ForeverCompanionsDB','ForeverCompanionsCharDB',
  'WaylaidForeverDB','WaylaidForeverCharDB','CompanionsForeverDB','CompanionsForeverCharDB',
  'WaylaidForeverLegacyLoader','CompanionsForeverLegacyLoader','CompanionsForever'}
local saved={};for _,key in ipairs(keys)do saved[key]=_G[key]end
local oldLoaded,oldAPI=IsAddOnLoaded,C_AddOns
C_AddOns=nil;IsAddOnLoaded=function(name)return name=='ForeverWaylaid' or name=='ForeverCompanions'end
assert(loadfile('compatibility/ForeverWaylaid/Compatibility.lua'))()
assert(loadfile('compatibility/ForeverCompanions/Compatibility.lua'))()
ForeverWaylaidDB={settings={textSize=14,peerSharing=true}}
ForeverWaylaidCharDB={flights={nodes={one={name='Learned flight'}},edges={}},pins={[42]={x=0.5}},
  localPrices={market={[10]={price=123,source='Forever Waylaid'}}},pets={oldBundled=true}}
WaylaidForeverDB=nil;WaylaidForeverCharDB=nil
local renamed={};assert(loadfile('WaylaidForever/Core.lua'))('WaylaidForever',renamed)
renamed.events.scripts.OnEvent(nil,'ADDON_LOADED','WaylaidForever')
assert(not renamed.legacyBlocked and renamed.db.settings.textSize==14 and renamed.db.settings.peerSharing)
assert(renamed.char.flights.nodes.one.name=='Learned flight' and renamed.char.pins[42].x==0.5)
assert(renamed.char.localPrices.market[10].source=='Waylaid Forever')
assert(ForeverWaylaidCharDB.localPrices.market[10].source=='Forever Waylaid','Historical source is untouched')
assert(renamed.char~=ForeverWaylaidCharDB and renamed.char.flights~=ForeverWaylaidCharDB.flights)
renamed.char.localPrices.market[10].price=456
renamed.events.scripts.OnEvent(nil,'ADDON_LOADED','WaylaidForever')
assert(renamed.char.localPrices.market[10].price==456,'Reload preserves newer prices')
ForeverCompanionsDB={settings={textSize=13,reduceMotion=true}}
ForeverCompanionsCharDB=C.char
CompanionsForeverDB=nil;CompanionsForeverCharDB=nil
local function loadCompanion()
  local result={}
  for _,name in ipairs({'Core','Style','PetData','Pets','PetProgression','PetUI','Desktop'})do
    assert(loadfile('CompanionsForever/'..name..'.lua'))('CompanionsForever',result)
  end
  return result
end
local companion=loadCompanion();companion.Initialize()
assert(companion.ready and not companion.blocked)
assert(companion.db.settings.textSize==13 and companion.db.settings.reduceMotion)
assert(companion.char~=ForeverCompanionsCharDB and companion.char.pets~=ForeverCompanionsCharDB.pets)
assert(companion.char.pets.tokens==C.char.pets.tokens and #companion.char.pets.pets==#C.char.pets.pets)
companion.char.pets.tokens=72;companion.Initialize()
assert(companion.char.pets.tokens==72,'Renamed companion save takes precedence on future logins')
assert(not companion.char.pets.oldBundled,'Standalone pet progress wins over older bundled progress')
CompanionsForeverLegacyLoader=nil
local blocked=loadCompanion();blocked.Initialize()
assert(blocked.blocked and not blocked.Pets.state,'An old running standalone game must not run alongside the renamed one')
WaylaidForeverLegacyLoader=nil
local blockedW={};assert(loadfile('WaylaidForever/Core.lua'))('WaylaidForever',blockedW)
blockedW.events.scripts.OnEvent(nil,'ADDON_LOADED','WaylaidForever')
assert(blockedW.legacyBlocked and not blockedW.char,'An old running ledger must not be duplicated')
assert(SLASH_WAYLAIDFOREVER1=='/wf' and SLASH_WAYLAIDFOREVER3=='/fwl')
assert(SLASH_COMPANIONSFOREVER1=='/cf' and SLASH_COMPANIONSFOREVER3=='/fcp')
for _,key in ipairs(keys)do _G[key]=saved[key]end
IsAddOnLoaded,C_AddOns=oldLoaded,oldAPI
print('PASS: renamed addon imports, price labels, deep-copy isolation, standalone-save priority, reload persistence, old engine guards and command aliases')
