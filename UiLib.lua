local UiLibrary = {}
UiLibrary.__index = UiLibrary

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TextService = game:GetService("TextService")

local guiAssets = game:GetObjects("rbxassetid://13337778865")[1]
local disabledColor = Color3.fromRGB(27, 27, 27)
local unhighlightColor = Color3.fromRGB(41, 41, 41)
local dropUnselectedColor = Color3.fromRGB(100, 100, 100)
local theme = Color3.new(1,1,1)
local sliders = {}
local toggles = {}
local allTexts = {}
local guiFont = Enum.Font.Gotham
local fontSizes = {
    [Enum.Font.Gotham] = 15,
    [Enum.Font.SourceSans] = 15,
}
local colorPickerConnections = {}
local tempPickerConnections = {}
local dropDowns = {}
local currentColorPicker
local currentColorPickerButton
local justRebinded = false
local text = {}
local borders = {}
local hideBind = {[2] = Enum.KeyCode.End.Name}
local currentHighlight
local mainGui
local freeThread

local secondaryBinds = {
    [Enum.KeyCode.LeftControl.Name] = "LCtrl",
    [Enum.KeyCode.RightControl.Name] = "RCtrl",
    [Enum.KeyCode.LeftAlt.Name] = "LAlt",
    [Enum.KeyCode.RightAlt.Name] = "RAlt",
    [Enum.KeyCode.Tab.Name] = "Tab",
    [Enum.KeyCode.RightShift.Name] = "RShift"
}

local bindBlacklist = {
    [Enum.KeyCode.Slash.Name] = true,
    [Enum.KeyCode.A.Name] = true,
    [Enum.KeyCode.W.Name] = true,
    [Enum.KeyCode.S.Name] = true,
    [Enum.KeyCode.D.Name] = true,
    [Enum.KeyCode.LeftShift.Name] = true,
    [Enum.KeyCode.Backspace.Name] = true,
    [Enum.KeyCode.Space.Name] = true,
    [Enum.KeyCode.Unknown.Name] = true,
    [Enum.KeyCode.Backquote.Name] = true,
}

local function functionPasser(func, ...)
    local currentThread = freeThread
    freeThread = nil
    func(...)
    freeThread = currentThread
end

local function newThread()
    while true do
        functionPasser(coroutine.yield())
    end
end

local function spawnWithReuse(func, ...)
    if not freeThread then
        freeThread = coroutine.create(newThread)
        coroutine.resume(freeThread)
    end

    task.spawn(freeThread, func, ...)
end

function UiLibrary.new(name: string)
    local secondaryDown = false
    mainGui = guiAssets.ScreenGui:Clone()
    mainGui.Frame.TopBar.GuiName.Text = name
    mainGui.Frame.TopBar.GuiName.Font = guiFont
    mainGui.Frame.TopBar.GuiName.TextSize = fontSizes[guiFont]

    table.insert(borders, mainGui.Frame.Border)
    table.insert(borders, mainGui.Frame.Tabs.Border)
    table.insert(text, mainGui.Frame.TopBar.GuiName)
    table.insert(allTexts, mainGui.Frame.TopBar.GuiName)

    if syn and syn.protect_gui then
        syn.protect_gui(mainGui)
        mainGui.Parent = game.CoreGui
    elseif gethui then
        mainGui.Parent = gethui()
    else
        mainGui.Parent = game.CoreGui
    end

    mainGui.Frame.TopBar.MouseButton1Down:Connect(function(X, Y)
        local offset = {X - mainGui.Frame.AbsolutePosition.X, Y - mainGui.Frame.AbsolutePosition.Y}
        local anchorPoint = UDim2.new(0,  mainGui.Frame.Size.X.Offset * mainGui.Frame.AnchorPoint.X, 0, mainGui.Frame.Size.Y.Offset * mainGui.Frame.AnchorPoint.Y)
        local mouseConnection
        local dragConnection

        mouseConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseMovement then
                dragConnection:Disconnect()
                mouseConnection:Disconnect()
            end
        end)

        dragConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                mainGui.Frame.Position = UDim2.new(0, input.Position.X - offset[1], 0, input.Position.Y - offset[2] + 72) + anchorPoint
            end
        end)
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if justRebinded then
            justRebinded = false

            return
        end

        if not gameProcessed then
            if hideBind[1] then
                if input.KeyCode.Name == hideBind[1] then
                    secondaryDown = true
                end

                if input.KeyCode.Name == hideBind[2] and secondaryDown then
                    mainGui.Enabled = not mainGui.Enabled

                    if currentHighlight then
                        currentHighlight.ImageColor3 = unhighlightColor
                        currentHighlight = false
                    end
                end
            else
                if input.KeyCode.Name == hideBind[2] then
                    mainGui.Enabled = not mainGui.Enabled

                    if currentHighlight then
                        currentHighlight.ImageColor3 = unhighlightColor
                        currentHighlight = false
                    end
                end
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode.Name == hideBind[1] then
            secondaryDown = false
        end
    end)

    return setmetatable({
        currentTab = false,
        borders = borders,
        tabCount = 0,
    }, UiLibrary)
end

function UiLibrary:RebindHide(keyCode)
    justRebinded = true
    hideBind = keyCode["2"] and {[2] = keyCode["2"]} or keyCode
end

function UiLibrary:ChangeTheme(newTheme: Color3)
    for i,v in ipairs(mainGui.Frame.Tabs.Holder:GetChildren()) do
        if v:IsA("TextButton") then
            if v.BackgroundColor3 == theme then
                v.BackgroundColor3 = newTheme
            end
        end
    end

    for i,v in ipairs(borders) do
        v.ImageColor3 = newTheme
    end

    for i,v in ipairs(text) do
        v.TextColor3 = newTheme
    end

    for i,v in pairs(sliders) do
        v.Frame.BackgroundColor3 = newTheme
    end

    if currentColorPickerButton then
        currentColorPicker.Border.ImageColor3 = newTheme
        currentColorPicker.Slider.Border.ImageColor3 = newTheme
        currentColorPicker.Gradient.Border.ImageColor3 = newTheme
        currentColorPicker.Gradient.Cursor.Border.ImageColor3 = newTheme
        currentColorPicker.Frame.Button.PlaceholderColor3 = newTheme
        currentColorPicker.Frame.Button.TextColor3 = newTheme
        currentColorPickerButton.ImageButton.Border.ImageColor3 = newTheme
    end

    for i,v in pairs(toggles) do
        if v.ImageButton.BackgroundColor3 == theme then
            v.ImageButton.BackgroundColor3 = newTheme
        end
    end

    for i,v in pairs(mainGui.Frame.Windows:GetChildren()) do
        v.ScrollBarImageColor3 = newTheme
    end

    for i,v in pairs(dropDowns) do
        v.Main.Options.ScrollBarImageColor3 = newTheme

        if v.Main.Border.ImageColor3 == theme then
            v.Main.Border.ImageColor3 = newTheme
        end

        for i,v in pairs(v.Main.Options:GetChildren()) do
            if v:IsA("TextButton") and v.TextColor3 == theme then
                v.TextColor3 = newTheme
            end
        end
    end

    for i,v in pairs(mainGui.Frame.Tabs.Holder:GetChildren()) do
        if v:IsA("TextButton") then
            if v.TextColor3 == disabledColor then
                v.BackgroundColor3 = newTheme
            else
                v.TextColor3 = newTheme
            end
        end
    end

    if currentHighlight then
        currentHighlight = newTheme
    end

    theme = newTheme
end

function UiLibrary.addBlacklist(keybinds)
    for i,v in pairs(keybinds) do
        bindBlacklist[v] = true
    end
end

function UiLibrary:ChangeFont(font)
    --local size = fontSizes[font]

    for i,v in pairs(allTexts) do
        v.Font = font
        --v.TextSize = size
    end
end


local Tabs = {}
Tabs.__index = Tabs

function UiLibrary:CreateTab(name)
    local tab = guiAssets.Tab:Clone()
    local window = guiAssets.Window:Clone()

    self.tabCount += 1
    tab.Text = name
    tab.Font = guiFont
    tab.TextColor3 = theme
    tab.TextSize = fontSizes[guiFont]
    tab.Parent = mainGui.Frame.Tabs.Holder
    window.Parent = mainGui.Frame.Windows
    table.insert(allTexts, tab)

    for i,v in ipairs(mainGui.Frame.Tabs.Holder:GetChildren()) do
        if v:IsA("TextButton") then
            v.Size = UDim2.new(1 / self.tabCount, 0, 1, 0)
        end
    end

    if not self.currentTab then
        self.currentTab = tab
        tab.TextColor3 = disabledColor
        tab.BackgroundColor3 = theme
    else
        window.Visible = false
    end

    tab.MouseButton1Down:Connect(function()
        for i,v in ipairs(mainGui.Frame.Windows:GetChildren()) do
            v.Visible = false
        end

        self.currentTab.TextColor3 = theme
        self.currentTab.BackgroundColor3 = disabledColor
        self.currentTab = tab
        tab.TextColor3 = disabledColor
        tab.BackgroundColor3 = theme
        window.Visible = true
    end)

    if currentColorPickerButton then
        for i,v in pairs(colorPickerConnections) do
            v:Disconnect()
            colorPickerConnections[i] = nil
        end
        
        currentColorPickerButton.ImageButton.Border.ImageColor3 = disabledColor
        currentColorPickerButton = nil
        currentColorPicker:Destroy()
    end

    return setmetatable({
        window = window
    }, Tabs)
end

local Section = {}
Section.__index = Section

local function getSide(window: ScrollingFrame, shortestSide: boolean)
    if window.Left.UIListLayout.AbsoluteContentSize.Y <= window.Right.UIListLayout.AbsoluteContentSize.Y then
        if shortestSide then
            return window.Right
        else
            return window.Left
        end
    else
        if shortestSide then
            return window.Left
        else
            return window.Right
        end
    end
end

local function updateSizes(section)
    section.Size = UDim2.new(1, 0, 0, section.Frame.Frame.Holder.UIListLayout.AbsoluteContentSize.Y + 23)
    local newSize = getSide(section.Parent.Parent, true).UIListLayout.AbsoluteContentSize.Y + 3
    section.Parent.Parent.CanvasSize = UDim2.new(0, 0, 0, newSize)

    if 249 < newSize then
        section.Parent.Parent.Right.UIPadding.PaddingRight = UDim.new(0, 8)
    else
        section.Parent.Parent.Right.UIPadding.PaddingRight = UDim.new(0, 0)
    end
end

function Tabs:CreateSection(name)
    local section = guiAssets.Section:Clone()
    local textSize = TextService:GetTextSize(name, 15, guiFont, Vector2.zero).X

    section.Parent = getSide(self.window, false)
    section.Frame.Frame.NameGui.TextLabel.Text = name
    section.Frame.Frame.NameGui.TextLabel.Font = guiFont
    section.Frame.Frame.NameGui.TextLabel.TextSize = fontSizes[guiFont]
    section.Frame.Frame.NameGui.TextLabel.TextYAlignment = Enum.TextYAlignment.Top
    section.Frame.Frame.NameGui.TextLabel.TextColor3 = theme
    section.Frame.Frame.NameGui.Size = UDim2.new(0, textSize + 6, 0, 15)
    section.Frame.Frame.Frame.Border.Size = UDim2.new(0, textSize + 8, 0, 20)
    table.insert(allTexts, section.Frame.Frame.NameGui.TextLabel)

    return setmetatable({
        section = section
    }, Section)
end

local ViewportElement = {}
ViewportElement.__index = ViewportElement

function Tabs:CreateViewport(name)
    local viewport = guiAssets.Viewport:Clone()

    viewport.TextLabel.Text = name
    viewport.TextLabel.Font = guiFont
    viewport.TextLabel.TextSize = fontSizes[guiFont]
    viewport.TextLabel.TextColor3 = theme
    viewport.ViewportFrame.Border.ImageColor3 = theme
    viewport.Parent = getSide(self.window, false)

    table.insert(borders, viewport.ViewportFrame.Border)
    table.insert(allTexts, viewport.TextLabel)

    return setmetatable({
        viewport = viewport
    }, ViewportElement)
end

function ViewportElement:SetViewport(instance)
    if not instance:IsA("Model") or not instance:FindFirstChild("HumanoidRootPart") then
        return
    end

    if self.connection then
        self.connection:Disconnect()
    end

    local camera = self.viewport.ViewportFrame:FindFirstChild("Camera")
    local viewing = instance:Clone()
    local humanoidRootPart = viewing:FindFirstChild("HumanoidRootPart")
    humanoidRootPart.Anchored = true

    if not camera then
        camera = Instance.new("Camera")
        camera.Focus = CFrame.identity
        camera.Parent = self.viewport.ViewportFrame
        self.viewport.ViewportFrame.CurrentCamera = camera
    else
        for i,v in pairs(camera:GetChildren()) do
            v:Destroy()
        end
    end

    viewing.PrimaryPart = humanoidRootPart
    viewing:SetPrimaryPartCFrame(CFrame.identity)
    local extentsSize = viewing:GetExtentsSize()
    camera.CFrame = CFrame.new(0, 0, extentsSize.Y)
    viewing.Parent = camera

    self.connection = RunService.Heartbeat:Connect(function()
        viewing:SetPrimaryPartCFrame(viewing.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(1), 0))
    end)
end

local ToggleElement = {}
ToggleElement.__index = ToggleElement

function Section:CreateToggle(config)
    --[[
        {
            name: string
            default: boolean?
            callbackOnCreation: boolean?
            callback: () -> ()
        }
    ]]
    local toggle = guiAssets.Toggle:Clone()
    local toggleTable = {
        toggle = toggle,
        boolean = config.default or false,
        callback = config.callback,
    }

    table.insert(toggles, toggle)

    toggle.TextLabel.Text = config.name
    toggle.TextLabel.TextColor3 = theme
    toggle.TextLabel.Font = guiFont
    toggle.TextLabel.TextSize = fontSizes[guiFont]
    toggle.ImageButton.BackgroundColor3 = self.boolean and theme or disabledColor
    toggle.Parent = self.section.Frame.Frame.Holder
    updateSizes(self.section)
    table.insert(allTexts, toggle.TextLabel)

    if config.default then
        toggle.ImageButton.BackgroundColor3 = theme
    end

    if (not config.callbackOnCreation and config.callbackOnCreation ~= false) or config.callbackOnCreation then
        spawnWithReuse(config.callback, toggleTable.boolean)
    end

    toggle.ImageButton.MouseButton1Down:Connect(function()
        toggleTable.boolean = not toggleTable.boolean
        toggle.ImageButton.BackgroundColor3 = toggleTable.boolean and theme or disabledColor
        toggleTable.callback(toggleTable.boolean)
    end)

    toggle.ImageButton.MouseEnter:Connect(function()
        if currentHighlight then
            currentHighlight.ImageColor3 = unhighlightColor
        end

        toggle.ImageButton.Border.ImageColor3 = theme
        currentHighlight = toggle.ImageButton.Border
    end)

    toggle.ImageButton.MouseLeave:Connect(function()
        toggle.ImageButton.Border.ImageColor3 = unhighlightColor
        currentHighlight = false
    end)

    return setmetatable(toggleTable, ToggleElement)
end

function ToggleElement:Set(boolean: boolean)
    self.boolean = boolean
    self.toggle.ImageButton.BackgroundColor3 = self.boolean and theme or disabledColor
    spawnWithReuse(self.callback, self.boolean)
end

local function makeBind(self)
    self.bindConnections[#self.bindConnections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not gameProcessedEvent then
            if self.bind[1] then
                if input.KeyCode.Name == self.bind[1] then
                    self.secondaryDown = true
                end

                if input.KeyCode.Name == self.bind[2] and self.secondaryDown then
                    if self.toggle then
                        self.boolean = not self.boolean
                        self.toggle.ImageButton.BackgroundColor3 = self.boolean and theme or disabledColor
                        self.callback(self.boolean)
                    else
                        if self.callback then
                            self.callback()
                        end
                    end
                end
            else
                if input.KeyCode.Name == self.bind[2] then
                    if self.toggle then
                        self.boolean = not self.boolean
                        self.toggle.ImageButton.BackgroundColor3 = self.boolean and theme or disabledColor
                        self.callback(self.boolean)
                    else
                        if self.callback then
                            self.callback()
                        end
                    end
                end
            end
        end
    end)

    self.bindConnections[#self.bindConnections + 1] = UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode.Name == self.bind[1] then
            self.secondaryDown = false
        end
    end)
end

local function makeKeybind(parent, self, config)
    local keybind = guiAssets.KeyBind:Clone()
    local getInputs
    self.bindConnections = {}
    self.secondaryDown = false
    self.bind = config.default and {config.default["1"], config.default["2"]} or {}

    keybind.Button.TextColor3 = theme
    keybind.Button.Font = guiFont
    keybind.Button.TextSize = fontSizes[guiFont]
    keybind.Parent = parent
    table.insert(text, keybind.Button)
    table.insert(allTexts,  keybind.Button)

    if config.default then
        makeBind(self)

        if self.bind[2] or self.bind[1] then
            local keybindText = self.bind[1] and secondaryBinds[self.bind[1]] .. " + " .. self.bind[2] or self.bind[2]
            keybind.Button.Text = keybindText
            keybind.Size = UDim2.new(0, TextService:GetTextSize(keybindText, 15, guiFont, Vector2.zero).X + 8, 0, 20)
        else
            keybind.Button.Text = "None"
            keybind.Size = UDim2.new(0, TextService:GetTextSize("None", 15, guiFont, Vector2.zero).X + 8, 0, 20)
        end
    end

    keybind.Button.MouseButton1Down:Connect(function()
        if not getInputs then
            self.bind = {}
            self.secondaryDown = false
            keybind.Button.Text = "..."
            keybind.Size = UDim2.new(0, TextService:GetTextSize("...", 15, guiFont, Vector2.zero).X + 8, 0, 20)

            for i,v in pairs(self.bindConnections) do
                v:Disconnect()
                self.bindConnections[i] = nil
            end
            
            getInputs = UserInputService.InputBegan:Connect(function(input, gameProccessed)
                if not gameProccessed then
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        self.bind = {}
                        getInputs:Disconnect()
                        getInputs = false
                        keybind.Button.Text = "None"
                        keybind.Size = UDim2.new(0, TextService:GetTextSize("None", 15, guiFont, Vector2.zero).X + 8, 0, 20)

                        if config.callback then
                            config.callback({})
                        end
                    end

                    if bindBlacklist[input.KeyCode.Name] then
                        return
                    end

                    if secondaryBinds[input.KeyCode.Name] then
                        self.bind[1] = input.KeyCode.Name
                        local keybindText = secondaryBinds[input.KeyCode.Name] .. " + ..."
                        keybind.Button.Text = keybindText
                        keybind.Size = UDim2.new(0, TextService:GetTextSize(keybindText, 15, guiFont, Vector2.zero).X + 8, 0, 20)
                    else
                        self.bind[2] = input.KeyCode.Name
                    end

                    if self.bind[2] then
                        getInputs:Disconnect()
                        getInputs = false
                        local keybindText = self.bind[1] and secondaryBinds[self.bind[1]] .. " + " .. self.bind[2] or self.bind[2]
                        keybind.Button.Text = keybindText
                        keybind.Size = UDim2.new(0, TextService:GetTextSize(keybindText, 15, guiFont, Vector2.zero).X + 8, 0, 20)

                        if config.callback then
                            config.callback(self.bind)
                        end

                        makeBind(self)
                    end
                end
            end)
        end
    end)

    keybind.Button.MouseButton2Down:Connect(function()
        keybind.Button.Text = "None"
        keybind.Size = UDim2.new(0, TextService:GetTextSize("None", 15, guiFont, Vector2.zero).X + 8, 0, 20)
        self.secondaryDown = false
        self.bind = {}

        for i,v in pairs(self.bindConnections) do
            v:Disconnect()
            self.bindConnections[i] = nil
        end

        if getInputs then
            getInputs:Disconnect()
            getInputs = false
        end

        if config.callback then
            config.callback(self.bind)
        end
    end)
end

function ToggleElement:AddKeybind(config)
    --[[
        {
            default: {secondary bind, primary bind}
            callback: () -> ()?
        }
    ]]
    makeKeybind(self.toggle, self, config)
end

local function round(number, decimalPlaces)
    local power = math.pow(10, decimalPlaces)
    return math.round(number * power) / power
end

local function updateSliderSize(sliderbar, number, minMax)
    sliderbar.Frame.Size = UDim2.new((number - minMax[1]) / (minMax[2] - minMax[1]), 0, 1, 0)
    sliderbar.TextLabel.Text = number .. " / " .. minMax[2]
end

local function makeSlider(sliderBar, config)
    local minMax = {config.min, config.max}
    local value = config.default and math.clamp(config.default, minMax[1], minMax[2]) or minMax[1]
    local rounding = config.rounding or 0
    local sliding = false
    local endConnection
    local slidingConnection

    sliderBar.Frame.BackgroundColor3 = theme
    sliderBar.TextLabel.TextColor3 = theme
    sliderBar.TextLabel.Font = guiFont
    sliderBar.TextLabel.TextSize = fontSizes[guiFont]

    updateSliderSize(sliderBar, value, minMax)
    table.insert(sliders, sliderBar)
    table.insert(allTexts,  sliderBar.TextLabel)

    sliderBar.TextLabel.MouseButton1Down:Connect(function(X, Y)
        sliding = true
        local precentage = math.clamp((X - sliderBar.Frame.AbsolutePosition.X) / sliderBar.TextLabel.AbsoluteSize.X, 0, 1)
        local previousValue = value
        local newValue = precentage * (minMax[2] - minMax[1]) + minMax[1]
        value = rounding > 0 and round(newValue, rounding) or math.floor(newValue + .5)

        if value ~= previousValue then
            updateSliderSize(sliderBar, value, minMax)
            config.callback(value)
        end

        endConnection = UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseMovement then
                slidingConnection:Disconnect()
                endConnection:Disconnect()
                sliding = false

                if currentHighlight ~= sliderBar.Border then
                    sliderBar.Border.ImageColor3 = unhighlightColor
                end
            end
        end)

        slidingConnection = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                precentage = math.clamp((input.Position.X - sliderBar.Frame.AbsolutePosition.X) / sliderBar.TextLabel.AbsoluteSize.X, 0, 1)
                previousValue = value
                newValue = precentage * (minMax[2] - minMax[1]) + minMax[1]
                value = rounding > 0 and round(newValue, rounding) or math.floor(newValue + .5)

                if value ~= previousValue then
                    updateSliderSize(sliderBar, value, minMax)
                    config.callback(value)
                end
            end
        end)
    end)

    sliderBar.TextLabel.MouseEnter:Connect(function()
        if currentHighlight then
            currentHighlight.ImageColor3 = unhighlightColor
        end
        
        sliderBar.Border.ImageColor3 = theme
        currentHighlight = sliderBar.Border
    end)

    sliderBar.TextLabel.MouseLeave:Connect(function()
        currentHighlight = false

        if not sliding then
            sliderBar.Border.ImageColor3 = unhighlightColor
        end
    end)
end



function ToggleElement:AddSlider(config)
    --[[
        {
            min: number
            max: number
            default: number?
            rounding: number?
            callback: number
        }
    ]]
    local slider = guiAssets.SliderElement:Clone()

    self.toggle.Size = UDim2.new(1, 0, 0, 40)
    slider.Parent = self.toggle
    updateSizes(self.toggle.Parent.Parent.Parent.Parent)
    makeSlider(slider, config)
end

function Section:CreateSlider(config)
    --[[
        {   
            name: string
            min: number
            max: number
            default: number?
            rounding: number?
        }
    ]]
    local slider = guiAssets.Slider:Clone()
    local sliderElement = guiAssets.SliderElement:Clone()

    slider.TextLabel.Text = config.name
    slider.TextLabel.Font = guiFont
    slider.TextLabel.TextSize = fontSizes[guiFont]
    slider.TextLabel.Size = UDim2.new(1, -15, 0, 15)
    sliderElement.Parent = slider
    slider.Parent = self.section.Frame.Frame.Holder

    table.insert(allTexts, slider.TextLabel)
    updateSizes(self.section)
    makeSlider(sliderElement, config)
end

function Section:CreateButton(config)
    --[[
        {
            name: string
            callback: () -> ()
        }
    ]]

    local button = guiAssets.Button:Clone()

    button.ImageButton.Text = config.name
    button.ImageButton.Font = guiFont
    button.ImageButton.TextSize = fontSizes[guiFont]
    button.ImageButton.TextColor3 = theme
    button.Parent = self.section.Frame.Frame.Holder
    updateSizes(self.section)
    table.insert(text, button.ImageButton)
    table.insert(allTexts,  button.ImageButton)

    button.ImageButton.MouseButton1Down:Connect(function()
        button.ImageButton.TextColor3 = disabledColor
        button.ImageButton.TextStrokeTransparency = 1
        button.ImageButton.BackgroundColor3 = theme
        config.callback()
    end)

    button.ImageButton.MouseButton1Up:Connect(function()
        button.ImageButton.TextColor3 = theme
        button.ImageButton.TextStrokeTransparency = 0
        button.ImageButton.BackgroundColor3 = disabledColor
    end)

    button.ImageButton.MouseEnter:Connect(function()
        button.ImageButton.Border.ImageColor3 = theme
    end)

    button.ImageButton.MouseLeave:Connect(function()
        button.ImageButton.TextColor3 = theme
        button.ImageButton.TextStrokeTransparency = 0
        button.ImageButton.BackgroundColor3 = disabledColor
        button.ImageButton.Border.ImageColor3 = unhighlightColor
    end)
end

local function updatePicker(button, h, s, v)
    local newColor = Color3.fromHSV(h, s, v)
    
    button.ImageButton.BackgroundColor3 = newColor
    if currentColorPickerButton == button then
        currentColorPicker.Frame.Button.PlaceholderText = math.floor(newColor.R * 255)..", "..math.floor(newColor.G * 255)..", "..math.floor(newColor.B * 255)
        currentColorPicker.Gradient.Cursor.Position = UDim2.new(math.clamp(s, 0, 1), 0, math.clamp(1 - v, 0, 1), 0)
        currentColorPicker.Gradient.UIGradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
            ColorSequenceKeypoint.new(1, Color3.fromHSV(h, 1, 1))
        }
    end
end

function Section:CreateColorPicker(config)
    --[[
        {
            name: string
            default: Color3?
            resetColor: Color3?
            callbackOnCreation: boolean?
            callback: () -> ()
        }
    ]]
    local colorPicker = guiAssets.ColorPickerButton:Clone()
    local default = config.default or Color3.new(1, 1, 1)
    local hue, saturation, value = default:ToHSV()

    colorPicker.TextLabel.Text = config.name
    colorPicker.TextLabel.Font = guiFont
    colorPicker.TextLabel.TextSize = fontSizes[guiFont]
    colorPicker.ImageButton.BackgroundColor3 = default
    colorPicker.Parent = self.section.Frame.Frame.Holder
    updateSizes(self.section)
    table.insert(allTexts,  colorPicker.TextLabel)

    if config.callbackOnCreation then
        spawnWithReuse(config.callback, default)
    end

    colorPicker.ImageButton.MouseEnter:Connect(function()
        colorPicker.ImageButton.Border.ImageColor3 = theme
    end)

    colorPicker.ImageButton.MouseLeave:Connect(function()
        if currentColorPickerButton ~= colorPicker then
            colorPicker.ImageButton.Border.ImageColor3 = disabledColor
        end
    end)

    if config.resetColor then
        colorPicker.ImageButton.MouseButton2Down:Connect(function()
            local h, s, v = config.resetColor:ToHSV()

            hue = h
            saturation = s
            value = v
            updatePicker(colorPicker, hue, saturation, value)
            config.callback(config.resetColor)
        end)
    end

    colorPicker.ImageButton.MouseButton1Down:Connect(function()
        if currentColorPickerButton == colorPicker then
            for i,v in pairs(colorPickerConnections) do
                v:Disconnect()
                colorPickerConnections[i] = nil
            end
            
            currentColorPickerButton.ImageButton.Border.ImageColor3 = disabledColor
            currentColorPickerButton = nil
            currentColorPicker:Destroy()
            return
        end

        if currentColorPickerButton then
            for i,v in pairs(colorPickerConnections) do
                v:Disconnect()
                colorPickerConnections[i] = nil
            end

            currentColorPickerButton.ImageButton.Border.ImageColor3 = disabledColor
            updatePicker(colorPicker, hue, saturation, value)
        else
            currentColorPickerButton = colorPicker
            currentColorPicker = guiAssets.ColorPicker:Clone()
            currentColorPicker.Position = UDim2.new(0, colorPicker.ImageButton.AbsolutePosition.X, 0, colorPicker.ImageButton.AbsolutePosition.Y + 65)
            currentColorPicker.Border.ImageColor3 = theme
            currentColorPicker.Slider.Border.ImageColor3 = theme
            currentColorPicker.Gradient.Border.ImageColor3 = theme
            currentColorPicker.Gradient.Cursor.Border.ImageColor3 = theme
            currentColorPicker.Frame.Button.Font = guiFont
            currentColorPicker.Frame.Button.TextSize = fontSizes[guiFont]
            currentColorPicker.Frame.Button.PlaceholderColor3 = theme
            currentColorPicker.Frame.Button.TextColor3 = theme
            updatePicker(colorPicker, hue, saturation, value)
            currentColorPicker.Visible = true

            currentColorPicker.Parent = mainGui
        end

        colorPickerConnections[#colorPickerConnections + 1] = RunService.Heartbeat:Connect(function()
            currentColorPicker.Position = UDim2.new(0, colorPicker.ImageButton.AbsolutePosition.X, 0, colorPicker.ImageButton.AbsolutePosition.Y + 65)
        end)

        colorPickerConnections[#colorPickerConnections + 1] = UserInputService.InputEnded:Connect(function(inputObject)
            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                for i, v in pairs(tempPickerConnections) do
                    v:Disconnect()
                    tempPickerConnections[i] = nil
                end
            end
        end)

        colorPickerConnections[#colorPickerConnections + 1] = currentColorPicker.Slider.MouseButton1Down:Connect(function(X, Y)
            hue = math.clamp((X - currentColorPicker.Slider.AbsolutePosition.X) / currentColorPicker.Slider.AbsoluteSize.X, 0, 1)
            updatePicker(colorPicker, hue, saturation, value)
            config.callback(Color3.fromHSV(hue, saturation, value))

            tempPickerConnections[#tempPickerConnections + 1] = UserInputService.InputChanged:Connect(function(inputObject)
                if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                    hue = math.clamp((inputObject.Position.X - currentColorPicker.Slider.AbsolutePosition.X) / currentColorPicker.Slider.AbsoluteSize.X, 0, 1)
                    updatePicker(colorPicker, hue, saturation, value)
                    config.callback(Color3.fromHSV(hue, saturation, value))
                end
            end)
        end)

        colorPickerConnections[#colorPickerConnections + 1] = currentColorPicker.Gradient.TextButton.MouseButton1Down:Connect(function(X, Y)
            local absoluteSize = currentColorPicker.Gradient.TextButton.AbsoluteSize
            local absolutePosition = currentColorPicker.Gradient.TextButton.AbsolutePosition

            saturation = math.clamp((X - absolutePosition.X) / absoluteSize.X, 0, 1)
            value = 1 - math.clamp(((Y - 36) - absolutePosition.Y) / absoluteSize.Y, 0, 1)
            updatePicker(colorPicker, hue, saturation, value)
            config.callback(Color3.fromHSV(hue, saturation, value))

            tempPickerConnections[#tempPickerConnections + 1] = UserInputService.InputChanged:Connect(function(inputObject)
                if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
                    saturation = math.clamp((inputObject.Position.X - absolutePosition.X) / absoluteSize.X, 0, 1)
                    value = 1 - math.clamp((inputObject.Position.Y - absolutePosition.Y) / absoluteSize.Y, 0, 1)
                    updatePicker(colorPicker, hue, saturation, value)
                    config.callback(Color3.fromHSV(hue, saturation, value))
                end
            end)
        end)

        colorPickerConnections[#colorPickerConnections + 1] = currentColorPicker.Frame.Button.FocusLost:Connect(function(enterPressed)
            if enterPressed then
                local color = string.split(string.gsub(currentColorPicker.Frame.Button.Text, " ", ""), ",")
                local h, s, v = Color3.fromRGB(color[1], color[2], color[3]):ToHSV()

                hue = h
                saturation = s
                value = v
                updatePicker(colorPicker, hue, saturation, value)
                config.callback(Color3.fromHSV(hue, saturation, value))
            end

            currentColorPicker.Frame.Button.Text = ""
        end)
    end)
end

local TextElement = {}
TextElement.__index = TextElement

function Section:CreateText(name)
    local textLabel = guiAssets.Slider:Clone()

    textLabel.TextLabel.Text = name
    textLabel.TextLabel.Size = UDim2.new(1, -15, 1, 0)
    textLabel.TextLabel.Font = guiFont
    textLabel.TextLabel.TextSize = fontSizes[guiFont]
    textLabel.Size = UDim2.new(1, 0, 0, 20)
    textLabel.Parent = self.section.Frame.Frame.Holder

    table.insert(allTexts,  textLabel.TextLabel)
    updateSizes(self.section)

    return setmetatable({
        textLabel = textLabel
    }, TextElement)
end

function TextElement:AddKeybind(config)
    --[[
        {
            default = {secondary bind, primary bind}
            callback = () -> ()?
            keyPressed = () -> ()
        }
    ]]

    self.callback = config.keyPressed
    makeKeybind(self.textLabel, self, config)
end

local DropdownElement = {}
DropdownElement.__index = DropdownElement

function Section:CreateDropDown(config)
    --[[
        {   
            name: string
            default: string?
            options: {}
            callback: () -> ()
        }
    ]]
    local dropTable = {}

    dropTable.options = 0
    dropTable.selected = false
    dropTable.opened = false
    dropTable.dropdown = guiAssets.Dropdown:Clone()
    dropTable.callback = config.callback
    
    dropTable.dropdown.Frame.TextLabel.Text = config.name
    dropTable.dropdown.Frame.TextLabel.Font = guiFont
    dropTable.dropdown.Frame.TextLabel.TextSize = fontSizes[guiFont]
    dropTable.dropdown.Parent = self.section.Frame.Frame.Holder
    dropTable.dropdown.Main.ImageButton.ImageButton.ImageLabel.ImageColor3 = theme
    dropTable.dropdown.Main.ImageButton.ImageButton.Font = guiFont
    dropTable.dropdown.Main.ImageButton.ImageButton.TextSize = fontSizes[guiFont]
    dropTable.dropdown.Main.Seperator.ImageColor3 = theme
    table.insert(dropDowns, dropTable.dropdown)
    table.insert(borders, dropTable.dropdown.Main.ImageButton.ImageButton.ImageLabel)
    table.insert(borders, dropTable.dropdown.Main.Seperator)
    table.insert(text, dropTable.dropdown.Main.ImageButton.ImageButton)
    table.insert(allTexts, dropTable.dropdown.Main.ImageButton.ImageButton)
    table.insert(allTexts, dropTable.dropdown.Frame.TextLabel)
    updateSizes(self.section)

    dropTable.dropdown.Main.ImageButton.MouseEnter:Connect(function()
        dropTable.dropdown.Main.Border.ImageColor3 = theme
    end)

    dropTable.dropdown.Main.ImageButton.MouseLeave:Connect(function()
        if not dropTable.opened then
            dropTable.dropdown.Main.Border.ImageColor3 = unhighlightColor
        end
    end)

    dropTable.dropdown.Main.ImageButton.MouseButton1Down:Connect(function()
        dropTable.opened = not dropTable.opened

        if dropTable.opened then
            dropTable.dropdown.Main.ImageButton.ImageButton.ImageLabel.Image = "http://www.roblox.com/asset/?id=13337486257"
            dropTable.dropdown.Main.Seperator.Visible = true
            dropTable.dropdown.Main.Options.Visible = true
            dropTable.dropdown.Size = UDim2.new(1, 0, 0, math.min(31 + (15 * dropTable.options), 106))
            dropTable.dropdown.Main.Size = UDim2.new(1, -8, 0, math.min(16 + (15 * dropTable.options), 90))

            if dropTable.options > 5 then
                dropTable.dropdown.Main.Options.CanvasSize = UDim2.new(0, 0, 0, dropTable.dropdown.Main.Options.UIListLayout.AbsoluteContentSize.Y + 1)
            else
                dropTable.dropdown.Main.Options.CanvasSize = UDim2.new()
            end
        else
            dropTable.dropdown.Main.ImageButton.ImageButton.ImageLabel.Image = "http://www.roblox.com/asset/?id=13337479807"
            dropTable.dropdown.Main.Seperator.Visible = false
            dropTable.dropdown.Main.Options.Visible = false
            dropTable.dropdown.Size = UDim2.new(1, 0, 0, 30)
            dropTable.dropdown.Main.Size = UDim2.new(1, -8, 0, 15)
        end

        updateSizes(self.section)
    end)

    local hasDefault = false

    if config.default then
        for i,v in pairs(config.options) do
            if v == config.default then
                hasDefault = true
            end
        end
    end
    
    for i,v in pairs(config.options) do
        local option = guiAssets.Option:Clone()
        option.Text = v
        option.Font = guiFont
        option.TextSize = fontSizes[guiFont]
        option.TextColor3 = dropUnselectedColor
        option.Parent = dropTable.dropdown.Main.Options
        dropTable.options += 1

        table.insert(allTexts, option)

        if v == config.default then
            dropTable.selected = option
            dropTable.dropdown.Main.ImageButton.ImageButton.Text = v
            option.TextColor3 = theme
        elseif not hasDefault and not dropTable.selected then
            dropTable.selected = option
            option.TextColor3 = theme
            dropTable.dropdown.Main.ImageButton.ImageButton.Text = v
            spawnWithReuse(config.callback, v)
        end

        option.MouseEnter:Connect(function()
            option.TextColor3 = theme
        end)

        option.MouseLeave:Connect(function()
            if dropTable.selected ~= option then
                option.TextColor3 = dropUnselectedColor
            end
        end)

        option.MouseButton1Down:Connect(function()
            if dropTable.selected ~= option then
                if dropTable.selected then
                    dropTable.selected.TextColor3 = dropUnselectedColor
                end

                dropTable.selected = option
                option.TextColor3 = theme
                dropTable.dropdown.Main.ImageButton.ImageButton.Text = v
                config.callback(v)
            end
        end)
    end

    return setmetatable(dropTable, DropdownElement)
end

function DropdownElement:Add(optionText)
    local option = guiAssets.Option:Clone()
    option.Text = optionText
    option.Font = guiFont
    option.TextSize = fontSizes[guiFont]
    option.TextColor3 = dropUnselectedColor
    option.Parent = self.dropdown.Main.Options
    self.options += 1

    if self.opened and self.options > 5 then
        self.dropdown.Main.Options.CanvasSize = UDim2.new(0, 0, 0, self.dropdown.Main.Options.UIListLayout.AbsoluteContentSize.Y + 1)
    end

    table.insert(allTexts, option)

    option.MouseEnter:Connect(function()
        option.TextColor3 = theme
    end)

    option.MouseLeave:Connect(function()
        if self.selected ~= option then
            option.TextColor3 = dropUnselectedColor
        end
    end)

    option.MouseButton1Down:Connect(function()
        if self.selected ~= option then
            self.selected.TextColor3 = dropUnselectedColor
            self.selected = option
            option.TextColor3 = theme
            self.dropdown.Main.ImageButton.ImageButton.Text = optionText
            self.callback(optionText)
        end
    end)
end

function DropdownElement:Remove(option)
    local destroyed = false
    local newSelected

    for i,v in pairs(self.dropdown.Main.Options:GetChildren()) do
        if v:IsA("TextButton") and v.Text == option then
            destroyed = v
        else
            newSelected = v
        end

        if newSelected and destroyed then
            break
        end
    end

    if destroyed then
        if newSelected and self.selected == destroyed then
            self.selected = newSelected
            self.selected.TextColor3 = theme
            self.dropdown.Main.ImageButton.ImageButton.Text = newSelected.Text

            spawnWithReuse(self.callback, newSelected.Text)
        end

        table.insert(allTexts, destroyed)
        destroyed:Destroy()
        self.options -= 1

        if self.opened then
            self.dropdown.Size = UDim2.new(1, 0, 0, math.min(31 + (15 * self.options), 106))
            self.dropdown.Main.Size = UDim2.new(1, -8, 0, math.min(16 + (15 * self.options), 90))

            if self.options > 5 then
                self.dropdown.Main.Options.CanvasSize = UDim2.new(0, 0, 0, self.dropdown.Main.Options.UIListLayout.AbsoluteContentSize.Y + 1)
            else
                self.dropdown.Main.Options.CanvasSize = UDim2.new(0, 0, 0, 0)
            end
        end
    end
end

function Section:CreateTextbox(config)
    --[[
        {
            name: string
            placeholderText: string
            callback: () -> ()
        }
    ]]

    local textBox = guiAssets.Textbox:Clone()
    local typing = false
    
    textBox.TextLabel.Text = config.name
    textBox.TextLabel.Font = guiFont
    textBox.TextLabel.TextSize = fontSizes[guiFont]
    textBox.Frame.Textbox.PlaceholderText = config.placeholderText
    textBox.Frame.Textbox.Font = guiFont
    textBox.Frame.Textbox.TextSize = fontSizes[guiFont]
    textBox.Frame.Textbox.TextColor3 = theme
    textBox.Parent = self.section.Frame.Frame.Holder

    table.insert(allTexts, textBox.TextLabel)
    table.insert(allTexts, textBox.Frame.Textbox)
    table.insert(text, textBox.Frame.Textbox)
    updateSizes(self.section)

    textBox.Frame.MouseEnter:Connect(function()
        textBox.Frame.Border.ImageColor3 = theme
    end)

    textBox.Frame.MouseLeave:Connect(function()
        if not typing then
            textBox.Frame.Border.ImageColor3 = unhighlightColor
        end
    end)

    textBox.Frame.Textbox.Focused:Connect(function()
        typing = true
    end)

    textBox.Frame.Textbox.FocusLost:Connect(function(enterPressed)
        textBox.Frame.Border.ImageColor3 = unhighlightColor
        typing = false

        if enterPressed then
            local input = string.gsub(textBox.Frame.Textbox.Text, "^%s+", "")
            textBox.Frame.Textbox.Text = ""
            if input ~= "" then
                textBox.Frame.Textbox.PlaceholderText = input
                config.callback(input)
            end
        end
    end)
end

return UiLibrary
