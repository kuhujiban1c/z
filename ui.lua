-- StarterPlayerScripts / DevTools_Ultimate_Glass.lua
-- Ultimate Redesign: Glassmorphism & Modern Sidebar
-- Version 2.0 (Stable & Optimized)

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Config & Colors
local THEME = {
    Bg = Color3.fromRGB(11, 14, 17),
    Accent = Color3.fromRGB(0, 229, 255),
    Sidebar = Color3.fromRGB(16, 20, 24),
    Text = Color3.fromRGB(225, 232, 240),
    TextDim = Color3.fromRGB(140, 150, 160)
}

-- State Management
local state = {
    speed = 16, jump = 50, noclip = false, infiniteJump = false,
    esp = false, nightVision = false, fov = 70, clockTime = 12
}

local backup = {
    Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient, GlobalShadows = Lighting.GlobalShadows
}

-- Helpers
local function getCharHum()
    local char = player.Character
    return char, (char and char:FindFirstChildOfClass("Humanoid"))
end

local function createTween(obj, info, goal)
    local t = TweenService:Create(obj, TweenInfo.new(info), goal)
    t:Play()
    return t
end

-- =============== UI CONSTRUCTION ===============
local gui = Instance.new("ScreenGui")
gui.Name = "GlassDevTools"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- Main Container
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, 600, 0, 400)
main.Position = UDim2.new(0.5, -300, 0.5, -200)
main.BackgroundColor3 = THEME.Bg
main.BackgroundTransparency = 0.15
main.Visible = false
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke", main)
stroke.Color = THEME.Accent
stroke.Thickness = 1.2
stroke.Transparency = 0.5

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 160, 1, 0)
sidebar.BackgroundColor3 = THEME.Sidebar
sidebar.BackgroundTransparency = 0.1
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 16)

local sideTitle = Instance.new("TextLabel")
sideTitle.Size = UDim2.new(1, 0, 0, 50)
sideTitle.Text = "DEVTOOLS"
sideTitle.TextColor3 = THEME.Accent
sideTitle.Font = Enum.Font.GothamBold
sideTitle.TextSize = 18
sideTitle.BackgroundTransparency = 1
sideTitle.Parent = sidebar

local tabList = Instance.new("UIListLayout", sidebar)
tabList.Padding = UDim.new(0, 5)
tabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- Content Container
local content = Instance.new("Frame")
content.Position = UDim2.new(0, 170, 0, 15)
content.Size = UDim2.new(1, -185, 1, -30)
content.BackgroundTransparency = 1
content.Parent = main

-- Toggle Switch Logic
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 45, 0, 45)
toggleBtn.Position = UDim2.new(1, -60, 0, 20)
toggleBtn.BackgroundColor3 = THEME.Bg
toggleBtn.Text = "🛠"
toggleBtn.TextColor3 = THEME.Accent
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = gui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 12)

toggleBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

-- Tab Builder
local sections = {}
local function makeSection(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.85, 0, 0, 35)
    btn.BackgroundColor3 = THEME.Accent
    btn.BackgroundTransparency = 1
    btn.Text = " " .. icon .. "  " .. name
    btn.TextColor3 = THEME.TextDim
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.TextXAlignment = Enum.TextXAlignment.Left
    btn.Parent = sidebar
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)

    local secFrame = Instance.new("ScrollingFrame")
    secFrame.Size = UDim2.new(1, 0, 1, 0)
    secFrame.BackgroundTransparency = 1
    secFrame.BorderSizePixel = 0
    secFrame.ScrollBarThickness = 2
    secFrame.Visible = false
    secFrame.Parent = content
    
    local layout = Instance.new("UIListLayout", secFrame)
    layout.Padding = UDim.new(0, 10)
    
    sections[name] = secFrame
    
    btn.MouseButton1Click:Connect(function()
        for _, s in pairs(sections) do s.Visible = false end
        for _, b in ipairs(sidebar:GetChildren()) do 
            if b:IsA("TextButton") then b.TextColor3 = THEME.TextDim b.BackgroundTransparency = 1 end 
        end
        secFrame.Visible = true
        btn.TextColor3 = Color3.new(1,1,1)
        btn.BackgroundTransparency = 0.8
    end)
    
    return secFrame
end

-- Component Builders
local function makeButton(parent, text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 35)
    b.BackgroundColor3 = THEME.Accent
    b.BackgroundTransparency = 0.85
    b.Text = text
    b.TextColor3 = THEME.Text
    b.Font = Enum.Font.Gotham
    b.TextSize = 14
    b.Parent = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
    
    b.MouseEnter:Connect(function() createTween(b, 0.2, {BackgroundTransparency = 0.7}) end)
    b.MouseLeave:Connect(function() createTween(b, 0.2, {BackgroundTransparency = 0.85}) end)
    b.MouseButton1Click:Connect(callback)
    return b
end

local function makeSlider(parent, text, min, max, def, callback)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(1, -10, 0, 50)
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Text = text .. " (" .. def .. ")"
    label.TextColor3 = THEME.TextDim
    label.Font = Enum.Font.Gotham
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.BackgroundTransparency = 1
    label.Parent = holder
    
    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(1, 0, 0, 6)
    bar.Position = UDim2.new(0, 0, 0, 30)
    bar.BackgroundColor3 = Color3.new(0.2, 0.2, 0.2)
    bar.Parent = holder
    Instance.new("UICorner", bar)
    
    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((def - min)/(max - min), 0, 1, 0)
    fill.BackgroundColor3 = THEME.Accent
    fill.Parent = bar
    Instance.new("UICorner", fill)

    local function update(input)
        local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * pos)
        fill.Size = UDim2.new(pos, 0, 1, 0)
        label.Text = text .. " (" .. val .. ")"
        callback(val)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local connection
            connection = UIS.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then update(input) end
            end)
            UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then connection:Disconnect() end
            end)
            update(input)
        end
    end)
end

-- =============== FILLING TABS ===============
local moveTab = makeSection("Move", "🚀")
local visTab  = makeSection("Vis", "👁")
local worldTab = makeSection("World", "🌍")

-- MOVEMENT
makeSlider(moveTab, "Speed", 16, 250, state.speed, function(v)
    state.speed = v
    local _, hum = getCharHum()
    if hum then hum.WalkSpeed = v end
end)

makeButton(moveTab, "Noclip: OFF", function(b)
    state.noclip = not state.noclip
    b.Text = "Noclip: " .. (state.noclip and "ON ✅" or "OFF")
end)

-- VISUALS
makeButton(visTab, "Night Vision: OFF", function(b)
    state.nightVision = not state.nightVision
    b.Text = "Night Vision: " .. (state.nightVision and "ON 🌙" or "OFF")
    if state.nightVision then
        Lighting.Brightness = 3
        Lighting.Ambient = Color3.fromRGB(150, 150, 150)
    else
        Lighting.Brightness = backup.Brightness
        Lighting.Ambient = backup.Ambient
    end
end)

-- WORLD
makeSlider(worldTab, "Clock Time", 0, 24, state.clockTime, function(v)
    Lighting.ClockTime = v
end)

-- LOOPS
RS.Stepped:Connect(function()
    if state.noclip then
        local char = player.Character
        if char then
            for _, p in ipairs(char:GetChildren()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- Initial Selection
sections["Move"].Visible = true
sidebar:FindFirstChildOfClass("TextButton").TextColor3 = Color3.new(1,1,1)

-- Drag Logic
local dragging, dragInput, dragStart, startPos
main.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true dragStart = input.Position startPos = main.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then dragging = false end
		end)
	end
end)
UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

Dek Anda mengenai evolusi visual DevTools siap untuk dipresentasikan! Kabari saya jika ada fitur spesifik lain yang ingin Anda tambahkan ke desainnya.