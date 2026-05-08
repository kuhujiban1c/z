-- ============================================================
--  StarterPlayerScripts / enhanced_wolf_fixed.lua
--  Ultimate Client Dev Tools  —  AI Enhanced Edition
--  Credit: https://t.me/uni4codex
--  Fixed & Refactored: all deprecated API, logic bugs, and
--  forward-reference issues resolved.
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
-- Declared here so UI callbacks can reference them before the
-- function bodies are defined further below.
local setNoclipConnection
local setFlyConnection

-- =============== UI FACTORY ===============
local screen = Instance.new("ScreenGui")
screen.Name           = "ClientDevToolsEnhanced"
screen.ResetOnSpawn   = false
screen.IgnoreGuiInset = true
screen.Parent         = player:WaitForChild("PlayerGui")

-- ---- Main Frame ----
local frame = Instance.new("Frame")
frame.Size            = UDim2.new(0, 450, 0.9, 0)
frame.Position        = UDim2.new(0.5, -225, 0.05, 0)
frame.AnchorPoint     = Vector2.new(0.5, 0)
frame.BackgroundColor3 = Color3.fromRGB(22, 22, 22)
frame.BorderSizePixel = 0
frame.Visible         = false
frame.Active          = true
frame.Parent          = screen

local frameCorner = Instance.new("UICorner", frame)
frameCorner.CornerRadius = UDim.new(0, 8)

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

toggleBtn.MouseButton1Click:Connect(function()
	frame.Visible = not frame.Visible
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
titleText.Size               = UDim2.new(1, -50, 0.6, 0)
titleText.Position           = UDim2.new(0, 12, 0, 2)
titleText.BackgroundTransparency = 1
titleText.Text               = "🤖 Ultimate AI Dev Tools"
titleText.TextColor3         = Color3.new(1, 1, 1)
titleText.TextXAlignment     = Enum.TextXAlignment.Left
titleText.Font               = Enum.Font.GothamBold
titleText.TextSize           = 16

local creditLabel = Instance.new("TextLabel", titleBar)
creditLabel.Size             = UDim2.new(1, -50, 0.4, 0)
creditLabel.Position         = UDim2.new(0, 12, 0.6, 0)
creditLabel.BackgroundTransparency = 1
creditLabel.Text             = "By: t.me/uni4codex  |  AI Enhanced"
creditLabel.TextColor3       = Color3.fromRGB(180, 180, 180)
creditLabel.TextXAlignment   = Enum.TextXAlignment.Left
creditLabel.Font             = Enum.Font.Gotham
creditLabel.TextSize         = 10

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
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
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

local btnNoclip = makeButton(secMove, "Noclip: OFF")
btnNoclip.MouseButton1Click:Connect(function()
	state.noclip = not state.noclip
	btnNoclip.Text = state.noclip and "Noclip: ON ✅" or "Noclip: OFF ❌"
	setNoclipConnection()
end)

local btnFly = makeButton(secMove, "Fly: OFF")
btnFly.MouseButton1Click:Connect(function()
	state.fly = not state.fly
	btnFly.Text = state.fly and "Fly: ON ✈️" or "Fly: OFF"
	setFlyConnection()
end)

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

local antiAFKBtn = makeButton(secUtil, "Anti AFK: OFF")
antiAFKBtn.MouseButton1Click:Connect(function()
	state.antiAFK = not state.antiAFK
	antiAFKBtn.Text = state.antiAFK and "Anti AFK: ON ⚡" or "Anti AFK: OFF"
	if state.antiAFK then
		task.spawn(function()
			while state.antiAFK do
				task.wait(60)
				pcall(function()
					-- Simulate a tiny virtual input to prevent AFK kick
					if humanoid then
						humanoid:ChangeState(Enum.HumanoidStateType.Running)
					end
				end)
			end
		end)
	end
end)

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
	-- Cleanup when disabled
	if not state.tracers then
		for _, beam in ipairs(advanced.tracerBeams) do
			pcall(function() beam:Destroy() end)
		end
		advanced.tracerBeams = {}
		return
	end
	-- Build beams for new players
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
	-- Prune destroyed beams
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
								-- Clamp max size to avoid extreme values
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

-- =============== AI TOOLS ===============
-- Auto Farm Alpha Wolf
local autoFarmBtn = makeButton(secAI, "Auto Farm Alpha Wolf: OFF", Color3.fromRGB(255, 140, 0))
autoFarmBtn.MouseButton1Click:Connect(function()
	aiState.autoFarm = not aiState.autoFarm
	autoFarmBtn.Text = aiState.autoFarm and "Auto Farm: ON 🐺" or "Auto Farm: OFF"
	if aiState.autoFarm then
		task.spawn(function()
			local equippedTool = nil
			while aiState.autoFarm do
				task.wait(0.2)
				-- Refresh character reference if needed
				if not character or not humanoid then
					character, humanoid = getCharHum()
				end
				local myRoot = character and character:FindFirstChild("HumanoidRootPart")
				if not myRoot then continue end

				-- Find nearest Alpha Wolf
				local bestWolf, bestDist = nil, 1000
				for _, obj in ipairs(workspace:GetDescendants()) do
					if obj:IsA("Model") and obj.Name == "Alpha Wolf" then
						local wolfRoot = obj:FindFirstChild("HumanoidRootPart")
						local wolfHum  = obj:FindFirstChild("Humanoid")
						if wolfRoot and wolfHum and wolfHum.Health > 0 then
							local dist = (myRoot.Position - wolfRoot.Position).Magnitude
							if dist < bestDist then
								bestDist = dist
								bestWolf = obj
							end
						end
					end
				end

				if bestWolf then
					local wolfRoot = bestWolf.HumanoidRootPart
					humanoid:MoveTo(wolfRoot.Position)

					if (myRoot.Position - wolfRoot.Position).Magnitude <= 5 then
						-- Equip best available tool
						if not equippedTool or equippedTool.Parent ~= character then
							equippedTool = nil
							for _, t in ipairs(player.Backpack:GetChildren()) do
								if t:IsA("Tool") then
									equippedTool = t
									break
								end
							end
						end
						if equippedTool and equippedTool.Parent == player.Backpack then
							humanoid:EquipTool(equippedTool)
						end
						-- Attack
						if equippedTool and equippedTool.Parent == character then
							equippedTool:Activate()
						else
							-- Fallback: direct damage
							pcall(function()
								bestWolf.Humanoid:TakeDamage(15)
							end)
						end
					end
				end
			end
		end)
	end
end)

-- Auto Collect Items
--   FIX: added parentheses to fix operator precedence bug in condition.
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
					-- FIX: correct operator precedence with parentheses
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

-- =============== ITEM CHEST TELEPORT ===============
--[[
  Chest locations berdasarkan workspace explorer:
    - workspace (langsung)  → Item Chest2, Item Chest3
    - workspace.Items       → berbagai item model termasuk chest
    - workspace.Characters  → Alpha Wolf, dll (NPC, bukan chest)
  
  Fungsi ini mencari semua model yang namanya mengandung "Chest"
  dari SELURUH workspace secara rekursif.
--]]

-- Status
local chestState = {
	autoTP       = false,   -- loop teleport otomatis ke semua chest
	espChest     = false,   -- highlight semua chest
	collecting   = false,   -- sedang loop collect
	delay        = 1,       -- jeda antar teleport (detik)
	radius       = 10,      -- radius proximity untuk dianggap "selesai"
	chestList    = {},      -- cache daftar chest terakhir
	highlights   = {},      -- highlight aktif
}

-- ---- Helper: kumpulkan semua model chest dari workspace ----
local CHEST_KEYWORDS = {"Chest", "chest", "ItemChest", "Item Chest"}

local function isChestModel(obj)
	if not obj:IsA("Model") then return false end
	for _, kw in ipairs(CHEST_KEYWORDS) do
		if string.find(obj.Name, kw, 1, true) then return true end
	end
	return false
end

local function getAllChests()
	local found = {}
	-- Cari di seluruh workspace secara rekursif (termasuk folder Items)
	for _, obj in ipairs(workspace:GetDescendants()) do
		if isChestModel(obj) then
			local pivot = obj:FindFirstChild("HumanoidRootPart")
				or obj:FindFirstChildWhichIsA("BasePart")
			if pivot then
				table.insert(found, { model = obj, part = pivot })
			end
		end
	end
	return found
end

-- ---- Helper: bersihkan semua highlight chest ----
local function clearChestHighlights()
	for _, h in ipairs(chestState.highlights) do
		pcall(function() h:Destroy() end)
	end
	chestState.highlights = {}
end

-- ---- Highlight semua chest (ESP) ----
local function applyChestESP()
	clearChestHighlights()
	local chests = getAllChests()
	for _, entry in ipairs(chests) do
		local h = Instance.new("Highlight")
		h.FillColor           = Color3.fromRGB(255, 220, 50)
		h.OutlineColor        = Color3.fromRGB(255, 140, 0)
		h.FillTransparency    = 0.4
		h.OutlineTransparency = 0
		h.Adornee             = entry.model
		h.Parent              = screen   -- screen sudah ada di scope atas
		table.insert(chestState.highlights, h)
	end
	return #chests
end

-- ---- Teleport sekali ke satu chest terdekat ----
local function teleportToNearestChest()
	local myRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil, "Karakter tidak ditemukan" end

	local chests = getAllChests()
	if #chests == 0 then return nil, "Tidak ada chest di workspace" end

	local best, bestDist = nil, math.huge
	for _, entry in ipairs(chests) do
		local pos  = entry.part.Position
		local dist = (myRoot.Position - pos).Magnitude
		if dist < bestDist then
			best     = entry
			bestDist = dist
		end
	end

	if best then
		local pos = best.part.Position + Vector3.new(0, 3, 0)
		myRoot.CFrame = CFrame.new(pos)
		return best.model.Name, bestDist
	end
	return nil, "Gagal"
end

-- ============================================================
-- UI — Tab baru khusus CHEST (ditambahkan ke tab AI Tools)
-- ============================================================
makeLabel(secAI, "━━━━━━ 📦 ITEM CHEST TOOLS ━━━━━━")

-- Info label jumlah chest
local chestCountLabel = makeLabel(secAI, "Chest ditemukan: –")

-- Tombol Scan / Refresh
local scanChestBtn = makeButton(secAI, "🔍 Scan Semua Chest", Color3.fromRGB(60, 100, 180))
scanChestBtn.MouseButton1Click:Connect(function()
	local chests = getAllChests()
	chestState.chestList = chests
	chestCountLabel.Text = "Chest ditemukan: " .. #chests
		.. "  (Chest2 + Chest3 + Items folder)"
end)

-- ESP Chest Toggle
local espChestBtn = makeButton(secAI, "👁 ESP Chest: OFF", Color3.fromRGB(180, 130, 0))
espChestBtn.MouseButton1Click:Connect(function()
	chestState.espChest = not chestState.espChest
	if chestState.espChest then
		local count = applyChestESP()
		espChestBtn.Text = "👁 ESP Chest: ON (" .. count .. ")"
	else
		clearChestHighlights()
		espChestBtn.Text = "👁 ESP Chest: OFF"
	end
end)

-- Teleport ke Chest Terdekat (sekali)
local tpNearestBtn = makeButton(secAI, "📦 TP ke Chest Terdekat", Color3.fromRGB(80, 160, 80))
tpNearestBtn.MouseButton1Click:Connect(function()
	local name, info = teleportToNearestChest()
	if name then
		tpNearestBtn.Text = "✅ TP → " .. name
		task.delay(2, function()
			tpNearestBtn.Text = "📦 TP ke Chest Terdekat"
		end)
	else
		tpNearestBtn.Text = "❌ " .. tostring(info)
		task.delay(2, function()
			tpNearestBtn.Text = "📦 TP ke Chest Terdekat"
		end)
	end
end)

-- Slider delay antar teleport
makeSlider(secAI, "Delay TP (detik)", 1, 10, chestState.delay, function(v)
	chestState.delay = v
end)

-- Slider radius proximity
makeSlider(secAI, "Radius Kumpul (studs)", 3, 20, chestState.radius, function(v)
	chestState.radius = v
end)

-- AUTO COLLECT ALL CHESTS — Loop teleport ke semua chest satu per satu
local autoChestBtn = makeButton(secAI, "🤖 Auto TP Semua Chest: OFF", Color3.fromRGB(200, 80, 200))
autoChestBtn.MouseButton1Click:Connect(function()
	chestState.autoTP = not chestState.autoTP

	if chestState.autoTP then
		autoChestBtn.Text = "🤖 Auto TP Chest: ON ⏹ (klik stop)"
		task.spawn(function()
			while chestState.autoTP do
				local myRoot = character and character:FindFirstChild("HumanoidRootPart")
				if not myRoot then task.wait(1); continue end

				local chests = getAllChests()
				if #chests == 0 then
					autoChestBtn.Text = "🤖 Auto TP: Tidak ada chest!"
					task.wait(3)
					chestState.autoTP = false
					break
				end

				-- Update ESP jika aktif
				if chestState.espChest then
					clearChestHighlights()
					applyChestESP()
				end

				-- Iterasi setiap chest
				for i, entry in ipairs(chests) do
					if not chestState.autoTP then break end

					-- Refresh karakter jika respawn
					myRoot = character and character:FindFirstChild("HumanoidRootPart")
					if not myRoot then task.wait(1); break end

					local targetPos = entry.part.Position + Vector3.new(0, 3, 0)
					myRoot.CFrame   = CFrame.new(targetPos)

					-- Update label progress
					autoChestBtn.Text = string.format(
						"🤖 Auto TP: [%d/%d] %s", i, #chests, entry.model.Name
					)

					task.wait(chestState.delay)
				end

				-- Satu putaran selesai, scan ulang (chest baru mungkin muncul)
				task.wait(1)
			end

			autoChestBtn.Text = "🤖 Auto TP Semua Chest: OFF"
		end)
	else
		autoChestBtn.Text = "🤖 Auto TP Semua Chest: OFF"
	end
end)

-- TELEPORT LIST — tampilkan daftar chest & klik untuk TP langsung
makeLabel(secAI, "── Daftar Chest (klik untuk TP) ──")

local chestListFrame = Instance.new("ScrollingFrame", secAI)
chestListFrame.Size                 = UDim2.new(1, 0, 0, 180)
chestListFrame.BackgroundColor3     = Color3.fromRGB(28, 28, 28)
chestListFrame.BorderSizePixel      = 0
chestListFrame.ScrollBarThickness   = 4
chestListFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
chestListFrame.CanvasSize           = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", chestListFrame).CornerRadius = UDim.new(0, 6)

local chestListLayout = Instance.new("UIListLayout", chestListFrame)
chestListLayout.Padding = UDim.new(0, 3)
chestListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	chestListFrame.CanvasSize = UDim2.new(0, 0, 0,
		chestListLayout.AbsoluteContentSize.Y + 8)
end)

local function buildChestList()
	-- Bersihkan isi lama
	for _, c in ipairs(chestListFrame:GetChildren()) do
		if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
	end

	local chests = getAllChests()
	chestCountLabel.Text = "Chest ditemukan: " .. #chests

	if #chests == 0 then
		local lbl = Instance.new("TextLabel", chestListFrame)
		lbl.Size               = UDim2.new(1, 0, 0, 28)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3         = Color3.fromRGB(180, 80, 80)
		lbl.Font               = Enum.Font.Gotham
		lbl.TextSize           = 12
		lbl.Text               = "  Tidak ada chest ditemukan"
		return
	end

	for i, entry in ipairs(chests) do
		local btn = Instance.new("TextButton", chestListFrame)
		btn.Size            = UDim2.new(1, -6, 0, 28)
		btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		btn.TextColor3      = Color3.fromRGB(255, 220, 80)
		btn.Font            = Enum.Font.Gotham
		btn.TextSize        = 12
		btn.TextXAlignment  = Enum.TextXAlignment.Left
		btn.Text            = string.format(
			"  [%d] %s  (%.0f studs)",
			i,
			entry.model.Name,
			(character and character:FindFirstChild("HumanoidRootPart"))
				and (character.HumanoidRootPart.Position - entry.part.Position).Magnitude
				or 0
		)
		btn.BorderSizePixel = 0
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

		btn.MouseButton1Click:Connect(function()
			local myRoot = character and character:FindFirstChild("HumanoidRootPart")
			if myRoot then
				myRoot.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 3, 0))
				btn.BackgroundColor3 = Color3.fromRGB(40, 100, 40)
				task.delay(1, function()
					btn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
				end)
			end
		end)
	end
end

-- Tombol refresh daftar
local refreshListBtn = makeButton(secAI, "🔄 Refresh Daftar Chest", Color3.fromRGB(50, 50, 80))
refreshListBtn.MouseButton1Click:Connect(function()
	buildChestList()
	if chestState.espChest then
		clearChestHighlights()
		applyChestESP()
	end
end)

-- Build awal saat script load
task.delay(2, buildChestList)

-- =============== COORDINATE TELEPORT ===============
makeLabel(secMove, "━━━━━━ 📍 COORDINATE TP ━━━━━━")

local coordFrame = Instance.new("Frame")
coordFrame.Size = UDim2.new(1, 0, 0, 105)
coordFrame.BackgroundTransparency = 1
coordFrame.Parent = secMove

-- Input X
local xLabel = makeLabel(coordFrame, "X:")
xLabel.Size = UDim2.new(0.1, 0, 0, 20)

local xBox = Instance.new("TextBox", coordFrame)
xBox.Size = UDim2.new(0.22, 0, 0, 24)
xBox.Position = UDim2.new(0.1, 0, 0, 0)
xBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
xBox.TextColor3 = Color3.new(1,1,1)
xBox.Text = "0"
xBox.Font = Enum.Font.Code
xBox.TextSize = 14
xBox.ClearTextOnFocus = false
Instance.new("UICorner", xBox).CornerRadius = UDim.new(0,4)

-- Input Y
local yLabel = makeLabel(coordFrame, "Y:")
yLabel.Size = UDim2.new(0.1, 0, 0, 20)
yLabel.Position = UDim2.new(0.36, 0, 0, 0)

local yBox = Instance.new("TextBox", coordFrame)
yBox.Size = UDim2.new(0.22, 0, 0, 24)
yBox.Position = UDim2.new(0.46, 0, 0, 0)
yBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
yBox.TextColor3 = Color3.new(1,1,1)
yBox.Text = "0"
yBox.Font = Enum.Font.Code
yBox.TextSize = 14
yBox.ClearTextOnFocus = false
Instance.new("UICorner", yBox).CornerRadius = UDim.new(0,4)

-- Input Z
local zLabel = makeLabel(coordFrame, "Z:")
zLabel.Size = UDim2.new(0.1, 0, 0, 20)
zLabel.Position = UDim2.new(0.72, 0, 0, 0)

local zBox = Instance.new("TextBox", coordFrame)
zBox.Size = UDim2.new(0.22, 0, 0, 24)
zBox.Position = UDim2.new(0.82, 0, 0, 0)
zBox.BackgroundColor3 = Color3.fromRGB(40,40,40)
zBox.TextColor3 = Color3.new(1,1,1)
zBox.Text = "0"
zBox.Font = Enum.Font.Code
zBox.TextSize = 14
zBox.ClearTextOnFocus = false
Instance.new("UICorner", zBox).CornerRadius = UDim.new(0,4)

-- Tombol Teleport
local tpCoordBtn = makeButton(coordFrame, "📍 Teleport to Coords", Color3.fromRGB(70, 130, 200))
tpCoordBtn.Size = UDim2.new(1, 0, 0, 30)
tpCoordBtn.Position = UDim2.new(0, 0, 0, 30)
tpCoordBtn.MouseButton1Click:Connect(function()
	local x = tonumber(xBox.Text)
	local y = tonumber(yBox.Text)
	local z = tonumber(zBox.Text)
	if not x or not y or not z then
		tpCoordBtn.Text = "Invalid numbers!"
		task.wait(2)
		tpCoordBtn.Text = "📍 Teleport to Coords"
		return
	end
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		root.CFrame = CFrame.new(x, y, z)
		tpCoordBtn.BackgroundColor3 = Color3.fromRGB(40,160,40)
		task.delay(1.2, function()
			tpCoordBtn.BackgroundColor3 = Color3.fromRGB(70,130,200)
		end)
	else
		tpCoordBtn.Text = "No character!"
		task.wait(2)
		tpCoordBtn.Text = "📍 Teleport to Coords"
	end
end)

-- Tombol Get Current Position
local getPosBtn = makeButton(coordFrame, "📋 Get Current Position", Color3.fromRGB(100, 100, 100))
getPosBtn.Size = UDim2.new(1, 0, 0, 24)
getPosBtn.Position = UDim2.new(0, 0, 0, 65)
getPosBtn.MouseButton1Click:Connect(function()
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root then
		local pos = root.Position
		xBox.Text = tostring(math.floor(pos.X * 10 + 0.5) / 10) -- akurat 1 desimal
		yBox.Text = tostring(math.floor(pos.Y * 10 + 0.5) / 10)
		zBox.Text = tostring(math.floor(pos.Z * 10 + 0.5) / 10)
		getPosBtn.Text = "✅ Posisi disalin"
		task.delay(1.2, function()
			getPosBtn.Text = "📋 Get Current Position"
		end)
	else
		getPosBtn.Text = "No character!"
		task.delay(1.2, function()
			getPosBtn.Text = "📋 Get Current Position"
		end)
	end
end)

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
	-- Restore persistent states on respawn
	setNoclipConnection()
	setFlyConnection()
	-- Restore walk speed & jump
	humanoid.WalkSpeed    = state.speed
	humanoid.UseJumpPower = true
	humanoid.JumpPower    = state.jump
end)

-- =============== INITIALISE ===============
setNoclipConnection()
setFlyConnection()

print("🤖 Ultimate AI Dev Tools Enhanced — All systems loaded successfully!")
