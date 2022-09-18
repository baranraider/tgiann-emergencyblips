QBCore = nil
Citizen.CreateThread(function()
    while QBCore == nil do
        TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
        Citizen.Wait(200)
    end
end)

local PlayerData, blips, activeBlips, carBlips = {}, {}, {}, {}
local activeGps, activeCarBlip, policeBlip = false, false, false
local lastGpsText = ""

RegisterNetEvent('QBCore:Client:OnPlayerLoaded')
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

RegisterCommand("gpsloaded", function()
    PlayerData = QBCore.Functions.GetPlayerData()
end)

AddEventHandler('tgiann:playerdead', function(dead)
	if activeGps and dead then 
		TriggerServerEvent("tgiann-gps:acikgps-kapat", true)
	end
end)

RegisterNetEvent('tgiann-emerhencyblips:forceClose')
AddEventHandler('tgiann-emerhencyblips:forceClose', function()
	if activeGps then 
		TriggerServerEvent("tgiann-gps:acikgps-kapat", false)
	end
end)




-- Citizen.CreateThread(function()
-- 	TriggerEvent('chat:addSuggestion', '/agps', 'Araç Kod Numarası Belirle.', {{ name="Kod No", help="Araç Kod Numarası"}})
-- end)

-- RegisterCommand("agps", function(source, args)
-- 	if args[1] then
-- 		if PlayerData.job == nil then PlayerData = QBCore.Functions.GetPlayerData() end
-- 		if PlayerData.job.name == "police" then
-- 			local playerPed = PlayerPedId()
-- 			if IsPedInAnyVehicle(playerPed) then
-- 				local vehicle = GetVehiclePedIsIn(playerPed)
-- 				if GetVehicleClass(vehicle) == 18 then
-- 					if GetPedInVehicleSeat(vehicle, -1) == playerPed then
-- 						if activeGps then
-- 							local plate = QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle))
-- 							TriggerServerEvent("tgiann-emergencyblips:carBlips", plate, args[1])
-- 							QBCore.Functions.Notify("Araç GPS'i Ayarlandı!", "success") 
-- 						else
-- 							QBCore.Functions.Notify("GPS'in Açık Değil!", "error") 
-- 						end
-- 					else
-- 						QBCore.Functions.Notify("Sürücü Koltuğunda Olman Lazım!", "error") 
-- 					end
-- 				else
-- 					QBCore.Functions.Notify("Polis Aracında Değilsin!", "error") 
-- 				end
-- 			else
-- 				QBCore.Functions.Notify("Araç İçinde Değilsin!", "error") 
-- 			end
-- 		else
-- 			QBCore.Functions.Notify("Polis Değilsin!", "error") 
-- 		end
-- 	else
-- 		QBCore.Functions.Notify("Araç Kod Numarasını Girmedin!", "error") 
-- 	end
-- end)

RegisterNetEvent('tgiann-emergencyblips:updateAllData')
AddEventHandler('tgiann-emergencyblips:updateAllData', function(pData, cData)
	blips = pData
	carBlips = cData
end)

RegisterNetEvent('tgiann-emergencyblips:removePlayerGps')
AddEventHandler('tgiann-emergencyblips:removePlayerGps', function(src, pData, cData)
	blips = pData
	carBlips = cData
	Citizen.Wait(500)
	RemoveBlip(activeBlips[tostring(src)])
end)

RegisterNetEvent('tgiann-emergencyblips:toggle')
AddEventHandler('tgiann-emergencyblips:toggle', function(active, data, policeBlipData)
	policeBlip = policeBlipData
	lastGpsText = data
	activeGps = active
	if not activeGps then
		SetBlipDisplay(GetMainPlayerBlipId(), 4)
		for src, blipData in pairs(activeBlips) do
			RemoveBlip(blipData)
		end
		activeBlips = {}
	else
		SetBlipDisplay(GetMainPlayerBlipId(), 1)
	end
end)

RegisterNetEvent('tgiann-closest-police')
AddEventHandler('tgiann-closest-police', function(cb) 
	local closestPolice = 0
	local policeCount = 0
	for src, info in pairs(blips) do
		if info.blipColor == 29 then
			policeCount = policeCount + 1
			local playerIndex = GetPlayerFromServerId(src)
			if playerIndex ~= -1 then
				if #(GetEntityCoords(GetPlayerPed(playerIndex)) - GetEntityCoords(PlayerPedId())) < 250 then
					closestPolice = closestPolice + 1
				end
			end
		end
	end
	cb({closestPolice = closestPolice, policeCount = policeCount}) 
end)

Citizen.CreateThread(function()
	while true do
		if activeGps then
			local allBlips = exports["tgiann-infinity"]:GetPlayerCoordsData()
			for src, info in pairs(blips) do
				local playerBlips = allBlips[src]
				if playerBlips then
					if DoesBlipExist(activeBlips[src]) then
						SetBlipCoords(activeBlips[src], playerBlips.x, playerBlips.y, playerBlips.z)
						if GetBlipSprite(activeBlips[src]) ~= info.blipType then
							SetBlipSprite(activeBlips[src], info.blipType or 2)
						end						
						SetBlipColour(activeBlips[src], info.blipColor)
						SetBlipScale(activeBlips[src], info.blipScale)
						BeginTextCommandSetBlipName("STRING")
						if info.carBlip then
							AddTextComponentString(carBlips[info.carPlate].text)
						else
							AddTextComponentString(info.blipText)
						end
						EndTextCommandSetBlipName(activeBlips[src])
					else
						if info.blipText ~= "Bilinmiyor" then
							local blip = AddBlipForCoord(playerBlips.x, playerBlips.y, playerBlips.z)
							SetBlipSprite(blip, info.blipType or 2)
							SetBlipColour(blip, info.blipColor)
							SetBlipAsShortRange(blip, true)
							SetBlipScale(blip, info.blipScale)
							SetBlipDisplay(blip, 4)
							SetBlipShowCone(blip, true)
							BeginTextCommandSetBlipName("STRING")
							AddTextComponentString(info.blipText)
							EndTextCommandSetBlipName(blip)
							activeBlips[tostring(src)] = blip
						end
					end
				end

			end
		end
		Citizen.Wait(100)
	end
end)

local lastPlate = ""
local serverDataUpdated = false
local lastBlipType = 1
Citizen.CreateThread(function()
	while true do
		if activeGps and policeBlip then
			local playerPed = PlayerPedId()
			blipType = IsVehicleSirenOn(vehicle) and 1 or GetVehicleClass(vehicle) == 15 and 15 or 1
			if IsPedInAnyVehicle(PlayerPedId()) then
				if not QBCore.Functions.GetPlayerData().metadata["isdead"] then 
					blipScale = 0.85
					local updatedBlip = false
					TriggerServerEvent("tgiann-emergencyblips:updatePlayerGps", false, 1, true, blipType, blipScale)
					local vehicle = GetVehiclePedIsIn(PlayerPedId())
					blipType = IsVehicleSirenOn(vehicle) and 1 or GetVehicleClass(vehicle) == 15 and 15 or 1
					if not activeCarBlip then
						lastPlate = QBCore.Shared.Trim(GetVehicleNumberPlateText(vehicle))
						for carPlate, data in pairs(carBlips) do
							if lastPlate == carPlate then
								activeCarBlip = true
								updatedBlip = true
								TriggerServerEvent("tgiann-emergencyblips:updatePlayerGps", false, 1, true, blipType, blipScale)
							end
						end
					end

					if (not updatedBlip and not serverDataUpdated) or lastBlipType ~= blipType then
						serverDataUpdated = true
						blipScale = 0.85
						TriggerServerEvent("tgiann-emergencyblips:updatePlayerGps", false, 1, true, blipType, blipScale)
					end
					lastBlipType = blipType
				else
					blipType = 274
					blipScale = 1.0
					TriggerServerEvent("tgiann-emergencyblips:updatePlayerGps", false, 1, true, blipType, blipScale)
				end
			else
				if not QBCore.Functions.GetPlayerData().metadata["isdead"] then 
					blipScale = 0.3
					TriggerServerEvent("tgiann-emergencyblips:updatePlayerGps", false, 1, true, blipType, blipScale)
				else
					blipType = 274
					blipScale = 1.0
					TriggerServerEvent("tgiann-emergencyblips:updatePlayerGps", false, 1, true, blipType, blipScale)
				end
			end
		end
		Citizen.Wait(300)
	end
end)

RegisterNetEvent("tgiann-emergencyblip:ac")
AddEventHandler("tgiann-emergencyblip:ac", function()
	local PlayerData = QBCore.Functions.GetPlayerData()
	QBCore.Functions.TriggerCallback('tgiann-base:item-kontrol', function(qtty)
		if qtty > 0 then
			if PlayerData.job ~= nil and PlayerData.job.name ~= 'unemployed' then 
                local keyboard = exports['qb-input']:ShowInput({
                    header = "GPS",
                    submitText = "Onayla",
                    inputs = {
                        {
                            type = 'text',
                            isRequired = true,
                            text = "GPS Numarası",
                            name = 'input',
                        },
						{
                            type = 'text',
                            isRequired = true,
                            text = "[1] PD | [2] BCSO | [3] SASP | [4] SAPR",
                            name = 'input2',
                        }
                    }
                })
                local gpscolor = keyboard.input2
                if gpscolor == nil or tonumber(gpscolor) == nil then gpscolor = 1 end 
                local number = keyboard.input
                if PlayerData.job.name == "police" then
                    TriggerServerEvent('tgiann-gps:polis-ekle', number, tonumber(gpscolor))
                else
                    TriggerServerEvent('tgiann-gps:ems-ekle', number)
                end
			else
				QBCore.Functions.Notify('Polis Değilsin', "error")
			end
		else
			QBCore.Functions.Notify('Üzerinde GPS Yok!')	
		end
	end, 'gps')	
end)

RegisterNetEvent("tgiann-emergencyblip:kapat")
AddEventHandler("tgiann-emergencyblip:kapat", function()
	QBCore.Functions.TriggerCallback('tgiann-base:item-kontrol', function(qtty)
		if qtty > 0 then
			TriggerServerEvent('tgiann-gps:acikgps-kapat', false)
		else
			QBCore.Functions.Notify('Üzerinde GPS Yok!')	
		end
	end, 'gps')	
end)

