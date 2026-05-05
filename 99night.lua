-- =============== ITEM DUPE (AI TOOLS SECTION) ===============
-- Tambahkan setelah Auto Collect Items dan sebelum Developer tab
-- Pastikan semua definisi berikut diletakkan di dalam file enhanced_wolf_fixed.lua

-- ---- Dupe State ----
local dupeState = {
	running      = false,
	currentMethod = nil,
	delay        = 0.15,    -- interval antar aksi (detik)
	remoteName   = "MainEvent", -- bisa diganti via UI
}

-- ---- Dupe helper functions ----
local function getActiveTool()
	if character and character:FindFirstChildOfClass("Tool") then
		return character:FindFirstChildOfClass("Tool")
	end
	return nil
end

local function getBackpackTools()
	local tools = {}
	if player and player.Backpack then
		for _, item in ipairs(player.Backpack:GetChildren()) do
			if item:IsA("Tool") then
				table.insert(tools, item)
			end
		end
	end
	return tools
end

local function findRemoteEvent(name)
	-- Cari RemoteEvent di seluruh game dengan nama tertentu
	local remotes = {}
	for _, obj in ipairs(game:GetDescendants()) do
		if obj:IsA("RemoteEvent") and obj.Name == name then
			table.insert(remotes, obj)
		end
	end
	return remotes
end

-- ---- UI untuk Dupe Panel ----
makeLabel(secAI, "━━━━━━ 🔁 ITEM DUPE ━━━━━━")

-- Remote name input
local remoteNameBox = Instance.new("TextBox", secAI)
remoteNameBox.Size = UDim2.new(1, 0, 0, 30)
remoteNameBox.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
remoteNameBox.TextColor3 = Color3.new(1, 1, 1)
remoteNameBox.Font = Enum.Font.Gotham
remoteNameBox.PlaceholderText = "RemoteEvent name"
remoteNameBox.Text = dupeState.remoteName
remoteNameBox.TextSize = 14
remoteNameBox.ClearTextOnFocus = false
Instance.new("UICorner", remoteNameBox).CornerRadius = UDim.new(0, 4)
remoteNameBox.FocusLost:Connect(function()
	dupeState.remoteName = remoteNameBox.Text
end)

makeSlider(secAI, "Dupe Delay (detik)", 0.05, 1.0, dupeState.delay, function(v)
	dupeState.delay = v
end)

-- Status label
local dupeStatusLabel = makeLabel(secAI, "Status: Idle")
dupeStatusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)

-- Stop button (hidden normally)
local stopDupeBtn = makeButton(secAI, "⏹ STOP DUPE", Color3.fromRGB(200, 50, 50))
stopDupeBtn.Visible = false
stopDupeBtn.MouseButton1Click:Connect(function()
	dupeState.running = false
	dupeState.currentMethod = nil
	dupeStatusLabel.Text = "⏹ Stopped"
	stopDupeBtn.Visible = false
	-- re-enable all dupe buttons
	for _, btn in ipairs({dupeEquipBtn, dupeDropBtn, dupeRemoteBtn, dupeTimestopBtn, dupeFireAllBtn}) do
		if btn then btn.Visible = true end
	end
end)

-- Fungsi bantu untuk menonaktifkan tombol dupe saat sedang berjalan
local function setDupeRunning(methodName)
	dupeState.running = true
	dupeState.currentMethod = methodName
	dupeStatusLabel.Text = "⏳ Running: " .. methodName
	stopDupeBtn.Visible = true
	for _, btn in ipairs({dupeEquipBtn, dupeDropBtn, dupeRemoteBtn, dupeTimestopBtn, dupeFireAllBtn}) do
		if btn then btn.Visible = false end
	end
end

-- ============================================================
-- VERSI 1: Dupe via Equip/Unequip (Spam Activate)
-- ============================================================
local dupeEquipBtn = makeButton(secAI, "🔁 Dupe: Equip Spam", Color3.fromRGB(100, 160, 100))
dupeEquipBtn.MouseButton1Click:Connect(function()
	local tool = getActiveTool() or getBackpackTools()[1]
	if not tool then
		dupeStatusLabel.Text = "❌ No tool found in Backpack!"
		return
	end
	setDupeRunning("Equip Spam")
	task.spawn(function()
		while dupeState.running do
			pcall(function()
				-- Simulate equip/unequip quickly
				if humanoid then
					humanoid:EquipTool(tool)
				end
				task.wait(dupeState.delay)
				if tool.Parent == character then
					tool.Parent = player.Backpack
				end
			end)
			task.wait(dupeState.delay)
		end
	end)
end)

-- ============================================================
-- VERSI 2: Dupe via Drop & Equip (Dropping then re-equipping)
-- ============================================================
local dupeDropBtn = makeButton(secAI, "🔄 Dupe: Drop/Equip", Color3.fromRGB(100, 120, 160))
dupeDropBtn.MouseButton1Click:Connect(function()
	local tool = getActiveTool() or getBackpackTools()[1]
	if not tool then
		dupeStatusLabel.Text = "❌ No tool found!"
		return
	end
	setDupeRunning("Drop/Equip")
	task.spawn(function()
		while dupeState.running do
			pcall(function()
				-- Drop tool to ground (force parent to workspace)
				local oldParent = tool.Parent
				tool.Parent = workspace
				task.wait(0.05)
				-- Equip again
				if humanoid then
					humanoid:EquipTool(tool)
				end
				task.wait(dupeState.delay)
			end)
		end
	end)
end)

-- ============================================================
-- VERSI 3: Dupe via RemoteEvent Fire (Mengirim args berkali-kali)
--   - Cari remote dengan nama dari remoteNameBox
--   - Fire server dengan argument tool yang sedang dipegang
-- ============================================================
local dupeRemoteBtn = makeButton(secAI, "📡 Dupe: Remote Spam", Color3.fromRGB(160, 100, 130))
dupeRemoteBtn.MouseButton1Click:Connect(function()
	local remotes = findRemoteEvent(dupeState.remoteName)
	if #remotes == 0 then
		dupeStatusLabel.Text = "❌ Remote '"..dupeState.remoteName.."' not found!"
		return
	end
	local tool = getActiveTool()
	if not tool then
		dupeStatusLabel.Text = "⚠️ No active tool, using generic args"
	end
	setDupeRunning("Remote Spam ("..dupeState.remoteName..")")
	task.spawn(function()
		while dupeState.running do
			pcall(function()
				local args = { tool and tool.Name or "Tool" }
				-- Fire to all matching remotes
				for _, remote in ipairs(remotes) do
					remote:FireServer(unpack(args))
				end
			end)
			task.wait(dupeState.delay)
		end
	end)
end)

-- ============================================================
-- VERSI 4: Dupe via Timestop (Menghentikan simulasi fisika lokal)
--   - Set workspace.FallenPartsDestroyHeight negatif
--   - Drop tool, lalu teleport ke karakter agar dupe tidak hilang
-- ============================================================
local dupeTimestopBtn = makeButton(secAI, "⏱️ Dupe: Timestop Drop", Color3.fromRGB(160, 140, 100))
dupeTimestopBtn.MouseButton1Click:Connect(function()
	local tool = getActiveTool() or getBackpackTools()[1]
	if not tool then
		dupeStatusLabel.Text = "❌ No tool found!"
		return
	end
	setDupeRunning("Timestop Drop")
	task.spawn(function()
		while dupeState.running do
			pcall(function()
				-- Simulasikan "timestop" lokal
				local oldGravity = workspace.Gravity
				workspace.Gravity = 0
				-- Buang tool ke depan
				local handle = tool:FindFirstChild("Handle")
				if handle and character and character:FindFirstChild("HumanoidRootPart") then
					tool.Parent = workspace
					handle.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -5)
					handle.Velocity = Vector3.new(0,0,0)
					task.wait(0.2)
					-- Ambil kembali
					if humanoid then
						humanoid:EquipTool(tool)
					end
				end
				workspace.Gravity = oldGravity
			end)
			task.wait(dupeState.delay)
		end
	end)
end)

-- ============================================================
-- VERSI 5: Fire all methods bersamaan (agresif)
-- ============================================================
local dupeFireAllBtn = makeButton(secAI, "💥 Dupe: ALL METHODS", Color3.fromRGB(200, 80, 80))
dupeFireAllBtn.MouseButton1Click:Connect(function()
	local tool = getActiveTool() or getBackpackTools()[1]
	if not tool then
		dupeStatusLabel.Text = "❌ No tool found!"
		return
	end
	setDupeRunning("ALL METHODS (aggressive)")

	-- Jalankan semua metode secara paralel dalam thread terpisah
	task.spawn(function()
		while dupeState.running do
			pcall(function()
				-- Equip spam
				if humanoid then humanoid:EquipTool(tool) end
				task.wait(0.05)
				if tool.Parent == character then tool.Parent = player.Backpack end
			end)
		end
	end)
	task.spawn(function()
		while dupeState.running do
			pcall(function()
				local oldParent = tool.Parent
				tool.Parent = workspace
				task.wait(0.1)
				if humanoid then humanoid:EquipTool(tool) end
			end)
		end
	end)
	task.spawn(function()
		local remotes = findRemoteEvent(dupeState.remoteName)
		while dupeState.running and #remotes > 0 do
			pcall(function()
				for _, remote in ipairs(remotes) do
					remote:FireServer(tool and tool.Name or "Tool")
				end
			end)
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while dupeState.running do
			pcall(function()
				local oldGravity = workspace.Gravity
				workspace.Gravity = 0
				local handle = tool:FindFirstChild("Handle")
				if handle and character and character:FindFirstChild("HumanoidRootPart") then
					tool.Parent = workspace
					handle.CFrame = character.HumanoidRootPart.CFrame * CFrame.new(0,0,-3)
					task.wait(0.15)
					if humanoid then humanoid:EquipTool(tool) end
				end
				workspace.Gravity = oldGravity
			end)
			task.wait(0.3)
		end
	end)
end)

-- Pastikan variabel global untuk tombol-tombol terdefinisi
-- (diletakkan di atas button creation agar bisa diakses di setDupeRunning)
-- Ini adalah deklarasi forward, letakkan sebelum tombol-tombol didefinisikan
local dupeEquipBtn, dupeDropBtn, dupeRemoteBtn, dupeTimestopBtn, dupeFireAllBtn
