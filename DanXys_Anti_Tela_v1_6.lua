--[[
    DanXys Anti Tela v2.0 | Aim Lab + Full-Panel Particles + Circular Radar + Neon UI
    Interface Luau client-side. Usa apenas Players e propriedades publicas.
    Nao identifica espectadores invisiveis nem ferramentas administrativas.
    Pop-ups 1.5s + hitbox visual + canto e recepcao estimados (guias locais).
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
local particleSurfaces = {} -- camadas criadas primeiro; conteúdo desenhado por cima
local minimizedFX = false

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
    -- Uma camada interna de partículas é inserida antes de textos e botões.
    -- Assim, as faíscas ficam no fundo preto de cada cartão.
    local cardFX = el("Frame", {
        Name = "DanXysCardParticles",
        Position = UDim2.fromOffset(6, 6),
        Size = UDim2.fromOffset(w - 12, h - 12),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        BorderSizePixel = 0,
        ZIndex = 1
    }, f)
    table.insert(particleSurfaces, {
        layer = cardFX,
        width = w - 12,
        height = h - 12,
        holder = parent
    })
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

-- PARTÍCULAS DE FUNDO (primeira camada; os controles aparecem na frente)
local fullPanelFX = el("Frame", {
    Name = "FullPanelParticles",
    Position = UDim2.fromOffset(8, 8),
    Size = UDim2.fromOffset(PANEL_W - 16, PANEL_H - 16),
    BackgroundTransparency = 1,
    ClipsDescendants = true,
    BorderSizePixel = 0,
    ZIndex = 1
}, panel)
table.insert(particleSurfaces, {
    layer = fullPanelFX,
    width = PANEL_W - 16,
    height = PANEL_H - 16,
    holder = panel
})

-- ======================================================================
-- V1.8 | EFEITOS REAIS (NAO SAO APENAS PARTE DA ARTE DO LOGOTIPO)
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

-- Cabeçalho: pequenas faíscas extras, em paralelo à camada geral.
task.spawn(function()
    while alive and fxLayer.Parent do
        sparkParticle()
        task.wait(0.28)
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
local version = text(panel, "v2.0  /  AIM LAB", UDim2.fromOffset(490, 47),
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
local tabNames = {"DASHBOARD", "PLAYERS", "AIM", "SETTINGS", "HISTORY"}
for i, name in ipairs(tabNames) do
    tabs[name] = button(panel, name, 16 + (i-1)*146, 117, 138, 41, C.deepBlue)
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
local spectateLabel = text(serverCard, "SPECTATE: UNKNOWN", UDim2.fromOffset(15, 105),
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
-- Substitui o caractere ✦ (que aparecia como quadradinho no Mac)
-- por duas formas circulares reais. O miolo é independente da haste.
local radarHalo = el("Frame", {
    Name = "RadarHalo", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(18, 18),
    BackgroundColor3 = C.blue,
    BackgroundTransparency = 0.80,
    BorderSizePixel = 0, ZIndex = 6
}, radar)
el("UICorner", {CornerRadius = UDim.new(1, 0)}, radarHalo)
local radarDot = el("Frame", {
    Name = "RadarDot", AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(7, 7),
    BackgroundColor3 = C.cyan, BackgroundTransparency = 0,
    BorderSizePixel = 0, ZIndex = 7
}, radar)
el("UICorner", {CornerRadius = UDim.new(1, 0)}, radarDot)
local dotPulse = TweenService:Create(radarHalo,
    TweenInfo.new(1.15, Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut, -1, true),
    {Size = UDim2.fromOffset(24, 24), BackgroundTransparency = 0.91})
dotPulse:Play()
table.insert(titleTweens, dotPulse)

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

-- ======================================================================
-- V1.8 | PARTÍCULAS POR TODO O MENU, ATRÁS DAS INFORMAÇÕES
-- - 1 agendador de baixa frequência (não usa RenderStepped)
-- - partículas limitadas em cada cartão e no espaço entre cartões
-- - nunca cobre os textos ou botões
-- - desativadas quando o painel está minimizado
-- ======================================================================
local fxRandom = Random.new()
local MAX_ACTIVE_PARTICLES = 24
local liveParticleCount = 0
local surfaceCursor = 0

local function ancestorsVisible(layer)
    if minimizedFX or not layer or not layer.Parent then return false end
    local current = layer
    while current and current ~= gui do
        if current:IsA("GuiObject") and not current.Visible then
            return false
        end
        current = current.Parent
    end
    return true
end

local function fireBackgroundParticle(surface)
    if not alive or liveParticleCount >= MAX_ACTIVE_PARTICLES then return end
    if not ancestorsVisible(surface.layer) then return end

    local w, h = surface.width, surface.height
    local sx = fxRandom:NextInteger(9, math.max(10, w - 10))
    local sy = fxRandom:NextInteger(10, math.max(11, h - 10))
    local size = fxRandom:NextInteger(2, 4)
    local color = fxRandom:NextInteger(1, 5) == 1 and C.white or C.cyan
    local flight = fxRandom:NextNumber(1.3, 2.2)
    local driftX = fxRandom:NextInteger(-36, 36)
    local driftY = fxRandom:NextInteger(-36, -10)

    -- Halo suave, com um ponto central. Ambos atrás do conteúdo do cartão.
    local glow = el("Frame", {
        Name = "BackgroundSpark",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromOffset(sx, sy),
        Size = UDim2.fromOffset(size + 9, size + 9),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.88,
        BorderSizePixel = 0, ZIndex = 1
    }, surface.layer)
    el("UICorner", {CornerRadius = UDim.new(1, 0)}, glow)
    local dot = el("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = color,
        BackgroundTransparency = 0.18,
        BorderSizePixel = 0, ZIndex = 1
    }, glow)
    el("UICorner", {CornerRadius = UDim.new(1, 0)}, dot)
    liveParticleCount = liveParticleCount + 1

    local drift = TweenService:Create(glow,
        TweenInfo.new(flight, Enum.EasingStyle.Sine,
            Enum.EasingDirection.Out), {
            Position = UDim2.fromOffset(sx + driftX, sy + driftY),
            BackgroundTransparency = 1,
            Size = UDim2.fromOffset(2, 2)
        })
    local fadeDot = TweenService:Create(dot,
        TweenInfo.new(flight, Enum.EasingStyle.Linear), {
            BackgroundTransparency = 1
        })
    drift:Play()
    fadeDot:Play()
    task.delay(flight + 0.06, function()
        if glow.Parent then glow:Destroy() end
        liveParticleCount = math.max(0, liveParticleCount - 1)
    end)
end

-- Distribuição round-robin entre cartões visíveis + plano de fundo.
-- A tela atual recebe todos os efeitos; abas ocultas ficam suspensas.
task.spawn(function()
    while alive and gui.Parent do
        if not minimizedFX then
            local shown = {}
            for _, surface in ipairs(particleSurfaces) do
                if ancestorsVisible(surface.layer) then
                    table.insert(shown, surface)
                end
            end
            if #shown > 0 then
                surfaceCursor = (surfaceCursor % #shown) + 1
                fireBackgroundParticle(shown[surfaceCursor])
            end
        end
        task.wait(0.09)
    end
end)

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
    -- Risco indireto: conta adicional e visivel, NAO prova observacao.
    if expected and total > expected then
        spectateLabel.Text = "SPECTATE: CONTA EXTRA (NAO PROVA)"
        spectateLabel.TextColor3 = C.red
    else
        spectateLabel.Text = "SPECTATE: UNKNOWN"
        spectateLabel.TextColor3 = C.yellow
    end

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
local NORMAL_TITLE_POS = UDim2.fromOffset(23, 7)
local NORMAL_TITLE_SIZE = UDim2.fromOffset(455, 90)
local NORMAL_LOGO_SIZE = UDim2.fromOffset(440, 105)
local NORMAL_MIN_POS = UDim2.fromOffset(669, 15)
local NORMAL_CLOSE_POS = UDim2.fromOffset(708, 15)
listen(minimize.MouseButton1Click, function()
    minimized = not minimized
    minimizedFX = minimized
    panel.ClipsDescendants = minimized
    panel.Size = minimized and UDim2.fromOffset(120, 32)
        or UDim2.fromOffset(PANEL_W, PANEL_H)
    underGlow.Visible = not minimized
    minimize.Text = minimized and "+" or "—"
    titleArea.Position = minimized and UDim2.fromOffset(2, 1) or NORMAL_TITLE_POS
    titleArea.Size = minimized and UDim2.fromOffset(78, 30) or NORMAL_TITLE_SIZE
    titleArea.ClipsDescendants = minimized
    if logoImage then
        logoImage.Size = minimized and UDim2.fromOffset(76, 30) or NORMAL_LOGO_SIZE
    end
    minimize.Position = minimized and UDim2.fromOffset(81, 5) or NORMAL_MIN_POS
    close.Position = minimized and UDim2.fromOffset(102, 5) or NORMAL_CLOSE_POS
    minimize.Size = minimized and UDim2.fromOffset(17, 22) or UDim2.fromOffset(30, 29)
    close.Size = minimized and UDim2.fromOffset(16, 22) or UDim2.fromOffset(30, 29)
    minimize.TextSize = minimized and 12 or 13
    close.TextSize = minimized and 12 or 13
    for _, object in ipairs(panel:GetChildren()) do
        if object:IsA("GuiObject") and object ~= titleArea and object ~= minimize
            and object ~= close then
            object.Visible = not minimized
        end
    end
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


-- ================================================================
-- v1.9: AUXILIOS VISUAIS LOCAIS - nao mudam hitboxes do servidor,
-- forca do saque, recepcao ou direcao real das jogadas.
-- ================================================================
local visualFolder = Instance.new("Folder")
visualFolder.Name = "DanXys_VisualAssist"
local oldVisual = workspace:FindFirstChild(visualFolder.Name)
if oldVisual then oldVisual:Destroy() end
visualFolder.Parent = workspace

local assist = {
    boxes = false,
    corners = false,
    landing = false
}
local hitboxAdornments = {}
local courtMarks = {}
local landingMarker
local ballPart
local lastBallSearch = -math.huge
local lastCourtSearch = -math.huge
local courtCF, courtSZ, groundY

local hitboxBtn = button(controlsCard, "HITBOX VISUAL: OFF", 17, 200, 205, 34, C.deepBlue)
local cornerBtn = button(controlsCard, "CORNERS: OFF", 234, 200, 196, 34, C.deepBlue)
local landingBtn = button(controlsCard, "RECEPTION: OFF", 442, 200, 205, 34, C.deepBlue)
local assistInfo = text(controlsCard,
    "Guias visuais. Sem alterar colisao, golpes ou recepcao do servidor.",
    UDim2.fromOffset(18, 245), UDim2.fromOffset(665, 32), 12, C.muted)

local function paintButton(b, enabled, label)
    b.Text = label .. (enabled and ": ON" or ": OFF")
    b.BackgroundColor3 = enabled and C.deepBlue or C.button
    b.TextColor3 = enabled and C.green or C.white
end

local function findCourt()
    local map = workspace:FindFirstChild("Map")
    local obj = map and map:FindFirstChild("Court", true)
    if not obj then return nil end
    if obj:IsA("BasePart") then
        return obj.CFrame, obj.Size
    elseif obj:IsA("Model") then
        return obj:GetBoundingBox()
    end
    return nil
end

local function clearCornerGuides()
    for _, part in ipairs(courtMarks) do
        if part.Parent then part:Destroy() end
    end
    table.clear(courtMarks)
end

local function makeCornerGuides()
    clearCornerGuides()
    courtCF, courtSZ = findCourt()
    if not courtCF then
        assistInfo.Text = "Quadra nao encontrada (Workspace.Map.Court)."
        return false
    end
    groundY = courtCF.Position.Y + courtSZ.Y/2
    for ix, xsign in ipairs({-1, 1}) do
        for iz, zsign in ipairs({-1, 1}) do
            local marker = Instance.new("Part")
            marker.Name = "DanXysCornerMarker"
            marker.Shape = Enum.PartType.Ball
            marker.Material = Enum.Material.Neon
            marker.Color = C.cyan
            marker.Transparency = 0.43
            marker.Size = Vector3.new(2, 0.35, 2)
            marker.Anchored = true
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            marker.CFrame = courtCF * CFrame.new(
                xsign * math.max(0, courtSZ.X/2-2.5),
                courtSZ.Y/2 + 0.35,
                zsign * math.max(0, courtSZ.Z/2-2.5))
            marker.Parent = visualFolder
            table.insert(courtMarks, marker)
        end
    end
    assistInfo.Text = "4 cantos do Workspace.Map.Court destacados (aproximacao)."
    return true
end

local function clearHitboxes()
    for _, ador in pairs(hitboxAdornments) do
        if ador.Parent then ador:Destroy() end
    end
    table.clear(hitboxAdornments)
end

local function updateHitboxes()
    if not assist.boxes then return end
    local seen = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= Players.LocalPlayer then
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            if root then
                seen[player.UserId] = true
                local adorn = hitboxAdornments[player.UserId]
                if not adorn or not adorn.Parent then
                    adorn = Instance.new("BoxHandleAdornment")
                    adorn.Name = "DanXysHitboxVisual"
                    adorn.Adornee = root
                    adorn.AlwaysOnTop = true
                    adorn.ZIndex = 3
                    adorn.Transparency = 0.77
                    adorn.Color3 = C.cyan
                    adorn.Parent = visualFolder
                    hitboxAdornments[player.UserId] = adorn
                end
                adorn.Adornee = root
                adorn.Size = Vector3.new(math.max(root.Size.X, 4),
                    math.max(root.Size.Y, 5), math.max(root.Size.Z, 4))
            end
        end
    end
    for id, adorn in pairs(hitboxAdornments) do
        if not seen[id] then
            adorn:Destroy()
            hitboxAdornments[id] = nil
        end
    end
end

local function isWorldBall(p)
    if not p or not p:IsA("BasePart") or not p:IsDescendantOf(workspace) then return false end
    if p.Anchored then return false end
    local model = p:FindFirstAncestorOfClass("Model")
    if model and model:FindFirstChildOfClass("Humanoid") then return false end
    return true
end

local function findBall()
    for _, model in ipairs(workspace:GetChildren()) do
        if model:IsA("Model") and model.Name:match("^CLIENT_BALL_%d+$") then
            local first = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
            if first then return first end
        end
    end
    for _, name in ipairs({"Ball", "Volleyball", "VolleyBall", "GameBall"}) do
        local obj = workspace:FindFirstChild(name, true)
        if obj and isWorldBall(obj) then return obj end
        if obj and obj:IsA("Model") then
            local part = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
            if isWorldBall(part) then return part end
        end
    end
    return nil
end

local function setLandingVisible(on)
    if not landingMarker then
        landingMarker = Instance.new("Part")
        landingMarker.Name = "DanXysReceptionForecast"
        landingMarker.Shape = Enum.PartType.Ball
        landingMarker.Anchored = true
        landingMarker.CanCollide = false
        landingMarker.CanTouch = false
        landingMarker.CanQuery = false
        landingMarker.Material = Enum.Material.Neon
        landingMarker.Size = Vector3.new(2.8, 0.28, 2.8)
        landingMarker.Color = C.yellow
        landingMarker.Transparency = 0.33
        landingMarker.Parent = visualFolder
    end
    landingMarker.Transparency = on and 0.33 or 1
end

local function updateLanding()
    if not assist.landing then return end
    if not ballPart or not isWorldBall(ballPart) then
        ballPart = nil
        if os.clock() - lastBallSearch >= 2 then
            lastBallSearch = os.clock()
            ballPart = findBall()
        end
    end
    if not ballPart then
        if landingMarker then setLandingVisible(false) end
        assistInfo.Text = "Bola nao identificada. Guia de recepcao indisponivel."
        return
    end
    if not courtCF and os.clock() - lastCourtSearch >= 3 then
        lastCourtSearch = os.clock()
        courtCF, courtSZ = findCourt()
    end
    if not courtCF then
        if landingMarker then setLandingVisible(false) end
        assistInfo.Text = "Quadra nao encontrada para calcular queda."
        return
    end
    groundY = courtCF.Position.Y + courtSZ.Y/2 + 0.3
    local p, v = ballPart.Position, ballPart.AssemblyLinearVelocity
    local h = p.Y-groundY
    local g = workspace.Gravity
    local disc = v.Y*v.Y + 2*g*h
    if h <= 0 or disc < 0 or g <= 0 then
        if landingMarker then setLandingVisible(false) end
        return
    end
    local t = (v.Y + math.sqrt(disc))/g
    if t <= 0 or t > 3.5 or v.Magnitude < 3 then
        if landingMarker then setLandingVisible(false) end
        return
    end
    -- Estimativa balistica: sem prever colisao com rede, spin ou scripts do jogo.
    local predicted = p + Vector3.new(v.X*t, 0, v.Z*t)
    setLandingVisible(true)
    landingMarker.Position = Vector3.new(predicted.X, groundY + 0.16, predicted.Z)
end

listen(hitboxBtn.MouseButton1Click, function()
    assist.boxes = not assist.boxes
    paintButton(hitboxBtn, assist.boxes, "HITBOX VISUAL")
    if not assist.boxes then clearHitboxes() else updateHitboxes() end
end)
listen(cornerBtn.MouseButton1Click, function()
    assist.corners = not assist.corners
    paintButton(cornerBtn, assist.corners, "CORNERS")
    if assist.corners then
        if not makeCornerGuides() then
            assist.corners = false
        end
    else
        clearCornerGuides()
    end
    paintButton(cornerBtn, assist.corners, "CORNERS")
end)
listen(landingBtn.MouseButton1Click, function()
    assist.landing = not assist.landing
    paintButton(landingBtn, assist.landing, "RECEPTION")
    if not assist.landing then setLandingVisible(false)
    else updateLanding() end
end)

-- Frequencia baixa, sem RenderStepped; monitor visual independente do sensor.
task.spawn(function()
    local tickCount = 0
    while alive and visualFolder.Parent do
        tickCount = tickCount+1
        if assist.boxes and tickCount % 4 == 0 then updateHitboxes() end
        if assist.landing then updateLanding() end
        if assist.corners and tickCount % 40 == 0 then
            -- Se a quadra mudou ao teletransportar, atualiza as marcacoes.
            makeCornerGuides()
        end
        task.wait(0.2)
    end
end)

local aimShutdown = (function()
-- =====================================================================
-- v2.0 | AIM LAB - reimplementacao a partir de analise estatica LOCOPANI
-- INTERCEPTA APENAS BallService.RF.Interact (Spike/ServeSpike), quando
-- executor disponibiliza hookmetamethod ou getrawmetatable/setreadonly.
-- Nao altera alcance/colisao no servidor nem garante acerto ou pontuacao.
-- =====================================================================
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local localPlayer = Players.LocalPlayer
local aim = {
    active = false,
    side = "Auto",
    depth = "Back",
    strength = 100,
    inset = 3,
    drop = 0.35,
    tiltSync = true,
    showTarget = true,
    receive = false,
    receiveRange = 20,
    maxServe = false,
    status = "OFF",
    spikeCalls = 0,
    aimedCalls = 0,
    serveCalls = 0,
    lastAim = "NONE",
    lastError = "",
    target = nil,
    lastPick = nil,
    lastPickTime = 0,
}

local aimLeft = card(pages.AIM, 16, 4, 350, 288, "◈  AUTO CORNER / AIMBOT")
local aimToggle = button(aimLeft, "AUTO CORNER: OFF", 15, 42, 316, 35, C.cyan)
local aimSide = button(aimLeft, "SIDE: AUTO", 15, 86, 151, 30, C.blue)
local aimDepth = button(aimLeft, "DEPTH: BACK", 179, 86, 151, 30, C.blue)
local aimMinus = button(aimLeft, "-", 15, 128, 43, 32, C.blue)
local aimStrengthLabel = text(aimLeft, "AIM STRENGTH: 100%", UDim2.fromOffset(63, 129),
    UDim2.fromOffset(216, 30), 14, C.cyan, true)
local aimPlus = button(aimLeft, "+", 290, 128, 40, 32, C.blue)
local dropButton = button(aimLeft, "DROP: 0.35", 15, 171, 151, 32, C.blue)
local insetButton = button(aimLeft, "MARGIN: 3.0", 179, 171, 151, 32, C.blue)
local tiltButton = button(aimLeft, "SYNC TILT: ON", 15, 215, 151, 32, C.deepBlue)
local targetButton = button(aimLeft, "TARGET DOT: ON", 179, 215, 151, 32, C.deepBlue)
text(aimLeft, "TECLA C: liga/desliga | potencia nao e garantida", 
    UDim2.fromOffset(14, 254), UDim2.fromOffset(323, 24), 10, C.muted)

local aimRight = card(pages.AIM, 379, 4, 359, 288, "◎  LIVE AIM DIAGNOSTICS")
local aimHookLabel = text(aimRight, "HOOK: NOT INITIALIZED", UDim2.fromOffset(16, 42),
    UDim2.fromOffset(326, 25), 13, C.yellow, true)
local aimRemoteLabel = text(aimRight, "BALL SERVICE: CHECKING", UDim2.fromOffset(16, 72),
    UDim2.fromOffset(324, 25), 12, C.yellow, true)
local aimTargetLabel = text(aimRight, "TARGET: NONE", UDim2.fromOffset(16, 106),
    UDim2.fromOffset(325, 25), 13, C.cyan, true)
local aimHitsLabel = text(aimRight, "SPIKE REQUESTS AIMED: 0", UDim2.fromOffset(16, 140),
    UDim2.fromOffset(320, 25), 12, C.white, true)
local aimServeLabel = text(aimRight, "SERVE REQUESTS EDITED: 0", UDim2.fromOffset(16, 171),
    UDim2.fromOffset(321, 25), 12, C.white, true)
local aimDetailLabel = text(aimRight, "Nenhum contato detectado", UDim2.fromOffset(16, 208),
    UDim2.fromOffset(320, 25), 12, C.muted)
local rescanAim = button(aimRight, "RECHECK GAME REMOTES", 16, 245, 322, 29, C.deepBlue)

local auxLeft = card(pages.AIM, 16, 308, 350, 242, "⚡  ACTION ASSISTS")
local receiveToggle = button(auxLeft, "AUTO RECEIVE (TEST): OFF", 15, 42, 317, 36, C.blue)
local receiveRangeBtn = button(auxLeft, "RECEIVE RADIUS: 20", 15, 90, 317, 34, C.deepBlue)
local serveToggle = button(auxLeft, "MAX SERVE REQUEST (TEST): OFF", 15, 138, 317, 34, C.blue)
text(auxLeft, "TEST: envio local nao prova aceite do servidor.",
    UDim2.fromOffset(15, 188), UDim2.fromOffset(317, 36), 11, C.muted)

local auxRight = card(pages.AIM, 379, 308, 359, 242, "▤  SOURCE / REALITY CHECK")
text(auxRight, "Auto Corner: alvo calculado pela quadra e defesa",
    UDim2.fromOffset(16, 44), UDim2.fromOffset(326, 32), 12, C.cyan)
text(auxRight, "Hitbox visual: nao muda colisao do servidor",
    UDim2.fromOffset(16, 90), UDim2.fromOffset(326, 32), 12, C.muted)
text(auxRight, "Auto Receive: acionamento client-side experimental",
    UDim2.fromOffset(16, 132), UDim2.fromOffset(326, 32), 12, C.muted)
text(auxRight, "Spectate: permanece UNKNOWN; sem alertas falsos",
    UDim2.fromOffset(16, 177), UDim2.fromOffset(326, 37), 12, C.yellow)

local aimMarker = Instance.new("Part")
aimMarker.Name = "DanXys_AimTarget"
aimMarker.Shape = Enum.PartType.Ball
aimMarker.Material = Enum.Material.Neon
aimMarker.Color = C.cyan
aimMarker.Size = Vector3.new(1.6, 0.22, 1.6)
aimMarker.Anchored = true
aimMarker.CanCollide = false
aimMarker.CanTouch = false
aimMarker.CanQuery = false
aimMarker.Transparency = 1
aimMarker.Parent = visualFolder

local interactRemote, serveRemote, receiveDoMove, receiveStopEmotes
local function resolveAimRemotes()
    local packages = RS:FindFirstChild("Packages")
    local idx = packages and packages:FindFirstChild("_Index")
    local knot = idx and idx:FindFirstChild("sleitnick_knit@1.7.0")
    local knit = knot and knot:FindFirstChild("knit")
    local services = knit and knit:FindFirstChild("Services")
    local ballService = services and services:FindFirstChild("BallService")
    local gameService = services and services:FindFirstChild("GameService")
    local animationService = services and services:FindFirstChild("AnimationService")
    local ballRF = ballService and ballService:FindFirstChild("RF")
    local ballRE = ballService and ballService:FindFirstChild("RE")
    local gameRF = gameService and gameService:FindFirstChild("RF")
    local animationRE = animationService and animationService:FindFirstChild("RE")
    interactRemote = ballRF and ballRF:FindFirstChild("Interact")
    serveRemote = gameRF and gameRF:FindFirstChild("Serve")
    receiveDoMove = ballRE and ballRE:FindFirstChild("DoMove")
    receiveStopEmotes = animationRE and animationRE:FindFirstChild("StopAllEmotes")
    aimRemoteLabel.Text = "BALL SERVICE: " .. (interactRemote and "FOUND" or "NOT FOUND")
    aimRemoteLabel.TextColor3 = interactRemote and C.green or C.yellow
    return interactRemote ~= nil
end

local function aimOrigin(root)
    local closest = nil
    local distance = 25
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and child.Name:match("^CLIENT_BALL_%d+$") then
            local part = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)
            if part then
                local d = (part.Position - root.Position).Magnitude
                if d < distance then
                    closest, distance = part, d
                end
            end
        end
    end
    return (closest and closest.Position) or root.Position
end

local function aimTarget()
    local character = localPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then return nil, "NO CHARACTER" end
    local cf, sz = findCourt()
    if not cf or not sz then return nil, "COURT NOT FOUND" end
    if sz.X < 4 or sz.Z < 4 then return nil, "INVALID COURT" end
    local r = cf:PointToObjectSpace(root.Position)
    local net = workspace:FindFirstChild("Map")
    net = net and net:FindFirstChild("BallCollideOnly")
    net = net and net:FindFirstChild("Net")
    local netZ = net and cf:PointToObjectSpace(net.Position).Z or 0
    local enemyDirection = (r.Z >= netZ) and -1 or 1
    local halfX = sz.X * 0.5
    local halfZ = sz.Z * 0.5
    local margin = math.min(aim.inset, halfX - 0.5, halfZ - 0.5)
    local xEdge = halfX - margin
    local zBack = enemyDirection * (halfZ - margin)
    local zNear = netZ + enemyDirection * (math.max(halfZ * 0.32, margin + 1))
    zNear = math.clamp(zNear, -halfZ + margin, halfZ - margin)
    local origin = aimOrigin(root)
    local originLocal = cf:PointToObjectSpace(origin)
    local opponents = {}
    for _, person in ipairs(Players:GetPlayers()) do
        if person ~= localPlayer and (not localPlayer.Team or person.Team ~= localPlayer.Team) then
            local oppChar = person.Character
            local oppRoot = oppChar and oppChar:FindFirstChild("HumanoidRootPart")
            local hum = oppChar and oppChar:FindFirstChildOfClass("Humanoid")
            if oppRoot and hum and hum.Health > 0 then
                local localPos = cf:PointToObjectSpace(oppRoot.Position)
                if (localPos.Z - netZ) * enemyDirection > 0 then
                    local velocity = cf:VectorToObjectSpace(oppRoot.AssemblyLinearVelocity)
                    table.insert(opponents, Vector2.new(localPos.X + velocity.X * 0.16,
                        localPos.Z + velocity.Z * 0.16))
                end
            end
        end
    end
    local cam = workspace.CurrentCamera
    local forward = cam and cam.CFrame.LookVector or root.CFrame.LookVector
    local flatForward = Vector3.new(forward.X, 0, forward.Z)
    if flatForward.Magnitude > 0.01 then flatForward = flatForward.Unit end

    local candidates = {}
    local function insert(side, depth, x, z)
        if aim.side ~= "Auto" and aim.side ~= side then return end
        if aim.depth ~= "All" and aim.depth ~= depth then return end
        local localPoint = Vector3.new(x, sz.Y * 0.5 + 0.2, z)
        local world = cf:PointToWorldSpace(localPoint)
        local closest = 40
        for _, opp in ipairs(opponents) do
            closest = math.min(closest, (opp - Vector2.new(x, z)).Magnitude)
        end
        local toward = Vector3.new(world.X - origin.X, 0, world.Z - origin.Z)
        local directionScore = toward.Magnitude > 0.01
            and math.max(-1, math.min(1, toward.Unit:Dot(flatForward))) or 0
        local score = closest + directionScore * 2.0 + (depth == "Back" and 1.4 or 0)
        local key = side .. " " .. depth
        if aim.lastPick == key and os.clock() - aim.lastPickTime < 0.65 then
            score = score + 1.8
        end
        table.insert(candidates, {key = key, world = world, score = score})
    end
    insert("Left", "Back", -xEdge, zBack)
    insert("Right", "Back", xEdge, zBack)
    insert("Left", "Nearest", -xEdge, zNear)
    insert("Right", "Nearest", xEdge, zNear)
    table.sort(candidates, function(a, b) return a.score > b.score end)
    local picked = candidates[1]
    if not picked then return nil, "NO CORNER AVAILABLE" end
    aim.lastPick = picked.key
    aim.lastPickTime = os.clock()
    local vec = Vector3.new(picked.world.X - origin.X, 0, picked.world.Z - origin.Z)
    if vec.Magnitude < 0.01 then return nil, "BAD AIM VECTOR" end
    return {position = picked.world, flat = vec.Unit, key = picked.key}, nil
end

-- Estado persistente para evitar empilhar metatable hooks se reexecutar.
local env = (type(getgenv) == "function" and getgenv()) or _G
local hookState = env.DanXys_AimHookV20
if type(hookState) ~= "table" then
    hookState = { installed = false, handler = nil }
    env.DanXys_AimHookV20 = hookState
end

local function modifyAimRequest(remote, method, ...)
    if not alive or method ~= "InvokeServer" then return nil end
    if remote == interactRemote and aim.active then
        local payload = ...
        if type(payload) == "table" and (payload.Move == "Spike" or payload.Move == "ServeSpike") then
            aim.spikeCalls = aim.spikeCalls + 1
            local chosen, problem = aimTarget()
            if chosen then
                local original = payload.LookVector
                if typeof(original) ~= "Vector3" or original.Magnitude < 0.01 then
                    local camera = workspace.CurrentCamera
                    original = camera and camera.CFrame.LookVector or chosen.flat
                end
                local origFlat = Vector3.new(original.X, 0, original.Z)
                if origFlat.Magnitude < 0.01 then origFlat = chosen.flat end
                local blend = math.clamp(aim.strength / 100, 0, 1)
                local direction = origFlat.Unit:Lerp(chosen.flat, blend)
                if direction.Magnitude < 0.01 then direction = chosen.flat end
                direction = direction.Unit
                local down = math.max(0.08, aim.drop)
                local shoot = Vector3.new(direction.X, -down, direction.Z).Unit
                local patched = table.clone(payload)
                patched.LookVector = shoot
                patched.Direction = shoot
                if aim.tiltSync and typeof(payload.TiltDirection) == "Vector3" then
                    local y = payload.TiltDirection.Y
                    patched.TiltDirection = Vector3.new(direction.X, y, direction.Z)
                end
                aim.target = chosen.position
                aim.lastAim = chosen.key
                aim.aimedCalls = aim.aimedCalls + 1
                return patched
            else
                aim.lastError = problem or "NO AIM"
            end
        end
    end
    if remote == serveRemote and aim.maxServe then
        local args = table.pack(...)
        if args.n >= 2 then
            args[2] = 5
            aim.serveCalls = aim.serveCalls + 1
            return args, true
        end
    end
    return nil
end
hookState.handler = modifyAimRequest

local function setupAimHook()
    resolveAimRemotes()
    if hookState.installed then
        aim.status = "HOOK READY"
        return true
    end
    if type(getnamecallmethod) ~= "function" then
        aim.status = "NO NAMECALL SUPPORT"
        return false
    end
    if type(hookmetamethod) == "function" then
        local original
        local fn = function(remote, ...)
            local method = getnamecallmethod()
            local handler = hookState.handler
            if handler then
                local updated, packed = handler(remote, method, ...)
                if packed and updated then
                    return original(remote, table.unpack(updated, 1, updated.n))
                elseif updated then
                    return original(remote, updated)
                end
            end
            return original(remote, ...)
        end
        local callable = (type(newcclosure) == "function") and newcclosure(fn) or fn
        local ok, prev = pcall(hookmetamethod, game, "__namecall", callable)
        if ok and type(prev) == "function" then
            original = prev
            hookState.installed = true
            aim.status = "HOOK READY"
            return true
        end
    end
    if type(getrawmetatable) == "function" and type(setreadonly) == "function" then
        local ok = pcall(function()
            local mt = getrawmetatable(game)
            local original = mt.__namecall
            setreadonly(mt, false)
            mt.__namecall = function(remote, ...)
                local method = getnamecallmethod()
                local handler = hookState.handler
                if handler then
                    local updated, packed = handler(remote, method, ...)
                    if packed and updated then
                        return original(remote, table.unpack(updated, 1, updated.n))
                    elseif updated then
                        return original(remote, updated)
                    end
                end
                return original(remote, ...)
            end
            setreadonly(mt, true)
        end)
        if ok then
            hookState.installed = true
            aim.status = "HOOK READY"
            return true
        end
    end
    aim.status = "NO HOOK SUPPORT"
    return false
end

local function refreshAimUI()
    local ready = hookState.installed and interactRemote ~= nil
    aimToggle.Text = "AUTO CORNER: " .. (aim.active and "ON" or "OFF")
    aimToggle.TextColor3 = aim.active and C.green or C.white
    aimSide.Text = "SIDE: " .. string.upper(aim.side)
    aimDepth.Text = "DEPTH: " .. string.upper(aim.depth)
    aimStrengthLabel.Text = "AIM STRENGTH: " .. tostring(aim.strength) .. "%"
    dropButton.Text = string.format("DROP: %.2f", aim.drop)
    insetButton.Text = string.format("MARGIN: %.1f", aim.inset)
    tiltButton.Text = "SYNC TILT: " .. (aim.tiltSync and "ON" or "OFF")
    targetButton.Text = "TARGET DOT: " .. (aim.showTarget and "ON" or "OFF")
    receiveToggle.Text = "AUTO RECEIVE (TEST): " .. (aim.receive and "ON" or "OFF")
    receiveRangeBtn.Text = "RECEIVE RADIUS: " .. tostring(aim.receiveRange)
    serveToggle.Text = "MAX SERVE REQUEST (TEST): " .. (aim.maxServe and "ON" or "OFF")
    aimHookLabel.Text = "HOOK: " .. aim.status
    aimHookLabel.TextColor3 = ready and C.green or C.yellow
    aimHitsLabel.Text = "SPIKE REQUESTS AIMED: " .. tostring(aim.aimedCalls)
    aimServeLabel.Text = "SERVE REQUESTS EDITED: " .. tostring(aim.serveCalls)
    aimTargetLabel.Text = "TARGET: " .. aim.lastAim
    aimDetailLabel.Text = (aim.lastError ~= "" and aim.lastError) or
        (aim.active and (ready and "Intercepcao habilitada; aguardando spike" or "Recurso indisponivel neste executor") or "Aim desligado")
end

listen(aimToggle.MouseButton1Click, function()
    if not aim.active then
        aim.active = setupAimHook() and interactRemote ~= nil
        if not aim.active then aim.lastError = "HOOK/REMOTES NOT AVAILABLE" else aim.lastError = "" end
    else
        aim.active = false
        aim.target = nil
    end
    refreshAimUI()
end)
listen(aimSide.MouseButton1Click, function()
    aim.side = (aim.side == "Auto" and "Left") or (aim.side == "Left" and "Right") or "Auto"
    refreshAimUI()
end)
listen(aimDepth.MouseButton1Click, function()
    aim.depth = (aim.depth == "Back" and "Nearest") or (aim.depth == "Nearest" and "All") or "Back"
    refreshAimUI()
end)
listen(aimMinus.MouseButton1Click, function()
    aim.strength = math.clamp(aim.strength - 10, 10, 100)
    refreshAimUI()
end)
listen(aimPlus.MouseButton1Click, function()
    aim.strength = math.clamp(aim.strength + 10, 10, 100)
    refreshAimUI()
end)
listen(dropButton.MouseButton1Click, function()
    aim.drop = aim.drop >= 0.55 and 0.15 or math.floor((aim.drop + 0.05) * 100 + 0.5) / 100
    refreshAimUI()
end)
listen(insetButton.MouseButton1Click, function()
    aim.inset = aim.inset >= 6 and 1.5 or aim.inset + 0.75
    refreshAimUI()
end)
listen(tiltButton.MouseButton1Click, function()
    aim.tiltSync = not aim.tiltSync
    refreshAimUI()
end)
listen(targetButton.MouseButton1Click, function()
    aim.showTarget = not aim.showTarget
    if not aim.showTarget then aimMarker.Transparency = 1 end
    refreshAimUI()
end)
listen(receiveToggle.MouseButton1Click, function()
    if not aim.receive and (type(firesignal) ~= "function" or not receiveDoMove) then
        resolveAimRemotes()
        if type(firesignal) ~= "function" or not receiveDoMove then
            aim.lastError = "AUTO RECEIVE REQUIRES firesignal + DoMove"
            refreshAimUI()
            return
        end
    end
    aim.receive = not aim.receive
    refreshAimUI()
end)
listen(receiveRangeBtn.MouseButton1Click, function()
    aim.receiveRange = aim.receiveRange >= 30 and 12 or aim.receiveRange + 3
    refreshAimUI()
end)
listen(serveToggle.MouseButton1Click, function()
    if not aim.maxServe then
        if not setupAimHook() or not serveRemote then
            aim.lastError = "SERVE REMOTE/HOOK UNAVAILABLE"
            refreshAimUI()
            return
        end
    end
    aim.maxServe = not aim.maxServe
    refreshAimUI()
end)
listen(rescanAim.MouseButton1Click, function()
    resolveAimRemotes()
    aim.status = hookState.installed and "HOOK READY" or "OFF"
    aim.lastError = ""
    refreshAimUI()
end)
listen(UserInputService.InputBegan, function(input, consumed)
    if consumed or UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.C then
        if not aim.active then
            aim.active = setupAimHook() and interactRemote ~= nil
            if not aim.active then aim.lastError = "HOOK/REMOTES UNAVAILABLE" end
        else
            aim.active = false
            aim.target = nil
        end
        refreshAimUI()
    end
end)

local lastAimDraw = 0
local lastReceiveTime = 0
listen(RunService.Heartbeat, function()
    if not alive then return end
    local now = os.clock()
    if now - lastAimDraw < 0.16 then return end
    lastAimDraw = now
    if aim.active and aim.showTarget then
        local targetData = aimTarget()
        if targetData then
            aim.target = targetData.position
            aimMarker.Position = aim.target + Vector3.new(0, 0.16, 0)
            aimMarker.Transparency = 0.18
        else
            aimMarker.Transparency = 1
        end
    else
        aimMarker.Transparency = 1
    end
    if aim.receive and now - lastReceiveTime >= 1.2 then
        local character = localPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0
            and humanoid.FloorMaterial ~= Enum.Material.Air
            and humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
            and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall then
            local nearest, best = nil, aim.receiveRange
            for _, child in ipairs(workspace:GetChildren()) do
                if child:IsA("Model") and child.Name:match("^CLIENT_BALL_%d+$") then
                    local part = child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart", true)
                    if part then
                        local d = (part.Position - root.Position).Magnitude
                        if d < best then
                            nearest, best = part, d
                        end
                    end
                end
            end
            if nearest and type(firesignal) == "function" and receiveDoMove then
                local ok = pcall(function()
                    firesignal(receiveDoMove.OnClientEvent, "Set", false, false)
                    if receiveStopEmotes then firesignal(receiveStopEmotes.OnClientEvent) end
                end)
                if ok then lastReceiveTime = now end
            end
        end
    end
end)

task.spawn(function()
    while alive do
        if pages.AIM.Visible then refreshAimUI() end
        task.wait(0.4)
    end
end)
resolveAimRemotes()
refreshAimUI()
return function()
    hookState.handler = nil
    aim.active = false
    aim.receive = false
    aim.maxServe = false
end
end)() -- AIM LAB em funcao propria para nao ultrapassar limite de locals

local function cleanup()
    if not alive then return end
    alive = false
    aimShutdown()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    for _, t in ipairs(titleTweens) do pcall(function() t:Cancel() end) end
    if visualFolder and visualFolder.Parent then visualFolder:Destroy() end
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
notify("DANXYS ANTI TELA", "v2.0 Aim Lab | Server Monitor", C.cyan)
print("[DanXys Anti Tela v2.0] Sensor active | Server:", serverType())
print("[DanXys] Spectate: UNKNOWN (not observable via Players)")
