local F=...
local oldMap,oldOverlay,oldReady=WorldMapFrame,F.worldOverlay,F.ready
local oldDisplay,oldProject,oldPlayer=F.DisplayRoute,F.Geometry.Project,F.Route.Player
local oldEnabled=F.db.settings.worldRoute
local mapID=1411
local levels={PIN_FRAME_LEVEL_MAP_EXPLORATION=2002,PIN_FRAME_LEVEL_FOG_OF_WAR=2006,PIN_FRAME_LEVEL_QUEST_BLOB=2007}
local manager={GetValidFrameLevel=function(_,kind)return levels[kind]end}
WorldMapFrame={ScrollContainer={Child=UIParent},GetMapID=function()return mapID end,
  GetPinFrameLevelsManager=function()return manager end}
F.ready=true;F.db.settings.worldRoute=true;F.worldOverlay=nil
F.Route.Player=function()return nil end
local a={x=0.25,y=0.25,name='Road'}
local b={x=0.5,y=0.5,name='Zeppelin tower'}
local c={x=1.5,y=0.5,name='Off-map destination'}
F.Geometry.Project=function(p)return p.x,p.y end
F.DisplayRoute=function()return {
  {from=a,to=b,mode='Travel',road='mapped'},
  {from=b,to=c,mode='Zeppelin'},
  {from=a,to=c,mode='Travel',road='unknown'},
},{} end
F.InstallMap()
local overlay=F.worldOverlay
overlay.SetFrameLevel=function(self,level)self.level=level end
overlay.GetFrameLevel=function(self)return self.level or 6 end
for _,id in ipairs({1411,1454,947,1411})do
  mapID=id;overlay.scripts.OnUpdate(nil,0.06)
  assert(overlay.level>levels.PIN_FRAME_LEVEL_MAP_EXPLORATION and overlay.level>levels.PIN_FRAME_LEVEL_FOG_OF_WAR,
    'Zone, city and world routes must render above full-map exploration/fog pins')
  assert(overlay.level==levels.PIN_FRAME_LEVEL_QUEST_BLOB,'Keep routes below normal POI/player icons')
  assert(#overlay.lines>2 and overlay.lines[1].shown and overlay.lines[2].shown,
    'Keep walking, transport and unknown-walk dashes when changing map views')
  assert(#overlay.pins==1 and overlay.pins[1].shown,'Transport departure marker stays visible without an itinerary panel')
end
levels.PIN_FRAME_LEVEL_MAP_EXPLORATION=2102
levels.PIN_FRAME_LEVEL_FOG_OF_WAR=2106
levels.PIN_FRAME_LEVEL_QUEST_BLOB=2107
overlay.scripts.OnUpdate(nil,0.06)
assert(overlay.level==2107,'Refresh layer after providers change frame levels')
F.db.settings.worldRoute=false;overlay.scripts.OnUpdate(nil,0.06)
for _,line in ipairs(overlay.lines)do assert(not line.shown,'Disabling routes hides raised lines')end
for _,pin in ipairs(overlay.pins)do assert(not pin.shown,'Disabling routes hides raised markers')end
F.UpdateWorldRouteLayer(overlay,{}) -- Older clients without a layer manager retain the canvas fallback.
assert(overlay.level==2107)
WorldMapFrame,F.worldOverlay,F.ready=oldMap,oldOverlay,oldReady
F.DisplayRoute,F.Geometry.Project,F.Route.Player=oldDisplay,oldProject,oldPlayer
F.db.settings.worldRoute=oldEnabled
print('PASS: zone/city/world route layer, map changes, departure markers, provider level changes and visibility toggle')
