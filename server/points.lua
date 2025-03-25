local points = {}
local Vip = require('server.vip')

function points.AddVipPoints(player, amount)
    if not player or not amount then return false, locale('errors.invalid_data') end

    if type(amount) ~= 'number' or amount <= 0 then
        return false, locale('errors.invalid_amount')
    end

    local citizenid = player.PlayerData.citizenid
    if not citizenid then return false, locale('errors.invalid_data') end

    local data = Vip.GetPlayerVipData(player)
    if not data then return false, locale('errors.player_not_found') end

    local newPoints = (data.vip_points or 0) + amount
    local success = MySQL.update.await('UPDATE dalton_vip SET vip_points = ? WHERE citizenid = ?', { newPoints, citizenid })
    
    if not success then 
        return false, locale('errors.database_error')
    end

    if Config.NotifyPlayer then
        TriggerClientEvent('ox_lib:notify', player.PlayerData.source, {
            id = 'vip_points_added_' .. citizenid,
            title = 'VIP Points',
            description = locale('notifications.vip_points_added', amount),
            duration = 3000,
            type = 'success',
            position = 'top'
        })
    end

    return true, locale('notifications.success')
end

function points.UseReferralCode(player, code)
    if not player or not code then return false, locale('errors.invalid_data') end

    local pointsToAdd = Config.ReferralCodes[code:lower()]
    if not pointsToAdd then return false, locale('errors.invalid_referral') end

    local citizenid = player.PlayerData.citizenid
    local data = Vip.GetPlayerVipData(player)
    if not data then return false, locale('errors.player_not_found') end

    if data.used_referral then
        return false, locale('errors.referral_already_used')
    end

    local success, message = points.AddVipPoints(player, pointsToAdd)
    if success then
        MySQL.update('UPDATE dalton_vip SET used_referral = ? WHERE citizenid = ?', { true, citizenid })
        return true, locale('notifications.vip_points_added', pointsToAdd)
    end
    return false, message
end

exports('AddVipPoints', points.AddVipPoints)
exports('UseReferralCode', points.UseReferralCode)

return points
