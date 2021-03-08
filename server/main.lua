ESX = nil
local PlayersHarvesting = {}

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

if Config.MaxInService ~= -1 then
	TriggerEvent('esx_service:activateService', 'brasseur', Config.MaxInService)
end

RegisterServerEvent('esx_brasseur:startHarvest')
AddEventHandler('esx_brasseur:startHarvest', function(zone)
	local _source = source
	local xPlayer = ESX.GetPlayerFromId(_source)
	
	if zone == "Ingredients" then
		Citizen.Wait(0)
		TriggerClientEvent('esx_brasseur:progressBars', _source, 10000, "Récupération des ingrédients...")
		Citizen.Wait(10000)
		xPlayer.addInventoryItem('houblon', 5)	
		xPlayer.addInventoryItem('malte', 5)	
		xPlayer.addInventoryItem('levure', 5)				
	elseif zone == "Fermentation" then
		local giveItem = xPlayer.getInventoryItem('bouteille')	
		
		if giveItem.count >= giveItem.limit then
			TriggerClientEvent('esx_brasseur:notify', _source, _U('need_more_ingredients'), 130)
			return
		else	
			Citizen.Wait(0)
			TriggerClientEvent('esx_brasseur:progressBars', _source, 5000, "Mélange & fermentation..")
			Citizen.Wait(5000)
			xPlayer.removeInventoryItem('houblon', 5)
			xPlayer.removeInventoryItem('malte', 5)
			xPlayer.removeInventoryItem('levure', 5)
			xPlayer.addInventoryItem('bouteille', 5)			
		end
	elseif zone == "Conditionnement" then
		local giveItem = xPlayer.getInventoryItem('biere')
		
		if giveItem.count >= giveItem.limit then
			TriggerClientEvent('esx_slaughterer:notify', _source, "Votre inventaire est plein.", 130)
			return
		else
			Citizen.Wait(0)
			TriggerClientEvent('esx_brasseur:progressBars', _source, 5000, "Conditionnement de la bière...")
			Citizen.Wait(5000)
			xPlayer.removeInventoryItem('bouteille', 5)
			xPlayer.addInventoryItem('biere', 5)
		end					
	end
end)

RegisterServerEvent('esx_brasseur:sell')
AddEventHandler('esx_brasseur:sell', function(itemName, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local price = Config.Items[itemName]
	local xItem = xPlayer.getInventoryItem(itemName)
	
	if not price then
		print(('esx_brasseur: %s attempted to sell an invalid item!'):format(xPlayer.identifier))
		return
	end
	
	if xItem.count < amount then
		TriggerClientEvent('esx:showNotification', source, _U('dealer_notenough'))
		return
	end
	
	price = ESX.Math.Round(price * amount)
	
	xPlayer.addMoney(price)
	
	TriggerClientEvent('esx_brasseur:notify', xPlayer.source, _U('give_money') .. price.."€", 110)
	
	xPlayer.removeInventoryItem(xItem.name, amount)
end)


ESX.RegisterServerCallback('esx_brasseur:getPlayerInventory', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local items = xPlayer.inventory
	
	cb( { items = items } )
end)

ESX.RegisterServerCallback('esx_brasseur:canPickUp', function(source, cb, items)
	local xPlayer = ESX.GetPlayerFromId(source)
	
	if xPlayer.getInventoryItem(items[1]).count < xPlayer.getInventoryItem(items[1]).limit and 
		xPlayer.getInventoryItem(items[2]).count < xPlayer.getInventoryItem(items[1]).limit and 
		xPlayer.getInventoryItem(items[3]).count < xPlayer.getInventoryItem(items[1]).limit then
		cb(true)
	else
		for k, item in pairs(items) do	
			local xItem = xPlayer.getInventoryItem(item)
			
			if xItem.name == "houblon" then
				if xItem.limit ~= -1 and xItem.count >= xItem.limit then
					TriggerClientEvent('esx_brasseur:notify', xPlayer.source, "Inventaire plein. Trop d'houblon", 130)
				end
			elseif xItem.name == "malte" then
				if xItem.limit ~= -1 and xItem.count >= xItem.limit then
					TriggerClientEvent('esx_brasseur:notify', xPlayer.source, "Inventaire plein. Trop de malte", 130)
				end
			elseif xItem.name == "levure" then
				if xItem.limit ~= -1 and xItem.count >= xItem.limit then
					TriggerClientEvent('esx_brasseur:notify', xPlayer.source, "Inventaire plein. Trop de levure", 130)
				end
			end
		end 
		
		cb(false)
	end
end)

ESX.RegisterServerCallback('esx_brasseur:Count', function(source, cb, item, nbres, zone)
	local xPlayer = ESX.GetPlayerFromId(source)
	local xItem = xPlayer.getInventoryItem(item)
	
	if zone == "Conditionnement" then
		if xItem.count >= nbres then
			cb(true)
		else
			cb(false)
		end
	elseif zone == "Fermentation" then
		if xPlayer.getInventoryItem(item[1]).count >= nbres and 
			xPlayer.getInventoryItem(item[2]).count >= nbres and 
			xPlayer.getInventoryItem(item[3]).count >= nbres then
			
			cb(true)
		else
			if xPlayer.getInventoryItem(item[1]).count < nbres then
				TriggerClientEvent('esx_brasseur:notify', xPlayer.source, "Il vous manque: " ..item[1], 130)
			end
			if xPlayer.getInventoryItem(item[2]).count < nbres then
				TriggerClientEvent('esx_brasseur:notify', xPlayer.source, "Il vous manque: " ..item[2], 130)
			end
			if xPlayer.getInventoryItem(item[3]).count < nbres then
				TriggerClientEvent('esx_brasseur:notify', xPlayer.source, "Il vous manque: " ..item[3], 130)
			end
			
			cb(false)
		end
	end
end)