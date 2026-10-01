local _, F = ...
local S = {}; F.Style = S
S.gold = {0.94,0.77,0.42}; S.ink = {0.22,0.13,0.07}; S.muted = {0.66,0.61,0.49}
S.icons = {crate="Interface\\Icons\\INV_Crate_01", writ="Interface\\Icons\\INV_Misc_Note_01", flight="Interface\\Icons\\Ability_Druid_FlightForm", route="Interface\\Icons\\INV_Misc_Map_01"}
S.qualityPending={}
S.panels={}
function S.Faction()
  return F.db and F.db.settings.debugAlliance and "Alliance" or UnitFactionGroup("player")
end
function S.ApplyTheme()
  local theme=S.Theme()
  for _,panel in ipairs(S.panels)do panel:SetBackdropColor(unpack(theme.panel))end
  if F.window then F.window:SetBackdropColor(unpack(theme.bg))end
  if F.banner then S.Accent(F.banner);F.crest:SetTexture(theme.crest)end
  if F.compassStripe then S.Accent(F.compassStripe)end
  if F.auctionScanUI then F.auctionScanUI.pose()end
end
function S.RarityColor(id)
  local info=C_Item and C_Item.GetItemInfo or GetItemInfo
  local quality
  if info then local _,_,value=info(id);quality=value end
  if quality==nil then S.qualityPending[id]=true;return 0.66,0.66,0.66 end
  S.qualityPending[id]=nil
  local color=C_Item and C_Item.GetItemQualityColor or GetItemQualityColor
  if color then return color(quality)end
  local entry=ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
  if entry then return entry.r,entry.g,entry.b end
  return 0.66,0.66,0.66
end
function S.InnerBorder(parent,inset)
  local lines={}
  for _,edge in ipairs({"TOP","BOTTOM","LEFT","RIGHT"})do
    local line=parent:CreateTexture(nil,"OVERLAY")
    if edge=="TOP" or edge=="BOTTOM" then
      local y=edge=="TOP" and -inset or inset
      line:SetPoint(edge.."LEFT",parent,edge.."LEFT",inset,y)
      line:SetPoint(edge.."RIGHT",parent,edge.."RIGHT",-inset,y);line:SetHeight(1)
    else
      local x=edge=="LEFT" and inset or -inset
      line:SetPoint("TOP"..edge,parent,"TOP"..edge,x,-inset)
      line:SetPoint("BOTTOM"..edge,parent,"BOTTOM"..edge,x,inset);line:SetWidth(1)
    end
    lines[#lines+1]=line
  end
  return lines
end
function S.ColorBorder(lines,r,g,b,alpha)
  for _,line in ipairs(lines)do line:SetColorTexture(r,g,b,alpha or 0.8)end
end
function S.Theme()
  if S.Faction()=="Alliance" then
    return {bg={0.065,0.071,0.080,1},panel={0.10,0.113,0.124,1},accent={0.26,0.32,0.37,1},fade={0.08,0.092,0.11,1},crest="Interface\\Timer\\Alliance-Logo"}
  end
  return {bg={0.09,0.075,0.055,1},panel={0.15,0.12,0.09,1},accent={0.55,0.20,0.14,1},crest="Interface\\Timer\\Horde-Logo"}
end
function S.Accent(texture)
  local theme=S.Theme()
  local opacity=texture:GetAlpha()
  texture:SetColorTexture(unpack(theme.accent))
  if texture.SetGradient and CreateColor then
    -- Explicitly reset both ends when returning from the Alliance preview.
    texture:SetColorTexture(1,1,1,1)
    texture:SetGradient("HORIZONTAL",CreateColor(unpack(theme.accent)),CreateColor(unpack(theme.fade or theme.accent)))
  end
  texture:SetAlpha(opacity or 1)
end
function S.BindItem(frame,id)
  frame.itemID=id;frame:EnableMouse(id~=nil)
  frame:SetScript("OnEnter",function(self)
    if not self.itemID then return end
    GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetHyperlink("item:"..self.itemID)
    GameTooltip:AddLine("Shift-click: fill auction search",0.94,0.77,0.42);GameTooltip:Show()
  end)
  frame:SetScript("OnLeave",function()GameTooltip:Hide()end)
  frame:SetScript("OnMouseUp",function(self,button)
    if F.ItemClick(self.itemID,button) then return end
    local selectItem=rawget(self,"selectItem")
    if button=="LeftButton" and selectItem then selectItem()end
  end)
end

local function itemName(id)
  local info=C_Item and C_Item.GetItemInfo or GetItemInfo
  local name=info and info(id)
  if name then return name end
  local item=F.cratesByID[id] or F.writsByID[id]
  if item then return item.name end
  local recipe=F.recipeData.recipes[tostring(id)]
  if recipe then return (recipe[1] or recipe).name end
  local leaf=F.recipeData.metadata.leaves[tostring(id)]
  if leaf then return leaf.name end
  for _,crate in ipairs(F.catalog.crates)do
    for _,option in ipairs(crate.options)do if option.itemId==id then return option.name end end
  end
end
function F.SearchAuctionItem(id)
  local modern=AuctionHouseFrame and AuctionHouseFrame:IsShown()
  local legacy=AuctionFrame and AuctionFrame:IsShown()
  if not modern and not legacy then return false end
  -- Use the box the player has clicked into; never choose a tab or search mode.
  local box=GetCurrentKeyBoardFocus and GetCurrentKeyBoardFocus()
  if not box or not box.SetText or not box:IsObjectType("EditBox") or not box:IsShown() then return false end
  local name=itemName(id)
  if not name then return false end
  box:SetText(name)
  box:SetFocus()
  box:SetCursorPosition(#name)
  GameTooltip:Hide()
  return true
end
function F.ItemClick(id,button)
  if not id or button~="LeftButton" or not IsShiftKeyDown or not IsShiftKeyDown() then return false end
  F.SearchAuctionItem(id)
  return true
end
function S.Text(parent, text, x, y, width, font, color)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
  t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT"); t:SetText(text or "")
  if color then t:SetTextColor(unpack(color)) end
  return t
end
function S.Panel(parent, x, y, w, h, parchment)
  local p=CreateFrame("Frame",nil,parent,"BackdropTemplate");p:SetPoint("TOPLEFT",x,y);p:SetSize(w,h)
  p:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=32,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
  p:SetBackdropColor(unpack(S.Theme().panel))
  S.panels[#S.panels+1]=p
  p:SetBackdropBorderColor(0.52,0.40,0.22,1)
  local solid=p:CreateTexture(nil,"BACKGROUND",nil,-8);solid:SetPoint("TOPLEFT",4,-4);solid:SetPoint("BOTTOMRIGHT",-4,4);solid:SetColorTexture(0.055,0.04,0.024,0.97)
  if parchment then
    local tex=p:CreateTexture(nil,"BACKGROUND",nil,1);tex:SetPoint("TOPLEFT",5,-5);tex:SetPoint("BOTTOMRIGHT",-5,5)
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo("QuestBG-Parchment") then tex:SetAtlas("QuestBG-Parchment")
    else tex:SetTexture("Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal") end
    p.paper=tex
  end
  return p
end
function S.Button(parent, text, x, y, w, fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,26);b:SetText(text);b:SetScript("OnClick",fn);return b
end
function S.Icon(parent, x,y,size, itemID, fallback)
  local p=S.Panel(parent,x,y,size,size)
  p.icon=p:CreateTexture(nil,"ARTWORK");p.icon:SetPoint("TOPLEFT",4,-4);p.icon:SetPoint("BOTTOMRIGHT",-4,4);p.icon:SetTexCoord(0.07,0.93,0.07,0.93)
  p.rarityBorder=S.InnerBorder(p,4)
  S.SetIcon(p,itemID,fallback);return p
end
function S.SetIcon(frame,id,fallback)
  S.BindItem(frame,id)
  local icon=id and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
  if not icon and id and GetItemIcon then icon=GetItemIcon(id) end
  frame.icon:SetTexture(icon or fallback or S.icons.crate)
  local r,g,b=0,0,0
  local cargo=id and (F.cratesByID[id] or F.writsByID[id])
  if cargo then r,g,b=S.RarityColor(id)end
  S.ColorBorder(frame.rarityBorder,r,g,b,cargo and 1 or 0)
end
function S.Rule(parent,x,y,w)
  local t=parent:CreateTexture(nil,"ARTWORK");t:SetPoint("TOPLEFT",x,y);t:SetSize(w,1);t:SetColorTexture(0.5,0.35,0.15,0.4);return t
end
function S.Money(value)
  if not value then return "|cff978977Unpriced|r" end
  value=math.ceil(value)
  local g,s,c=math.floor(value/10000),math.floor(value/100)%100,value%100
  local result=""
  if g>0 then result=g.."|TInterface\\MoneyFrame\\UI-GoldIcon:12:12:1:0|t " end
  if s>0 or g>0 then result=result..s.."|TInterface\\MoneyFrame\\UI-SilverIcon:12:12:1:0|t " end
  return result..c.."|TInterface\\MoneyFrame\\UI-CopperIcon:12:12:1:0|t"
end
function S.Count(id)
  local fn=C_Item and C_Item.GetItemCount or GetItemCount
  return fn and fn(id) or 0
end
function S.Age(stamp)
  if not stamp then return "age unknown" end
  local minutes=math.max(0,math.floor((F.Now()-stamp)/60))
  if minutes<60 then return minutes.."m ago" end
  if minutes<1440 then return math.floor(minutes/60).."h ago" end
  return math.floor(minutes/1440).."d ago"
end
function S.Check(parent,text,x,y,key)
  local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(26,26)
  S.Text(b,text,32,-6,360,"GameFontHighlight")
  b:SetScript("OnShow",function(self)self:SetChecked(F.db.settings[key])end)
  b:SetScript("OnClick",function(self) F.db.settings[key]=not not self:GetChecked();F.ApplySettings() end)
  return b
end
