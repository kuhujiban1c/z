-- =============== FUEL CANISTER EXPLOIT (AI TOOLS) ===============
makeLabel(secAI, "━━━━━━ 🛢️ FUEL CANISTER ━━━━━━")

local fuelState = {
    canisters = {},          -- { model, remote, owner, lastOwner, interacted, burnFuel }
    selectedCanister = nil,
    spamRunning = false,
    spamCount = 5,
    remoteName = "Interact", -- fallback nama remote
}

-- ---- Fungsi pembaca atribut & remote ----
local function scanFuelCanisters()
    local list = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name == "Fuel Canister" then
            local remote = nil
            -- Cari RemoteEvent di dalam model (prioritas)
            for _, child in ipairs(obj:GetDescendants()) do
                if child:IsA("RemoteEvent") then
                    remote = child
                    break
                end
            end
            -- Jika tidak ditemukan, coba cari global dengan nama
            if not remote then
                for _, ev in ipairs(game:GetDescendants()) do
                    if ev:IsA("RemoteEvent") and ev.Name == fuelState.remoteName then
                        remote = ev
                        break
                    end
                end
            end

            local owner = obj:GetAttribute("Owner") or "?"
            local lastOwner = obj:GetAttribute("LastOwner") or "?"
            local interacted = obj:GetAttribute("InteractedWith") or false
            local burnFuel = obj:GetAttribute("BurnFuel") or 0

            table.insert(list, {
                model = obj,
                remote = remote,
                owner = owner,
                lastOwner = lastOwner,
                interacted = interacted,
                burnFuel = burnFuel,
            })
        end
    end
    return list
end

-- ---- UI Elements ----
local fuelStatusLabel = makeLabel(secAI, "Status: Siap")
fuelStatusLabel.TextColor3 = Color3.fromRGB(160, 200, 255)

makeLabel(secAI, "Nama RemoteEvent (fallback):")
local fuelRemoteNameBox = Instance.new("TextBox", secAI)
fuelRemoteNameBox.Size = UDim2.new(1, 0, 0, 28)
fuelRemoteNameBox.BackgroundColor3 = Color3.fromRGB(34, 34, 44)
fuelRemoteNameBox.TextColor3 = Color3.new(1,1,1)
fuelRemoteNameBox.Font = Enum.Font.Gotham
fuelRemoteNameBox.Text = fuelState.remoteName
fuelRemoteNameBox.TextSize = 13
fuelRemoteNameBox.ClearTextOnFocus = false
Instance.new("UICorner", fuelRemoteNameBox).CornerRadius = UDim.new(0,4)
fuelRemoteNameBox.FocusLost:Connect(function()
    fuelState.remoteName = fuelRemoteNameBox.Text
end)

makeSlider(secAI, "Jumlah Spam", 1, 20, fuelState.spamCount, function(v)
    fuelState.spamCount = v
end)

-- List Canister Panel
local fuelListPanel = Instance.new("ScrollingFrame", secAI)
fuelListPanel.Size = UDim2.new(1, 0, 0, 140)
fuelListPanel.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
fuelListPanel.BorderSizePixel = 0
fuelListPanel.ScrollBarThickness = 5
fuelListPanel.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 130)
fuelListPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
Instance.new("UICorner", fuelListPanel).CornerRadius = UDim.new(0, 6)

local fuelListLayout = Instance.new("UIListLayout", fuelListPanel)
fuelListLayout.Padding = UDim.new(0, 3)
fuelListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    fuelListPanel.CanvasSize = UDim2.new(0, 0, 0, fuelListLayout.AbsoluteContentSize.Y + 8)
end)

local function buildFuelList()
    -- Clear list
    for _, c in ipairs(fuelListPanel:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local list = fuelState.canisters
    if #list == 0 then
        local lbl = Instance.new("TextLabel", fuelListPanel)
        lbl.Size = UDim2.new(1, 0, 0, 28)
        lbl.BackgroundTransparency = 1
        lbl.TextColor3 = Color3.fromRGB(180, 80, 80)
        lbl.Font = Enum.Font.Gotham
        lbl.TextSize = 12
        lbl.Text = "  Tidak ada Fuel Canister ditemukan"
        return
    end

    for i, data in ipairs(list) do
        local row = Instance.new("Frame", fuelListPanel)
        row.Size = UDim2.new(1, -6, 0, 36)
        row.BackgroundColor3 = data.interacted and Color3.fromRGB(30,40,30) or Color3.fromRGB(40,30,30)
        row.BorderSizePixel = 0
        Instance.new("UICorner", row).CornerRadius = UDim.new(0, 5)

        -- Info text
        local info = string.format("[%d] Owner:%s Int:%s Fuel:%d",
            i, data.owner, tostring(data.interacted), data.burnFuel)
        local infoLbl = Instance.new("TextLabel", row)
        infoLbl.Size = UDim2.new(0.75, 0, 1, 0)
        infoLbl.Position = UDim2.new(0, 4, 0, 0)
        infoLbl.BackgroundTransparency = 1
        infoLbl.TextColor3 = Color3.new(1,1,1)
        infoLbl.Font = Enum.Font.Gotham
        infoLbl.TextSize = 11
        infoLbl.TextXAlignment = Enum.TextXAlignment.Left
        infoLbl.Text = info

        -- Select button
        local selBtn = Instance.new("TextButton", row)
        selBtn.Size = UDim2.new(0.12, 0, 0.8, 0)
        selBtn.Position = UDim2.new(0.77, 0, 0.1, 0)
        selBtn.Text = "Pilih"
        selBtn.BackgroundColor3 = Color3.fromRGB(60, 130, 230)
        selBtn.TextColor3 = Color3.new(1,1,1)
        selBtn.Font = Enum.Font.GothamBold
        selBtn.TextSize = 10
        Instance.new("UICorner", selBtn).CornerRadius = UDim.new(0,4)
        selBtn.MouseButton1Click:Connect(function()
            fuelState.selectedCanister = data
            fuelStatusLabel.Text = "Dipilih: "..data.model:GetFullName()
        end)

        -- Spam langsung tombol
        local spamBtn = Instance.new("TextButton", row)
        spamBtn.Size = UDim2.new(0.12, 0, 0.8, 0)
        spamBtn.Position = UDim2.new(0.88, -2, 0.1, 0)
        spamBtn.Text = "Spam"
        spamBtn.BackgroundColor3 = Color3.fromRGB(200, 80, 80)
        spamBtn.TextColor3 = Color3.new(1,1,1)
        spamBtn.Font = Enum.Font.GothamBold
        spamBtn.TextSize = 10
        Instance.new("UICorner", spamBtn).CornerRadius = UDim.new(0,4)
        spamBtn.MouseButton1Click:Connect(function()
            if not data.remote then
                fuelStatusLabel.Text = "❌ Remote tidak ditemukan!"
                return
            end
            fuelState.spamRunning = true
            fuelStatusLabel.Text = "⏳ Spamming..."
            for _ = 1, fuelState.spamCount do
                task.spawn(function()
                    pcall(function()
                        data.remote:FireServer(data.model)
                    end)
                end)
            end
            wait(0.1)
            fuelState.spamRunning = false
            fuelStatusLabel.Text = "✅ Spam selesai"
        end)
    end
end

-- Tombol Scan
local scanFuelBtn = makeButton(secAI, "🔍 Scan Fuel Canisters", Color3.fromRGB(60, 130, 200))
scanFuelBtn.MouseButton1Click:Connect(function()
    fuelStatusLabel.Text = "⏳ Scanning..."
    fuelState.canisters = scanFuelCanisters()
    buildFuelList()
    fuelStatusLabel.Text = string.format("✅ %d canister ditemukan", #fuelState.canisters)
end)

-- Tombol Spam Semua yang belum InteractedWith
local spamAllFuelBtn = makeStyledButton(secAI, "💥 Spam Semua (Uninteracted)", Color3.fromRGB(220, 60, 60))
spamAllFuelBtn.MouseButton1Click:Connect(function()
    local targets = {}
    for _, data in ipairs(fuelState.canisters) do
        if not data.interacted and data.remote then
            table.insert(targets, data)
        end
    end
    if #targets == 0 then
        fuelStatusLabel.Text = "⚠️ Tidak ada canister yang belum diinteraksikan"
        return
    end
    fuelStatusLabel.Text = "💥 Spamming "..#targets.." canister..."
    fuelState.spamRunning = true
    for _, data in ipairs(targets) do
        for _ = 1, fuelState.spamCount do
            task.spawn(function()
                pcall(function()
                    data.remote:FireServer(data.model)
                end)
            end)
        end
        task.wait(0.05) -- sedikit jeda antar canister
    end
    wait(0.2)
    fuelState.spamRunning = false
    fuelStatusLabel.Text = "✅ Selesai spam semua"
end)

-- Stop spam (jika diperlukan)
local stopFuelSpamBtn = makeButton(secAI, "⏹ STOP SPAM", Color3.fromRGB(180, 40, 40))
stopFuelSpamBtn.MouseButton1Click:Connect(function()
    fuelState.spamRunning = false
    fuelStatusLabel.Text = "⏹ Dihentikan"
end)
