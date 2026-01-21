Config = {}

-- General Settings
Config.Debug = false
Config.Framework = 'auto' -- 'esx', 'qb', or 'auto'

-- Pizzeria Location (Boss Interaction)
Config.Location = {
    pedModel = 's_m_y_chef_01',
    coords = vec4(287.7287, -964.0475, 28.4186, 358.9221),
    blip = {
        enabled = true,
        sprite = 267,
        color = 5, 
        scale = 0.7,
        label = "RealMarkus Pizza Job"
    }
}

-- Vehicle Preview (NUI Showroom)
Config.ShowVehicle = {
    enabled = true,
    spawnCoords = vec4(292.0, -956.0, 29.1, 88.0),
    camCoords = vec3(285.5, -960.5, 30.8),
    camLookAt = vec3(292.0, -956.0, 29.6)
}

-- Job Start / Garage
Config.Garage = {
    spawnPoint = vec4(292.0, -956.0, 29.1, 88.0),
    warpPed = true 
}

-- Economy
Config.Payout = {
    account = 'money', -- Target account
    min = 100,        -- Min payout per delivery
    max = 220         -- Max payout per delivery
}

-- Gameplay & Animations
Config.Work = {
    propName = 'prop_pizza_box_02',
    animDict = 'anim@heists@box_carry@',
    animClip = 'idle',
    payoutMessage = 'Delivery successful! You earned $%s',
    
    -- Handover Animation (Player and NPC)
    handover = {
        dict = 'mp_common',
        anim = 'givetake2_a',
        duration = 2000
    },
    
    -- Interaction messages
    labels = {
        knock = "Knock on door",
        waiting = "Waiting for customer...",
        give_pizza = "Deliver Pizza"
    }
}

-- Vehicle Target Bones 
Config.TargetBones = {
    cars = { 'boot', 'numberplate' },
    bikes = { 'seat_r', 'misc_a', 'wheel_rr', 'icebox' } 
}

-- Customer Ped Models 
Config.Customers = {
    'a_m_y_beach_01',
    'a_m_y_business_02',
    'a_f_m_bevhills_01',
    'a_f_y_hipster_01',
    'g_m_m_chigoon_02',
    'a_m_m_ktown_01'
}

-- Fleet Configuration (Sent to NUI)
-- Images must be located in the html/assets/ folder
Config.Fleet = {
    {
        label = "Delivery Scooters",
        image = "pizza_cat.png",
        vehicles = {
            { model = "faggio",  label = "Faggio", price = 0 },
        }
    },
    {
        label = "Delivery Car",
        image = "pizza_van.png",
        vehicles = {
            { model = "blista",   label = "Blista",    price = 0 },
        }
    }
}

-- Delivery Locations
Config.Routes = {
    -- VESPUCCI
    vec3(-1182.67, -1064.47, 2.15),
    vec3(-1161.30, -1100.09, 2.22),
    vec3(-1114.03, -1069.30, 2.15),
    vec3(-1076.30, -1027.02, 4.54),

    -- MIRROR PARK
    vec3(1241.39, -566.44, 69.66),
    vec3(1389.04, -569.41, 74.50),
    vec3(1049.09, -479.91, 64.10),
    vec3(1098.63, -464.46, 67.32),

    -- STRAWBERRY
    vec3(152.92, -1823.62, 27.87),
    vec3(103.98, -1885.40, 24.32),
    vec3(171.65, -1871.51, 24.40),
    vec3(270.39, -1916.98, 26.18),
    vec3(329.46, -1845.89, 27.75),

    -- ROCKFORD HILLS 
    vec3(-788.36, -6.62, 40.87),
    vec3(-598.69, 147.82, 61.67),
    vec3(-511.18, 100.07, 63.80),
    vec3(-507.12, 100.64, 63.80),

    -- WEST VINEWOOD 
    vec3(239.44, 242.96, 106.68),
    vec3(412.87, 152.36, 103.21),
    vec3(454.36, 80.81, 98.57)
}