
TOOL.Category		= "Information"
TOOL.Name			= "#Measuring Stick"
TOOL.Command		= nil
TOOL.ConfigName		= ""

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then

	language.Add( "Tool.ol_measuringstick.name", "Measuring Stick" )
	language.Add( "Tool.ol_measuringstick.desc", "Measure the distance between two points" )
	language.Add( "Tool.ol_measuringstick.0", "Click on the first point." )
	language.Add( "Tool.ol_measuringstick.1", "Click on the second point." )
	
end

function TOOL:LeftClick( trace )

	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end
	
	local iNum = self:NumObjects()
	
	self:SetObject( iNum + 1, trace.Entity, trace.HitPos, nil, trace.PhysicsBone, trace.HitNormal )

	if ( iNum > 0 ) then
		local WPos1, WPos2 = self:GetPos(1),	 self:GetPos(2)
		local length = ( WPos1 - WPos2):Length()
		
		// Clear the objects so we're ready to go again
		self:ClearObjects()

		message = string.format("Distance: %.5f",length)

		local ply = self:GetOwner()
		
		ply:PrintMessage(3, message)
		ply:PrintMessage(2, message)
		
	else
		self:SetStage( iNum+1 )
	end

	return true
end

function TOOL:RightClick( trace )
	local iNum = self:NumObjects()

	self:SetObject( 1, trace.Entity, trace.HitPos, nil, trace.PhysicsBone, trace.HitNormal )

	local tr = {}
	tr.start = trace.HitPos
	tr.endpos = tr.start + (trace.HitNormal * 16384)
	tr.filter = {} 
	tr.filter[1] = self:GetOwner()
	if (trace.Entity:IsValid()) then
		tr.filter[2] = trace.Entity
	end
	
	local tr = util.TraceLine( tr )
		
	if ( !tr.Hit ) then
		self:ClearObjects()
		return
	end
	
	self:SetObject( 2, tr.Entity, tr.HitPos, nil, tr.PhysicsBone, tr.HitNormal )
	
	local WPos1, WPos2 = self:GetPos(1),	 self:GetPos(2)
	local Ent1, Ent2 = self:GetEnt(1),	 self:GetEnt(2)
	local length = ( WPos1 - WPos2):Length()

	// Clear the objects so we're ready to go again
	self:ClearObjects()

	message = string.format("Distance from %s to %s: %.3f",Ent1:GetClass(),Ent2:GetClass(),length)

	local ply = self:GetOwner()

	ply:PrintMessage(3, message)
	ply:PrintMessage(2, message)
	
	// Clear the objects so we're ready to go again
	self:ClearObjects()
	
	return true
end

function TOOL.BuildCPanel( CPanel )

	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool.ol_measuringstick.name", Description	= "#Tool.ol_measuringstick.desc" }  )
end

local function OverrideCanTool(pl, rt, toolmode)
	-- We don't want any addons denying use of this tool. Even when using
	-- PropDefender, people should be able to use this tool on other people's
	-- stuff.
	if toolmode == "ol_measuringstick" then
		return true
	end
end
hook.Add( "CanTool", "ol_measuringstick_CanTool", OverrideCanTool );