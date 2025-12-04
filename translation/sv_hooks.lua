local PLUGIN = PLUGIN

local function SendChatToPlayers(speaker, chatType, text, bAnonymous, data, players)
    if #players == 0 then return end
    
    net.Start("ixChatMessage")
        net.WriteEntity(speaker)
        net.WriteString(chatType)
        net.WriteString(text)
        net.WriteBool(bAnonymous or false)
        net.WriteTable(data)
    net.Send(players)
end

local function FilterAPIError(translatedText)
    if !translatedText then return true end
    
    local upperText = string.upper(translatedText)
    return string.find(upperText, "PLEASE SELECT") or
           string.find(upperText, "TWO DISTINCT") or
           string.find(upperText, "MYMEMORY") or
           string.find(upperText, "INVALID LANGUAGE") or
           string.find(upperText, "QUERY LENGTH") or
           string.find(upperText, "RATE LIMIT")
end

local function GetValidPlayers(players)
    local valid = {}
    for _, ply in ipairs(players) do
        if IsValid(ply) then
            valid[#valid + 1] = ply
        end
    end
    return valid
end

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
                languageGroups[recipientLang][#languageGroups[recipientLang] + 1] = recipient
            end
        end
        
        local targetLangs = {}
        for lang, _ in pairs(languageGroups) do
            targetLangs[#targetLangs + 1] = lang
        end
        
        if #targetLangs == 1 then
            local targetLang = targetLangs[1]
            local players = GetValidPlayers(languageGroups[targetLang])
            
            if #players == 0 then return text end
            
            ix.translation.Translate(text, targetLang, function(translatedText, sourceLang, failed)
                local finalText = translatedText
                
                if FilterAPIError(translatedText) or failed then
                    finalText = text
                    failed = true
                end
                
                if ix.config.Get("translationShowOriginal") and finalText != text and !failed then
                    finalText = finalText .. " [" .. text .. "]"
                end
                
                local translatedData = table.Copy(data)
                translatedData.originalText = text
                translatedData.translated = !failed and finalText != text
                translatedData.sourceLang = sourceLang
                translatedData.targetLang = targetLang
                
                SendChatToPlayers(speaker, chatType, finalText, bAnonymous, translatedData, players)
            end)
            
            return text
        end
        
        local firstLang = targetLangs[1]
        
        ix.translation.Translate(text, firstLang, function(firstTranslated, sourceLang, firstFailed)
            local detectedSource = sourceLang or "en"
            
            for _, targetLang in ipairs(targetLangs) do
                local players = GetValidPlayers(languageGroups[targetLang])
                if #players == 0 then continue end
                
                if targetLang == detectedSource then
                    SendChatToPlayers(speaker, chatType, text, bAnonymous, data, players)
                    continue
                end
                
                if targetLang == firstLang then
                    local finalText = firstTranslated
                    
                    if FilterAPIError(firstTranslated) or firstFailed then
                        finalText = text
                        firstFailed = true
                    end
                    
                    if ix.config.Get("translationShowOriginal") and finalText != text and !firstFailed then
                        finalText = finalText .. " [" .. text .. "]"
                    end
                    
                    local translatedData = table.Copy(data)
                    translatedData.originalText = text
                    translatedData.translated = !firstFailed and finalText != text
                    translatedData.sourceLang = detectedSource
                    translatedData.targetLang = targetLang
                    
                    SendChatToPlayers(speaker, chatType, finalText, bAnonymous, translatedData, players)
                    continue
                end
                
                ix.translation.TranslateWithSource(text, detectedSource, targetLang, function(translatedText, srcLang, failed)
                    local finalText = translatedText
                    
                    if FilterAPIError(translatedText) or failed then
                        finalText = text
                        failed = true
                    end
                    
                    if ix.config.Get("translationShowOriginal") and finalText != text and !failed then
                        finalText = finalText .. " [" .. text .. "]"
                    end
                    
                    local translatedData = table.Copy(data)
                    translatedData.originalText = text
                    translatedData.translated = !failed and finalText != text
                    translatedData.sourceLang = detectedSource
                    translatedData.targetLang = targetLang
                    
                    SendChatToPlayers(speaker, chatType, finalText, bAnonymous, translatedData, players)
                end)
            end
        end)
        
        return text
    end
end)

function PLUGIN:OnLanguageChanged(client, character, oldLang, newLang)
    if !IsValid(client) or !character then return end
    
    ix.log.Add(client, "translationLanguageChanged", character:GetName(), self:GetLanguageName(newLang))
end
