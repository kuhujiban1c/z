-- ============================================================
--  StarterPlayerScripts / enhanced_wolf_fixed.lua
--  Ultimate Client Dev Tools  —  AI Enhanced Edition
--  Credit: https://t.me/uni4codex
--  Fixed & Refactored: all deprecated API, logic bugs, and
--  forward-reference issues resolved.
--  UI Enhanced: glass effect, animations, hover, tooltips, etc.
-- ============================================================

-- =============== SERVICES ===============
local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local RS               = game:GetService("RunService")
local Lighting         = game:GetService("Lighting")
local TweenService     = game:GetService("TweenService")
local PathfindingService = game:GetService("PathfindingService")

local player  = Players.LocalPlayer
local Camera  = workspace.CurrentCamera

-- =============== CHARACTER HELPERS ===============
local character, humanoid

local function getCharHum()
	local c = player.Character or player.CharacterAdded:Wait()
	local h = c:WaitForChild("Humanoid")
	return c, h
end

character, humanoid = getCharHum()

-- =============== STATE ===============
local state = {
	speed          = 16,
	jump           = 50,
	noclip         = false,
	fly            = false,
	infiniteJump   = false,
	flyMult        = 2,
	esp            = false,
	rainbow        = false,
	nightVision    = false,
	fov            = 70,
	gravity        = workspace.Gravity,
	clockTime      = Lighting.ClockTime or 12,
	reduceLag      = false,
	antiAFK        = false,
	freecam        = false,
	xray           = false,
	clickTP        = false,
	aimbot         = false,
	tracers        = false,
	hitboxes       = false,
	autoRespawn    = false,
}

local aiState = {
	autoFarm    = false,
	autoCollect = false,
}

-- Lighting backup
local backup = {
	Brightness     = Lighting.Brightness,
	Ambient        = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	FogEnd         = Lighting.FogEnd,
	GlobalShadows  = Lighting.GlobalShadows,
	Technology     = Lighting.Technology,
	ShadowSoftness = Lighting.ShadowSoftness,
}

-- Advanced runtime objects
local advanced = {
	xrayParts         = {},
	tracerBeams       = {},
	aimbotTarget      = nil,
	clickTPConnection = nil,
	freecamSpeed      = 1,
	freecamCFrame     = nil,
}

-- =============== FORWARD DECLARATIONS ===============
local setNoclipConnection
local setFlyConnection

-- =============== UI FACTORY ===============
local screen = Instance.new("ScreenGui")
screen.Name           = "ClientDevToolsEnhanced"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.Parent         = player:WaitForChild("PlayerGui")

-- ---- [UI ENHANCEMENT] Glass effect: blur & shadow ----
local blur = Instance.new("BlurEffect", Lighting)
blur.Enabled = false
blur.Size = 0

-- ---- Main Frame ----
local frame = Instance.new("Frame")
frame.Size            = UDim2.new(0, 450, 0.9, 0)
frame.Position        = UDim2.new(0.5, -225, 0.05, 0)
frame.AnchorPoint     = Vector2.new(0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
frame.BackgroundTransparency = 0.15  -- glass effect
frame.BorderSizePixel = 0
frame.Visible         = false
frame.Active          = true
frame.Parent          = screen

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 8)

-- [UI ENHANCEMENT] Shadow image
local shadow = Instance.new("ImageLabel", frame)
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://6014261993"
shadow.ImageTransparency = 0.5
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(49, 49, 200, 200)
shadow.ZIndex = 0

-- ---- Toggle Button ----
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size            = UDim2.new(0, 56, 0, 40)
toggleBtn.Position        = UDim2.new(1, -64, 1, -56)
toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
toggleBtn.Text            = "🛠️"
toggleBtn.TextColor3      = Color3.new(1, 1, 1)
toggleBtn.TextSize        = 22
toggleBtn.Font            = Enum.Font.GothamBold
toggleBtn.Parent          = screen

local toggleCorner = Instance.new("UICorner", toggleBtn)
toggleCorner.CornerRadius = UDim.new(0, 8)

-- [UI ENHANCEMENT] Animasi fade in/out untuk frame
toggleBtn.MouseButton1Click:Connect(function()
	if frame.Visible then
		-- Fade out
		local tween = TweenService:Create(frame, TweenInfo.new(0.2), {BackgroundTransparency = 1})
		tween:Play()
		tween.Completed:Wait()
		frame.Visible = false
	else
		frame.Visible = true
		local tween = TweenService:Create(frame, TweenInfo.new(0.3), {BackgroundTransparency = 0.15})
		tween:Play()
	end
end)

-- ---- Drag Helper (generic) ----
local function makeDraggable(element)
	local dragging, dragStart, startPos
	element.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging  = true
			dragStart = input.Position
			startPos  = element.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UIS.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			element.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

makeDraggable(frame)
makeDraggable(toggleBtn)

-- ---- Title Bar ----
local titleBar = Instance.new("Frame", frame)
titleBar.Size            = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
titleBar.BorderSizePixel = 0

local titleCorner = Instance.new("UICorner", titleBar)
titleCorner.CornerRadius = UDim.new(0, 8)

local titleText = Instance.new("TextLabel", titleBar)
titleText.Size               = UDim2.new(1, -110, 0.6, 0)  -- lebih kecil karena ada tombol minimize
titleText.Position           = UDim2.new(0, 12, 0, 2)
titleText.BackgroundTransparency = 1
titleText.Text               = "🤖 Ultimate AI Dev Tools"
titleText.TextColor3         = Color3.new(1, 1, 1)
titleText.TextXAlignment     = Enum.TextXAlignment.Left
titleText.Font               = Enum.Font.GothamBold
titleText.TextSize           = 16

local creditLabel = Instance.new("TextLabel", titleBar)
creditLabel.Size             = UDim2.new(1, -110, 0.4, 0)
creditLabel.Position         = UDim2.new(0, 12, 0.6, 0)
creditLabel.BackgroundTransparency = 1
creditLabel.Text             = "By: t.me/uni4codex  |  AI Enhanced"
creditLabel.TextColor3       = Color3.fromRGB(180, 180, 180)
creditLabel.TextXAlignment   = Enum.TextXAlignment.Left
creditLabel.Font             = Enum.Font.Gotham
creditLabel.TextSize         = 10

-- [UI ENHANCEMENT] Minimize button
local minimizeBtn = Instance.new("TextButton", titleBar)
minimizeBtn.Size = UDim2.new(0, 32, 0, 32)
minimizeBtn.Position = UDim2.new(1, -72, 0, 4)
minimizeBtn.Text = "─"
minimizeBtn.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 18
minimizeBtn.BorderSizePixel = 0
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 6)

local isMinimized = false
minimizeBtn.MouseButton1Click:Connect(function()
	isMinimized = not isMinimized
	if isMinimized then
		frame.Size = UDim2.new(0, 450, 0, 40)
		minimizeBtn.Text = "□"
	else
		frame.Size = UDim2.new(0, 450, 0.9, 0)
		minimizeBtn.Text = "─"
	end
end)

local closeX = Instance.new("TextButton", titleBar)
closeX.Size            = UDim2.new(0, 32, 0, 32)
closeX.Position        = UDim2.new(1, -36, 0, 4)
closeX.Text            = "✕"
closeX.BackgroundColor3 = Color3.fromRGB(220, 80, 80)
closeX.TextColor3      = Color3.new(1, 1, 1)
closeX.Font            = Enum.Font.GothamBold
closeX.TextSize        = 16
closeX.BorderSizePixel = 0
Instance.new("UICorner", closeX).CornerRadius = UDim.new(0, 6)
closeX.MouseButton1Click:Connect(function() frame.Visible = false end)

-- ---- Tab Bar ----
local tabBar = Instance.new("Frame", frame)
tabBar.Size            = UDim2.new(1, -20, 0, 36)
tabBar.Position        = UDim2.new(0, 10, 0, 45)
tabBar.BackgroundColor3 = Color3.fromRGB(28, 28, 28)
tabBar.BorderSizePixel = 0
Instance.new("UICorner", tabBar).CornerRadius = UDim.new(0, 6)

local tabLayout = Instance.new("UIListLayout", tabBar)
tabLayout.FillDirection       = Enum.FillDirection.Horizontal
tabLayout.Padding             = UDim.new(0, 4)
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment   = Enum.VerticalAlignment.Center

-- [UI ENHANCEMENT] Tab indicator
local indicator = Instance.new("Frame", tabBar)
indicator.Size = UDim2.new(0, 72, 0, 3)
indicator.Position = UDim2.new(0, 0, 1, -3)
indicator.BackgroundColor3 = Color3.fromRGB(70, 100, 180)
indicator.BorderSizePixel = 0
indicator.Name = "TabIndicator"
Instance.new("UICorner", indicator).CornerRadius = UDim.new(0, 2)

-- ---- Content Holder ----
local contentHolder = Instance.new("Frame", frame)
contentHolder.Size               = UDim2.new(1, -20, 1, -100)
contentHolder.Position           = UDim2.new(0, 10, 0, 90)
contentHolder.BackgroundTransparency = 1

-- =============== WIDGET BUILDERS ===============
local function makeTabButton(name)
	local b = Instance.new("TextButton")
	b.Size            = UDim2.new(0, 72, 0, 28)
	b.BackgroundColor3 = Color3.fromRGB(44, 44, 44)
	b.TextColor3      = Color3.new(1, 1, 1)
	b.Text            = name
	b.Font            = Enum.Font.GothamBold
	b.TextSize        = 11
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.Parent = tabBar
	return b
end

local function makeSection()
	local scroller = Instance.new("ScrollingFrame")
	scroller.Size                 = UDim2.new(1, 0, 1, 0)
	scroller.CanvasSize           = UDim2.new(0, 0, 0, 0)
	scroller.ScrollBarThickness   = 6
	scroller.BackgroundTransparency = 1
	scroller.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
	scroller.Visible              = false
	scroller.Parent               = contentHolder

	local lay = Instance.new("UIListLayout", scroller)
	lay.Padding = UDim.new(0, 8)
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroller.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 16)
	end)
	return scroller
end

local function makeButton(parent, txt, color)
	local b = Instance.new("TextButton")
	b.Size            = UDim2.new(1, 0, 0, 36)
	b.BackgroundColor3 = color or Color3.fromRGB(56, 56, 56)
	b.TextColor3      = Color3.new(1, 1, 1)
	b.Font            = Enum.Font.Gotham
	b.TextSize        = 14
	b.Text            = txt
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
	b.Parent = parent
	return b
end

-- [UI ENHANCEMENT] Styled button with hover effect
local function makeStyledButton(parent, txt, baseColor, hoverColor)
	local b = makeButton(parent, txt, baseColor)
	local originalColor = baseColor or Color3.fromRGB(56,56,56)
	hoverColor = hoverColor or originalColor:Lerp(Color3.new(1,1,1), 0.2)
	
	b.MouseEnter:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = hoverColor}):Play()
	end)
	b.MouseLeave:Connect(function()
		TweenService:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = originalColor}):Play()
	end)
	return b
end

local function makeLabel(parent, txt)
	local l = Instance.new("TextLabel")
	l.Size               = UDim2.new(1, 0, 0, 24)
	l.BackgroundTransparency = 1
	l.TextColor3         = Color3.fromRGB(200, 200, 200)
	l.TextXAlignment     = Enum.TextXAlignment.Left
	l.Font               = Enum.Font.Gotham
	l.TextSize           = 12
	l.Text               = txt
	l.Parent             = parent
	return l
end

-- [UI ENHANCEMENT] Tooltip utility
local function addTooltip(button, text)
	local tip = Instance.new("TextLabel", button)
	tip.Size = UDim2.new(0, 120, 0, 20)
	tip.Position = UDim2.new(0, 0, 1, 5)
	tip.BackgroundColor3 = Color3.fromRGB(0,0,0)
	tip.BackgroundTransparency = 0.2
	tip.TextColor3 = Color3.new(1,1,1)
	tip.Text = text
	tip.Visible = false
	tip.TextSize = 11
	tip.Font = Enum.Font.Gotham
	tip.ZIndex = 100
	button.MouseEnter:Connect(function() tip.Visible = true end)
	button.MouseLeave:Connect(function() tip.Visible = false end)
end

local function makeSlider(parent, labelText, minVal, maxVal, default, onChange)
	local container = Instance.new("Frame")
	container.Size               = UDim2.new(1, 0, 0, 52)
	container.BackgroundTransparency = 1
	container.Parent             = parent

	local lbl = makeLabel(container, labelText .. " (" .. tostring(default) .. ")")
	lbl.Position = UDim2.new(0, 0, 0, 0)

	local track = Instance.new("Frame", container)
	track.Size            = UDim2.new(1, 0, 0, 24)
	track.Position        = UDim2.new(0, 0, 0, 24)
	track.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	track.BorderSizePixel = 0
	Instance.new("UICorner", track).CornerRadius = UDim.new(0, 4)

	local fill = Instance.new("Frame", track)
	fill.BackgroundColor3 = Color3.fromRGB(80, 120, 255)
	fill.BorderSizePixel  = 0
	fill.Size             = UDim2.new((default - minVal) / (maxVal - minVal), 0, 1, 0)
	Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

	local dragging = false

	local function setFromX(x)
		local rel = math.clamp(
			(x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1
		)
		fill.Size = UDim2.new(rel, 0, 1, 0)
		local val = math.floor(minVal + rel * (maxVal - minVal) + 0.5)
		lbl.Text  = labelText .. " (" .. val .. ")"
		if onChange then onChange(val) end
	end

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			setFromX(input.Position.X)
			-- [UI ENHANCEMENT] Visual feedback on drag start
			TweenService:Create(fill, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(120,180,255)}):Play()
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					TweenService:Create(fill, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(80,120,255)}):Play()
				end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement or
			input.UserInputType == Enum.UserInputType.Touch
		) then
			setFromX(input.Position.X)
		end
	end)

	if onChange then onChange(default) end
end

-- =============== TABS ===============
local tabMovement  = makeTabButton("Move")
local tabVisual    = makeTabButton("Visual")
local tabWorld     = makeTabButton("World")
local tabUtility   = makeTabButton("Utility")
local tabPlayers   = makeTabButton("Players")
local tabAdvanced  = makeTabButton("Advanced")
local tabCombat    = makeTabButton("Combat")
local tabDeveloper = makeTabButton("Dev")
local tabAI        = makeTabButton("AI Tools")

local secMove      = makeSection()
local secVis       = makeSection()
local secWorld     = makeSection()
local secUtil      = makeSection()
local secOther     = makeSection()
local secAdvanced  = makeSection()
local secCombat    = makeSection()
local secDeveloper = makeSection()
local secAI        = makeSection()

local TAB_MAP = {
	[tabMovement]  = secMove,
	[tabVisual]    = secVis,
	[tabWorld]     = secWorld,
	[tabUtility]   = secUtil,
	[tabPlayers]   = secOther,
	[tabAdvanced]  = secAdvanced,
	[tabCombat]    = secCombat,
	[tabDeveloper] = secDeveloper,
	[tabAI]        = secAI,
}

local COLOR_ACTIVE   = Color3.fromRGB(70, 100, 180)
local COLOR_INACTIVE = Color3.fromRGB(44, 44, 44)

local function showSection(targetSec)
	for _, child in ipairs(contentHolder:GetChildren()) do
		if child:IsA("ScrollingFrame") then
			child.Visible = (child == targetSec)
		end
	end
	for btn, sec in pairs(TAB_MAP) do
		btn.BackgroundColor3 = (sec == targetSec) and COLOR_ACTIVE or COLOR_INACTIVE
	end
	
	-- [UI ENHANCEMENT] Animasi tab indicator
	local targetTab
	for btn, sec in pairs(TAB_MAP) do
		if sec == targetSec then targetTab = btn break end
	end
	if targetTab then
		TweenService:Create(indicator, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
			Position = UDim2.new(0, targetTab.Position.X.Offset, 1, -3)
		}):Play()
	end
end

for btn, sec in pairs(TAB_MAP) do
	btn.MouseButton1Click:Connect(function() showSection(sec) end)
end

showSection(secMove)

-- =============== MOVEMENT ===============
makeSlider(secMove, "Walk Speed", 16, 300, state.speed, function(v)
	state.speed = v
	if humanoid then humanoid.WalkSpeed = v end
end)

makeSlider(secMove, "Jump Power", 50, 200, state.jump, function(v)
	state.jump = v
	if humanoid then
		humanoid.UseJumpPower = true
		humanoid.JumpPower = v
	end
end)

local btnNoclip = makeStyledButton(secMove, "Noclip: OFF") -- pakai styled button
btnNoclip.MouseButton1Click:Connect(function()
	state.noclip = not state.noclip
	btnNoclip.Text = state.noclip and "Noclip: ON ✅" or "Noclip: OFF ❌"
	setNoclipConnection()
end)
addTooltip(btnNoclip, "Terobos semua objek")

local btnFly = makeStyledButton(secMove, "Fly: OFF")
btnFly.MouseButton1Click:Connect(function()
	state.fly = not state.fly
	btnFly.Text = state.fly and "Fly: ON ✈️" or "Fly: OFF"
	setFlyConnection()
end)
addTooltip(btnFly, "Terbang bebas dengan kontrol keyboard")

makeSlider(secMove, "Fly Speed Multiplier", 1, 6, state.flyMult, function(v)
	state.flyMult = v
end)

-- Infinite Jump
local jumpConn
local btnInf = makeButton(secMove, "Infinite Jump: OFF")
btnInf.MouseButton1Click:Connect(function()
	state.infiniteJump = not state.infiniteJump
	btnInf.Text = state.infiniteJump and "Infinite Jump: ON 🦘" or "Infinite Jump: OFF"
	if jumpConn then jumpConn:Disconnect(); jumpConn = nil end
	if state.infiniteJump then
		jumpConn = UIS.JumpRequest:Connect(function()
			if humanoid then
				humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end
end)
addTooltip(btnInf, "Lompat tanpa batas")

-- Click Teleport
local clickTPBtn = makeButton(secMove, "Click TP: OFF", Color3.fromRGB(120, 120, 255))
clickTPBtn.MouseButton1Click:Connect(function()
	state.clickTP = not state.clickTP
	clickTPBtn.Text = state.clickTP and "Click TP: ON 🖱️" or "Click TP: OFF"
	if advanced.clickTPConnection then
		advanced.clickTPConnection:Disconnect()
		advanced.clickTPConnection = nil
	end
	if state.clickTP then
		local mouse = player:GetMouse()
		advanced.clickTPConnection = mouse.Button1Down:Connect(function()
			if character and mouse.Target then
				local root = character:FindFirstChild("HumanoidRootPart")
				if root then
					root.CFrame = CFrame.new(mouse.Hit.Position + Vector3.new(0, 3, 0))
				end
			end
		end)
	end
end)
addTooltip(clickTPBtn, "Klik di mana saja untuk teleport")

-- Freecam
local freecamCon
local freecamBtn = makeButton(secMove, "Freecam: OFF", Color3.fromRGB(200, 100, 200))
freecamBtn.MouseButton1Click:Connect(function()
	state.freecam = not state.freecam
	freecamBtn.Text = state.freecam and "Freecam: ON 📷" or "Freecam: OFF"
	if freecamCon then freecamCon:Disconnect(); freecamCon = nil end
	if state.freecam then
		Camera.CameraSubject = nil
		advanced.freecamCFrame = Camera.CFrame
		freecamCon = RS.Heartbeat:Connect(function(dt)
			local speed = advanced.freecamSpeed * dt * 60
			local move  = Vector3.new(0, 0, 0)
			if UIS:IsKeyDown(Enum.KeyCode.W)         then move += Camera.CFrame.LookVector  end
			if UIS:IsKeyDown(Enum.KeyCode.S)         then move -= Camera.CFrame.LookVector  end
			if UIS:IsKeyDown(Enum.KeyCode.A)         then move -= Camera.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D)         then move += Camera.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space)     then move += Vector3.new(0, 1, 0)      end
			if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then move -= Vector3.new(0, 1, 0)      end
			Camera.CFrame = Camera.CFrame * CFrame.new(move * speed)
		end)
	else
		if humanoid then Camera.CameraSubject = humanoid end
	end
end)
addTooltip(freecamBtn, "Kamera terbang bebas")

makeSlider(secMove, "Freecam Speed", 1, 10, advanced.freecamSpeed, function(v)
	advanced.freecamSpeed = v
end)

-- =============== VISUAL ===============
local espFolder = Instance.new("Folder")
espFolder.Name   = "ESP_Local"
espFolder.Parent = screen

local function applyESPToPlayer(p)
	if p == player or not state.esp then return end
	local c = p.Character
	if not c or espFolder:FindFirstChild(p.Name) then return end
	local h = Instance.new("Highlight")
	h.Name               = p.Name
	h.FillTransparency   = 1
	h.OutlineTransparency = 0
	h.OutlineColor       = Color3.fromRGB(0, 255, 200)
	h.Adornee            = c
	h.Parent             = espFolder
end

local function refreshESP()
	for _, k in ipairs(espFolder:GetChildren()) do k:Destroy() end
	if not state.esp then return end
	for _, p in ipairs(Players:GetPlayers()) do applyESPToPlayer(p) end
end

local btnESP = makeButton(secVis, "ESP Players: OFF")
btnESP.MouseButton1Click:Connect(function()
	state.esp = not state.esp
	btnESP.Text = state.esp and "ESP Players: ON 👁️" or "ESP Players: OFF"
	refreshESP()
end)
addTooltip(btnESP, "Tampilkan outline pemain")

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(0.2)
		applyESPToPlayer(p)
	end)
end)

Players.PlayerRemoving:Connect(function(p)
	local k = espFolder:FindFirstChild(p.Name)
	if k then k:Destroy() end
end)

-- Rainbow Aura
local auraHighlight
local btnRainbow = makeButton(secVis, "Rainbow Aura: OFF")
btnRainbow.MouseButton1Click:Connect(function()
	state.rainbow = not state.rainbow
	btnRainbow.Text = state.rainbow and "Rainbow Aura: ON 🌈" or "Rainbow Aura: OFF"
	if state.rainbow then
		if not auraHighlight or not auraHighlight.Parent then
			auraHighlight = Instance.new("Highlight")
			auraHighlight.Name               = "RainbowAura"
			auraHighlight.FillTransparency   = 0.7
			auraHighlight.OutlineTransparency = 1
			auraHighlight.Adornee            = character
			auraHighlight.Parent             = screen
		end
	else
		if auraHighlight then auraHighlight:Destroy(); auraHighlight = nil end
	end
end)

-- Night Vision
local btnNV = makeButton(secVis, "Night Vision: OFF")
btnNV.MouseButton1Click:Connect(function()
	state.nightVision = not state.nightVision
	btnNV.Text = state.nightVision and "Night Vision: ON 🌙" or "Night Vision: OFF"
	if state.nightVision then
		Lighting.Brightness     = 3
		Lighting.Ambient        = Color3.fromRGB(128, 128, 128)
		Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
		Lighting.FogEnd         = 100000
	else
		Lighting.Brightness     = backup.Brightness
		Lighting.Ambient        = backup.Ambient
		Lighting.OutdoorAmbient = backup.OutdoorAmbient
		Lighting.FogEnd         = backup.FogEnd
	end
end)

makeSlider(secVis, "Camera FOV", 50, 120, state.fov, function(v)
	state.fov = v
	Camera.FieldOfView = v
end)

-- X-Ray
local btnXray = makeButton(secVis, "X-Ray Vision: OFF")
btnXray.MouseButton1Click:Connect(function()
	state.xray = not state.xray
	btnXray.Text = state.xray and "X-Ray Vision: ON 🔍" or "X-Ray Vision: OFF"
	if state.xray then
		for _, part in ipairs(workspace:GetDescendants()) do
			if part:IsA("BasePart") and part.Transparency < 0.5 then
				advanced.xrayParts[part] = part.Transparency
				part.Transparency = 0.5
			end
		end
	else
		for part, transparency in pairs(advanced.xrayParts) do
			if part.Parent then part.Transparency = transparency end
		end
		advanced.xrayParts = {}
	end
end)

-- Rainbow animator
RS.Heartbeat:Connect(function()
	if state.rainbow and auraHighlight then
		local hue = (tick() % 5) / 5
		auraHighlight.FillColor = Color3.fromHSV(hue, 0.8, 1)
	end
end)

-- =============== WORLD ===============
makeSlider(secWorld, "Gravity", 0, 196, math.floor(state.gravity + 0.5), function(v)
	state.gravity    = v
	workspace.Gravity = v
end)

makeSlider(secWorld, "Time of Day", 0, 24, math.floor(state.clockTime + 0.5), function(v)
	state.clockTime     = v
	Lighting.ClockTime  = v
end)

local btnReduceLag = makeButton(secWorld, "Reduce Lag: OFF", Color3.fromRGB(80, 160, 80))
btnReduceLag.MouseButton1Click:Connect(function()
	state.reduceLag = not state.reduceLag
	if state.reduceLag then
		Lighting.GlobalShadows  = false
		Lighting.Technology     = Enum.Technology.Legacy
		Lighting.ShadowSoftness = 0
	else
		Lighting.GlobalShadows  = backup.GlobalShadows
		Lighting.Technology     = backup.Technology
		Lighting.ShadowSoftness = backup.ShadowSoftness
	end
	btnReduceLag.Text = state.reduceLag and "Reduce Lag: ON ⚡" or "Reduce Lag: OFF"
end)

-- =============== UTILITY ===============
local autoResp = makeButton(secUtil, "Auto Respawn: OFF")
autoResp.MouseButton1Click:Connect(function()
	state.autoRespawn = not state.autoRespawn
	autoResp.Text = state.autoRespawn and "Auto Respawn: ON 🔄" or "Auto Respawn: OFF"
end)
addTooltip(autoResp, "Respawn otomatis saat mati")

local antiAFKBtn = makeButton(secUtil, "Anti AFK: OFF")
antiAFKBtn.MouseButton1Click:Connect(function()
	state.antiAFK = not state.antiAFK
	antiAFKBtn.Text = state.antiAFK and "Anti AFK: ON ⚡" or "Anti AFK: OFF"
	if state.antiAFK then
		task.spawn(function()
			while state.antiAFK do
				task.wait(60)
				pcall(function()
					if humanoid then
						humanoid:ChangeState(Enum.HumanoidStateType.Running)
					end
				end)
			end
		end)
	end
end)
addTooltip(antiAFKBtn, "Cegah kick karena idle")

-- Saved Position / Marker
local savedCFrame = nil

local saveBtn = makeButton(secUtil, "Save Position 📍")
saveBtn.MouseButton1Click:Connect(function()
	if character and character:FindFirstChild("HumanoidRootPart") then
		savedCFrame = character.HumanoidRootPart.CFrame
		saveBtn.Text = "Position Saved ✅"
		task.delay(2, function() saveBtn.Text = "Save Position 📍" end)
	end
end)

local loadBtn = makeButton(secUtil, "Load Position 🔁")
loadBtn.MouseButton1Click:Connect(function()
	if savedCFrame and character and character:FindFirstChild("HumanoidRootPart") then
		character.HumanoidRootPart.CFrame = savedCFrame
	end
end)

-- =============== PLAYERS ===============
local function teleportToPlayer(targetPlayer)
	if targetPlayer and targetPlayer.Character then
		local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
		if root and character and character:FindFirstChild("HumanoidRootPart") then
			character.HumanoidRootPart.CFrame = root.CFrame * CFrame.new(0, 0, 3)
		end
	end
end

local playerList = Instance.new("ScrollingFrame", secOther)
playerList.Size                 = UDim2.new(1, 0, 1, 0)
playerList.BackgroundTransparency = 1
playerList.ScrollBarThickness   = 4

local playerLayout = Instance.new("UIListLayout", playerList)
playerLayout.Padding = UDim.new(0, 4)
playerLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	playerList.CanvasSize = UDim2.new(0, 0, 0, playerLayout.AbsoluteContentSize.Y + 10)
end)

local function refreshPlayerList()
	for _, child in ipairs(playerList:GetChildren()) do
		if child:IsA("Frame") then child:Destroy() end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local row = Instance.new("Frame")
			row.Size            = UDim2.new(1, 0, 0, 40)
			row.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
			row.BorderSizePixel = 0
			Instance.new("UICorner", row).CornerRadius = UDim.new(0, 6)
			row.Parent = playerList

			local nameLabel = Instance.new("TextLabel", row)
			nameLabel.Size             = UDim2.new(0.7, 0, 1, 0)
			nameLabel.Text             = p.Name
			nameLabel.TextColor3       = Color3.new(1, 1, 1)
			nameLabel.Font             = Enum.Font.Gotham
			nameLabel.TextSize         = 13
			nameLabel.BackgroundTransparency = 1

			local tpBtn = Instance.new("TextButton", row)
			tpBtn.Size            = UDim2.new(0.3, 0, 1, 0)
			tpBtn.Position        = UDim2.new(0.7, 0, 0, 0)
			tpBtn.Text            = "TP"
			tpBtn.BackgroundColor3 = Color3.fromRGB(70, 130, 230)
			tpBtn.TextColor3      = Color3.new(1, 1, 1)
			tpBtn.Font            = Enum.Font.GothamBold
			tpBtn.TextSize        = 12
			tpBtn.BorderSizePixel = 0
			Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 6)
			tpBtn.MouseButton1Click:Connect(function() teleportToPlayer(p) end)
		end
	end
end

refreshPlayerList()
Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(refreshPlayerList)

-- =============== COMBAT ===============
-- Aimbot
local aimbotBtn = makeButton(secCombat, "Aimbot: OFF")
aimbotBtn.MouseButton1Click:Connect(function()
	state.aimbot = not state.aimbot
	aimbotBtn.Text = state.aimbot and "Aimbot: ON 🎯" or "Aimbot: OFF"
end)

local function getClosestPlayerToCrosshair()
	local best, bestDist = nil, math.huge
	local center = Camera.ViewportSize / 2
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local head = p.Character:FindFirstChild("Head")
			if head then
				local screenPos, onScreen = Camera:WorldToScreenPoint(head.Position)
				if onScreen then
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if dist < 200 and dist < bestDist then
						best     = p
						bestDist = dist
					end
				end
			end
		end
	end
	return best
end

RS.Heartbeat:Connect(function()
	if state.aimbot then
		local target = getClosestPlayerToCrosshair()
		if target and target.Character and target.Character:FindFirstChild("Head") then
			Camera.CFrame = CFrame.lookAt(
				Camera.CFrame.Position,
				target.Character.Head.Position
			)
			advanced.aimbotTarget = target
		else
			advanced.aimbotTarget = nil
		end
	end
end)

-- Reach
local reachBtn = makeButton(secCombat, "Reach: OFF")
reachBtn.MouseButton1Click:Connect(function()
	state.reach = not state.reach
	reachBtn.Text = state.reach and "Reach: ON ⚔️" or "Reach: OFF"
end)

-- Tracers
local tracerBtn = makeButton(secCombat, "Tracers: OFF")
tracerBtn.MouseButton1Click:Connect(function()
	state.tracers = not state.tracers
	tracerBtn.Text = state.tracers and "Tracers: ON 📏" or "Tracers: OFF"
end)

RS.Heartbeat:Connect(function()
	if not state.tracers then
		for _, beam in ipairs(advanced.tracerBeams) do
			pcall(function() beam:Destroy() end)
		end
		advanced.tracerBeams = {}
		return
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player and p.Character then
			local root = p.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local found = false
				for _, b in ipairs(advanced.tracerBeams) do
					if b ~= nil and b.Parent == root then found = true; break end
				end
				if not found then
					local myRoot = character and character:FindFirstChild("HumanoidRootPart")
					if myRoot then
						local a0 = Instance.new("Attachment", myRoot)
						local a1 = Instance.new("Attachment", root)
						local beam = Instance.new("Beam")
						beam.Attachment0 = a0
						beam.Attachment1 = a1
						beam.Color       = ColorSequence.new(Color3.new(1, 0, 0))
						beam.Width0      = 0.1
						beam.Width1      = 0.1
						beam.FaceCamera  = true
						beam.Parent      = root
						table.insert(advanced.tracerBeams, beam)
					end
				end
			end
		end
	end
	for i = #advanced.tracerBeams, 1, -1 do
		local beam = advanced.tracerBeams[i]
		if not beam or not beam.Parent then
			table.remove(advanced.tracerBeams, i)
		end
	end
end)

-- Hitbox Expand
local hitboxBtn = makeButton(secCombat, "Hitbox Expand: OFF")
hitboxBtn.MouseButton1Click:Connect(function()
	state.hitboxes = not state.hitboxes
	hitboxBtn.Text = state.hitboxes and "Hitbox Expand: ON 📦" or "Hitbox Expand: OFF"
	if state.hitboxes then
		task.spawn(function()
			while state.hitboxes do
				task.wait(0.2)
				for _, p in ipairs(Players:GetPlayers()) do
					if p ~= player and p.Character then
						for _, part in ipairs(p.Character:GetChildren()) do
							if part:IsA("BasePart") then
								if part.Size.Magnitude < 30 then
									part.Size = part.Size * 1.1
								end
							end
						end
					end
				end
			end
		end)
	end
end)

-- =============== AI TOOLS — SMART OBJECT SCANNER ===============
--[[
  Cara kerja:
    1. Klik "Scan Workspace" → AI scan semua Model di seluruh workspace
    2. Tampil daftar KATEGORI (nama unik model) beserta jumlahnya
    3. Pilih kategori → tampil semua instance individual (Wolf 1, Wolf 2, dst)
    4. Pilih instance → TP ke sana, atau klik "Auto TP Semua" untuk loop
]]

-- ---- State AI Scanner ----
local scanner = {
	running      = false,
	delay        = 1.5,
	espOn        = false,
	highlights   = {},
	categoryData = {},
	selectedCat  = nil,
	selectedIdx  = nil,
}

-- ---- Cari pivot (posisi) dari sebuah Model ----
local function getModelPivot(model)
	local root = model:FindFirstChild("HumanoidRootPart")
	if root then return root end
	local primary = model.PrimaryPart
	if primary then return primary end
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then return d end
	end
	return nil
end

-- ---- Scan seluruh workspace, kelompokkan per nama ----
local function scanWorkspace()
	local result = {}
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Model") then
			local pivot = getModelPivot(obj)
			if pivot then
				local name = obj.Name
				if not result[name] then result[name] = {} end
				table.insert(result[name], { model = obj, pivot = pivot })
			end
		end
	end
	return result
end

-- ---- Clear semua highlight ----
local function clearHighlights()
	for _, h in ipairs(scanner.highlights) do
		pcall(function() h:Destroy() end)
	end
	scanner.highlights = {}
end

-- ---- Highlight semua item dari kategori ----
local function highlightCategory(items, color)
	clearHighlights()
	if not scanner.espOn then return end
	color = color or Color3.fromRGB(255, 220, 50)
	for _, entry in ipairs(items) do
		local h = Instance.new("Highlight")
		h.FillColor           = color
		h.OutlineColor        = Color3.fromRGB(255, 255, 255)
		h.FillTransparency    = 0.45
		h.OutlineTransparency = 0
		h.Adornee             = entry.model
		h.Parent              = screen
		table.insert(scanner.highlights, h)
	end
end

-- ---- Teleport ke satu entry ----
local function tpToEntry(entry)
	local myRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return false end
	if not entry or not entry.pivot or not entry.pivot.Parent then return false end
	myRoot.CFrame = CFrame.new(entry.pivot.Position + Vector3.new(0, 3.5, 0))
	return true
end

-- ============================================================
-- UI BUILDER (AI Scanner)
-- ============================================================
makeLabel(secAI, "━━━━━━ 🤖 AI OBJECT SCANNER ━━━━━━")

local scanStatusLabel = makeLabel(secAI, "Status: Belum di-scan")
scanStatusLabel.TextColor3 = Color3.fromRGB(160, 200, 255)

makeSlider(secAI, "Delay antar TP (detik)", 1, 10, scanner.delay, function(v)
	scanner.delay = v
end)

local espToggle = makeButton(secAI, "👁 ESP Highlight: OFF", Color3.fromRGB(80, 80, 130))
espToggle.MouseButton1Click:Connect(function()
	scanner.espOn = not scanner.espOn
	espToggle.Text = scanner.espOn and "👁 ESP Highlight: ON" or "👁 ESP Highlight: OFF"
	if not scanner.espOn then
		clearHighlights()
	elseif scanner.selectedCat and scanner.categoryData[scanner.selectedCat] then
		highlightCategory(scanner.categoryData[scanner.selectedCat])
	end
end)

makeLabel(secAI, "── Instance (pilih untuk TP) ──")

local itemPanel = Instance.new("ScrollingFrame", secAI)
itemPanel.Size                 = UDim2.new(1, 0, 0, 180)
itemPanel.BackgroundColor3     = Color3.fromRGB(24, 24, 30)
itemPanel.BorderSizePixel      = 0
itemPanel.ScrollBarThickness   = 5
itemPanel.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)
itemPanel.CanvasSize           = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", itemPanel).CornerRadius = UDim.new(0, 6)

local itemLayout = Instance.new("UIListLayout", itemPanel)
itemLayout.Padding = UDim.new(0, 3)
itemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	itemPanel.CanvasSize = UDim2.new(0, 0, 0, itemLayout.AbsoluteContentSize.Y + 8)
end)

local autoTPBtn = makeButton(secAI, "▶ Auto TP Semua: OFF", Color3.fromRGB(180, 80, 220))
local stopTPBtn = makeButton(secAI, "⏹ STOP", Color3.fromRGB(180, 40, 40))
stopTPBtn.Visible = false

stopTPBtn.MouseButton1Click:Connect(function()
	scanner.running   = false
	autoTPBtn.Text    = "▶ Auto TP Semua: OFF"
	stopTPBtn.Visible = false
end)

local function buildItemPanel(catName)
	for _, c in ipairs(itemPanel:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("Frame") or c:IsA("TextLabel") then
			c:Destroy()
		end
	end

	local items = scanner.categoryData[catName]
	if not items or #items == 0 then
		local lbl = Instance.new("TextLabel", itemPanel)
		lbl.Size               = UDim2.new(1, 0, 0, 28)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3         = Color3.fromRGB(180, 80, 80)
		lbl.Font               = Enum.Font.Gotham
		lbl.TextSize           = 12
		lbl.Text               = "  Tidak ada instance ditemukan"
		return
	end

	scanner.selectedCat = catName
	if scanner.espOn then highlightCategory(items) end

	for i, entry in ipairs(items) do
		local myRoot = character and character:FindFirstChild("HumanoidRootPart")
		local dist   = myRoot and entry.pivot.Parent
			and math.floor((myRoot.Position - entry.pivot.Position).Magnitude)
			or "?"

		local row = Instance.new("Frame", itemPanel)
		row.Size            = UDim2.new(1, -6, 0, 32)
		row.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
		row.BorderSizePixel = 0
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

		local nameLbl = Instance.new("TextLabel", row)
		nameLbl.Size             = UDim2.new(0.65, 0, 1, 0)
		nameLbl.Position         = UDim2.new(0, 6, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.TextColor3       = Color3.fromRGB(240, 220, 100)
		nameLbl.Font             = Enum.Font.Gotham
		nameLbl.TextSize         = 12
		nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
		nameLbl.Text             = string.format("[%d] %s", i, catName)

		local distLbl = Instance.new("TextLabel", row)
		distLbl.Size             = UDim2.new(0.2, 0, 1, 0)
		distLbl.Position         = UDim2.new(0.65, 0, 0, 0)
		distLbl.BackgroundTransparency = 1
		distLbl.TextColor3       = Color3.fromRGB(140, 200, 140)
		distLbl.Font             = Enum.Font.Gotham
		distLbl.TextSize         = 11
		distLbl.Text             = tostring(dist) .. "st"

		local tpBtn = Instance.new("TextButton", row)
		tpBtn.Size            = UDim2.new(0.15, 0, 0.8, 0)
		tpBtn.Position        = UDim2.new(0.85, -2, 0.1, 0)
		tpBtn.Text            = "TP"
		tpBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 230)
		tpBtn.TextColor3      = Color3.new(1, 1, 1)
		tpBtn.Font            = Enum.Font.GothamBold
		tpBtn.TextSize        = 11
		tpBtn.BorderSizePixel = 0
		Instance.new("UICorner", tpBtn).CornerRadius = UDim.new(0, 4)

		tpBtn.MouseButton1Click:Connect(function()
			if tpToEntry(entry) then
				tpBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
				task.delay(1.2, function()
					tpBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 230)
				end)
			else
				tpBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
				task.delay(1.2, function()
					tpBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 230)
				end)
			end
		end)
	end
end

autoTPBtn.MouseButton1Click:Connect(function()
	local catName = scanner.selectedCat
	if not catName or not scanner.categoryData[catName] then
		scanStatusLabel.Text = "❌ Pilih kategori dulu!"
		return
	end

	scanner.running   = true
	autoTPBtn.Text    = "▶ Auto TP: RUNNING..."
	stopTPBtn.Visible = true

	task.spawn(function()
		while scanner.running do
			local items = scanner.categoryData[catName]
			if not items or #items == 0 then
				scanStatusLabel.Text = "❌ Tidak ada item di kategori ini"
				break
			end

			local myRoot = character and character:FindFirstChild("HumanoidRootPart")
			if not myRoot then task.wait(1); continue end

			for i, entry in ipairs(items) do
				if not scanner.running then break end
				if not entry.pivot or not entry.pivot.Parent then
					continue
				end
				tpToEntry(entry)
				autoTPBtn.Text = string.format(
					"▶ Auto TP: [%d/%d] %s", i, #items, catName
				)
				scanStatusLabel.Text = string.format(
					"✈️ TP ke %s #%d / %d", catName, i, #items
				)
				task.wait(scanner.delay)
			end
			scanner.running = false
		end

		autoTPBtn.Text    = "▶ Auto TP Semua: SELESAI ✅"
		stopTPBtn.Visible = false
		scanStatusLabel.Text = "✅ Selesai teleport semua " .. (scanner.selectedCat or "")
		task.delay(3, function()
			autoTPBtn.Text = "▶ Auto TP Semua: OFF"
		end)
	end)
end)

makeLabel(secAI, "━━━━━━ 📋 KATEGORI OBJEK ━━━━━━")

local catPanel = Instance.new("ScrollingFrame", secAI)
catPanel.Size                 = UDim2.new(1, 0, 0, 220)
catPanel.BackgroundColor3     = Color3.fromRGB(20, 20, 28)
catPanel.BorderSizePixel      = 0
catPanel.ScrollBarThickness   = 5
catPanel.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 140)
catPanel.CanvasSize           = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", catPanel).CornerRadius = UDim.new(0, 6)

local catLayout = Instance.new("UIListLayout", catPanel)
catLayout.Padding = UDim.new(0, 3)
catLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	catPanel.CanvasSize = UDim2.new(0, 0, 0, catLayout.AbsoluteContentSize.Y + 8)
end)

local activeCatBtn = nil

local function buildCategoryPanel()
	for _, c in ipairs(catPanel:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("Frame") or c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	activeCatBtn = nil

	local names = {}
	for name, _ in pairs(scanner.categoryData) do
		table.insert(names, name)
	end
	table.sort(names)

	if #names == 0 then
		local lbl = Instance.new("TextLabel", catPanel)
		lbl.Size               = UDim2.new(1, 0, 0, 28)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3         = Color3.fromRGB(180, 80, 80)
		lbl.Font               = Enum.Font.Gotham
		lbl.TextSize           = 12
		lbl.Text               = "  Tidak ada model ditemukan"
		return
	end

	for _, name in ipairs(names) do
		local items = scanner.categoryData[name]
		local count = #items

		local row = Instance.new("Frame", catPanel)
		row.Size            = UDim2.new(1, -6, 0, 34)
		row.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		row.BorderSizePixel = 0
		Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

		local catBtn = Instance.new("TextButton", row)
		catBtn.Size            = UDim2.new(0.78, 0, 1, 0)
		catBtn.BackgroundTransparency = 1
		catBtn.TextColor3      = Color3.fromRGB(200, 230, 255)
		catBtn.Font            = Enum.Font.Gotham
		catBtn.TextSize        = 12
		catBtn.TextXAlignment  = Enum.TextXAlignment.Left
		catBtn.Text            = "  " .. name

		local countLbl = Instance.new("TextLabel", row)
		countLbl.Size          = UDim2.new(0.22, 0, 1, 0)
		countLbl.Position      = UDim2.new(0.78, 0, 0, 0)
		countLbl.BackgroundTransparency = 1
		countLbl.TextColor3    = Color3.fromRGB(140, 200, 140)
		countLbl.Font          = Enum.Font.GothamBold
		countLbl.TextSize      = 12
		countLbl.Text          = "×" .. count

		catBtn.MouseButton1Click:Connect(function()
			if activeCatBtn then
				activeCatBtn.Parent.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			end
			row.BackgroundColor3 = Color3.fromRGB(50, 60, 110)
			activeCatBtn = catBtn

			scanner.selectedCat = name
			scanStatusLabel.Text = "📋 " .. name .. "  (" .. count .. " instance)"
			buildItemPanel(name)
		end)
	end
end

local scanBtn = makeButton(secAI, "🔍 Scan Workspace Sekarang", Color3.fromRGB(60, 130, 200))
scanBtn.MouseButton1Click:Connect(function()
	scanStatusLabel.Text = "⏳ Scanning..."
	task.spawn(function()
		scanner.categoryData = scanWorkspace()
		local total = 0
		local cats  = 0
		for _, v in pairs(scanner.categoryData) do
			total = total + #v
			cats  = cats + 1
		end
		buildCategoryPanel()
		scanStatusLabel.Text = string.format(
			"✅ %d kategori, %d model ditemukan", cats, total
		)
	end)
end)

-- Auto Collect Items
local autoCollectBtn = makeButton(secAI, "Auto Collect Items: OFF")
autoCollectBtn.MouseButton1Click:Connect(function()
	aiState.autoCollect = not aiState.autoCollect
	autoCollectBtn.Text = aiState.autoCollect and "Auto Collect: ON 💰" or "Auto Collect: OFF"
	if aiState.autoCollect then
		task.spawn(function()
			while aiState.autoCollect do
				task.wait(0.5)
				local myRoot = character and character:FindFirstChild("HumanoidRootPart")
				if not myRoot then continue end
				for _, obj in ipairs(workspace:GetDescendants()) do
					if (obj:IsA("BasePart") and obj.Name == "Loot")
					or (obj:IsA("Tool") and obj.CanBeDropped) then
						local pos = obj:IsA("BasePart") and obj.Position or obj:GetPivot().Position
						local dist = (myRoot.Position - pos).Magnitude
						if dist < 8 then
							myRoot.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
							task.wait(0.1)
						end
					end
				end
			end
		end)
	end
end)

-- =============== REMOTE SNIFFER & CODE COPIER (SAFE VERSION) ===============
makeLabel(secAI, "━━━━━━ 🕵️ REMOTE SNIFFER (SAFE) ━━━━━━")

local snifferState = {
    remotes = {},                -- { object, path, type, arguments = {}, clientCalls = {} }
    isHooking = false,
    hookConnection = nil,
    spyConnections = {},        -- koneksi OnClientEvent untuk mendengar server
}

-- Fungsi path aman
local function getPathSafe(obj)
    local path = obj.Name
    local parent = obj.Parent
    while parent and parent ~= game do
        path = parent.Name .. "." .. path
        parent = parent.Parent
    end
    return (parent and parent.ClassName or "game") .. "." .. path
end

-- Scan semua remote
local function scanAllRemotes()
    snifferState.remotes = {}
    local remotes = {}
    for _, obj in ipairs(game:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            local path = getPathSafe(obj)
            table.insert(remotes, {
                object = obj,
                path = path,
                type = obj.ClassName,
                arguments = {},       -- client -> server (harus manual input)
                serverCalls = {},     -- server -> client (tertangkap)
                spyConnection = nil,
            })
        end
    end
    -- Simpan di state
    for _, r in ipairs(remotes) do
        snifferState.remotes[r.path] = r
    end
    return remotes
end

-- Inject Spy: buat koneksi OnClientEvent untuk semua remote yang ditemukan
local function injectSpyOnClientEvents()
    -- Bersihkan spy lama
    for _, r in pairs(snifferState.remotes) do
        if r.spyConnection then
            r.spyConnection:Disconnect()
            r.spyConnection = nil
        end
    end
    for _, r in pairs(snifferState.remotes) do
        if r.object:IsA("RemoteEvent") then
            local conn
            conn = r.object.OnClientEvent:Connect(function(...)
                local args = {...}
                table.insert(r.serverCalls, args)
                if #r.serverCalls > 10 then
                    table.remove(r.serverCalls, 1)
                end
            end)
            r.spyConnection = conn
        elseif r.object:IsA("RemoteFunction") then
            local conn
            conn = r.object.OnClientInvoke:Connect(function(...)
                local args = {...}
                table.insert(r.serverCalls, args)
                if #r.serverCalls > 10 then
                    table.remove(r.serverCalls, 1)
                end
            end)
            r.spyConnection = conn
        end
    end
end

-- UI Elements
local snifferStatusLabel = makeLabel(secAI, "Status: Idle")
snifferStatusLabel.TextColor3 = Color3.fromRGB(160, 200, 255)

-- Tombol Scan
local scanRemotesBtn = makeButton(secAI, "🔍 Scan Remotes", Color3.fromRGB(60, 130, 200))
scanRemotesBtn.MouseButton1Click:Connect(function()
    snifferStatusLabel.Text = "⏳ Scanning..."
    scanAllRemotes()
    local count = 0
    for _, _ in pairs(snifferState.remotes) do count = count + 1 end
    snifferStatusLabel.Text = string.format("✅ %d remote ditemukan", count)
    updateSnifferList()
end)

-- Tombol Inject Spy (dengar panggilan server -> client)
local injectSpyBtn = makeButton(secAI, "🕵️ Inject Spy", Color3.fromRGB(100, 180, 100))
injectSpyBtn.MouseButton1Click:Connect(function()
    injectSpyOnClientEvents()
    snifferStatusLabel.Text = "🔴 Spy aktif - mendengarkan server calls"
end)

-- Tombol Clear
local clearSnifferBtn = makeButton(secAI, "🗑️ Clear", Color3.fromRGB(100, 100, 100))
clearSnifferBtn.MouseButton1Click:Connect(function()
    for _, r in pairs(snifferState.remotes) do
        if r.spyConnection then
            r.spyConnection:Disconnect()
            r.spyConnection = nil
        end
    end
    snifferState.remotes = {}
    updateSnifferList()
    snifferStatusLabel.Text = "Data dibersihkan"
end)

-- Panel daftar
local snifferListPanel = Instance.new("ScrollingFrame", secAI)
snifferListPanel.Size = UDim2.new(1, 0, 0, 180)
snifferListPanel.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
snifferListPanel.BorderSizePixel = 0
snifferListPanel.ScrollBarThickness = 5
snifferListPanel.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)
snifferListPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", snifferListPanel).CornerRadius = UDim.new(0, 6)

local snifferListLayout = Instance.new("UIListLayout", snifferListPanel)
snifferListLayout.Padding = UDim.new(0, 4)
snifferListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    snifferListPanel.CanvasSize = UDim2.new(0, 0, 0, snifferListLayout.AbsoluteContentSize.Y + 10)
end)

function updateSnifferList()
    -- Bersihkan
    for _, child in ipairs(snifferListPanel:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local sorted = {}
    for _, r in pairs(snifferState.remotes) do
        table.insert(sorted, r)
    end
    table.sort(sorted, function(a,b) return a.path < b.path end)

    for _, r in ipairs(sorted) do
        local row = Instance.new("Frame", snifferListPanel)
        row.Size = UDim2.new(1, -4, 0, 50)
        row.BackgroundColor3 = (r.type == "RemoteEvent") and Color3.fromRGB(30,30,50) or Color3.fromRGB(50,30,30)
        row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

        local info = r.path .. " [" .. r.type .. "]\n"
        if #r.serverCalls > 0 then
            local lastCall = r.serverCalls[#r.serverCalls]
            info = info .. "S→C: " .. table.concat(lastCall, ", "):sub(1,80)
        else
            info = info .. "S→C: (none)"
        end

        local infoLbl = Instance.new("TextLabel", row)
        infoLbl.Size = UDim2.new(0.85, 0, 1, 0)
        infoLbl.BackgroundTransparency = 1
        infoLbl.TextColor3 = Color3.new(1,1,1)
        infoLbl.Font = Enum.Font.Code
        infoLbl.TextSize = 10
        infoLbl.TextXAlignment = Enum.TextXAlignment.Left
        infoLbl.TextYAlignment = Enum.TextYAlignment.Top
        infoLbl.Text = info

        -- Copy path button
        local copyBtn = Instance.new("TextButton", row)
        copyBtn.Size = UDim2.new(0.15, 0, 1, 0)
        copyBtn.Position = UDim2.new(0.85, 0, 0, 0)
        copyBtn.Text = "📋"
        copyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        copyBtn.TextColor3 = Color3.new(1,1,1)
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 14
        Instance.new("UICorner", copyBtn).CornerRadius = UDim.new(0, 4)
        copyBtn.MouseButton1Click:Connect(function()
            pcall(function()
                if setclipboard then
                    setclipboard(r.path)
                    snifferStatusLabel.Text = "📋 Path disalin: " .. r.path
                else
                    snifferStatusLabel.Text = "⚠️ Clipboard not available"
                end
            end)
        end)
    end
    snifferListPanel.CanvasSize = UDim2.new(0, 0, 0, snifferListLayout.AbsoluteContentSize.Y + 10)
end

-- Copy All Info (siap kirim ke developer)
local copyAllBtn = makeStyledButton(secAI, "📤 Copy All Remote Info", Color3.fromRGB(80, 80, 180))
copyAllBtn.MouseButton1Click:Connect(function()
    local fullText = ""
    for _, r in pairs(snifferState.remotes) do
        fullText = fullText .. r.path .. " (" .. r.type .. ")\n"
        if #r.serverCalls > 0 then
            fullText = fullText .. "   S→C Args: "
            local lastCall = r.serverCalls[#r.serverCalls]
            fullText = fullText .. table.concat(lastCall, ", ") .. "\n"
        else
            fullText = fullText .. "   S→C Args: (no data)\n"
        end
    end
    if fullText == "" then
        snifferStatusLabel.Text = "⚠️ Tidak ada data untuk disalin"
        return
    end
    -- Fallback: tampilkan di output box agar user bisa select & copy
    pcall(function()
        if setclipboard then
            setclipboard(fullText)
            snifferStatusLabel.Text = "✅ Semua info remote disalin ke clipboard"
        else
            snifferStatusLabel.Text = "📋 Klik kanan > Select All (data di output Developer)"
            print("=== COPY START ===")
            print(fullText)
            print("=== COPY END ===")
        end
    end)
end)

-- =============== INVENTORY EXPLOIT (DEBUG VERSION) ===============
makeLabel(secAI, "━━━━━━ 💣 EXPLOIT INVENTORY (v3 Debug) ━━━━━━")

local exploitState = {
    itemName = "Fuel Canister",
    spamCount = 10,
}

-- Status label sendiri untuk exploit
local exploitStatusLabel = makeLabel(secAI, "Status: Idle")
exploitStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)

makeLabel(secAI, "Nama Item:")
local exploitItemNameBox = Instance.new("TextBox", secAI)
exploitItemNameBox.Size = UDim2.new(1, 0, 0, 28)
exploitItemNameBox.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
exploitItemNameBox.TextColor3 = Color3.new(1,1,1)
exploitItemNameBox.Font = Enum.Font.Gotham
exploitItemNameBox.Text = exploitState.itemName
exploitItemNameBox.TextSize = 13
exploitItemNameBox.ClearTextOnFocus = false
Instance.new("UICorner", exploitItemNameBox).CornerRadius = UDim.new(0,4)
exploitItemNameBox.FocusLost:Connect(function()
    exploitState.itemName = exploitItemNameBox.Text
end)

makeSlider(secAI, "Jumlah Spam", 1, 50, exploitState.spamCount, function(v)
    exploitState.spamCount = v
end)

-- Fungsi mencari remote global (fallback kalau sniffer kosong)
local function findRemoteGlobal(name)
    for _, obj in ipairs(game:GetDescendants()) do
        if (obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction")) and obj.Name == name then
            return obj
        end
    end
    return nil
end

-- Fungsi mendapatkan remote: pertama dari sniffer, lalu global
local function getRemote(name)
    -- Cek di sniffer dulu
    if snifferState and snifferState.remotes then
        for path, data in pairs(snifferState.remotes) do
            if data.object and data.object.Name == name then
                return data.object, path
            end
        end
    end
    -- Fallback global
    local remote = findRemoteGlobal(name)
    if remote then
        return remote, remote:GetFullName()
    end
    return nil, nil
end

-- Fungsi spam yang aman
local function spamRemote(remote, remoteName, args)
    if not remote then
        exploitStatusLabel.Text = "❌ Remote " .. remoteName .. " tidak ditemukan"
        return
    end
    local isFunction = remote:IsA("RemoteFunction")
    local method = isFunction and "InvokeServer" or "FireServer"
    local success = 0
    local fails = 0
    for _ = 1, exploitState.spamCount do
        task.spawn(function()
            local ok, err = pcall(function()
                remote[method](remote, unpack(args or {}))
            end)
            if ok then success = success + 1 else fails = fails + 1 end
        end)
    end
    task.wait(0.2)
    exploitStatusLabel.Text = string.format("✅ %s: %d ok, %d gagal", remoteName, success, fails)
end

-- Daftar nama remote target
local exploitRemoteNames = {
    "RequestBagDropItem",
    "RequestGiveItemToNPC",
    "RequestConsumeItem",
    "RequestScrapItem",
    "CraftItem",
    "RequestCollectCandy",
    "RequestCollectCoints",
}

-- Buat tombol untuk setiap remote
for _, name in ipairs(exploitRemoteNames) do
    local remote, path = getRemote(name)
    local btnColor = remote and Color3.fromRGB(200, 100, 50) or Color3.fromRGB(80, 80, 80)
    local btn = makeButton(secAI, "💣 " .. name, btnColor)
    btn.MouseButton1Click:Connect(function()
        -- Refresh remote setiap klik (bisa saja baru ada)
        local r, p = getRemote(name)
        if not r then
            exploitStatusLabel.Text = "❌ " .. name .. " tidak ditemukan. Coba Scan Remotes dulu."
            return
        end
        local args = (name == "RequestCollectCandy" or name == "RequestCollectCoints") and {} or {exploitState.itemName}
        spamRemote(r, name, args)
    end)
end

-- Tombol SPAM ALL
local spamAllBtn = makeStyledButton(secAI, "💥 SPAM ALL", Color3.fromRGB(255, 50, 50))
spamAllBtn.MouseButton1Click:Connect(function()
    local totalOk, totalFail = 0, 0
    for _, name in ipairs(exploitRemoteNames) do
        local r, _ = getRemote(name)
        if r then
            local args = (name == "RequestCollectCandy" or name == "RequestCollectCoints") and {} or {exploitState.itemName}
            spamRemote(r, name, args)
        else
            exploitStatusLabel.Text = "❌ " .. name .. " tidak ditemukan, skip"
        end
    end
end)

makeLabel(secAI, "⛔ Pastikan klik 'Scan Remotes' dulu jika tombol abu-abu.")

-- =============== DEVELOPER ===============
local execContainer = Instance.new("Frame", secDeveloper)
execContainer.Size               = UDim2.new(1, 0, 0, 230)
execContainer.BackgroundTransparency = 1

local codeBox = Instance.new("TextBox", execContainer)
codeBox.Size             = UDim2.new(1, 0, 0, 160)
codeBox.Position         = UDim2.new(0, 0, 0, 0)
codeBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
codeBox.TextColor3       = Color3.new(1, 1, 1)
codeBox.TextXAlignment   = Enum.TextXAlignment.Left
codeBox.TextYAlignment   = Enum.TextYAlignment.Top
codeBox.Font             = Enum.Font.Code
codeBox.TextSize         = 14
codeBox.ClearTextOnFocus = false
codeBox.MultiLine        = true
codeBox.Text             = "-- type Lua code here"
codeBox.BorderSizePixel  = 0
Instance.new("UICorner", codeBox).CornerRadius = UDim.new(0, 6)

local execBtn = makeButton(execContainer, "▶  Execute 🚀", Color3.fromRGB(60, 140, 60))
execBtn.Position = UDim2.new(0, 0, 0, 168)
execBtn.Size     = UDim2.new(1, 0, 0, 36)
execBtn.MouseButton1Click:Connect(function()
	local code   = codeBox.Text
	local fn, err = loadstring(code)
	if fn then
		task.spawn(function()
			xpcall(fn, function(e) warn("[Exec Error] " .. tostring(e)) end)
		end)
	else
		warn("[Syntax Error] " .. tostring(err))
	end
end)

-- =============== HELPER LOOPS ===============

-- Noclip loop
local noclipConn
setNoclipConnection = function()
	if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
	if state.noclip then
		noclipConn = RS.Stepped:Connect(function()
			if not character then character, humanoid = getCharHum() end
			for _, part in ipairs(character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide = false end
			end
		end)
	end
end

-- Fly loop
local flyConn
setFlyConnection = function()
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	if state.fly then
		local bodyGyro, bodyVel
		flyConn = RS.Heartbeat:Connect(function()
			if not character or not humanoid then return end
			local root = character:FindFirstChild("HumanoidRootPart")
			if not root then return end

			if not bodyGyro or not bodyGyro.Parent then
				bodyGyro              = Instance.new("BodyGyro", root)
				bodyGyro.MaxTorque    = Vector3.new(4e5, 4e5, 4e5)
				bodyGyro.P            = 12500
				bodyGyro.Name         = "FlyGyro"
			end
			if not bodyVel or not bodyVel.Parent then
				bodyVel              = Instance.new("BodyVelocity", root)
				bodyVel.MaxForce     = Vector3.new(4e5, 4e5, 4e5)
				bodyVel.Velocity     = Vector3.new(0, 0, 0)
				bodyVel.Name         = "FlyVel"
			end

			humanoid.PlatformStand = true

			local dir = Vector3.new(0, 0, 0)
			if UIS:IsKeyDown(Enum.KeyCode.W)           then dir += root.CFrame.LookVector  end
			if UIS:IsKeyDown(Enum.KeyCode.S)           then dir -= root.CFrame.LookVector  end
			if UIS:IsKeyDown(Enum.KeyCode.A)           then dir -= root.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.D)           then dir += root.CFrame.RightVector end
			if UIS:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.new(0, 1, 0)    end
			if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.new(0, 1, 0)    end

			bodyVel.Velocity = dir * (state.speed * state.flyMult)
			bodyGyro.CFrame  = CFrame.lookAt(root.Position, root.Position + Camera.CFrame.LookVector)
		end)
	else
		if humanoid then humanoid.PlatformStand = false end
		if character then
			for _, v in ipairs(character:GetDescendants()) do
				if (v:IsA("BodyGyro") and v.Name == "FlyGyro")
				or (v:IsA("BodyVelocity") and v.Name == "FlyVel") then
					v:Destroy()
				end
			end
		end
	end
end

-- Auto Respawn
RS.Heartbeat:Connect(function()
	if state.autoRespawn and humanoid and humanoid.Health <= 0 then
		task.wait(1)
		pcall(function()
			if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
				if player.Character.Humanoid.Health <= 0 then
					player:LoadCharacter()
				end
			end
		end)
	end
end)

-- Character reload handler
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid  = newChar:WaitForChild("Humanoid")
	setNoclipConnection()
	setFlyConnection()
	humanoid.WalkSpeed    = state.speed
	humanoid.UseJumpPower = true
	humanoid.JumpPower    = state.jump
end)

-- =============== INITIALISE ===============
setNoclipConnection()
setFlyConnection()

print("🤖 Ultimate AI Dev Tools Enhanced — All systems loaded successfully!")
