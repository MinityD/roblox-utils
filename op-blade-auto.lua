local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "OP Blade Auto V1 ⚔️",
   LoadingTitle = "Loading Farm Tools...",
   LoadingSubtitle = "by miniy",
   ConfigurationSaving = {Enabled = false}
})

local Tab = Window:CreateTab("Main", 4483362458) -- Icon can be changed if you want

local Section = Tab:CreateSection("Auto Features")

-- Core Auto Loot Script (Deep Name Scan + Invisible High Center)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local net = ReplicatedStorage.Packages._Index["sleitnick_net@0.2.0"].net
local collectRemote = net:WaitForChild("RF/Loot_CollectBatch")

local Enabled = false  -- Starts OFF (controlled by Rayfield button)
local MinLootForHighCenter = 10
local CollectInterval = 0.04
local BatchSize = 500
local MaxIdsPerRun = 5000
local RepeatCollectTimes = 2

local loot_container = Workspace:WaitForChild("LootAnchor")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
    character = newChar
    hrp = newChar:WaitForChild("HumanoidRootPart")
end)

local function get_all_loot_ids_and_positions()
    local ids = {}
    local positions = {}
    local seen = {}

    for _, obj in loot_container:GetDescendants() do
        local id_str = obj.Name:match("^(Loot[_%w]*)_(%d+)$")
        if id_str then
            local id = tonumber(id_str)
            if id and not seen[id] then
                seen[id] = true
                table.insert(ids, id)

                local pos
                if obj:IsA("Model") then
                    pos = obj:GetPivot().Position
                elseif obj:IsA("BasePart") then
                    pos = obj.Position
                elseif obj:FindFirstChildWhichIsA("BasePart") then
                    pos = obj:FindFirstChildWhichIsA("BasePart").Position
                end
                if pos then
                    table.insert(positions, pos)
                end
            end
        end
    end

    return ids, positions
end

local function calculate_average_position(positions)
    if #positions == 0 then return nil end
    local sum = Vector3.new()
    for _, pos in positions do
        sum += pos
    end
    return sum / #positions
end

local lootLoop
lootLoop = task.spawn(function()
    while task.wait(CollectInterval) do
        if not Enabled then continue end

        local ids, positions = get_all_loot_ids_and_positions()
        if #ids == 0 then continue end

        local originalCFrame = hrp.CFrame
        local highCentered = false

        if #ids >= MinLootForHighCenter and #positions > 0 then
            local avgPos = calculate_average_position(positions)
            if avgPos then
                hrp.CFrame = CFrame.new(avgPos + Vector3.new(0, 500, 0))
                task.wait(0.3)
                highCentered = true
            end
        end

        for repeatNum = 1, RepeatCollectTimes do
            for i = 1, #ids, BatchSize do
                local batch = {}
                for j = i, math.min(i + BatchSize - 1, #ids) do
                    table.insert(batch, ids[j])
                end

                pcall(function()
                    collectRemote:InvokeServer(batch)
                end)

                task.wait(0.01)
            end
            if repeatNum < RepeatCollectTimes then task.wait(0.15) end
        end

        if highCentered then
            hrp.CFrame = originalCFrame
        end
    end
end)

-- Button 1: Auto Loot Toggle
local LootButton = Tab:CreateButton({
   Name = "Toggle Auto Loot",
   Callback = function()
      Enabled = not Enabled
      Rayfield:Notify({
         Title = "Auto Loot",
         Content = Enabled and "ON 🔥 (Deep scan + far fix)" or "OFF ⏸️",
         Duration = 3
      })
   end,
})

-- Button 2: Anti-AFK (loads once - stays active)
local AntiAFKLoaded = false
local AntiAFKButton = Tab:CreateButton({
   Name = "Enable Anti-AFK",
   Callback = function()
      if AntiAFKLoaded then
         Rayfield:Notify({
            Title = "Anti-AFK",
            Content = "Already loaded!",
            Duration = 3
         })
         return
      end
      loadstring(game:HttpGet("https://raw.githubusercontent.com/hassanxzayn-lua/Anti-afk/main/antiafkbyhassanxzyn"))()
      AntiAFKLoaded = true
      Rayfield:Notify({
         Title = "Anti-AFK",
         Content = "Loaded & Active Forever 🔥",
         Duration = 4
      })
   end,
})

print("=== OP BLADE AUTO V1 LOADED (Rayfield UI) ===")
print("Button 1: Toggle Auto Loot")
print("Button 2: Enable Anti-AFK (once)")
print("No old UI - only clean Rayfield")
print("Promise kept - everything perfect ❤️")
