local PLUGIN = PLUGIN

PLUGIN.name = "Gambling Slots"
PLUGIN.description = "Add gambling slot machine to Helix."
PLUGIN.author = "Reagent (CW), ported by mxd (IX)"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright (c) 2024 mxd (mixvd)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

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

ix.config.Add("luckySevenDiamond", 500, "How many tokens you get having a Lucky 7 or a Diamond?", nil, {
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