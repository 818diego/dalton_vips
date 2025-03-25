lib.locale()

-- Modules
local Vip = require('server.vip')
local Points = require('server.points')
local Tebex = require('server.tebex')

-- Threads
CreateThread(function()
    while true do
        Wait(Config.PointsInterval * 60 * 1000)
        local players = exports.qbx_core:GetQBPlayers()
        for _, player in pairs(players) do
            if player and player.PlayerData then
                local vipData = Vip.GetPlayerVipData(player)
                if vipData then
                    local vipLevel = Vip.GetVipLevelByName(vipData.vip_level or "Sin VIP")
                    local pointsToAdd = Config.PointsAmount * vipLevel.pointsMultiplier
                    if pointsToAdd > 0 then
                        Points.AddVipPoints(player, pointsToAdd)
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(10000)
        local players = exports.qbx_core:GetQBPlayers()
        for _, player in pairs(players) do
            if player then
                local vipData = Vip.GetPlayerVipData(player)
                if vipData and vipData.vip_level ~= "Sin VIP" then
                    if Vip.CheckVipExpiration(vipData) then
                        Vip.RemoveExpiredVip(player.PlayerData.citizenid, vipData.vip_level)
                    end
                end
            end
        end
    end
end)

-- Events
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function(player)
    Vip.GetPlayerVipData(player)
end)

-- Callbacks
lib.callback.register('dalton_vips:getVipInfo', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local vipData = Vip.GetPlayerVipData(player)
    if not vipData then return { points = 0, level = "Sin VIP" } end

    return {
        points = vipData.vip_points,
        level = vipData.vip_level
    }
end)

lib.callback.register('dalton_vips:buyVipLevel', function(source, levelName)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return false, locale('errors.player_not_found') end

    return Vip.BuyVipLevel(player, levelName)
end)

-- Commands
lib.addCommand('referred', {
    help = 'Use a referral code to get VIP points',
    params = {
        {
            name = 'code',
            type = 'string',
            help = 'Referral code',
        }
    },
}, function(source, args, raw)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local success, message = Points.UseReferralCode(player, args.code)
    TriggerClientEvent('ox_lib:notify', source, {
        id = success and 'referral_success' or 'referral_error',
        title = locale(success and 'notifications.success' or 'notifications.error'),
        description = message,
        duration = 3000,
        type = success and 'success' or 'error',
        position = 'top'
    })
end)

lib.addCommand('redeem', {
    help = 'Redeem a Tebex payment using the transaction ID',
    params = {
        {
            name = 'transactionId',
            type = 'string',
            help = 'Tebex transaction ID',
        }
    },
}, function(source, args, raw)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    Tebex.ProcessPayment(player, args.transactionId, function(success, result)
        local notification = {
            id = success and 'tebex_success' or 'tebex_error',
            title = locale(success and 'notifications.tebex_success' or 'notifications.error'),
            description = success and
                locale('notifications.tebex_points_received', result.points, table.concat(result.packages, ", ")) or
                result,
            duration = success and 5000 or 3000,
            type = success and 'success' or 'error',
            position = 'top'
        }
        TriggerClientEvent('ox_lib:notify', source, notification)
    end)
end)

lib.addCommand('addPoints', {
    help = 'Add VIP points to a player',
    restricted = 'group.admin',
    params = {
        {
            name = 'playerId',
            type = 'playerId',
            help = 'Player ID',
        },
        {
            name = 'points',
            type = 'number',
            help = 'Amount of VIP points to add',
        }
    },
}, function(source, args, raw)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return end

    local targetPlayer = exports.qbx_core:GetPlayer(args.playerId)
    if not targetPlayer then
        TriggerClientEvent('ox_lib:notify', source, {
            id = 'error_player_not_found',
            title = locale('notifications.error'),
            description = locale('errors.player_not_found'),
            duration = 3000,
            type = 'error',
            position = 'top'
        })
        return
    end

    local success, message = Points.AddVipPoints(targetPlayer, args.points)

    TriggerClientEvent('ox_lib:notify', source, {
        id = success and 'vip_points_success' or 'vip_points_error',
        title = locale(success and 'notifications.success' or 'notifications.error'),
        description = success and
            locale('notifications.points_added_admin', args.points, targetPlayer.PlayerData.name) or
            message,
        duration = 3000,
        type = success and 'success' or 'error',
        position = 'top'
    })
end)
