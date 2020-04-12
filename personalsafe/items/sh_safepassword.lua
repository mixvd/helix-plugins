ITEM.name = "Safe Password"
ITEM.description = "A safe password to secure your own container."
ITEM.model = "models/props_wasteland/prison_padlock001a.mdl"
ITEM.width = 1
ITEM.height = 1

ITEM.functions.Use = {
	name = "Set Password",
	tip = "useTip",
	icon = "icon16/lock_add.png",
	OnRun = function(itemTable, self, entity)
		local client = itemTable.player
		local password = net.ReadString()
		local entity = net.ReadEntity()
		local tr = client:GetEyeTraceNoCursor()

		if (tr.Entity:GetClass() != "ix_container") then 
			client:NotifyLocalized("You must use this on a personal safe!", recipient) 
			return false
		end

		if tr.Entity.password then 
			client:NotifyLocalized("You cannot put a name on an already secured container!", recipient)
		 	return false 
		end

		client:RequestString('Container Password', 'What password do you want for your personal safe?', function(password)

			if (password:len() != 0) then
			tr.Entity.Sessions = {}
			tr.Entity:SetLocked(true)
			tr.Entity.password = password

			client:NotifyLocalized("containerPassword", password)
			
		end
		end, '')

	end
}