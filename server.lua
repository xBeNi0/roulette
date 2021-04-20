SMX						= nil
TriggerEvent('smx:getSharedObject', function(obj) SMX = obj end)

RegisterServerEvent('smx_roulette:removemoney')
AddEventHandler('smx_roulette:removemoney', function(amount)
	local amount = amount
	local _source = source
	local xPlayer = SMX.GetPlayerFromId(_source)
	xPlayer.removeInventoryItem('chips', amount)
	TriggerEvent('smx_discordlog:logs', 'casino_roulette', _source, "postawił/a **"..amount.."** żetonów")
end)

RegisterServerEvent('smx_roulette:givemoney')
AddEventHandler('smx_roulette:givemoney', function(action, amount)
	local aciton = aciton
	local amount = amount
	local _source = source
	local xPlayer = SMX.GetPlayerFromId(_source)
	if action == 'black' or action == 'red' then
		local win = amount*2
		xPlayer.addInventoryItem('chips', win)
		TriggerEvent('smx_discordlog:logs', 'casino_roulette', _source, "wygrał/a **"..win.."** żetonów na czerwone/czarne")
	elseif action == 'green' then
		local win = amount*14
		xPlayer.addInventoryItem('chips', win)
		TriggerEvent('smx_discordlog:logs', 'casino_roulette', _source, "wygrał/a **"..win.."** żetonów na zielone")
	else
		TriggerEvent('smx_discordlog:logs', 'casino_roulette', _source, "przegrał/a **"..amount.."** żetonów")
	end
end)

SMX.RegisterServerCallback('smx_roulette:check_money', function(source, cb)
	local _source = source
	local xPlayer = SMX.GetPlayerFromId(_source)
	local quantity = xPlayer.getInventoryItem('chips').count
	
	cb(quantity)
end)

SMX.RegisterServerCallback('smx_roulette:getRandomNumber', function(source, cb, action)
	local red = {32,19,21,25,34,27,36,30,23,5,16,1,14,9,18,7,12,3}
	local black = {15,4,2,17,6,13,11,8,10,24,33,20,31,22,29,28,35,26}
	local canWin = math.random(1, 3)
	if canWin == 1 then
		math.randomseed(os.time())
		Citizen.Wait(200)
		local r = math.floor(math.random() * 36)
		cb(r)
	else
		if action == 'red' then
			local r = math.random(1, #black)
			cb(black[r])
		elseif aciton == 'black' then
			local r = math.random(1, #red)
			cb(red[r])
		else
			local r = math.random(1, #red)
			cb(red[r])
		end
	end
end)