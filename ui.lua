-- StarterPlayerScripts / DevTools_Ultimate_V3_Scroll.lua
-- Ultimate Redesign V3: Infinite Scrolling & Feature Expansion
-- Optimized for Performance and UX

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Theme Config
local THEME = {
    Bg = Color3.fromRGB(11, 14, 17),
    Accent = Color3.fromRGB(0, 229, 255),
    Sidebar = Color3.fromRGB(16, 20, 24),
    Text = Color3.fromRGB(225, 232, 240),
    TextDim = Color3.fromRGB(140, 150, 160)
}

-- Comprehensive State
local state = {
    speed = 16, jump = 50, noclip = false, infiniteJump = false,
    esp = false, nightVision = false, fov = 70, fly = false, flySpeed = 50,
    antiAFK = true, seatWipe = false
}

local backup = {
    Brightness = Lighting.Brightness, Ambient = Lighting.Ambient
}

-- Helpers
local function getCharHum()
    local char = player.Character
    return char, (char and char:FindFirstChildOfClass("Humanoid"))
end

local function notify(txt)
    print("[DevTools]: " .. txt)
end

-- =============== UI CONSTRUCTION ===============
local gui = Instance.new("ScreenGui")
gui.Name = "GlassDevToolsV3"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 620, 0, 420)
main.Position = UDim2.new(0.5, -310, 0.5, -210)
main.BackgroundColor3 = THEME.Bg
main.BackgroundTransparency = 0.1
main.Visible = false
main.Parent = gui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 16)
Instance.new("UIStroke", main).Color = THEME.Accent

-- Sidebar
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 150, 1, 0)
sidebar.BackgroundColor3 = THEME.Sidebar
sidebar.Parent = main
Instance.new("UICorner", sidebar).CornerRadius = UDim.new(0, 16)

local list = Instance.new("UIListLayout", sidebar)
list.Padding = UDim.new(0, 5)
list.HorizontalAlignment = "Center"

-- Content Wrapper (PENTING: Ini batas scrolling)
local contentArea = Instance.new("Frame")
contentArea.Position = UDim2.new(0, 160, 0, 15)
contentArea.Size = UDim2.new(1, -175, 1, -30)
contentArea.BackgroundTransparency = 1
contentArea.ClipsDescendants = true -- Agar konten tidak keluar batas
contentArea.Parent = main

-- Tab Builder dengan Scrolling logic
local tabs = {}
local function makeTab(name, icon)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 40)
    btn.Text = icon .. " " .. name
    btn.BackgroundColor3 = THEME.Accent
    btn.BackgroundTransparency = 1
    btn.TextColor3 = THEME.TextDim
    btn.Font = "GothamMedium"
    btn.TextSize = 14
    btn.Parent = sidebar
    Instance.new("UICorner", btn)

    -- ScrollingFrame Utama
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 2
    sf.ScrollBarImageColor3 = THEME.Accent
    sf.CanvasSize = UDim2.new(0, 0, 0, 0) -- Akan otomatis update
    sf.Visible = false
    sf.Parent = contentArea
    
    local layout = Instance.new("UIListLayout", sf)
    layout.Padding = UDim.new(0, 10)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        sf.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 20)
    end)

    tabs[name] = {btn = btn, frame = sf}

    btn.MouseButton1Click:Connect(function()
        for n, t in pairs(tabs) do
            t.frame.Visible = (n == name)
            t.btn.TextColor3 = (n == name) and Color3.new(1,1,1) or THEME.TextDim
            t.btn.BackgroundTransparency = (n == name) and 0.8 or 1
        end
    end)
    return sf
end

-- Component Builders
local function makeToggle(parent, text, callback)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -10, 0, 40)
    b.BackgroundColor3 = THEME.Accent
    b.BackgroundTransparency = 0.9
    b.Text = text
    b.TextColor3 = THEME.Text
    b.Font = "Gotham"
    b.TextSize = 13
    b.Parent = parent
    Instance.new("UICorner", b)
    b.MouseButton1Click:Connect(function()
        callback(b)
    end)
end

-- =============== FILLING CONTENT ===============
local move = makeTab("Movement", "🚀")
local visual = makeTab("Visual", "👁")
local util = makeTab("Utility", "🛠")

-- MOVEMENT TAB (Banyak Fitur)
makeToggle(move, "Fly: OFF", function(b)
    state.fly = not state.fly
    b.Text = "Fly: " .. (state.fly and "ON ✅" or "OFF")
    -- Logika Fly ada di Loop Stepped
end)

makeToggle(move, "Infinite Jump: OFF", function(b)
    state.infiniteJump = not state.infiniteJump
    b.Text = "Inf Jump: " .. (state.infiniteJump and "ON ✅" or "OFF")
end)

makeToggle(move, "Noclip: OFF", function(b)
    state.noclip = not state.noclip
    b.Text = "Noclip: " .. (state.noclip and "ON ✅" or "OFF")
end)

makeToggle(move, "Click Teleport (Ctrl+Click)", function(b)
    notify("Teleport active")
end)

-- VISUAL TAB
makeToggle(visual, "ESP Players: OFF", function(b)
    state.esp = not state.esp
    b.Text = "ESP: " .. (state.esp and "ON ✅" or "OFF")
    -- Refresh ESP logic
end)

makeToggle(visual, "Night Vision", function(b)
    state.nightVision = not state.nightVision
    Lighting.Brightness = state.nightVision and 3 or backup.Brightness
end)

-- UTILITY TAB
makeToggle(util, "Anti-AFK: ON", function(b)
    state.antiAFK = not state.antiAFK
    b.Text = "Anti-AFK: " .. (state.antiAFK and "ON ✅" or "OFF")
end)

makeToggle(util, "Clear Lag (Destroy Decals)", function(b)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Decal") or v:IsA("Texture") then v:Destroy() end
    end
    notify("Textures cleared")
end)

makeToggle(util, "Seat Destroyer", function(b)
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Seat") then v:Destroy() end
    end
end)

-- =============== CORE LOGIC ===============

-- Fly & Noclip Loop
RS.Stepped:Connect(function()
    local char, hum = getCharHum()
    if not char or not hum then return end
    
    if state.noclip then
        for _, p in pairs(char:GetChildren()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
    
    if state.fly then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local moveDir = hum.MoveDirection
            local camCF = Camera.CFrame
            hrp.Velocity = Vector3.new(0,0,0) -- Stop physics
            
            local velocity = Vector3.new(0,0,0)
            if UIS:IsKeyDown(Enum.KeyCode.W) then velocity += camCF.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.S) then velocity -= camCF.LookVector end
            if UIS:IsKeyDown(Enum.KeyCode.A) then velocity -= camCF.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.D) then velocity += camCF.RightVector end
            if UIS:IsKeyDown(Enum.KeyCode.Space) then velocity += Vector3.new(0,1,0) end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then velocity -= Vector3.new(0,1,0) end
            
            hrp.CFrame = hrp.CFrame + (velocity * (state.flySpeed / 60))
        end
    end
end)

-- Teleport Click (Ctrl + Mouse1)
UIS.InputBegan:Connect(function(input, gpe)
    if not gpe and input.UserInputType == Enum.UserInputType.MouseButton1 and UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
        local char = player.Character
        if char and mouse.Target then
            char:MoveTo(mouse.Hit.p + Vector3.new(0, 3, 0))
        end
    end
end)

-- Anti-AFK
player.Idled:Connect(function()
    if state.antiAFK then
        local virtualUser = game:GetService("VirtualUser")
        virtualUser:CaptureController()
        virtualUser:ClickButton2(Vector2.new())
    end
end)

-- UI Toggle & Init
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 50, 0, 50)
openBtn.Position = UDim2.new(1, -70, 0.5, 0)
openBtn.Text = "🛠"
openBtn.BackgroundColor3 = THEME.Bg
openBtn.TextColor3 = THEME.Accent
openBtn.Parent = gui
Instance.new("UICorner", openBtn)

openBtn.MouseButton1Click:Connect(function()
    main.Visible = not main.Visible
end)

-- Start at Movement Tab
tabs["Movement"].btn.TextColor3 = Color3.new(1,1,1)
tabs["Movement"].frame.Visible = true

notify("V3 Loaded Successfully")
