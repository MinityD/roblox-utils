-- OP Blade Auto Farm GUI V3 - Fixed + Kill Aura
-- Rayfield UI - Toggle & watch for notifications

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "OP Blade Auto V3 ⚔️",
   LoadingTitle = "Loading OP Tools...",
   LoadingSubtitle = "by miniy",
   ConfigurationSaving = {Enabled = false}
})

local Tab = Window:CreateTab("Farm", 4483362458)

local Section = Tab:CreateSection("Toggles")

local autoCollectEnabled = false
local noclipEnabled = false
local autoRebirthEnabled = false
local killAuraEnabled = false
local auraRange = 25  -- adjust if too OP or laggy

-- Auto Collect Loot (expanded names + distance)
Tab:CreateToggle({
   Name = "Auto Collect Loot",
   CurrentValue = false,
   Callback = function(Value)
      autoCollectEnabled = Value
      Rayfield:Notify({Title = "Auto Collect", Content = Value and "ON - Pulling loot!" or "OFF", Duration = 3})
   end
})

spawn(function()
   while true do
      task.wait(0.4)
      if not autoCollectEnabled then continue end
      local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
      if not root then continue end
      for _, obj in pairs(workspace:GetChildren()) do
         local nameLower = obj.Name:lower()
         if (obj:IsA("BasePart") or obj:IsA("Model")) and (nameLower:find("gold") or nameLower:find("gem") or nameLower:find("loot") or nameLower:find("drop") or nameLower:find("chest") or nameLower:find("item") or nameLower:find("reward") or nameLower:find("bag") or nameLower:find("shard") or nameLower:find("blade")) then
            local target = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChild("Handle")
            if target and (target.Position - root.Position).Magnitude < 60 then
               firetouchinterest(root, target, 0)
               task.wait(0.05)
               firetouchinterest(root, target, 1)
               Rayfield:Notify({Title = "Loot!", Content = "Collected " .. obj.Name, Duration = 2})
            end
         end
      end
   end
end)

-- Noclip (stronger loop)
Tab:CreateToggle({
   Name = "Noclip",
   CurrentValue = false,
   Callback = function(Value)
      noclipEnabled = Value
      Rayfield:Notify({Title = "Noclip", Content = Value and "ON - Through walls!" or "OFF", Duration = 3})
   end
})

game:GetService("RunService").Stepped:Connect(function()
   if not noclipEnabled then return end
   local char = game.Players.LocalPlayer.Character
   if char then
      for _, part in pairs(char:GetDescendants()) do
         if part:IsA("BasePart") then
            part.CanCollide = false
            part.Velocity = Vector3.new(0,0,0)  -- extra to prevent pushback
         end
      end
   end
end)

-- Auto Rebirth (more names + remote try)
Tab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Callback = function(Value)
      autoRebirthEnabled = Value
      Rayfield:Notify({Title = "Auto Rebirth", Content = Value and "ON - When ready!" or "OFF", Duration = 4})
   end
})

spawn(function()
   while true do
      task.wait(8)
      if not autoRebirthEnabled then continue end
      pcall(function()
         local pg = game.Players.LocalPlayer.PlayerGui
         local rebirthNames = {"Rebirth", "RebirthButton", "Prestige", "PrestigeButton", "RebirthConfirm", "ConfirmRebirth", "RebirthNow"}
         for _, name in rebirthNames do
            local btn = pg:FindFirstChild(name, true)
            if btn and (btn:IsA("TextButton") or btn:IsA("ImageButton")) then
               firesignal(btn.MouseButton1Click)
               Rayfield:Notify({Title = "Rebirth!", Content = "Hit " .. name, Duration = 4})
               return
            end
         end
         -- Remote fallback (try common names)
         local rs = game:GetService("ReplicatedStorage")
         local rebirthRemotes = {"Rebirth", "RebirthEvent", "PrestigeEvent", "RebirthRemote"}
         for _, name in rebirthRemotes do
            local remote = rs:FindFirstChild(name)
            if remote then
               remote:FireServer()
               Rayfield:Notify({Title = "Rebirth Remote!", Content = "Fired " .. name, Duration = 3})
               return
            end
         end
      end)
   end
end)

-- Kill Aura (damages enemies in range)
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
      task.wait(0.15)  -- fast but not laggy
      if not killAuraEnabled then continue end
      local char = game.Players.LocalPlayer.Character
      if not char then continue end
      local root = char:FindFirstChild("HumanoidRootPart")
      if not root then continue end
      for _, enemy in pairs(workspace:GetChildren()) do
         if enemy:FindFirstChild("Humanoid") and enemy.Humanoid.Health > 0 and enemy ~= char and enemy:FindFirstChild("HumanoidRootPart") and (enemy.HumanoidRootPart.Position - root.Position).Magnitude <= auraRange then
            enemy.Humanoid.Health = 0  -- direct kill (works if client damage allowed)
            Rayfield:Notify({Title = "Kill!", Content = "Aura hit enemy", Duration = 1})
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
   Title = "V3 Loaded!",
   Content = "Toggles improved + Kill Aura added! Test auto collect & aura ⚔️",
   Duration = 8
})
