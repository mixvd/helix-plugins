local PLUGIN = PLUGIN

-- Link to the map
-- https://steamcommunity.com/sharedfiles/filedetails/?id=2881666202

PLUGIN.name = "Sound & Broken Glass Removal"
PLUGIN.description = "Add sound effect to broken glass and a command to remove it from 'City 8 Definitive Edition by Aspect'."
PLUGIN.author = "mxd"
PLUGIN.schema = "Any"
PLUGIN.license = [[
Copyright (c) 2025 mxd (mixvd)

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local brokenGlassModels = {
    "models/propper/brokenglass_small.mdl",
    "models/propper/brokenglass_large.mdl",
    "models/propper/brokenglass.mdl"
}

ix.command.Add("RemoveBrokenGlass", {
    description = "Remove the broken glass around you.",
    adminOnly = true,
    OnRun = function(self, client)
        local foundGlass = false

        for k, v in ipairs (ents.FindInSphere( client:GetPos(), 10 )) do 
            if v:GetClass() == "prop_dynamic" and table.HasValue(brokenGlassModels, v:GetModel()) then
                v:Remove()
                foundGlass = true
                client:Notify("You've removed the broken glass around you.")
            end
        end

        if not foundGlass then
            client:Notify("There's no broken glass around you.")
        end
    end
})

function PLUGIN:PlayerFootstep(client, position, foot, soundName, volume)
    local glassEntities = ents.FindInSphere(position, 10)
    local onGlass = false
    for _, ent in ipairs(glassEntities) do
        local model = ent:GetModel()
        if ent:GetClass() == "prop_dynamic" and not ent:IsEffectActive(EF_NODRAW) then
            if table.HasValue(brokenGlassModels, model) then
                onGlass = true
                break
            else
                onGlass = false
            end
        end
    end
    if onGlass then
        local glassSounds = {
            "physics/glass/glass_bottle_break1.wav",
            "physics/glass/glass_bottle_break2.wav"
        }
        local randomSound = glassSounds[math.random(#glassSounds)]
        client:EmitSound(randomSound, 75, 100, 0.5)
    end
end
