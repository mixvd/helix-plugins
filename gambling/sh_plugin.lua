local PLUGIN = PLUGIN

PLUGIN.name = "Gambling Slots"
PLUGIN.description = "Add gambling slot machine to Helix."
PLUGIN.author = "Reagent (CW), ported by mxd (IX)"
PLUGIN.schema = "Any"

ix.util.Include("sv_hooks.lua")

ix.config.Add("gamblingPrice", 13, "How many token should cost a slot spin?", nil, {
    category = "Slot Machine",
    data = {min = 1, max = 13},
})

ix.config.Add("jackpotChance", 32, "How many chance you have to get a jackpot?", nil, {
    category = "Slot Machine",
    data = {min = 1, max = 32},
})

ix.config.Add("singleBarDollarSign", 50, "How many tokens you get having a Single Bar or a Dollar Sign?", nil, {
    category = "Slot Machine",
    data = {min = 1, max = 50},
})

ix.config.Add("horseShoeDoubleBar", 100, "How many tokens you get having a Horse Shoe or a Double Bar?", nil, {
    category = "Slot Machine",
    data = {min = 1, max = 100},
})

ix.config.Add("tripleBarClover", 200, "How many tokens you get having a Triple Bar or a Clover?", nil, {
    category = "Slot Machine",
    data = {min = 1, max = 200},
})

ix.config.Add("lucky7Diamond", 500, "How many tokens you get having a Lucky 7 or a Diamond?", nil, {
    category = "Slot Machine",
    data = {min = 1, max = 500},
})

ix.command.Add("SlotMachineAdd", {
    adminOnly = true,
    description = "Add a slot machine at your target position.",
    OnRun = function(self, client)
        local trace = client:GetEyeTraceNoCursor()
        local entity = scripted_ents.Get("ix_slot_machine"):SpawnFunction(client, trace)
    
        if ( IsValid(entity) ) then
            client:NotifyLocalized("You have added a slot machine.")
        end
    end
})