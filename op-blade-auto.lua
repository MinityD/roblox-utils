-- OP Blade Auto Farm GUI V2 - Rayfield UI (Fixed Collect + Kill Aura)
-- Toggle features | Mobile Delta friendly

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "OP Blade Auto Farm V2 ⚔️",
   LoadingTitle = "Loading OP Features...",
   LoadingSubtitle = "by miniy",
   ConfigurationSaving = {Enabled = false}
})

local Tab = Window:CreateTab("Main", 4483362458)

local Section = Tab:CreateSection("Auto Controls")

local autoCollectEnabled = false
local noclipEnabled = false
local autoRebirthEnabled = false
local killAuraEnabled = false
local auraRange = 30  -- studs for kill aura

-- Auto Collect Loot (broader search + notify)
Tab:CreateToggle({
   Name = "Auto Collect Loot",
   CurrentValue = false,
   Callback = function(Value)
      autoCollectEnabled = Value
      Rayfield:Notify({
         Title = "Auto Collect",
         Content = Value and "Enabled - Pulling loot from afar!" or "Disabled",
         Duration = 4
      })
   end
})

spawn(function()
   while true do
      task.wait(0.3)
      if not autoCollectEnabled then continue end
      local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
      if not root then continue end
      for _, obj in pairs(workspace:GetChildren()) do
         if obj:IsA("BasePart") or obj:IsA("Model") then
            local nameLower = obj.Name:lower()
            if nameLower:find("coin") or nameLower:find("loot") or nameLower:find("drop") or nameLower:find("chest") or nameLower:find("gem") or nameLower:find("reward") or nameLower:find("gold") or nameLower:find("item") then
               if (obj:IsA("BasePart") and (obj.Position - root.Position).Magnitude < 50) or (obj:IsA("Model") and obj.PrimaryPart and (obj.PrimaryPart.Position - root.Position).Magnitude < 50) then
                  firetouchinterest(root, obj:IsA("BasePart") and obj or obj.PrimaryPart, 0)
                  task.wait(0.05)
                  firetouchinterest(root, obj:IsA("BasePart") and obj or obj.PrimaryPart, 1)
                  Rayfield:Notify({Title = "Collected!", Content = "Picked up " .. obj.Name, Duration = 2})
               end
            end
         end
      end
   end
end)

-- Noclip
Tab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Callback = function(Value)
      noclipEnabled = Value
      Rayfield:Notify({Title = "Noclip", Content = Value and "ON - Phase mode!" or "OFF", Duration = 3})
   end
})

game:GetService("RunService").Stepped:Connect(function()
   if not noclipEnabled then return end
   local char = game.Players.LocalPlayer.Character
   if char then
      for _, part in pairs(char:GetDescendants()) do
         if part:IsA("BasePart") then part.CanCollide = false end
      end
   end
end)

-- Auto Rebirth (more names + remote fallback)
Tab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Callback = function(Value)
      autoRebirthEnabled = Value
      Rayfield:Notify({Title = "Auto Rebirth", Content = Value and "ON - Rebirthing when ready!" or "OFF", Duration = 4})
   end
})

spawn(function()
   while true do
      task.wait(8)
      if not autoRebirthEnabled then continue end
      pcall(function()
         local pg = game.Players.LocalPlayer.PlayerGui
         local rebirthNames = {"Rebirth", "RebirthButton", "Prestige", "PrestigeButton", "RebirthNow", "ConfirmRebirth"}
         for _, name in rebirthNames do
            local btn = pg:FindFirstChild(name, true)
            if btn and btn:IsA("TextButton") or btn:IsA("ImageButton") then
               firesignal(btn.MouseButton1Click)
               Rayfield:Notify({Title = "Rebirth!", Content = "Triggered " .. name, Duration = 4})
               return
            end
         end
         -- Remote fallback (common in simulators)
         local rs = game:GetService("ReplicatedStorage")
         if rs:FindFirstChild("Rebirth") or rs:FindFirstChild("RebirthEvent") or rs:FindFirstChild("PrestigeEvent") then
            rs:FindFirstChild("Rebirth") or rs:FindFirstChild("RebirthEvent") or rs:FindFirstChild("PrestigeEvent"):FireServer()
            Rayfield:Notify({Title = "Rebirth Remote!", Content = "Fired remote!", Duration = 3})
         end
      end)
   end
end)

-- Kill Aura (new - toggle to damage enemies in range)
Tab:CreateToggle({
   Name = "Kill Aura",
   CurrentValue = false,
   Callback = function(Value)
      killAuraEnabled = Value
      Rayfield:Notify({Title = "Kill Aura", Content = Value and "ON - Enemies die close!" or "OFF", Duration = 4})
   end
})

spawn(function()
   while true do
      task.wait(0.2)
      if not killAuraEnabled then continue end
      local char = game.Players.LocalPlayer.Character
      if not char then continue end
      local root = char:FindFirstChild("HumanoidRootPart")
      if not root then continue end
      for _, enemy in pairs(workspace:GetChildren()) do
         if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy ~= char and (enemy.HumanoidRootPart.Position - root.Position).Magnitude <= 30 then
            enemy.Humanoid:TakeDamage(9999)  -- instant kill if local damage works
            -- Or fire remote if game uses one (add if needed)
         end
      end
   end
end)

-- Anti-AFK + God mode
spawn(function()
   while true do
      task.wait(math.random(60, 120))
      local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
      if hum then hum.Jump = true end
   end
end)

local hum = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
if hum then
   hum.MaxHealth = math.huge
   hum.Health = math.huge
end

Rayfield:Notify({
   Title = "GUI Loaded V2!",
   Content = "Toggles fixed + Kill Aura added! Farm OP blades ⚔️",
   Duration = 8
})         Content = Value and "Enabled - Phase through everything!" or "Disabled",
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
