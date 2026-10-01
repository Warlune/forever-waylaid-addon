local _,F=...
local A={interval=0.16,frameCount=16};F.Scribe=A
-- Actual pixel-art poses, presented without interpolation or deformation.
-- The desk, banner and reference ledger always use the first frame.
function A.Create(parent)
  local rig={phase=0,regions={}}
  local frame=CreateFrame("Frame",nil,parent);frame:SetSize(218,218);frame:SetPoint("TOP",0,-55)
  rig.frame=frame
  local scale=218/256
  local pieces={
    {0,194,256,256,false}, -- fixed desk and faction banner
    {0,0,80,194,false}, -- fixed reference ledger, purse and coins
    {80,0,216,194,true}, -- scribe, quill, writing and page turn
    {216,0,256,114,false},
    {216,114,256,174,true}, -- candle flame
    {216,174,256,194,false}, -- fixed candlestick foot
  }
  for _,bounds in ipairs(pieces)do
    local texture=frame:CreateTexture(nil,"ARTWORK")
    texture:SetPoint("TOPLEFT",bounds[1]*scale,-bounds[2]*scale)
    texture:SetSize((bounds[3]-bounds[1])*scale,(bounds[4]-bounds[2])*scale)
    rig.regions[#rig.regions+1]={texture=texture,bounds=bounds,animated=bounds[5]}
  end
  function rig:Update(phase)
    self.phase=phase%A.frameCount
    local index=math.floor(self.phase)
    local faction=F.Style.Faction()=="Alliance" and "Alliance" or "Horde"
    if self.index==index and self.faction==faction then return end
    local changedFaction=self.faction~=faction
    self.index,self.faction=index,faction
    for _,region in ipairs(self.regions)do
      if changedFaction then
        region.texture:SetTexture("Interface\\AddOns\\ForeverWaylaid\\Art\\AuctionScribe"..faction.."Pixel16.tga","CLAMP","CLAMP","NEAREST")
      end
      if changedFaction or region.animated then
        local cell=region.animated and index or 0
        local x,y=(cell%4)*256,math.floor(cell/4)*256
        local b=region.bounds
        region.texture:SetTexCoord((x+b[1])/1024,(x+b[3])/1024,(y+b[2])/1024,(y+b[4])/1024)
      end
    end
  end
  rig:Update(0)
  return rig
end
