local _, F = ...
local S = {}; F.Style = S
S.gold = {0.94,0.77,0.42}; S.ink = {0.22,0.13,0.07}; S.muted = {0.66,0.61,0.49}
S.icons = {crate="Interface\\Icons\\INV_Crate_01", writ="Interface\\Icons\\INV_Misc_Note_01", flight="Interface\\Icons\\Ability_Druid_FlightForm", route="Interface\\Icons\\INV_Misc_Map_01"}
function S.Text(parent, text, x, y, width, font, color)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
  t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT"); t:SetText(text or "")
  if color then t:SetTextColor(unpack(color)) end
  return t
end
function S.Panel(parent, x, y, w, h, parchment)
  local p=CreateFrame("Frame",nil,parent,"BackdropTemplate");p:SetPoint("TOPLEFT",x,y);p:SetSize(w,h)
  p:SetBackdrop({bgFile="Interface\\DialogFrame\\UI-DialogBox-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=32,edgeSize=16,insets={left=4,right=4,top=4,bottom=4}})
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
  S.SetIcon(p,itemID,fallback);return p
end
function S.SetIcon(frame,id,fallback)
  local icon=id and C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(id)
  if not icon and id and GetItemIcon then icon=GetItemIcon(id) end
  frame.icon:SetTexture(icon or fallback or S.icons.crate)
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
  b:SetScript("OnClick",function(self) F.db.settings[key]=not not self:GetChecked();F.Refresh() end)
  return b
end
