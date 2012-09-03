
TOOL.Category		= "Constraints"
TOOL.Name			= "#Easy Parent"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "shadow" ] = "1"
TOOL.ClientConVar[ "physics" ] = "1"
TOOL.ClientConVar[ "collide" ] = "1"

if ( CLIENT ) then
	language.Add( "Tool.easy_parent.name", "Easy Parent" )
	language.Add( "Tool.easy_parent.desc", "Use this Parent tool for more solid welds." )
	language.Add( "Tool.easy_parent.0", "Left click to select main prop then select children props. Right click to begin parent process. Reload removes parent/children and clears selections." )

	language.Add( 'Undone.easy_parent', 'Easy Parent Undone' )
	language.Add( 'Cleanup.easy_parent', 'Easy Parent' )
	language.Add( 'Cleaned.easy_parent', 'Cleaned up all Easy Parents' )
end

function TOOL:ClearAll()
	for _, ent in pairs(self.Props or {}) do
		ent:SetColor( ent.origcolor ) --set color back
	end

	self.Props = {}
end

function TOOL:LeftClick(tr)
	if CLIENT then return true end

	local ply = self:GetOwner()

	if (tr.HitWorld) then
		ply:PrintMessage(HUD_PRINTTALK, "You can not select world props.")
		return false
	end

	local ent = tr.Entity

	if (!ValidEntity(ent)) then
		ply:PrintMessage(HUD_PRINTTALK, "You must select a valid entity.")
		return false
	end

	if (!self.Props) then self.Props = {} end

	--if already selected, unselect
	if (table.HasValue(self.Props, ent)) then
		table.RemoveByValue(self.Props, ent)
		ent:SetColor( ent.origcolor )
		return true
	end

	ent.origcolor = ent:GetColor() --save original color

	if (table.Count(self.Props) == 0) then
		ent:SetColor(Color(0, 255, 0, 150)) --green
	else
		ent:SetColor(Color(255, 0, 0, 150)) --red
	end

	table.insert(self.Props, ent)

	return true
end

local nextthink = 0

hook.Add("Think", "ParentSetter", function()
	if (nextthink > CurTime()) then return end
	nextthink = CurTime() + 0.1

	for i, ent in pairs(ents.GetAll()) do
		if (!IsValid(ent) or !ent.parentpos or IsValid(ent:GetParent())) then continue end

		--ent.parentpos = ent:WorldToLocal(parent:GetPos())

		local parent = ent.parent

		if !IsValid(parent) then continue end

		ent:GetPhysicsObject():Wake()

		ent:SetAngles( ent.parentangle + parent:GetAngles() )
		ent:SetPos( parent:LocalToWorld(ent.parentpos) )

		ent.parent = nil
		ent.parentpos = nil

		ent:GetPhysicsObject():Sleep()
	end
end)

function TOOL:RightClick(tr)
	if CLIENT then return true end

	if (self.Working) then return false end
	self.Working = true

	local ply = self:GetOwner()

	if (!self.Props or table.Count(self.Props) == 0) then
		ply:PrintMessage(HUD_PRINTTALK, "No props selected.")
		return false
	end

	local Shadow = self:GetClientNumber("shadow") == 1
	local Physics = self:GetClientNumber("physics") == 1
	local NoCollide = self:GetClientNumber("collide") == 1

	undo.Create('easy_parent')

	local parent = table.GetFirstValue(self.Props)

	for _id, ent in pairs(self.Props or {}) do
		if (Shadow) then ent:DrawShadow(false) end

		if (ent == parent or parent:GetParent() == ent) then continue end --no no no

		if !(ent:IsVehicle()) then --cant parent a vehicle or it crashes the game >:(

			ent.parentangle = parent:GetAngles() - ent:GetAngles()
			ent.parentpos = parent:WorldToLocal(ent:GetPos())
			ent.parent = parent

			--timer.Simple(0.5, ent.SetParent, ent, parent) --save the parent selection

			ent:SetParent(parent)

			undo.AddFunction(function()
				ent:SetParent() --clear parent
				ent.parentpos = nil
			end)
		else
			ply:PrintMessage(HUD_PRINTTALK, "Pods/vehicles can not be parented so it was welded instead.")
		end

		if (Physics || ent:IsVehicle()) then  --keep physics
			local weld = constraint.Weld(parent, ent, 0, 0, 0)
			undo.AddEntity( weld )
		end

		if( NoCollide == 1 ) then
			local collide = constraint.NoCollide(parent, ent, 0, 0)
			undo.AddEntity( collide )
		end
	end

	ply:PrintMessage(HUD_PRINTTALK, "Props parented: " .. tostring(table.Count(self.Props)))

	self:ClearAll()

	undo.SetPlayer( ply )
	undo.Finish()

	ply:AddCleanup( "easy_parent", ent )

	self.Working = false

	return true
end

function TOOL:Reload(tr)
	if (CLIENT) then return end

	local ply = self:GetOwner()

	local ent = tr.Entity
	local nums = 0
	local success = false

	if (ent and ValidEntity(ent)) then
		if (ValidEntity(ent:GetParent())) then
			ply:PrintMessage(HUD_PRINTTALK, "Parent removed.")
		end

		ent:SetParent() --removes any parent

		for _, _ent in pairs( ents.GetAll() ) do
			if ( ValidEntity(_ent:GetParent()) and _ent:GetParent() == ent ) then
				_ent:SetParent() --removes any parent

				nums = nums + 1
			end
		end

		if (nums > 0) then
			ply:PrintMessage(HUD_PRINTTALK, "Children removed: " .. tonumber(nums))
			success = true
		end
	end

	self:ClearAll()

	return success
end

function TOOL:Holster()
	if CLIENT then return end

	self:ClearAll()

	self.Working = false
end

//if SERVER then return end --done with server stuff
//The above line ruins singleplayer

if ( CLIENT ) then
    TOOL.Colors = {}

    TOOL.Blacklist = {
        "player",
        "world",
        "func_brush",
        "viewmodel",
        "worldspawn",
        "func_rotating",
        "physgun_beam",
        "beam_drawer2b",
        "class CLuaEffect",
        "class C_BaseFlex",
        "class C_PlayerResource",
        "manipulate_flex",
        "phys_constraintsystem",
        "info_player_start",
        "predicted_viewmodel",
        "bodyque",
        "weapon"
    }

    function TOOL:DrawHUD()

        for _, ent in pairs( self.Ents or {} ) do
            if (!IsValid(ent) or !IsValid(ent:GetParent())) then continue end

            local distance = LocalPlayer():GetPos():Distance(ent:GetPos())
            local pos = (ent:GetPos() + ent:OBBCenter()):ToScreen()
            local a = 180

            surface.SetDrawColor( Color(100,255,100,a) )
            surface.DrawPoly{
                {x=pos.x,y=pos.y};
                {x=pos.x-23,y=pos.y-18};
                {x=pos.x+23,y=pos.y-18};
            }
            surface.SetDrawColor( Color(0,0,0,a/2) )
            surface.DrawRect(pos.x-23,pos.y-35,46,18)

            draw.DrawText("Child","CenterPrintText",pos.x,pos.y - 35,Color(255,255,255,a),1)
        end
    end

    function TOOL:Think()
        if ((self.NextThink or 0) < CurTime()) then
            self.NextThink = CurTime() + 0.1
        end

        local tr = self:GetOwner():GetEyeTrace()
        local parent = tr.Entity

        self:ClearColors()

        if !IsValid(parent) or parent:IsWorld() then
            self.Ents = {}
            return
        else
            self.Ents = ents.GetAll()

            for _i, ent in pairs( self.Ents or {} ) do
                if !IsValid(ent) then
                    self.Ents[_i] = nil
                    continue
                end

                if (ent:GetParent() != parent or table.HasValue(self.Blacklist, ent:GetClass())) then
                    self.Ents[_i] = nil
                    continue
                end

                --if (!IsValid(ent) or !IsValid(ent:GetParent()) or ent:IsWorld() or table.HasValue(self.Blacklist, ent:GetClass()) or ent:IsWeapon()) then
                --	self.Ents[_i] = nil
                --continue end

                if (!self.Colors[ent]) then self.Colors[ent] = ent:GetColor() end --save old color

                ent:SetColor( Color(255, 255, 0, 200) ) --gren
            end
        end
    end

    function TOOL:Holster()
        self:ClearColors()
    end

    function TOOL:ClearColors()
        for ent,v in pairs( self.Colors ) do
            if ValidEntity(ent) then ent:SetColor( v ) end
            self.Colors[ent] = nil
        end

        self.Colors = {}
    end


    function TOOL.BuildCPanel( CPanel )
        CPanel:AddControl( "Label", { Text = "The first prop you select, is the parent prop, all other props will be parented to the first prop. Right click to finish the operation. To add more props, start a new operation, select the same parent prop as before and add further ones.", Description  = "Text" }  )
        CPanel:AddControl( "Label", { Text = "If done correctly you can have lag free contraptions.", Description  = "Text" }  )

        CPanel:AddControl( "Label", { Text = "", Description	= "space" }  )

        CPanel:AddControl( "CheckBox", { Label = "Disable Shadow", Command = "easy_parent_shadow" }  )
        CPanel:AddControl( "CheckBox", { Label = "NoCollide Props", Command = "easy_parent_collide" }  )
        CPanel:AddControl( "CheckBox", { Label = "Keep Physics on children.", Command = "easy_parent_physics" }  )
    end

end