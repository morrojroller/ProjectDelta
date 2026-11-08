-- // 06a_ui_library.luau
-- // Fabled UI library: window, tabs, sections, toggles, sliders,
-- // color pickers, keybind changers, textboxes and buttons.

local env = (getgenv and getgenv()) or _G
local PD = env.ProjectDelta
local userInputService = PD.userInputService
local workspace = PD.workspace

local TweenService = game:GetService("TweenService")

PD.UI = PD.UI or {}
local UI = PD.UI

UI.Controls = {}
UI.Syncers = {}
UI.Popups = {}
UI.Connections = {}

local Theme = {
    Background = Color3.fromRGB(7, 10, 8),
    Panel = Color3.fromRGB(12, 17, 13),
    PanelLight = Color3.fromRGB(17, 24, 18),
    PanelHover = Color3.fromRGB(21, 31, 24),
    Border = Color3.fromRGB(31, 50, 35),
    Accent = Color3.fromRGB(0, 255, 120),
    AccentDim = Color3.fromRGB(0, 120, 58),
    AccentDark = Color3.fromRGB(8, 50, 28),
    Text = Color3.fromRGB(235, 246, 239),
    TextDim = Color3.fromRGB(128, 150, 135),
    Danger = Color3.fromRGB(255, 75, 75),
    Font = Enum.Font.GothamMedium,
    FontBold = Enum.Font.GothamBold,
    TitleGradient = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(205, 255, 220)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 90, 45)),
    }),
}
UI.Theme = Theme

local function new(className, props, children)
    local instance = Instance.new(className)
    local parent = nil
    if props then
        parent = props.Parent
        for key, value in pairs(props) do
            if key ~= "Parent" then
                instance[key] = value
            end
        end
    end
    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end
    if parent then
        instance.Parent = parent
    end
    return instance
end

local function addCorner(instance, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = instance
    return corner
end

local function addStroke(instance, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Border
    stroke.Transparency = transparency == nil and 0.25 or transparency
    stroke.Thickness = thickness or 1
    stroke.Parent = instance
    return stroke
end

local function tween(instance, props, duration)
    TweenService:Create(
        instance,
        TweenInfo.new(duration or 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        props
    ):Play()
end

local function track(connection)
    table.insert(UI.Connections, connection)
    return connection
end
UI.Track = track

function UI:GetInputName(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then return "MouseButton1" end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then return "MouseButton2" end
    if input.UserInputType == Enum.UserInputType.MouseButton3 then return "MouseButton3" end
    if input.KeyCode and input.KeyCode ~= Enum.KeyCode.Unknown then
        return input.KeyCode.Name
    end
    return nil
end

function UI:CloseAllPopups()
    local popups = UI.Popups
    UI.Popups = {}
    for _, popup in ipairs(popups) do
        pcall(popup.Destroy)
    end
end

function UI:Cleanup()
    for _, connection in ipairs(UI.Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(UI.Connections)
    self:CloseAllPopups()
end

function UI:Bind(control, getter)
    table.insert(UI.Syncers, function()
        local ok, value = pcall(getter)
        if ok then
            pcall(function() control:Set(value) end)
        end
    end)
end

function UI:Sync()
    for _, syncer in ipairs(UI.Syncers) do
        pcall(syncer)
    end
end

local function colorToHex(color)
    local r = math.floor(color.R * 255 + 0.5)
    local g = math.floor(color.G * 255 + 0.5)
    local b = math.floor(color.B * 255 + 0.5)
    return string.format("#%02X%02X%02X", r, g, b)
end

local function toHSV(color)
    local r, g, b = color.R, color.G, color.B
    local maxValue = math.max(r, g, b)
    local minValue = math.min(r, g, b)
    local delta = maxValue - minValue
    local h, s, v = 0, 0, maxValue

    if maxValue ~= 0 then
        s = delta / maxValue
    end

    if delta ~= 0 then
        if maxValue == r then
            h = ((g - b) / delta) % 6
        elseif maxValue == g then
            h = (b - r) / delta + 2
        else
            h = (r - g) / delta + 4
        end
        h = h / 6
    end

    return h, s, v
end

local function makeRow(section, height)
    local row = new("Frame", {
        Size = UDim2.new(1, 0, 0, height or 32),
        BackgroundColor3 = Theme.PanelHover,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        LayoutOrder = section._order,
        Active = true,
        Parent = section.Frame,
    })
    section._order = section._order + 1
    addCorner(row, 4)
    track(row.MouseEnter:Connect(function()
        tween(row, {BackgroundTransparency = 0.45}, 0.14)
    end))
    track(row.MouseLeave:Connect(function()
        tween(row, {BackgroundTransparency = 1}, 0.14)
    end))
    return row
end

local function makeRowLabel(row, text)
    local label = new("TextLabel", {
        Size = UDim2.new(1, -110, 1, 0),
        Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })
    return label
end

-- // ---------------------------------------------------------------------------
-- // Window
-- // ---------------------------------------------------------------------------

local WindowMethods = {}
local TabMethods = {}
local SectionMethods = {}

function WindowMethods:SelectTab(tab)
    for _, other in ipairs(self.TabList) do
        local selected = (other == tab)
        other.Page.Visible = selected
        other.Button.BackgroundColor3 = selected and Theme.PanelLight or Theme.Background
        other.Button.BackgroundTransparency = selected and 0 or 1
        other.Button.TextColor3 = selected and Theme.Accent or Theme.TextDim
        other.Indicator.Visible = selected
    end
    self.ActiveTab = tab
end

function WindowMethods:Tab(name)
    local button = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Text = "  " .. name,
        TextColor3 = Theme.TextDim,
        TextSize = 11,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        LayoutOrder = #self.TabList + 1,
        Parent = self.Sidebar,
    })
    addCorner(button, 5)

    local indicator = new("Frame", {
        Size = UDim2.new(0, 3, 0, 16),
        Position = UDim2.new(0, 0, 0.5, -8),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = button,
    })
    addCorner(indicator, 2)

    local page = new("ScrollingFrame", {
        Size = UDim2.new(1, 0, 1, 0),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.AccentDim,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(0, 0, 0, 0),
        Visible = false,
        Parent = self.Content,
    })
    new("UIPadding", {
        PaddingTop = UDim.new(0, 12),
        PaddingBottom = UDim.new(0, 12),
        PaddingLeft = UDim.new(0, 12),
        PaddingRight = UDim.new(0, 12),
        Parent = page,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
        Parent = page,
    })

    local tab = setmetatable({
        Name = name,
        Page = page,
        Button = button,
        Indicator = indicator,
        Window = self,
    }, {__index = TabMethods})

    button.MouseButton1Click:Connect(function()
        self:SelectTab(tab)
    end)
    track(button.MouseEnter:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, {BackgroundTransparency = 0.45}, 0.14)
        end
    end))
    track(button.MouseLeave:Connect(function()
        if self.ActiveTab ~= tab then
            tween(button, {BackgroundTransparency = 1}, 0.14)
        end
    end))

    table.insert(self.TabList, tab)
    self.Tabs[name] = tab
    if #self.TabList == 1 then
        self:SelectTab(tab)
    end
    return tab
end

function WindowMethods:SetVisible(visible)
    self.Main.Visible = visible
    if visible and self.OnShow then
        pcall(self.OnShow)
    end
end

function WindowMethods:IsOpen()
    return self.Main.Visible
end

function WindowMethods:Toggle()
    self:SetVisible(not self.Main.Visible)
end

function WindowMethods:SetScale(scale)
    self.Scale.Scale = scale
end

function WindowMethods:SetStatus(text)
    self.Status.Text = text
end

function WindowMethods:SetMinimized(minimized)
    self.Minimized = minimized
    self.Sidebar.Visible = not minimized
    self.Content.Visible = not minimized
    self.Footer.Visible = not minimized
    self.Main.Size = minimized and UDim2.new(0, 690, 0, 48) or self.NormalSize
end

function WindowMethods:Destroy()
    UI:Cleanup()
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

function UI:CreateWindow(options)
    options = options or {}

    local screenGui = new("ScreenGui", {
        Name = "Fabled",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        DisplayOrder = 999,
        Parent = (gethui and gethui()) or (syn and syn.protect_gui and PD.coreGui) or PD.coreGui,
    })
    PD.screenGui = screenGui

    local normalSize = UDim2.new(0, 690, 0, 520)
    local main = new("Frame", {
        Name = "FabledWindow",
        Size = normalSize,
        Position = UDim2.new(0.5, -345, 0.5, -260),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = screenGui,
    })
    addCorner(main, 9)
    addStroke(main, Theme.Accent, 0.62, 1.2)

    local scale = new("UIScale", {
        Scale = (PD.silentAim and PD.silentAim.MenuScale) or 1,
        Parent = main,
    })

    -- // Top bar
    local topBar = new("Frame", {
        Size = UDim2.new(1, 0, 0, 48),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = main,
    })
    addCorner(topBar, 9)

    local topBarCover = new("Frame", {
        Size = UDim2.new(1, 0, 0, 12),
        Position = UDim2.new(0, 0, 1, -12),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = topBar,
    })

    local topGradient = new("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 32, 24)),
            ColorSequenceKeypoint.new(1, Theme.Panel),
        }),
        Rotation = 90,
        Parent = topBar,
    })

    local accentLine = new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        Position = UDim2.new(0, 0, 1, -1),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = topBar,
    })
    local accentGradient = new("UIGradient", {
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.5, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Parent = accentLine,
    })

    local title = new("TextLabel", {
        Size = UDim2.new(0, 200, 0, 48),
        Position = UDim2.new(0, 18, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Title or "FABLED",
        TextColor3 = Color3.fromRGB(255, 255, 255),
        TextSize = 20,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextStrokeTransparency = 0.8,
        TextStrokeColor3 = Theme.Accent,
        Parent = topBar,
    })
    new("UIGradient", {
        Color = Theme.TitleGradient,
        Rotation = 0,
        Parent = title,
    })

    local subtitle = new("TextLabel", {
        Size = UDim2.new(0, 160, 0, 48),
        Position = UDim2.new(0, 126, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Subtitle or "PROJECT DELTA",
        TextColor3 = Theme.TextDim,
        TextSize = 9,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = topBar,
    })

    local version = new("TextLabel", {
        Size = UDim2.new(0, 80, 0, 48),
        Position = UDim2.new(1, -150, 0, 0),
        BackgroundTransparency = 1,
        Text = options.Version or "v2.0",
        TextColor3 = Theme.TextDim,
        TextSize = 9,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = topBar,
    })

    local minimize = new("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -62, 0, 12),
        BackgroundColor3 = Theme.PanelLight,
        BorderSizePixel = 0,
        Text = "–",
        TextColor3 = Theme.TextDim,
        TextSize = 14,
        Font = Theme.FontBold,
        AutoButtonColor = false,
        Parent = topBar,
    })
    addCorner(minimize, 4)

    local close = new("TextButton", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(1, -34, 0, 12),
        BackgroundColor3 = Theme.PanelLight,
        BorderSizePixel = 0,
        Text = "×",
        TextColor3 = Theme.TextDim,
        TextSize = 16,
        Font = Theme.FontBold,
        AutoButtonColor = false,
        Parent = topBar,
    })
    addCorner(close, 4)

    -- // Sidebar
    local sidebar = new("Frame", {
        Size = UDim2.new(0, 150, 1, -70),
        Position = UDim2.new(0, 0, 0, 48),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = main,
    })
    new("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 8),
        Parent = sidebar,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 5),
        Parent = sidebar,
    })

    -- // Content
    local content = new("Frame", {
        Size = UDim2.new(1, -150, 1, -70),
        Position = UDim2.new(0, 150, 0, 48),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = main,
    })

    -- // Footer
    local footer = new("Frame", {
        Size = UDim2.new(1, 0, 0, 22),
        Position = UDim2.new(0, 0, 1, -22),
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        Parent = main,
    })
    local status = new("TextLabel", {
        Size = UDim2.new(1, -20, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = "RightAlt // Toggle Menu    •    Delete // Unload",
        TextColor3 = Theme.TextDim,
        TextSize = 9,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = footer,
    })
    local footerBrand = new("TextLabel", {
        Size = UDim2.new(0, 120, 1, 0),
        Position = UDim2.new(1, -130, 0, 0),
        BackgroundTransparency = 1,
        Text = "FABLED // RAGE",
        TextColor3 = Theme.AccentDim,
        TextSize = 9,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = footer,
    })

    local window = setmetatable({
        ScreenGui = screenGui,
        Main = main,
        TopBar = topBar,
        Sidebar = sidebar,
        Content = content,
        Footer = footer,
        Status = status,
        Scale = scale,
        NormalSize = normalSize,
        Tabs = {},
        TabList = {},
        ActiveTab = nil,
        Minimized = false,
    }, {__index = WindowMethods})

    -- // Dragging
    local dragging = false
    local dragStart = nil
    local startPos = nil
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = main.Position
        end
    end)
    track(userInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end))
    track(userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end))

    close.MouseButton1Click:Connect(function()
        window:SetVisible(false)
    end)
    minimize.MouseButton1Click:Connect(function()
        window:SetMinimized(not window.Minimized)
    end)

    track(close.MouseEnter:Connect(function()
        tween(close, {BackgroundColor3 = Theme.Danger, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.12)
    end))
    track(close.MouseLeave:Connect(function()
        tween(close, {BackgroundColor3 = Theme.PanelLight, TextColor3 = Theme.TextDim}, 0.12)
    end))
    track(minimize.MouseEnter:Connect(function()
        tween(minimize, {BackgroundColor3 = Theme.AccentDark, TextColor3 = Theme.Accent}, 0.12)
    end))
    track(minimize.MouseLeave:Connect(function()
        tween(minimize, {BackgroundColor3 = Theme.PanelLight, TextColor3 = Theme.TextDim}, 0.12)
    end))

    UI.Window = window
    return window
end

-- // ---------------------------------------------------------------------------
-- // Tabs & Sections
-- // ---------------------------------------------------------------------------

function TabMethods:Section(title)
    self._sectionOrder = (self._sectionOrder or 0) + 1
    local section = new("Frame", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.Panel,
        BorderSizePixel = 0,
        LayoutOrder = self._sectionOrder,
        Parent = self.Page,
    })
    addCorner(section, 6)
    addStroke(section, Theme.Border, 0.35, 1)
    new("UIPadding", {
        PaddingTop = UDim.new(0, 10),
        PaddingBottom = UDim.new(0, 10),
        PaddingLeft = UDim.new(0, 10),
        PaddingRight = UDim.new(0, 10),
        Parent = section,
    })
    new("UIListLayout", {
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 6),
        Parent = section,
    })

    local header = new("Frame", {
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
        Parent = section,
    })
    local bar = new("Frame", {
        Size = UDim2.new(0, 3, 0, 14),
        Position = UDim2.new(0, 0, 0, 3),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = header,
    })
    addCorner(bar, 2)
    new("TextLabel", {
        Size = UDim2.new(1, -12, 1, 0),
        Position = UDim2.new(0, 10, 0, 0),
        BackgroundTransparency = 1,
        Text = string.upper(title),
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local sectionObj = setmetatable({
        Frame = section,
        _order = 1,
    }, {__index = SectionMethods})

    return sectionObj
end

function SectionMethods:Toggle(text, default, callback)
    local row = makeRow(self, 32)
    local label = makeRowLabel(row, text)
    label.Size = UDim2.new(1, -46, 1, 0)

    local box = new("Frame", {
        Size = UDim2.new(0, 18, 0, 18),
        Position = UDim2.new(1, -26, 0.5, -9),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Parent = row,
    })
    addCorner(box, 4)
    local boxStroke = addStroke(box, Theme.Border, 0.15, 1)

    local fill = new("Frame", {
        Size = UDim2.new(0, 10, 0, 10),
        Position = UDim2.new(0.5, -5, 0.5, -5),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Visible = false,
        Parent = box,
    })
    addCorner(fill, 2)

    local state = not not default

    local function apply(value)
        state = value
        fill.Visible = value
        boxStroke.Color = value and Theme.Accent or Theme.Border
        boxStroke.Transparency = value and 0 or 0.15
        label.TextColor3 = value and Theme.Text or Theme.TextDim
        if value then
            tween(fill, {Size = UDim2.new(0, 10, 0, 10)}, 0.12)
        end
    end

    local function change(value)
        apply(value)
        if callback then callback(value) end
    end

    row.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            change(not state)
        end
    end)

    apply(state)

    local control = {}
    function control:Set(value)
        apply(not not value)
    end
    function control:Get()
        return state
    end
    control.Row = row
    return control
end

function SectionMethods:Slider(text, minValue, maxValue, default, callback, options)
    options = options or {}
    local decimals = options.decimals or 0
    local suffix = options.suffix or ""

    local row = makeRow(self, 46)
    local label = new("TextLabel", {
        Size = UDim2.new(1, -110, 0, 18),
        Position = UDim2.new(0, 8, 0, 4),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.Text,
        TextSize = 11,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })
    local valueLabel = new("TextLabel", {
        Size = UDim2.new(0, 100, 0, 18),
        Position = UDim2.new(1, -108, 0, 4),
        BackgroundTransparency = 1,
        Text = "",
        TextColor3 = Theme.Accent,
        TextSize = 11,
        Font = Theme.FontBold,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local sliderTrack = new("Frame", {
        Size = UDim2.new(1, -16, 0, 5),
        Position = UDim2.new(0, 8, 0, 32),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Active = true,
        Parent = row,
    })
    addCorner(sliderTrack, 3)
    addStroke(sliderTrack, Theme.Border, 0.35, 1)

    local fill = new("Frame", {
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = sliderTrack,
    })
    addCorner(fill, 3)

    local knob = new("Frame", {
        Size = UDim2.new(0, 11, 0, 11),
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        Parent = sliderTrack,
    })
    addCorner(knob, 6)
    addStroke(knob, Theme.Accent, 0, 1)

    local state = math.clamp(default or minValue, minValue, maxValue)

    local function round(value)
        if decimals <= 0 then
            return math.floor(value + 0.5)
        end
        local mult = 10 ^ decimals
        return math.floor(value * mult + 0.5) / mult
    end

    local function format(value)
        if decimals > 0 then
            return string.format("%." .. decimals .. "f", value) .. suffix
        end
        return tostring(math.floor(value + 0.5)) .. suffix
    end

    local function apply(value)
        state = round(math.clamp(value, minValue, maxValue))
        local alpha = 0
        if maxValue > minValue then
            alpha = (state - minValue) / (maxValue - minValue)
        end
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = format(state)
    end

    local function change(value, finished)
        apply(value)
        if callback then callback(state, finished) end
    end

    local function updateFromInput(input)
        local alpha = math.clamp((input.Position.X - sliderTrack.AbsolutePosition.X) / math.max(sliderTrack.AbsoluteSize.X, 1), 0, 1)
        change(minValue + (maxValue - minValue) * alpha, false)
    end

    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateFromInput(input)
            local moveConn = userInputService.InputChanged:Connect(function(moveInput)
                if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                    updateFromInput(moveInput)
                end
            end)
            local endConn
            endConn = userInputService.InputEnded:Connect(function(endInput)
                if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                    moveConn:Disconnect()
                    endConn:Disconnect()
                    if callback then callback(state, true) end
                end
            end)
            track(moveConn)
            track(endConn)
        end
    end)

    apply(state)

    local control = {}
    function control:Set(value)
        apply(value)
    end
    function control:Get()
        return state
    end
    control.Row = row
    return control
end

function SectionMethods:ColorPicker(text, default, callback)
    local row = makeRow(self, 34)
    local label = makeRowLabel(row, text)
    label.Size = UDim2.new(1, -70, 1, 0)

    local swatch = new("TextButton", {
        Size = UDim2.new(0, 46, 0, 22),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = default or Theme.Accent,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = row,
    })
    addCorner(swatch, 4)
    addStroke(swatch, Theme.Border, 0.15, 1)

    local current = default or Theme.Accent
    local pickerEntry = nil

    local function setColor(color)
        current = color
        swatch.BackgroundColor3 = color
        if pickerEntry and pickerEntry.SetColor then
            pickerEntry.SetColor(color)
        end
    end

    local function closePicker(finish)
        if pickerEntry then
            local entry = pickerEntry
            pickerEntry = nil
            entry.Destroy()
            if finish and callback then callback(current, true) end
        end
    end

    local function openPicker()
        if pickerEntry then
            closePicker(true)
            return
        end

        UI:CloseAllPopups()

        local panel = new("Frame", {
            Size = UDim2.new(0, 190, 0, 246),
            BackgroundColor3 = Theme.Panel,
            BorderSizePixel = 0,
            ZIndex = 60,
            Parent = PD.screenGui,
        })
        addCorner(panel, 6)
        addStroke(panel, Theme.Accent, 0.3, 1)

        local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
        local px = math.clamp(swatch.AbsolutePosition.X + swatch.AbsoluteSize.X - 190, 8, viewport.X - 198)
        local py = math.clamp(swatch.AbsolutePosition.Y + 26, 8, viewport.Y - 254)
        panel.Position = UDim2.fromOffset(px, py)

        local entry = {}
        entry.Destroy = function()
            if panel and panel.Parent then
                panel:Destroy()
            end
            for i = #UI.Popups, 1, -1 do
                if UI.Popups[i] == entry then
                    table.remove(UI.Popups, i)
                end
            end
            if pickerEntry == entry then
                pickerEntry = nil
            end
        end
        table.insert(UI.Popups, entry)
        pickerEntry = entry

        new("TextLabel", {
            Size = UDim2.new(1, -40, 0, 18),
            Position = UDim2.new(0, 10, 0, 8),
            BackgroundTransparency = 1,
            Text = "COLOR PICKER",
            TextColor3 = Theme.Text,
            TextSize = 10,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = panel,
        })

        local closeButton = new("TextButton", {
            Size = UDim2.new(0, 20, 0, 20),
            Position = UDim2.new(1, -28, 0, 7),
            BackgroundTransparency = 1,
            Text = "×",
            TextColor3 = Theme.TextDim,
            TextSize = 14,
            Font = Theme.FontBold,
            AutoButtonColor = false,
            Parent = panel,
        })
        closeButton.MouseButton1Click:Connect(function()
            closePicker(true)
        end)

        local svBox = new("Frame", {
            Size = UDim2.new(0, 170, 0, 100),
            Position = UDim2.new(0, 10, 0, 32),
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            BorderSizePixel = 0,
            Active = true,
            ClipsDescendants = true,
            Parent = panel,
        })
        addCorner(svBox, 3)

        local whiteOverlay = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = svBox,
        })
        new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            }),
            Parent = whiteOverlay,
        })

        local blackOverlay = new("Frame", {
            Size = UDim2.new(1, 0, 1, 0),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
            Parent = svBox,
        })
        new("UIGradient", {
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
            Rotation = 90,
            Parent = blackOverlay,
        })

        local svKnob = new("Frame", {
            Size = UDim2.new(0, 10, 0, 10),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = svBox,
        })
        addCorner(svKnob, 5)
        addStroke(svKnob, Color3.fromRGB(0, 0, 0), 0, 1)

        local hueTrack = new("Frame", {
            Size = UDim2.new(0, 170, 0, 10),
            Position = UDim2.new(0, 10, 0, 142),
            BackgroundColor3 = Color3.fromRGB(255, 0, 0),
            BorderSizePixel = 0,
            Active = true,
            Parent = panel,
        })
        addCorner(hueTrack, 3)
        new("UIGradient", {
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)),
                ColorSequenceKeypoint.new(1 / 6, Color3.fromRGB(255, 255, 0)),
                ColorSequenceKeypoint.new(2 / 6, Color3.fromRGB(0, 255, 0)),
                ColorSequenceKeypoint.new(3 / 6, Color3.fromRGB(0, 255, 255)),
                ColorSequenceKeypoint.new(4 / 6, Color3.fromRGB(0, 0, 255)),
                ColorSequenceKeypoint.new(5 / 6, Color3.fromRGB(255, 0, 255)),
                ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 0, 0)),
            }),
            Parent = hueTrack,
        })
        local hueKnob = new("Frame", {
            Size = UDim2.new(0, 8, 0, 14),
            Position = UDim2.new(0, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
            Parent = hueTrack,
        })
        addCorner(hueKnob, 4)
        addStroke(hueKnob, Color3.fromRGB(0, 0, 0), 0, 1)

        new("TextLabel", {
            Size = UDim2.new(0, 32, 0, 14),
            Position = UDim2.new(0, 10, 0, 160),
            BackgroundTransparency = 1,
            Text = "HEX",
            TextColor3 = Theme.TextDim,
            TextSize = 9,
            Font = Theme.FontBold,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = panel,
        })

        local hexBox = new("TextBox", {
            Size = UDim2.new(0, 104, 0, 24),
            Position = UDim2.new(0, 10, 0, 176),
            BackgroundColor3 = Theme.Background,
            BorderSizePixel = 0,
            Text = "",
            TextColor3 = Theme.Text,
            TextSize = 10,
            Font = Theme.Font,
            ClearTextOnFocus = false,
            Parent = panel,
        })
        addCorner(hexBox, 4)
        addStroke(hexBox, Theme.Border, 0.2, 1)

        local preview = new("Frame", {
            Size = UDim2.new(0, 56, 0, 24),
            Position = UDim2.new(0, 120, 0, 176),
            BackgroundColor3 = current,
            BorderSizePixel = 0,
            Parent = panel,
        })
        addCorner(preview, 4)
        addStroke(preview, Theme.Border, 0.2, 1)

        local h, s, v = toHSV(current)

        local function refresh()
            local color = Color3.fromHSV(h, s, v)
            current = color
            swatch.BackgroundColor3 = color
            preview.BackgroundColor3 = color
            svBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svKnob.Position = UDim2.new(s, 0, 1 - v, 0)
            hueKnob.Position = UDim2.new(h, 0, 0.5, 0)
            hexBox.Text = colorToHex(color)
            return color
        end

        entry.SetColor = function(color)
            h, s, v = toHSV(color)
            refresh()
        end

        local function emit(finished)
            if callback then callback(current, finished) end
        end

        local function moveSV(input)
            s = math.clamp((input.Position.X - svBox.AbsolutePosition.X) / math.max(svBox.AbsoluteSize.X, 1), 0, 1)
            v = 1 - math.clamp((input.Position.Y - svBox.AbsolutePosition.Y) / math.max(svBox.AbsoluteSize.Y, 1), 0, 1)
            refresh()
            emit(false)
        end

        svBox.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                moveSV(input)
                local moveConn = userInputService.InputChanged:Connect(function(moveInput)
                    if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                        moveSV(moveInput)
                    end
                end)
                local endConn
                endConn = userInputService.InputEnded:Connect(function(endInput)
                    if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                        moveConn:Disconnect()
                        endConn:Disconnect()
                        emit(true)
                    end
                end)
                track(moveConn)
                track(endConn)
            end
        end)

        local function moveHue(input)
            h = math.clamp((input.Position.X - hueTrack.AbsolutePosition.X) / math.max(hueTrack.AbsoluteSize.X, 1), 0, 1)
            refresh()
            emit(false)
        end

        hueTrack.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                moveHue(input)
                local moveConn = userInputService.InputChanged:Connect(function(moveInput)
                    if moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch then
                        moveHue(moveInput)
                    end
                end)
                local endConn
                endConn = userInputService.InputEnded:Connect(function(endInput)
                    if endInput.UserInputType == Enum.UserInputType.MouseButton1 or endInput.UserInputType == Enum.UserInputType.Touch then
                        moveConn:Disconnect()
                        endConn:Disconnect()
                        emit(true)
                    end
                end)
                track(moveConn)
                track(endConn)
            end
        end)

        hexBox.FocusLost:Connect(function()
            local text = string.gsub(hexBox.Text, "#", "")
            local ok, color = pcall(function()
                return Color3.fromHex("#" .. text)
            end)
            if ok and color then
                h, s, v = toHSV(color)
                refresh()
                emit(true)
            else
                hexBox.Text = colorToHex(current)
            end
        end)

        local presets = {
            Color3.fromRGB(0, 255, 120),
            Color3.fromRGB(255, 255, 255),
            Color3.fromRGB(255, 75, 75),
            Color3.fromRGB(0, 160, 255),
            Color3.fromRGB(255, 200, 55),
            Color3.fromRGB(185, 95, 255),
            Color3.fromRGB(255, 120, 0),
        }
        for index, preset in ipairs(presets) do
            local button = new("TextButton", {
                Size = UDim2.new(0, 18, 0, 18),
                Position = UDim2.new(0, 10 + (index - 1) * 24, 0, 214),
                BackgroundColor3 = preset,
                BorderSizePixel = 0,
                Text = "",
                AutoButtonColor = false,
                Parent = panel,
            })
            addCorner(button, 3)
            addStroke(button, Theme.Border, 0.15, 1)
            button.MouseButton1Click:Connect(function()
                h, s, v = toHSV(preset)
                refresh()
                emit(true)
            end)
        end

        refresh()
    end

    swatch.MouseButton1Click:Connect(openPicker)

    local control = {}
    function control:Set(color)
        setColor(color)
    end
    function control:Get()
        return current
    end
    control.Row = row
    return control
end

function SectionMethods:Keybind(text, default, callback)
    local row = makeRow(self, 32)
    local label = makeRowLabel(row, text)
    label.Size = UDim2.new(1, -112, 1, 0)

    local button = new("TextButton", {
        Size = UDim2.new(0, 96, 0, 22),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = "",
        TextColor3 = Theme.Accent,
        TextSize = 10,
        Font = Theme.FontBold,
        AutoButtonColor = false,
        Parent = row,
    })
    addCorner(button, 4)
    addStroke(button, Theme.Border, 0.15, 1)

    local state = default or "None"
    local listening = false
    local listenConn = nil

    local function apply(key)
        state = key or "None"
        button.Text = listening and "PRESS KEY..." or state
        button.TextColor3 = (state == "None") and Theme.TextDim or Theme.Accent
    end

    local function stopListening()
        listening = false
        if listenConn then
            listenConn:Disconnect()
            listenConn = nil
        end
        apply(state)
    end

    local function startListening()
        if listening then
            stopListening()
            return
        end
        listening = true
        apply(state)
        listenConn = userInputService.InputBegan:Connect(function(input)
            local name = UI:GetInputName(input)
            if input.KeyCode == Enum.KeyCode.Escape then
                stopListening()
                if callback then callback("None") end
                return
            end
            if name then
                stopListening()
                apply(name)
                if callback then callback(name) end
            end
        end)
        track(listenConn)
    end

    button.MouseButton1Click:Connect(startListening)
    apply(state)

    local control = {}
    function control:Set(key)
        apply(key)
    end
    function control:Get()
        return state
    end
    control.Row = row
    return control
end

function SectionMethods:Textbox(text, placeholder, default, callback)
    local row = makeRow(self, 32)
    local label = makeRowLabel(row, text)
    label.Size = UDim2.new(1, -190, 1, 0)

    local box = new("TextBox", {
        Size = UDim2.new(0, 170, 0, 22),
        Position = UDim2.new(1, -8, 0.5, 0),
        AnchorPoint = Vector2.new(1, 0.5),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Text = default or "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Theme.TextDim,
        TextColor3 = Theme.Text,
        TextSize = 10,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = row,
    })
    addCorner(box, 4)
    addStroke(box, Theme.Border, 0.15, 1)

    box:GetPropertyChangedSignal("Text"):Connect(function()
        if callback then callback(box.Text) end
    end)

    local control = {}
    function control:Set(value)
        box.Text = tostring(value or "")
    end
    function control:Get()
        return box.Text
    end
    control.Row = row
    control.TextBox = box
    return control
end

function SectionMethods:Button(text, callback)
    local button = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Theme.AccentDark,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Theme.Accent,
        TextSize = 10,
        Font = Theme.FontBold,
        AutoButtonColor = false,
        LayoutOrder = self._order,
        Parent = self.Frame,
    })
    self._order = self._order + 1
    addCorner(button, 4)
    local stroke = addStroke(button, Theme.Accent, 0.55, 1)

    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)

    track(button.MouseEnter:Connect(function()
        tween(button, {BackgroundColor3 = Color3.fromRGB(10, 66, 36)}, 0.12)
        stroke.Transparency = 0.2
    end))
    track(button.MouseLeave:Connect(function()
        tween(button, {BackgroundColor3 = Theme.AccentDark}, 0.12)
        stroke.Transparency = 0.55
    end))

    local control = {}
    function control:SetText(value)
        button.Text = value
    end
    control.Button = button
    return control
end

function SectionMethods:Label(text)
    local label = new("TextLabel", {
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = Theme.TextDim,
        TextSize = 9,
        Font = Theme.Font,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
        LayoutOrder = self._order,
        Parent = self.Frame,
    })
    self._order = self._order + 1
    new("UIPadding", {
        PaddingLeft = UDim.new(0, 4),
        PaddingRight = UDim.new(0, 4),
        Parent = label,
    })
    return label
end

function SectionMethods:Divider()
    local divider = new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Border,
        BorderSizePixel = 0,
        LayoutOrder = self._order,
        Parent = self.Frame,
    })
    self._order = self._order + 1
    return divider
end
