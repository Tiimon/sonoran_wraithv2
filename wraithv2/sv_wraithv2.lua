--[[
    Sonaran CAD Plugins

    Plugin Name: wraithv2
    Creator: SonoranCAD
    Description: Implements plate auto-lookup for the wraithv2 plate reader by WolfKnight

    Put all server-side logic in this file.
]]

local pluginConfig = Config.plugins["wraithv2"]

wraithLastPlates = { locked = nil, scanned = nil }

exports('cadGetLastPlates', function() return wraithLastPlates end)

CreateThread(function()
    if pluginConfig.isPluginEnabled then
        RegisterNetEvent("wk:onPlateLocked")
        AddEventHandler("wk:onPlateLocked", function(cam, plate, index)
            debugLog(("plate lock: %s - %s - %s"):format(cam, plate, index))
            local source = source
            local ids = GetIdentifiers(source)
            wraithLastPlates.locked = { cam = cam, plate = plate, index = index, vehicle = cam.vehicle }
            cadPlateLookup(plate, false, function(data)
                if data == nil then
                    debugLog("No data returned")
                    return
                end
                local reg = data.vehicleRegistrations[1] -- scanner is always full lookup
                local bolos = data.bolos
                if reg then
                    TriggerEvent("SonoranCAD::wraithv2:PlateLocked", source, reg, cam, plate, index)
                    local mi = reg.person.mi ~= "" and ", "..reg.person.mi or ""
                    debugLog(("DATA: Plate [%s]: S: %s E: %s O: %s"):format(reg.vehicle.plate, reg.status, reg.expiration, reg.person.first.." "..reg.person.last..mi))
                    
                    TriggerClientEvent("pNotify:SendNotification", source, {
                        text = "<b style='color:yellow'>"..cam.." ALPR</b><br/>Plate: "..reg.vehicle.plate.."<br/>Status: "..reg.status.."<br/>Expires: "..reg.expiration.."<br/>Owner: "..reg.person.first.." "..reg.person.last..mi,
                        type = "success",
                        queue = "alpr",
                        timeout = 45000,
                        layout = "centerLeft"
                    })
                    if bolos then
                        if bolos[1].flags then
                            local flags = table.concat(bolos[1].flags, ",")
                            TriggerClientEvent("pNotify:SendNotification", source, {
                                text = ("<b style='color:red'>BOLO ALERT!<br/>Plate: %s<br/>Flags: %s"):format(reg.vehicle.plate, flags),
                                type = "error",
                                queue = "bolo",
                                timeout = 20000,
                                layout = "centerLeft"
                            })
                        end
                    end
                else
                    TriggerClientEvent("pNotify:SendNotification", source, {
                        text = "<b style='color:yellow'>"..cam.." ALPR</b><br/>Plate: "..plate.."<br/>Status: Not Registered",
                        type = "error",
                        queue = "alpr",
                        timeout = 15000,
                        layout = "centerLeft"
                    })
                end
            end, ids[Config.primaryIdentifier])
        end)

        RegisterNetEvent("wk:onPlateScanned")
        AddEventHandler("wk:onPlateScanned", function(cam, plate, index)
            debugLog(("plate scan: %s - %s - %s"):format(cam, plate, index))
            local source = source
            wraithLastPlates.scanned = { cam = cam, plate = plate, index = index, vehicle = cam.vehicle }
            TriggerEvent("SonoranCAD::wraithv2:PlateScanned", source, reg, cam, plate, index)
            cadPlateLookup(plate, true, function(data)
                if data ~= nil then
                    local reg = data.vehicleRegistrations[1] -- scanner is always full lookup
                    if reg then
                        local mi = reg.person.mi ~= "" and ", "..reg.person.mi or ""
                        debugLog(("DATA: Plate [%s]: S: %s E: %s O: %s"):format(reg.vehicle.plate, reg.status, reg.expiration, reg.person.first.." "..reg.person.last..mi))
                        
                        TriggerClientEvent("pNotify:SendNotification", source, {
                            text = "<b style='color:yellow'>"..cam.." ALPR</b><br/>Plate: "..reg.vehicle.plate.."<br/>Status: "..reg.status.."<br/>Expires: "..reg.expiration.."<br/>Owner: "..reg.person.first.." "..reg.person.last..mi,
                            type = "success",
                            queue = "alpr",
                            timeout = 45000,
                            layout = "centerLeft"
                        })
                    else
                        TriggerClientEvent("pNotify:SendNotification", source, {
                            text = "<b style='color:yellow'>"..cam.." ALPR</b><br/>Plate: "..plate.."<br/>Status: Not Registered",
                            type = "error",
                            queue = "alpr",
                            timeout = 15000,
                            layout = "centerLeft"
                        })
                    end
                end
            end)
        end)
    end
end)

