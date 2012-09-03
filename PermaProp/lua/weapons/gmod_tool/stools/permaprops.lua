if SERVER then
	AddCSLuaFile("permaprops.lua")
end

TOOL.Name = "#PermaProps"
TOOL.Category = "Construction"
TOOL.Command = nil
TOOL.ConfigName = "" 

//TOOL.ClientConVar[""] = ""
TOOL.ClientConVar["r"] = "255"
TOOL.ClientConVar["g"] = "0"
TOOL.ClientConVar["b"] = "0"
TOOL.ClientConVar["a"] = "255"

if SERVER then
	hook.Add("Think","CheckTool",function()
		for _,v in pairs(player.GetAll()) do
			v:SetNWBool("PermaPropsInUse", (v:IsConnected() and v:Alive() and v:GetActiveWeapon():GetClass() == "gmod_tool" and v:GetTool() and v:GetTool().Mode == "permaprops" ))
		end
	end)
end

if CLIENT then
	language.Add( "Tool_permaprops_name", "PermaProps" )
	language.Add( "Tool_permaprops_desc", "Save a prop for server restarts" )
	language.Add( "Tool_permaprops_0", "Left click: make permanent; Right click: make temporary; Reload: update permanent entity" )
	
	local ent_colors = {}

	hook.Add("PreDrawOpaqueRenderables","DrawPermaColors",function()
		if LocalPlayer():GetNWBool("PermaPropsInUse") then
			//local customcolor = { TOOL:GetClientNumber("r",255), TOOL:GetClientNumber("g",0), TOOL:GetClientNumber("r",0), TOOL:GetClientNumber("a",255) }
			local all = ents.GetAll()
			for k,v in pairs(all) do if table.HasValue(PERMA.Blacklist,string.lower(v:GetClass())) then all[k] = nil end end
			for _,v in pairs( all ) do
				local col = {v:GetColor()}
				if not ent_colors[v] or (ent_colors[v] and v:GetNWBool("isperma") and col[4] == 100) then
					ent_colors[v] = {v:GetColor()}
					if v:GetNWBool("isperma") then
						v:SetColor( 255, 0, 0, 255 )
						if col[4] == 100 then ent_colors[v][4] = 255 end
					else
						local r, g, b = v:GetColor()
						v:SetColor( r, g, b, 100 )
					end
				elseif ent_colors[v] and not v:GetNWBool("isperma") and col[4] == 255 then
					v:SetColor(ent_colors[v][1],ent_colors[v][2],ent_colors[v][3],100)
				else
					if v:GetNWBool("isperma") then
						v:SetColor( 255, 0, 0, 255 )
					else
						local r, g, b = v:GetColor()
						v:SetColor( r, g, b, 100 )
					end
				end
			end
		else
			for k,v in pairs( ent_colors ) do
				if ValidEntity(k) then k:SetColor( unpack(v) ) end
				ent_colors[k] = nil
			end
		end
	end)
	
	hook.Add("HUDPaint","DrawPermaHUD",function()
		if LocalPlayer():GetNWBool("PermaPropsInUse") then
			for k,v in pairs(ent_colors) do
				if k:GetNWBool("isperma") then
					local pos = (k:GetPos() + k:OBBCenter()):ToScreen()
					surface.SetDrawColor( Color(100,100,100,200) )
					surface.DrawPoly{
						{x=pos.x,y=pos.y};
						{x=pos.x-23,y=pos.y-15};
						{x=pos.x+23,y=pos.y-15};
					}
					surface.SetDrawColor( Color(0,0,0,100) )
					surface.DrawRect(pos.x-23,pos.y-35,46,18)
					draw.DrawText("Perma","ScoreboardText",pos.x,pos.y - 35,Color(255,255,255,200),1)
				end
			end
		end
	end)
end

function TOOL:LeftClick( tr )
	RunConsoleCommand("perma_save")
	return true
end

function TOOL:RightClick( tr )
	RunConsoleCommand("perma_remove")	
	return true
end

function TOOL:Reload( tr )
	RunConsoleCommand("perma_save","1")
	return true
end

function TOOL.BuildCPanel( panel )
    
	panel:AddControl( "Header"  , { Text = "#Tool_permaprops_name", Description	= "#Tool_permaprops_desc" }  )

	//panel:AddControl( "Color", {Label="Entity Identifier Color", Description = "Entit Identifier Color", Red = "permaprops_r", Green="permaprops_g", Blue="permaprops_b", Alpha="permaprops_a", ShowAlpha="1", ShowHSV = "1", ShowRGB = "1", Multiplier = "255"} )
	//panel:AddControl( "ListBox", { Label = "Current PermaProps", Description = "Test?", MenuButton = false, Height = 200, Options = { ["Stuff1"] = {}, ["Stuff2"] = {} } }) 
	
end
