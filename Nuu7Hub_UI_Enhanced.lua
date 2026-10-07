--// 1. Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local MarketplaceService = game:GetService("MarketplaceService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--// 2. Settings
_G.Nuu7Settings = type(_G.Nuu7Settings) == "table" and _G.Nuu7Settings or {}
local Settings = _G.Nuu7Settings

local Defaults = {
    UI_Accent = "Cyan",
    UI_Size = 100,
    IconFixed = false,
    IconHidden = false,
    ShowFps = true,
    ShaderPreset = "Reset",

    -- Compatibilidad con las opciones del Nuu7 Hub original
    ESP_Activated = false,
    Ally_ESP = false,
    Color_Outline = Color3.fromRGB(0, 255, 255),
    Color_Ally_Outline = Color3.fromRGB(0, 255, 0),

    AutoShot = false,
    ClickShot = false,
    Punto_Deteccion = 14,
    Activar_FOV = false,
    Tamano_FOV = 200,
}
for key, value in pairs(Defaults) do
    if Settings[key] == nil then
        Settings[key] = value
    end
end
Settings.UI_Size = math.clamp(tonumber(Settings.UI_Size) or 100, 70, 120)

local WIN_W, WIN_H = 480, 310
local FLOAT_DEFAULT = UDim2.new(0, 44, 0.28, 0)

--// 3. Theme
local Theme = {
    Bg = Color3.fromRGB(9, 10, 13),
    Header = Color3.fromRGB(13, 14, 18),
    Sidebar = Color3.fromRGB(12, 13, 17),
    Card = Color3.fromRGB(19, 20, 26),
    CardHover = Color3.fromRGB(25, 26, 34),
    Stroke = Color3.fromRGB(36, 38, 48),
    Text = Color3.fromRGB(234, 236, 242),
    Sub = Color3.fromRGB(128, 132, 148),
    Off = Color3.fromRGB(44, 46, 56),
    Good = Color3.fromRGB(76, 217, 140),
}

local Accents = {
    Cyan = Color3.fromRGB(0, 224, 255),
    Blue = Color3.fromRGB(46, 125, 255),
    Violet = Color3.fromRGB(145, 96, 255),
    Magenta = Color3.fromRGB(235, 74, 190),
    White = Color3.fromRGB(228, 231, 240),
}
local AccentOrder = {"Cyan", "Blue", "Violet", "Magenta", "White"}

if not Accents[Settings.UI_Accent] then
    Settings.UI_Accent = "Cyan"
end
local Accent = Accents[Settings.UI_Accent]

--// 4. Utility Functions
local WHITE = Color3.new(1, 1, 1)

local function new(className, props)
    local inst = Instance.new(className)
    local parent
    for key, value in pairs(props) do
        if key == "Parent" then
            parent = value
        else
            inst[key] = value
        end
    end
    inst.Parent = parent
    return inst
end

local function corner(inst, radius)
    return new("UICorner", {CornerRadius = UDim.new(0, radius), Parent = inst})
end

local function stroke(inst, color, thickness, transparency)
    return new("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = inst,
    })
end

local function tween(inst, duration, props, style)
    local info = TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

local function paint(inst, property, value, animate)
    if animate then
        tween(inst, 0.18, {[property] = value})
    else
        inst[property] = value
    end
end

local function label(props)
    local p = {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.Gotham,
        TextColor3 = Theme.Text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
    }
    for key, value in pairs(props) do
        p[key] = value
    end
    return new("TextLabel", p)
end

local function isPress(input)
    return input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch
end

local function luminance(color)
    return 0.299 * color.R + 0.587 * color.G + 0.114 * color.B
end

local setClipboard
pcall(function()
    setClipboard = getfenv().setclipboard
end)

local function safeClipboard(value)
    if not setClipboard then
        return false
    end
    return pcall(setClipboard, value)
end

local accentBinds = {}

local function bindAccent(fn)
    accentBinds[#accentBinds + 1] = fn
    fn(Accent, false)
end

local function applyAccent(name)
    if not Accents[name] then
        return
    end
    Settings.UI_Accent = name
    Accent = Accents[name]
    for _, fn in ipairs(accentBinds) do
        fn(Accent, true)
    end
end

local function addPress(button, target)
    local scale = new("UIScale", {Parent = target})
    button.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        tween(scale, 0.08, {Scale = 0.96})
        local conn
        conn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                conn:Disconnect()
                tween(scale, 0.14, {Scale = 1})
            end
        end)
    end)
end

local Gui = new("ScreenGui", {
    Name = "Nuu7Hub",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder = 100,
})
do
    local old = PlayerGui:FindFirstChild("Nuu7Hub")
    if old then
        old:Destroy()
    end
    Gui.Parent = PlayerGui
end

local function clampAbs(pos, minX, maxX, minY, maxY)
    local size = Gui.AbsoluteSize
    local x = math.clamp(pos.X.Scale * size.X + pos.X.Offset, minX, maxX)
    local y = math.clamp(pos.Y.Scale * size.Y + pos.Y.Offset, minY, maxY)
    return UDim2.new(pos.X.Scale, x - pos.X.Scale * size.X, pos.Y.Scale, y - pos.Y.Scale * size.Y)
end

local function makeDraggable(handle, target, clamp, canDrag, onTap)
    handle.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        local startPointer = input.Position
        local startPosition = target.Position
        local moved = false
        local moveConn, endConn
        moveConn = UserInputService.InputChanged:Connect(function(changed)
            if changed.UserInputType ~= Enum.UserInputType.MouseMovement
                and changed.UserInputType ~= Enum.UserInputType.Touch then
                return
            end
            local delta = changed.Position - startPointer
            if delta.Magnitude > 6 then
                moved = true
            end
            if moved and (not canDrag or canDrag()) then
                target.Position = clamp(UDim2.new(
                    startPosition.X.Scale, startPosition.X.Offset + delta.X,
                    startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
                ))
            end
        end)
        endConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                moveConn:Disconnect()
                endConn:Disconnect()
                if not moved and onTap then
                    onTap()
                end
            end
        end)
    end)
end

--// 5. UI Components
local function place(page, inst)
    page.Count += 1
    inst.LayoutOrder = page.Count
    inst.Parent = page.Scroll
end

local function Section(page, text)
    local holder = new("Frame", {Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1})
    local tick = new("Frame", {
        Position = UDim2.fromOffset(2, 6),
        Size = UDim2.fromOffset(2, 10),
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        Parent = holder,
    })
    bindAccent(function(color, animate)
        paint(tick, "BackgroundColor3", color, animate)
    end)
    label({
        Text = string.upper(text),
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextColor3 = Theme.Sub,
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -10, 1, 0),
        Parent = holder,
    })
    place(page, holder)
end

local function Card(page, title, desc, height)
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 66),
        BackgroundColor3 = Theme.Card,
        BorderSizePixel = 0,
    })
    corner(card, 10)
    local cardStroke = stroke(card, Theme.Stroke, 1, 0.35)
    label({
        Name = "Title",
        Text = title,
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        Position = UDim2.fromOffset(14, 10),
        Size = UDim2.new(1, -90, 0, 18),
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = card,
    })
    if desc then
        label({
            Name = "Desc",
            Text = desc,
            TextSize = 12,
            TextColor3 = Theme.Sub,
            Position = UDim2.fromOffset(14, 30),
            Size = UDim2.new(1, -90, 0, 30),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            Parent = card,
        })
    end
    place(page, card)
    return card, cardStroke
end

local function tapArea(card, callback)
    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 3,
        Parent = card,
    })
    addPress(hit, card)
    hit.MouseEnter:Connect(function()
        tween(card, 0.12, {BackgroundColor3 = Theme.CardHover})
    end)
    hit.MouseLeave:Connect(function()
        tween(card, 0.12, {BackgroundColor3 = Theme.Card})
    end)
    hit.Activated:Connect(callback)
    return hit
end

local function Toggle(page, title, desc, default, callback)
    local card = Card(page, title, desc)
    card.Title.Size = UDim2.new(1, -120, 0, 18)
    card.Desc.Size = UDim2.new(1, -120, 0, 30)

    local state = default and true or false

    local track = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(46, 26),
        BackgroundColor3 = Theme.Off,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(track, 13)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 4, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(knob, 9)
    local stateLabel = label({
        Text = "OFF",
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -68, 0.5, 0),
        Size = UDim2.fromOffset(30, 14),
        Parent = card,
    })

    local function paintState(animate)
        paint(track, "BackgroundColor3", state and Accent or Theme.Off, animate)
        paint(knob, "BackgroundColor3", (state and luminance(Accent) > 0.8) and Theme.Bg or WHITE, animate)
        paint(stateLabel, "TextColor3", state and Accent or Theme.Sub, animate)
        stateLabel.Text = state and "ON" or "OFF"
    end

    local function setState(value, animate, silent)
        state = value
        paintState(animate)
        local pos = state and UDim2.new(1, -22, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
        if animate then
            tween(knob, 0.18, {Position = pos})
        else
            knob.Position = pos
        end
        if not silent then
            callback(state)
        end
    end

    bindAccent(function(_, animate)
        paintState(animate)
    end)
    setState(state, false, true)
    tapArea(card, function()
        setState(not state, true)
    end)

    return {
        Set = function(value)
            setState(value and true or false, true, true)
        end,
    }
end

local function Slider(page, title, desc, min, max, default, callback, format)
    local card = Card(page, title, desc, 78)
    card.Title.Size = UDim2.new(1, -90, 0, 18)
    card.Desc.Size = UDim2.new(1, -28, 0, 16)
    card.Desc.TextWrapped = false
    card.Desc.TextTruncate = Enum.TextTruncate.AtEnd

    local valueLabel = label({
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.fromOffset(70, 18),
        Parent = card,
    })
    local hit = new("TextButton", {
        Text = "",
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 14, 0, 46),
        Size = UDim2.new(1, -28, 0, 26),
        Parent = card,
    })
    local track = new("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = Theme.Off,
        BorderSizePixel = 0,
        Parent = hit,
    })
    corner(track, 2)
    local fill = new("Frame", {
        Size = UDim2.fromScale(0, 1),
        BackgroundColor3 = Accent,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(fill, 2)
    local knob = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = WHITE,
        BorderSizePixel = 0,
        Parent = track,
    })
    corner(knob, 8)
    local knobStroke = stroke(knob, Accent, 2, 0)

    bindAccent(function(color, animate)
        paint(fill, "BackgroundColor3", color, animate)
        paint(valueLabel, "TextColor3", color, animate)
        paint(knobStroke, "Color", color, animate)
    end)

    local value = default
    local function render(v)
        value = math.clamp(v, min, max)
        local rel = (value - min) / (max - min)
        fill.Size = UDim2.fromScale(rel, 1)
        knob.Position = UDim2.fromScale(rel, 0.5)
        valueLabel.Text = format and format(value) or tostring(value)
    end
    render(default)

    local scroll = page.Scroll
    hit.InputBegan:Connect(function(input)
        if not isPress(input) then
            return
        end
        scroll.ScrollingEnabled = false
        local function update(x)
            local rel = math.clamp((x - hit.AbsolutePosition.X) / math.max(hit.AbsoluteSize.X, 1), 0, 1)
            local v = math.floor(min + (max - min) * rel + 0.5)
            if v ~= value then
                render(v)
                callback(value)
            end
        end
        update(input.Position.X)
        local moveConn, endConn
        moveConn = UserInputService.InputChanged:Connect(function(changed)
            if changed.UserInputType == Enum.UserInputType.MouseMovement
                or changed.UserInputType == Enum.UserInputType.Touch then
                update(changed.Position.X)
            end
        end)
        endConn = input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                moveConn:Disconnect()
                endConn:Disconnect()
                scroll.ScrollingEnabled = true
            end
        end)
    end)

    return {
        Set = function(v)
            render(v)
        end,
    }
end

local function AccentPicker(page, title, desc)
    local card = Card(page, title, desc, 100)
    card.Desc.Size = UDim2.new(1, -28, 0, 16)
    card.Desc.TextWrapped = false

    local valueLabel = label({
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Right,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 10),
        Size = UDim2.fromOffset(80, 18),
        Parent = card,
    })
    local row = new("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(14, 58),
        Size = UDim2.new(1, -28, 0, 32),
        Parent = card,
    })
    new("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        Padding = UDim.new(0, 12),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = row,
    })
    new("UIPadding", {PaddingLeft = UDim.new(0, 3), Parent = row})

    local rings = {}
    for index, name in ipairs(AccentOrder) do
        local swatch = new("TextButton", {
            LayoutOrder = index,
            Size = UDim2.fromOffset(28, 28),
            BackgroundColor3 = Accents[name],
            AutoButtonColor = false,
            Text = "",
            Parent = row,
        })
        corner(swatch, 14)
        rings[name] = stroke(swatch, Theme.Text, 2, 1)
        addPress(swatch, swatch)
        swatch.Activated:Connect(function()
            applyAccent(name)
        end)
    end

    bindAccent(function(color, animate)
        for name, ring in pairs(rings) do
            paint(ring, "Transparency", name == Settings.UI_Accent and 0 or 1, animate)
        end
        valueLabel.Text = Settings.UI_Accent
        paint(valueLabel, "TextColor3", color, animate)
    end)
end

local function Action(page, title, desc, buttonText, callback)
    local card = Card(page, title, desc)
    card.Title.Size = UDim2.new(1, -120, 0, 18)
    card.Desc.Size = UDim2.new(1, -120, 0, 30)

    local pill = new("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(84, 30),
        BackgroundColor3 = Accent,
        BackgroundTransparency = 0.86,
        BorderSizePixel = 0,
        Parent = card,
    })
    corner(pill, 8)
    local pillStroke = stroke(pill, Accent, 1, 0.5)
    local pillText = label({
        Text = buttonText,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1),
        Parent = pill,
    })
    bindAccent(function(color, animate)
        paint(pill, "BackgroundColor3", color, animate)
        paint(pillStroke, "Color", color, animate)
        paint(pillText, "TextColor3", color, animate)
    end)
    tapArea(card, callback)
    return {Text = pillText}
end

local function Options(page, options, current, onSelect)
    local items = {}
    local selected = current

    local function style(animate)
        for id, item in pairs(items) do
            local active = id == selected
            paint(item.Stroke, "Color", active and Accent or Theme.Stroke, animate)
            paint(item.Stroke, "Transparency", active and 0.1 or 0.35, animate)
            paint(item.Pill, "BackgroundColor3", Accent, animate)
            paint(item.Pill, "BackgroundTransparency", active and 0.86 or 1, animate)
            paint(item.Status, "TextColor3", active and Accent or Theme.Sub, animate)
            item.Status.Text = active and "Activo" or "Inactivo"
        end
    end

    for _, option in ipairs(options) do
        local card, cardStroke = Card(page, option.Name, option.Desc)
        card.Title.Size = UDim2.new(1, -110, 0, 18)
        card.Desc.Size = UDim2.new(1, -110, 0, 30)
        local pill = new("Frame", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -14, 0.5, 0),
            Size = UDim2.fromOffset(66, 24),
            BackgroundColor3 = Accent,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Parent = card,
        })
        corner(pill, 12)
        local status = label({
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            TextXAlignment = Enum.TextXAlignment.Center,
            Size = UDim2.fromScale(1, 1),
            Parent = pill,
        })
        items[option.Id] = {Stroke = cardStroke, Pill = pill, Status = status}
        tapArea(card, function()
            if selected == option.Id then
                return
            end
            selected = option.Id
            style(true)
            onSelect(option.Id)
        end)
    end

    bindAccent(function(_, animate)
        style(animate)
    end)
end

local function StatGrid(page, defs)
    local grid = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    })
    new("UIGridLayout", {
        CellSize = UDim2.new(0.5, -4, 0, 56),
        CellPadding = UDim2.fromOffset(8, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = grid,
    })
    local values = {}
    for index, def in ipairs(defs) do
        local cell = new("Frame", {
            LayoutOrder = index,
            BackgroundColor3 = Theme.Card,
            BorderSizePixel = 0,
            Parent = grid,
        })
        corner(cell, 10)
        stroke(cell, Theme.Stroke, 1, 0.35)
        label({
            Text = string.upper(def.Label),
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextColor3 = Theme.Sub,
            Position = UDim2.fromOffset(12, 9),
            Size = UDim2.new(1, -24, 0, 12),
            Parent = cell,
        })
        values[def.Key] = label({
            Text = def.Value,
            Font = Enum.Font.GothamMedium,
            TextSize = 14,
            Position = UDim2.fromOffset(12, 26),
            Size = UDim2.new(1, -24, 0, 20),
            TextTruncate = Enum.TextTruncate.AtEnd,
            Parent = cell,
        })
        if def.Dot then
            local dot = new("Frame", {
                Position = UDim2.new(1, -18, 0, 11),
                Size = UDim2.fromOffset(6, 6),
                BackgroundColor3 = Theme.Good,
                BorderSizePixel = 0,
                Parent = cell,
            })
            corner(dot, 3)
        end
    end
    place(page, grid)
    return values
end

--// 6. Main Window
local Window = new("Frame", {
    Name = "Window",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIN_W, WIN_H),
    BackgroundTransparency = 1,
    Visible = false,
    Parent = Gui,
})
local WindowScale = new("UIScale", {Parent = Window})

local Stage = new("Frame", {
    Name = "Stage",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Parent = Window,
})
local Pop = new("UIScale", {Parent = Stage})

local Shadow = new("ImageLabel", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.new(1, 44, 1, 44),
    BackgroundTransparency = 1,
    Image = "rbxassetid://6014261993",
    ImageColor3 = Color3.new(0, 0, 0),
    ImageTransparency = 0.55,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    ZIndex = 0,
    Parent = Stage,
})

local Main = new("CanvasGroup", {
    Name = "MainFrame",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    ZIndex = 1,
    Parent = Stage,
})
corner(Main, 14)

local Outline = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    ZIndex = 5,
    Parent = Stage,
})
corner(Outline, 14)
local OutlineStroke = stroke(Outline, Theme.Stroke, 1, 0.2)

local Header = new("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = Theme.Header,
    BorderSizePixel = 0,
    Parent = Main,
})
local HeaderMark = new("Frame", {
    Position = UDim2.fromOffset(14, 13),
    Size = UDim2.fromOffset(2, 26),
    BackgroundColor3 = Accent,
    BorderSizePixel = 0,
    Parent = Header,
})
corner(HeaderMark, 1)
label({
    Text = "Nuu7 Hub",
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    Position = UDim2.fromOffset(26, 8),
    Size = UDim2.fromOffset(180, 20),
    Parent = Header,
})
local VersionLabel = label({
    Text = "V2",
    Font = Enum.Font.GothamMedium,
    TextSize = 11,
    TextColor3 = Accent,
    Position = UDim2.fromOffset(26, 28),
    Size = UDim2.fromOffset(60, 14),
    Parent = Header,
})
local HeaderLine = new("Frame", {
    Position = UDim2.new(0, 0, 1, -1),
    Size = UDim2.new(1, 0, 0, 1),
    BackgroundColor3 = Accent,
    BorderSizePixel = 0,
    Parent = Header,
})
new("UIGradient", {
    Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.25, 0.35),
        NumberSequenceKeypoint.new(0.75, 0.35),
        NumberSequenceKeypoint.new(1, 1),
    }),
    Parent = HeaderLine,
})

local FpsPill = new("TextLabel", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -54, 0.5, 0),
    Size = UDim2.fromOffset(68, 22),
    BackgroundColor3 = Theme.Card,
    BorderSizePixel = 0,
    Font = Enum.Font.GothamMedium,
    Text = "-- FPS",
    TextColor3 = Accent,
    TextSize = 11,
    Visible = Settings.ShowFps,
    Parent = Header,
})
corner(FpsPill, 11)

local CloseButton = new("TextButton", {
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -10, 0.5, 0),
    Size = UDim2.fromOffset(34, 34),
    BackgroundTransparency = 1,
    AutoButtonColor = false,
    Font = Enum.Font.GothamMedium,
    Text = "×",
    TextColor3 = Theme.Sub,
    TextSize = 24,
    Parent = Header,
})
addPress(CloseButton, CloseButton)
CloseButton.MouseEnter:Connect(function()
    tween(CloseButton, 0.12, {TextColor3 = Theme.Text})
end)
CloseButton.MouseLeave:Connect(function()
    tween(CloseButton, 0.12, {TextColor3 = Theme.Sub})
end)

bindAccent(function(color, animate)
    paint(HeaderMark, "BackgroundColor3", color, animate)
    paint(VersionLabel, "TextColor3", color, animate)
    paint(HeaderLine, "BackgroundColor3", color, animate)
    paint(FpsPill, "TextColor3", color, animate)
end)

local Body = new("Frame", {
    Position = UDim2.fromOffset(0, 52),
    Size = UDim2.new(1, 0, 1, -52),
    BackgroundTransparency = 1,
    Parent = Main,
})

local function updateScale()
    local viewport = Gui.AbsoluteSize
    local fit = math.min(viewport.X * 0.98 / WIN_W, viewport.Y * 0.96 / WIN_H)
    local base = math.clamp(math.min(viewport.X * 0.94 / WIN_W, viewport.Y * 0.88 / WIN_H), 0.45, 1.1)
    WindowScale.Scale = math.max(0.4, math.min(base * Settings.UI_Size / 100, fit))
end

local function clampWindow(pos)
    local size = Gui.AbsoluteSize
    local halfHeight = WIN_H * WindowScale.Scale / 2
    return clampAbs(pos, 60, size.X - 60, math.min(halfHeight, size.Y / 2), size.Y - 30)
end

makeDraggable(Header, Window, clampWindow)

--// 7. Sidebar
local Sidebar = new("Frame", {
    Name = "Sidebar",
    Size = UDim2.new(0, 108, 1, 0),
    BackgroundColor3 = Theme.Sidebar,
    BorderSizePixel = 0,
    Parent = Body,
})
new("Frame", {
    Position = UDim2.new(1, -1, 0, 0),
    Size = UDim2.new(0, 1, 1, 0),
    BackgroundColor3 = Theme.Stroke,
    BorderSizePixel = 0,
    Parent = Sidebar,
})
local TabList = new("Frame", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Parent = Sidebar,
})
new("UIListLayout", {
    Padding = UDim.new(0, 6),
    SortOrder = Enum.SortOrder.LayoutOrder,
    Parent = TabList,
})
new("UIPadding", {
    PaddingTop = UDim.new(0, 10),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
    Parent = TabList,
})

local Content = new("Frame", {
    Name = "Content",
    Position = UDim2.fromOffset(108, 0),
    Size = UDim2.new(1, -108, 1, 0),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    Parent = Body,
})

local TabButtons = {}
local Pages = {}

local function styleTab(name, active)
    local tab = TabButtons[name]
    tab.Active = active
    tween(tab.Button, 0.15, {BackgroundTransparency = active and 0 or 1})
    tween(tab.Bar, 0.15, {BackgroundTransparency = active and 0 or 1})
    tween(tab.Icon, 0.15, {BackgroundColor3 = active and Accent or Theme.Off})
    tween(tab.Text, 0.15, {TextColor3 = active and Theme.Text or Theme.Sub})
end

local CurrentTab

local function selectTab(name, instant)
    if CurrentTab == name then
        return
    end
    local previous = CurrentTab
    CurrentTab = name
    if previous then
        Pages[previous].Group.Visible = false
        styleTab(previous, false)
    end
    styleTab(name, true)
    local group = Pages[name].Group
    group.Visible = true
    if instant then
        group.GroupTransparency = 0
        group.Position = UDim2.new()
        return
    end
    group.GroupTransparency = 1
    group.Position = UDim2.fromOffset(0, 10)
    tween(group, 0.2, {GroupTransparency = 0, Position = UDim2.new()})
end

local function createTab(name, order)
    local button = new("TextButton", {
        Name = name,
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 38),
        BackgroundColor3 = Theme.Card,
        BackgroundTransparency = 1,
        AutoButtonColor = false,
        Text = "",
        Parent = TabList,
    })
    corner(button, 9)
    local bar = new("Frame", {
        Position = UDim2.new(0, 3, 0.5, -8),
        Size = UDim2.fromOffset(3, 16),
        BackgroundColor3 = Accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = button,
    })
    corner(bar, 2)
    local icon = new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 20, 0.5, 0),
        Size = UDim2.fromOffset(7, 7),
        Rotation = 45,
        BackgroundColor3 = Theme.Off,
        BorderSizePixel = 0,
        Parent = button,
    })
    corner(icon, 2)
    local text = label({
        Text = name,
        Font = Enum.Font.GothamMedium,
        TextColor3 = Theme.Sub,
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -38, 1, 0),
        Parent = button,
    })
    local tab = {Button = button, Bar = bar, Icon = icon, Text = text, Active = false}
    TabButtons[name] = tab

    addPress(button, button)
    button.MouseEnter:Connect(function()
        if not tab.Active then
            tween(button, 0.12, {BackgroundTransparency = 0.6})
        end
    end)
    button.MouseLeave:Connect(function()
        if not tab.Active then
            tween(button, 0.12, {BackgroundTransparency = 1})
        end
    end)
    button.Activated:Connect(function()
        selectTab(name)
    end)
    bindAccent(function(color, animate)
        if tab.Active then
            paint(icon, "BackgroundColor3", color, animate)
            paint(bar, "BackgroundColor3", color, animate)
        else
            bar.BackgroundColor3 = color
        end
    end)
end

local function createPage(name)
    local group = new("CanvasGroup", {
        Name = name,
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Visible = false,
        Parent = Content,
    })
    local scroll = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Accent,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        Parent = group,
    })
    new("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = scroll,
    })
    new("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 14),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 14),
        Parent = scroll,
    })
    bindAccent(function(color, animate)
        paint(scroll, "ScrollBarImageColor3", color, animate)
    end)
    local page = {Group = group, Scroll = scroll, Count = 0}
    Pages[name] = page
    return page
end

local TabNames = {"Info", "RenyShot", "Movil", "Visual", "ESP", "Shader", "Tools"}
for index, name in ipairs(TabNames) do
    createTab(name, index)
end

--// 8. Tabs
local Info = createPage("Info")
local RenyShot = createPage("RenyShot")
local Movil = createPage("Movil")
local Visual = createPage("Visual")
local ESP = createPage("ESP")
local Shader = createPage("Shader")
local Tools = createPage("Tools")

local controls = {}
local clockSlider
local applyPreset

-- Info
Section(Info, "Panel")
Card(Info, "Nuu7 Hub", "Interfaz móvil V2 con diseño oscuro minimalista.", 62)
local InfoValues = StatGrid(Info, {
    {Key = "Version", Label = "Version", Value = "V2"},
    {Key = "Status", Label = "Status", Value = "Online", Dot = true},
    {Key = "Device", Label = "Device", Value = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled) and "Mobile" or "PC"},
    {Key = "Player", Label = "Player", Value = LocalPlayer.Name},
    {Key = "Game", Label = "Game", Value = game.Name},
    {Key = "Players", Label = "Players", Value = "--"},
    {Key = "Ping", Label = "Ping", Value = "--"},
    {Key = "FPS", Label = "FPS", Value = "--"},
})
local serverCard = Card(Info, "Server", game.JobId ~= "" and game.JobId or "Sin JobId (Studio)", 62)
serverCard.Desc.Size = UDim2.new(1, -28, 0, 30)

-- Visual
local camera = Workspace.CurrentCamera
local fovDefault = math.clamp(Settings.FOV or math.floor((camera and camera.FieldOfView or 70) + 0.5), 40, 120)

Section(Visual, "Cámara")
controls.Fov = Slider(Visual, "Campo de visión", "Ajusta el FOV de la cámara", 40, 120, fovDefault, function(value)
    Settings.FOV = value
    local currentCamera = Workspace.CurrentCamera
    if currentCamera then
        currentCamera.FieldOfView = value
    end
end, function(value)
    return value .. "°"
end)

Section(Visual, "Interfaz")
controls.Fps = Toggle(Visual, "Contador de FPS", "Muestra los FPS reales en la cabecera", Settings.ShowFps, function(value)
    Settings.ShowFps = value
    FpsPill.Visible = value
end)

-- RenyShot
Section(RenyShot, "Modo de disparo")
controls.AutoShot = Toggle(
    RenyShot,
    "AutoShot",
    "Activa la configuración de AutoShot del Hub original.",
    Settings.AutoShot,
    function(value)
        Settings.AutoShot = value
    end
)

controls.ClickShot = Toggle(
    RenyShot,
    "ClickShot",
    "Configuración reservada del sistema original.",
    Settings.ClickShot,
    function(value)
        Settings.ClickShot = value
    end
)

Section(RenyShot, "Configuración de detección")
controls.DetectionPoints = Slider(
    RenyShot,
    "Punto de detección",
    "Cantidad de puntos de detección configurada.",
    1,
    50,
    Settings.Punto_Deteccion,
    function(value)
        Settings.Punto_Deteccion = value
    end
)

Section(RenyShot, "FOV")
controls.ActivateFov = Toggle(
    RenyShot,
    "Activar FOV",
    "Limita la configuración de detección al campo de visión.",
    Settings.Activar_FOV,
    function(value)
        Settings.Activar_FOV = value
    end
)

controls.RenyFov = Slider(
    RenyShot,
    "Tamaño FOV",
    "Radio del campo de visión.",
    10,
    500,
    Settings.Tamano_FOV,
    function(value)
        Settings.Tamano_FOV = value
    end
)

-- Movil
Section(Movil, "Controles móviles")
Card(Movil, "Interfaz táctil", "Controles optimizados para tocar, arrastrar y desplazar.", 62)
controls.LockMobile = Toggle(
    Movil,
    "Fijar icono flotante",
    "Impide mover accidentalmente el botón N7.",
    Settings.IconFixed,
    function(value)
        Settings.IconFixed = value
    end
)

controls.HideMobile = Toggle(
    Movil,
    "Ocultar icono flotante",
    "Hace transparente el botón sin eliminarlo.",
    Settings.IconHidden,
    function(value)
        Settings.IconHidden = value
        if FloatHolder then
            FloatHolder.Visible = not value
        end
    end
)

controls.MobileScale = Slider(
    Movil,
    "Escala de interfaz",
    "Ajusta el tamaño general del Hub.",
    70,
    120,
    Settings.UI_Size,
    function(value)
        Settings.UI_Size = value
        updateScale()
    end,
    function(value)
        return value .. "%"
    end
)

Section(Movil, "Atajos")
Card(Movil, "Arrastre de ventana", "Mantén pulsado el encabezado para mover el Hub.", 62)
Card(Movil, "Botón N7", "Tócalo para abrir o cerrar la interfaz.", 62)

-- ESP
Section(ESP, "Visión")
controls.ESP = Toggle(
    ESP,
    "ESP activado",
    "Configuración de ESP para jugadores enemigos.",
    Settings.ESP_Activated,
    function(value)
        Settings.ESP_Activated = value
    end
)

controls.AllyESP = Toggle(
    ESP,
    "Ally ESP",
    "Configuración de ESP para aliados.",
    Settings.Ally_ESP,
    function(value)
        Settings.Ally_ESP = value
    end
)

Section(ESP, "Colores")
local function colorSetting(page, title, desc, settingKey)
    local card = Card(page, title, desc, 82)
    local value = Settings[settingKey]

    local swatch = new("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -14, 0.5, 0),
        Size = UDim2.fromOffset(42, 30),
        BackgroundColor3 = value,
        AutoButtonColor = false,
        Text = "",
        Parent = card,
    })
    corner(swatch, 8)
    local swatchStroke = stroke(swatch, Theme.Stroke, 1, 0.2)

    local colors = {
        Cyan = Color3.fromRGB(0, 255, 255),
        Green = Color3.fromRGB(0, 255, 0),
        Red = Color3.fromRGB(255, 70, 90),
        Yellow = Color3.fromRGB(255, 220, 70),
        Violet = Color3.fromRGB(145, 96, 255),
    }
    local order = {"Cyan", "Green", "Red", "Yellow", "Violet"}
    local index = 1

    for i, colorName in ipairs(order) do
        if colors[colorName] == value then
            index = i
            break
        end
    end

    local function setColor(color)
        Settings[settingKey] = color
        paint(swatch, "BackgroundColor3", color, true)
        paint(swatchStroke, "Color", color, true)
    end

    swatch.Activated:Connect(function()
        index = index % #order + 1
        setColor(colors[order[index]])
    end)

    addPress(swatch, swatch)
    return swatch
end

colorSetting(ESP, "Color Outline", "Color del contorno del ESP enemigo.", "Color_Outline")
colorSetting(ESP, "Color Ally Outline", "Color del contorno del ESP aliado.", "Color_Ally_Outline")

Card(
    ESP,
    "Estado de integración",
    "Estas opciones conservan la configuración del Hub original. El archivo original no incluía el motor ESP que renderiza los contornos.",
    82
)

-- Shader
local colorGrade = Lighting:FindFirstChild("Nuu7_ColorGrade")
if not colorGrade then
    colorGrade = Instance.new("ColorCorrectionEffect")
    colorGrade.Name = "Nuu7_ColorGrade"
    colorGrade.Enabled = false
    colorGrade.Parent = Lighting
end

local baseClock = Lighting.ClockTime

local Presets = {
    Tokyo = {
        Clock = 20,
        Tint = Color3.fromRGB(205, 190, 255),
        Saturation = 0.25,
        Contrast = 0.12,
        Brightness = 0
    },
    Night = {
        Clock = 0,
        Tint = Color3.fromRGB(165, 185, 255),
        Saturation = -0.1,
        Contrast = 0.1,
        Brightness = -0.04
    },
    Pink = {
        Clock = 17.5,
        Tint = Color3.fromRGB(255, 205, 225),
        Saturation = 0.2,
        Contrast = 0.05,
        Brightness = 0.02
    },
}

applyPreset = function(id)
    Settings.ShaderPreset = id
    local preset = Presets[id]

    if preset then
        colorGrade.Enabled = true
        tween(colorGrade, 0.4, {
            TintColor = preset.Tint,
            Saturation = preset.Saturation,
            Contrast = preset.Contrast,
            Brightness = preset.Brightness,
        })
        tween(Lighting, 0.4, {ClockTime = preset.Clock})

        if clockSlider then
            clockSlider.Set(math.floor(preset.Clock + 0.5))
        end
    else
        tween(colorGrade, 0.4, {
            TintColor = WHITE,
            Saturation = 0,
            Contrast = 0,
            Brightness = 0
        })

        task.delay(0.42, function()
            if Settings.ShaderPreset == "Reset" then
                colorGrade.Enabled = false
            end
        end)

        tween(Lighting, 0.4, {ClockTime = baseClock})

        if clockSlider then
            clockSlider.Set(math.floor(baseClock + 0.5))
        end
    end
end

Section(Shader, "Ambientes")
Options(Shader, {
    {Id = "Tokyo", Name = "Tokyo", Desc = "Atardecer neón con tonos violetas."},
    {Id = "Night", Name = "Night", Desc = "Noche fría con contraste suave."},
    {Id = "Pink", Name = "Pink", Desc = "Luz cálida con matiz rosado."},
    {Id = "Reset", Name = "Reset", Desc = "Restaura la iluminación original."},
}, Presets[Settings.ShaderPreset] and Settings.ShaderPreset or "Reset", function(id)
    applyPreset(id)
end)

Section(Shader, "Tiempo")
clockSlider = Slider(
    Shader,
    "Hora del juego",
    "Cambia la hora de la iluminación.",
    0,
    24,
    math.floor(Lighting.ClockTime + 0.5),
    function(value)
        Settings.Hora_Juego = value
        Lighting.ClockTime = value
    end,
    function(value)
        return string.format("%02d:00", value % 24)
    end
)

-- Tools
Section(Tools, "Servidor")
local copy
copy = Action(
    Tools,
    "Copiar Server ID",
    "Copia el JobId del servidor actual.",
    "Copiar",
    function()
        if game.JobId == "" then
            copy.Text.Text = "Sin ID"
            task.delay(1.2, function()
                copy.Text.Text = "Copiar"
            end)
            return
        end

        local ok = safeClipboard(game.JobId)
        copy.Text.Text = ok and "Copiado" or "Error"

        task.delay(1.2, function()
            copy.Text.Text = "Copiar"
        end)
    end
)

local copyLink
copyLink = Action(
    Tools,
    "Copiar enlace del servidor",
    "Genera un enlace con PlaceId y JobId.",
    "Copiar",
    function()
        if game.JobId == "" then
            copyLink.Text.Text = "Sin ID"
            task.delay(1.2, function()
                copyLink.Text.Text = "Copiar"
            end)
            return
        end

        local url = "https://www.roblox.com/games/" .. tostring(game.PlaceId) .. "?server=" .. game.JobId
        local ok = safeClipboard(url)

        copyLink.Text.Text = ok and "Copiado" or "Error"
        task.delay(1.2, function()
            copyLink.Text.Text = "Copiar"
        end)
    end
)

Card(
    Tools,
    "Buscar servidor",
    "El código original mostraba esta opción, pero no contenía una implementación real de búsqueda o teletransporte entre servidores. No se agrega una falsa.",
    82
)

Section(Tools, "Interfaz")
controls.Size = Slider(
    Tools,
    "Tamaño de UI",
    "Escala de la ventana (70% a 120%).",
    70,
    120,
    Settings.UI_Size,
    function(value)
        Settings.UI_Size = value
        updateScale()
    end,
    function(value)
        return value .. "%"
    end
)

AccentPicker(Tools, "Color de acento", "Cambia el color principal del Hub.")

controls.Lock = Toggle(
    Tools,
    "Fijar icono",
    "Impide mover el botón flotante.",
    Settings.IconFixed,
    function(value)
        Settings.IconFixed = value
    end
)

controls.Hide = Toggle(
    Tools,
    "Ocultar icono",
    "Oculta visualmente el botón flotante.",
    Settings.IconHidden,
    function(value)
        Settings.IconHidden = value
        if FloatHolder then
            FloatHolder.Visible = not value
        end
    end
)

Section(Tools, "Sistema")
Action(
    Tools,
    "Restablecer interfaz",
    "Vuelve al tamaño, color y posición originales.",
    "Reset",
    function()
        Settings.UI_Size = 100
        controls.Size.Set(100)
        if controls.MobileScale then
            controls.MobileScale.Set(100)
        end
        updateScale()

        applyAccent("Cyan")

        Settings.IconFixed = false
        controls.Lock.Set(false)
        if controls.LockMobile then
            controls.LockMobile.Set(false)
        end

        Settings.IconHidden = false
        if controls.Hide then
            controls.Hide.Set(false)
        end
        if controls.HideMobile then
            controls.HideMobile.Set(false)
        end

        if FloatHolder then
            FloatHolder.Visible = true
            FloatHolder.Position = FLOAT_DEFAULT
        end

        Settings.ShowFps = true
        controls.Fps.Set(true)
        FpsPill.Visible = true

        Window.Position = UDim2.fromScale(0.5, 0.5)
    end
)

--// 9. Animations
local fpsConnection
local setFloatVisual

local function updateMetrics(fps)
    FpsPill.Text = fps .. " FPS"
    InfoValues.FPS.Text = tostring(fps)
    InfoValues.Players.Text = #Players:GetPlayers() .. "/" .. Players.MaxPlayers
    local ok, ping = pcall(function()
        return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
    end)
    InfoValues.Ping.Text = ok and (math.floor(ping + 0.5) .. " ms") or "N/A"
end

local function startMonitor()
    if fpsConnection then
        return
    end
    local frames, elapsed = 0, 0
    fpsConnection = RunService.Heartbeat:Connect(function(dt)
        frames += 1
        elapsed += dt
        if elapsed >= 0.5 then
            local fps = math.floor(frames / elapsed + 0.5)
            frames, elapsed = 0, 0
            updateMetrics(fps)
        end
    end)
end

local function stopMonitor()
    if fpsConnection then
        fpsConnection:Disconnect()
        fpsConnection = nil
    end
end

local isOpen = false

local function setOpen(open)
    if open == isOpen then
        return
    end
    isOpen = open
    if setFloatVisual then
        setFloatVisual(open)
    end
    if open then
        Window.Visible = true
        Main.GroupTransparency = 1
        Shadow.ImageTransparency = 1
        OutlineStroke.Transparency = 1
        Pop.Scale = 0.95
        Stage.Position = UDim2.new(0.5, 0, 0.5, 12)
        tween(Main, 0.22, {GroupTransparency = 0})
        tween(Shadow, 0.22, {ImageTransparency = 0.55})
        tween(OutlineStroke, 0.22, {Transparency = 0.2})
        tween(Pop, 0.22, {Scale = 1})
        tween(Stage, 0.22, {Position = UDim2.fromScale(0.5, 0.5)})
        startMonitor()
    else
        tween(Main, 0.16, {GroupTransparency = 1})
        tween(Shadow, 0.16, {ImageTransparency = 1})
        tween(OutlineStroke, 0.16, {Transparency = 1})
        tween(Pop, 0.16, {Scale = 0.95})
        tween(Stage, 0.16, {Position = UDim2.new(0.5, 0, 0.5, 12)})
        stopMonitor()
        task.delay(0.18, function()
            if not isOpen then
                Window.Visible = false
            end
        end)
    end
end

CloseButton.Activated:Connect(function()
    setOpen(false)
end)

--// 10. Floating Button
FloatHolder = new("Frame", {
    Name = "Nuu7Icon",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = FLOAT_DEFAULT,
    Size = UDim2.fromOffset(64, 64),
    BackgroundTransparency = 1,
    ZIndex = 20,
    Parent = Gui,
})
local FloatGlow = new("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Accent,
    BackgroundTransparency = 0.93,
    BorderSizePixel = 0,
    ZIndex = 20,
    Parent = FloatHolder,
})
corner(FloatGlow, 32)
local FloatButton = new("TextButton", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(48, 48),
    BackgroundColor3 = Theme.Bg,
    AutoButtonColor = false,
    Font = Enum.Font.GothamBold,
    Text = "N7",
    TextColor3 = Theme.Text,
    TextSize = 15,
    ZIndex = 21,
    Parent = FloatHolder,
})
corner(FloatButton, 24)
local FloatRing = stroke(FloatButton, Accent, 1.5, 0.45)
addPress(FloatButton, FloatButton)

bindAccent(function(color, animate)
    paint(FloatGlow, "BackgroundColor3", color, animate)
    paint(FloatRing, "Color", color, animate)
end)

setFloatVisual = function(open)
    tween(FloatRing, 0.2, {Transparency = open and 0 or 0.45})
    tween(FloatGlow, 0.2, {BackgroundTransparency = open and 0.8 or 0.93})
end

local function clampFloat(pos)
    local size = Gui.AbsoluteSize
    return clampAbs(pos, 32, size.X - 32, 32, size.Y - 32)
end

makeDraggable(FloatButton, FloatHolder, clampFloat, function()
    return not Settings.IconFixed
end, function()
    setOpen(not isOpen)
end)

FloatHolder.Visible = not Settings.IconHidden

--// 11. Initialization
updateScale()
selectTab("Info", true)

if Presets[Settings.ShaderPreset] then
    applyPreset(Settings.ShaderPreset)
end

task.spawn(function()
    local ok, info = pcall(MarketplaceService.GetProductInfo, MarketplaceService, game.PlaceId)
    if ok and info and info.Name then
        InfoValues.Game.Text = info.Name
    end
end)

Gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
    updateScale()
    Window.Position = clampWindow(Window.Position)
    FloatHolder.Position = clampFloat(FloatHolder.Position)
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed and input.KeyCode == Enum.KeyCode.RightShift then
        setOpen(not isOpen)
    end
end)

Gui.Destroying:Connect(stopMonitor)
