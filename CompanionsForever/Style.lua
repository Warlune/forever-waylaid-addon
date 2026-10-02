local _, F = ...
local S = {}; F.Style = S
S.gold = {0.94,0.77,0.42}; S.ink = {0.22,0.13,0.07}; S.muted = {0.66,0.61,0.49}
S.panels={}
S.texts={}
function S.HighContrast()
  return F.db and F.db.settings.highContrast
end
function S.TextColor(text,color)
  text.fwColor=color
  text:SetTextColor(unpack(S.HighContrast() and {1,1,1} or color))
end
function S.ReadableFont(text,font)
  text.fwFont=font
  text:SetFontObject(font)
  -- SetFont overrides survive SetFontObject on the client. Read the shared
  -- source font rather than the label's previously enlarged font.
  local source=_G[font]
  local path,size,flags
  if source and source.GetFont then path,size,flags=source:GetFont()
  else path,size,flags=text:GetFont()end
  if path and size and F.db then
    text:SetFont(path,math.max(size,S.MinimumTextSize()),flags)
  end
end
function S.MinimumTextSize()
  local size=tonumber(F.db and F.db.settings.textSize)
  if size==12 or size==13 or size==14 or size==16 then return size end
  return 0
end
function S.Faction()
  return F.db and F.db.settings.debugAlliance and "Alliance" or UnitFactionGroup("player")
end
function S.ApplyTheme()
  local theme=S.Theme()
  for _,panel in ipairs(S.panels)do
    panel:SetBackdropColor(unpack(theme.panel))
    if rawget(panel,"paper") then panel.paper:SetShown(not S.HighContrast())end
    panel:SetBackdropBorderColor(unpack(S.HighContrast() and {0.8,0.8,0.8,1} or {0.52,0.40,0.22,1}))
  end
  for _,text in ipairs(S.texts)do
    S.ReadableFont(text,text.fwFont)
    S.TextColor(text,text.fwColor)
  end

end
function S.Theme()
  if S.HighContrast() then
    return {bg={0.025,0.025,0.025,1},panel={0.035,0.035,0.035,1},accent={0.22,0.22,0.22,1},fade={0.04,0.04,0.04,1},crest=S.Faction()=="Alliance" and "Interface\\Timer\\Alliance-Logo" or "Interface\\Timer\\Horde-Logo"}
  end
  if S.Faction()=="Alliance" then
    return {bg={0.065,0.071,0.080,1},panel={0.10,0.113,0.124,1},accent={0.26,0.32,0.37,1},fade={0.08,0.092,0.11,1},crest="Interface\\Timer\\Alliance-Logo"}
  end
  return {bg={0.09,0.075,0.055,1},panel={0.15,0.12,0.09,1},accent={0.55,0.20,0.14,1},crest="Interface\\Timer\\Horde-Logo"}
end
function S.Text(parent, text, x, y, width, font, color)
  local t=parent:CreateFontString(nil,"OVERLAY",font or "GameFontHighlight")
  t:SetPoint("TOPLEFT",x,y); t:SetWidth(width); t:SetJustifyH("LEFT"); t:SetText(text or "")
  t.fwFont=font or "GameFontHighlight"
  S.ReadableFont(t,t.fwFont)
  S.TextColor(t,color or {1,1,1})
  S.texts[#S.texts+1]=t
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
    tex:SetShown(not S.HighContrast())
  end
  return p
end
function S.Button(parent, text, x, y, w, fn)
  local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(w,26);b:SetText(text);b:SetScript("OnClick",fn)
  local label=b:GetFontString()
  if label then
    label.fwFont="GameFontNormal";S.ReadableFont(label,label.fwFont);S.TextColor(label,S.gold);S.texts[#S.texts+1]=label
  end
  return b
end
function S.Check(parent,text,x,y,key)
  local b=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate");b:SetPoint("TOPLEFT",x,y);b:SetSize(26,26)
  S.Text(b,text,32,-6,360,"GameFontHighlight")
  b:SetScript("OnShow",function(self)self:SetChecked(F.db.settings[key])end)
  b:SetScript("OnClick",function(self) F.db.settings[key]=not not self:GetChecked();F.ApplySettings() end)
  return b
end