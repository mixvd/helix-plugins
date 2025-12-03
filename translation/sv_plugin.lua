local PLUGIN = PLUGIN

ix.translation = ix.translation or {}
ix.translation.cache = ix.translation.cache or {}
ix.translation.cacheOrder = ix.translation.cacheOrder or {}

local chttp_loaded = false

local function LoadCHTTP()
    if chttp_loaded then return true end
    
    local success = pcall(require, "chttp")
    if success and CHTTP != nil then
        chttp_loaded = true
        return true
    end
    return false
end

local function GetHTTPFunction()
    LoadCHTTP()
    return chttp_loaded and CHTTP or HTTP
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
    
    local httpFunc = GetHTTPFunction()
    
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
    
    httpFunc(requestData)
end

function ix.translation.Translate(text, targetLang, callback)
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
    
    local httpFunc = GetHTTPFunction()
    
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
                    
                    if isAPIError or translatedText == text or translatedText == "" then
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
                    
                    if translatedText and translatedText != "" then
                        ix.translation.AddToCache(text, targetLang, translatedText, detectedLang)
                        callback(translatedText, detectedLang, false)
                    else
                        callback(text, detectedLang, false)
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
    
    httpFunc(requestData)
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
