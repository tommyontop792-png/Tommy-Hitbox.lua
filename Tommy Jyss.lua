local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
   Name = "👑 Tommy Jyss🌩️", LoadingTitle = "👑 Tommy Jyss🌩️",
   LoadingSubtitle = "Cargando...",
   ConfigurationSaving = {Enabled=true, FolderName="TommyJyssConfig", FileName="Config"},
   Discord = {Enabled=false}, KeySystem = false,
})

local Players,RunService,UserInputService,TweenService = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService")
local LocalPlayer,Camera = Players.LocalPlayer,workspace.CurrentCamera

-- Variables
local FruitAttack,FastAttackEnabled,ESPEnabled,NoClipEnabled,InfiniteJumpEnabled,WalkOnWaterEnabled = false,false,false,false,false,false
local SpeedValue,ZoomFOV,DefaultFOV = 16,20,70
local ZoomEnabled,GUIVisible = false,true
local fruitConns,ESPObjects = {},{}
local FastAttackConnection = nil
local SelectedPlayer,InstaTpConnection,SpectateConnection,TeleportConnection,ActiveTween = nil,nil,nil,nil,nil
local PredictionStrength,YOffset,autoV4 = 0,0,false

local fruitNames = {["Pain-Pain"]=true,["Dragon-Dragon"]=true,["Tiger-Tiger"]=true,["T-Rex-T-Rex"]=true,["Kitsune-Kitsune"]=true}

-- Funciones
local function GetPlayerList() local l={"None"} for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer then table.insert(l,p.Name) end end return l end
local function SetNoCollide(s) local c=LocalPlayer.Character; if not c then return end for _,v in pairs(c:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=not s end end end

local function RemoveAttackAnim()
    local c=LocalPlayer.Character; if not c then return end
    local a=c:FindFirstChildOfClass("Humanoid") and c:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
    if a then for _,t in pairs(a:GetPlayingAnimationTracks()) do t:Stop(0) end end
end

local function GetNearestPlayer()
    local nearest,minDist=nil,math.huge
    local hrp=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    for _,p in pairs(Players:GetPlayers()) do
        if p~=LocalPlayer and p.Character then
            local o=p.Character:FindFirstChild("HumanoidRootPart")
            if o then local d=(hrp.Position-o.Position).Magnitude; if d<minDist then minDist=d;nearest=p end end
        end
    end
    return nearest
end

local function StartFastAttack()
    if FastAttackConnection then task.cancel(FastAttackConnection) end
    FastAttackConnection = task.spawn(function()
        while FastAttackEnabled do
            task.wait(0.05)
            local char=LocalPlayer.Character; if not char then continue end
            local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then continue end
            local target=GetNearestPlayer()
            if target and target.Character then
                local oHRP=target.Character:FindFirstChild("HumanoidRootPart")
                if oHRP then
                    local dir=(oHRP.Position-hrp.Position).Unit
                    for _,tool in pairs(char:GetChildren()) do
                        if tool:IsA("Tool") and not fruitNames[tool.Name] then
                            for _,n in pairs({"LeftClickRemote","AttackRemote","HitRemote","Remote","SwordRemote","SlashRemote","DamageRemote"}) do
                                local r=tool:FindFirstChild(n); if r then pcall(function() r:FireServer(vector.create(dir.X,dir.Y,dir.Z),1) end) end
                            end
                            RemoveAttackAnim()
                        end
                    end
                    for _,n in pairs({"CombatRemote","PunchRemote","HitRemote","MeleeRemote"}) do
                        local r=char:FindFirstChild(n)
                        if r and r:IsA("RemoteEvent") then pcall(function() r:FireServer(vector.create(dir.X,dir.Y,dir.Z),1) end) end
                    end
                    RemoveAttackAnim()
                end
            end
        end
    end)
end

local function FruitLoop(toolName,getDir,extraArgs)
    return task.spawn(function()
        while FruitAttack do
            task.wait(0.05)
            local char=LocalPlayer.Character; if not char then continue end
            local hrp=char:FindFirstChild("HumanoidRootPart")
            local tool=char:FindFirstChild(toolName)
            local target=GetNearestPlayer()
            if target and target.Character and hrp and tool then
                local oHRP=target.Character:FindFirstChild("HumanoidRootPart")
                if oHRP then
                    local dir=(oHRP.Position-hrp.Position).Unit
                    pcall(function() tool:WaitForChild("LeftClickRemote"):FireServer(getDir(dir),table.unpack(extraArgs or {})) end)
                    RemoveAttackAnim()
                end
            end
        end
    end)
end

local function StartTeleporting()
    if TeleportConnection then TeleportConnection:Disconnect() end
    TeleportConnection = RunService.Heartbeat:Connect(function()
        if not SelectedPlayer then return end
        local target=Players:FindFirstChild(SelectedPlayer)
        if target and target.Character then
            local tHRP=target.Character:FindFirstChild("HumanoidRootPart")
            local myHRP=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if tHRP and myHRP then
                local pred=tHRP.CFrame+tHRP.Velocity*PredictionStrength
                if ActiveTween then ActiveTween:Cancel() end
                ActiveTween=TweenService:Create(myHRP,TweenInfo.new(0.1),{CFrame=pred*CFrame.new(0,YOffset,0)}); ActiveTween:Play()
                SetNoCollide(true)
            end
        end
    end)
end

-- Input
UserInputService.InputBegan:Connect(function(i)
    if i.KeyCode==Enum.KeyCode.RightShift then GUIVisible=not GUIVisible; Window:Toggle() end
    if ZoomEnabled and i.KeyCode==Enum.KeyCode.Z then Camera.FieldOfView=ZoomFOV; LocalPlayer.CameraMaxZoomDistance=500; LocalPlayer.CameraMinZoomDistance=0 end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.KeyCode==Enum.KeyCode.Z then Camera.FieldOfView=DefaultFOV; LocalPlayer.CameraMaxZoomDistance=400; LocalPlayer.CameraMinZoomDistance=0.5 end
end)

-- ===== COMBATE =====
local CT = Window:CreateTab("⚔️ Combate", 4483362458)
CT:CreateSection("⚡ Fast Attack")
CT:CreateToggle({Name="⚡ Fast Attack | ON / OFF", CurrentValue=false, Callback=function(v)
    FastAttackEnabled=v
    if v then StartFastAttack() else if FastAttackConnection then task.cancel(FastAttackConnection); FastAttackConnection=nil end end
end})

CT:CreateSection("🍎 Frutas")
local fruits = {
    {name="💢 Pain | Fast Attack",    tool="Pain-Pain",       dir=function(d) return vector.create(d.X,0,d.Z) end,   args={1,true}},
    {name="🐉 Dragon | Fast Attack",  tool="Dragon-Dragon",   dir=function(d) return vector.create(d.X,d.Y,d.Z) end, args={1}},
    {name="🐅 Tiger | Fast Attack",   tool="Tiger-Tiger",     dir=function(d) return vector.create(d.X,d.Y,d.Z) end, args={3}},
    {name="🦖 T-Rex | Fast Attack",   tool="T-Rex-T-Rex",     dir=function(d) return vector.create(d.X,d.Y,d.Z) end, args={1}},
    {name="🦊 Kitsune | Fast Attack", tool="Kitsune-Kitsune", dir=function(d) return d end,                          args={1,true}},
}
for _,f in pairs(fruits) do
    CT:CreateToggle({Name=f.name, CurrentValue=false, Callback=function(v)
        FruitAttack=v
        if v then if fruitConns[f.tool] then task.cancel(fruitConns[f.tool]) end; fruitConns[f.tool]=FruitLoop(f.tool,f.dir,f.args)
        else if fruitConns[f.tool] then task.cancel(fruitConns[f.tool]); fruitConns[f.tool]=nil end end
    end})
end

CT:CreateSection("⚙️ Extra")
CT:CreateSlider({Name="📏 Hitbox | Rango", Range={100,5000}, Increment=100, Suffix=" studs", CurrentValue=2048, Flag="HitboxRange", Callback=function() end})
CT:CreateToggle({Name="👁️ ESP | Ver Jugadores", CurrentValue=false, Callback=function(v)
    ESPEnabled=v
    if not v then for _,o in pairs(workspace:GetDescendants()) do if o.Name=="TommyJyssESP" then o:Destroy() end end end
end})

-- ===== MOVIMIENTO =====
local MT = Window:CreateTab("🏃 Movimiento", 4483362458)
MT:CreateSection("🚀 Velocidad")
MT:CreateSlider({Name="🚀 Speed | Velocidad", Range={16,500}, Increment=10, Suffix=" studs/s", CurrentValue=16, Callback=function(v)
    SpeedValue=v; local c=LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") then c.Humanoid.WalkSpeed=v end
end})
MT:CreateSection("🧩 Extras")
MT:CreateToggle({Name="⬆️ Jump | Salto Infinito", CurrentValue=false, Callback=function(v) InfiniteJumpEnabled=v end})
MT:CreateToggle({Name="👻 NoClip | Sin Colisión", CurrentValue=false, Callback=function(v) NoClipEnabled=v end})
MT:CreateToggle({Name="💧 Water | Caminar en Agua", CurrentValue=false, Callback=function(v)
    WalkOnWaterEnabled=v; if not v and workspace:FindFirstChild("TommyJyssWaterSolid") then workspace.TommyJyssWaterSolid:Destroy() end
end})
MT:CreateButton({Name="✈️ Fly | Abrir Fly Gui", Callback=function() loadstring(game:HttpGet("https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt"))() end})

-- ===== PLAYERS =====
local PT = Window:CreateTab("👥 Players", 4483362458)
PT:CreateSection("👤 Selección")
local PlayerDropdown = PT:CreateDropdown({Name="👤 Player | Seleccionar", Options=GetPlayerList(), CurrentOption={"None"}, Callback=function(opt)
    if type(opt)=="table" then opt=opt[1] end; SelectedPlayer=(opt~="None") and opt or nil
end})
PT:CreateButton({Name="🔄 Refrescar | Lista", Callback=function() PlayerDropdown:Refresh(GetPlayerList(),true) end})

PT:CreateSection("🌐 Teleport")
PT:CreateToggle({Name="🌐 InstaTp | Teleporte Instantáneo", CurrentValue=false, Callback=function(v)
    InstaTeleportEnabled=v
    if v then
        InstaTpConnection=RunService.Stepped:Connect(function()
            if SelectedPlayer then pcall(function()
                local t=Players:FindFirstChild(SelectedPlayer)
                if t and t.Character then
                    local tor=t.Character:FindFirstChild("Torso") or t.Character:FindFirstChild("UpperTorso")
                    local myHRP=LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if tor and myHRP then myHRP.CFrame=tor.CFrame*CFrame.new(0,YOffset,0.2); myHRP.Velocity=Vector3.new(0,0,0) end
                end
            end) end
        end)
    else if InstaTpConnection then InstaTpConnection:Disconnect() end end
end})
PT:CreateToggle({Name="👥 TweenTp | Tween To Player", CurrentValue=false, Callback=function(v)
    TeleportEnabled=v
    if v then if SelectedPlayer then StartTeleporting() end
    else if TeleportConnection then TeleportConnection:Disconnect() end; if ActiveTween then ActiveTween:Cancel();ActiveTween=nil end; SetNoCollide(false) end
end})
PT:CreateButton({Name="🌏 TP All | Teleporte a Todos", Callback=function()
    task.spawn(function()
        for _,p in pairs(Players:GetPlayers()) do
            if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local s=tick(); while tick()-s<5 do
                    if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                        pcall(function() LocalPlayer.Character.HumanoidRootPart.CFrame=p.Character.HumanoidRootPart.CFrame*CFrame.new(0,YOffset,0) end)
                    else break end; task.wait()
                end
            end
        end
        Rayfield:Notify({Title="TP All",Content="Finalizado.",Duration=5})
    end)
end})

PT:CreateSection("⚙️ Opciones")
PT:CreateSlider({Name="📟 Prediction | Fuerza", Range={0,10}, Increment=0.1, CurrentValue=0, Callback=function(v) PredictionStrength=v end})
PT:CreateSlider({Name="🌊 Y Offset | Altura", Range={0,10000}, Increment=1, CurrentValue=0, Callback=function(v) YOffset=v end})
PT:CreateToggle({Name="👁️ Spectate | Ver Jugador", CurrentValue=false, Callback=function(v)
    SpectateEnabled=v
    if v then SpectateConnection=RunService.RenderStepped:Connect(function()
        if SelectedPlayer then local t=Players:FindFirstChild(SelectedPlayer)
            if t and t.Character then workspace.CurrentCamera.CameraSubject=t.Character.Humanoid end end
    end)
    else if SpectateConnection then SpectateConnection:Disconnect() end; workspace.CurrentCamera.CameraSubject=LocalPlayer.Character.Humanoid end
end})
PT:CreateToggle({Name="🧭 Auto V4 | Awakening", CurrentValue=false, Callback=function(v)
    autoV4=v; task.spawn(function() while autoV4 do task.wait(0.5); pcall(function() LocalPlayer.Backpack.Awakening.RemoteFunction:InvokeServer(true) end) end end)
end})

-- ===== ZOOM =====
local ZT = Window:CreateTab("🔭 Zoom", 4483362458)
ZT:CreateSection("🔭 Zoom Extendido")
ZT:CreateToggle({Name="🔭 Zoom | Activar (Mantén Z)", CurrentValue=false, Callback=function(v)
    ZoomEnabled=v
    if v then LocalPlayer.CameraMaxZoomDistance=500; LocalPlayer.CameraMinZoomDistance=0
    else Camera.FieldOfView=DefaultFOV; LocalPlayer.CameraMaxZoomDistance=400; LocalPlayer.CameraMinZoomDistance=0.5 end
end})
ZT:CreateSlider({Name="🔍 Zoom | FOV Zoom", Range={5,60}, Increment=5, Suffix=" FOV", CurrentValue=20, Callback=function(v) ZoomFOV=v end})
ZT:CreateSlider({Name="📷 Zoom | FOV Normal", Range={50,120}, Increment=5, Suffix=" FOV", CurrentValue=70, Callback=function(v) DefaultFOV=v; if not ZoomEnabled then Camera.FieldOfView=v end end})
ZT:CreateSlider({Name="📡 Zoom | Distancia Max", Range={50,1000}, Increment=50, Suffix=" studs", CurrentValue=500, Callback=function(v) if ZoomEnabled then LocalPlayer.CameraMaxZoomDistance=v end end})

-- ===== SEA 2 =====
local S2 = Window:CreateTab("🌊 Sea 2", 4483362458)
S2:CreateSection("🗺️ Teleports")
S2:CreateButton({Name="🗺️ TP | Barco Maldito", Callback=function() if LocalPlayer.Character then LocalPlayer.Character:PivotTo(CFrame.new(923,126,32852)) end end})

-- ===== SEA 3 =====
local S3 = Window:CreateTab("🏰 Sea 3", 4483362458)
S3:CreateSection("🏰 Teleports")
S3:CreateButton({Name="🏰 TP | Castillo", Callback=function() if LocalPlayer.Character then LocalPlayer.Character:PivotTo(CFrame.new(-5085,316,-3156)) end end})
S3:CreateButton({Name="🏛️ TP | Mansión", Callback=function() if LocalPlayer.Character then LocalPlayer.Character:PivotTo(CFrame.new(-12463,375,-7523)) end end})

-- ===== ESP =====
local function CreateESP(target)
    if not target:FindFirstChild("Head") or target.Head:FindFirstChild("TommyJyssESP") then return end
    local bb=Instance.new("BillboardGui"); bb.Name="TommyJyssESP"; bb.Adornee=target.Head
    bb.Size=UDim2.new(0,100,0,50); bb.StudsOffset=Vector3.new(0,2,0); bb.AlwaysOnTop=true; bb.Parent=target.Head
    local lbl=Instance.new("TextLabel",bb); lbl.BackgroundTransparency=1; lbl.Size=UDim2.new(1,0,1,0)
    lbl.Text=target.Name; lbl.Font=Enum.Font.GothamBold; lbl.TextSize=14; lbl.TextColor3=Color3.new(0,1,1); lbl.TextStrokeTransparency=0
    table.insert(ESPObjects,bb)
end
local function ClearESP() for _,o in pairs(ESPObjects) do if o and o.Parent then o:Destroy() end end ESPObjects={} end
local function UpdateESP() ClearESP(); if not ESPEnabled then return end; for _,p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then CreateESP(p.Character) end end end

task.spawn(function() while true do task.wait(3); UpdateESP() end end)
Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(function() task.wait(1); if ESPEnabled then UpdateESP() end end) end)
Players.PlayerRemoving:Connect(function() task.wait(0.5); UpdateESP() end)

-- ===== RUNTIME =====
UserInputService.JumpRequest:Connect(function()
    if InfiniteJumpEnabled then local c=LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") then c.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end end
end)
RunService.Stepped:Connect(function()
    if NoClipEnabled and LocalPlayer.Character then for _,v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide=false end end end
end)
RunService.Heartbeat:Connect(function()
    local c=LocalPlayer.Character; if c and c:FindFirstChild("Humanoid") and SpeedValue~=c.Humanoid.WalkSpeed then c.Humanoid.WalkSpeed=SpeedValue end
end)
RunService.RenderStepped:Connect(function()
    local c=LocalPlayer.Character; local hrp=c and c:FindFirstChild("HumanoidRootPart")
    if WalkOnWaterEnabled and hrp then
        if hrp.Position.Y>=9.5 and hrp.AssemblyLinearVelocity.Y<=0 then
            local wp=workspace:FindFirstChild("TommyJyssWaterSolid")
            if not wp then wp=Instance.new("Part",workspace); wp.Name="TommyJyssWaterSolid"; wp.Size=Vector3.new(20,1,20); wp.Transparency=1; wp.Anchored=true; wp.CanCollide=true; wp.CanQuery=false end
            wp.CFrame=CFrame.new(hrp.Position.X,9.2,hrp.Position.Z)
        else if workspace:FindFirstChild("TommyJyssWaterSolid") then workspace.TommyJyssWaterSolid:Destroy() end end
    else if workspace:FindFirstChild("TommyJyssWaterSolid") then workspace.TommyJyssWaterSolid:Destroy() end end
end)
RunService.RenderStepped:Connect(function() if FruitAttack or FastAttackEnabled then RemoveAttackAnim() end end)

Rayfield:LoadConfiguration()
