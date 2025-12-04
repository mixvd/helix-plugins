local PLUGIN = PLUGIN

ix.translation = ix.translation or {}
ix.translation.cache = ix.translation.cache or {}
ix.translation.cacheOrder = ix.translation.cacheOrder or {}

ix.translation.rtlLanguages = {
    ["ar"] = true,
    ["he"] = true,
    ["fa"] = true,
    ["ur"] = true,
    ["yi"] = true,
}

local RTL_MARK = string.char(0xE2, 0x80, 0x8F)
local RTL_EMBEDDING = string.char(0xE2, 0x80, 0xAB)
local POP_DIRECTIONAL = string.char(0xE2, 0x80, 0xAC)

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

local function WrapRTL(text, targetLang)
    if ix.translation.rtlLanguages[targetLang] then
        return RTL_EMBEDDING .. text .. POP_DIRECTIONAL
    end
    return text
end

local bracketPatterns = {
    { open = "<", close = ">", pattern = "<([^<>]+)>" },
    { open = "[", close = "]", pattern = "%[([^%[%]]+)%]" },
    { open = "(", close = ")", pattern = "%(([^%(%)]+)%)" },
    { open = "{", close = "}", pattern = "{([^{}]+)}" },
    { open = "«", close = "»", pattern = "«([^«»]+)»" },
}

local function ExtractBracketInfo(text)
    local brackets = {}
    
    for _, bracket in ipairs(bracketPatterns) do
        local pos = 1
        while true do
            local startPos, endPos, innerText = string.find(text, bracket.pattern, pos)
            if !startPos then break end
            
            table.insert(brackets, {
                inner = innerText,
                open = bracket.open,
                close = bracket.close,
                startPos = startPos,
                endPos = endPos,
                pattern = bracket.pattern
            })
            
            pos = endPos + 1
        end
    end
    
    table.sort(brackets, function(a, b) return a.startPos > b.startPos end)
    
    return brackets
end

local function ReplaceBracketsWithPlaceholders(text, brackets)
    local result = text
    local sortedBrackets = {}
    
    for i, bracket in ipairs(brackets) do
        table.insert(sortedBrackets, {bracket = bracket, originalIndex = i})
    end
    
    table.sort(sortedBrackets, function(a, b) return a.bracket.startPos > b.bracket.startPos end)
    
    for _, item in ipairs(sortedBrackets) do
        local bracket = item.bracket
        local placeholder = string.format("__BRACKET_%d__", item.originalIndex)
        local bracketText = bracket.open .. bracket.inner .. bracket.close
        result = string.gsub(result, bracketText, placeholder, 1)
    end
    
    return result, sortedBrackets
end

local function RestoreBracketsFromPlaceholders(text, sortedBrackets, translatedSegments)
    local result = text
    
    for i = #sortedBrackets, 1, -1 do
        local item = sortedBrackets[i]
        local bracket = item.bracket
        local placeholder = string.format("__BRACKET_%d__", item.originalIndex)
        local translated = translatedSegments[item.originalIndex] or bracket.inner
        
        local escapedPlaceholder = string.gsub(placeholder, "([%(%)%.%%%+%-%*%?%[%^%$])", "%%%1")
        result = string.gsub(result, escapedPlaceholder, bracket.open .. translated .. bracket.close, 1)
    end
    
    return result
end

local function TranslateAndRestoreBrackets(translatedText, originalText, brackets, targetLang, callback)
    if #brackets == 0 then
        callback(translatedText)
        return
    end
    
    local sortedBrackets = {}
    for i, bracket in ipairs(brackets) do
        table.insert(sortedBrackets, {bracket = bracket, originalIndex = i})
    end
    table.sort(sortedBrackets, function(a, b) return a.bracket.startPos > b.bracket.startPos end)
    
    local translatedSegments = {}
    local remaining = #brackets
    local function checkComplete()
        remaining = remaining - 1
        if remaining <= 0 then
            local result = RestoreBracketsFromPlaceholders(translatedText, sortedBrackets, translatedSegments)
            callback(result)
        end
    end
    
    for i, bracket in ipairs(brackets) do
        local timeout = ix.config.Get("translationTimeout", 15)
        local email = ix.config.Get("translationEmail", "")
        local url = "https://api.mymemory.translated.net/get?q=" .. URLEncode(bracket.inner) .. "&langpair=autodetect|" .. targetLang
        
        if email != "" then
            url = url .. "&de=" .. URLEncode(email)
        end
        
        local requestData = {
            url = url,
            method = "GET",
            timeout = timeout,
            success = function(code, body, headers)
                if code == 200 then
                    local response = util.JSONToTable(body)
                    if response and response.responseData and response.responseData.translatedText then
                        local translated = response.responseData.translatedText
                        local upper = string.upper(translated)
                        if !string.find(upper, "PLEASE SELECT") and !string.find(upper, "MYMEMORY") and translated != bracket.inner then
                            translatedSegments[i] = WrapRTL(translated, targetLang)
                        end
                    end
                end
                checkComplete()
            end,
            failed = function()
                checkComplete()
            end
        }
        
        if CHTTP then
            if !CHTTP(requestData) then
                checkComplete()
            end
        elseif HTTP then
            HTTP(requestData)
        else
            checkComplete()
        end
    end
end

local function ProcessVocoder(text, targetLang, callback)
    local vocoderPattern = "<::%s*(.-)%s*::>"
    local innerText = string.match(text, vocoderPattern)
    
    if !innerText or innerText == "" then
        callback(text, nil, false)
        return
    end
    
    local cached, cachedDetectedLang = ix.translation.GetFromCache(innerText, targetLang)
    if cached then
        local result = string.gsub(text, vocoderPattern, "<:: " .. cached .. " ::>")
        callback(result, cachedDetectedLang, false)
        return
    end
    
    ix.translation.TranslateText(innerText, targetLang, function(translatedInner, detectedLang, failed)
        if !failed and translatedInner and translatedInner != innerText then
            ix.translation.AddToCache(innerText, targetLang, translatedInner, detectedLang)
            local result = string.gsub(text, vocoderPattern, "<:: " .. translatedInner .. " ::>")
            callback(result, detectedLang, false)
        else
            callback(text, detectedLang, failed)
        end
    end)
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
}

ix.translation.fallbackLanguages = {"fr", "de", "es", "it", "pt", "ru", "zh", "ja", "ko", "ar"}


function ix.translation.TryFallbackLanguages(text, targetLang, alreadyTried, callback, index)
    index = index or 1
    
    local fallbacks = ix.translation.fallbackLanguages
    
    while index <= #fallbacks do
        local tryLang = fallbacks[index]
        
        if tryLang != alreadyTried and tryLang != targetLang then
            ix.translation.TranslateWithSource(text, tryLang, targetLang, function(result, srcLang, failed)
                if !failed and result != text and result != "" then
                    callback(result, tryLang, false)
                else
                    ix.translation.TryFallbackLanguages(text, targetLang, alreadyTried, callback, index + 1)
                end
            end)
            return
        end
        
        index = index + 1
    end
    
    callback(text, alreadyTried or "en", true)
end

function ix.translation.TranslateText(text, targetLang, callback)
    local cached, cachedDetectedLang = ix.translation.GetFromCache(text, targetLang)
    if cached then
        callback(WrapRTL(cached, targetLang), cachedDetectedLang, false)
        return
    end
    
    local brackets = ExtractBracketInfo(text)
    local hasBrackets = #brackets > 0
    
    local textToTranslate = text
    local sortedBrackets = nil
    if hasBrackets then
        textToTranslate, sortedBrackets = ReplaceBracketsWithPlaceholders(text, brackets)
    end
    
    local timeout = ix.config.Get("translationTimeout", 15)
    local email = ix.config.Get("translationEmail", "")
    
    local url = "https://api.mymemory.translated.net/get?q=" .. URLEncode(textToTranslate) .. "&langpair=autodetect|" .. targetLang
    
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
                    local detectedLang = response.responseData.detectedLanguage or "en"
                    
                    local correctedLang = ix.translation.languageCorrections[detectedLang]
                    if correctedLang then
                        detectedLang = correctedLang
                    end
                    
                    local upperTranslation = translatedText and string.upper(translatedText) or ""
                    local isAPIError = string.find(upperTranslation, "PLEASE SELECT") or
                                       string.find(upperTranslation, "TWO DISTINCT") or
                                       string.find(upperTranslation, "MYMEMORY") or
                                       string.find(upperTranslation, "INVALID")
                    
                    if detectedLang == targetLang then
                        callback(text, detectedLang, false)
                        return
                    end
                    
                    if isAPIError or translatedText == text or translatedText == "" then
                        ix.translation.TranslateWithSource(text, detectedLang, targetLang, function(result, srcLang, failed)
                            if failed or result == text then
                                ix.translation.TryFallbackLanguages(text, targetLang, detectedLang, function(finalResult, finalLang, finalFailed)
                                    if hasBrackets and !finalFailed then
                                        TranslateAndRestoreBrackets(finalResult, text, brackets, targetLang, function(finalText)
                                            callback(WrapRTL(finalText, targetLang), finalLang, false)
                                        end)
                                    else
                                        callback(WrapRTL(finalResult, targetLang), finalLang, finalFailed)
                                    end
                                end)
                            else
                                if hasBrackets then
                                    TranslateAndRestoreBrackets(result, text, brackets, targetLang, function(finalText)
                                        callback(WrapRTL(finalText, targetLang), srcLang, false)
                                    end)
                                else
                                    callback(WrapRTL(result, targetLang), srcLang, failed)
                                end
                            end
                        end)
                        return
                    end
                    
                    if translatedText and translatedText != "" and translatedText != text then
                        if hasBrackets then
                            TranslateAndRestoreBrackets(translatedText, text, brackets, targetLang, function(finalText)
                                ix.translation.AddToCache(text, targetLang, finalText, detectedLang)
                                callback(WrapRTL(finalText, targetLang), detectedLang, false)
                            end)
                        else
                            ix.translation.AddToCache(text, targetLang, translatedText, detectedLang)
                            callback(WrapRTL(translatedText, targetLang), detectedLang, false)
                        end
                    else
                        ix.translation.TryFallbackLanguages(text, targetLang, detectedLang, function(finalResult, finalLang, finalFailed)
                            if hasBrackets and !finalFailed then
                                TranslateAndRestoreBrackets(finalResult, text, brackets, targetLang, function(finalText)
                                    callback(WrapRTL(finalText, targetLang), finalLang, false)
                                end)
                            else
                                callback(WrapRTL(finalResult, targetLang), finalLang, finalFailed)
                            end
                        end)
                    end
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
                        callback(WrapRTL(translatedText, targetLang), sourceLang, false)
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
        ProcessVocoder(text, targetLang, function(translatedText, detectedLang, failed)
            callback(WrapRTL(translatedText, targetLang), detectedLang or "en", failed or false)
        end)
        return
    end
    
    local cached, cachedDetectedLang = ix.translation.GetFromCache(text, targetLang)
    if cached then
        callback(WrapRTL(cached, targetLang), cachedDetectedLang, false)
        return
    end
    
    local brackets = ExtractBracketInfo(text)
    local hasBrackets = #brackets > 0
    
    local textToTranslate = text
    local sortedBrackets = nil
    if hasBrackets then
        textToTranslate, sortedBrackets = ReplaceBracketsWithPlaceholders(text, brackets)
    end
    
    local timeout = ix.config.Get("translationTimeout", 15)
    local email = ix.config.Get("translationEmail", "")
    
    local url = "https://api.mymemory.translated.net/get?q=" .. URLEncode(textToTranslate) .. "&langpair=autodetect|" .. targetLang
    
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
                    
                    if detectedLang == targetLang then
                        callback(text, detectedLang, false)
                        return
                    end
                    
                    if isAPIError or translatedText == text or translatedText == "" then
                        ix.translation.TranslateWithSource(text, detectedLang, targetLang, function(result, srcLang, failed)
                            if failed or result == text then
                                ix.translation.TryFallbackLanguages(text, targetLang, detectedLang, function(finalResult, finalLang, finalFailed)
                                    if hasBrackets and !finalFailed then
                                        TranslateAndRestoreBrackets(finalResult, text, brackets, targetLang, function(finalText)
                                            ix.translation.AddToCache(text, targetLang, finalText, finalLang)
                                            callback(WrapRTL(finalText, targetLang), finalLang, false)
                                        end)
                                    else
                                        callback(WrapRTL(finalResult, targetLang), finalLang, finalFailed)
                                    end
                                end)
                            else
                                if hasBrackets then
                                    TranslateAndRestoreBrackets(result, text, brackets, targetLang, function(finalText)
                                        ix.translation.AddToCache(text, targetLang, finalText, srcLang)
                                        callback(WrapRTL(finalText, targetLang), srcLang, false)
                                    end)
                                else
                                    callback(result, srcLang, failed)
                                end
                            end
                        end)
                        return
                    end
                    
                    if translatedText and translatedText != "" and translatedText != text then
                        if hasBrackets then
                            TranslateAndRestoreBrackets(translatedText, text, brackets, targetLang, function(finalText)
                                ix.translation.AddToCache(text, targetLang, finalText, detectedLang)
                                callback(WrapRTL(finalText, targetLang), detectedLang, false)
                            end)
                        else
                            ix.translation.AddToCache(text, targetLang, translatedText, detectedLang)
                            callback(WrapRTL(translatedText, targetLang), detectedLang, false)
                        end
                    else
                        ix.translation.TryFallbackLanguages(text, targetLang, detectedLang, function(finalResult, finalLang, finalFailed)
                            if hasBrackets and !finalFailed then
                                TranslateAndRestoreBrackets(finalResult, text, brackets, targetLang, function(finalText)
                                    ix.translation.AddToCache(text, targetLang, finalText, finalLang)
                                    callback(WrapRTL(finalText, targetLang), finalLang, false)
                                end)
                            else
                                callback(WrapRTL(finalResult, targetLang), finalLang, finalFailed)
                            end
                        end)
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
