local PLUGIN = PLUGIN

net.Receive("ixTranslationOpenMenu", function()
    local bFirstTime = net.ReadBool()
    ix.translation.OpenMenu(bFirstTime)
end)

net.Receive("ixTranslatedChatMessage", function()
    local speaker = net.ReadEntity()
    local chatType = net.ReadString()
    local text = net.ReadString()
    local anonymous = net.ReadBool()
    local data = net.ReadTable()
    
    if IsValid(speaker) or chatType then
        local info = {
            chatType = chatType,
            text = text,
            anonymous = anonymous,
            data = data
        }
        
        hook.Run("MessageReceived", speaker, info)
        ix.chat.Send(speaker, info.chatType or chatType, info.text or text, info.anonymous or anonymous, info.data)
    end
end)

net.Receive("ixTranslationLanguageUpdated", function()
    local languageCode = net.ReadString()
    local languageName = net.ReadString()
    
    ix.translation.currentLanguage = languageCode
    
    if IsValid(PLUGIN.menu) then
        PLUGIN.menu:Remove()
        ix.translation.menuOpen = false
    end
end)

net.Receive("ixTranslationSendLanguages", function()
    local languages = net.ReadTable()
    
    if languages and table.Count(languages) > 0 then
        PLUGIN.languages = languages
    end
    
    if IsValid(PLUGIN.menu) and PLUGIN.menu.Populate then
        PLUGIN.menu:Populate()
    end
end)
