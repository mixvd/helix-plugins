-- made by [myb] flapjack STEAM_0:0:37238513
-- ported & edited by Reagent (CW)
-- ported & edited by mxd (IX)

AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include( 'shared.lua' )

function ENT:SpawnFunction(client, trace)
	local SpawnPos = trace.HitPos + trace.HitNormal * 46
	local entity = ents.Create( "ix_slot_machine" )
	
	entity:SetPos( SpawnPos )

	local angles = (entity:GetPos() - client:GetPos()):Angle()
	angles.p = 0
	angles.y = 0
	angles.r = 0

	entity:SetAngles(angles)
	entity:Spawn()
	entity:Activate()

	for k, v in pairs(ents.FindInBox(entity:LocalToWorld(entity:OBBMins()), entity:LocalToWorld(entity:OBBMaxs()))) do
		if (string.find(v:GetClass(), "prop") and v:GetModel() == "models/props/slotmachine/slotmachinefinal.mdl") then
			entity:SetPos(v:GetPos())
			entity:SetAngles(v:GetAngles())
			SafeRemoveEntity(v)

			break
		end
	end

	return entity
end

function ENT:Initialize()
	self.Entity:SetModel( "models/props/slotmachine/slotmachinefinal.mdl" )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )
	size = 1.5
	self.Entity:SetModelScale(size,0)

	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
		phys:Wake()
        phys:SetMass( 100 )
	end

	self.spin_1 = ents.Create("prop_scalable")
	self.spin_1:SetPos(self:GetPos() + Vector(-17.5, -1, -7))
	self.spin_1:SetAngles(self:GetAngles() - Angle(0, 0, 0))
	self.spin_1:SetModel("models/props/slotmachine/spin_wheel.mdl")
	self.spin_1:SetParent(self)
	self.spin_1:SetCollisionGroup( COLLISION_GROUP_WORLD )
	self.spin_1:SetNotSolid(true)
	self.spin_1:Spawn()
	self.spin_1:SetSkin(12) -- dollar sign
	self.spin_1:SetModelScale(size,0)

	self.spin_2 = ents.Create("prop_scalable")
	self.spin_2:SetPos(self:GetPos() + Vector(-3.5, -1, -7))
	self.spin_2:SetAngles(self:GetAngles() - Angle(0, 0, 0))
	self.spin_2:SetModel("models/props/slotmachine/spin_wheel.mdl")
	self.spin_2:SetParent(self)
	self.spin_2:SetCollisionGroup( COLLISION_GROUP_WORLD )
	self.spin_2:SetNotSolid(true)
	self.spin_2:Spawn()
	self.spin_2:SetSkin(11) -- watermelon
	self.spin_2:SetModelScale(size,0)

	self.spin_3 = ents.Create("prop_scalable")
	self.spin_3:SetPos(self:GetPos() + Vector(9.5, -1, -7))
	self.spin_3:SetAngles(self:GetAngles() - Angle(0, 0, 0))
	self.spin_3:SetModel("models/props/slotmachine/spin_wheel.mdl")
	self.spin_3:SetParent(self)
	self.spin_3:SetCollisionGroup( COLLISION_GROUP_WORLD )
	self.spin_3:SetNotSolid(true)
	self.spin_3:Spawn()
	self.spin_3:SetSkin(10) -- horse shoe
	self.spin_3:SetModelScale(size,0)

	self.Entity.Is_playing = true
end


function ENT:Use(client)
	local character = client:GetCharacter()

	if self.Entity.Is_playing == false then return end

	if (!character:HasMoney(ix.config.Get("gamblingPrice", 13))) then
		client:Notify("You don't have enough money!")
		return
	end

	timer.Create("spin_all_wheels"..self:EntIndex( ), 0, 1, function()
		self.Entity.Is_playing = false
		character:TakeMoney(ix.config.Get("gamblingPrice", 13))
		self:EmitSound("ambient/levels/labs/coinslot1.wav", 60, 100)
		self:EmitSound("spin.wav", 100, 100)
		self.spin_1:SetSkin(0)
		self.spin_2:SetSkin(0)
		self.spin_3:SetSkin(0)

		self.Select_one = true
		self.Select_two = true
		self.Select_three = true
		self.jackpot = false
		self.lucky = math.random(1, ix.config.Get("jackpotChance", 32))


		chance = ix.config.Get("jackpotChance", 32) / 2
		if self.lucky == math.Round(chance) then

			self.pick_one = math.Rand(1,12)
			self.jackpot = true
		end

	timer.Create("stop_all_wheels"..self:EntIndex( ), 0.75, 3, function()

	if self.jackpot == false then
		self.pick_one = math.random(1,12)
	end

	if self.Select_one == true then
		self.spin_1:SetSkin(self.pick_one)
		self:EmitSound("drum_stop.wav", 100, 100)
		self.Select_one = false
		return
	end

	if self.Select_two == true then
		self.spin_2:SetSkin(self.pick_one)
		self:EmitSound("drum_stop.wav", 100, 100)
		self.Select_two = false
		return
	end

	if self.Select_three == true then
		self.spin_3:SetSkin(self.pick_one)
		self:EmitSound("drum_stop.wav", 100, 100)
		self.Select_three = false
	end

	self.payout = 0

		if self.spin_1:GetSkin() == 1 then self.payout = self.payout + 5 end
		if self.spin_1:GetSkin() == 3 then self.payout = self.payout + 5 end
		if self.spin_1:GetSkin() == 4 then self.payout = self.payout + 5 end
		if self.spin_1:GetSkin() == 5 then self.payout = self.payout + 5 end
		if self.spin_1:GetSkin() == 8 then self.payout = self.payout + 5 end
		if self.spin_1:GetSkin() == 9 then self.payout = self.payout + 5 end
		if self.spin_1:GetSkin() == 10 then self.payout = self.payout + 5 end
		if self.spin_1:GetSkin() == 12 then self.payout = self.payout + 5 end

		if self.spin_2:GetSkin() == 1 then self.payout = self.payout + 5 end
		if self.spin_2:GetSkin() == 3 then self.payout = self.payout + 5 end
		if self.spin_2:GetSkin() == 4 then self.payout = self.payout + 5 end
		if self.spin_2:GetSkin() == 5 then self.payout = self.payout + 5 end
		if self.spin_2:GetSkin() == 8 then self.payout = self.payout + 5 end
		if self.spin_2:GetSkin() == 9 then self.payout = self.payout + 5 end
		if self.spin_2:GetSkin() == 10 then self.payout = self.payout + 5 end
		if self.spin_2:GetSkin() == 12 then self.payout = self.payout + 5 end

		if self.spin_3:GetSkin() == 1 then self.payout = self.payout + 5 end
		if self.spin_3:GetSkin() == 3 then self.payout = self.payout + 5 end
		if self.spin_3:GetSkin() == 4 then self.payout = self.payout + 5 end
		if self.spin_3:GetSkin() == 5 then self.payout = self.payout + 5 end
		if self.spin_3:GetSkin() == 8 then self.payout = self.payout + 5 end
		if self.spin_3:GetSkin() == 9 then self.payout = self.payout + 5 end
		if self.spin_3:GetSkin() == 10 then self.payout = self.payout + 5 end
		if self.spin_3:GetSkin() == 12 then self.payout = self.payout + 5 end

		if self.jackpot == true and self.spin_3:GetSkin() == 1 then  self.payout = ix.config.Get("tripleBarClover", 200) end
		if self.jackpot == true and self.spin_3:GetSkin() == 3 then  self.payout = ix.config.Get("singleBarDollarSign", 50) end
		if self.jackpot == true and self.spin_3:GetSkin() == 4 then  self.payout = ix.config.Get("lucky7Diamond", 500) end
		if self.jackpot == true and self.spin_3:GetSkin() == 5 then  self.payout = ix.config.Get("horseShoeDoubleBar", 100) end
		if self.jackpot == true and self.spin_3:GetSkin() == 8 then  self.payout = ix.config.Get("tripleBarClover", 200) end
		if self.jackpot == true and self.spin_3:GetSkin() == 9 then  self.payout = ix.config.Get("lucky7Diamond", 500) end
		if self.jackpot == true and self.spin_3:GetSkin() == 10 then self.payout = ix.config.Get("horseShoeDoubleBar", 100) end
		if self.jackpot == true and self.spin_3:GetSkin() == 12 then self.payout = ix.config.Get("singleBarDollarSign", 50) end

		if self.payout > ix.config.Get("singleBarDollarSign", 50) - 1 then self:EmitSound("jackpot.wav", 100, 100) end

		if self.payout > 9 then self:EmitSound("payout.wav", 100, 100) character:GiveMoney(self.payout)
			client:Notify("Your payout is "..self.payout.."T")
		end

		self.payout = 0
		self.Entity.Is_playing = true
		self.jackpot = false

	end)
	end)
end
