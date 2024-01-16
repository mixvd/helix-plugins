local PLUGIN = PLUGIN

function PLUGIN:SaveData()
	local slots = {}
	
	for k, v in pairs(ents.FindByClass("ix_slot_machine")) do
		slots[#slots + 1] = {
			angles = v:GetAngles(),
			pos = v:GetPos(),
		}
	end
	
	ix.data.Set("slotMachine", slots)
end

function PLUGIN:LoadData()
	local slots = ix.data.Get("slotMachine")

	if slots then
		for k, v in pairs(slots) do
			local entity = ents.Create("ix_slot_machine")
			entity:SetAngles(v.angles)
			entity:SetPos(v.pos)
			entity:Spawn()
			entity:Activate()
		end
	end
end