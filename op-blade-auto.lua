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

-- Toggle for Auto Collect Loot
Tab:CreateToggle({
   Name = "Auto Collect Loot",
   CurrentValue = false,
   Callback = function(Value)
      autoCollectEnabled = Value
      Rayfield:Notify({
         Title = "Auto Collect",
         Content = Value and "ON - Looking for Looticon/Attachments!" or "OFF",
         Duration = 4
      })
   end
})

-- Auto Collect Loot (specific to OP Blade Dex names: LootAttachment, Looticon, LootGlow, LootBackground)
spawn(function()
   while true do
      task.wait(0.2)  -- faster loop
      if not autoCollectEnabled then continue end
      local root = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
      if not root then continue end
      
      -- Target loot folder first
      local lootFolder = workspace:FindFirstChild("loot")
      if lootFolder then
         for _, attachment in pairs(lootFolder:GetChildren()) do
            if attachment.Name:find("LootAttachment") then
               local icon = attachment.Parent:FindFirstChild("Looticon") or attachment.Parent:FindFirstChild("LootGlow") or attachment.Parent:FindFirstChild("LootBackground") or attachment.Parent:FindFirstChildWhichIsA("BasePart")
               if icon and (icon.Position - root.Position).Magnitude < 80 then
                  firetouchinterest(root, icon, 0)
                  task.wait(0.03)
                  firetouchinterest(root, icon, 1)
                  Rayfield:Notify({Title = "Loot Grabbed!", Content = "From LootAttachment", Duration = 1.5})
               end
            end
         end
      end
      
      -- Fallback: direct Looticon/Glow/Background in workspace
      for _, obj in pairs(workspace:GetChildren()) do
         local nameLower = obj.Name:lower()
         if nameLower:find("looticon") or nameLower:find("lootglow") or nameLower:find("lootbackground") then
            if (obj.Position - root.Position).Magnitude < 80 then
               firetouchinterest(root, obj, 0)
               task.wait(0.03)
               firetouchinterest(root, obj, 1)
               Rayfield:Notify({Title = "Direct Loot!", Content = "Collected " .. obj.Name, Duration = 2})
            end
         end
      end
   end
end)

-- Toggle for Noclip
Tab:CreateToggle({
   Name = "Noclip (Faster Walk)",
   CurrentValue = false,
   Callback = function(Value)
      noclipEnabled = Value
      Rayfield:Notify({
         Title = "Noclip",
         Content = Value and "ON - Smooth walk through walls!" or "OFF",
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
            part.AssemblyLinearVelocity = Vector3.new(0, part.AssemblyLinearVelocity.Y, 0)  -- keep vertical
            part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 0.5, 1, 1)  -- low friction
         end
      end
      local hum = char:FindFirstChild("Humanoid")
      if hum then hum.WalkSpeed = 32 end  -- speed boost
   end
end)

-- Toggle for Auto Rebirth
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
   Content = "Auto Collect fixed + Noclip faster! Test loot & rebirth ⚔️",
   Duration = 8
})
