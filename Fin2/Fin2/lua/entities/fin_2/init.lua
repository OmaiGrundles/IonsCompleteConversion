
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

function ENT:Initialize()   
	math.randomseed(CurTime())
	self.Entity:SetMoveType( MOVETYPE_NONE )                 
end   

function ENT:OnRemove()
	duplicator.ClearEntityModifier(self.ent, "fin2")
	self.ent.Fin2_Ent = nil
end

 function ENT:Think()
	local physobj = self.ent:GetPhysicsObject()
	if !physobj:IsValid() then return end
	
	local curvel = physobj:GetVelocity()
	local curup = self:GetForward()
	
	local vec1 = curvel
	local vec2 = curup
	vec1 = vec1 - 2*(vec1:Dot(vec2))*vec2
	local sped = vec1:Length()
	
	local finalvec = curvel
	local modf = math.abs(curup:DotProduct(curvel:GetNormalized()))
	local nvec = (curup:DotProduct(curvel:GetNormalized()))
	
	if (self.pln == 1) then
		
		if nvec > 0 then
			vec1 = vec1 + (curup * 10)
		else
			vec1 = vec1 + (curup * -10)
		end
		
		finalvec = vec1:GetNormalized() * (math.pow(sped, modf) - 1)
		finalvec = finalvec:GetNormalized()
		finalvec = (finalvec * self.efficiency) + curvel
		
	end
	
	if (self.lift != "lift_none") then
		if (self.lift == "lift_normal") then
			local liftmul = 1 - math.abs(nvec)
			finalvec = finalvec + (curup * liftmul * curvel:Length() * self.efficiency) / 700
		else
			local liftmul = (nvec / math.abs(nvec)) - nvec
			finalvec = finalvec + (curup * curvel:Length() * self.efficiency * liftmul) / 700
		end
	end
	
	finalvec = finalvec:GetNormalized()
	finalvec = finalvec * curvel:Length()
	
	if (self.wind == 1) then
		local wind = ((2 * (fintool.wind:DotProduct(curup)) * curup - fintool.wind)) * (math.abs(fintool.wind:DotProduct(curup)) / 10000)
		wind = wind * (self.efficiency / 50)
		finalvec = finalvec + wind
	end
	
	if (self.cline == 1) then
		local trace = {
			start = self.ent:GetPos(),
			endpos = self.ent:GetPos() + Vector(0, 0, -1000000),
			mask = 131083
		}
		local trc = util.TraceLine(trace)
		
		local MatType = trc.MatType
		
		if (MatType == 67 || MatType == 77) then
			local heatvec = Vector(0, 0, 100)
			local cline = ((2 * (heatvec:DotProduct(curup)) * curup - heatvec)) * (math.abs(heatvec:DotProduct(curup)) / 1000)
			finalvec = finalvec + (cline * (self.efficiency / 50))
		end
		
	end
	
	
	physobj:SetVelocity(finalvec)
	
	
	
	self.Entity:NextThink( CurTime())
	return true 
 end
