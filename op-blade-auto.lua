-- OP Blade Auto Farm GUI (Rayfield UI - 2026 Mobile-Friendly)
-- Toggle features in GUI | Re-execute to reload

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "OP Blade Auto Farm 😎",
   LoadingTitle = "Loading Auto Features...",
   LoadingSubtitle = "by miniy",
   ConfigurationSaving = {
      Enabled = false,
      FolderName = nil,
      FileName = "OPBladeConfig"
   }
})

local Tab = Window:CreateTab("Main", 4483362458) -- Icon ID example

local Section = Tab:CreateSection("Auto Farm Controls")

local autoCollectEnabled = false
local noclipEnabled = false
local autoRebirthEnabled = false

-- Auto Collect Loot
Tab:CreateToggle({
   Name = "Auto Collect Loot",
   CurrentValue = false,
   Flag = "AutoCollect",
   Callback = function(Value)
      autoCollectEnabled = Value
      Rayfield:Notify({
         Title = "Auto Collect",
         Content = Value and "Enabled - Loot auto-picks up!" or "Disabled",
         Duration = 3
      })
   end
})

spawn(function()
   while true do
      wait(0.5)
      if not autoCollectEnabled then continue end
      for _, obj in pairs(workspace:GetChildren()) do
         if obj:IsA("BasePart") and (obj.Name:lower():find("coin") or obj.Name:lower():find("loot") or obj.Name:lower():find("drop") or obj.Name:lower():find("chest") or obj.Name:lower():find("gem") or obj.Name:lower():find("reward")) then
            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, obj, 0)
            wait(0.1)
            firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart, obj, 1)
         end
      end
   end
end)

-- Noclip Toggle
Tab:CreateToggle({
   Name = "Noclip (Walk Through Walls)",
   CurrentValue = false,
   Flag = "Noclip",
   Callback = function(Value)
      noclipEnabled = Value
      Rayfield:Notify({
         Title = "Noclip",
         Content = Value and "Enabled - Phase through everything!" or "Disabled",
         Duration = 3
      })
   end
})

game:GetService("RunService").Stepped:Connect(function()
   if not noclipEnabled then return end
   local char = game.Players.LocalPlayer.Character
   if char then
      for _, part in pairs(char:GetDescendants()) do
         if part:IsA("BasePart") then
            part.CanCollide = false
         end
      end
   end
end)

-- Auto Rebirth Toggle
Tab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Flag = "AutoRebirth",
   Callback = function(Value)
      autoRebirthEnabled = Value
      Rayfield:Notify({
         Title = "Auto Rebirth",
         Content = Value and "Enabled - Rebirths when ready!" or "Disabled",
         Duration = 3
      })
   end
})

spawn(function()
   while true do
      wait(10)
      if not autoRebirthEnabled then continue end
      pcall(function()
         local rebirthGui = game.Players.LocalPlayer.PlayerGui:FindFirstChild("Rebirth", true) or game.Players.LocalPlayer.PlayerGui:FindFirstChild("RebirthButton", true) or game.Players.LocalPlayer.PlayerGui:FindFirstChild("Prestige", true)
         if rebirthGui and rebirthGui:IsA("TextButton") then
            firesignal(rebirthGui.MouseButton1Click)
            Rayfield:Notify({Title = "Rebirth!", Content = "Triggered successfully!", Duration = 4})
         end
         -- If remote-based, add: game.ReplicatedStorage.RebirthEvent:FireServer()
      end)
   end
end)

-- Anti-AFK (always on)
spawn(function()
   while true do
      wait(math.random(60, 120))
      local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
      if hum then hum.Jump = true end
   end
end)

-- God mode attempt
local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
if hum then
   hum.MaxHealth = math.huge
   hum.Health = math.huge
end

Rayfield:Notify({
   Title = "GUI Loaded!",
   Content = "Toggle features above - Happy farming in OP Blade! ⚔️",
   Duration = 6
})
