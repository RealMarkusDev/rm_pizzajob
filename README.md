# 🍕 RM Pizza Job (Real Markus Pizzeria)

**RM Pizza Job** is a fully optimized and secure pizza delivery job for FiveM. Designed for serious RP servers, it features a modern NUI, server-side checks, and full integration with `ox_lib` and `ox_target`.

![License](https://img.shields.io/badge/License-Proprietary-red)
![Framework](https://img.shields.io/badge/Framework-ESX%20%7C%20QBCore-blue)
![Version](https://img.shields.io/badge/Version-1.0.0-green)

Showcase: https://www.youtube.com/watch?v=t9yg9tJl18U
Discord: https://discord.gg/7TZBfTazu9 (More scripts coming soon 🔥🚀)
## ✨ Features

- **🛡️ Secure Architecture:** Server-side vehicle spawning and payout validation (exploit protection).
- **🎨 Modern NUI:** Clean HTML/CSS/JS interface for job selection and shift summary.
- **👁️ ox_target Integration:** No markers or text 3D. Interact naturally with NPCs, vehicles, and doors.
- **📦 Prop & Animation Handling:** Realistic pizza box carrying with sticky animations.
- **🗺️ Smart Routing:** Random delivery routes that reset upon completion.
- **🚗 Fleet Management:** Configurable vehicles via NUI.
- **💾 Framework Agnostic:** Auto-detects ESX or QBCore.

## 📋 Dependencies

This resource relies on the standard Overextended stack for best performance.

- [ox_lib](https://github.com/overextended/ox_lib) (Required for UI, Callbacks, Math)
- [ox_target](https://github.com/overextended/ox_target) (Required for interactions)
- **Framework:** `es_extended` (Legacy/1.10+) OR `qb-core`

## 🛠️ Installation

1. **Download** the resource and place it in your `resources` folder.
2. **Rename** the folder to `rm_pizzajob` (if it isn't already).
3. **Configure** the `shared/config.lua` to your liking (prices, vehicles, coordinates).
4. **Add** the following to your `server.cfg` (ensure it starts **after** dependencies):

```cfg
ensure ox_lib
ensure ox_target
ensure rm_pizzajob

## 📜 License

RM Pizza Job is provided for **personal and server use only**.

You are allowed to:
✔ Use this resource on your FiveM server
✔ Modify it for personal/server needs

You are NOT allowed to:
❌ Resell this script (in part or full)
❌ Redistribute without permission
❌ Claim this work as your own

Real Markus Development. All rights reserved.

