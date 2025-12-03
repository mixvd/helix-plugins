local PLUGIN = PLUGIN

ix.translation = ix.translation or {}
ix.translation.cache = ix.translation.cache or {}
ix.translation.cacheOrder = ix.translation.cacheOrder or {}

local function IsCHTTPAvailable()
    if util.IsBinaryModuleInstalled("chttp") then
        if !CHTTP then
            require("chttp")
        end
        return CHTTP != nil
    end
    return false
end

local function URLEncode(str)
    if str then
        str = string.gsub(str, "\n", "\r\n")
        str = string.gsub(str, "([^%w %-%_%.%~])", function(c)
            return string.format("%%%02X", string.byte(c))
        end)
        str = string.gsub(str, " ", "+")
    end
    return str
end

local function GetCacheKey(text, targetLang)
    return string.format("auto:%s:%s", targetLang, text)
end

local function ProcessVocoder(text, targetLang, callback)
    local vocoderPattern = "<::%s*(.-)%s*::>"
    local innerText = string.match(text, vocoderPattern)
    
    if !innerText then
        callback(text)
        return
    end
    
    local cached, cachedDetectedLang = ix.translation.GetFromCache(innerText, targetLang)
    if cached then
        local result = string.gsub(text, vocoderPattern, "<:: " .. cached .. " ::>")
        callback(result)
        return
    end
    
    local timeout = ix.config.Get("translationTimeout", 15)
    local email = ix.config.Get("translationEmail", "")
    
    local url = "https://api.mymemory.translated.net/get?q=" .. URLEncode(innerText) .. "&langpair=autodetect|" .. targetLang
    
    if email != "" then
        url = url .. "&de=" .. URLEncode(email)
    end
    
    if !IsCHTTPAvailable() and !HTTP then
        callback(text)
        return
    end
    
    local requestData = {
        url = url,
        method = "GET",
        timeout = timeout,
        success = function(code, body, headers)
            if code == 200 then
                local response = util.JSONToTable(body)
                
                if response and response.responseData then
                    local translatedInner = response.responseData.translatedText
                    local detectedLang = response.responseData.detectedLanguage or "en"
                    
                    local upperTranslation = translatedInner and string.upper(translatedInner) or ""
                    local isAPIError = string.find(upperTranslation, "PLEASE SELECT") or
                                       string.find(upperTranslation, "MYMEMORY") or
                                       string.find(upperTranslation, "INVALID")
                    
                    if isAPIError or translatedInner == innerText or translatedInner == "" then
                        if detectedLang != targetLang then
                            local retryUrl = "https://api.mymemory.translated.net/get?q=" .. URLEncode(innerText) .. "&langpair=" .. detectedLang .. "|" .. targetLang
                            if email != "" then
                                retryUrl = retryUrl .. "&de=" .. URLEncode(email)
                            end
                            
                            local retryRequest = {
                                url = retryUrl,
                                method = "GET",
                                timeout = timeout,
                                success = function(code2, body2, headers2)
                                    if code2 == 200 then
                                        local response2 = util.JSONToTable(body2)
                                        if response2 and response2.responseData then
                                            translatedInner = response2.responseData.translatedText
                                        end
                                    end
                                    local result = string.gsub(text, vocoderPattern, "<:: " .. (translatedInner or innerText) .. " ::>")
                                    if translatedInner and translatedInner != innerText then
                                        ix.translation.AddToCache(innerText, targetLang, translatedInner, detectedLang)
                                    end
                                    callback(result)
                                end,
                                failed = function()
                                    callback(text)
                                end
                            }
                            
                            if CHTTP then
                                if !CHTTP(retryRequest) then
                                    callback(text)
                                end
                            else
                                HTTP(retryRequest)
                            end
                            return
                        end
                    end
                    
                    local result = string.gsub(text, vocoderPattern, "<:: " .. (translatedInner or innerText) .. " ::>")
                    if translatedInner and translatedInner != innerText and !isAPIError then
                        ix.translation.AddToCache(innerText, targetLang, translatedInner, detectedLang)
                    end
                    callback(result)
                    return
                end
            end
            
            callback(text)
        end,
        failed = function(reason)
            callback(text)
        end
    }
    
    if CHTTP then
        if !CHTTP(requestData) then
            callback(text)
        end
    else
        HTTP(requestData)
    end
end

function ix.translation.AddToCache(text, targetLang, translatedText, detectedLang)
    if !ix.config.Get("translationCacheEnabled") then return end
    
    local key = GetCacheKey(text, targetLang)
    local maxSize = ix.config.Get("translationCacheSize", 500)
    
    if #ix.translation.cacheOrder >= maxSize then
        local oldestKey = table.remove(ix.translation.cacheOrder, 1)
        ix.translation.cache[oldestKey] = nil
    end
    
    ix.translation.cache[key] = {
        text = translatedText,
        detectedLang = detectedLang,
        timestamp = os.time()
    }
    table.insert(ix.translation.cacheOrder, key)
end

function ix.translation.GetFromCache(text, targetLang)
    if !ix.config.Get("translationCacheEnabled") then return nil end
    
    local key = GetCacheKey(text, targetLang)
    local cached = ix.translation.cache[key]
    
    if cached then
        return cached.text, cached.detectedLang
    end
    
    return nil, nil
end

ix.translation.languageCorrections = {
    ["ca"] = "fr",
    ["gl"] = "pt",
    ["oc"] = "fr",
    ["ro"] = "fr",
}

function ix.translation.TranslateWithSource(text, sourceLang, targetLang, callback)
    if sourceLang == targetLang then
        callback(text, sourceLang, false)
        return
    end
    
    local timeout = ix.config.Get("translationTimeout", 15)
    local email = ix.config.Get("translationEmail", "")
    
    local url = "https://api.mymemory.translated.net/get?q=" .. URLEncode(text) .. "&langpair=" .. sourceLang .. "|" .. targetLang
    
    if email != "" then
        url = url .. "&de=" .. URLEncode(email)
    end
    
    if !IsCHTTPAvailable() and !HTTP then
        callback(text, sourceLang, true)
        return
    end
    
    local requestData = {
        url = url,
        method = "GET",
        timeout = timeout,
        success = function(code, body, headers)
            if code == 200 then
                local response = util.JSONToTable(body)
                
                if response and response.responseData then
                    local translatedText = response.responseData.translatedText
                    
                    local upperTranslation = translatedText and string.upper(translatedText) or ""
                    if string.find(upperTranslation, "PLEASE SELECT") or 
                       string.find(upperTranslation, "MYMEMORY") or
                       string.find(upperTranslation, "INVALID") then
                        callback(text, sourceLang, true)
                        return
                    end
                    
                    if translatedText and translatedText != "" and translatedText != text then
                        ix.translation.AddToCache(text, targetLang, translatedText, sourceLang)
                        callback(translatedText, sourceLang, false)
                    else
                        callback(text, sourceLang, false)
                    end
                    return
                end
            end
            
            callback(text, sourceLang, true)
        end,
        failed = function(reason)
            callback(text, sourceLang, true)
        end
    }
    
    if CHTTP then
        if !CHTTP(requestData) then
            callback(text, sourceLang, true)
        end
    else
        HTTP(requestData)
    end
end

function ix.translation.Translate(text, targetLang, callback)
    local hasVocoder = string.find(text, "<::") and string.find(text, "::>")
    
    if hasVocoder then
        ProcessVocoder(text, targetLang, function(translatedText)
            callback(translatedText, "en", false)
        end)
        return
    end
    
    local cached, cachedDetectedLang = ix.translation.GetFromCache(text, targetLang)
    if cached then
        callback(cached, cachedDetectedLang, false)
        return
    end
    
    local timeout = ix.config.Get("translationTimeout", 15)
    local email = ix.config.Get("translationEmail", "")
    
    local url = "https://api.mymemory.translated.net/get?q=" .. URLEncode(text) .. "&langpair=autodetect|" .. targetLang
    
    if email != "" then
        url = url .. "&de=" .. URLEncode(email)
    end
    
    if !IsCHTTPAvailable() and !HTTP then
        callback(text, "en", true)
        return
    end
    
    local requestData = {
        url = url,
        method = "GET",
        timeout = timeout,
        success = function(code, body, headers)
            if code == 200 then
                local response = util.JSONToTable(body)
                
                if response and response.responseData then
                    local translatedText = response.responseData.translatedText
                    local detectedLang = "en"
                    
                    if response.responseData.detectedLanguage then
                        detectedLang = response.responseData.detectedLanguage
                    end
                    
                    local upperTranslation = translatedText and string.upper(translatedText) or ""
                    local isAPIError = string.find(upperTranslation, "PLEASE SELECT") or
                                       string.find(upperTranslation, "TWO DISTINCT") or
                                       string.find(upperTranslation, "MYMEMORY") or
                                       string.find(upperTranslation, "INVALID LANGUAGE") or
                                       string.find(upperTranslation, "QUERY LENGTH LIMIT") or
                                       string.find(upperTranslation, "NO PUBKEY") or
                                       string.find(upperTranslation, "RATE LIMIT")
                    
                    local correctedLang = ix.translation.languageCorrections[detectedLang]
                    if correctedLang then
                        detectedLang = correctedLang
                    end
                    
                    if !isAPIError and (translatedText == text or translatedText == "") and detectedLang != targetLang then
                        ix.translation.TranslateWithSource(text, detectedLang, targetLang, callback)
                        return
                    end
                    
                    if isAPIError then
                        if detectedLang != targetLang then
                            ix.translation.TranslateWithSource(text, detectedLang, targetLang, callback)
                            return
                        else
                            callback(text, detectedLang, false)
                            return
                        end
                    end
                    
                    if detectedLang == targetLang then
                        callback(text, detectedLang, false)
                        return
                    end
                    
                    if translatedText and translatedText != "" and translatedText != text then
                        ix.translation.AddToCache(text, targetLang, translatedText, detectedLang)
                        callback(translatedText, detectedLang, false)
                    else
                        if detectedLang != targetLang then
                            ix.translation.TranslateWithSource(text, detectedLang, targetLang, callback)
                        else
                            callback(text, detectedLang, false)
                        end
                    end
                    return
                    
                elseif response and response.responseStatus == 403 then
                    timer.Simple(2, function()
                        ix.translation.Translate(text, targetLang, callback)
                    end)
                    return
                else
                    callback(text, "en", true)
                    return
                end
            end
            
            callback(text, "en", true)
        end,
        failed = function(reason)
            callback(text, "en", true)
        end
    }
    
    if CHTTP then
        if !CHTTP(requestData) then
            callback(text, "en", true)
        end
    else
        HTTP(requestData)
    end
end

ix.log.AddType("translationLanguageChanged", function(client, characterName, newLang)
    return string.format("%s changed their language to %s.", characterName, newLang)
end)

function PLUGIN:OnCharacterCreated(client, character)
    character:SetLanguage("en")
end

function PLUGIN:PlayerLoadedCharacter(client, character)
    if !character then return end
    
    if ix.config.Get("translationMenuOnFirstSpawn") then
        local hasSetLanguage = character:GetData("hasSetLanguage", false)
        
        if !hasSetLanguage then
            timer.Simple(2, function()
                if IsValid(client) then
                    net.Start("ixTranslationOpenMenu")
                    net.WriteBool(true)
                    net.Send(client)
                end
            end)
        end
    end
end
