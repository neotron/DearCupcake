require "CREDDExchangeLib"

local Cupcake = Apollo.GetPackage("Gemini:Addon-1.1").tPackage:NewAddon("DearCupcake", false, { "GuildContentRoster" }, "Gemini:Hook-1.0" )
local GeminiLogging = Apollo.GetPackage("Gemini:Logging-1.2").tPackage
local GeminiGUI = Apollo.GetPackage("Gemini:GUI-1.0").tPackage
local  log 

function Cupcake:OnInitialize()
   self.db = Apollo.GetPackage("Gemini:DB-1.0").tPackage:New(self, { realm = { notes = {} } })
end

function Cupcake:OnEnable()
   log = GeminiLogging:GetLogger({
                                 level = GeminiLogging.INFO,
                                 pattern = "%d %n %c %l - %m",
                                 appender = "GeminiConsole"
                         })
   self.roster = Apollo.GetAddon("GuildContentRoster")
   self:RawHook(self.roster, "OnGenerateGridTooltip")
   self:Hook(self.roster, "ResetRosterMemberButtons")
end

function Cupcake:OnGenerateGridTooltip(luaCaller, wndHandler, wndControl, eType, iRow, iColumn)
   local grid = luaCaller.wndMain:FindChild("RosterGrid")
   local tooltip = grid:GetCellData(iRow + 1, 8) or ""
   local user = grid:GetCellData(iRow + 1, 1)
   if user then 
      local privateNote = self.db.realm.notes[user.strName]

      if privateNote then
	 tooltip = tooltip .. "\nPrivate Note: "..privateNote
      end
   end
   self.grid = grid
   wndHandler:SetTooltip(tooltip)
end

function Cupcake:UpdateRow(grid, row, tCurr)
   local strTextColor = "UI_TextHoloBodyHighlight"
   if tCurr.fLastOnline ~= 0 then -- offline
      strTextColor = "UI_BtnTextGrayNormal"
   end
   local stdNote = "<T Font=\"CRB_InterfaceSmall\" TextColor=\""..strTextColor.."\">".. FixXMLString(tCurr.strNote) .."</T>"
   if self.db.realm.notes[tCurr.strName] then
      grid:SetCellDoc(row, 8, "<P>"..stdNote.."<T Image=\"HUD_BottomBar:spr_HUD_MenuIcons_Lore\" /> </P>")
   else
      grid:SetCellDoc(row, 8, stdNote)
   end
end

function Cupcake:ResetRosterMemberButtons(luaCaller)
   local grid = luaCaller.wndMain:FindChild("RosterGrid")
   local tSel = grid:GetData()
   local selectedRow 
   for i = 1,grid:GetRowCount() do
      local tCurr = grid:GetCellData(i, 1)
      if tSel and tSel.strName == tCurr.strName then
	 selectedRow = i
      end
      self:UpdateRow(grid, i, tCurr)
   end

   self:OnCloseClick() -- destroy old UI
   if tSel then
      local note = self.db.realm.notes[tSel.strName] 
      self.noteUI = GeminiGUI:Create(Cupcake.tPrivateNoteDef):GetInstance(self, luaCaller.wndMain)
      local editBox = self.noteUI:FindChild("EditBox")
      editBox:SetText(note or "")
      editBox:SetData({ tSel =  tSel, row = selectedRow })
   end
end

function Cupcake:OnUpdateNote()
   if self.noteUI then
      local editBox =  self.noteUI:FindChild("EditBox")
      local data = editBox:GetData()
      if not data or not data.tSel.strName then return end
      local name = data.tSel.strName
      local note = editBox:GetText()
      local needRebuild = false
      if note and note ~= "" then
	 if not self.db.realm.notes[name] then
	    needRebuild = true
	 end
	 self.db.realm.notes[name] = note
      else
	 if self.db.realm.notes[name] then
	    needRebuild = true
	 end
	 self.db.realm.notes[name] = nil
      end
      if needRebuild then
	 local grid = self.roster.wndMain:FindChild("RosterGrid")
	 self:UpdateRow(grid, data.row, data.tSel)
      end
   end
end

function Cupcake:OnCloseClick()
   if self.noteUI then
      self.noteUI:Destroy()
      self.noteUI = nil
   end
end

Cupcake.tPrivateNoteDef = {
   AnchorOffsets = { 5, 25, 220, 280 },
   AnchorPoints = { 1, 0, 1, 0 },
   RelativeToClient = true, 
   Name = "PrivateNote", 
   BGColor = "white",
   NewWindowDepth = true, 
   TextColor = "white", 
   Picture = true, 
   IgnoreMouse = true, 
   NoClip = true, 
   Sprite = "CRB_Basekit:kitBase_HoloBlue_PopoutLarge", 
   Children = {
      {
         AnchorOffsets = { 0, 20, 0, 40 },
         AnchorPoints = "HFILL",
         RelativeToClient = true, 
         Font = "CRB_InterfaceMedium_B", 
         Text = "Private Note", 
         Name = "PrivateNoteTitle", 
         BGColor = "white", 
         TextColor = "UI_WindowTitleYellow", 
         DT_CENTER = true, 
         DT_VCENTER = true, 
      },
      {
         AnchorOffsets = { -35, 15, -7, 44 },
         AnchorPoints = "TOPRIGHT",
         Class = "Button", 
         Base = "BK3:btnHolo_Close", 
         Font = "Thick", 
         ButtonType = "PushButton", 
         DT_VCENTER = true, 
         DT_CENTER = true, 
         Name = "CloseButton", 
         BGColor = "white", 
         TextColor = "white", 
         NormalTextColor = "white", 
         PressedTextColor = "white", 
         FlybyTextColor = "white", 
         PressedFlybyTextColor = "white", 
         DisabledTextColor = "white", 
         Visible = true, 
         Events = {
            ButtonSignal = "OnCloseClick",
         },
      },
      {
         AnchorOffsets = { 36, 184, -18, -6 },
         AnchorPoints = "FILL",
         Class = "Button", 
         Base = "BK3:btnHolo_Blue_Med", 
         Font = "CRB_Button", 
         ButtonType = "PushButton", 
         DT_VCENTER = true, 
         DT_CENTER = true, 
         Name = "UpdateNoteBtn", 
         BGColor = "white", 
         TextColor = "white", 
         TooltipColor = "white", 
         NormalTextColor = "UI_BtnTextBlueNormal", 
         PressedTextColor = "UI_BtnTextBluePressed", 
         FlybyTextColor = "UI_BtnTextBlueFlyby", 
         PressedFlybyTextColor = "UI_BtnTextBluePressedFlyby", 
         DisabledTextColor = "UI_BtnTextBlueDisabled", 
         TooltipFont = "CRB_InterfaceMedium", 
         TooltipId = "Friends_BlockBtnTooltip", 
         IgnoreTooltipDelay = true, 
         TextId = "Friends_UpdateNote", 
         TestAlpha = true, 
         ButtonTextXMargin = 18, 
         DT_WORDBREAK = true, 
         Events = {
            ButtonSignal = "OnUpdateNote",
         },
      },
      {
	 WidgetType = "EditBox", 
         AnchorOffsets = { 36, 48, -18, -76 },
         AnchorPoints = "FILL",
         RelativeToClient = true, 
         BGColor = "UI_WindowBGDefault", 
         TextColor = "UI_WindowTextDefault", 
         Template = "Holo_InputBox", 
         Name = "EditBox", 
         Sprite = "Holo_InputBox", 
         DT_WORDBREAK = true, 
         IgnoreMouse = true,
	 MultiLine = true, 
         Border = true, 
         UseTemplateBG = true, 
      },
   },
}
