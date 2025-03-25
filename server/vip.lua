local vip = {}
local cache = {}
local dirtyPlayers = {}

function vip.GetVipLevelName(player)
    if not player then return "Sin VIP" end
    local vipData = vip.GetPlayerVipData(player)
    if not vipData then return "Sin VIP" end
    return vipData.vip_level or "Sin VIP"
end

function vip.GetVipLevelByName(levelName)
    if levelName == "Sin VIP" then
        return { name = "Sin VIP", pointsMultiplier = 1 }
    end

    for _, level in ipairs(Config.VipLevels) do
        if level.name == levelName then
            return level
        end
    end

    return { name = "Sin VIP", pointsMultiplier = 1 }
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

function vip.RemoveExpiredVip(citizenid, oldVipLevel)
    cache[citizenid].vip_level = "Sin VIP"
    cache[citizenid].vip_activated_at = nil

    MySQL.update('UPDATE dalton_vip SET vip_level = ?, vip_activated_at = NULL WHERE citizenid = ?',
        { "Sin VIP", citizenid })

    local player = exports.qbx_core:GetPlayerByCitizenId(citizenid)
    if player then
        TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
            id = 'vip_expired_' .. citizenid,
            title = locale('notifications.vip_expired'),
            description = locale('notifications.vip_expired_desc', oldVipLevel),
            duration = 10000,
            type = 'error',
            position = 'top'
        })
    end
end

function vip.InsertPlayer(player)
    if not player or not player.PlayerData.citizenid then return end
    local citizenid = player.PlayerData.citizenid

    MySQL.insert(
        'INSERT INTO dalton_vip (citizenid, vip_points, vip_level, vip_activated_at, used_referral) VALUES (?, ?, ?, NULL, ?)',
        {
            citizenid, 0, "Sin VIP", false
        })

    cache[citizenid] = {
        citizenid = citizenid,
        vip_points = 0,
        vip_level = "Sin VIP",
        vip_activated_at = nil,
        used_referral = false,
        lastUpdate = os.time()
    }
    return cache[citizenid]
end

function vip.GetPlayerVipData(player, type)
    if not player or not player.PlayerData.citizenid then return end
    local citizenid = player.PlayerData.citizenid

    local result = MySQL.query.await('SELECT * FROM dalton_vip WHERE citizenid = ?', { citizenid })
    if result and #result > 0 then
        local vipData = result[1]
        if vip.CheckVipExpiration(vipData) then
            vip.RemoveExpiredVip(citizenid, vipData.vip_level)
            result = MySQL.query.await('SELECT * FROM dalton_vip WHERE citizenid = ?', { citizenid })
            vipData = result[1]
        end
        return type and vipData[type] or vipData
    else
        return vip.InsertPlayer(player)
    end
end

function vip.BuyVipLevel(player, levelName)
    if not player then return false, locale('errors.player_not_found') end

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

    local vipData = vip.GetPlayerVipData(player)
    if not vipData then return false, locale('errors.player_not_found') end

    if vipData.vip_level ~= "Sin VIP" and not vip.CheckVipExpiration(vipData) then
        return false, locale('errors.active_vip')
    end

    if vipData.vip_points < 0 then
        vipData.vip_points = 0
        MySQL.update('UPDATE dalton_vip SET vip_points = 0 WHERE citizenid = ?', { player.PlayerData.citizenid })
    end

    if vipData.vip_points < targetLevel.cost then
        return false, locale('errors.insufficient_points')
    end

    local citizenid = player.PlayerData.citizenid
    local newPoints = vipData.vip_points - targetLevel.cost
    local currentTime = os.date('%Y-%m-%d %H:%M:%S')

    cache[citizenid].vip_points = newPoints
    cache[citizenid].vip_level = targetLevel.name
    cache[citizenid].vip_activated_at = currentTime
    dirtyPlayers[citizenid] = true

    MySQL.update('UPDATE dalton_vip SET vip_points = ?, vip_level = ?, vip_activated_at = ? WHERE citizenid = ?',
        { newPoints, targetLevel.name, currentTime, citizenid })

    if Config.NotifyPlayer then
        local durationInMinutes = math.floor(Config.VipDuration / (60 * 1000))
        TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
            id = 'vip_updated_' .. citizenid,
            title = locale('notifications.vip_updated'),
            description = locale('notifications.vip_updated_desc', targetLevel.name, durationInMinutes),
            duration = 5000,
            type = 'success',
            position = 'top'
        })
    end

    return true, locale('notifications.success')
end

function vip.SaveDirtyPlayers()
    local currentTime = os.time()
    local updates = {}
    local params = {}
    for citizenid, _ in pairs(dirtyPlayers) do
        local data = cache[citizenid]
        if data then
            table.insert(updates, "(?,?,?,?)")
            table.insert(params, citizenid)
            table.insert(params, data.vip_points or 0)
            table.insert(params, data.vip_level or "Sin VIP")
            table.insert(params, data.vip_activated_at or nil)
        end
    end
    if #updates > 0 then
        local query = string.format([[
            INSERT INTO dalton_vip (citizenid, vip_points, vip_level, vip_activated_at)
            VALUES %s
            ON DUPLICATE KEY UPDATE
            vip_points = VALUES(vip_points),
            vip_level = VALUES(vip_level),
            vip_activated_at = VALUES(vip_activated_at)
        ]], table.concat(updates, ","))

        MySQL.update(query, params)
    end
    dirtyPlayers = {}
end

function vip.GetDirtyPlayers()
    return dirtyPlayers
end

function vip.SetDirtyPlayer(citizenid)
    dirtyPlayers[citizenid] = true
end

function vip.GetCache()
    return cache
end

exports('GetPlayerVipData', vip.GetPlayerVipData)
exports('GetVipLevelName', vip.GetVipLevelName)
exports('BuyVipLevel', vip.BuyVipLevel)
exports('GetVipLevelByName', vip.GetVipLevelByName)

return vip
