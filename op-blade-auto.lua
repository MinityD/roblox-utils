-- OP Blade Auto Farm Script (2026 Mobile-Friendly)
-- Auto collect loot, auto rebirth, noclip, anti-AFK
-- Use in OP Blade game - test on alt!

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local root = char:WaitForChild("HumanoidRootPart")

local autoFarm = true  -- toggle by re-executing

print("OP Blade Auto Farm ON! Re-execute to toggle OFF.")

-- Noclip (walk through walls)
local noclip = true
game:GetService("RunService").Stepped:Connect(function()
    if not noclip then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- Auto collect loot/items (firetouch drops/coins)
spawn(function()
    while autoFarm do
        wait(0.5)
        for _, obj in pairs(workspace:GetChildren()) do
            if obj:IsA("BasePart") and (obj.Name:lower():find("coin") or obj.Name:lower():find("loot") or obj.Name:lower():find("drop") or obj.Name:lower():find("chest")) then
                firetouchinterest(root, obj, 0)
                wait(0.1)
                firetouchinterest(root, obj, 1)
            end
        end
    end
end)

-- Auto rebirth (check GUI button or remote - adjust name if needed)
spawn(function()
    while autoFarm do
        wait(10)  -- check every 10s
        pcall(function()
            local rebirthGui = player.PlayerGui:FindFirstChild("Rebirth", true) or player.PlayerGui:FindFirstChild("RebirthButton", true)
            if rebirthGui and rebirthGui:IsA("TextButton") then
                firesignal(rebirthGui.MouseButton1Click)
                print("Auto Rebirth triggered!")
            end
            -- Or fire remote if game uses one
            local rs = game:GetService("ReplicatedStorage")
            if rs:FindFirstChild("RebirthEvent") then
                rs.RebirthEvent:FireServer()
            end
        end)
    end
end)

-- Anti-AFK (simulate jump/move to avoid kick)
spawn(function()
    while autoFarm do
        wait(math.random(60, 120))
        hum.Jump = true
        root.Velocity = root.Velocity + Vector3.new(math.random(-10,10), 0, math.random(-10,10))
    end
end)

-- God mode attempt (high health, ignore damage)
hum.MaxHealth = math.huge
hum.Health = math.huge

-- Toggle off on re-execute (simple flip)
autoFarm = not autoFarm
if not autoFarm then print("Auto Farm OFF") end
