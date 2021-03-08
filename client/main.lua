local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57,
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177,
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70,
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["TOP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil

local PlayerData = {}
local HasAlreadyEnteredMarker = false
local LastStation, LastPart, LastPartNum
local CurrentAction = nil
local CurrentActionMsg = ''
local CurrentActionData = {}
local JobBlips = {}

local isProcessing = false

local playerInService = false
local menuOpen = false
local wasOpen = false

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	
	PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	PlayerData = xPlayer
	blips()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	PlayerData.job = job
	deleteBlips()
	blips()
end)

function ShowNotification(text, id)
    SetNotificationTextEntry("STRING")
    SetNotificationBackgroundColor(id)
    AddTextComponentString(text)
    DrawNotification(false, false)
end

function ShowHelpNotification(msg)
	BeginTextCommandDisplayHelp('STRING')
	AddTextComponentSubstringPlayerName(msg)
	EndTextCommandDisplayHelp(0, false, true, -1)
end

RegisterNetEvent("esx_brasseur:notify")
AddEventHandler("esx_brasseur:notify", function(text, id)
    SetNotificationTextEntry("STRING")
    SetNotificationBackgroundColor(id)
    AddTextComponentString(text)
    DrawNotification(false, false)
end)

function SetVehicleMaxMods(vehicle)
	local props = {
		modEngine = 4,
		modBrakes = 3,
		modTransmission = 4,
		modSuspension = 3,
		modTurbo = true,
	}
	
	ESX.Game.SetVehicleProperties(vehicle, props)
end

function OpenCloakroomMenu()

	local playerPed = PlayerPedId()
	local grade = PlayerData.job.grade_name

	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom',
	{
		title    = _U('cloakroom'),
		align    = 'top-left',
		elements = {
			{label = "» ".._U('citizen_wear'), value = 'citizen_wear'},
			{label = "» ".._U('brasseur_wear'), value = 'brasseur_wear'},
		},
	}, function(data, menu)
			menu.close()

			if data.current.value == 'citizen_wear' then
				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					TriggerEvent('skinchanger:loadSkin', skin)
				end)

				if Config.MaxInService ~= -1 then

					ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
						if isInService then

							playerInService = false

							local notification = {
								title    = _U('service_anonunce'),
								subject  = '',
								msg      = _U('service_out_announce', GetPlayerName(PlayerId())),
								iconType = 1
							}

							TriggerServerEvent('esx_service:notifyAllInService', notification, 'brasseur')

							TriggerServerEvent('esx_service:disableService', 'brasseur')
							ShowNotification(_U('service_out'), 130)
						end
					end, 'brasseur')
				end
			end

			if Config.MaxInService ~= -1 and data.current.value == 'brasseur_wear' then
				local serviceOk = 'waiting'

				ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin, jobSkin)
					if skin.sex == 0 then
						TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_male)
					else
						TriggerEvent('skinchanger:loadClothes', skin, jobSkin.skin_female)
					end
				end)

			ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
				if not isInService then

					ESX.TriggerServerCallback('esx_service:enableService', function(canTakeService, maxInService, inServiceCount)
						if not canTakeService then
							ShowNotification(_U('service_max', inServiceCount, maxInService), 130)
						else

							serviceOk = true
							playerInService = true

							local notification = {
								title    = _U('service_anonunce'),
								subject  = '',
								msg      = _U('service_in_announce', GetPlayerName(PlayerId())),
								iconType = 1
							}
	
							TriggerServerEvent('esx_service:notifyAllInService', notification, 'brasseur')
							ShowNotification(_U('service_in'), 110)
						end
					end, 'brasseur')

				else
					serviceOk = true
				end
			end, 'brasseur')

			while type(serviceOk) == 'string' do
				Citizen.Wait(5)
			end

			-- if we couldn't enter service don't let the player get changed
			if not serviceOk then
				return
			end
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'brasseur_actions_menu'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end)
end

function OpenbrasseurActionsMenu()
	local elements = {
        { label = "» ".._U('cloakroom'), value = 'cloakroom'}
	}
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'brasseur_actions',
	{
		title    = 'Brasseur',
		align    = 'top-left',
		elements = elements
	},
		
	function(data, menu)
		if data.current.value == 'cloakroom' then
			OpenCloakroomMenu()
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'brasseur_actions_menu'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end)
end

function OpenVehicleSpawnerMenu(station, partNum)
	ESX.UI.Menu.CloseAll()

	local elements = {}
	
	local sharedVehicles = Config.AuthorizedVehicles.Shared
	
	for i=1, #sharedVehicles, 1 do
		table.insert(elements, { label = sharedVehicles[i].label, model = sharedVehicles[i].model})
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_spawner',
	{
		title = _U('vehicle_menu'),
		align = 'top-left',
		elements = elements
	}, function(data, menu)
		menu.close()
		
		local foundSpawnPoint, spawnPoint = GetAvailableVehicleSpawnPoint(station, partNum)
		
		if foundSpawnPoint then
			if Config.MaxInService == -1 then
				ESX.Game.SpawnVehicle(data.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
					SetVehicleLivery(vehicle, 0)
					TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
					SetVehicleMaxMods(vehicle)
					SetModelAsNoLongerNeeded(vehicle)
				end)
			else
				
				ESX.TriggerServerCallback('esx_service:isInService', function(isInService)
					
					if isInService then
						ESX.Game.SpawnVehicle(data.current.model, spawnPoint.coords, spawnPoint.heading, function(vehicle)
							SetVehicleLivery(vehicle, 0)
							TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
							SetVehicleMaxMods(vehicle)
							SetModelAsNoLongerNeeded(vehicle)
						end)
					else
						ShowNotification(_U('service_not'), 130)
					end
					
				end, 'brasseur')
			end
		end
		
		end, function(data, menu)
		menu.close()
		
		CurrentAction = 'menu_vehicle_spawner'
		CurrentActionMsg = _U('garage_prompt')
		CurrentActionData = {station = station, partNum = partNum}
	end)
end

function GetAvailableVehicleSpawnPoint(station, partNum)
	local spawnPoints = Config.Zones[station].Vehicles[partNum].SpawnPoints
	local found, foundSpawnPoint = false, nil
	
	for i=1, #spawnPoints, 1 do
		if ESX.Game.IsSpawnPointClear(spawnPoints[i], spawnPoints[i].radius) then
			found, foundSpawnPoint = true, spawnPoints[i]
			break
		end
	end
	
	if found then
		return true, foundSpawnPoint
	else
		ShowNotification(_U('vehicle_blocked'), 130)
		return false
	end
end

AddEventHandler('esx_brasseur:hasEnteredMarker' , function(station, part, partNum)
	if part == 'Cloakroom' then
		CurrentAction = 'menu_boss_actions'
		CurrentActionMsg = _U('open_cloackroom')
		CurrentActionData = {}	
	elseif part == 'Vehicles' then
		CurrentAction = 'menu_vehicle_spawner'
		CurrentActionMsg = _U('garage_prompt')
		CurrentActionData = {station = station, partNum = partNum}		
	elseif part == 'VehicleDeleters' then		
		local playerPed = PlayerPedId()

		if IsPedInAnyVehicle(playerPed, false) then		
			local vehicle = GetVehiclePedIsIn(playerPed, false)
			
			if DoesEntityExist(vehicle) then
				CurrentAction = 'delete_vehicle'
				CurrentActionMsg = _U('store_vehicle')
				CurrentActionData = {vehicle = vehicle}
			end			
		end
	end
end)

AddEventHandler('esx_brasseur:hasExitedMarker', function(station, part, partNum)
	ESX.UI.Menu.CloseAll()
	
	CurrentAction = nil
end)

function deleteBlips()
	if JobBlips[1] ~= nil then
		for i=1, #JobBlips, 1 do
			RemoveBlip(JobBlips[i])
			JobBlips[i] = nil
		end
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if GetDistanceBetweenCoords(coords, Config.Zones.Brasseur.Vente.Coords, true) < 1.5 then
			if not menuOpen then
				ESX.ShowHelpNotification(_U('menu_vente'))

				if IsControlJustReleased(0, Keys['E']) then
					if Config.MaxInService == -1 then
						wasOpen = true
						OpenShop()
					elseif playerInService then
						wasOpen = true
						OpenShop()
					else
						ShowNotification(_U('service_not'), 130)
					end	
				end
			else
				Citizen.Wait(500)
			end
		else
			if wasOpen then
				wasOpen = false
				menuOpen = false
				ESX.UI.Menu.CloseAll()
			end

			Citizen.Wait(500)
		end
	end
end)

Citizen.CreateThread(function()	
	for k,v in pairs(Config.Zones) do
		local blip = AddBlipForCoord(v.Blip.Coords)
		
		SetBlipSprite (blip, v.Blip.Sprite)
		SetBlipDisplay(blip, v.Blip.Display)
		SetBlipScale (blip, v.Blip.Scale)
		SetBlipColour (blip, v.Blip.Colour)
		SetBlipAsShortRange(blip, true)
		
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString(_U('map_blip'))
		EndTextCommandSetBlipName(blip)
	end
end)

-- Create Blips
function blips()
	if PlayerData.job ~= nil and PlayerData.job.name == 'brasseur' then
		-- AliveChicken
		for k,v in pairs(Config.Zones.Brasseur)do

			if k == 'Ingredients' then
				local blip = AddBlipForCoord(v.Coords)
				
				SetBlipSprite (blip, v.Sprite)
				SetBlipDisplay(blip, v.Display)
				SetBlipScale (blip, v.Scale)
				SetBlipColour (blip, v.Colour)
				SetBlipAsShortRange(blip, true)
				
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(v.Name)
				EndTextCommandSetBlipName(blip)
				
				table.insert(JobBlips, blip)
			elseif k == 'Fermentation' then
				local blip = AddBlipForCoord(v.Coords)
				
				SetBlipSprite (blip, v.Sprite)
				SetBlipDisplay(blip, v.Display)
				SetBlipScale (blip, v.Scale)
				SetBlipColour (blip, v.Colour)
				SetBlipAsShortRange(blip, true)
				
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(v.Name)
				EndTextCommandSetBlipName(blip)
				
				table.insert(JobBlips, blip)
			elseif k == 'Conditionnement' then
				local blip = AddBlipForCoord(v.Coords)
				
				SetBlipSprite (blip, v.Sprite)
				SetBlipDisplay(blip, v.Display)
				SetBlipScale (blip, v.Scale)
				SetBlipColour (blip, v.Colour)
				SetBlipAsShortRange(blip, true)
				
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(v.Name)
				EndTextCommandSetBlipName(blip)
				
				table.insert(JobBlips, blip)
			elseif k == 'Vente' then
				local blip = AddBlipForCoord(v.Coords)
				
				SetBlipSprite (blip, v.Sprite)
				SetBlipDisplay(blip, v.Display)
				SetBlipScale (blip, v.Scale)
				SetBlipColour (blip, v.Colour)
				SetBlipAsShortRange(blip, true)
				
				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(v.Name)
				EndTextCommandSetBlipName(blip)
				
				table.insert(JobBlips, blip)
			end
		end

	end
end


-- Display markers
Citizen.CreateThread(function()
	while true do
		
		Citizen.Wait(0)
		
		if PlayerData.job ~= nil and PlayerData.job.name == 'brasseur' then
			
			local playerPed = PlayerPedId()
			local coords = GetEntityCoords(playerPed)
			local isInMarker, hasExited, letSleep = false, false, true
			local currentStation, currentPart, currentPartNum
			
			for k,v in pairs(Config.Zones) do
				for i=1, #v.Vehicles, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Vehicles[i].Spawner, true)
					
					if distance < Config.DrawDistance then
						DrawMarker(36, v.Vehicles[i].Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						letSleep = false
					end
					
					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Vehicles', i
					end
				end
				
				
				for i=1, #v.VehicleDeleters, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.VehicleDeleters[i], true)
					
					if distance < Config.DrawDistance then
						DrawMarker(36, v.VehicleDeleters[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 191, 63, 63, 100, false, true, 2, true, false, false, false)
						letSleep = false
					end
					
					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'VehicleDeleters', i
					end
				end
				
				
				for i=1, #v.Ingredients, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Ingredients[i], true)
					
					if distance < Config.DrawDistance then
						DrawMarker(6, v.Ingredients[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						letSleep = false
					end
					
					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Ingredients', i
					end
				end
				
				for i=1, #v.Fermentation, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Fermentation[i], true)
					
					if distance < Config.DrawDistance then
						DrawMarker(6, v.Fermentation[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						letSleep = false
					end
					
					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Fermentation', i
					end
				end
				
				for i=1, #v.Conditionnement, 1 do
					local distance = GetDistanceBetweenCoords(coords, v.Conditionnement[i], true)
					
					if distance < Config.DrawDistance then
						DrawMarker(6, v.Conditionnement[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						letSleep = false
					end
					
					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Conditionnement', i
					end
				end

				for i=1, #v.Vente, 1 do
					
					local distance = GetDistanceBetweenCoords(coords, v.Vente[i], true)
					
					if distance < Config.DrawDistance then
						DrawMarker(29, v.Vente[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.5, 0.5, 0.5, 72, 191, 63, 100, false, true, 2, true, false, false, false)
						letSleep = false
					end
					
					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Vente', i
					end
				end

				for i=1, #v.Cloakroom, 1 do
				
					local distance = GetDistanceBetweenCoords(coords, v.Cloakroom[i], true)
						
					if distance < Config.DrawDistance then
						DrawMarker(22, v.Cloakroom[i], 0.0, 0.0, 0.0, -180.0, 0.0, 0.0, 0.5, 0.5, 0.5, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						letSleep = false
					end
						
					if distance < Config.MarkerSize.x then
						isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Cloakroom', i
					end
				end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				
				if
					(LastStation ~= nil and LastPart ~= nil and LastPartNum ~= nil) and
					(LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('esx_brasseur:hasExitedMarker', LastStation, LastPart, LastPartNum)
					hasExited = true
				end
				
				HasAlreadyEnteredMarker = true
				LastStation             = currentStation
				LastPart                = currentPart
				LastPartNum             = currentPartNum
				
				TriggerEvent('esx_brasseur:hasEnteredMarker', currentStation, currentPart, currentPartNum)
			end
			
			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_brasseur:hasExitedMarker', LastStation, LastPart, LastPartNum)
			end

			if letSleep then
				Citizen.Wait(500)
			end

		else
			Citizen.Wait(500)
		end
	end
end)

RegisterNetEvent('esx_brasseur:progressBars')
AddEventHandler('esx_brasseur:progressBars', function(time, text)
	exports['progressBars']:startUI(time, text)
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(10)
		
		if CurrentAction ~= nil then
			ShowHelpNotification(CurrentActionMsg)
			
			if IsControlJustReleased(0, Keys['E']) and PlayerData.job ~= nil and PlayerData.job.name == 'brasseur' then	

				if CurrentAction == 'menu_vehicle_spawner' then
					if Config.MaxInService == -1 then
						OpenVehicleSpawnerMenu(CurrentActionData.station, CurrentActionData.partNum)
					elseif playerInService then
						OpenVehicleSpawnerMenu(CurrentActionData.station, CurrentActionData.partNum)
					else
						ShowNotification(_U('service_not'), 130)
					end	
				elseif CurrentAction == 'delete_vehicle' then
					ESX.Game.DeleteVehicle(CurrentActionData.vehicle)
					DeleteVehicle(CurrentActionData.vehicle)
				elseif CurrentAction == 'menu_boss_actions' then
					OpenbrasseurActionsMenu()
				end
				
				CurrentAction = nil
			end
		end -- CurrentAction end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = PlayerPedId()
		local coords = GetEntityCoords(playerPed)

		if GetDistanceBetweenCoords(coords, Config.Zones.Brasseur.Ingredients.Coords, true) < 1 then
			if not isProcessing then
				ShowHelpNotification(_U('menu_Ingredients'))
			end
			if IsControlJustReleased(0, Keys['E']) and not isProcessing then
				if Config.MaxInService == -1 then
					ESX.TriggerServerCallback('esx_brasseur:canPickUp', function(canPickUp)
						if canPickUp then
							Process("Ingredients")
						else
							ShowNotification(_U('full_inventory'), 130)
						end
					end, {"houblon", "malte", "levure"})
				elseif playerInService then
					ESX.TriggerServerCallback('esx_brasseur:canPickUp', function(canPickUp)
						if canPickUp then
							Process("Ingredients")
						else
							ShowNotification(_U('full_inventory'), 130)
						end
					end, {"houblon", "malte", "levure"})
				else
					ShowNotification(_U('service_not'), 130)
				end	
			end
		elseif GetDistanceBetweenCoords(coords, Config.Zones.Brasseur.Fermentation.Coords, true) < 1 then
			if not isProcessing then
				ShowHelpNotification(_U('menu_Fermentation'))
			end
			
			if IsControlJustReleased(0, Keys['E']) and not isProcessing then
				if Config.MaxInService == -1 then
					ESX.TriggerServerCallback('esx_brasseur:Count', function(Count)
						if Count then
							Process("Fermentation")
						else
							ShowNotification(_U('need_more_ingredients'), 130)
						end
					end, {"houblon", "malte", "levure"}, 5, 'Fermentation')
				elseif playerInService then
					ESX.TriggerServerCallback('esx_brasseur:Count', function(Count)
						if Count then
							Process("Fermentation")
						else
							ShowNotification(_U('need_more_ingredients'), 130)
						end
					end, {"houblon", "malte", "levure"}, 5, 'Fermentation')
				else
					ShowNotification(_U('service_not'), 130)
				end	
			end
		elseif GetDistanceBetweenCoords(coords, Config.Zones.Brasseur.Conditionnement.Coords, true) < 1 then
			if not isProcessing then
				ShowHelpNotification(_U('menu_Conditionnement'))
			end
			
			if IsControlJustReleased(0, Keys['E']) and not isProcessing then
				if Config.MaxInService == -1 then
					ESX.TriggerServerCallback('esx_brasseur:Count', function(Count)
						if Count then
							Process("Conditionnement")
						else
							ShowNotification(_U('need_more_beer'), 130)
						end
					end, 'bouteille', 5, 'Conditionnement')
				elseif playerInService then
					ESX.TriggerServerCallback('esx_brasseur:Count', function(Count)
						if Count then
							Process("Conditionnement")
						else
							ShowNotification(_U('need_more_beer'), 130)
						end
					end, 'bouteille', 5, 'Conditionnement')
				else
					ShowNotification(_U('service_not'), 130)
				end	
			end
		else
			Citizen.Wait(500)
		end
	end
end)


function Process(zone)
	local playerPed = PlayerPedId()
	
	if zone == "Ingredients" then
		isProcessing = true

		SetEntityCoords(playerPed, 94.01, 6356.10, 31.375 -0.95) 
		SetEntityHeading(playerPed, -154.65)
		FreezeEntityPosition(playerPed, true)
		
		spawnInfoObject("prop_box_tea01a", 94.37, 6355.62, 31.37)
		
		TriggerServerEvent('esx_brasseur:startHarvest', zone)
		
		TaskStartScenarioInPlace(playerPed, "CODE_HUMAN_MEDIC_TEND_TO_DEAD", 0, true)
		
		Citizen.Wait(10000)

		ClearPedTasksImmediately(playerPed)
		FreezeEntityPosition(playerPed, false)
		
		DeleteOBJ("prop_box_tea01a", 94.37, 6355.62, 31.37)
		
		local timeLeft = Config.Delays.Ingredients / 1000
		local playerPed = playerPed

		while timeLeft > 0 do
			Citizen.Wait(1000)
			timeLeft = timeLeft - 1

			if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.Zones.Brasseur.Ingredients.Coords, false) > 4 then
				break
			end
		end

		isProcessing = false
	elseif zone == "Fermentation" then 
		isProcessing = true
		
		SetEntityCoords(playerPed, 1442.49, 6331.86, 23.98 -0.95) 
		SetEntityHeading(playerPed, -173.45)
		FreezeEntityPosition(playerPed, true)
		
		TriggerServerEvent('esx_brasseur:startHarvest', zone)
		
		TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
		
		Citizen.Wait(5000)

		ClearPedTasksImmediately(playerPed)
		FreezeEntityPosition(playerPed, false)
				
		local timeLeft = Config.Delays.Fermentation / 1000
		local playerPed = playerPed

		while timeLeft > 0 do
			Citizen.Wait(1000)
			timeLeft = timeLeft - 1

			if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.Zones.Brasseur.Fermentation.Coords, false) > 4 then
				break
			end
		end

		isProcessing = false
	elseif zone == "Conditionnement" then
		isProcessing = true
		
		SetEntityCoords(playerPed, 2360.89, 3133.78, 48.20 -0.95) 
		SetEntityHeading(playerPed, -10.14)
		FreezeEntityPosition(playerPed, true)
		
		spawnInfoObject("prop_crate_11e", 2361.00, 3134.61, 48.46) --prop_cs_box_clothes

		TriggerServerEvent('esx_brasseur:startHarvest', zone)
		
		TaskStartScenarioInPlace(playerPed, "PROP_HUMAN_BUM_BIN", 0, true)
		
		Citizen.Wait(5000)

		ClearPedTasksImmediately(playerPed)
		FreezeEntityPosition(playerPed, false)
		
		DeleteOBJ("prop_crate_11e", 2361.00, 3134.61, 48.46)
						
		local timeLeft = Config.Delays.Conditionnement / 1000
		local playerPed = playerPed

		while timeLeft > 0 do
			Citizen.Wait(1000)
			timeLeft = timeLeft - 1

			if GetDistanceBetweenCoords(GetEntityCoords(playerPed), Config.Zones.Brasseur.Conditionnement.Coords, false) > 4 then
				break
			end
		end

		isProcessing = false
	end
end

function spawnInfoObject(object, x, y, z)
    RequestModel(object)

    while not HasModelLoaded(object) do
	    Citizen.Wait(1)
    end

	local nbObjetsCrees = 0

	while nbObjetsCrees < 1 do
        local obj = CreateObject(GetHashKey(object), x, y, z, true, true, true)
	    PlaceObjectOnGroundProperly(obj)
        FreezeEntityPosition(obj, true)
		nbObjetsCrees = nbObjetsCrees + 1
	end
end

function DeleteOBJ(theobject, x, y, z)
    --[ Deletes The Object ]
    local object = GetHashKey(theobject)

    if DoesObjectOfTypeExistAtCoords(x, y, z, 0.9, object, true) then
        local obj = GetClosestObjectOfType(x, y, z, 0.9, object, false, false, false)
		SetModelAsNoLongerNeeded(obj)
		SetEntityAsMissionEntity(obj)
        DeleteObject(obj)
    end
end

function OpenShop()
	ESX.UI.Menu.CloseAll()
	local elements = {}
	menuOpen = true

	for k, v in pairs(ESX.GetPlayerData().inventory) do
		local price = Config.Items[v.name]

		if price and v.count > 0 then
			table.insert(elements, {
				label = ('%s - <span style="color:green;">%s</span>'):format(v.label, _U('dealer_item', ESX.Math.GroupDigits(price))),
				name = v.name,
				price = price,

				-- menu properties
				type = 'slider',
				value = 1,
				min = 1,
				max = v.count
			})
		end
	end

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'shop', {
		title    = "Menu vente",
		align    = 'top-left',
		elements = elements
	}, function(data, menu)
		TriggerServerEvent('esx_brasseur:sell', data.current.name, data.current.value)
		OpenShop()
	end, function(data, menu)
		menu.close()
		menuOpen = false
	end)
end

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		if Config.MaxInService ~= -1 then
			TriggerServerEvent('esx_service:disableService', 'brasseur')
		end
	end
end)