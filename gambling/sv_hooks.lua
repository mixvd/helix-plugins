local PLUGIN = PLUGIN

function PLUGIN:SaveData()
	local slots = {}
	
	for k, v in pairs(ents.FindByClass("ix_slot_machine")) do
		slots[#slots + 1] = {
			v:GetAngles(),
			v:GetPos(),
		}
	end
	
	ix.data.Set("slotMachine", slots)
end

function PLUGIN:LoadData()
	local slots = ix.data.Get("slotMachine")

	if slots then
		for k, v in pairs(slots) do
			local entity = ents.Create("ix_slot_machine")
			entity:SetAngles(v[1])
			entity:SetPos(v[2])
			entity:Spawn()
		end
	end
end