--[[
    DanXys Anti Tela v1.7 | Electric Particles + Neon UI + Server Monitor
    Interface Luau client-side. Usa apenas Players e propriedades publicas.
    Nao identifica espectadores invisiveis nem ferramentas administrativas.
    Pop-ups compactos, com barra de 1.5 segundo.
]]

local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

-- Para usar a arte de titulo identica a previa, faca upload do PNG
-- fornecido ao Roblox Creator Hub e cole o ID abaixo.
-- Exemplo: "rbxassetid://123456789012345"
-- Sem o ID, o titulo futurista e desenhado usando fonte nativa.
local LOGO_IMAGE_ID = "rbxassetid://133068819773560"

-- Reexecutar sem duplicar o sensor e suas conexoes.
if _G.DanXysCleanup then pcall(_G.DanXysCleanup) end
if _G.VLMonitorCleanup then pcall(_G.VLMonitorCleanup) end
for _, name in ipairs({"DanXysAntiTela", "VLServerMonitor"}) do
    local previous = CoreGui:FindFirstChild(name)
    if previous then previous:Destroy() end
end

local alive = true
local connections = {}
local titleTweens = {}
local function listen(signal, fn)
    local connection = signal:Connect(fn)
    table.insert(connections, connection)
    return connection
end
local function el(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do object[key] = value end
    object.Parent = parent
    return object
end
local function rounded(parent, radius)
    return el("UICorner", {CornerRadius = UDim.new(0, radius or 10)}, parent)
end
local function outline(parent, color, thickness, transparency)
    return el("UIStroke", {
        Color = color, Thickness = thickness or 1,
        Transparency = transparency or 0
    }, parent)
end
local function tween(object, duration, goal, easing)
    local t = TweenService:Create(object,
        TweenInfo.new(duration, easing or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), goal)
    t:Play()
    return t
end

local C = {
    black = Color3.fromRGB(1, 2, 5),
    background = Color3.fromRGB(2, 5, 11),
    card = Color3.fromRGB(2, 6, 14),
    button = Color3.fromRGB(3, 16, 34),
    deepBlue = Color3.fromRGB(0, 54, 120),
    blue = Color3.fromRGB(0, 122, 255),
    cyan = Color3.fromRGB(2, 202, 255),
    white = Color3.fromRGB(250, 252, 255),
    muted = Color3.fromRGB(151, 184, 217),
    green = Color3.fromRGB(38, 255, 151),
    red = Color3.fromRGB(255, 46, 102),
    yellow = Color3.fromRGB(255, 199, 35)
}

local function text(parent, content, pos, size, fontSize, color, bold)
    return el("TextLabel", {
        BackgroundTransparency = 1, Position = pos, Size = size,
        Text = content, Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextColor3 = color or C.white, TextSize = fontSize or 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BorderSizePixel = 0
    }, parent)
end
local function button(parent, content, x, y, w, h, accent)
    local b = el("TextButton", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = C.button, BorderSizePixel = 0,
        Text = content, TextColor3 = C.white,
        Font = Enum.Font.GothamBlack, TextSize = 13,
        AutoButtonColor = false
    }, parent)
    rounded(b, 8)
    local edge = outline(b, accent or C.blue, 1.35, 0.06)
    el("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(178, 205, 245))
        })
    }, b)
    listen(b.MouseEnter, function()
        if alive then
            tween(b, 0.15, {BackgroundColor3 = Color3.fromRGB(0, 91, 185)})
            tween(edge, 0.15, {Thickness = 2.4, Transparency = 0})
        end
    end)
    listen(b.MouseLeave, function()
        if alive then
            tween(b, 0.15, {BackgroundColor3 = b:GetAttribute("Selected") and C.deepBlue or C.button})
            tween(edge, 0.15, {Thickness = 1.35, Transparency = 0.06})
        end
    end)
    return b
end
local function card(parent, x, y, w, h, heading, headingColor, strokeColor)
    -- Aura externa, por baixo do cartão. Cria profundidade sem shaders.
    local aura = el("Frame", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, parent)
    rounded(aura, 11)
    local auraEdge = outline(aura, strokeColor or C.blue, 5.5, 0.85)
    local auraTween = TweenService:Create(auraEdge,
        TweenInfo.new(2.7, Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut, -1, true),
        {Transparency = 0.68, Thickness = 7})
    auraTween:Play()
    table.insert(titleTweens, auraTween)
    local f = el("Frame", {
        Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0
    }, parent)
    rounded(f, 11)
    outline(f, strokeColor or C.blue, 2.05, 0)
    el("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 20, 44)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(2, 9, 23)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(1, 3, 10))
        })
    }, f)
    -- pequeno brilho lateral fixo, sem loop de renderizacao
    local rail = el("Frame", {
        Position = UDim2.fromOffset(0, 17), Size = UDim2.fromOffset(2, h-34),
        BorderSizePixel = 0, BackgroundColor3 = strokeColor or C.cyan,
        BackgroundTransparency = 0.12
    }, f)
    rounded(rail, 2)
    if heading then
        local headingLabel = text(f, heading, UDim2.fromOffset(14, 8),
            UDim2.new(1, -28, 0, 26), 15, headingColor or C.cyan, true)
        headingLabel.Font = Enum.Font.GothamBlack
    end
    return f
end

local gui = el("ScreenGui", {
    Name = "DanXysAntiTela", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 500,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, CoreGui)

local PANEL_W, PANEL_H = 754, 735
local underGlow = el("Frame", {
    Name = "NeonGlow",
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 14, 0.5, 0),
    Size = UDim2.fromOffset(PANEL_W + 8, PANEL_H + 8),
    BackgroundTransparency = 1, BorderSizePixel = 0
}, gui)
rounded(underGlow, 19)
outline(underGlow, C.blue, 8, 0.75)

local panel = el("Frame", {
    Name = "NeonPanel", AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 18, 0.5, 0),
    Size = UDim2.fromOffset(PANEL_W, PANEL_H),
    BackgroundColor3 = Color3.fromRGB(255, 255, 255), BorderSizePixel = 0,
    Active = true
}, gui)
rounded(panel, 15)
local border = outline(panel, C.cyan, 2.7, 0)
local borderGradient = el("UIGradient", {
    Rotation = 35,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 22, 95)),
        ColorSequenceKeypoint.new(0.28, C.cyan),
        ColorSequenceKeypoint.new(0.63, Color3.fromRGB(0, 90, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 22, 95))
    })
}, border)
-- Agora existe movimento real nas bordas: a v1.6 tinha degradê ESTÁTICO.
local borderMotion = TweenService:Create(borderGradient,
    TweenInfo.new(6, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1),
    {Rotation = 395})
borderMotion:Play()
table.insert(titleTweens, borderMotion)
local borderPulse = TweenService:Create(border,
    TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    {Thickness = 3.4, Transparency = 0.15})
borderPulse:Play()
table.insert(titleTweens, borderPulse)
local outerGlowStroke = underGlow:FindFirstChildOfClass("UIStroke")
if outerGlowStroke then
    local outerPulse = TweenService:Create(outerGlowStroke,
        TweenInfo.new(2.3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Thickness = 12, Transparency = 0.65})
    outerPulse:Play()
    table.insert(titleTweens, outerPulse)
end
el("UIGradient", {
    Rotation = 90,
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.black),
        ColorSequenceKeypoint.new(0.55, C.background),
        ColorSequenceKeypoint.new(1, C.black)
    })
}, panel)

-- Escala para manter o painel utilizavel em janelas menores.
local scale = el("UIScale", {Scale = 1}, panel)
local function fitScreen()
    local cam = workspace.CurrentCamera
    if not cam then return end
    local view = cam.ViewportSize
    if view.X < 920 then
        scale.Scale = math.clamp(math.min((view.X - 30) / PANEL_W,
            (view.Y - 34) / PANEL_H), 0.43, 1)
        panel.Position = UDim2.new(0, 12, 0.5, 0)
    else
        scale.Scale = math.clamp(math.min((view.X - 310) / PANEL_W,
            (view.Y - 36) / PANEL_H), 0.56, 1)
        panel.Position = UDim2.new(0, 18, 0.5, 0)
    end
    underGlow.Position = panel.Position
    underGlow.Size = UDim2.fromOffset(PANEL_W*scale.Scale + 6, PANEL_H*scale.Scale + 6)
end
fitScreen()
if workspace.CurrentCamera then
    listen(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), fitScreen)
end

-- ======================================================================
-- V1.7 | EFEITOS REAIS (NAO SAO APENAS PARTE DA ARTE DO LOGOTIPO)
-- Luzes em movimento, faiscas, arco eletrico e sweep de brilho do cabecalho.
-- Os elementos sao leves, limitados ao topo e desligam com o menu.
-- ======================================================================
local rng = Random.new()
local fxLayer = el("Frame", {
    Name = "ElectricEffects", Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(PANEL_W, 106),
    BackgroundTransparency = 1, ClipsDescendants = true, ZIndex = 6
}, panel)

local function sparkParticle()
    if not alive or not fxLayer.Parent then return end
    local x = rng:NextInteger(9, PANEL_W - 13)
    local y = rng:NextInteger(12, 102)
    local diameter = rng:NextInteger(2, 5)
    local shade = rng:NextInteger(1, 5) == 1 and C.white or C.cyan
    local glow = el("Frame", {
        Name = "Spark", Size = UDim2.fromOffset(diameter + 4, diameter + 4),
        Position = UDim2.fromOffset(x, y),
        BackgroundColor3 = shade, BackgroundTransparency = 0.58,
        BorderSizePixel = 0, ZIndex = 8
    }, fxLayer)
    rounded(glow, 50)
    local luminousCenter = el("Frame", {
        Size = UDim2.fromOffset(diameter, diameter),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundColor3 = C.white, BackgroundTransparency = 0.05,
        BorderSizePixel = 0
    }, glow)
    rounded(luminousCenter, 50)
    local duration = rng:NextNumber(0.85, 1.55)
    local fly = TweenService:Create(glow,
        TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            Position = UDim2.fromOffset(x + rng:NextInteger(-18, 22), y - rng:NextInteger(22, 55)),
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(1, 1)
        })
    local fade = TweenService:Create(luminousCenter,
        TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            BackgroundTransparency = 1
        })
    fly:Play()
    fade:Play()
    task.delay(duration + 0.05, function()
        if glow.Parent then glow:Destroy() end
    end)
end

-- Mantem cerca de 10 a 15 faíscas na interface, sem usar RenderStepped.
task.spawn(function()
    while alive and fxLayer.Parent do
        sparkParticle()
        task.wait(0.11)
    end
end)

local function boltSegment(parent, x1, y1, x2, y2, thickness, shade)
    local dx, dy = x2 - x1, y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    local seg = el("Frame", {
        Name = "ElectricArc", AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.fromOffset(x1, y1),
        Size = UDim2.fromOffset(length, thickness),
        Rotation = math.deg(math.atan2(dy, dx)),
        BackgroundColor3 = shade, BorderSizePixel = 0,
        BackgroundTransparency = 0.04
    }, parent)
    return seg
end

local function flashLightning()
    if not alive or not fxLayer.Parent then return end
    local branch = el("Frame", {
        Name = "Lightning", BackgroundTransparency = 1,
        Size = UDim2.fromOffset(PANEL_W, 107), ZIndex = 8
    }, fxLayer)
    local x = rng:NextInteger(1, 2) == 1 and rng:NextInteger(20, 85)
        or rng:NextInteger(555, 710)
    local y = rng:NextInteger(3, 22)
    for _ = 1, 5 do
        local nextX = math.clamp(x + rng:NextInteger(-18, 25), 4, PANEL_W - 4)
        local nextY = y + rng:NextInteger(9, 16)
        boltSegment(branch, x, y, nextX, nextY, 4, C.blue)
        boltSegment(branch, x, y, nextX, nextY, 1.8, C.white)
        x, y = nextX, nextY
    end
    task.delay(0.13, function()
        if branch.Parent then branch:Destroy() end
    end)
end

task.spawn(function()
    while alive and fxLayer.Parent do
        task.wait(rng:NextNumber(1.2, 2.6))
        flashLightning()
    end
end)

-- Reflexo azul atravessando o separador horizontal.
local movingShine = el("Frame", {
    Name = "ShineStrip", Position = UDim2.fromOffset(-95, 104),
    Size = UDim2.fromOffset(92, 2), BorderSizePixel = 0,
    BackgroundColor3 = C.cyan, BackgroundTransparency = 0.15,
    ZIndex = 2
}, fxLayer)
local shiny = TweenService:Create(movingShine,
    TweenInfo.new(2.4, Enum.EasingStyle.Quad,
        Enum.EasingDirection.InOut, -1),
    {Position = UDim2.fromOffset(PANEL_W + 20, 104)})
shiny:Play()
table.insert(titleTweens, shiny)

-- CABECALHO: logo opcional da arte aprovada ou tipografia nativa estilizada.
local titleArea = el("Frame", {
    Position = UDim2.fromOffset(23, 7), Size = UDim2.fromOffset(455, 90),
    BackgroundTransparency = 1, Active = true
}, panel)
local hasLogoImage = type(LOGO_IMAGE_ID) == "string" and LOGO_IMAGE_ID:match("%d+") ~= nil
local logoImage
if hasLogoImage then
    logoImage = el("ImageLabel", {
        Name = "DanXysLogo", BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, -1), Size = UDim2.fromOffset(440, 105),
        Image = LOGO_IMAGE_ID, ScaleType = Enum.ScaleType.Fit
    }, titleArea)
    local logoTween = TweenService:Create(logoImage,
        TweenInfo.new(2.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Position = UDim2.fromOffset(0, -5)})
    logoTween:Play()
    table.insert(titleTweens, logoTween)
    -- Brilho diagonal que passa sobre a imagem importada.
    local shimmer = el("Frame", {
        Name = "TitleShimmer", Position = UDim2.fromOffset(-75, 8),
        Size = UDim2.fromOffset(35, 76),
        BackgroundColor3 = Color3.fromRGB(165, 234, 255),
        BackgroundTransparency = 0.84, BorderSizePixel = 0,
        Rotation = 17, ZIndex = 5
    }, titleArea)
    local shimmerFade = el("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.22),
            NumberSequenceKeypoint.new(1, 1)
        })
    }, shimmer)
    local shimmerTween = TweenService:Create(shimmer,
        TweenInfo.new(3.1, Enum.EasingStyle.Sine,
            Enum.EasingDirection.InOut, -1),
        {Position = UDim2.fromOffset(510, 8)})
    shimmerTween:Play()
    table.insert(titleTweens, shimmerTween)
else
    -- O desenho nativo aproxima o estilo, mas a arte fornecida fica mais fiel.
    local cursor = 0
    for i = 1, #"DANXYS" do
        local letter = ("DANXYS"):sub(i, i)
        local width = TextService:GetTextSize(letter, 51, Enum.Font.GothamBlack,
            Vector2.new(100, 70)).X + 4
        local shadow = text(titleArea, letter, UDim2.fromOffset(cursor+2, 2),
            UDim2.fromOffset(width + 2, 62), 51, C.blue, true)
        shadow.Font = Enum.Font.GothamBlack
        shadow.TextTransparency = 0.25
        shadow.TextStrokeColor3 = C.blue
        shadow.TextStrokeTransparency = 0.3
        local letterObj = text(titleArea, letter, UDim2.fromOffset(cursor, -1),
            UDim2.fromOffset(width + 2, 62), 51, C.white, true)
        letterObj.Font = Enum.Font.GothamBlack
        letterObj.TextStrokeColor3 = C.cyan
        letterObj.TextStrokeTransparency = 0.10
        el("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
                ColorSequenceKeypoint.new(0.52, Color3.fromRGB(227, 242, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 118, 255))
            })
        }, letterObj)
        local floatTween = TweenService:Create(letterObj,
            TweenInfo.new(1.2 + i * 0.05, Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut, -1, true, i * 0.045),
            {Position = UDim2.fromOffset(cursor, -4)})
        floatTween:Play()
        table.insert(titleTweens, floatTween)
        cursor = cursor + width
    end
    local subtitleGlow = text(titleArea, "ANTI TELA", UDim2.fromOffset(114, 56),
        UDim2.fromOffset(270, 36), 28, C.blue, true)
    subtitleGlow.Font = Enum.Font.GothamBlack
    subtitleGlow.TextStrokeTransparency = 0.2
    subtitleGlow.TextStrokeColor3 = C.blue
    local subtitle = text(titleArea, "ANTI TELA", UDim2.fromOffset(112, 54),
        UDim2.fromOffset(270, 36), 28, C.cyan, true)
    subtitle.Font = Enum.Font.GothamBlack
    subtitle.TextStrokeColor3 = C.blue
    subtitle.TextStrokeTransparency = 0.06
    el("UIGradient", {
        Rotation = 90,
        Color = ColorSequence.new(C.white, C.cyan)
    }, subtitle)
end
local version = text(panel, "v1.7  /  SERVER MONITOR", UDim2.fromOffset(490, 47),
    UDim2.fromOffset(193, 25), 13, C.cyan, true)
version.Font = Enum.Font.GothamBlack
local minimize = button(panel, "—", 669, 15, 30, 29, C.blue)
local close = button(panel, "✕", 708, 15, 30, 29, C.red)
close.TextColor3 = C.red
local line = el("Frame", {
    Position = UDim2.fromOffset(17, 105), Size = UDim2.fromOffset(720, 3),
    BackgroundColor3 = C.cyan, BorderSizePixel = 0
}, panel)
rounded(line, 2)
el("UIGradient", {Color = ColorSequence.new(C.cyan, C.deepBlue)}, line)

local pages, tabs = {}, {}
local tabNames = {"DASHBOARD", "PLAYERS", "SETTINGS", "HISTORY"}
for i, name in ipairs(tabNames) do
    tabs[name] = button(panel, name, 16 + (i-1)*181, 117, 174, 41, C.deepBlue)
    pages[name] = el("Frame", {
        Position = UDim2.fromOffset(0, 166),
        Size = UDim2.fromOffset(PANEL_W, 557),
        BackgroundTransparency = 1, Visible = false
    }, panel)
end
local currentTab = "DASHBOARD"
local function showTab(name)
    currentTab = name
    for tabName, page in pairs(pages) do
        local selected = tabName == name
        page.Visible = selected
        tabs[tabName].BackgroundColor3 = selected and C.deepBlue or C.button
        tabs[tabName]:SetAttribute("Selected", selected)
        tabs[tabName].TextColor3 = selected and C.white or C.muted
    end
end
for name, tabButton in pairs(tabs) do
    listen(tabButton.MouseButton1Click, function() showTab(name) end)
end

-- PAGINA DASHBOARD
local dashboard = pages.DASHBOARD
local serverCard = card(dashboard, 16, 4, 350, 139, "◎  SERVER STATUS")
local sensorLabel = text(serverCard, "SENSOR: ACTIVE", UDim2.fromOffset(15, 45),
    UDim2.fromOffset(275, 24), 16, C.green, true)
local serverLabel = text(serverCard, "SERVER TYPE: ...", UDim2.fromOffset(15, 77),
    UDim2.fromOffset(310, 22), 15, C.white, true)
text(serverCard, "SPECTATE: UNKNOWN", UDim2.fromOffset(15, 105),
    UDim2.fromOffset(310, 22), 15, C.yellow, true)
-- Decoracao estilo radar no cartao de status
local radar = el("Frame", {
    Position = UDim2.fromOffset(254, 35), Size = UDim2.fromOffset(81, 81),
    BackgroundTransparency = 1
}, serverCard)
for radius = 66, 26, -20 do
    local circle = el("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(radius, radius), BackgroundTransparency = 1
    }, radar)
    rounded(circle, 100)
    outline(circle, C.blue, 1, 0.3)
end
-- Ponteiro de radar girando de verdade.
local radarPivot = el("Frame", {
    Position = UDim2.fromOffset(0, 0),
    Size = UDim2.fromOffset(81, 81), BackgroundTransparency = 1
}, radar)
local radarArm = el("Frame", {
    Position = UDim2.fromOffset(40, 39), Size = UDim2.fromOffset(32, 2),
    BackgroundColor3 = C.cyan, BackgroundTransparency = 0.15,
    BorderSizePixel = 0
}, radarPivot)
local radarSpin = TweenService:Create(radarPivot,
    TweenInfo.new(3.8, Enum.EasingStyle.Linear,
        Enum.EasingDirection.InOut, -1), {Rotation = 360})
radarSpin:Play()
table.insert(titleTweens, radarSpin)
text(radar, "✦", UDim2.fromOffset(24, 21),
    UDim2.fromOffset(32, 31), 24, C.cyan, true)

local statsCard = card(dashboard, 379, 4, 359, 139, "♟  PLAYERS")
local playerCountLabel = text(statsCard, "0 / 0", UDim2.fromOffset(16, 37),
    UDim2.fromOffset(185, 48), 36, C.white, true)
playerCountLabel.Font = Enum.Font.GothamBlack
local entriesLabel = text(statsCard, "NEW ENTRIES: 0",
    UDim2.fromOffset(196, 55), UDim2.fromOffset(147, 25), 12, C.yellow, true)
local baselineStats = text(statsCard, "BASELINE: 0 PLAYERS",
    UDim2.fromOffset(16, 113), UDim2.fromOffset(320, 18), 12, C.cyan, true)
local track = el("Frame", {Position = UDim2.fromOffset(16, 102),
    Size = UDim2.fromOffset(318, 6), BackgroundColor3 = C.deepBlue,
    BorderSizePixel = 0}, statsCard)
rounded(track, 4)
local trackFill = el("Frame", {Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = C.cyan, BorderSizePixel = 0}, track)
rounded(trackFill, 4)

local eventCard = card(dashboard, 16, 156, 350, 117, "ϟ  LAST EVENTS")
local lastJoin = text(eventCard, "LAST JOIN: NONE", UDim2.fromOffset(15, 40),
    UDim2.fromOffset(298, 24), 13, C.green, true)
local lastLeave = text(eventCard, "LAST LEAVE: NONE", UDim2.fromOffset(15, 78),
    UDim2.fromOffset(321, 24), 13, C.red, true)
local extraCard = card(dashboard, 379, 156, 359, 117,
    "⚠  EXTRA PLAYER", C.red, C.red)
el("UIGradient", {
    Rotation = 0,
    Color = ColorSequence.new(Color3.fromRGB(25, 3, 14), C.black)
}, extraCard)
local extraHeading = text(extraCard, "NONE", UDim2.fromOffset(15, 39),
    UDim2.fromOffset(323, 32), 25, C.white, true)
local extraDetail = text(extraCard, "No additional players detected",
    UDim2.fromOffset(15, 81), UDim2.fromOffset(325, 22), 12, C.muted)

local modeCard = card(dashboard, 16, 286, 350, 117, "⚑  MATCH MODE")
local modeButtons = {}
for i, name in ipairs({"PUBLIC", "1v1", "2v2"}) do
    modeButtons[name] = button(modeCard, name, 13+(i-1)*111, 40, 102, 31, C.deepBlue)
end
local baselineBtn = button(modeCard, "SET BASELINE", 13, 82, 165, 28, C.cyan)
local baselineMode = text(modeCard, "BASELINE: 0", UDim2.fromOffset(190, 84),
    UDim2.fromOffset(146, 23), 11, C.cyan, true)

local quickCard = card(dashboard, 379, 286, 359, 117, "⚙  QUICK SETTINGS")
local notificationBtn = button(quickCard, "NOTIFICATIONS: ON", 13, 41, 331, 30, C.deepBlue)
local clearBtn = button(quickCard, "CLEAR HISTORY", 13, 79, 331, 30, C.deepBlue)
local miniHistoryCard = card(dashboard, 16, 416, 722, 139, "▤  SERVER HISTORY")
local miniTotal = text(miniHistoryCard, "TOTAL: 0", UDim2.fromOffset(600, 8),
    UDim2.fromOffset(104, 24), 11, C.muted, true)
local miniHistory = el("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 34), Size = UDim2.fromOffset(694, 96),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ScrollBarThickness = 3, ScrollBarImageColor3 = C.cyan,
    CanvasSize = UDim2.new()
}, miniHistoryCard)
local miniLayout = el("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 3)
}, miniHistory)

-- PAGINA PLAYERS
local playerPage = pages.PLAYERS
local rosterCard = card(playerPage, 16, 4, 722, 551, "♟  PLAYERS IN THIS SERVER")
local rosterSummary = text(rosterCard, "Loading...", UDim2.fromOffset(14, 38),
    UDim2.fromOffset(630, 22), 13, C.cyan, true)
local rosterScroll = el("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 75), Size = UDim2.fromOffset(698, 456),
    BackgroundColor3 = C.background, BorderSizePixel = 0,
    ScrollBarThickness = 4, ScrollBarImageColor3 = C.cyan,
    CanvasSize = UDim2.new()
}, rosterCard)
rounded(rosterScroll, 8)
local rosterLayout = el("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4)
}, rosterScroll)

-- PAGINA SETTINGS
local settingsPage = pages.SETTINGS
local settingsCard = card(settingsPage, 16, 4, 722, 230, "⚙  SENSOR SETTINGS")
text(settingsCard, "Modo de monitoramento", UDim2.fromOffset(17, 42),
    UDim2.fromOffset(600, 24), 14, C.white, true)
local settingModes = {}
for i, name in ipairs({"PUBLIC", "1v1", "2v2"}) do
    settingModes[name] = button(settingsCard, name, 17+(i-1)*211, 72, 198, 32, C.deepBlue)
end
local baselineSetting = button(settingsCard, "SET BASELINE (PARTICIPANTES ATUAIS)",
    17, 123, 634, 34, C.cyan)
local settingsBaselineLabel = text(settingsCard, "BASELINE: 0 PLAYERS",
    UDim2.fromOffset(19, 170), UDim2.fromOffset(600, 22), 13, C.muted, true)
local controlsCard = card(settingsPage, 16, 247, 722, 300, "◈  PREFERENCES")
local settingsNotify = button(controlsCard, "NOTIFICATIONS: ON", 17, 51, 305, 38, C.deepBlue)
local settingsClear = button(controlsCard, "CLEAR HISTORY", 337, 51, 310, 38, C.deepBlue)
text(controlsCard, "POP-UP: 1.5s  •  barra regressiva  •  canto superior direito",
    UDim2.fromOffset(17, 107), UDim2.fromOffset(622, 27), 13, C.cyan)
text(controlsCard, "O sensor registra contas visiveis no servidor; nao detecta camera/spectate.",
    UDim2.fromOffset(17, 143), UDim2.fromOffset(622, 41), 12, C.muted)

-- PAGINA HISTORY
local historyPage = pages.HISTORY
local historyCard = card(historyPage, 16, 4, 722, 551, "▤  COMPLETE SERVER HISTORY")
local historyCount = text(historyCard, "TOTAL EVENTS: 0", UDim2.fromOffset(14, 37),
    UDim2.fromOffset(550, 22), 13, C.cyan, true)
local historyScroll = el("ScrollingFrame", {
    Position = UDim2.fromOffset(12, 72), Size = UDim2.fromOffset(698, 406),
    BackgroundColor3 = C.background, BorderSizePixel = 0,
    ScrollBarThickness = 4, ScrollBarImageColor3 = C.cyan,
    CanvasSize = UDim2.new()
}, historyCard)
rounded(historyScroll, 8)
local historyLayout = el("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 5)
}, historyScroll)
local historyClear = button(historyCard, "CLEAR HISTORY", 15, 472, 638, 33, C.deepBlue)

-- CanvasSize baseado no conteudo; sem loop por frame.
local function autoCanvas(scroll, layout)
    listen(layout:GetPropertyChangedSignal("AbsoluteContentSize"), function()
        if alive then scroll.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 8) end
    end)
end
autoCanvas(miniHistory, miniLayout)
autoCanvas(rosterScroll, rosterLayout)
autoCanvas(historyScroll, historyLayout)

-- Estado do sensor
local selectedMode, expected = "PUBLIC", nil
local active = {}      -- [UserId] = Player
local baseline = {}    -- UserIds capturados quando SET BASELINE foi pressionado
local baselineSize = 0
local newEntries = 0
local notificationsOn = true
local historyItems = {}
local lastJoinName, lastLeaveName = "NONE", "NONE"

local function serverType()
    if game.PrivateServerId == "" then return "PUBLIC" end
    if game.PrivateServerOwnerId ~= 0 then return "PRIVATE" end
    return "RESERVED"
end
serverLabel.Text = "SERVER TYPE: " .. serverType()

local function activeList()
    local list = {}
    for _, player in pairs(active) do table.insert(list, player) end
    table.sort(list, function(a, b) return a.Name:lower() < b.Name:lower() end)
    return list
end
local function newcomersList()
    local list = {}
    for _, player in pairs(active) do
        if not baseline[player.UserId] then table.insert(list, player.Name) end
    end
    table.sort(list)
    return list
end
local function refreshRoster()
    if not alive then return end
    for _, item in ipairs(rosterScroll:GetChildren()) do
        if item:IsA("GuiObject") then item:Destroy() end
    end
    local list = activeList()
    rosterSummary.Text = string.format("%d jogadores online  •  Baseline: %d", #list, baselineSize)
    for i, player in ipairs(list) do
        local isNew = not baseline[player.UserId]
        local row = el("Frame", {
            LayoutOrder = i, Size = UDim2.new(1, -10, 0, 44),
            BackgroundColor3 = C.card, BorderSizePixel = 0
        }, rosterScroll)
        rounded(row, 6)
        text(row, player.Name, UDim2.fromOffset(12, 5),
            UDim2.fromOffset(370, 19), 13, isNew and C.yellow or C.white, true)
        text(row, "USER ID: " .. tostring(player.UserId), UDim2.fromOffset(12, 23),
            UDim2.fromOffset(395, 16), 10, C.muted)
        text(row, isNew and "NEW SINCE BASELINE" or "BASELINE",
            UDim2.new(1, -192, 0, 9), UDim2.fromOffset(180, 24),
            11, isNew and C.yellow or C.green, true)
    end
end

local function refreshStatus()
    if not alive then return end
    local total = #activeList()
    entriesLabel.Text = "NEW ENTRIES: " .. newEntries
    playerCountLabel.Text = selectedMode == "PUBLIC" and tostring(total)
        or string.format("%d / %d", total, expected)
    baselineStats.Text = "BASELINE: " .. baselineSize .. " PLAYERS"
    baselineMode.Text = "BASELINE: " .. baselineSize
    settingsBaselineLabel.Text = "BASELINE: " .. baselineSize .. " PLAYERS"
    lastJoin.Text = "LAST JOIN: " .. lastJoinName
    lastLeave.Text = "LAST LEAVE: " .. lastLeaveName

    if selectedMode == "PUBLIC" then
        sensorLabel.Text = "SENSOR: ACTIVE"
        sensorLabel.TextColor3 = C.green
        extraHeading.Text = "DISABLED"
        extraHeading.TextColor3 = C.muted
        extraDetail.Text = "Select 1v1 or 2v2 for limit alerts"
        extraDetail.TextColor3 = C.muted
        extraCard:FindFirstChildOfClass("UIStroke").Color = C.red
    else
        local new = newcomersList()
        if total > expected then
            sensorLabel.Text = "ALERT: " .. (total - expected) .. " ABOVE LIMIT"
            sensorLabel.TextColor3 = C.red
            extraHeading.Text = (total - expected) .. " ABOVE LIMIT"
            extraHeading.TextColor3 = C.red
            extraDetail.Text = #new > 0 and table.concat(new, ", ")
                or "Additional count; no new baseline ID"
            extraDetail.TextColor3 = C.red
            extraCard:FindFirstChildOfClass("UIStroke").Color = C.red
        elseif #new > 0 then
            sensorLabel.Text = "PLAYER LIST CHANGED"
            sensorLabel.TextColor3 = C.yellow
            extraHeading.Text = "NEW SINCE BASELINE"
            extraHeading.TextColor3 = C.yellow
            extraDetail.Text = table.concat(new, ", ")
            extraDetail.TextColor3 = C.yellow
            extraCard:FindFirstChildOfClass("UIStroke").Color = C.red
        else
            sensorLabel.Text = "SENSOR: ACTIVE"
            sensorLabel.TextColor3 = C.green
            extraHeading.Text = "NONE"
            extraHeading.TextColor3 = C.white
            extraDetail.Text = "No additional players detected"
            extraDetail.TextColor3 = C.muted
            extraCard:FindFirstChildOfClass("UIStroke").Color = C.red
        end
    end
    refreshRoster()
end

local function setMode(mode)
    selectedMode = mode
    expected = mode == "1v1" and 2 or mode == "2v2" and 4 or nil
    for _, group in ipairs({modeButtons, settingModes}) do
        for name, b in pairs(group) do
            b.BackgroundColor3 = name == mode and C.deepBlue or C.button
            b:SetAttribute("Selected", name == mode)
            b.TextColor3 = name == mode and C.white or C.muted
        end
    end
    refreshStatus()
end
for _, group in ipairs({modeButtons, settingModes}) do
    for name, b in pairs(group) do
        listen(b.MouseButton1Click, function() setMode(name) end)
    end
end
local function setBaseline()
    table.clear(baseline)
    local list = Players:GetPlayers()
    for _, player in ipairs(list) do
        active[player.UserId] = player
        baseline[player.UserId] = true
    end
    baselineSize = #list
    refreshStatus()
end
listen(baselineBtn.MouseButton1Click, setBaseline)
listen(baselineSetting.MouseButton1Click, setBaseline)

local function makeHistoryRow(parent, content, color, order, height)
    local row = text(parent, content, UDim2.new(),
        UDim2.new(1, -12, 0, height), height > 25 and 12 or 11, color, true)
    row.LayoutOrder = order
    return row
end
local function log(kind, player, extra)
    local stamp = os.date("%H:%M:%S")
    local message = (extra and "EXTRA ENTRY" or kind) .. ": " .. player.Name
        .. " [" .. player.UserId .. "]"
    local color = kind == "LEAVE" and C.yellow or extra and C.red or C.green
    local record = {msg = stamp .. " | " .. message, color = color}
    table.insert(historyItems, record)
    local count = #historyItems
    record.mini = makeHistoryRow(miniHistory, record.msg, color, count, 20)
    record.full = makeHistoryRow(historyScroll, record.msg, color, count, 37)
    if #historyItems > 80 then
        local oldest = table.remove(historyItems, 1)
        oldest.mini:Destroy()
        oldest.full:Destroy()
    end
    miniTotal.Text = "TOTAL: " .. #historyItems
    historyCount.Text = "TOTAL EVENTS: " .. #historyItems
    task.defer(function()
        if not alive then return end
        miniHistory.CanvasPosition = Vector2.new(0,
            math.max(0, miniLayout.AbsoluteContentSize.Y - miniHistory.AbsoluteSize.Y))
        historyScroll.CanvasPosition = Vector2.new(0,
            math.max(0, historyLayout.AbsoluteContentSize.Y - historyScroll.AbsoluteSize.Y))
    end)
end
local function clearHistory()
    for _, record in ipairs(historyItems) do
        record.mini:Destroy()
        record.full:Destroy()
    end
    table.clear(historyItems)
    miniTotal.Text = "TOTAL: 0"
    historyCount.Text = "TOTAL EVENTS: 0"
end
for _, b in ipairs({clearBtn, settingsClear, historyClear}) do
    listen(b.MouseButton1Click, clearHistory)
end

-- POP-UPS TOP RIGHT: 226 x 54, barra regressiva real por TweenService.
local toastRoot = el("Frame", {
    Name = "PopupStack", AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -16, 0, 30),
    Size = UDim2.fromOffset(226, 166), BackgroundTransparency = 1,
    ClipsDescendants = false
}, gui)
el("UIListLayout", {
    Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder
}, toastRoot)
local toasts = {}
local POPUP_TIME = 1.5
local function notify(title, details, color)
    if not alive or not notificationsOn then return end
    local holder = el("Frame", {
        Size = UDim2.fromOffset(226, 54), BackgroundTransparency = 1
    }, toastRoot)
    local box = el("Frame", {
        Position = UDim2.fromOffset(246, 0),
        Size = UDim2.fromOffset(226, 52),
        BackgroundColor3 = C.black, BorderSizePixel = 0
    }, holder)
    rounded(box, 9)
    outline(box, color, 1.6)
    el("UIGradient", {
        Rotation = 0,
        Color = ColorSequence.new(C.black, Color3.fromRGB(8, 18, 30))
    }, box)
    local side = el("Frame", {
        Position = UDim2.fromOffset(0, 7), Size = UDim2.fromOffset(3, 32),
        BackgroundColor3 = color, BorderSizePixel = 0
    }, box)
    rounded(side, 2)
    local head = text(box, title, UDim2.fromOffset(12, 4),
        UDim2.fromOffset(207, 17), 11, color, true)
    head.Font = Enum.Font.GothamBlack
    local detail = text(box, details, UDim2.fromOffset(12, 23),
        UDim2.fromOffset(204, 16), 10, C.white)
    local progressTrack = el("Frame", {
        Position = UDim2.fromOffset(10, 44), Size = UDim2.fromOffset(177, 4),
        BackgroundColor3 = Color3.fromRGB(17, 39, 59), BorderSizePixel = 0
    }, box)
    rounded(progressTrack, 4)
    local progress = el("Frame", {
        Size = UDim2.fromScale(1, 1), BackgroundColor3 = color,
        BorderSizePixel = 0
    }, progressTrack)
    rounded(progress, 4)
    local seconds = text(box, "1.5s", UDim2.fromOffset(190, 39),
        UDim2.fromOffset(34, 13), 10, C.white, true)
    table.insert(toasts, holder)
    if #toasts > 2 then
        local oldest = table.remove(toasts, 1)
        if oldest then oldest:Destroy() end
    end
    tween(box, 0.12, {Position = UDim2.fromOffset(0, 0)})
    tween(progress, POPUP_TIME, {Size = UDim2.fromScale(0, 1)}, Enum.EasingStyle.Linear)
    task.spawn(function()
        local started = os.clock()
        while alive and holder.Parent and os.clock()-started < POPUP_TIME do
            local remain = math.max(0, POPUP_TIME - (os.clock()-started))
            seconds.Text = string.format("%.1fs", remain)
            task.wait(0.08)
        end
    end)
    task.delay(POPUP_TIME, function()
        if not alive or not holder.Parent then return end
        local exitTween = tween(box, 0.14, {Position = UDim2.fromOffset(246, 0)})
        exitTween.Completed:Wait()
        local index = table.find(toasts, holder)
        if index then table.remove(toasts, index) end
        if holder.Parent then holder:Destroy() end
    end)
end
local function flipNotifications()
    notificationsOn = not notificationsOn
    local content = notificationsOn and "NOTIFICATIONS: ON" or "NOTIFICATIONS: OFF"
    notificationBtn.Text = content
    settingsNotify.Text = content
    notificationBtn.TextColor3 = notificationsOn and C.green or C.red
    settingsNotify.TextColor3 = notificationsOn and C.green or C.red
end
listen(notificationBtn.MouseButton1Click, flipNotifications)
listen(settingsNotify.MouseButton1Click, flipNotifications)

local minimized = false
listen(minimize.MouseButton1Click, function()
    minimized = not minimized
    panel.Size = minimized and UDim2.fromOffset(PANEL_W, 113)
        or UDim2.fromOffset(PANEL_W, PANEL_H)
    underGlow.Visible = not minimized
    minimize.Text = minimized and "+" or "—"
    for _, object in ipairs(panel:GetChildren()) do
        if object:IsA("GuiObject") and object ~= titleArea and object ~= minimize
            and object ~= close and object ~= line and object ~= version then
            object.Visible = not minimized
        end
    end
    -- Ao expandir, preservar apenas a aba que estava selecionada.
    if not minimized then showTab(currentTab) end
end)

-- Arrastar segurando o cabecalho.
local dragging = false
local dragStart, originalPosition
listen(titleArea.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        originalPosition = panel.Position
    end
end)
listen(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
listen(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(originalPosition.X.Scale,
            originalPosition.X.Offset + delta.X,
            originalPosition.Y.Scale, originalPosition.Y.Offset + delta.Y)
        underGlow.Position = panel.Position
    end
end)

local function cleanup()
    if not alive then return end
    alive = false
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, t in ipairs(titleTweens) do pcall(function() t:Cancel() end) end
    gui:Destroy()
end
_G.DanXysCleanup = cleanup
listen(close.MouseButton1Click, cleanup)

-- Snapshot inicial + eventos. O sensor escuta apenas jogadores replicados.
for _, player in ipairs(Players:GetPlayers()) do
    active[player.UserId] = player
    baseline[player.UserId] = true
end
baselineSize = #Players:GetPlayers()
listen(Players.PlayerAdded, function(player)
    if not alive or active[player.UserId] then return end
    active[player.UserId] = player
    newEntries = newEntries + 1
    lastJoinName = player.Name
    local isExtra = expected ~= nil and #activeList() > expected
    log("JOIN", player, isExtra)
    if isExtra then
        notify("EXTRA PLAYER", player.Name .. " joined above the limit", C.red)
    else
        notify("NEW PLAYER", player.Name .. " joined the server", C.green)
    end
    refreshStatus()
end)
listen(Players.PlayerRemoving, function(player)
    if not alive then return end
    active[player.UserId] = nil
    lastLeaveName = player.Name
    log("LEAVE", player, false)
    notify("PLAYER LEFT", player.Name .. " disconnected", C.yellow)
    refreshStatus()
end)

setMode("PUBLIC")
showTab("DASHBOARD")
refreshStatus()
notify("DANXYS ANTI TELA", "Server Monitor v1.7 ativo", C.cyan)
print("[DanXys Anti Tela v1.7] Sensor active | Server:", serverType())
print("[DanXys] Spectate: UNKNOWN (not observable via Players)")
