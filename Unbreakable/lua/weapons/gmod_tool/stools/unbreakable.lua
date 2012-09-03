/*******************
 *
 *                              Unbreakable STool
 *
 *
 *   Date   : 28  janvier 2007
 *
 *   Auteur : Chaussette™
 *
 *******************************************************************************/

if( SERVER ) then
    // Comment this line if you don't want to send this stool to clients
    AddCSLuaFile( "weapons/gmod_tool/stools/unbreakable.lua" )
    
    
    local function PlayerInitialSpawn()
        
        FiltreDegats = ents.Create( "filter_activator_name" )
        
        FiltreDegats:SetKeyValue( "targetname", "FiltreDegats" )
        FiltreDegats:SetKeyValue( "negated", "1" )
        FiltreDegats:Spawn()
        
        hook.Remove( "PlayerInitialSpawn", "Unbreakable_PlayerInitialSpawn" )
    end
    hook.Add( "PlayerInitialSpawn", "Unbreakable_PlayerInitialSpawn", PlayerInitialSpawn )
    
    
    
    
    function TOOL:Incassable( Element, Valeur )
        
        local Filtre = ""
        if( Valeur ) then Filtre = "FiltreDegats" end
        
        if( Element && Element:IsValid() ) then
            
            Element:SetVar( "Unbreakable"    , Valeur )
            Element:Fire  ( "setdamagefilter", Filtre, 0 )
        end
    end
    
    
    
    
    function TOOL:Parcourir( Element, Valeur )
        
        if( Element && Element:IsValid() && ( Element:GetVar( "Unbreakable" ) != Valeur )) then
            
            self:Incassable( Element, Valeur )
            
            if( Element.Constraints ) then
                
                for x, Contrainte in pairs( Element.Constraints ) do
                    for x = 1, 4, 1 do
                        
                        if( Contrainte[ "Ent" .. x ] ) then self:Parcourir( Contrainte[ "Ent" .. x ], Valeur ) end
                    end
                end
            end
        end
    end
end


TOOL.Category		= "Constraints"
TOOL.Name			= "#Unbreakable"
TOOL.Command		= nil
TOOL.ConfigName		= ""

TOOL.ClientConVar[ "etendre" ] = "1"


if ( CLIENT ) then
    
    language.Add( "Tool.unbreakable.name", "Unbreakable" )
    language.Add( "Tool.unbreakable.desc", "Make a prop unbreakable" )
    language.Add( "Tool.unbreakable.0", "Left click to make a prop unbreakable. Right click to restore its previous settings" )
    language.Add( "Tool.unbreakable_etendre", "Extend to constrained objects" )
end




function TOOL:Action( Element, Valeur )
    
    if( Element && Element:IsValid() ) then
        
        if( CLIENT ) then return true end
        
        if( self:GetClientNumber( "etendre" ) == 0 ) then
            
            self:Incassable( Element, Valeur )
        else
            
            self:Parcourir( Element, Valeur )
        end
        
        return true
    end
    
    return false
end




function TOOL:LeftClick( Visee )
    
    return self:Action( Visee.Entity, true )
end


function TOOL:RightClick( Visee )
    
    return self:Action( Visee.Entity, false )
end

function TOOL.BuildCPanel( Panneau )
    
    Panneau:AddControl( "Header"  , { Text = "#Tool.unbreakable_name", Description	= "#Tool.unbreakable_desc" }  )
    Panneau:AddControl( "Checkbox", { Label = "#Tool.unbreakable_etendre", Command = "unbreakable_etendre" } )
end
