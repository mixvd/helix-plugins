PLUGIN.name = "Drop Equipped"
PLUGIN.author = "Mixed"
PLUGIN.desc = "Makes equipped weapons drop on the ground when you die. Special thanks to Vex."

function PLUGIN:PlayerDeath(client)
    local items = client:GetCharacter():GetInventory():GetItems()
    for k, item in pairs( items ) do
        if item.isWeapon then
            if item:GetData( "equip" ) then
            	item:SetData("equip", false)
                ix.item.Spawn( item.uniqueID, client:GetShootPos(), function()
                    item:Remove()
                end, Angle(), item.data )
            end
        end
    end
end