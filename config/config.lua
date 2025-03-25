Config = {}

Config.PointsInterval = 1       -- Interval in minutes to give points
Config.PointsAmount = 1         -- Base amount of points given per interval
Config.NotifyPlayer = true      -- Whether to notify the player when receiving/buying VIP
Config.VipDuration = 2592000000 -- VIP duration in milliseconds (30 days by default)

-- Referral codes system
Config.ReferralCodes = {
    ["supremo"] = 500, -- The code "supremo" will grant 500 points
    ["dalton"] = 300,  -- The code "dalton" will grant 300 points
}

-- Cache data save interval (in seconds)
Config.SaveInterval = 300 -- 5 minutes

Config.VipLevels = {
    -- Default level is "No VIP" (0 points)
    { name = "Bronze", cost = 1000, pointsMultiplier = 2 },
    { name = "Silver", cost = 1800, pointsMultiplier = 3 },
    { name = "Gold",   cost = 2500, pointsMultiplier = 4 }
}

-- Tebex Configuration
Config.TebexAPI = {
    SecretKey = "YourApiSecretKey", -- Replace with your Tebex secret key
    Enabled = true,                 -- Enable/disable Tebex integration
    PackageRewards = {              -- Package ID and VIP points it grants
        [1234567] = 1000,           -- Package with ID 100001 will grant 1000 VIP points
        -- Add more packages as needed
    }
}
