local PLUGIN = PLUGIN

ix.translation = ix.translation or {}
ix.translation.currentLanguage = ix.translation.currentLanguage or "en"
ix.translation.menuOpen = false

function ix.translation.SetLanguage(languageCode)
    net.Start("ixTranslationSetLanguage")
    net.WriteString(languageCode)
    net.SendToServer()
end

function ix.translation.RequestLanguages()
    net.Start("ixTranslationGetLanguages")
    net.SendToServer()
end

function ix.translation.GetMyLanguage()
    local character = LocalPlayer():GetCharacter()
    if character then
        return character:GetLanguage() or "en"
    end
    return "en"
end

function ix.translation.IsMenuOpen()
    return ix.translation.menuOpen
end

function ix.translation.OpenMenu(bFirstTime)
    if ix.translation.menuOpen then return end
    
    ix.translation.menuOpen = true
    
    local menu = vgui.Create("ixTranslationMenu")
    menu:SetFirstTime(bFirstTime or false)
    menu:Populate()
    
    menu.OnClose = function()
        ix.translation.menuOpen = false
    end
end

function ix.translation.CloseMenu()
    if IsValid(PLUGIN.menu) then
        PLUGIN.menu:Remove()
    end
    ix.translation.menuOpen = false
end

function PLUGIN:ScreenResolutionChanged()
    if IsValid(PLUGIN.menu) then
        PLUGIN.menu:Remove()
        ix.translation.menuOpen = false
    end
end
