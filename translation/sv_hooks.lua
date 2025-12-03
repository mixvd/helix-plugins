local PLUGIN = PLUGIN

hook.Add("InitializedPlugins", "ixTranslationOverride", function()
    local originalChatSend = ix.chat.Send
    
    ix.chat.Send = function(speaker, chatType, text, bAnonymous, receivers, data)
        if !ix.config.Get("translationEnabled") then
            return originalChatSend(speaker, chatType, text, bAnonymous, receivers, data)
        end
        
        if !PLUGIN:ShouldTranslateChatType(chatType) then
            return originalChatSend(speaker, chatType, text, bAnonymous, receivers, data)
        end
        
        if !IsValid(speaker) then
            return originalChatSend(speaker, chatType, text, bAnonymous, receivers, data)
        end
        
        local class = ix.chat.classes[chatType]
        if !class then
            return originalChatSend(speaker, chatType, text, bAnonymous, receivers, data)
        end
        
        if class.CanSay and class:CanSay(speaker, text, data or {}) == false then
            return
        end
        
        data = data or {}
        
        local calculatedReceivers = receivers
        if !receivers then
            calculatedReceivers = {}
            
            if class.CanHear then
                for _, v in player.Iterator() do
                    if v:GetCharacter() and class:CanHear(speaker, v, data) != false then
                        calculatedReceivers[#calculatedReceivers + 1] = v
                    end
                end
            else
                for _, v in player.Iterator() do
                    if v:GetCharacter() then
                        calculatedReceivers[#calculatedReceivers + 1] = v
                    end
                end
            end
            
            if #calculatedReceivers == 0 then
                return
            end
        end
        
        local rawText = text
        local maxLength = ix.config.Get("chatMax")
        
        text = string.gsub(text, "%s+", " ")
        
        if text:utf8len() > maxLength then
            text = text:utf8sub(0, maxLength)
        end
        
        if ix.config.Get("chatAutoFormat") and hook.Run("CanAutoFormatMessage", speaker, chatType, text) then
            text = ix.chat.Format(text)
        end
        
        text = hook.Run("PlayerMessageSend", speaker, chatType, text, bAnonymous, calculatedReceivers, rawText) or text
        
        local languageGroups = {}
        for _, recipient in ipairs(calculatedReceivers) do
            if IsValid(recipient) then
                local recipientChar = recipient:GetCharacter()
                local recipientLang = recipientChar and recipientChar:GetLanguage() or "en"
                
                if !languageGroups[recipientLang] then
                    languageGroups[recipientLang] = {}
                end
                table.insert(languageGroups[recipientLang], recipient)
            end
        end
        
        local detectedSourceLang = nil
        local pendingDetections = 0
        local completedDetections = 0
        
        for targetLang, _ in pairs(languageGroups) do
            pendingDetections = pendingDetections + 1
        end
        
        if pendingDetections == 1 then
            local onlyLang = next(languageGroups)
            local speakerChar = speaker:GetCharacter()
            local speakerLang = speakerChar and speakerChar:GetLanguage() or "en"
            
            if speakerLang == onlyLang then
                local validPlayers = {}
                for _, ply in ipairs(languageGroups[onlyLang]) do
                    if IsValid(ply) then
                        table.insert(validPlayers, ply)
                    end
                end
                
                if #validPlayers > 0 then
                    net.Start("ixChatMessage")
                        net.WriteEntity(speaker)
                        net.WriteString(chatType)
                        net.WriteString(text)
                        net.WriteBool(bAnonymous or false)
                        net.WriteTable(data)
                    net.Send(validPlayers)
                end
                return text
            end
        end
        
        for targetLang, players in pairs(languageGroups) do
            ix.translation.Translate(text, targetLang, function(translatedText, sourceLang, failed)
                if !detectedSourceLang and sourceLang then
                    detectedSourceLang = sourceLang
                    
                    for checkLang, checkPlayers in pairs(languageGroups) do
                        if checkLang == sourceLang then
                            local validPlayers = {}
                            for _, ply in ipairs(checkPlayers) do
                                if IsValid(ply) then
                                    table.insert(validPlayers, ply)
                                end
                            end
                            
                            if #validPlayers > 0 then
                                net.Start("ixChatMessage")
                                    net.WriteEntity(speaker)
                                    net.WriteString(chatType)
                                    net.WriteString(text)
                                    net.WriteBool(bAnonymous or false)
                                    net.WriteTable(data)
                                net.Send(validPlayers)
                            end
                        end
                    end
                end
                
                if sourceLang == targetLang then
                    return
                end
                
                local validPlayers = {}
                for _, ply in ipairs(players) do
                    if IsValid(ply) then
                        table.insert(validPlayers, ply)
                    end
                end
                
                if #validPlayers == 0 then return end
                
                local upperText = translatedText and string.upper(translatedText) or ""
                local isAPIError = string.find(upperText, "PLEASE SELECT") or
                                   string.find(upperText, "TWO DISTINCT") or
                                   string.find(upperText, "MYMEMORY") or
                                   string.find(upperText, "INVALID LANGUAGE") or
                                   string.find(upperText, "QUERY LENGTH") or
                                   string.find(upperText, "RATE LIMIT")
                
                if isAPIError then
                    translatedText = text
                    failed = true
                end
                
                if failed or translatedText == text then
                    translatedText = text
                end
                
                local finalText = translatedText
                if ix.config.Get("translationShowOriginal") and translatedText != text and !failed then
                    finalText = translatedText .. " [" .. text .. "]"
                end
                
                local translatedData = table.Copy(data)
                translatedData.originalText = text
                translatedData.translated = !failed
                translatedData.sourceLang = sourceLang
                translatedData.targetLang = targetLang
                
                net.Start("ixChatMessage")
                    net.WriteEntity(speaker)
                    net.WriteString(chatType)
                    net.WriteString(finalText)
                    net.WriteBool(bAnonymous or false)
                    net.WriteTable(translatedData)
                net.Send(validPlayers)
            end)
        end
        
        return text
    end
end)

function PLUGIN:OnLanguageChanged(client, character, oldLang, newLang)
    if !IsValid(client) or !character then return end
    
    ix.log.Add(client, "translationLanguageChanged", character:GetName(), self:GetLanguageName(newLang))
end
