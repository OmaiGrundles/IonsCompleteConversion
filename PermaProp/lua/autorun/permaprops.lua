/*
	PermaProps
	Created by Entoros, June 2010
	Facepunch: http://www.facepunch.com/member.php?u=180808
	
	Ideas:
		Make permaprops cleanup-able
		
	Errors:
		Errors on die
*/

if not glon then require("glon") end

PERMA = {}
PERMA.Pos = {}
PERMA.File = "permaprops.txt"
PERMA.Blacklist = {
	"player",
	"world",
	"func_brush",
}

//cleanup.Register("permaprops")

if SERVER then
	AddCSLuaFile("permaprops.lua");
	
	function PERMA:Initialize()
		self:LoadFromFile()
		
		for _,v in pairs( ents.GetAll() ) do
			if v:GetNWBool("isperma") then v:Remove() end
		end
		
		for _,v in pairs( self.Pos ) do
			if game.GetMap() == v.map then
				local e = ents.Create( v.class )
				e:SetNWBool( "isperma", true )
				e:SetPos( v.pos )
				e:SetAngles( v.ang )
				e:SetColor( v.color.r, v.color.g, v.color.b, v.color.a )
				e:SetModel( v.model )
				e:SetMaterial( v.material )
				e:SetSkin( v.skin )
				e:SetSolid( v.solid )
				e:SetName( v.name )
				e:Spawn()
				e:Activate()
				
				local phys = e:GetPhysicsObject()
				if IsValid( phys ) then phys:Sleep() end
			end
		end
		
		concommand.Add("perma_save",function(pl,cmd,args)
			if not pl:IsAdmin() then return end
			
			local update = tobool(args[1])
			local e = pl:GetEyeTrace().Entity
			if not ValidEntity( e ) then pl:ChatPrint("That is not a valid entity!") return end
			if table.HasValue( self.Blacklist, e ) then pl:ChatPrint("That is a blacklisted entity!") return end
			if e:GetNWBool("isperma") and not update then pl:ChatPrint("That entity is already permanent!") return end
			
			if update then
				if not e:GetNWBool("isperma") then pl:ChatPrint("That entity is not permanent yet.") return end
				self:UpdateEnt( e ) 
				pl:ChatPrint("You updated the " .. e:GetClass() .. " you selected in the database.")
			else 
				self:SaveEnt( e )
				pl:ChatPrint("You saved " .. e:GetClass() .. " with model ".. e:GetModel() .. " to the database.")
			end
		
		end)
		
		concommand.Add("perma_printfile",function()
			PrintTable( glon.decode(file.Read(self.File)))
		end)
		
		concommand.Add("perma_printcurrent",function()
			PrintTable( self.Pos )
		end)
		
		concommand.Add("perma_erase",function( pl )
			if not pl:IsSuperAdmin() then return end
			
			for _,v in pairs( ents.GetAll() ) do
				if v:GetNWBool("isperma") then v:SetName("") end
			end
			
			file.Write(self.File,glon.encode({}))
			self.Pos = {}
			
			pl:ChatPrint("Database successfully erased!")
		end)
		
		concommand.Add("perma_remove",function( pl )
			if not pl:IsAdmin() then return end
			
			local e = pl:GetEyeTrace().Entity
			if not ValidEntity( e ) then pl:ChatPrint("That is not a valid entity!") return end
			if not e:GetNWBool("isperma") then pl:ChatPrint("That is not a PermaProp!") return end
			
			self:RemoveEnt( e )
			e:SetNWBool("isperma",false)
			pl:ChatPrint("You erased " .. e:GetClass() .. " with a model of " .. e:GetModel() .. " from the database.")
			
		end)
		
		concommand.Add("perma_isperma",function(pl)
			local e = pl:GetEyeTrace().Entity
			if not ValidEntity( e ) then pl:ChatPrint("That is not a valid entity!") return end
	
			pl:ChatPrint( "That entity is" .. ( not e:GetNWBool("isperma") && " not " || " " ) .. "a PermaProp.")
		end)
		
	end
	
	function PERMA:SaveEnt( ent )
		local col = { ent:GetColor() }
		local info = {
			name = "perma"..table.Count(self.Pos),
			class = ent:GetClass(),
			pos = ent:GetPos(),
			ang = ent:GetAngles(),
			color = Color(col[1],col[2],col[3],col[4]),
			model = ent:GetModel(),
			material = ent:GetMaterial(),
			skin = ent:GetSkin(),
			solid = ent:GetSolid(),
			map = game.GetMap(),
			}
		ent:SetName( info.name )
		ent:SetNWBool("isperma", true )
		self.Pos[info.name] = info
		self:SaveToFile()
	end
	
	function PERMA:UpdateEnt( ent )
		local col = { ent:GetColor() }
		local info = self.Pos[ent:GetName()]
		info.pos = ent:GetPos()
		info.ang = ent:GetAngles()
		info.color = Color(col[1],col[2],col[3],col[4]) // does this break?
		info.model = ent:GetModel()
		info.material = ent:GetMaterial()
		info.skin = ent:GetSkin()
		info.solid = ent:GetSolid()
		self.Pos[ent:GetName()] = info
		self:SaveToFile()
	end
	
	function PERMA:RemoveEnt( ent )
		local name = ent:GetName()
		if not self.Pos[name] then return end
		self.Pos[name] = nil
		self:SaveToFile()
	end
	
	function PERMA:LoadFromFile()
		if not file.Exists(self.File) then file.Write(self.File,glon.encode({}))
		else self.Pos = glon.decode(file.Read(self.File)) end
	end
	
	function PERMA:SaveToFile()
		file.Write(self.File,glon.encode(self.Pos))
	end
	
	hook.Add("InitPostEntity","InitializePermaProps",function() PERMA:Initialize() end)
end

