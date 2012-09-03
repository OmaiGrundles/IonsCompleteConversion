/*

Fin tool II

by Austin "Q42" Fox

This addon is not for stealing. K THX.

*/

fintool = {}

function fintool.initialize()
	fintool.wind = Vector( math.Rand(-360, 360), math.Rand(-360, 360), 0)
	fintool.maxwind = 360
	fintool.minwind = 0
end

hook.Add( "Initialize", "finitialize", fintool.initialize )

function fintool.think()
	fintool.nextthink = fintool.nextthink or CurTime()
	if CurTime() > fintool.nextthink then
		fintool.maxdelay = fintool.maxdelay or 120
		fintool.wind = Vector( math.Rand(fintool.minwind, fintool.maxwind), math.Rand(fintool.minwind, fintool.maxwind), 0)
		fintool.nextthink = fintool.nextthink + math.Rand(0, fintool.maxdelay)
	end
end
hook.Add( "Think", "finthink", fintool.think )

function fintool.setmaxdelay(player,command,arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.maxdelay = arg[1] end
end 
concommand.Add("fintool_setmaxwinddelay",fintool.setmaxdelay)

function fintool.setmaxwind(player,command,arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.maxwind = arg[1] end
end 

concommand.Add("fintool_setmaxwind",fintool.setmaxwind)

function fintool.setminwind(player,command,arg)
	if player:IsAdmin() or player:IsSuperAdmin() then fintool.minwind = arg[1] end
end 

concommand.Add("fintool_setminwind",fintool.setminwind)