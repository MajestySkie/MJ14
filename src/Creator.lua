local Root = script.Parent
local Themes = require(Root.Themes)
local Flipper = require(Root.Packages.Flipper)

local Creator = {
    Registry = {},
    Signals = {},
    TransparencyMotors = {},
    DefaultProperties = {
        ScreenGui = {
            ResetOnSpawn = false,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        },
        Frame = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
        ScrollingFrame = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ScrollBarImageColor3 = Color3.new(0, 0, 0),
        },
        TextLabel = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            BackgroundTransparency = 1,
            TextSize = 14,
        },
        TextButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            AutoButtonColor = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14,
        },
        TextBox = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            ClearTextOnFocus = false,
            Font = Enum.Font.SourceSans,
            Text = "",
            TextColor3 = Color3.new(0, 0, 0),
            TextSize = 14,
        },
        ImageLabel = {
            BackgroundTransparency = 1,
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
        ImageButton = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            AutoButtonColor = false,
        },
        CanvasGroup = {
            BackgroundColor3 = Color3.new(1, 1, 1),
            BorderColor3 = Color3.new(0, 0, 0),
            BorderSizePixel = 0,
        },
    },
}

local function ApplyCustomProps(Object, Props)
    if Props.ThemeTag then
        Creator.AddThemeObject(Object, Props.ThemeTag)
    end
end

function Creator.AddSignal(Signal, Function)
    table.insert(Creator.Signals, Signal:Connect(Function))
end

function Creator.Disconnect()
    for Idx = #Creator.Signals, 1, -1 do
        local Connection = table.remove(Creator.Signals, Idx)
        Connection:Disconnect()
    end
end

function Creator.GetThemeProperty(Property)
    if Themes[require(Root).Theme][Property] then
        return Themes[require(Root).Theme][Property]
    end
    return Themes["Dark"][Property]
end

function Creator.UpdateTheme()
    for Instance, Object in next, Creator.Registry do
        for Property, ColorIdx in next, Object.Properties do
            Instance[Property] = Creator.GetThemeProperty(ColorIdx)
        end
    end

    for _, Motor in next, Creator.TransparencyMotors do
        Motor:setGoal(Flipper.Instant.new(Creator.GetThemeProperty("ElementTransparency")))
    end
end

function Creator.AddThemeObject(Object, Properties)
    local Idx = #Creator.Registry + 1
    local Data = {
        Object = Object,
        Properties = Properties,
        Idx = Idx,
    }

    Creator.Registry[Object] = Data
    Creator.UpdateTheme()
    return Object
end

function Creator.OverrideTag(Object, Properties)
    Creator.Registry[Object].Properties = Properties
    Creator.UpdateTheme()
end

function Creator.New(Name, Properties, Children)
    local Object = Instance.new(Name)

    -- Default properties
    for Name, Value in next, Creator.DefaultProperties[Name] or {} do
        Object[Name] = Value
    end

    -- Properties
    for Name, Value in next, Properties or {} do
        if Name ~= "ThemeTag" then
            Object[Name] = Value
        end
    end

    -- Children
    for _, Child in next, Children or {} do
        Child.Parent = Object
    end

    ApplyCustomProps(Object, Properties)
    return Object
end

function Creator.SpringMotor(Initial, Instance, Prop, IgnoreDialogCheck, ResetOnThemeChange)
    IgnoreDialogCheck = IgnoreDialogCheck or false
    ResetOnThemeChange = ResetOnThemeChange or false
    local Motor = Flipper.SingleMotor.new(Initial)
    Motor:onStep(function(value)
        Instance[Prop] = value
    end)

    if ResetOnThemeChange then
        table.insert(Creator.TransparencyMotors, Motor)
    end

    local function SetValue(Value, Ignore)
        Ignore = Ignore or false
        if not IgnoreDialogCheck then
            if not Ignore then
                if Prop == "BackgroundTransparency" and require(Root).DialogOpen then
                    return
                end
            end
        end
        Motor:setGoal(Flipper.Spring.new(Value, { frequency = 8 }))
    end

    return Motor, SetValue
end

-- Fungsi Tambahan: Dragable Image
function Creator.CreateDragableImage(parent, assetId, size, position, onClick)
    local dragButton = Instance.new("ImageButton")
    dragButton.Size = UDim2.new(0, size.X, 0, size.Y)
    dragButton.Position = UDim2.new(position.X.Scale, position.X.Offset, position.Y.Scale, position.Y.Offset)
    dragButton.Image = "rbxassetid://" .. assetId
    dragButton.BackgroundTransparency = 1
    dragButton.Parent = parent

    local dragging = false
    local dragStart, startPos

    dragButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = dragButton.Position
        end
    end)

    dragButton.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            dragButton.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    dragButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    dragButton.MouseButton1Click:Connect(function()
        if not dragging then
            onClick()
        end
    end)

    return dragButton
end

return Creator
