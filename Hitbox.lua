local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer
local hitboxSize = 2048  -- MÃXIMO = INFINITO BIDIRECCIONAL
local teamCheck = false
local visible = true
local auraKill = false  -- NUEVO: Aura Kill Toggle
local lastHits = {}  -- Debounce por target

local CommF_ = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("CommF_")
local enemyFolders = {"Enemies", "Boss", "Bosses", "Raid", "Raids", "Mobs", "SeaBeast", "SeaBeasts", "Ships"}  -- 100% Blox Fruits

local function expandHitbox(model, isEnemy)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
        for _, part in ipairs(model:GetChildren()) do
            if part:IsA("BasePart") and (isEnemy or part.Name == "Handle") then
                part.Size = size
                part.CanCollide = false
                part.Transparency = visible and 0.75 or 1
            end
        end
        local root = model:FindFirstChild("HumanoidRootPart")
        if root and visible then
            if not root:FindFirstChild("HitboxVisualizer") then
                local vis = Instance.new("SelectionBox")
                vis.Name = "HitboxVisualizer"
                vis.Adornee = root
                vis.Color3 = Color3.new(isEnemy and 1 or 0, 0, isEnemy and 0 or 1)  -- Rojo enemigo, Azul tuyo
                vis.Transparency = 0.5
                vis.Parent = root
            end
        elseif root then
            local vis = root:FindFirstChild("HitboxVisualizer")
            if vis then vis:Destroy() end
        end
    end
end

local function auraDamage(model)
    if not auraKill then return end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and humanoid.Health > 0 then
        local root = model:FindFirstChild("HumanoidRootPart")
        if root then
            pcall(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("Main") and char.Main:FindFirstChild("Swing") then
                    local now = tick()
                    if now - (lastHits[model] or 0) > 0.1 then  -- 10 DPS anti-spam
                        char.Main.Swing:FireServer(root.CFrame)
                        lastHits[model] = now
                    end
                end
            end)
        end
    else
        lastHits[model] = nil  -- Limpia debounce si muerto
    end
end

local function updateAll()
    -- TU ARMA/M1 (BIDIRECCIONAL - ALCANCE INFINITO)
    if LocalPlayer.Character then
        local tool = LocalPlayer.Character:FindFirstChildOfClass("Tool")
        if tool then
            expandHitbox(tool, false)
        end
        expandHitbox(LocalPlayer.Character, false)
        auraDamage(LocalPlayer.Character)  -- No auto-daÃ±a a ti
    end
    
    -- JUGADORES (PVP AURA + HITBOX)
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and (not teamCheck or player.Team ~= LocalPlayer.Team) then
            expandHitbox(player.Character, true)
            auraDamage(player.Character)
        end
    end
    -- NPCs/Bosses (FARM AURA INFINITO)
    for _, folderName in ipairs(enemyFolders) do
        local folder = workspace:FindFirstChild(folderName)
        if folder then
            for _, model in ipairs(folder:GetChildren()) do
                if model:IsA("Model") then
                    expandHitbox(model, true)
                    auraDamage(model)
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(updateAll)  -- Loop ULTRA anti-revert

workspace.ChildAdded:Connect(function(child) task.wait(0.01) updateAll() end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function() task.wait(0.3) updateAll() end)
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.3) 
    updateAll()
end)

local function createGui()
    if LocalPlayer.PlayerGui:FindFirstChild("HitboxGui") then LocalPlayer.PlayerGui.HitboxGui:Destroy() end
    local sg = Instance.new("ScreenGui") sg.Name = "HitboxGui" sg.Parent = LocalPlayer.PlayerGui
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 220)  -- MÃ¡s alto para Aura
    frame.Position = UDim2.new(0, 10, 1, -230)
    frame.AnchorPoint = Vector2.new(0, 1)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.BackgroundTransparency = 0.05
    frame.Parent = sg
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundTransparency = 1
    title.Text = "ðŸ”¥ HITBOX + AURAKILL ULTRA v6 (Blox Fruits)"
    title.TextColor3 = Color3.new(1,1,0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local sizeBox = Instance.new("TextBox")
    sizeBox.Size = UDim2.new(1, -10, 0, 25)
    sizeBox.Position = UDim2.new(0, 5, 0, 35)
    sizeBox.BackgroundColor3 = Color3.new(0.15, 0.15, 0.15)
    sizeBox.TextColor3 = Color3.new(1,1,1)
    sizeBox.Text = "2048"
    sizeBox.PlaceholderText = "Size (2048 = INFINITO)"
    sizeBox.TextScaled = true
    sizeBox.Parent = frame
    
    local maxBtn = Instance.new("TextButton")
    maxBtn.Size = UDim2.new(1, -10, 0, 28)
    maxBtn.Position = UDim2.new(0, 5, 0, 65)
    maxBtn.BackgroundColor3 = Color3.new(1, 0.2, 0.2)
    maxBtn.TextColor3 = Color3.new(1,1,1)
    maxBtn.Text = "ðŸš€ MAX ULTRA 2048 (BIDIRECCIONAL)"
    maxBtn.TextScaled = true
    maxBtn.Font = Enum.Font.GothamBold
    maxBtn.Parent = frame
    
    local teamBtn = Instance.new("TextButton")
    teamBtn.Size = UDim2.new(0.48, -7, 0, 25)
    teamBtn.Position = UDim2.new(0, 5, 0, 100)
    teamBtn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    teamBtn.TextColor3 = Color3.new(1,1,1)
    teamBtn.Text = "Team Check: OFF"
    teamBtn.TextScaled = true
    teamBtn.Parent = frame
    
    local visBtn = Instance.new("TextButton")
    visBtn.Size = UDim2.new(0.48, -3, 0, 25)
    visBtn.Position = UDim2.new(0.5, 2, 0, 100)
    visBtn.BackgroundColor3 = Color3.new(0.3, 0.3, 0.3)
    visBtn.TextColor3 = Color3.new(1,1,1)
    visBtn.Text = "Visible: ON"
    visBtn.TextScaled = true
    visBtn.Parent = frame
    
    -- NUEVO: Aura Kill Button
    local auraBtn = Instance.new("TextButton")
    auraBtn.Size = UDim2.new(1, -10, 0, 28)
    auraBtn.Position = UDim2.new(0, 5, 0, 130)
    auraBtn.BackgroundColor3 = Color3.new(0.8, 0, 0.2)
    auraBtn.TextColor3 = Color3.new(1,1,1)
    auraBtn.Text = "ðŸ’€ Aura Kill: OFF (EQUIPA ESPADA!)"
    auraBtn.TextScaled = true
    auraBtn.Font = Enum.Font.GothamBold
    auraBtn.Parent = frame
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -10, 0, 22)
    status.Position = UDim2.new(0, 5, 0, 163)
    status.BackgroundTransparency = 1
    status.Text = "Â¡BIDIRECCIONAL + AURAKILL ACTIVADO! TamaÃ±o: " .. hitboxSize
    status.TextColor3 = Color3.new(0,1,0)
    status.TextScaled = true
    status.Font = Enum.Font.GothamBold
    status.Parent = frame
    
    -- INFO Label
    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -10, 0, 20)
    info.Position = UDim2.new(0, 5, 0, 190)
    info.BackgroundTransparency = 1
    info.Text = "ðŸ’¡ Equipa espada (Pole/Katana) para Aura!"
    info.TextColor3 = Color3.new(1,1,0)
    info.TextScaled = true
    info.Font = Enum.Font.Gotham
    info.Parent = frame
    
    sizeBox.FocusLost:Connect(function(enter)
        if enter then
            local num = math.min(tonumber(sizeBox.Text) or 2048, 2048)
            hitboxSize = num
            status.Text = "Â¡SUPERA LÃMITE! TamaÃ±o: " .. hitboxSize .. " + Aura"
            updateAll()
            sizeBox.Text = ""
        end
    end)
    
    maxBtn.MouseButton1Click:Connect(function()
        hitboxSize = 2048
        sizeBox.Text = "2048"
        status.Text = "Â¡LA MÃS GRANDE + AURAKILL! Infinito"
        updateAll()
    end)
    
    teamBtn.MouseButton1Click:Connect(function()
        teamCheck = not teamCheck
        teamBtn.Text = "Team Check: " .. (teamCheck and "ON" or "OFF")
        updateAll()
    end)
    
    visBtn.MouseButton1Click:Connect(function()
        visible = not visible
        visBtn.Text = "Visible: " .. (visible and "ON" or "OFF")
        updateAll()
    end)
    
    -- NUEVO: Aura Toggle
    auraBtn.MouseButton1Click:Connect(function()
        auraKill = not auraKill
        auraBtn.Text = "ðŸ’€ Aura Kill: " .. (auraKill and "ON" or "OFF") .. " (ESPADA!)"
        auraBtn.BackgroundColor3 = auraKill and Color3.new(0, 0.8, 0.2) or Color3.new(0.8, 0, 0.2)
        status.Text = "Â¡AURAKILL " .. (auraKill and "ON - MATANDO TODO!" or "OFF") .. " | TamaÃ±o: " .. hitboxSize
    end)
end

createGui()
LocalPlayer.CharacterAdded:Connect(function() task.wait(0.5) createGui() updateAll() end)
updateAll()
