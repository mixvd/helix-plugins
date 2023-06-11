local PLUGIN = PLUGIN

local PANEL = {}

local ScrW, ScrH = ScrW(), ScrH()

function PANEL:Init()
    if not LocalPlayer():IsAdmin() then return end

    if IsValid(ix.gui.cinematicSplashTextMenu) then
        ix.gui.cinematicSplashTextMenu:Remove()
    end
    ix.gui.cinematicSplashTextMenu = self

    self.contents = {
        text = "",
        bigText = "",
        duration = 3,
        blackBars = true,
        music = true,
        color = color_white
    }

    local textEntryTall = ScrH*0.045

    self:SetSize(ScrW*0.6, ScrH*0.6)
    self:Center()
    self:MakePopup()
    self:SetTitle("Cinematic Splash Text Menu")

    local textLabel = self:Add("DLabel")
    textLabel:SetText("Splash Text")
    textLabel:SetFont("cinematicSplashFontSmall")
    textLabel:SetTextColor(ix.config.Get("color", Color(75, 119, 190)))
    textLabel:Dock(TOP)
    textLabel:DockMargin( 20, 5, 20, 0 )
    textLabel:SizeToContents()

    local textEntry = self:Add("DTextEntry")
    textEntry:SetFont("cinematicSplashFontSmall")
    textEntry:Dock(TOP)
    textEntry:DockMargin( 20, 5, 20, 0 )
    textEntry:SetUpdateOnType(true)
    textEntry.OnValueChange = function(this, value)
        self.contents.text = value
    end
    textEntry:SetTall(textEntryTall)

    local bigTextLabel = self:Add("DLabel")
    bigTextLabel:SetText("Big Splash Text (Appears under normal text)")
    bigTextLabel:SetFont("cinematicSplashFontSmall")
    bigTextLabel:SetTextColor(ix.config.Get("color", Color(75, 119, 190)))
    bigTextLabel:Dock(TOP)
    bigTextLabel:DockMargin( 20, 5, 20, 0 )
    bigTextLabel:SizeToContents()

    local bigTextEntry = self:Add("DTextEntry")
    bigTextEntry:SetFont("cinematicSplashFontSmall")
    bigTextEntry:Dock(TOP)
    bigTextEntry:DockMargin( 20, 5, 20, 0 )
    bigTextEntry:SetUpdateOnType(true)
    bigTextEntry.OnValueChange = function(this, value)
        self.contents.bigText = value
    end
    bigTextEntry:SetTall(textEntryTall)

    local durationLabel = self:Add("DLabel")
    durationLabel:SetText("Splash Text Duration")
    durationLabel:SetFont("cinematicSplashFontSmall")
    durationLabel:SetTextColor(ix.config.Get("color", Color(75, 119, 190)))
    durationLabel:Dock(TOP)
    durationLabel:DockMargin( 20, 5, 20, 0 )
    durationLabel:SizeToContents()

    local durationSlider = self:Add("DNumSlider")
	durationSlider:Dock(TOP)
	durationSlider:SetMin(1)				 -- Set the minimum number you can slide to
	durationSlider:SetMax(30)				-- Set the maximum number you can slide to
	durationSlider:SetDecimals(0)			 -- Decimal places - zero for whole number
    durationSlider:SetValue(self.contents.duration)

	durationSlider:DockMargin(10, 0, 0, 5)
    durationSlider.OnValueChanged = function(_, val)
        self.contents.duration = math.Round(val)
    end

    local blackBarBool = self:Add("DCheckBoxLabel")
    blackBarBool:SetText("Draw Black Bars")
    blackBarBool:SetFont("cinematicSplashFontSmall")
    blackBarBool:SetValue(self.contents.blackBars)
    blackBarBool.OnChange = function(this, bValue)
        self.contents.blackBars = bValue
    end
    blackBarBool:Dock(TOP)
    blackBarBool:DockMargin( 20, 5, 20, 0 )
    blackBarBool:SizeToContents()

    local musicBool = self:Add("DCheckBoxLabel")
    musicBool:SetText("Play audio")
    musicBool:SetFont("cinematicSplashFontSmall")
    musicBool:SetValue(self.contents.music)
    musicBool.OnChange = function(this, bValue)
        self.contents.music = bValue
    end
    musicBool:Dock(TOP)
    musicBool:DockMargin( 20, 5, 20, 0 )
    musicBool:SizeToContents()

    local Mixer = self:Add("DColorMixer")
    Mixer:Dock(TOP)					-- Make Mixer fill place of Frame
    Mixer:SetPalette(true)  			-- Show/hide the palette 				DEF:true
    Mixer:SetAlphaBar(true) 			-- Show/hide the alpha bar 				DEF:true
    Mixer:SetWangs(true) 				-- Show/hide the R G B A indicators 	DEF:true
    Mixer:SetColor(Color(30,100,160)) 	-- Set the default color
    Mixer:SetTall(textEntryTall*3.5)
    Mixer:DockMargin( 20, 5, 20, 0 )

    local quitButton = self:Add("DButton")
    quitButton:Dock(BOTTOM)
    quitButton:DockMargin( 20, 5, 20, 0 )
    quitButton:SetText("CANCEL")
    quitButton:SetTextColor(Color(255,0,0))
    quitButton:SetFont("cinematicSplashFontSmall")
    quitButton:SetTall(ScrH*0.05)
    quitButton.DoClick = function()
        self:Remove()
    end

    local postButton = self:Add("DButton")
    postButton:Dock(BOTTOM)
    postButton:DockMargin( 20, 5, 20, 0 )
    postButton:SetText("POST")
    postButton:SetTextColor(color_white)
    postButton:SetFont("cinematicSplashFontSmall")
    postButton:SetTall(ScrH*0.05)
    postButton.DoClick = function()
        if not (self.contents and (self.contents.text or self.contents.bigText)) then ix.util.Notify("Something went horribly wrong. Try reloading this panel") return end
        if  self.contents.text == "" and self.contents.bigText == "" then ix.util.Notify("Text is missing. Enter some text to display") return end

        net.Start("triggerCinematicSplashMenu")
            net.WriteString(self.contents.text) -- the normal text
            net.WriteString(self.contents.bigText) -- the big text
            net.WriteUInt(self.contents.duration,6) -- the duration of the splash
            net.WriteBool(self.contents.blackBars) -- whether to draw blackBars
            net.WriteBool(self.contents.music) -- whether to play a sound
            net.WriteColor(self.contents.color)
        net.SendToServer()
        self:Remove()
    end
    self:SizeToContents()

    Mixer.ValueChanged = function(this, col) -- this is here because it needs to reference panels that are defined after mixer
    local newColor = Color(col.r, col.g, col.b)
    self.contents.color = newColor --ValueChanged doesn't include the color metatable, so we just define it here. Also remove any alpha changes
    textLabel:SetTextColor(newColor)
    bigTextLabel:SetTextColor(newColor)
    durationLabel:SetTextColor(newColor)
    postButton:SetTextColor(newColor)
    end
end

vgui.Register("cinematicSplashTextMenu", PANEL, "DFrame")

net.Receive("openCinematicSplashMenu", function()
    vgui.Create("cinematicSplashTextMenu")
end)