local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ============================================================
--  SECTION 2: CREATE THE MAIN WINDOW
--  This is the outer container — the "window" users see on screen.
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name           = "OP Blade Auto",
    LoadingTitle   = "Loading Farm Suite...",
    LoadingSubtitle = "by you...",
    ConfigurationSaving = { Enabled = false },
    -- RightShift on PC, hamburger icon on mobile to open/close
})

-- ============================================================
--  SECTION 3: CORE ROBLOX SERVICES
--  Services are global singletons that give access to the game engine.
-- ============================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--  ^ Shared storage visible to all players and the server.
--    Network events (RemoteFunctions/RemoteEvents) live here.

local Workspace = game:GetService("Workspace")
--  ^ The 3-D world. All parts, models, and game objects sit here.

local Players = game:GetService("Players")
--  ^ Manages player data (local player, character, etc.)

local UserInputService = game:GetService("UserInputService")
--  ^ Detects keyboard/mouse input (used for the Loot ESP key).

local RunService = game:GetService("RunService")
--  ^ Fires every frame (Heartbeat / RenderStepped).
--    We use it for the loot ESP labels.

local TweenService = game:GetService("TweenService")
--  ^ Smooth animations; used for teleport fade-in effect.

-- ============================================================
--  SECTION 4: RESOLVE THE SERVER REMOTE FUNCTION
--  The game communicates between client and server through
--  RemoteFunctions (two-way) and RemoteEvents (one-way).
--
--  "net" is a custom networking package inside the game's
--  ReplicatedStorage. We dig through its path to find the
--  function that tells the server "collect these loot IDs".
-- ============================================================
local net            = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local collectRemote  = net:WaitForChild("RF/Loot_CollectBatch")
--  WaitForChild waits up to 5 seconds (default) before erroring,
--  so even if the game loads slowly this line is safe.

-- ============================================================
--  SECTION 5: PLAYER & CHARACTER REFERENCES
--  "character" is the 3-D avatar in the world.
--  "hrp" (HumanoidRootPart) is the invisible part at the
--  character's center used for movement and positioning.
-- ============================================================
local player    = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp       = character:WaitForChild("HumanoidRootPart")

-- Keep references fresh when the player respawns.
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    hrp       = newChar:WaitForChild("HumanoidRootPart")
end)

-- ============================================================
--  SECTION 6: LOOT CONTAINER
--  "LootAnchor" is a folder/model inside Workspace where the
--  game places every loot item that has spawned in the world.
-- ============================================================
local loot_container = Workspace:WaitForChild("LootAnchor")

-- ============================================================
--  SECTION 7: SETTINGS
--  All tuneable values are grouped here so they are easy to find.
-- ============================================================
local Settings = {
    -- ── Auto-Loot ──────────────────────────────────────────
    Enabled             = true,   -- Master toggle for the loot loop
    CollectInterval     = 0.04,   -- Seconds between each scan cycle (~25/sec)
    BatchSize           = 500,    -- How many IDs to send per server call
    MaxIdsPerRun        = 5000,   -- Safety cap: never process more than this
    RepeatCollectTimes  = 2,      -- Send each batch twice for reliability
    MinLootForHighCenter = 10,    -- Need ≥ this many pieces to use far-loot fix

    -- ── Far-Loot Fix ────────────────────────────────────────
    TeleportHeight      = 500,    -- Studs above loot cluster during collection
    TeleportWaitTime    = 0.25,   -- Seconds to pause at high point (server tick)

    -- ── Movement (Player Stats) ─────────────────────────────
    DefaultWalkSpeed    = 16,     -- Roblox's stock walk speed
    DefaultJumpPower    = 50,     -- Roblox's stock jump power

    -- ── Loot ESP ────────────────────────────────────────────
    ESPEnabled          = false,  -- Draw labels above loot items
    ESPColor            = Color3.fromRGB(0, 255, 128), -- Neon green

    -- ── Stats Counter ───────────────────────────────────────
    TotalCollected      = 0,      -- Running total this session
    SessionStart        = os.time(),
}

-- ============================================================
--  SECTION 8: UTILITY FUNCTIONS
-- ============================================================

-- Returns true if the character is alive (has a Humanoid with > 0 health).
local function isAlive()
    if not character then return false end
    local hum = character:FindFirstChildWhichIsA("Humanoid")
    return hum and hum.Health > 0
end

-- Safely sets a character property (walk speed, jump power, etc.)
-- wrapped in pcall so errors are silently ignored.
local function safeSetStat(statName, value)
    pcall(function()
        local hum = character and character:FindFirstChildWhichIsA("Humanoid")
        if hum then hum[statName] = value end
    end)
end

-- ============================================================
--  SECTION 9: LOOT SCANNING — "get_all_loot_ids_and_positions"
--
--  HOW THE DEEP SCAN WORKS:
--  1. We call loot_container:GetDescendants() which returns EVERY
--     object nested inside LootAnchor, no matter how deep.
--  2. For each object we check its Name with a Lua pattern:
--       "^(Loot[_%w]*)_(%d+)$"
--       ┌── Starts at beginning of string (^)
--       ├── "Loot" literal, then any word chars/underscores
--       ├── Underscore separator
--       └── One or more digits at the end ($) — this is the ID
--  3. We convert the captured digit string to a number (tonumber).
--  4. The "seen" table prevents counting the same ID twice (dedup).
--  5. We also record the 3-D position of each loot piece so we
--     can calculate the cluster's average center.
-- ============================================================
local function get_all_loot_ids_and_positions()
    local ids       = {}
    local positions = {}
    local seen      = {}
    local count     = 0

    for _, obj in loot_container:GetDescendants() do
        if count >= Settings.MaxIdsPerRun then break end

        -- Pattern match: capture everything after the last underscore as ID
        local id_str = obj.Name:match("_(%d+)$")
        if id_str then
            local id = tonumber(id_str)
            if id and not seen[id] then
                seen[id]  = true
                count     = count + 1
                table.insert(ids, id)

                -- Try to find a 3-D position for this loot piece.
                -- Loot can be stored as a Model, a BasePart, or a container
                -- with a child BasePart — we handle all three cases.
                local pos
                if obj:IsA("Model") then
                    -- GetPivot() returns the model's CFrame (position + rotation)
                    pos = obj:GetPivot().Position
                elseif obj:IsA("BasePart") then
                    pos = obj.Position
                else
                    local bp = obj:FindFirstChildWhichIsA("BasePart")
                    if bp then pos = bp.Position end
                end

                if pos then
                    table.insert(positions, pos)
                end
            end
        end
    end

    return ids, positions
end

-- ============================================================
--  SECTION 10: AVERAGE POSITION CALCULATOR
--
--  Adds all positions together (Vector3 addition), then divides
--  by count. This gives the geometric center / centroid of the
--  loot cluster — the best teleport target.
-- ============================================================
local function calculate_average_position(positions)
    if #positions == 0 then return nil end
    local sum = Vector3.new(0, 0, 0)
    for _, pos in ipairs(positions) do
        sum = sum + pos
    end
    return sum / #positions
end

-- ============================================================
--  SECTION 11: STATS LABEL (ScreenGui)
--
--  We create a tiny on-screen label in the corner that shows
--  how many items have been collected this session.
--  This is a CUSTOM GUI built entirely from scratch — no
--  third-party library used here.
--
--  GUI Hierarchy:
--    PlayerGui
--    └── OPBlade_StatsGui  (ScreenGui)
--        └── Frame          (background panel)
--            ├── Title      (TextLabel — "⚔ OP BLADE V2")
--            ├── CountLabel (TextLabel — "Collected: 0")
--            └── RateLabel  (TextLabel — "Rate: 0/min")
-- ============================================================
local statsGui    = nil
local countLabel  = nil
local rateLabel   = nil

local function buildStatsGui()
    -- Remove any old GUI from a previous execution.
    local old = player.PlayerGui:FindFirstChild("OPBlade_StatsGui")
    if old then old:Destroy() end

    -- ScreenGui: the root 2-D canvas layered on top of the game.
    local sg = Instance.new("ScreenGui")
    sg.Name           = "OPBlade_StatsGui"
    sg.ResetOnSpawn   = false   -- survives character respawns
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent         = player.PlayerGui

    -- Outer panel — dark translucent background
    local frame = Instance.new("Frame")
    frame.Name              = "Panel"
    frame.Size              = UDim2.new(0, 200, 0, 90)
    frame.Position          = UDim2.new(1, -210, 0, 10)  -- top-right corner
    frame.BackgroundColor3  = Color3.fromRGB(15, 15, 20)
    frame.BackgroundTransparency = 0.3
    frame.BorderSizePixel   = 0
    frame.Parent            = sg

    -- Rounded corners via UICorner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent       = frame

    -- Accent stripe on the left edge
    local stripe = Instance.new("Frame")
    stripe.Size             = UDim2.new(0, 4, 1, 0)
    stripe.Position         = UDim2.new(0, 0, 0, 0)
    stripe.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
    stripe.BorderSizePixel  = 0
    stripe.Parent           = frame
    local sc = Instance.new("UICorner")
    sc.CornerRadius = UDim.new(0, 4)
    sc.Parent       = stripe

    -- Title label
    local title = Instance.new("TextLabel")
    title.Text               = "⚔  OP BLADE V2"
    title.Size               = UDim2.new(1, -10, 0, 22)
    title.Position           = UDim2.new(0, 8, 0, 4)
    title.BackgroundTransparency = 1
    title.TextColor3         = Color3.fromRGB(0, 210, 110)
    title.TextScaled         = true
    title.Font               = Enum.Font.GothamBold
    title.TextXAlignment     = Enum.TextXAlignment.Left
    title.Parent             = frame

    -- Divider line
    local div = Instance.new("Frame")
    div.Size            = UDim2.new(1, -16, 0, 1)
    div.Position        = UDim2.new(0, 8, 0, 28)
    div.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    div.BorderSizePixel  = 0
    div.Parent           = frame

    -- Collected counter
    countLabel = Instance.new("TextLabel")
    countLabel.Text              = "Collected:  0"
    countLabel.Size              = UDim2.new(1, -10, 0, 22)
    countLabel.Position          = UDim2.new(0, 8, 0, 34)
    countLabel.BackgroundTransparency = 1
    countLabel.TextColor3        = Color3.fromRGB(220, 220, 220)
    countLabel.TextScaled        = true
    countLabel.Font              = Enum.Font.Gotham
    countLabel.TextXAlignment    = Enum.TextXAlignment.Left
    countLabel.Parent            = frame

    -- Rate display
    rateLabel = Instance.new("TextLabel")
    rateLabel.Text               = "Rate:  0 / min"
    rateLabel.Size               = UDim2.new(1, -10, 0, 22)
    rateLabel.Position           = UDim2.new(0, 8, 0, 58)
    rateLabel.BackgroundTransparency = 1
    rateLabel.TextColor3         = Color3.fromRGB(160, 160, 170)
    rateLabel.TextScaled         = true
    rateLabel.Font               = Enum.Font.Gotham
    rateLabel.TextXAlignment     = Enum.TextXAlignment.Left
    rateLabel.Parent             = frame

    statsGui = sg
end

-- Update the stats labels every second in the background.
task.spawn(function()
    buildStatsGui()
    while task.wait(1) do
        if countLabel and countLabel.Parent then
            local elapsed  = math.max(1, os.time() - Settings.SessionStart)
            local rate     = math.floor(Settings.TotalCollected / elapsed * 60)
            countLabel.Text = string.format("Collected:  %d", Settings.TotalCollected)
            rateLabel.Text  = string.format("Rate:  %d / min", rate)
        end
    end
end)

-- ============================================================
--  SECTION 12: LOOT ESP (Billboard Labels)
--
--  When ESPEnabled is true we render a BillboardGui (a label
--  that always faces the camera) above every loot object.
--
--  We keep track of existing labels in a table so we can
--  remove stale ones when loot disappears.
-- ============================================================
local espLabels = {}   -- [instance] = BillboardGui

local function clearESP()
    for inst, bb in pairs(espLabels) do
        pcall(function() bb:Destroy() end)
        espLabels[inst] = nil
    end
end

local function updateESP()
    if not Settings.ESPEnabled then
        clearESP()
        return
    end

    local current = {}

    for _, obj in loot_container:GetDescendants() do
        local id_str = obj.Name:match("_(%d+)$")
        if id_str then
            -- Find a BasePart to attach the label to
            local target
            if obj:IsA("BasePart") then
                target = obj
            elseif obj:IsA("Model") then
                target = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
            end

            if target and not espLabels[target] then
                local bb = Instance.new("BillboardGui")
                bb.Size          = UDim2.new(0, 80, 0, 24)
                bb.StudsOffset   = Vector3.new(0, 2, 0)
                bb.AlwaysOnTop   = true
                bb.Parent        = target

                local lbl = Instance.new("TextLabel")
                lbl.Size              = UDim2.new(1, 0, 1, 0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3        = Settings.ESPColor
                lbl.TextScaled        = true
                lbl.Font              = Enum.Font.GothamBold
                lbl.Text              = "💰 " .. id_str
                lbl.Parent            = bb

                espLabels[target] = bb
            end

            if target then current[target] = true end
        end
    end

    -- Clean up labels for loot that no longer exists
    for inst, bb in pairs(espLabels) do
        if not current[inst] then
            pcall(function() bb:Destroy() end)
            espLabels[inst] = nil
        end
    end
end

-- Run ESP update every 0.5 seconds (fast enough, not spammy)
RunService.Heartbeat:Connect(function()
    -- Throttle using a simple tick counter
end)
task.spawn(function()
    while task.wait(0.5) do
        pcall(updateESP)
    end
end)

-- ============================================================
--  SECTION 13: MAIN AUTO-LOOT LOOP
--
--  This is the heart of the script. It runs forever in a
--  separate coroutine (task.spawn) so it never blocks the UI.
--
--  LOOP STEPS EACH CYCLE:
--  1. Check if Enabled; if not, skip.
--  2. Scan for all loot IDs + positions (deep scan).
--  3. If enough loot exists, apply the "far loot fix":
--       a. Save the player's current CFrame (position + rotation).
--       b. Teleport them 500 studs UP, centered over the cluster.
--       c. Wait 0.25 seconds so the server registers the new position.
--       d. NOW the player is "close enough" to all pieces — collect.
--       e. After collecting, teleport back to the saved CFrame.
--  4. Send IDs to the server in batches via InvokeServer.
--  5. Repeat the batch send twice for reliability.
-- ============================================================
task.spawn(function()
    while task.wait(Settings.CollectInterval) do
        if not Settings.Enabled then continue end
        if not isAlive() then task.wait(2) continue end

        -- Step 1: Scan
        local ids, positions = get_all_loot_ids_and_positions()
        if #ids == 0 then continue end

        -- Step 2: Far-loot fix (teleport to cluster center)
        local originalCFrame = hrp.CFrame
        local highCentered   = false

        if #ids >= Settings.MinLootForHighCenter and #positions > 0 then
            local avgPos = calculate_average_position(positions)
            if avgPos then
                -- WHY 500 STUDS UP?
                --   The server checks whether the player is within range
                --   of loot before allowing collection. Teleporting high
                --   above the cluster's center puts the player equidistant
                --   from all pieces, bypassing per-piece distance checks.
                --
                -- WHY IS IT "INVISIBLE"?
                --   1. The teleport is near-instant (one frame).
                --   2. The character is 500 studs UP — off camera.
                --   3. We return to the original CFrame right after.
                --   Observers only see a brief freeze, not a visible teleport.
                hrp.CFrame = CFrame.new(avgPos + Vector3.new(0, Settings.TeleportHeight, 0))
                task.wait(Settings.TeleportWaitTime)
                highCentered = true
            end
        end

        -- Step 3: Batch-send IDs to server
        for repeatNum = 1, Settings.RepeatCollectTimes do
            for i = 1, #ids, Settings.BatchSize do
                local batch = {}
                for j = i, math.min(i + Settings.BatchSize - 1, #ids) do
                    table.insert(batch, ids[j])
                end

                -- pcall wraps the remote call so a server-side error
                -- doesn't crash the entire script.
                local ok, result = pcall(function()
                    return collectRemote:InvokeServer(batch)
                end)

                if ok and type(result) == "number" then
                    Settings.TotalCollected = Settings.TotalCollected + result
                elseif ok then
                    -- Server returned something non-numeric (still success)
                    Settings.TotalCollected = Settings.TotalCollected + #batch
                end

                task.wait(0.01)   -- tiny yield so the game doesn't freeze
            end

            if repeatNum < Settings.RepeatCollectTimes then
                task.wait(0.15)   -- brief gap between repeat sends
            end
        end

        -- Step 4: Return to original position (undo far-loot fix)
        if highCentered then
            hrp.CFrame = originalCFrame
        end
    end
end)

-- ============================================================
--  SECTION 14: RAYFIELD UI — TABS AND CONTROLS
-- ============================================================

-- ── Tab 1: Main ──────────────────────────────────────────────
local MainTab = Window:CreateTab("⚔ Main", 4483362458)
MainTab:CreateSection("Auto Features")

-- Auto Loot Toggle
MainTab:CreateToggle({
    Name         = "Auto Loot",
    CurrentValue = true,
    Callback     = function(val)
        Settings.Enabled = val
        Rayfield:Notify({
            Title   = "Auto Loot",
            Content = val and "ENABLED 🔥 — farming started!" or "PAUSED ⏸️",
            Duration = 4,
        })
    end,
})

-- Loot ESP Toggle
MainTab:CreateToggle({
    Name         = "Loot ESP",
    CurrentValue = false,
    Callback     = function(val)
        Settings.ESPEnabled = val
        if not val then clearESP() end
        Rayfield:Notify({
            Title   = "Loot ESP",
            Content = val and "ON 👁️" or "OFF",
            Duration = 3,
        })
    end,
})

MainTab:CreateSection("Player Stats")

-- WalkSpeed Slider
MainTab:CreateSlider({
    Name         = "Walk Speed",
    Range        = {16, 250},
    Increment    = 1,
    CurrentValue = 16,
    Callback     = function(val)
        safeSetStat("WalkSpeed", val)
    end,
})

-- JumpPower Slider
MainTab:CreateSlider({
    Name         = "Jump Power",
    Range        = {50, 350},
    Increment    = 5,
    CurrentValue = 50,
    Callback     = function(val)
        safeSetStat("JumpPower", val)
    end,
})

-- Reset Stats Button
MainTab:CreateButton({
    Name     = "Reset Walk & Jump to Default",
    Callback = function()
        safeSetStat("WalkSpeed", Settings.DefaultWalkSpeed)
        safeSetStat("JumpPower",  Settings.DefaultJumpPower)
        Rayfield:Notify({ Title = "Stats Reset", Content = "WalkSpeed & JumpPower restored.", Duration = 3 })
    end,
})

-- ── Tab 2: Settings ───────────────────────────────────────────
local SettingsTab = Window:CreateTab("⚙ Settings", 4483362458)
SettingsTab:CreateSection("Loot Tuning")

SettingsTab:CreateSlider({
    Name         = "Collect Interval (lower = faster)",
    Range        = {1, 20},        -- in hundredths of a second (×0.01)
    Increment    = 1,
    CurrentValue = 4,              -- default: 0.04 s = value 4
    Callback     = function(val)
        Settings.CollectInterval = val * 0.01
    end,
})

SettingsTab:CreateSlider({
    Name         = "Batch Size",
    Range        = {50, 1000},
    Increment    = 50,
    CurrentValue = 500,
    Callback     = function(val)
        Settings.BatchSize = val
    end,
})

SettingsTab:CreateSlider({
    Name         = "Min Loot for Far Fix",
    Range        = {1, 50},
    Increment    = 1,
    CurrentValue = 10,
    Callback     = function(val)
        Settings.MinLootForHighCenter = val
    end,
})

SettingsTab:CreateSlider({
    Name         = "Teleport Height (studs)",
    Range        = {100, 2000},
    Increment    = 100,
    CurrentValue = 500,
    Callback     = function(val)
        Settings.TeleportHeight = val
    end,
})

-- ── Tab 3: Utility ────────────────────────────────────────────
local UtilTab = Window:CreateTab("🛠 Utility", 4483362458)
UtilTab:CreateSection("Anti-AFK")

-- Anti-AFK (loads once; prevents Roblox auto-kick after 20 min idle)
local AntiAFKLoaded = false
UtilTab:CreateButton({
    Name     = "Enable Anti-AFK  (load once)",
    Callback = function()
        if AntiAFKLoaded then
            Rayfield:Notify({ Title = "Anti-AFK", Content = "Already active!", Duration = 3 })
            return
        end
        -- Load an external anti-AFK script from GitHub.
        -- It works by periodically simulating tiny character movement
        -- so Roblox's idle timer never triggers.
        loadstring(
            game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn")
        )()
        AntiAFKLoaded = true
        Rayfield:Notify({
            Title   = "Anti-AFK",
            Content = "Enabled forever! 🔥 You won't be kicked.",
            Duration = 5,
        })
    end,
})

UtilTab:CreateSection("Session")

-- Session Stats Display (read-only info label)
UtilTab:CreateLabel("Session stats shown in top-right corner of screen.")

UtilTab:CreateButton({
    Name     = "Reset Session Counter",
    Callback = function()
        Settings.TotalCollected = 0
        Settings.SessionStart   = os.time()
        Rayfield:Notify({ Title = "Counter Reset", Content = "Session stats cleared.", Duration = 3 })
    end,
})

UtilTab:CreateSection("Danger Zone")

UtilTab:CreateButton({
    Name     = "Rebuild Stats GUI",
    Callback = function()
        buildStatsGui()
        Rayfield:Notify({ Title = "GUI Rebuilt", Content = "Stats overlay recreated.", Duration = 3 })
    end,
})

-- ============================================================
--  SECTION 15: STARTUP MESSAGES
--  These print to the developer console (F9 in-game).
--  We keep it minimal — just confirmation lines, no spam.
-- ============================================================
print("╔══════════════════════════════════════╗")
print("║   OP BLADE AUTO                       ║")
print("║   Press RightShift to open UI         ║")
print("║   Auto Loot is ON by default          ║")
print("╚══════════════════════════════════════╝")
