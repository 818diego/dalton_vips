local vip = {}

function vip.GetLicense2(source)
    if not source then return nil end
    local identifiers = GetPlayerIdentifiers(source)
    if not identifiers then return nil end
    for _, identifier in pairs(identifiers) do
        if string.find(identifier, "license2:") then
            return string.gsub(identifier, "license2:", "")
        end
    end
    return nil
end

function vip.GetPlayerVipData(player, directLicense2)
    local license2 = directLicense2
    
    if not license2 and player and player.PlayerData then
        license2 = vip.GetLicense2(player.PlayerData.source)
    end
    
    if not license2 then return nil end

    local result = MySQL.query.await('SELECT * FROM dalton_vip WHERE license2 = ? LIMIT 1', { license2 })
    
    if not result or #result == 0 then
        MySQL.insert.await('INSERT INTO dalton_vip (license2, vip_points, vip_level, vip_activated_at, used_referral) VALUES (?, ?, ?, NULL, ?)',
            { license2, 0, "Sin VIP", false })
        
        return {
            license2 = license2,
            vip_points = 0,
            vip_level = "Sin VIP",
            vip_activated_at = nil,
            used_referral = false
        }
    end

    return result[1]
end

function vip.GetVipLevelName(player, directLicense2)
    if not player and not directLicense2 then return "Sin VIP" end
    local vipData = vip.GetPlayerVipData(player, directLicense2)
    if not vipData then return "Sin VIP" end
    return vipData.vip_level or "Sin VIP"
end

function vip.GetVipLevelByName(levelName)
    if levelName == "Sin VIP" then
        return { name = "Sin VIP", cost = 0, pointsMultiplier = 1 }
    end

    if not Config.VipLevels then
        return { name = "Sin VIP", cost = 0, pointsMultiplier = 1 }
    end

    for _, level in ipairs(Config.VipLevels) do
        if level.name == levelName then
            return level
        end
    end

    return { name = "Sin VIP", cost = 0, pointsMultiplier = 1 }
end

function vip.CheckVipExpiration(vipData)
    if not vipData or vipData.vip_level == "Sin VIP" or not vipData.vip_activated_at then return false end

    local activationTime = vipData.vip_activated_at
    if type(activationTime) == "string" then
        activationTime = os.time({
            year = tonumber(activationTime:sub(1, 4)),
            month = tonumber(activationTime:sub(6, 7)),
            day = tonumber(activationTime:sub(9, 10)),
            hour = tonumber(activationTime:sub(12, 13)),
            min = tonumber(activationTime:sub(15, 16)),
            sec = tonumber(activationTime:sub(18, 19))
        })
    end

    return os.time() - activationTime >= Config.VipDuration / 1000
end

function vip.RemoveExpiredVip(license2, oldVipLevel)
    MySQL.update('UPDATE dalton_vip SET vip_level = ?, vip_activated_at = NULL WHERE license2 = ?',
        { "Sin VIP", license2 })

    local player = exports.qbx_core:GetPlayerByIdentifier(license2)
    if player then
        TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
            id = 'vip_expired_' .. license2,
            title = locale('notifications.vip_expired'),
            description = locale('notifications.vip_expired_desc', oldVipLevel),
            duration = 10000,
            type = 'error',
            position = 'top'
        })
    end
end

function vip.BuyVipLevel(player, levelName, directLicense2)
    local license2 = directLicense2
    local playerObj = player

    if not license2 and player and player.PlayerData then
        license2 = vip.GetLicense2(player.PlayerData.source)
    elseif license2 and not player then
        playerObj = exports.qbx_core:GetPlayerByIdentifier(license2)
    end
    
    if not license2 then return false, locale('errors.player_not_found') end

    local targetLevel = nil
    for _, level in ipairs(Config.VipLevels) do
        if level.name == levelName then
            targetLevel = level
            break
        end
    end
    if not targetLevel then
        return false, locale('errors.invalid_vip_level')
    end

    local vipData = vip.GetPlayerVipData(nil, license2)
    if not vipData then return false, locale('errors.player_not_found') end

    if vipData.vip_level ~= "Sin VIP" and not vip.CheckVipExpiration(vipData) then
        return false, locale('errors.active_vip')
    end

    if vipData.vip_points < targetLevel.cost then
        return false, locale('errors.insufficient_points')
    end

    local newPoints = vipData.vip_points - targetLevel.cost
    local currentTime = os.date('%Y-%m-%d %H:%M:%S')

    MySQL.update('UPDATE dalton_vip SET vip_points = ?, vip_level = ?, vip_activated_at = ? WHERE license2 = ?',
        { newPoints, targetLevel.name, currentTime, license2 })

    if Config.NotifyPlayer and playerObj and playerObj.PlayerData then
        local durationInMinutes = math.floor(Config.VipDuration / (60 * 1000))
        TriggerClientEvent('ox_lib:notify', playerObj.PlayerData.source, {
            id = 'vip_updated_' .. license2,
            title = locale('notifications.vip_updated'),
            description = locale('notifications.vip_updated_desc', targetLevel.name, durationInMinutes),
            duration = 5000,
            type = 'success',
            position = 'top'
        })
    end

    return true, locale('notifications.success')
end

exports('GetPlayerVipData', vip.GetPlayerVipData)
exports('GetVipLevelName', vip.GetVipLevelName)
exports('BuyVipLevel', vip.BuyVipLevel)
exports('GetVipLevelByName', vip.GetVipLevelByName)

return vip
