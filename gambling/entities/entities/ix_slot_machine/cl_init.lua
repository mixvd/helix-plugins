include('shared.lua')

function ENT:Draw()
  self:DrawModel()
  local position = self:GetPos()
  local angles = self:GetAngles()
end
