local PLUGIN = PLUGIN

local colors = {
    background = Color(5, 12, 20, 245),
    backgroundAlt = Color(10, 20, 35, 250),
    primary = Color(45, 140, 200),
    primaryDark = Color(30, 100, 160),
    primaryLight = Color(65, 170, 230),
    accent = Color(0, 220, 180),
    text = Color(200, 215, 225),
    textDim = Color(120, 140, 160),
    textBright = Color(255, 255, 255),
    border = Color(45, 70, 100, 200),
    selected = Color(45, 140, 200, 100),
    hover = Color(35, 90, 130, 150),
    success = Color(50, 200, 120),
    scanline = Color(0, 0, 0, 15)
}

local PANEL = {}

function PANEL:Init()
    self.bFirstTime = false
    self.selectedLanguage = nil
    self.languageButtons = {}
    self.animAlpha = 0
    self.scanlineOffset = 0
    
    PLUGIN.menu = self
    
    self:SetSize(520, 640)
    self:Center()
    self:MakePopup()
    self:SetTitle("")
    self:ShowCloseButton(false)
    self:DockPadding(0, 0, 0, 0)
    
    self:SetAlpha(0)
    self:AlphaTo(255, 0.3, 0)
    
    self.header = vgui.Create("DPanel", self)
    self.header:Dock(TOP)
    self.header:SetTall(70)
    self.header.Paint = function(pnl, w, h)
        draw.RoundedBoxEx(8, 0, 0, w, h, colors.backgroundAlt, true, true, false, false)
        
        draw.SimpleText(L("translationMenuTitle"), "ixMediumFont", w / 2, 25, colors.primaryLight, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        local subtitle = self.bFirstTime and L("translationMenuSubtitleFirst") or L("translationMenuSubtitle")
        draw.SimpleText(subtitle, "ixSmallFont", w / 2, 48, colors.textDim, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        
        surface.SetDrawColor(colors.primary)
        surface.DrawRect(20, h - 2, w - 40, 2)
    end
    
    self.closeBtn = vgui.Create("DButton", self.header)
    self.closeBtn:SetSize(24, 24)
    self.closeBtn:SetPos(self:GetWide() - 32, 8)
    self.closeBtn:SetText("")
    self.closeBtn.hovered = false
    self.closeBtn.Paint = function(btn, w, h)
        local bgColor = btn.hovered and Color(180, 50, 50) or Color(40, 50, 60)
        
        draw.RoundedBox(4, 0, 0, w, h, bgColor)
        
        if btn.hovered then
            surface.SetDrawColor(Color(255, 80, 80))
            surface.DrawOutlinedRect(0, 0, w, h, 2)
        else
            surface.SetDrawColor(colors.border)
            surface.DrawOutlinedRect(0, 0, w, h, 1)
        end
        
        local xColor = btn.hovered and colors.textBright or colors.text
        local cx, cy = w / 2, h / 2
        local size = 5
        
        surface.SetDrawColor(xColor)
        for offset = 0, 1 do
            surface.DrawLine(cx - size + offset, cy - size, cx + size + offset, cy + size)
            surface.DrawLine(cx + size - offset, cy - size, cx - size - offset, cy + size)
        end
    end
    self.closeBtn.OnCursorEntered = function(btn)
        btn.hovered = true
    end
    self.closeBtn.OnCursorExited = function(btn)
        btn.hovered = false
    end
    self.closeBtn.DoClick = function()
        surface.PlaySound("buttons/button18.wav")
        self:Close()
    end
    
    self.scroll = vgui.Create("DScrollPanel", self)
    self.scroll:Dock(FILL)
    self.scroll:DockMargin(15, 15, 15, 15)
    
    local scrollbar = self.scroll:GetVBar()
    scrollbar:SetWide(6)
    scrollbar.Paint = function(pnl, w, h)
        draw.RoundedBox(3, 0, 0, w, h, colors.backgroundAlt)
    end
    scrollbar.btnUp.Paint = function() end
    scrollbar.btnDown.Paint = function() end
    scrollbar.btnGrip.Paint = function(pnl, w, h)
        draw.RoundedBox(3, 0, 0, w, h, colors.primary)
    end
    
    self.languageList = vgui.Create("DPanel", self.scroll)
    self.languageList:Dock(TOP)
    self.languageList:DockMargin(0, 0, 0, 10)
    self.languageList.Paint = function() end
    
    self.footer = vgui.Create("DPanel", self)
    self.footer:Dock(BOTTOM)
    self.footer:SetTall(70)
    self.footer.Paint = function(pnl, w, h)
        surface.SetDrawColor(colors.border)
        surface.DrawRect(20, 0, w - 40, 1)
    end
    
    self.confirmBtn = vgui.Create("DButton", self.footer)
    self.confirmBtn:SetSize(200, 45)
    self.confirmBtn:SetText("")
    self.confirmBtn:SetPos(self:GetWide() / 2 - 210, 12)
    self.confirmBtn.hovered = false
    self.confirmBtn.Paint = function(btn, w, h)
        local bgColor = btn.hovered and colors.success or colors.primary
        if !self.selectedLanguage then
            bgColor = colors.textDim
        end
        
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
        draw.SimpleText(L("translationConfirm"), "ixMediumFont", w / 2, h / 2, colors.textBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.confirmBtn.OnCursorEntered = function(btn)
        btn.hovered = true
    end
    self.confirmBtn.OnCursorExited = function(btn)
        btn.hovered = false
    end
    self.confirmBtn.DoClick = function()
        if self.selectedLanguage then
            surface.PlaySound("buttons/button14.wav")
            ix.translation.SetLanguage(self.selectedLanguage)
        end
    end
    
    self.cancelBtn = vgui.Create("DButton", self.footer)
    self.cancelBtn:SetSize(200, 45)
    self.cancelBtn:SetText("")
    self.cancelBtn:SetPos(self:GetWide() / 2 + 10, 12)
    self.cancelBtn.hovered = false
    self.cancelBtn.Paint = function(btn, w, h)
        local bgColor = btn.hovered and colors.primaryDark or colors.backgroundAlt
        
        draw.RoundedBox(6, 0, 0, w, h, bgColor)
        surface.SetDrawColor(colors.border)
        surface.DrawOutlinedRect(0, 0, w, h, 1)
        draw.SimpleText(L("translationCancel"), "ixMediumFont", w / 2, h / 2, colors.text, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    self.cancelBtn.OnCursorEntered = function(btn)
        btn.hovered = true
    end
    self.cancelBtn.OnCursorExited = function(btn)
        btn.hovered = false
    end
    self.cancelBtn.DoClick = function()
        surface.PlaySound("buttons/button18.wav")
        self:Close()
    end
    
    timer.Create("ixTranslationScanline", 0.05, 0, function()
        if IsValid(self) then
            self.scanlineOffset = (self.scanlineOffset + 2) % 4
        else
            timer.Remove("ixTranslationScanline")
        end
    end)
end

function PANEL:SetFirstTime(bFirst)
    self.bFirstTime = bFirst
    
    if bFirst then
        self.cancelBtn:SetVisible(false)
        self.confirmBtn:SetPos(self:GetWide() / 2 - 100, 12)
    end
end

function PANEL:Populate()
    for _, btn in pairs(self.languageButtons) do
        if IsValid(btn) then
            btn:Remove()
        end
    end
    self.languageButtons = {}
    
    local character = LocalPlayer():GetCharacter()
    local currentLang = character and character:GetLanguage() or "en"
    self.selectedLanguage = currentLang
    
    local sortedLangs = {}
    for code, name in pairs(PLUGIN.languages) do
        table.insert(sortedLangs, {code = code, name = name})
    end
    table.sort(sortedLangs, function(a, b) return a.name < b.name end)
    
    local columns = 2
    local buttonWidth = 230
    local buttonHeight = 50
    local spacing = 10
    local row = 0
    local col = 0
    
    for i, lang in ipairs(sortedLangs) do
        local btn = vgui.Create("DButton", self.languageList)
        btn:SetSize(buttonWidth, buttonHeight)
        btn:SetPos(col * (buttonWidth + spacing), row * (buttonHeight + spacing))
        btn:SetText("")
        btn.langCode = lang.code
        btn.langName = lang.name
        btn.selected = (lang.code == currentLang)
        btn.hovered = false
        
        btn.Paint = function(b, w, h)
            local bgColor = colors.backgroundAlt
            
            if b.selected then
                bgColor = colors.selected
            elseif b.hovered then
                bgColor = colors.hover
            end
            
            draw.RoundedBox(6, 0, 0, w, h, bgColor)
            
            if b.selected then
                surface.SetDrawColor(colors.accent)
                surface.DrawOutlinedRect(0, 0, w, h, 2)
            else
                surface.SetDrawColor(colors.border)
                surface.DrawOutlinedRect(0, 0, w, h, 1)
            end
            
            local badgeWidth = 35
            draw.RoundedBox(4, 8, (h - 24) / 2, badgeWidth, 24, b.selected and colors.accent or colors.primaryDark)
            draw.SimpleText(string.upper(b.langCode), "ixSmallFont", 8 + badgeWidth / 2, h / 2, colors.textBright, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            
            local textColor = b.selected and colors.textBright or colors.text
            draw.SimpleText(b.langName, "ixMediumFont", 55, h / 2, textColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            
            if b.selected then
                draw.SimpleText("✓", "ixMediumFont", w - 20, h / 2, colors.accent, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        end
        
        btn.OnCursorEntered = function(b)
            b.hovered = true
        end
        
        btn.OnCursorExited = function(b)
            b.hovered = false
        end
        
        btn.DoClick = function(b)
            surface.PlaySound("buttons/button15.wav")
            
            for _, otherBtn in pairs(self.languageButtons) do
                if IsValid(otherBtn) then
                    otherBtn.selected = false
                end
            end
            
            b.selected = true
            self.selectedLanguage = b.langCode
        end
        
        self.languageButtons[lang.code] = btn
        
        col = col + 1
        if col >= columns then
            col = 0
            row = row + 1
        end
    end
    
    local totalRows = math.ceil(#sortedLangs / columns)
    self.languageList:SetTall(totalRows * (buttonHeight + spacing))
end

function PANEL:Paint(w, h)
    draw.RoundedBox(8, 0, 0, w, h, colors.background)
    
    surface.SetDrawColor(0, 10, 20, 100)
    surface.DrawRect(0, 0, w, h / 2)
    
    surface.SetDrawColor(colors.primary.r, colors.primary.g, colors.primary.b, 100)
    surface.DrawOutlinedRect(0, 0, w, h, 1)
    surface.DrawOutlinedRect(1, 1, w - 2, h - 2, 1)
    
    surface.SetDrawColor(colors.scanline)
    for i = self.scanlineOffset, h, 4 do
        surface.DrawRect(0, i, w, 1)
    end
end

function PANEL:PaintOver(w, h)
    local cornerSize = 20
    surface.SetDrawColor(colors.accent)
    
    surface.DrawRect(0, 0, cornerSize, 2)
    surface.DrawRect(0, 0, 2, cornerSize)
    
    surface.DrawRect(w - cornerSize, 0, cornerSize, 2)
    surface.DrawRect(w - 2, 0, 2, cornerSize)
    
    surface.DrawRect(0, h - 2, cornerSize, 2)
    surface.DrawRect(0, h - cornerSize, 2, cornerSize)
    
    surface.DrawRect(w - cornerSize, h - 2, cornerSize, 2)
    surface.DrawRect(w - 2, h - cornerSize, 2, cornerSize)
end

function PANEL:Close()
    if self.OnClose then
        self.OnClose()
    end
    
    timer.Remove("ixTranslationScanline")
    
    self:AlphaTo(0, 0.2, 0, function()
        if IsValid(self) then
            self:Remove()
        end
    end)
end

vgui.Register("ixTranslationMenu", PANEL, "DFrame")
