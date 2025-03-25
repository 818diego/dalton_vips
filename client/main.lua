lib.locale()

-- Command to view VIP information and purchase VIP levels
RegisterCommand('vip', function()
    lib.callback('dalton_vips:getVipInfo', false, function(vipInfo)
        if not vipInfo then
            lib.notify({
                id = 'vip_menu_error',
                title = locale('notifications.error'),
                description = locale('notifications.vip_menu_error'),
                type = 'error',
                duration = 3000,
                position = 'top'
            })
            return
        end

        lib.registerContext({
            id = 'vip_menu',
            title = locale('menu.vip_info'),
            options = {
                {
                    title = locale('menu.your_vip_level'),
                    description = vipInfo.level,
                    icon = 'crown',
                    disabled = true,
                },
                {
                    title = locale('menu.your_total_points'),
                    description = vipInfo.points .. ' ' .. locale('menu.points_suffix'),
                    icon = 'star',
                    disabled = true,
                },
                {
                    title = locale('menu.buy_vip'),
                    description = locale('menu.buy_vip_desc'),
                    icon = 'shopping-cart',
                    onSelect = function()
                        OpenVipShop(vipInfo)
                    end,
                }
            }
        })
        lib.showContext('vip_menu')
    end)
end, false)

-- Command to help with the VIP system
RegisterCommand('viphelp', function()
    lib.alertDialog({
        header = locale('menu.help_title'),
        content = locale('menu.help_content'),
        centered = true,
        showCancel = false,
        size = 'lg',
        labels = {
            confirm = locale('menu.understood')
        }
    })
end, false)

-- Keybind to open the VIP menu
RegisterKeyMapping('vip', locale('menu.vip_info'), 'keyboard', 'F9')

function OpenVipShop(vipInfo)
    local options = {}
    for _, level in ipairs(Config.VipLevels) do
        table.insert(options, {
            title = level.name,
            description = locale('menu.cost_multiplier', level.cost, level.pointsMultiplier),
            icon = 'crown',
            onSelect = function()
                local alert = lib.alertDialog({
                    header = locale('menu.confirm_purchase'),
                    content = locale('menu.confirm_purchase_desc', level.name, level.cost, 30, level.pointsMultiplier),
                    centered = true,
                    cancel = true,
                    labels = {
                        confirm = locale('menu.confirm'),
                        cancel = locale('menu.cancel')
                    }
                })

                if alert == 'confirm' then
                    BuyVipLevel(level.name)
                end
            end,
        })
    end

    lib.registerContext({
        id = 'vip_shop',
        title = locale('menu.vip_shop'),
        menu = 'vip_menu',
        options = options
    })
    lib.showContext('vip_shop')
end

function BuyVipLevel(levelName)
    lib.callback('dalton_vips:buyVipLevel', false, function(success, message)
        if success then
            lib.notify({
                id = 'vip_purchase_success',
                title = locale('notifications.success'),
                description = message,
                type = 'success',
                duration = 5000,
                position = 'top'
            })
        else
            lib.notify({
                id = 'vip_purchase_error',
                title = locale('notifications.error'),
                description = message,
                type = 'error',
                duration = 3000,
                position = 'top'
            })
        end
    end, levelName)
end
