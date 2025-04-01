local tebex = {}
local Points = require('server.points')
local Vip = require('server.vip')

-- verify if the transactionId has been redeemed
function tebex.HasRedeemed(transactionId)
    local result = MySQL.query.await('SELECT 1 FROM dalton_vip_transactions WHERE transaction_id = ?', { transactionId })
    return result and #result > 0
end

-- update the transaction as redeemed
function tebex.MarkAsRedeemed(license2, transactionId, pointsAdded)
    MySQL.insert(
        'INSERT INTO dalton_vip_transactions (license2, transaction_id, points_added, redeemed_at) VALUES (?, ?, ?, NOW())',
        { license2, transactionId, pointsAdded })
end

-- get information about the transaction from Tebex
function tebex.GetTebexPayment(transactionId)
    if not Config.TebexAPI.Enabled or not Config.TebexAPI.SecretKey then
        return false, locale('errors.tebex_disabled')
    end
    local endpoint = ('https://plugin.tebex.io/payments/%s'):format(transactionId)
    local promise = promise.new()

    PerformHttpRequest(endpoint, function(statusCode, responseText, headers)
        if statusCode ~= 200 then
            promise:resolve({
                success = false,
                message = locale('errors.tebex_error') .. ": " .. (responseText or locale('errors.unknown_error'))
            })
            return
        end

        local response = json.decode(responseText)
        if not response then
            promise:resolve({
                success = false,
                message = locale('errors.tebex_decode_error')
            })
            return
        end

        promise:resolve({
            success = true,
            data = response
        })
    end, 'GET', '', {
        ['X-Tebex-Secret'] = Config.TebexAPI.SecretKey
    })

    return Citizen.Await(promise)
end

function tebex.ProcessPayment(player, transactionId, callback)
    if not player then
        callback(false, locale('errors.player_not_found'))
        return
    end

    if not transactionId or transactionId == '' then
        callback(false, locale('errors.invalid_data'))
        return
    end

    if tebex.HasRedeemed(transactionId) then
        callback(false, locale('errors.payment_already_redeemed'))
        return
    end

    PerformHttpRequest(
        'https://plugin.tebex.io/payments/' .. transactionId,
        function(statusCode, responseText, headers)
            if statusCode ~= 200 then
                callback(false, locale('errors.tebex_error') .. ": " .. (statusCode or "Error desconocido"))
                return
            end

            local response = json.decode(responseText)
            if not response then
                callback(false, locale('errors.tebex_decode_error'))
                return
            end

            if response.status ~= "Complete" then
                callback(false, locale('errors.payment_incomplete') .. ": " .. response.status)
                return
            end

            -- process the payments
            local totalPoints = 0
            local packageNames = {}

            if response.packages and #response.packages > 0 then
                for _, package in ipairs(response.packages) do
                    local packageId = package.id
                    local points = Config.TebexAPI.PackageRewards[packageId]

                    if points and points > 0 then
                        totalPoints = totalPoints + points
                        table.insert(packageNames, package.name)
                    end
                end
            end

            if totalPoints <= 0 then
                callback(false, locale('errors.no_vip_rewards'))
                return
            end

            -- add point to the player
            local success, message = Points.AddVipPoints(player, totalPoints)
            if success then
                local license2 = Vip.GetLicense2(player.PlayerData.source)
                tebex.MarkAsRedeemed(license2, transactionId, totalPoints)
                callback(true, {
                    points = totalPoints,
                    packages = packageNames
                })
                print(string.format("[TEBEX] Player %s (ID: %s) redeemed transaction %s for %d points",
                    player.PlayerData.name, license2, transactionId, totalPoints))
            else
                callback(false, locale('errors.add_points_error') .. ": " .. message)
            end
        end,
        'GET',
        '',
        {
            ['X-Tebex-Secret'] = Config.TebexAPI.SecretKey
        }
    )
end

return tebex
