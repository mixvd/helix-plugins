local PLUGIN = PLUGIN

util.AddNetworkString("ixTranslationOpenMenu")
util.AddNetworkString("ixTranslationSetLanguage")
util.AddNetworkString("ixTranslationLanguageUpdated")
util.AddNetworkString("ixTranslationGetLanguages")
util.AddNetworkString("ixTranslationSendLanguages")

net.Receive("ixTranslationSetLanguage", function(_, client)
    local languageCode = net.ReadString()
    
    if !client or !IsValid(client) then return end
    
    local character = client:GetCharacter()
    if !character then return end
    
    languageCode = string.lower(languageCode)
    if !PLUGIN:IsValidLanguage(languageCode) then
        client:NotifyLocalized("translationInvalidLanguage")
        return
    end
    
    local oldLang = character:GetLanguage() or "en"
    
    character:SetLanguage(languageCode)
    character:SetData("hasSetLanguage", true)
    
    net.Start("ixTranslationLanguageUpdated")
    net.WriteString(languageCode)
    net.WriteString(PLUGIN:GetLanguageName(languageCode))
    net.Send(client)
    
    client:NotifyLocalized("translationLanguageSet", PLUGIN:GetLanguageName(languageCode))
    
    hook.Run("OnLanguageChanged", client, character, oldLang, languageCode)
end)

net.Receive("ixTranslationGetLanguages", function(_, client)
    if !client or !IsValid(client) then return end
    
    net.Start("ixTranslationSendLanguages")
    net.WriteTable(PLUGIN.languages)
    net.Send(client)
end)
