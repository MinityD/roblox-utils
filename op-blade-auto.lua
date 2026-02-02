-- OP Blade Auto Farm GUI V4 - Fixed Auto Collect + Faster Noclip
-- Rayfield UI - No kill aura

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "OP Blade Auto V4 ⚔️",
   LoadingTitle = "Loading Farm Tools...",
   LoadingSubtitle = "by miniy",
   ConfigurationSaving = {Enabled = false}
})

local Tab = Window:CreateTab("Main", 4483362458)

local Section = Tab:CreateSection("Auto Features")

local autoCollectEnabled = false
local noclipEnabled = false
local autoRebirthEnabled = false

-- Auto Collect Loot (very broad search + inside models)
Tab:CreateToggle({
   Name = "Auto Collect Loot",
   CurrentValue = false,
   Callback = function(Value)
      autoCollectEnabled = Value
      Rayfield:Notify({
         Title = "Auto Collect",
         Content = Value and "ON - Looking for all drops!" or "OFF",
         Duration = 4
      })
   end
})

spawn(function()
   while true do
      task.wait(0.25)  -- faster loop
      if not autoCollectEnabled then continue end
      local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
      if not root then continue end
      
      for _, obj in pairs(workspace:GetChildren()) do
         local found = false
         local targetPart = nil
         
         -- Check name directly
         local nameLower = obj.Name:lower()
         if nameLower:find("gold") or nameLower:find("gem") or nameLower:find("loot") or nameLower:find("drop") or nameLower:find("chest") or nameLower:find("item") or nameLower:find("reward") or nameLower:find("bag") or nameLower:find("shard") or nameLower:find("blade") or nameLower:find("pickup") or nameLower:find("orb") then
            found = true
            targetPart = obj:IsA("BasePart") and obj or obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")
         end
         
         -- If model, look inside
         if obj:IsA("Model") and not found then
            for _, child in pairs(obj:GetDescendants()) do
               local childName = child.Name:lower()
               if childName:find("gold") or childName:find("gem") or childName:find("loot") or childName:find("drop") or childName:find("chest") or childName:find("item") or childName:find("reward") then
                  found = true
                  targetPart = child
                  break
               end
            end
         end
         
         if found and targetPart and (targetPart.Position - root.Position).Magnitude < 80 then
            firetouchinterest(root, targetPart, 0)
            task.wait(0.03)
            firetouchinterest(root, targetPart, 1)
            Rayfield:Notify({
               Title = "Loot Grabbed!",
               Content = "Picked up " .. obj.Name,
               Duration = 2
            })
         end
      end
   end
end)

-- Noclip (faster & stronger - prevents pushback)
Tab:CreateToggle({
   Name = "Noclip (Faster Walk)",
   CurrentValue = false,
   Callback = function(Value)
      noclipEnabled = Value
      Rayfield:Notify({
         Title = "Noclip",
         Content = Value and "ON - Walk through walls faster!" or "OFF",
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
            part.AssemblyLinearVelocity = Vector3.new(0,0,0)  -- stop physics push
         end
      end
   end
end)

-- Auto Rebirth (same as before - expanded names)
Tab:CreateToggle({
   Name = "Auto Rebirth",
   CurrentValue = false,
   Callback = function(Value)
      autoRebirthEnabled = Value
      Rayfield:Notify({
         Title = "Auto Rebirth",
         Content = Value and "ON - Rebirthing when possible" or "OFF",
         Duration = 4
      })
   end
})

spawn(function()
   while true do
      task.wait(8)
      if not autoRebirthEnabled then continue end
      pcall(function()
         local pg = game.Players.LocalPlayer.PlayerGui
         local rebirthNames = {"Rebirth", "RebirthButton", "Prestige", "PrestigeButton", "RebirthConfirm", "ConfirmRebirth", "RebirthNow", "RebirthPanel"}
         for _, name in rebirthNames do
            local btn = pg:FindFirstChild(name, true)
            if btn and (btn:IsA("TextButton") or btn:IsA("ImageButton")) then
               firesignal(btn.MouseButton1Click)
               Rayfield:Notify({Title = "Rebirth!", Content = "Triggered " .. name, Duration = 4})
               return
            end
         end
         -- Remote attempt
         local rs = game:GetService("ReplicatedStorage")
         local rebirthRemotes = {"Rebirth", "RebirthEvent", "PrestigeEvent", "RebirthRemote", "RebirthFunction"}
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
   Title = "V4 Loaded!",
   Content = "Auto Collect improved + Noclip faster! Test loot collection ⚔️",
   Duration = 8
})
