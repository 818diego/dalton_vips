# 👑 DaltonLife VIP System

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![FiveM](https://img.shields.io/badge/FiveM-Ready-brightgreen)
![Framework](https://img.shields.io/badge/Framework-QBOX-red)
![Version](https://img.shields.io/badge/version-0.1-success)

A VIP system for FiveM with a points system, levels, referral codes, and Tebex integration. Compatible with QBOX.

## 📋 Features

- ✨ VIP points system with multipliers (e.g., you receive 1 point for playing 30 minutes)
- 👑 3 VIP levels (Bronze, Silver, Gold)
- ⏱️ VIP duration system (30 days)
- 🎁 Referral codes
- 💳 Tebex integration

## 📦 Dependencies

- [QBOX](https://github.com/Qbox-project)
- [oxmysql](https://github.com/overextended/oxmysql)
- [ox_lib](https://github.com/overextended/ox_lib)

## 💽 Installation

1. Make sure you have all dependencies installed
2. Copy the `dalton_vips` folder to your resources folder
3. Import the `sql/InstallSQL.sql` file into your database
4. Add `ensure dalton_vips` to your `server.cfg`
5. Configure your Tebex key in `config/config.lua`

## 📚 Commands

| Command                          | Description              |
| -------------------------------- | ------------------------ |
| `/vip`                           | Opens the VIP menu       |
| `/viphelp`                       | Shows the system help    |
| `/referred [code]`               | Uses a referral code     |
| `/redeem [transactionId]`        | Redeems a Tebex purchase |
| `/addPoints [playerId] [points]` | (Admin) Adds VIP points  |

## 🔧 Exports

### Server

```lua
-- Get VIP data of a player
exports['dalton_vips']:GetPlayerVipData(player)

-- Add VIP points
exports['dalton_vips']:AddVipPoints(player, amount)

-- Get current VIP level
exports['dalton_vips']:GetVipLevelName(player)

-- Buy VIP level
exports['dalton_vips']:BuyVipLevel(player, levelName)

-- Get VIP level info by name
exports['dalton_vips']:GetVipLevelByName(levelName)

-- Use referral code
exports['dalton_vips']:UseReferralCode(player, code)
```

## 🛡️ License

This project is under the MIT License. See the [LICENSE](LICENSE) file for more details.

## 👥 Contribute

Contributions are welcome. Please open an issue or pull request to suggest changes or improvements.

## ❤️ Credits

Developed with ❤️ by 818diego
