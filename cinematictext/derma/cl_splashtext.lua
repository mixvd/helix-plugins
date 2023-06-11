local PLUGIN = PLUGIN

local PANEL = {}
local ScrW, ScrH = ScrW(), ScrH()
local music

local contents = {
    text = "",
    bigText = "",
    color = color_white,
    duration = 6,
    music = true
}

function PANEL:Init()
    if ix.gui.cinematicSplashText then
        ix.gui.cinematicSplashText:Remove()
    end

    ix.gui.cinematicSplashText = self

    self:SetSize(ScrW, ScrH)
    self.barSize  = ScrH*(ix.config.Get("cinematicBarSize", 0.18))
end

function PANEL:Paint()
end

function PANEL:DrawBlackBars()
    self.topBar = self:Add("DPanel")
    self.topBar:SetSize(ScrW, self.barSize + 10) -- +10 in to make sure it covers the top
    self.topBar:SetPos(0, -self.barSize) -- set it to be outside of the screen
    self.topBar.Paint = function(this, w, h)
        surface.SetDrawColor(0,0,0, 255)
        surface.DrawRect(0, 0, w, h)
    end

    self.bottomBar = self:Add("DPanel")
    self.bottomBar:SetSize(ScrW, self.barSize + 10)  -- +10 in to make sure it covers the bottom
    self.bottomBar:SetPos(0, ScrH) -- set it to be outside of the screen
    self.bottomBar.Paint = function(this, w, h)
        surface.SetDrawColor(0,0,0, 255)
        surface.DrawRect(0, 0, w, h)
    end
end

function PANEL:TriggerBlackBars()
    if not (IsValid(self.topBar) and IsValid(self.bottomBar)) then return end -- dont do anything if the bars dont exist

    self.topBar:MoveTo(0, 0, 2, 0, 0.5)
    self.bottomBar:MoveTo(0, ScrH - self.barSize, 2, 0, 0.5, function() self:TriggerText() end)
end

function PANEL:TriggerText()
    local textPanel = self:Add("DPanel")
    textPanel.Paint = function() end
    local panelWide, panelTall = 300, 300
    textPanel:SetSize(panelWide, panelTall)
    if contents.text and contents.text ~= "" then
        textPanel.text = textPanel:Add("DLabel")
        textPanel.text:SetFont("cinematicSplashFont")
        textPanel.text:SetTextColor(contents.color or color_white)
        textPanel.text:SetText(contents.text)
        textPanel.text:SetAutoStretchVertical(true)
        textPanel.text:Dock(TOP)
        textPanel.text:SetAlpha(0)
        textPanel.text:AlphaTo(255, 2, 0, function()
            if not contents.bigText then self:TriggerCountdown() end
        end)

        surface.SetFont("cinematicSplashFont")
        textPanel.text.textWide, textPanel.text.textTall = surface.GetTextSize(contents.text)
        panelWide = panelWide > textPanel.text.textWide and panelWide or textPanel.text.textWide
        panelTall = panelTall + textPanel.text.textTall
        textPanel:SetSize(panelWide, panelTall)
    end

    if contents.bigText and contents.bigText ~= "" then
        textPanel.bigText = textPanel:Add("DLabel")
        textPanel.bigText:SetFont("cinematicSplashFontBig")
        textPanel.bigText:SetTextColor(contents.color or color_white)
        textPanel.bigText:SetText(contents.bigText)
        textPanel.bigText:SetAutoStretchVertical(true)
        textPanel.bigText:Dock(TOP)
        textPanel.bigText:SetAlpha(0)
        textPanel.bigText:AlphaTo(255, 2, 1, function()
            self:TriggerCountdown()
        end)

        surface.SetFont("cinematicSplashFontBig")
        textPanel.bigText.textWide, textPanel.bigText.textTall = surface.GetTextSize(contents.bigText)
        panelWide = panelWide > textPanel.bigText.textWide and panelWide or textPanel.bigText.textWide
        panelTall = panelTall + textPanel.bigText.textTall
        textPanel:SetSize(panelWide, panelTall)
    end

    if textPanel.text then textPanel.text:DockMargin((panelWide/2) - (textPanel.text.textWide/2), 0, 0, 20) end
    if textPanel.bigText then textPanel.bigText:DockMargin((panelWide/2) - (textPanel.bigText.textWide/2), 0, 0, 20) end
    textPanel:InvalidateLayout(true)

    textPanel:SetPos(ScrW - textPanel:GetWide() - ScrW*0.05, ScrH*0.58)

    if contents.music then
        music = CreateSound(LocalPlayer(), ix.config.Get("cinematicTextMusic","music/stingers/industrial_suspense2.wav"))
        music:PlayEx(0, 100)
        music:ChangeVolume(1, 2)

    end
end

function PANEL:TriggerCountdown()
    self:AlphaTo(0, 4, contents.duration, function()
        self:Remove()
    end)
    timer.Simple(contents.duration, function()
        if music then music:FadeOut(4) end
    end)
end

vgui.Register("cinematicSplashText", PANEL, "DPanel")

net.Receive("triggerCinematicSplashMenu", function()
    contents.text = net.ReadString()
    contents.bigText = net.ReadString()
    contents.duration = net.ReadUInt(6)
    local blackbars = net.ReadBool()
    contents.music = net.ReadBool()
    contents.color = net.ReadColor()

    if contents.text == "" then contents.text = nil end
    if contents.bigText == "" then contents.bigText = nil end

    local splashText = vgui.Create("cinematicSplashText")
    if blackbars then
        splashText:DrawBlackBars()
        splashText:TriggerBlackBars()
    else
        splashText:TriggerText()
    end
end)