-- =============================================================================
-- NUU7 HUB - PARTE 1: NÚCLEO DE CONFIGURACIÓN Y ESTADO GLOBAL
-- =============================================================================

-- Inicialización segura del contenedor global
_G.Nuu7_State = _G.Nuu7_State or {}

-- Configuración Centralizada
_G.Nuu7_State.Config = {
    Key = "0nuu7",
    Active = false,
    ESP = { Lines = false, Names = false, Distance = false, TeamCheck = true },
    Hitbox = { Enabled = false, Size = 2 },
    Movement = { WalkSpeed = 16 },
    SilentAim = { Enabled = false, Part = "Head" },
    Aimbot = { Enabled = false, FOV = 100, Smoothness = 0.2 },
    AutoShoot = false
}

-- Definición e Inyección de Servicios Críticos
_G.Nuu7_State.Services = {
    Players = game:GetService("Players"),
    RunService = game:GetService("RunService"),
    UserInputService = game:GetService("UserInputService"),
    TweenService = game:GetService("TweenService"),
    CoreGui = game:GetService("CoreGui"),
    Workspace = game:GetService("Workspace")
}

_G.Nuu7_State.LocalPlayer = _G.Nuu7_State.Services.Players.LocalPlayer
_G.Nuu7_State.Camera = _G.Nuu7_State.Services.Workspace.CurrentCamera

print("[Nuu7 Hub]: Parte 1 (Configuración) inicializada correctamente.")
-- =============================================================================
-- NUU7 HUB - PARTE 2: MOTORES MATEMÁTICOS Y COMPROBACIONES
-- =============================================================================

if not _G.Nuu7_State then return end

local Services = _G.Nuu7_State.Services
local LocalPlayer = _G.Nuu7_State.LocalPlayer
local Camera = _G.Nuu7_State.Camera
local Config = _G.Nuu7_State.Config

-- Algoritmo de arrastre fluido nativo (Interpolado)
function _G.Nuu7_State.MakeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    gui.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    Services.UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Services.TweenService:Create(gui, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

-- Lógica avanzada Sheriff vs Murderer para detección exacta
function _G.Nuu7_State.IsEnemy(player)
    if not Config.ESP.TeamCheck then return true end
    if player == LocalPlayer then return false end
    
    local function checkInventory(p)
        if not p or not p:FindFirstChild("Backpack") then return "Innocent" end
        if p.Backpack:FindFirstChild("Knife") or (p.Character and p.Character:FindFirstChild("Knife")) then return "Murder" end
        if p.Backpack:FindFirstChild("Gun") or (p.Character and p.Character:FindFirstChild("Gun")) then return "Sheriff" end
        return "Innocent"
    end
    
    local localRole = checkInventory(LocalPlayer)
    local playerRole = checkInventory(player)
    
    if localRole == "Murder" and playerRole ~= "Murder" then return true end
    if localRole ~= "Murder" and playerRole == "Murder" then return true end
    if player.Team and LocalPlayer.Team then return player.Team ~= LocalPlayer.Team end
    
    return true
end

-- Cálculo trigonométrico y angular de proximidad en pantalla (FOV Target)
function _G.Nuu7_State.GetClosestPlayerInFOV()
    local target = nil
    local maxDist = Config.Aimbot.FOV
    local mousePos = Services.UserInputService:GetMouseLocation()

    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and _G.Nuu7_State.IsEnemy(p) and p.Character and p.Character:FindFirstChild("Head") then
            local screenPos, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
            if onScreen then
                local magnitude = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                if magnitude < maxDist then
                    maxDist = magnitude
                    target = p
                end
            end
        end
    end
    return target
end

print("[Nuu7 Hub]: Parte 2 (Cálculos y Filtros) vinculada.")
-- =============================================================================
-- NUU7 HUB - PARTE 3: INTERFAZ GRÁFICA INTERACTIVA (APPLE DESIGN)
-- =============================================================================

if not _G.Nuu7_State then return end

local Services = _G.Nuu7_State.Services
local Config = _G.Nuu7_State.Config

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Nuu7_Hub_Core"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() ScreenGui.Parent = Services.CoreGui end)
if not ScreenGui.Parent then ScreenGui.Parent = _G.Nuu7_State.LocalPlayer:WaitForChild("PlayerGui") end

_G.Nuu7_State.FOVCircle = Drawing.new("Circle")
_G.Nuu7_State.FOVCircle.Color = Color3.fromRGB(255, 59, 48)
_G.Nuu7_State.FOVCircle.Thickness = 1.5
_G.Nuu7_State.FOVCircle.Filled = false
_G.Nuu7_State.FOVCircle.Transparency = 0.6
_G.Nuu7_State.FOVCircle.Visible = false

local MainFrame = Instance.new("Frame")
local KeyFrame = Instance.new("Frame")
local MiniIcon = Instance.new("TextButton")

function _G.Nuu7_State.InitMainUI()
    MainFrame.Size = UDim2.new(0, 520, 0, 360)
    MainFrame.Position = UDim2.new(0.5, -260, 0.5, -180)
    MainFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    MainFrame.BackgroundTransparency = 0.15
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)
    local mainStroke = Instance.new("UIStroke", MainFrame)
    mainStroke.Color = Color3.fromRGB(48, 48, 50)
    mainStroke.Thickness = 1.2

    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = MainFrame

    local HubTitle = Instance.new("TextLabel")
    HubTitle.Text = "Nuu7 Hub"
    HubTitle.Position = UDim2.new(0, 20, 0, 0)
    HubTitle.Size = UDim2.new(0, 200, 1, 0)
    HubTitle.Font = Enum.Font.SFMono
    HubTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
    HubTitle.TextSize = 16
    HubTitle.TextXAlignment = Enum.TextXAlignment.Left
    HubTitle.BackgroundTransparency = 1
    HubTitle.Parent = TopBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Text = "✕"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 59, 48)
    CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    CloseBtn.Font = Enum.Font.SourceSansBold
    CloseBtn.TextSize = 14
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = TopBar
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Text = "■"
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -75, 0.5, -15)
    MinBtn.BackgroundColor3 = Color3.fromRGB(255, 149, 0)
    MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinBtn.Font = Enum.Font.SourceSansBold
    MinBtn.TextSize = 14
    MinBtn.BorderSizePixel = 0
    MinBtn.Parent = TopBar
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(1, 0)

    local Container = Instance.new("Frame")
    Container.Size = UDim2.new(1, -40, 1, -70)
    Container.Position = UDim2.new(0, 20, 0, 55)
    Container.BackgroundTransparency = 1
    Container.Parent = MainFrame

    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    UIListLayout.Padding = UDim.new(0, 8)
    UIListLayout.Parent = Container

    MiniIcon.Size = UDim2.new(0, 50, 0, 50)
    MiniIcon.Position = UDim2.new(0.05, 0, 0.05, 0)
    MiniIcon.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    MiniIcon.TextColor3 = Color3.fromRGB(10, 132, 255)
    MiniIcon.Text = "◉"
    MiniIcon.TextSize = 24
    MiniIcon.Visible = false
    MiniIcon.Parent = ScreenGui
    Instance.new("UICorner", MiniIcon).CornerRadius = UDim.new(1, 0)

    _G.Nuu7_State.MakeDraggable(MainFrame)
    _G.Nuu7_State.MakeDraggable(MiniIcon)

    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        _G.Nuu7_State.FOVCircle:Remove()
        Config.Active = false
    end)

    MinBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; MiniIcon.Visible = true end)
    MiniIcon.MouseButton1Click:Connect(function() MiniIcon.Visible = false; MainFrame.Visible = true end)

    local Signature = Instance.new("TextLabel")
    Signature.Text = "By LiamX"
    Signature.Size = UDim2.new(0, 100, 0, 20)
    Signature.Position = UDim2.new(1, -110, 1, -20)
    Signature.BackgroundTransparency = 1
    Signature.Font = Enum.Font.SourceSansBold
    Signature.TextSize = 12
    Signature.Parent = MainFrame

    Services.RunService.RenderStepped:Connect(function()
        Signature.TextColor3 = Color3.fromHSV((tick() % 4) / 4, 0.7, 1)
    end)

    local function CreateToggle(name, default, callback)
        local ToggleFrame = Instance.new("Frame")
        ToggleFrame.Size = UDim2.new(1, 0, 0, 30)
        ToggleFrame.BackgroundTransparency = 1
        ToggleFrame.Parent = Container

        local Label = Instance.new("TextLabel")
        Label.Text = name
        Label.Size = UDim2.new(0.7, 0, 1, 0)
        Label.TextColor3 = Color3.fromRGB(225, 225, 230)
        Label.Font = Enum.Font.SourceSans
        Label.TextSize = 14
        Label.TextXAlignment = Enum.TextXAlignment.Left
        Label.BackgroundTransparency = 1
        Label.Parent = ToggleFrame

        local Switch = Instance.new("TextButton")
        Switch.Size = UDim2.new(0, 42, 0, 20)
        Switch.Position = UDim2.new(1, -45, 0.5, -10)
        Switch.BackgroundColor3 = default and Color3.fromRGB(48, 209, 88) or Color3.fromRGB(44, 44, 46)
        Switch.Text = ""
        Switch.Parent = ToggleFrame
        Instance.new("UICorner", Switch).CornerRadius = UDim.new(1, 0)

        local state = default
        Switch.MouseButton1Click:Connect(function()
            state = not state
            Services.TweenService:Create(Switch, TweenInfo.new(0.2), {
                BackgroundColor3 = state and Color3.fromRGB(48, 209, 88) or Color3.fromRGB(44, 44, 46)
            }):Play()
            callback(state)
        end)
    end

    CreateToggle("ESP Line", false, function(v) Config.ESP.Lines = v end)
    CreateToggle("ESP Name", false, function(v) Config.ESP.Names = v end)
    CreateToggle("ESP Distance", false, function(v) Config.ESP.Distance = v end)
    CreateToggle("Silent Aim", false, function(v) Config.SilentAim.Enabled = v end)
    CreateToggle("Aggressive Aimbot", false, function(v) Config.Aimbot.Enabled = v _G.Nuu7_State.FOVCircle.Visible = v end)
    CreateToggle("Auto Shoot", false, function(v) Config.AutoShoot = v end)
end

function _G.Nuu7_State.CreateKeySystem()
    KeyFrame.Size = UDim2.new(0, 300, 0, 160)
    KeyFrame.Position = UDim2.new(0.5, -150, 0.4, -80)
    KeyFrame.BackgroundColor3 = Color3.fromRGB(28, 28, 30)
    KeyFrame.BorderSizePixel = 0
    KeyFrame.Parent = ScreenGui

    Instance.new("UICorner", KeyFrame).CornerRadius = UDim.new(0, 12)
    local stroke = Instance.new("UIStroke", KeyFrame)
    stroke.Color = Color3.fromRGB(44, 44, 46)

    local Title = Instance.new("TextLabel")
    Title.Text = "Nuu7 Hub ≡"
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.Font = Enum.Font.SFMono
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.TextSize = 14
    Title.BackgroundTransparency = 1
    Title.Parent = KeyFrame

    local KeyInput = Instance.new("TextBox")
    KeyInput.Size = UDim2.new(0, 240, 0, 32)
    KeyInput.Position = UDim2.new(0.5, -120, 0.4, 0)
    KeyInput.BackgroundColor3 = Color3.fromRGB(44, 44, 46)
    KeyInput.PlaceholderText = "Clave..."
    KeyInput.Text = ""
    KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
    KeyInput.Parent = KeyFrame
    Instance.new("UICorner", KeyInput).CornerRadius = UDim.new(0, 6)

    local SubmitBtn = Instance.new("TextButton")
    SubmitBtn.Size = UDim2.new(0, 120, 0, 30)
    SubmitBtn.Position = UDim2.new(0.5, -60, 0.75, 0)
    SubmitBtn.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
    SubmitBtn.Text = "Entrar"
    SubmitBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    SubmitBtn.Parent = KeyFrame
    Instance.new("UICorner", SubmitBtn).CornerRadius = UDim.new(0, 6)

    _G.Nuu7_State.MakeDraggable(KeyFrame)

    SubmitBtn.MouseButton1Click:Connect(function()
        if KeyInput.Text == Config.Key then
            KeyFrame:Destroy()
            Config.Active = true
            _G.Nuu7_State.InitMainUI()
        else
            KeyInput.Text = ""
            KeyInput.PlaceholderText = "Invalida."
        end
    end)
end

_G.Nuu7_State.CreateKeySystem()
-- =============================================================================
-- NUU7 HUB - PARTE 4: NÚCLEO DE RENDERIZADO Y AUTOMATISMOS
-- =============================================================================

if not _G.Nuu7_State then return end

local Services = _G.Nuu7_State.Services
local LocalPlayer = _G.Nuu7_State.LocalPlayer
local Camera = _G.Nuu7_State.Camera
local Config = _G.Nuu7_State.Config

local espCache = {}

-- Ciclo asincrónico para renderizado estable 2D y alteración local de colisiones
Services.RunService.RenderStepped:Connect(function()
    if Config.Aimbot.Enabled and _G.Nuu7_State.FOVCircle then
        _G.Nuu7_State.FOVCircle.Position = Services.UserInputService:GetMouseLocation()
    end

    if not Config.Active then return end

    for _, p in ipairs(Services.Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            
            if root and _G.Nuu7_State.IsEnemy(p) then
                -- Hitbox Invisible local (Seguridad al 100% en propiedades físicas)
                if Config.Hitbox.Enabled or Config.Hitbox.Size > 1 then
                    root.Size = Vector3.new(2 * Config.Hitbox.Size, 2 * Config.Hitbox.Size, 2 * Config.Hitbox.Size)
                    root.Transparency = 1
                    root.CanCollide = false
                end

                -- Dibujado vectorial ESP
                local hrpPos, onScreen = Camera:WorldToViewportPoint(root.Position)
                if onScreen and (Config.ESP.Lines or Config.ESP.Names or Config.ESP.Distance) then
                    if not espCache[p] then
                        espCache[p] = { Line = Drawing.new("Line"), Text = Drawing.new("Text") }
                    end
                    
                    local draw = espCache[p]
                    if Config.ESP.Lines then
                        draw.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        draw.Line.To = Vector2.new(hrpPos.X, hrpPos.Y)
                        draw.Line.Color = Color3.fromRGB(255, 59, 48)
                        draw.Line.Visible = true
                    else
                        draw.Line.Visible = false
                    end

                    if Config.ESP.Names then
                        draw.Text.Text = p.Name
                        draw.Text.Position = Vector2.new(hrpPos.X, hrpPos.Y - 20)
                        draw.Text.Color = Color3.fromRGB(255, 255, 255)
                        draw.Text.Center = true
                        draw.Text.Visible = true
                    else
                        draw.Text.Visible = false
                    end
                else
                    if espCache[p] then espCache[p].Line.Visible = false; espCache[p].Text.Visible = false end
                end
            end
        end
    end
end)

-- Motor Lock-On Agresivo & AutoShoot
Services.RunService.RenderStepped:Connect(function()
    if not Config.Active or not Config.Aimbot.Enabled then return end
    
    local targetPlayer = _G.Nuu7_State.GetClosestPlayerInFOV()
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild(Config.SilentAim.Part) then
        local targetPart = targetPlayer.Character[Config.SilentAim.Part]
        local targetPos = Camera:WorldToViewportPoint(targetPart.Position)
        local mousePos = Services.UserInputService:GetMouseLocation()
        
        -- Entrada simulada de hardware (Mouse Relativo)
        mousemoverel((targetPos.X - mousePos.X) * Config.Aimbot.Smoothness, (targetPos.Y - mousePos.Y) * Config.Aimbot.Smoothness)

        if Config.AutoShoot then
            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
            
            local result = Services.Workspace:Raycast(Camera.CFrame.Position, (targetPart.Position - Camera.CFrame.Position).Unit * 500, raycastParams)
            if result and result.Instance:IsDescendantOf(targetPlayer.Character) then
                mouse1click()
            end
        end
    end
end)
-- =============================================================================
-- NUU7 HUB - PARTE 5: INTERCEPCIÓN EN CAPA BAJA (METATABLE SILENT AIM)
-- =============================================================================

if not _G.Nuu7_State then return end

local Config = _G.Nuu7_State.Config
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcstackclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if _G.Nuu7_State.Config and Config.Active and Config.SilentAim.Enabled and method == "FindPartOnRayWithIgnoreList" then
        local targetPlayer = _G.Nuu7_State.GetClosestPlayerInFOV()
        if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild(Config.SilentAim.Part) then
            local targetedPart = targetPlayer.Character[Config.SilentAim.Part]
            local origin = args.Origin
            local direction = (targetedPart.Position - origin).Unit * 1000
            args = Ray.new(origin, direction)
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
print("[Nuu7 Hub]: Script cargado completamente y ejecutando al 100%.")
