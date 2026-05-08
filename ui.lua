-- StarterPlayerScripts / DevTools_ClientUltimateEnhanced.lua
-- Ultimate Client Dev Tools with Advanced Features & AI
-- UI Updated Version

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local Camera = workspace.CurrentCamera

local player = Players.LocalPlayer
local function getCharHum()
	local c = player.Character or player.CharacterAdded:Wait()
	local h = c:WaitForChild("Humanoid")
	return c, h
end

-- =============== STATE ===============
local state = {
	speed = 16, jump = 50, noclip = false, fly = false, infiniteJump = false,
	flyMult = 2, esp = false, rainbow = false, nightVision = false, fov = 70,
	gravity = workspace.Gravity, clockTime = Lighting.ClockTime or 12,
	reduceLag = false, antiAFK = false, xray = false
}

local backup = {
	Brightness = Lighting.Brightness, Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient, FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows, Technology = Lighting.Technology
}

local advanced = {
	xrayParts = {}
}

-- =============== UI FACTORY ===============
local gui = Instance.new("ScreenGui")
gui.Name = "ClientDevToolsEnhanced"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

-- Toggle Button
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 56, 0, 40)
toggleBtn.Position = UDim2.new(1, -70, 0.5, 0)
toggleBtn.BackgroundColor3 = Color3.fromRGB(45,45,45)
toggleBtn.Text = "🛠️"
toggleBtn.TextColor3 = Color3.new(1,1,1)
toggleBtn.TextSize = 22
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.Parent = gui
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 8)

-- Main Frame
local main = Instance.new("Frame")
main.Size = UDim2.new(0, 520, 0, 420)
main.Position = UDim2.new(0.5, -260, 0.5, -210)
main.BackgroundColor3 = Color3.fromRGB(24,24,28)
main.BorderSizePixel = 0
main.Visible = false
main.Active = true
main.Parent = gui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(60,60,70)
stroke.Thickness = 1

local padding = Instance.new("UIPadding", main)
padding.PaddingTop = UDim.new(0, 12)
padding.PaddingBottom = UDim.new(0, 12)
padding.PaddingLeft = UDim.new(0, 12)
padding.PaddingRight = UDim.new(0, 12)

-- Manual Draggable logic
do
	local dragging, dragStart, startPos
	local function updateMain(input)
		local delta = input.Position - dragStart
		main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
	main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true dragStart = input.Position startPos = main.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)
	
	local toggleDragging, toggleDragStart, toggleStartPos
	local function updateToggle(input)
		local delta = input.Position - toggleDragStart
		toggleBtn.Position = UDim2.new(toggleStartPos.X.Scale, toggleStartPos.X.Offset + delta.X, toggleStartPos.Y.Scale, toggleStartPos.Y.Offset + delta.Y)
	end
	toggleBtn.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			toggleDragging = true toggleDragStart = input.Position toggleStartPos = toggleBtn.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then toggleDragging = false end
			end)
		end
	end)
	
	UIS.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then updateMain(input) end
			if toggleDragging then updateToggle(input) end
		end
	end)
end

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -44, 0, 28)
title.BackgroundTransparency = 1
title.Text = "Ultimate AI Dev Tools"
title.TextColor3 = Color3.fromRGB(255,255,255)
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = main

local close = Instance.new("TextButton")
close.Size = UDim2.new(0, 32, 0, 32)
close.Position = UDim2.new(1, -32, 0, -4)
close.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
close.Text = "×"
close.TextColor3 = Color3.new(1,1,1)
close.Font = Enum.Font.GothamBold
close.TextSize = 18
close.Parent = main
Instance.new("UICorner", close).CornerRadius = UDim.new(0, 8)

close.MouseButton1Click:Connect(function() main.Visible = false end)
toggleBtn.MouseButton1Click:Connect(function() main.Visible = not main.Visible end)

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1, 0, 0, 38)
tabBar.Position = UDim2.new(0, 0, 0, 32)
tabBar.BackgroundColor3 = Color3.fromRGB(32,32,38)
tabBar.BorderSizePixel = 0
tabBar.Parent = main
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 10)

-- Agar Tab tidak mentok keluar saat ada banyak menu, pakai ScrollingFrame
local tabScroller = Instance.new("ScrollingFrame")
tabScroller.Size = UDim2.new(1, 0, 1, 0)
tabScroller.BackgroundTransparency = 1
tabScroller.BorderSizePixel = 0
tabScroller.ScrollBarThickness = 0
tabScroller.CanvasSize = UDim2.new(0, 0, 0, 0)
tabScroller.Parent = tabBar

local tabPad = Instance.new("UIPadding", tabScroller)
tabPad.PaddingLeft = UDim.new(0, 8)
tabPad.PaddingRight = UDim.new(0, 8)

local tabLayout = Instance.new("UIListLayout", tabScroller)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0, 6)
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center

tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	tabScroller.CanvasSize = UDim2.new(0, tabLayout.AbsoluteContentSize.X + 16, 0, 0)
end)

local content = Instance.new("Frame")
content.Size = UDim2.new(1, 0, 1, -82)
content.Position = UDim2.new(0, 0, 0, 82)
content.BackgroundTransparency = 1
content.Parent = main

local function makeTab(name)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0, 80, 0, 28)
	b.BackgroundColor3 = Color3.fromRGB(46,46,54)
	b.Text = name
	b.TextColor3 = Color3.fromRGB(235,235,235)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 11
	b.BorderSizePixel = 0
	b.Parent = tabScroller
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
	return b
end

local function makeSection()
	local s = Instance.new("ScrollingFrame")
	s.Size = UDim2.new(1, 0, 1, 0)
	s.BackgroundTransparency = 1
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 4
	s.ScrollBarImageColor3 = Color3.fromRGB(80,80,90)
	s.Visible = false
	s.CanvasSize = UDim2.new(0,0,0,0)
	s.Parent = content

	local pad = Instance.new("UIPadding", s)
	pad.PaddingRight = UDim.new(0, 4)

	local layout = Instance.new("UIListLayout", s)
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		s.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
	end)

	return s
end

local function makeButton(parent, text, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1, 0, 0, 36)
	b.BackgroundColor3 = color or Color3.fromRGB(54,54,62)
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255,255,255)
	b.Font = Enum.Font.Gotham
	b.TextSize = 14
	b.BorderSizePixel = 0
	b.Parent = parent
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)

	local st = Instance.new("UIStroke", b)
	st.Color = Color3.fromRGB(75,75,85)
	st.Thickness = 1

	return b
end

local function makeSlider(parent, labelText, min, max, default, onChange)
	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(1, 0, 0, 54)
	holder.BackgroundTransparency = 1
	holder.Parent = parent

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 20)
	label.BackgroundTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = Color3.fromRGB(220,220,220)
	label.Font = Enum.Font.Gotham
	label.TextSize = 12
	label.Text = labelText .. " (" .. default .. ")"
	label.Parent = holder

	local bar = Instance.new("Frame")
	bar.Size = UDim2.new(1, 0, 0, 18)
	bar.Position = UDim2.new(0, 0, 0, 28)
	bar.BackgroundColor3 = Color3.fromRGB(42,42,48)
	bar.BorderSizePixel = 0
	bar.Parent = holder
	Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 8)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
	fill.BackgroundColor3 = Color3.fromRGB(90, 130, 255)
	fill.BorderSizePixel = 0
	fill.Parent = bar
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 8)

	local dragging = false
	local function setValue(x)
		local rel = math.clamp((x - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
		local val = math.floor(min + (max - min) * rel + 0.5)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		label.Text = labelText .. " (" .. val .. ")"
		if onChange then onChange(val) end
	end

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setValue(input.Position.X)
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			setValue(input.Position.X)
		end
	end)

	if onChange then onChange(default) end
end

-- =============== TABS SETUP ===============
local tabMovement   = makeTab("Movement")
local tabVisual     = makeTab("Visual")
local tabWorld      = makeTab("World")
local tabUtility    = makeTab("Utility")

local secMove  = makeSection()
local secVis   = makeSection()
local secWorld = makeSection()
local secUtil  = makeSection()

local function showSection(sec)
	for _, child in ipairs(content:GetChildren()) do
		if child:IsA("ScrollingFrame") then 
			child.Visible = (child == sec)
		end
	end
	
	-- Reset warna Tab
	for _, b in ipairs(tabScroller:GetChildren()) do
		if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(46,46,54) end
	end
	
	-- Warna Aktif
	local activeColor = Color3.fromRGB(90, 130, 255)
	if sec == secMove then tabMovement.BackgroundColor3 = activeColor
	elseif sec == secVis then tabVisual.BackgroundColor3 = activeColor
	elseif sec == secWorld then tabWorld.BackgroundColor3 = activeColor
	elseif sec == secUtil then tabUtility.BackgroundColor3 = activeColor
	end
end

tabMovement.MouseButton1Click:Connect(function() showSection(secMove) end)
tabVisual.MouseButton1Click:Connect(function() showSection(secVis) end)
tabWorld.MouseButton1Click:Connect(function() showSection(secWorld) end)
tabUtility.MouseButton1Click:Connect(function() showSection(secUtil) end)

showSection(secMove)

-- =============== 1. MOVEMENT ===============
makeSlider(secMove, "Walk Speed", 16, 300, state.speed, function(v)
	state.speed = v
	local _, hum = getCharHum()
	if hum then hum.WalkSpeed = v end
end)

makeSlider(secMove, "Jump Power", 50, 200, state.jump, function(v)
	state.jump = v
	local _, hum = getCharHum()
	if hum then hum.UseJumpPower = true; hum.JumpPower = v end
end)

local btnNoclip = makeButton(secMove, "Noclip: OFF")
btnNoclip.MouseButton1Click:Connect(function()
	state.noclip = not state.noclip
	btnNoclip.Text = state.noclip and "Noclip: ON ✅" or "Noclip: OFF ❌"
end)

RS.Stepped:Connect(function()
	if state.noclip then
		local char = player.Character
		if char then
			for _, part in pairs(char:GetDescendants()) do
				if part:IsA("BasePart") and part.CanCollide then
					part.CanCollide = false
				end
			end
		end
	end
end)

local btnInf = makeButton(secMove, "Infinite Jump: OFF")
btnInf.MouseButton1Click:Connect(function()
	state.infiniteJump = not state.infiniteJump
	btnInf.Text = state.infiniteJump and "Infinite Jump: ON 🦘" or "Infinite Jump: OFF"
end)

UIS.JumpRequest:Connect(function()
	if state.infiniteJump then
		local _, hum = getCharHum()
		if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
	end
end)

-- =============== 2. VISUAL ===============
local espFolder = Instance.new("Folder")
espFolder.Name = "ESP_Local"
espFolder.Parent = gui

local function refreshESP()
	for _, k in ipairs(espFolder:GetChildren()) do k:Destroy() end
	if not state.esp then return end
	for _, p in ipairs(Players:GetPlayers()) do 
		if p ~= player and p.Character then
			local h = Instance.new("Highlight")
			h.Name = p.Name
			h.FillTransparency = 1
			h.OutlineTransparency = 0
			h.OutlineColor = Color3.fromRGB(90, 130, 255)
			h.Adornee = p.Character
			h.Parent = espFolder
		end
	end
end

local btnESP = makeButton(secVis, "ESP Players: OFF")
btnESP.MouseButton1Click:Connect(function()
	state.esp = not state.esp
	btnESP.Text = state.esp and "ESP Players: ON 👁️" or "ESP Players: OFF"
	refreshESP()
end)

makeSlider(secVis, "Camera FOV", 50, 120, state.fov, function(v)
	state.fov = v
	Camera.FieldOfView = v
end)

local btnNV = makeButton(secVis, "Night Vision: OFF")
btnNV.MouseButton1Click:Connect(function()
	state.nightVision = not state.nightVision
	btnNV.Text = state.nightVision and "Night Vision: ON 🌙" or "Night Vision: OFF"
	if state.nightVision then
		Lighting.Brightness = 3
		Lighting.Ambient = Color3.fromRGB(128,128,128)
		Lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
	else
		Lighting.Brightness = backup.Brightness
		Lighting.Ambient = backup.Ambient
		Lighting.OutdoorAmbient = backup.OutdoorAmbient
	end
end)

-- =============== 3. WORLD ===============
makeSlider(secWorld, "Gravity", 0, 196, math.floor(state.gravity + 0.5), function(v)
	state.gravity = v
	workspace.Gravity = v
end)

makeSlider(secWorld, "Time of Day", 0, 24, math.floor(state.clockTime + 0.5), function(v)
	state.clockTime = v
	Lighting.ClockTime = v
end)

local btnReduceLag = makeButton(secWorld, "Reduce Lag: OFF", Color3.fromRGB(80, 160, 80))
btnReduceLag.MouseButton1Click:Connect(function()
	state.reduceLag = not state.reduceLag
	if state.reduceLag then
		Lighting.GlobalShadows = false
		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj:IsA("BasePart") then obj.Material = Enum.Material.SmoothPlastic end
			if obj:IsA("Texture") or obj:IsA("Decal") then obj:Destroy() end
		end
		btnReduceLag.Text = "Reduce Lag: ON 🚀"
	else
		Lighting.GlobalShadows = backup.GlobalShadows
		btnReduceLag.Text = "Reduce Lag: OFF"
	end
end)

-- =============== 4. UTILITY ===============
local btnSpark = makeButton(secUtil, "✨ Add Sparkles (3s)")
btnSpark.MouseButton1Click:Connect(function()
	local char = player.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local s = Instance.new("Sparkles", char.HumanoidRootPart)
		Debris:AddItem(s, 3)
	end
end)

local btnSit = makeButton(secUtil, "Sit / Stand")
btnSit.MouseButton1Click:Connect(function()
	local _, hum = getCharHum()
	if hum then hum.Sit = not hum.Sit end
end)
