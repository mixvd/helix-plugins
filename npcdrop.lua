local PLUGIN = PLUGIN;

PLUGIN.name = "NPC Drop"
PLUGIN.author = "Mixed"
PLUGIN.description = "Makes NPC Drop items when they die."

function PLUGIN:OnNPCKilled(entity)
    local class = entity:GetClass()
    local rand = math.random(1, 2)

    
    if (class == "npc_zombie") then
    	if rand == 1 then
        	ix.item.Spawn("uniqueID", entity:GetPos() + Vector(0, 0, 8))
        end
    end
    if (class == "npc_headcrab") then
    	if rand == 1 or rand == 2 then
        	ix.item.Spawn("uniqueID", entity:GetPos() + Vector(0, 0, 8))
        end
    end
    if (class == "npc_antlion") then
    	if rand == 1 and rand == 2 then
        	ix.item.Spawn("uniqueID", entity:GetPos() + Vector(0, 0, 8))
        end
    end
end
