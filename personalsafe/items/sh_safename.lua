ITEM.name = "Safe Name"
ITEM.description = "A safe name to rename your own container."
ITEM.model = "models/props_lab/clipboard.mdl"
ITEM.width = 1
ITEM.height = 1

ITEM.functions.Use = {
	name = "Set Name",
	tip = "useTip",
	icon = "icon16/lock_add.png",
	OnRun = function(itemTable, self, entity)
		local client = itemTable.player
		local name = net.ReadString()
		local entity = net.ReadEntity()
		local tr = client:GetEyeTraceNoCursor()

		if (tr.Entity:GetClass() != "ix_container") then 
			client:NotifyLocalized("You must use this on a personal safe!", recipient) 
			return false
		end

		if tr.Entity.name then 
			client:NotifyLocalized("You cannot put a name on an already named container!", recipient)
		 	return false 
		end

		client:RequestString('Container Name', 'What name do you want for your personal safe?', function(name)

			if (name:len() != 0) then
			tr.Entity.Sessions = {}
			tr.Entity:SetDisplayName(name)
			tr.Entity.name = name

			client:NotifyLocalized("containerName", name)
			
		end
		end, '')

	end
}