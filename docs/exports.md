# Dalton VIPs Exports Documentation

This document explains how to use the exports from the `dalton_vips` resource.

## Important Note

All exports in this resource are **server-side only**. They cannot be used directly from the client side.

If you need to access VIP information from the client, you should create your own server callbacks that use these exports and then call those callbacks from the client.

## Available Exports

### VIP Information

#### GetPlayerVipData

Gets a player's complete VIP data or a specific field.

```lua
-- Get all VIP data
local vipData = exports['dalton_vips']:GetPlayerVipData(player)

-- Get specific field (e.g., vip_points)
local points = exports['dalton_vips']:GetPlayerVipData(player, 'vip_points')
```

#### GetVipLevelName

Gets the name of a player's current VIP level.

```lua
local vipLevel = exports['dalton_vips']:GetVipLevelName(player)
```

#### GetVipLevelByName

Gets the configuration data for a VIP level by its name.

```lua
local levelData = exports['dalton_vips']:GetVipLevelByName('VIP Premium')
-- levelData will include pointsMultiplier and other configured properties
```

### VIP Management

#### BuyVipLevel

Purchase a VIP level for a player.

```lua
local success, message = exports['dalton_vips']:BuyVipLevel(player, 'VIP Premium')
if success then
    -- VIP level purchased successfully
else
    -- Handle error (message contains the error text)
end
```

### Points Management

#### AddVipPoints

Add VIP points to a player.

```lua
local success, message = exports['dalton_vips']:AddVipPoints(player, 500)
if success then
    -- Points added successfully
else
    -- Handle error
end
```

#### UseReferralCode

Allow a player to use a referral code to get VIP points.

```lua
local success, message = exports['dalton_vips']:UseReferralCode(player, 'WELCOME2023')
if success then
    -- Referral code used successfully
else
    -- Handle error
end
```

## Example Usage in Another Resource

### Server-side usage

```lua
-- In a server file of another resource
RegisterCommand('givevippoints', function(source, args)
    local playerId = tonumber(args[1])
    local points = tonumber(args[2])

    if not playerId or not points then return end

    local player = exports.qbx_core:GetPlayer(playerId)
    if not player then return end

    local success, message = exports['dalton_vips']:AddVipPoints(player, points)
    print(success, message)
end, true)
```

### Client-to-Server Communication

If you need to access VIP data from the client, create your own callbacks:

```lua
-- In your resource's server.lua
lib.callback.register('yourresource:getPlayerVipLevel', function(source)
    local player = exports.qbx_core:GetPlayer(source)
    if not player then return nil end

    return exports['dalton_vips']:GetVipLevelName(player)
end)

-- In your resource's client.lua
lib.callback('yourresource:getPlayerVipLevel', false, function(vipLevel)
    if vipLevel then
        print('Your VIP level is: ' .. vipLevel)
    end
end)
```
