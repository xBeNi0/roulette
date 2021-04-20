SMX = nil
local animSeating = false
local focusLock = false
local spawnedPeds = {}
Citizen.CreateThread(function()
	while SMX == nil do
		TriggerEvent('smx:getSharedObject', function(obj)
			SMX = obj 
		end)
		Citizen.Wait(0)
	end
	Citizen.CreateThread(CreatePeds)
	local wait = 100
	while true do
		if animSeating then
			wait = 1
			DisableAllControlActions(0)
			DisableAllControlActions(2)
			DisableAllControlActions(3)
		else
			wait = 100
		end
		Citizen.Wait(wait)
	end
end)
local seatSideAngle = 30
local game_during = false
local currentType = 'gray'
local currentHigh = false
local currentCoords = nil
local currentRot = nil
local cam = nil

local extraObjects = {
	{
		model = 623773339,
		coords = {x = 942.22808837891, y = 55.389007568359, z = 74.986679077148, h = 148.00003051758},
		color = 3,
		highStakes = true,
		rot = 212.0
	},
	{
		model = 623773339,
		coords = {x = 943.89141845703, y = 58.553730010986, z = 74.986679077148, h = 58.000038146973},
		color = 3,
		highStakes = true,
		rot = 302.0
	},
	{
		model = 623773339,
		coords = {x = 945.75830078125, y = 53.351531982422, z = 74.986679077148, h = 238.00006103516},
		color = 0,
		highStakes = false,
		rot = 122.0
	},
	{
		model = 623773339,
		coords = {x = 947.53674316406, y = 56.885509490967, z = 74.986679077148, h = 328.00003051758},
		color = 0,
		highStakes = false,
		rot = 32.0
	},
}

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(5000)
		ChangeTextures()
	end
end)

function ChangeTextures()
	for k,v in next, extraObjects do
		local tempTable = GetClosestObjectOfType(v.coords.x, v.coords.y, v.coords.z, 3.0, v.model, false, false, false)
		SetObjectTextureVariant(tempTable, v.color or 3)
	end
end

function findRotation( x1, y1, x2, y2 ) 
    local t = -math.deg( math.atan2( x2 - x1, y2 - y1 ) )
    return t < -180 and t + 180 or t
end

Citizen.CreateThread(function()
	RequestAnimDict("anim_casino_b@amb@casino@games@shared@player@")
	ChangeTextures()
	ProcessTables()
end)

function ProcessTables()
	while true do Wait(0)
		local playerPed = PlayerPedId()
		if not IsEntityDead(playerPed) and not animSeating then
			local pCoords = GetEntityCoords(PlayerPedId())
			if extraObjects ~= nil then
				for i,v in next, extraObjects do
					local cord = v.coords
					local highStakes = v.highStakes
					local camRot = v.rot
					if GetDistanceBetweenCoords(cord.x, cord.y, cord.z, pCoords.x, pCoords.y, pCoords.z, true) < 3.0 then
						local tableObj = GetClosestObjectOfType(pCoords, 1.5, 623773339, false, false, false)
						if GetEntityCoords(tableObj) ~= vector3(0.0, 0.0, 0.0) then
							local rouletteChair = 1
							local coords = GetWorldPositionOfEntityBone(tableObj, GetEntityBoneIndexByName(tableObj, "Chair_Base_0"..rouletteChair))
							local rot = GetWorldRotationOfEntityBone(tableObj, GetEntityBoneIndexByName(tableObj, "Chair_Base_0"..rouletteChair))
							local dist = GetDistanceBetweenCoords(coords, pCoords, true)
							for i=1,4 do
								local coords = GetWorldPositionOfEntityBone(tableObj, GetEntityBoneIndexByName(tableObj, "Chair_Base_0"..i))
								if GetDistanceBetweenCoords(coords, pCoords, true) < dist then
									dist = GetDistanceBetweenCoords(coords, pCoords, true)
									rouletteChair = i
								end
							end
							local coords = GetWorldPositionOfEntityBone(tableObj, GetEntityBoneIndexByName(tableObj, "Chair_Base_0"..rouletteChair))
							local rot = GetWorldRotationOfEntityBone(tableObj, GetEntityBoneIndexByName(tableObj, "Chair_Base_0"..rouletteChair))
							local angle = rot.z-findRotation(coords.x, coords.y, pCoords.x, pCoords.y)+90.0
							local seatAnim = "sit_enter_"
							if angle > 0 then seatAnim = "sit_enter_left" end
							if angle < 0 then seatAnim = "sit_enter_right" end
							if angle > seatSideAngle or angle < -seatSideAngle then seatAnim = seatAnim .. "_side" end
							local canSit = true
							local pedNearby, pedDistance = SMX.Game.GetClosestPlayer(g2_coords)
							if pedNearby == -1 or pedDistance > 1.2 then
								canSit = true
							else
								canSit = false
							end
							if GetDistanceBetweenCoords(coords, pCoords, true) < 1.5 and canSit then
								if highStakes then
									SMX.ShowHelpNotification("~INPUT_CONTEXT~ Zagraj w Ruletkę na wysokie stawki")
								else
									SMX.ShowHelpNotification("~INPUT_CONTEXT~ Zagraj w Ruletkę na niskie stawki")
								end
							end
							if canSit then
								if IsControlJustPressed(1, 51) then
									if canSit then
										--SMX.TriggerServerCallback('smx_casino_handler:checkPerm', function(perm)
											--if perm then
												animSeating = true
												local initPos = GetAnimInitialOffsetPosition("anim_casino_b@amb@casino@games@shared@player@", seatAnim, coords, rot, 0.01, 2)
												local initRot = GetAnimInitialOffsetRotation("anim_casino_b@amb@casino@games@shared@player@", seatAnim, coords, rot, 0.01, 2)
												TaskGoStraightToCoord(PlayerPedId(), initPos, 1.0, 5000, initRot.z, 0.01)
												Wait(250)
												print(initPos.x, initPos.y, initPos.z)
												SetEntityCoords(PlayerPedId(), initPos)
												SetEntityHeading(PlayerPedId(), initRot)
												Wait(50)
												SetCurrentPedWeapon(GetPlayerPed(-1),GetHashKey("WEAPON_UNARMED"),true)
												local scene = NetworkCreateSynchronisedScene(coords, rot, 2, true, true, 1065353216, 0, 1065353216)
												NetworkAddPedToSynchronisedScene(PlayerPedId(), scene, "anim_casino_b@amb@casino@games@shared@player@", seatAnim, 2.0, -2.0, 13, 16, 1148846080, 0)
												NetworkStartSynchronisedScene(scene)
												local scene = NetworkConvertSynchronisedSceneToSynchronizedScene(scene)
												repeat Wait(0) until GetSynchronizedScenePhase(scene) >= 0.99 or HasAnimEventFired(PlayerPedId(), 2038294702) or HasAnimEventFired(PlayerPedId(), -1424880317)
												Wait(1000)
												scene = NetworkCreateSynchronisedScene(coords, rot, 2, true, true, 1065353216, 0, 1065353216)
												NetworkAddPedToSynchronisedScene(PlayerPedId(), scene, "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 2.0, -2.0, 13, 16, 1148846080, 0)
												NetworkStartSynchronisedScene(scene)
												repeat Wait(0) until IsEntityPlayingAnim(PlayerPedId(), "anim_casino_b@amb@casino@games@shared@player@", "idle_cardgames", 3) == 1
												local type = 'low'
												if highStakes then
													type = 'high'
												end
												local g2_rot = rot
												local g2_coords = coords
												TriggerEvent('smx_roulette:openTable', type, g2_coords, g2_rot, GetEntityCoords(tableObj), v.rot, highStakes)
												--TriggerEvent('smx_roulette:openTable', type, coords, rot, tableCoords, camRot, high)
											--[[else
												SMX.ShowNotification("Kasyno jest teraz w fazie testów!")
											end
										end)]]
									else
										SMX.ShowNotification("To miejsce jest zajęte!")
									end
								end
							end
							break
						end
					end
				end
			end
		end
	end
end

function CreatePeds()
	if not HasAnimDictLoaded("anim_casino_b@amb@casino@games@blackjack@dealer") then
		RequestAnimDict("anim_casino_b@amb@casino@games@blackjack@dealer")
		repeat Wait(0) until HasAnimDictLoaded("anim_casino_b@amb@casino@games@blackjack@dealer")
	end
	if not HasAnimDictLoaded("anim_casino_b@amb@casino@games@shared@dealer@") then
		RequestAnimDict("anim_casino_b@amb@casino@games@shared@dealer@")
		repeat Wait(0) until HasAnimDictLoaded("anim_casino_b@amb@casino@games@shared@dealer@")
	end
	if not HasAnimDictLoaded("anim_casino_b@amb@casino@games@blackjack@player") then
		RequestAnimDict("anim_casino_b@amb@casino@games@blackjack@player")
		repeat Wait(0) until HasAnimDictLoaded("anim_casino_b@amb@casino@games@blackjack@player")
	end
	local chips = {}				
	local hand = {}
	local splitHand = {}
	local handObjs = {}
	for i,v in next, extraObjects do
		local tempTable = GetClosestObjectOfType(v.coords.x, v.coords.y, v.coords.z, 2.0, 623773339, false, false, false)
		SetObjectTextureVariant(tempTable, v.color or 3)
		local model = 's_m_y_casino_01'
		chips[i] = {}	
		for x=1,4 do
			chips[i][x] = {}
		end
		handObjs[i] = {}	
		for x=1,4 do
			handObjs[i][x] = {}
		end
		if not HasModelLoaded(model) then
			RequestModel(model)
			repeat Wait(0) until HasModelLoaded(model)
		end
		local dealer = acCreatePed(4, model, v.coords.x, v.coords.y, v.coords.z, v.coords.h, false, true)
		SetEntityCanBeDamaged(dealer, false)
		SetBlockingOfNonTemporaryEvents(dealer, true)
		SetPedCanRagdollFromPlayerImpact(dealer, false)
		SetPedResetFlag(dealer, 249, true)
		SetPedConfigFlag(dealer, 185, true)
		SetPedConfigFlag(dealer, 108, true)
		SetPedConfigFlag(dealer, 208, true)	
		--SetDealerOutfit(dealer, i+6)
		local ped = dealer
		local face = math.random(1,5)
		local hair = math.random(1,5)
		local torso = 1
		SetPedComponentVariation(ped, 0, face, 0, 0)
		SetPedComponentVariation(ped, 1, 1, 0, 0)
		SetPedComponentVariation(ped, 2, hair, 0, 0)
		SetPedComponentVariation(ped, 3, 1, 4, 0)
		SetPedComponentVariation(ped, 4, 0, 0, 0)
		SetPedComponentVariation(ped, 6, 1, 0, 0)
		SetPedComponentVariation(ped, 7, 2, 0, 0)
		SetPedComponentVariation(ped, 8, 3, 0, 0)
		SetPedComponentVariation(ped, 10, 1, 0, 0)
		SetPedComponentVariation(ped, 11, 1, 0, 0)
		SetPedPropIndex(ped, 1, 0, 0, false)
		local scene = CreateSynchronizedScene(v.coords.x, v.coords.y, v.coords.z, 0.0, 0.0, v.coords.h, 2)
		TaskSynchronizedScene(dealer, scene, "anim_casino_b@amb@casino@games@shared@dealer@", "idle", 1000.0, -8.0, 4, 1, 1148846080, 0)		
		spawnedPeds[i] = dealer
	end
end

RegisterNetEvent('smx_roulette:openTable')
AddEventHandler('smx_roulette:openTable', function(type, coords, rot, tableCoords, camRot, high)
	if cam ~= nil then
		DestroyCam(cam)
		cam = nil
	end
	print(camRot)
	if type == 'low' then
		currentType = '#123937'
	else
		currentType =  '#9062a4'
	end
	currentCoords = coords
	currentRot = rot
	currentHigh = high
	cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", tableCoords.x, tableCoords.y, tableCoords.z + 3.0, -90.0, camRot, 0.0, 60.0, 2, 2)
	--PointCamAtCoord(cam, tableCoords.x, tableCoords.y, tableCoords.z)
    SetCamActive(cam, true)
	RenderScriptCams(true, true, 500, true, true)
	Citizen.Wait(350)
	Run()
end)

function Run()
	SMX.TriggerServerCallback('smx_roulette:check_money', function(quantity)
		if quantity >= 10 then
			SendNUIMessage({
				type = "show_table",
				zetony = quantity,
				low = currentType,
				max = currentHigh
			})
			focusLock = true
			SetNuiFocus(true, true)
		else
			SMX.ShowNotification('Potrzebujesz conajmniej 10 żetonów aby zagrać!')
			exit()
			SendNUIMessage({
				type = "reset_bet"
			})
		end
	end, '')
end

function exit()
	SetNuiFocus(false, false)
	focusLock = false
    SetCamActive(cam, false)
	RenderScriptCams(false, true, 500, true, true)
	cam = nil
	local scene = NetworkCreateSynchronisedScene(currentCoords, currentRot, 2, false, false, 1065353216, 0, 1065353216)
	NetworkAddPedToSynchronisedScene(PlayerPedId(), scene, "anim_casino_b@amb@casino@games@shared@player@", "sit_exit_left", 2.0, -2.0, 13, 16, 1148846080, 0)
	NetworkStartSynchronisedScene(scene)
	Wait(math.floor(GetAnimDuration("anim_casino_b@amb@casino@games@shared@player@", "sit_exit_left")*800))
	ClearPedTasks(PlayerPedId())
	currentType = 'gray'
	currentHigh = false
	currentCoords = nil
	currentRot = nil
	animSeating = false
	EnableAllControlActions(0)
	EnableAllControlActions(2)
	EnableAllControlActions(3)
end

RegisterNUICallback('exit', function(data, cb)
	exit()
	cb('ok')
end)

RegisterNUICallback('betup', function(data, cb)
	TriggerServerEvent('smx_sound-system-SV:PlayOnSource', 'betup', 1.0)
	cb('ok')
end)

RegisterNUICallback('roll', function(data, cb)
	if data.kwota > 0 then
		TriggerEvent('smx_roulette:start_game', data.kolor, data.kwota)
	else
		SMX.ShowNotification('Musisz postawić konkretną liczbę żetonów!')
	end
	cb('ok')
end)

RegisterNetEvent('smx_roulette:start_game')
AddEventHandler('smx_roulette:start_game', function(action, amount)
	local amount = amount
	if game_during == false then
		TriggerServerEvent('smx_roulette:removemoney', amount)
		local kolorBetu = ''
		if action == 'black' then
			kolorBetu = 'czarne'
		elseif action == 'red' then
			kolorBetu = 'czerwone'
		elseif action == 'green' then
			kolorBetu = 'zielony'
		end
		TriggerEvent('smx_notify:clientNotify', {text = "Założono "..amount.." żetonów na "..kolorBetu, type='casino'})
		game_during = true
		SMX.TriggerServerCallback('smx_roulette:getRandomNumber', function(randomNumber)
			--local randomNumber = 0
			SendNUIMessage({
				type = "show_roulette",
				hwButton = randomNumber,
				low = currentType,
				max = currentHigh
			})
			TriggerServerEvent('smx_sound-system-SV:PlayOnSource', 'ruletka', 1.0)
			Citizen.Wait(10000)
			local red = {32,19,21,25,34,27,36,30,23,5,16,1,14,9,18,7,12,3}
			local black = {15,4,2,17,6,13,11,8,10,24,33,20,31,22,29,28,35,26}
			local function has_value (tab, val)
				for index, value in ipairs(tab) do
					if value == val then
						return true
					end
				end
				return false
			end
			if action == 'black' then
				if has_value(black, randomNumber) then
					local win = amount * 2
					SMX.ShowNotification('Wygrana: '..win..' żetonów. Gratulacje!')
					TriggerServerEvent('smx_roulette:givemoney', action, amount)
				else
					SMX.ShowNotification('Tym razem nie udało Ci się wygrać!')
				end
			elseif action == 'red' then
				local win = amount * 2
				if has_value(red, randomNumber) then
					SMX.ShowNotification('Wygrana: '..win..' żetonów. Gratulacje!')
					TriggerServerEvent('smx_roulette:givemoney', action, amount)
				else
					SMX.ShowNotification('Tym razem nie udało Ci się wygrać!')
				end
			elseif action == 'green' then
				local win = amount * 14
				if randomNumber == 0 then
					SMX.ShowNotification('Wygrana: '..win..' żetonów. Gratulacje!')
					TriggerServerEvent('smx_roulette:givemoney', action, amount)
				else
					SMX.ShowNotification('Tym razem nie udało Ci się wygrać!')
				end
			end
			--TriggerServerEvent('roulette:givemoney', randomNumber)
			SendNUIMessage({type = 'hide_roulette'})
			SetNuiFocus(false, false)
			focusLock = false
			Run()
			--SMX.ShowNotification('Gra end!')
			game_during = false
		end, action)
	else
		SMX.ShowNotification('Trwa losowanie...')
	end
end)

Citizen.CreateThread(function()
    -- Update every frame
    while true do
        Citizen.Wait(0)
        if focusLock == true then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 4, true)
            DisableControlAction(0, 6, true)
            DisableControlAction(0, 12, true)
            DisableControlAction(0, 13, true)
            DisableControlAction(0, 177, true)
            DisableControlAction(0, 200, true)
            DisableControlAction(0, 202, true)
            DisableControlAction(0, 322, true)
            DisableControlAction(0, 18, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 66, true)
            DisableControlAction(0, 67, true)
            DisableControlAction(0, 68, true)
            DisableControlAction(0, 69, true)
            DisableControlAction(0, 70, true)
            DisableControlAction(0, 91, true)
            DisableControlAction(0, 92, true)
            DisableControlAction(0, 95, true)
            DisableControlAction(0, 98, true)
            DisableControlAction(0, 106, true)
            DisableControlAction(0, 114, true)
            DisableControlAction(0, 122, true)
            DisableControlAction(0, 135, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 144, true)
            DisableControlAction(0, 176, true)
            DisableControlAction(0, 177, true)
            DisableControlAction(0, 222, true)
            DisableControlAction(0, 223, true)
            DisableControlAction(0, 229, true)
            DisableControlAction(0, 237, true)
            DisableControlAction(0, 238, true)
		end
	end
end)