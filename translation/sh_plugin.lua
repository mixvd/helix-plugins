local PLUGIN = PLUGIN

PLUGIN.name = "Translation System"
PLUGIN.author = "mxd"
PLUGIN.description = "Real-time chat translation using MyMemory API. Auto-detects language and translates."
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright (c) 2025 mxd (mixvd)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

ix.util.Include("sv_plugin.lua")
ix.util.Include("sv_nets.lua")
ix.util.Include("sv_hooks.lua")
ix.util.Include("cl_plugin.lua")
ix.util.Include("cl_nets.lua")

PLUGIN.languages = {
    ["en"] = "English",
    ["fr"] = "Français",
    ["es"] = "Español",
    ["de"] = "Deutsch",
    ["it"] = "Italiano",
    ["pt"] = "Português",
    ["ru"] = "Русский",
    ["zh"] = "中文",
    ["ja"] = "日本語",
    ["ko"] = "한국어",
    ["ar"] = "العربية",
    ["he"] = "עברית",
    ["fa"] = "فارسی",
    ["ur"] = "اردو",
    ["pl"] = "Polski",
    ["nl"] = "Nederlands",
    ["tr"] = "Türkçe",
    ["uk"] = "Українська",
    ["cs"] = "Čeština",
    ["sv"] = "Svenska",
    ["da"] = "Dansk",
    ["fi"] = "Suomi",
    ["el"] = "Ελληνικά",
    ["hu"] = "Magyar",
    ["ro"] = "Română",
    ["sk"] = "Slovenčina",
    ["bg"] = "Български",
    ["hr"] = "Hrvatski",
    ["sl"] = "Slovenščina",
    ["et"] = "Eesti",
    ["lv"] = "Latviešu",
    ["lt"] = "Lietuvių"
}

PLUGIN.translatedChatTypes = {
    ["ic"] = true,
    ["me"] = true,
    ["it"] = true,
    ["w"] = true,
    ["y"] = true,
    ["radio"] = true,
    ["event"] = true,
    ["ooc"] = true,
    ["looc"] = true
}

ix.char.RegisterVar("language", {
    field = "language",
    fieldType = ix.type.string,
    default = "en",
    bNoDisplay = true
})

ix.config.Add("translationEnabled", true, "Enable or disable the translation system.", nil, {
    category = "Translation"
})

ix.config.Add("translationEmail", "", "Your email (optional) - increases rate limit from 1000 to 10000 requests/day. No signup needed!", nil, {
    category = "Translation"
})

ix.config.Add("translationTimeout", 15, "Timeout in seconds for translation API requests.", nil, {
    category = "Translation",
    data = {min = 5, max = 60}
})

ix.config.Add("translationCacheEnabled", true, "Enable caching of translations to reduce API calls.", nil, {
    category = "Translation"
})

ix.config.Add("translationCacheSize", 500, "Maximum number of cached translations.", nil, {
    category = "Translation",
    data = {min = 50, max = 2000}
})

ix.config.Add("translationShowOriginal", false, "Show original text alongside translated text.", nil, {
    category = "Translation"
})

ix.config.Add("translationMenuOnFirstSpawn", true, "Automatically show language selection menu on first spawn.", nil, {
    category = "Translation"
})

function PLUGIN:GetLanguageName(code)
    return self.languages[code] or "Unknown"
end

function PLUGIN:IsValidLanguage(code)
    return self.languages[code] != nil
end

function PLUGIN:ShouldTranslateChatType(chatType)
    return self.translatedChatTypes[chatType] == true
end

ix.command.Add("Language", {
    description = "@cmdLanguage",
    OnRun = function(self, client)
        net.Start("ixTranslationOpenMenu")
        net.Send(client)
    end
})

ix.command.Add("SetLanguage", {
    description = "@cmdSetLanguage",
    adminOnly = true,
    arguments = ix.type.string,
    OnRun = function(self, client, languageCode)
        languageCode = string.lower(languageCode)
        
        if !PLUGIN:IsValidLanguage(languageCode) then
            client:NotifyLocalized("translationInvalidLanguage")
            return
        end
        
        local character = client:GetCharacter()
        if character then
            character:SetLanguage(languageCode)
            client:NotifyLocalized("translationLanguageSet", PLUGIN:GetLanguageName(languageCode))
        end
    end
})
