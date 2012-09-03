
TOOL.Category		= "Construction"
TOOL.Name			= "#Stacker"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "freeze" ]	 	= "0"
TOOL.ClientConVar[ "weld" ]	 	= "0"
TOOL.ClientConVar[ "nocollide" ]	= "0"
TOOL.ClientConVar[ "mode" ] 		= "1"
TOOL.ClientConVar[ "dir" ] 		= "1"
TOOL.ClientConVar[ "count" ] 		= "1"
TOOL.ClientConVar[ "model" ] 		= ""
TOOL.ClientConVar[ "offsetx" ] 		= "0"
TOOL.ClientConVar[ "offsety" ] 		= "0"
TOOL.ClientConVar[ "offsetz" ] 		= "0"
TOOL.ClientConVar[ "rotp" ] 		= "0"
TOOL.ClientConVar[ "roty" ] 		= "0"
TOOL.ClientConVar[ "rotr" ] 		= "0"
TOOL.ClientConVar[ "recalc" ] 		= "0"

// Add Default Language translation (saves adding it to the txt files)
if ( CLIENT ) then

	language.Add( "Tool.ol_stacker.name", "Stacker" )
	language.Add( "Tool.ol_stacker.desc", "Stacks Props Easily" )
	language.Add( "Tool.ol_stacker.0", "Click To Stack The Prop You're Pointing At." )
	
	language.Add( "Undone.ol_stacker", "Undone Stack" )
	
end

function TOOL:LeftClick( trace )
	if !trace.Entity then return false end
	if !trace.Entity:IsValid() then return false end
	if trace.Entity:GetClass() != "prop_physics" then return false end
	if CLIENT then return true end
	
	local freeze		= self:GetClientNumber( "freeze" ) == 1
	local weld		= self:GetClientNumber( "weld" ) == 1
	local nocollide		= self:GetClientNumber( "nocollide" ) == 1
	local mode		= self:GetClientNumber( "mode" )
	local dir		= self:GetClientNumber( "dir" )
	local count		= self:GetClientNumber( "count" )
	local offsetx		= self:GetClientNumber( "offsetx" )
	local offsety		= self:GetClientNumber( "offsety" )
	local offsetz		= self:GetClientNumber( "offsetz" )
	local rotp		= self:GetClientNumber( "rotp" )
	local roty		= self:GetClientNumber( "roty" )
	local rotr		= self:GetClientNumber( "rotr" )
	local recalc		= self:GetClientNumber( "recalc" ) == 1
	local offset		= Vector(offsetx, offsety, offsetz)
	local rot		= Angle(rotp, roty, rotr)
	-- local model		= self:GetClientInfo( "model" )
	
	-- if !model || !util.IsValidModel(model) then return false end
	
	local player = self:GetOwner()
	local ent = trace.Entity
	
	local newvec = ent:GetPos()
	local newang = ent:GetAngles()
	local lastent = ent
	
	undo.Create("ol_stacker")
	
	for i=1, count, 1 do
		if ( !self:GetSWEP():CheckLimit( "props" ) ) then break end
		
		// ********************
		// POSITION CALCULATION
		// ********************
		if i == 1 || (mode == 2 && recalc == true) then
			// We only calculate this stuff if its the first item in the stack OR
			// if recalc is turned on
			stackdir, height, thisoffset = self:OLStackerCalcPos(lastent, mode, dir, offset)
		end
		
		newvec = newvec + stackdir * height + thisoffset
		newang = newang + rot
		
		// Test to make sure this is inside the level
		if !util:IsInWorld(newvec) then
			// This check is currently disabled because of a bug in gmod causing
			// util:IsInWorld to always return false.
			--break
		end
		
		// Find out if there is an entity on this spot
		local entlist = ents.FindInSphere(newvec,1)
		local bFound = false
		for k, v in pairs(entlist) do
			if v:IsValid() && v != lastent && v:GetClass() == "prop_physics" && v:GetPos() == newvec && v != self.GhostEntity then
				bFound = true
			end
		end
		if bFound then break end
		
		newent = ents.Create("prop_physics")
			newent:SetModel(ent:GetModel())
			newent:SetColor(ent:GetColor())
			newent:SetPos(newvec)
			newent:SetAngles(newang)
			newent:Spawn()
			if freeze then
				newent:GetPhysicsObject():EnableMotion( false )
			end
		
		if weld then
			local weldent = constraint.Weld( lastent, newent, 0, 0, 0 )
			undo.AddEntity( weldent )
		end
		if nocollide then
			local nocollideent = constraint.NoCollide(lastent, newent, 0, 0)
			undo.AddEntity( nocollideent )
		end
		
		lastent = newent
		undo.AddEntity( newent )
		player:AddCount( "props", newent )
		player:AddCleanup( "props", newent )
		
		if PropDefender && PropDefender.Player && PropDefender.Player.Give then
			PropDefender.Player.Give(player, newent, false)
		end
	end
	
	
	undo.SetPlayer( player )
	undo.Finish()
		
	return true
end

function TOOL:OLStackerCalcPos(lastent, mode, dir, offset)
	local forward = Vector(1,0,0):Angle()
	local pos = lastent:GetPos()
	local ang = lastent:GetAngles()

	local lower, upper = lastent:WorldSpaceAABB( )
	local glower = lastent:OBBMins()
	local gupper = lastent:OBBMaxs()
	
	local stackdir = Vector(0,0,1)
	local height = math.abs(upper.z - lower.z)

	if mode == 1 then // Relative to world
		if dir == 1 then
			stackdir = forward:Up()
			height = math.abs(upper.z - lower.z)
		elseif dir == 2 then
			stackdir = forward:Up() * -1
			height = math.abs(upper.z - lower.z)
		elseif dir == 3 then
			stackdir = forward:Forward()
			height = math.abs(upper.x - lower.x)
		elseif dir == 4 then
			stackdir = forward:Forward() * -1
			height = math.abs(upper.x - lower.x)
		elseif dir == 5 then
			stackdir = forward:Right()
			height = math.abs(upper.y - lower.y)
		elseif dir == 6 then
			stackdir = forward:Right() * -1
			height = math.abs(upper.y - lower.y)
		end
	elseif mode == 2 then // Relative to prop
		forward = ang
		if dir == 1 then
			stackdir = forward:Up()
			offset = forward:Up() * offset.X + forward:Forward() * -1 * offset.Z + forward:Right() * offset.Y
			height = math.abs(gupper.z - glower.z)
		elseif dir == 2 then
			stackdir = forward:Up() * -1
			offset = forward:Up() * -1 * offset.X + forward:Forward() * offset.Z + forward:Right() * offset.Y
			height = math.abs(gupper.z - glower.z)
		elseif dir == 3 then
			stackdir = forward:Forward()
			offset = forward:Forward() * offset.X + forward:Up() * offset.Z + forward:Right() * offset.Y
			height = math.abs(gupper.x - glower.x)
		elseif dir == 4 then
			stackdir = forward:Forward() * -1
			offset = forward:Forward() * -1 * offset.X + forward:Up() * offset.Z + forward:Right() * -1 * offset.Y
			height = math.abs(gupper.x - glower.x)
		elseif dir == 5 then
			stackdir = forward:Right()
			offset = forward:Right() * offset.X + forward:Up() * offset.Z + forward:Forward() * -1 * offset.Y
			height = math.abs(gupper.y - glower.y)
		elseif dir == 6 then
			stackdir = forward:Right() * -1
			offset = forward:Right() * -1 * offset.X + forward:Up() * offset.Z + forward:Forward() * offset.Y
			height = math.abs(gupper.y - glower.y)
		end
		
		-- offset = (stackdir:Angle():Up() * offset.Z) + (stackdir:Angle():Forward() * offset.X) + (stackdir:Angle():Right() * offset.Y)
	end
	
	return stackdir, height, offset
end

function TOOL:RightClick( trace )
	return self:LeftClick( trace )

	// Maybe Ill add this later...
	/*
	if !trace.Entity then return false end
	
	local ent = trace.Entity
	local ply = self:GetOwner()
	
	if ent:GetClass() != "prop_physics" then return false end
	
	local model = ent:GetModel()
	if !model then
		ply:ConCommand("ol_stacker_model \"\"\n")
	else
		ply:ConCommand("ol_stacker_model "..model.."\n")
	end
	
	return true
	*/
end

function TOOL.BuildCPanel( CPanel )

	// HEADER
	CPanel:AddControl( "Header", { Text = "#Tool.ol_stacker.name", Description	= "#Tool.ol_stacker.desc" }  )
	
	CPanel:AddControl( "Checkbox", { Label = "Freeze Props", Command = "ol_stacker_freeze" } )
	
	CPanel:AddControl( "Checkbox", { Label = "Weld Props", Command = "ol_stacker_weld" } )
	
	CPanel:AddControl( "Checkbox", { Label = "No Collide Props", Command = "ol_stacker_nocollide" } )

	local params = {Label = "Relative To:", MenuButton = "0", Options = {}}
	params.Options["World"] = {ol_stacker_mode = "1"}
	params.Options["Prop"] = {ol_stacker_mode = "2"}
	
	CPanel:AddControl( "ComboBox", params )

	local params = {Label = "Stack Direction", MenuButton = "0", Options = {}}
	params.Options["Up"] = {ol_stacker_dir = "1"}
	params.Options["Down"] = {ol_stacker_dir = "2"}
	params.Options["Front"] = {ol_stacker_dir = "3"}
	params.Options["Behind"] = {ol_stacker_dir = "4"}
	params.Options["Right"] = {ol_stacker_dir = "5"}
	params.Options["Left"] = {ol_stacker_dir = "6"}
	
	CPanel:AddControl( "ComboBox", params )
	
	CPanel:AddControl( "Slider",  { Label	= "Count",
					Type	= "Integer",
					Min		= 0,
					Max		= 10,
					Command = "ol_stacker_count",
					Description = "How many props to stack."}	 )

	CPanel:AddControl( "Header", { Text = "Advanced Options", Description	= "These options are for advanced users. Leave them all default (0) if you don't understand what they do." }  )

	CPanel:AddControl( "Button",  { Label	= "Reset Advanced Options",
					Command = "olstacker_resetoffsets",
					Text = "Reset"}	 )

	CPanel:AddControl( "Slider",  { Label	= "Offset X (forward/back)",
					Type	= "Float",
					Min		= 0,
					Max		= 1000,
					Command = "ol_stacker_offsetx"}	 )

	CPanel:AddControl( "Slider",  { Label	= "Offset Y (right/left)",
					Type	= "Float",
					Min		= 0,
					Max		= 1000,
					Command = "ol_stacker_offsety"}	 )

	CPanel:AddControl( "Slider",  { Label	= "Offset Z (up/down)",
					Type	= "Float",
					Min		= 0,
					Max		= 1000,
					Command = "ol_stacker_offsetz"}	 )

	CPanel:AddControl( "Slider",  { Label	= "Rotate Pitch",
					Type	= "Float",
					Min		= 0,
					Max		= 360,
					Command = "ol_stacker_rotp"}	 )

	CPanel:AddControl( "Slider",  { Label	= "Rotate Yaw",
					Type	= "Float",
					Min		= 0,
					Max		= 360,
					Command = "ol_stacker_roty"}	 )

	CPanel:AddControl( "Slider",  { Label	= "Rotate Roll",
					Type	= "Float",
					Min		= 0,
					Max		= 360,
					Command = "ol_stacker_rotr"}	 )

	CPanel:AddControl( "Checkbox", { Label = "Stack relative to new rotation", Command = "ol_stacker_recalc", Description = "If this is checked, each item in the stack will be stacked relative to the previous item in the stack. This allows you to create curved stacks." } )

end

if (CLIENT) then

local function ResetOffsets( player, command, arguments )
	-- Reset all of the offset options to 0
	LocalPlayer():ConCommand("ol_stacker_offsetx 0\n")
	LocalPlayer():ConCommand("ol_stacker_offsety 0\n")
	LocalPlayer():ConCommand("ol_stacker_offsetz 0\n")
	LocalPlayer():ConCommand("ol_stacker_rotp 0\n")
	LocalPlayer():ConCommand("ol_stacker_roty 0\n")
	LocalPlayer():ConCommand("ol_stacker_rotr 0\n")
	LocalPlayer():ConCommand("ol_stacker_recalc 0\n")
end

concommand.Add( "olstacker_resetoffsets", ResetOffsets )

end

function TOOL:UpdateGhostStack( ghost, player, ent )

	if ( !ent || !ghost ) then return end
	if ( !ent:IsValid() || !ghost:IsValid() ) then return end

	local mode		= self:GetClientNumber( "mode" )
	local dir		= self:GetClientNumber( "dir" )
	local offsetx		= self:GetClientNumber( "offsetx" )
	local offsety		= self:GetClientNumber( "offsety" )
	local offsetz		= self:GetClientNumber( "offsetz" )
	local rotp		= self:GetClientNumber( "rotp" )
	local roty		= self:GetClientNumber( "roty" )
	local rotr		= self:GetClientNumber( "rotr" )
	local offset		= Vector(offsetx, offsety, offsetz)
	local rot		= Angle(rotp, roty, rotr)
	
	local stackdir, height, thisoffset = self:OLStackerCalcPos(ent, mode, dir, offset)
	
	local newvec = ent:GetPos() + stackdir * height + thisoffset
	local newang = ent:GetAngles() + rot
	
	ghost:SetAngles(newang)
	ghost:SetPos( newvec )
	
	ghost:SetNoDraw( false )

end

function TOOL:Think()
	local player 	= self:GetOwner()
	local tr 	= util.GetPlayerTrace( player, player:GetAimVector() )
	local trace 	= util.TraceLine( tr )
	
	
	if trace.Hit then
		local newent	= trace.Entity

		if newent:IsValid() && newent:GetClass() == "prop_physics" && (newent != self.lastent || !self.GhostEntity) then
			-- Time to change our ghost
			self:MakeGhostEntity( newent:GetModel(), Vector(0,0,0), Angle(0,0,0) )
			self.lastent = newent
		end
		if (!self.lastent || !self.lastent:IsValid()) && self.GhostEntity then
			self:ReleaseGhostEntity()
		end
	end

	if self.lastent != nil && self.lastent:IsValid() then
		self:UpdateGhostStack( self.GhostEntity, player, self.lastent )
	end
end