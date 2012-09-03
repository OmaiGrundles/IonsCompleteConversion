TOOL.Category		= "Constraints"
TOOL.Name			= "#All Constraints Remover"
TOOL.Command		= nil
TOOL.ConfigName		= ""

if CLIENT then
    language.Add( "Tool.all_constraints_remover.name", "All Constraints Remover" )
    language.Add( "Tool.all_constraints_remover.desc", "Removes the specified type of constraint from an entity" )
    language.Add( "Tool.all_constraints_remover.0", "Left click on an entity to remove all constraints of selected type, right click to remove any type" )
	language.Add( "Tool.all_constraints.type", "Constraint type:" )
end

TOOL.ClientConVar[ "constraint_type" ] = "Weld"

function TOOL:LeftClick( trace )

	local constraint_type = self:GetClientInfo( "constraint_type" )
	
	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end
	
	// If theres no physics object then we cant remove constraints from it
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end
	
	constraint.RemoveConstraints( trace.Entity, constraint_type )
	
	return true
	
end

function TOOL:RightClick( trace )

	if ( trace.Entity:IsValid() && trace.Entity:IsPlayer() ) then return end

	// If there's no physics object then we can't remove constraints from it
	if ( SERVER && !util.IsValidPhysicsObject( trace.Entity, trace.PhysicsBone ) ) then return false end

    constraint.RemoveConstraints( trace.Entity, "Weld" )
	constraint.RemoveConstraints( trace.Entity, "Rope" )
	constraint.RemoveConstraints( trace.Entity, "AdvBallsocket" )
	constraint.RemoveConstraints( trace.Entity, "Axis" )
	constraint.RemoveConstraints( trace.Entity, "Ballsocket" )
	constraint.RemoveConstraints( trace.Entity, "Elastic" )
	constraint.RemoveConstraints( trace.Entity, "Hydraulic" )
	constraint.RemoveConstraints( trace.Entity, "KeepUpright" )
	constraint.RemoveConstraints( trace.Entity, "Muscle" )
	constraint.RemoveConstraints( trace.Entity, "Pulley" )
	constraint.RemoveConstraints( trace.Entity, "Winch" )
	constraint.RemoveConstraints( trace.Entity, "Slider" )

	return true
end

function TOOL.BuildCPanel( panel )
	panel:AddControl( "Header", { Text = "#Tool.all_constraints_remover.name", Description = "#Tool.all_constraints_remover.desc" } )
	
	panel:AddControl("ComboBox", {
	Label = "#Tool.all_constraints.type",
	MenuButton = "0",
	Options = {
		["#Weld"] = { all_constraints_remover_constraint_type = "Weld" },
		["#Rope"] = { all_constraints_remover_constraint_type = "Rope" },
		//["#NoCollide"] = { all_constraints_remover_constraint_type = "NoCollide" }, // Doesnt remove
		["#AdvBallsocket"] = { all_constraints_remover_constraint_type = "AdvBallsocket" },
		["#Axis"] = { all_constraints_remover_constraint_type = "Axis" },
		["#Ballsocket"] = { all_constraints_remover_constraint_type = "Ballsocket" },
		["#Elastic"] = { all_constraints_remover_constraint_type = "Elastic" },
		["#Hydraulic"] = { all_constraints_remover_constraint_type = "Hydraulic" },
		["#KeepUpright"] = { all_constraints_remover_constraint_type = "Keepupright" },
		//["#Motor"] = { all_constraints_remover_constraint_type = "Motor" }, // Doesnt remove (disables the motor, but keeps the axis)
		["#Muscle"] = { all_constraints_remover_constraint_type = "Muscle" },
		["#Pulley"] = { all_constraints_remover_constraint_type = "Pulley" },
		["#Winch"] = { all_constraints_remover_constraint_type = "Winch" },
		["#Slider"] = { all_constraints_remover_constraint_type = "Slider" }
	}
	})
	
end
