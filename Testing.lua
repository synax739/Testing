-- // Delta Mobil – ESP + Rivals Optimized Aimbot (Ayarlanabilir GUI)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ====================== AYARLAR ======================
local Settings = {
    ESP = true,
    Aimbot = false,
    AimbotMaxDistance = 700,
    AimbotSmoothness = 0.22,
    AimbotFOV = 130,
    Prediction = 0.08,
    TeamCheck = false,

    ESP_Box = true,
    ESP_Name = true,
    ESP_Distance = true,
    ESP_HealthBar = true,
    ESP_BoxColor = Color3.fromRGB(255, 0, 0),
    ESP_MaxDistance = 1000
}

local ESPObjects = {}

local function newDrawing(type)
    local s, d = pcall(function() return Drawing.new(type) end)
    return s and d or nil
end

local function createESP(player)
    local obj = {}
    obj.box = newDrawing("Square")
    if obj.box then obj.box.Thickness = 2 obj.box.Filled = false end
    obj.name = newDrawing("Text")
    if obj.name then obj.name.Size = 13 obj.name.Center = true obj.name.Outline = true obj.name.Color = Color3.new(1,1,1) end
    obj.dist = newDrawing("Text")
    if obj.dist then obj.dist.Size = 12 obj.dist.Center = true obj.dist.Outline = true obj.dist.Color = Color3.new(1,1,1) end
    obj.hpBg = newDrawing("Square")
    if obj.hpBg then obj.hpBg.Filled = true obj.hpBg.Color = Color3.fromRGB(40,40,40) end
    obj.hpBar = newDrawing("Square")
    if obj.hpBar then obj.hpBar.Filled = true end
    ESPObjects[player] = obj
end

local function removeESP(player)
    local obj = ESPObjects[player]
    if not obj then return end
    for _, v in pairs(obj) do pcall(function() v:Remove() end) end
    ESPObjects[player] = nil
end

local function isInFront(position)
    local camPos = Camera.CFrame.Position
    local toTarget = (position - camPos).Unit
    return Camera.CFrame.LookVector:Dot(toTarget) > 0.08
end

local function getESPBox(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end

    local topPos = head and (head.Position + Vector3.new(0, 1.5, 0)) or (hrp.Position + Vector3.new(0, 2.5, 0))
    local bottomPos = hrp.Position - Vector3.new(0, hum.HipHeight, 0)

    local topScr, topOn = Camera:WorldToViewportPoint(topPos)
    local bottomScr, botOn = Camera:WorldToViewportPoint(bottomPos)

    if not topOn and not botOn then return nil end

    local boxH = math.abs(topScr.Y - bottomScr.Y)
    local boxW = boxH * 0.5
    local centerX = (topScr.X + bottomScr.X) / 2
    local boxX = centerX - boxW / 2
    local boxY = math.min(topScr.Y, bottomScr.Y)

    return {
        Position = Vector2.new(boxX, boxY),
        Size = Vector2.new(boxW, boxH),
        TopCenter = Vector2.new(centerX, boxY),
        BottomCenter = Vector2.new(centerX, boxY + boxH)
    }
end

local function updateESP()
    local myChar = LocalPlayer.Character
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
            if ESPObjects[player] then removeESP(player) end
            continue
        end
        local char = player.Character
        if not char then
            if ESPObjects[player] then removeESP(player) end
            continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            if ESPObjects[player] then removeESP(player) end
            continue
        end

        if not Settings.ESP then
            if ESPObjects[player] then
                for _, d in pairs(ESPObjects[player]) do d.Visible = false end
            end
            continue
        end

        if not isInFront(hrp.Position) then
            if ESPObjects[player] then
                for _, d in pairs(ESPObjects[player]) do d.Visible = false end
            end
            continue
        end

        local dist = 0
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            dist = (myChar.HumanoidRootPart.Position - hrp.Position).Magnitude
        end
        if dist > Settings.ESP_MaxDistance then
            if ESPObjects[player] then
                for _, d in pairs(ESPObjects[player]) do d.Visible = false end
            end
            continue
        end

        if not ESPObjects[player] then createESP(player) end
        local obj = ESPObjects[player]
        if not obj then continue end

        local box = getESPBox(char)
        if not box then
            for _, d in pairs(obj) do d.Visible = false end
            continue
        end

        if Settings.ESP_Box and obj.box then
            obj.box.Visible = true
            obj.box.Position = box.Position
            obj.box.Size = box.Size
            obj.box.Color = Settings.ESP_BoxColor
        end
        if Settings.ESP_Name and obj.name then
            obj.name.Visible = true
            obj.name.Text = player.Name
            obj.name.Position = box.TopCenter - Vector2.new(0, 15)
        end
        if Settings.ESP_Distance and obj.dist then
            obj.dist.Visible = true
            obj.dist.Text = math.floor(dist) .. "m"
            obj.dist.Position = box.BottomCenter + Vector2.new(0, 2)
        end
        if Settings.ESP_HealthBar and obj.hpBg and obj.hpBar then
            local hp = hum.Health / hum.MaxHealth
            local barX = box.Position.X - 8
            local barH = box.Size.Y
            obj.hpBg.Visible = true
            obj.hpBg.Position = Vector2.new(barX, box.Position.Y)
            obj.hpBg.Size = Vector2.new(3, barH)
            local fill = barH * hp
            obj.hpBar.Visible = true
            obj.hpBar.Position = Vector2.new(barX, box.Position.Y + (barH - fill))
            obj.hpBar.Size = Vector2.new(3, fill)
            obj.hpBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
        end
    end
end

local function getBestTarget()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestPlayer = nil
    local closestDist = math.huge

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then continue end

        local char = player.Character
        if not char then continue end

        local head = char:FindFirstChild("Head")
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        local hum = char:FindFirstChildOfClass("Humanoid")

        if not hum or hum.Health <= 0 then continue end

        local targetPart = head or torso
        if not targetPart then continue end

        local dist = (myRoot.Position - targetPart.Position).Magnitude
        if dist > Settings.AimbotMaxDistance then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen then continue end

        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if screenDist > Settings.AimbotFOV then continue end

        if screenDist < closestDist then
            closestDist = screenDist
            closestPlayer = {Player = player, TargetPart = targetPart}
        end
    end
    return closestPlayer
end

local function updateAimbot()
    if not Settings.Aimbot then return end

    local targetData = getBestTarget()
    if targetData and targetData.TargetPart then
        local targetPos = targetData.TargetPart.Position
        local velocity = targetData.TargetPart.Velocity or Vector3.new(0,0,0)
        targetPos = targetPos + velocity * Settings.Prediction

        local current = Camera.CFrame
        local targetCFrame = CFrame.lookAt(current.Position, targetPos)
        Camera.CFrame = current:Lerp(targetCFrame, Settings.AimbotSmoothness)
    end
end

-- ====================== GELİŞTİRİLMİŞ MOBİL MENÜ ======================
local function createMobileMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "Kael_Rivals_Menu"
    gui.ResetOnSpawn = false
    gui.Parent = game.CoreGui or LocalPlayer:WaitForChild("PlayerGui")

    local mainBtn = Instance.new("TextButton")
    mainBtn.Size = UDim2.new(0, 50, 0, 50)
    mainBtn.Position = UDim2.new(1, -60, 0, 15)
    mainBtn.BackgroundColor3 = Color3.fromRGB(220, 0, 80)
    mainBtn.Text = "⚙"
    mainBtn.TextColor3 = Color3.new(1,1,1)
    mainBtn.TextSize = 28
    mainBtn.Font = Enum.Font.GothamBold
    mainBtn.Parent = gui
    Instance.new("UICorner", mainBtn).CornerRadius = UDim.new(1,0)

    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 240, 0, 420)
    menu.Position = UDim2.new(1, -255, 0, 75)
    menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    menu.Visible = false
    menu.Parent = gui
    Instance.new("UICorner", menu).CornerRadius = UDim.new(0, 8)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    title.Text = "KAEL 2456 - RIVALS"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.Parent = menu

    local y = 50

    local function addToggle(name, default, key)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -20, 0, 36)
        btn.Position = UDim2.new(0, 10, 0, y)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        btn.Text = name .. ": " .. (default and "ON" or "OFF")
        btn.TextColor3 = Color3.new(1,1,1)
        btn.TextSize = 14
        btn.Font = Enum.Font.Gotham
        btn.Parent = menu

        btn.MouseButton1Click:Connect(function()
            Settings[key] = not Settings[key]
            local state = Settings[key]
            btn.Text = name .. ": " .. (state and "ON" or "OFF")
            btn.BackgroundColor3 = state and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        end)
        y += 46
    end

    local function addSlider(name, key, minVal, maxVal, step)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 20)
        label.Position = UDim2.new(0, 10, 0, y)
        label.BackgroundTransparency = 1
        label.Text = name .. ": " .. Settings[key]
        label.TextColor3 = Color3.new(1,1,1)
        label.TextSize = 13
        label.Font = Enum.Font.Gotham
        label.Parent = menu
        y += 22

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -20, 0, 30)
        box.Position = UDim2.new(0, 10, 0, y)
        box.BackgroundColor3 = Color3.fromRGB(40,40,40)
        box.Text = tostring(Settings[key])
        box.TextColor3 = Color3.new(1,1,1)
        box.ClearTextOnFocus = false
        box.Parent = menu
        Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

        box.FocusLost:Connect(function()
            local num = tonumber(box.Text)
            if num then
                num = math.clamp(num, minVal, maxVal)
                Settings[key] = num
                label.Text = name .. ": " .. num
                box.Text = tostring(num)
            else
                box.Text = tostring(Settings[key])
            end
        end)
        y += 45
    end

    -- Toggle'lar
    addToggle("ESP", Settings.ESP, "ESP")
    addToggle("Aimbot", Settings.Aimbot, "Aimbot")
    addToggle("Team Check", Settings.TeamCheck, "TeamCheck")

    -- Slider'lar (Ayarlanabilir değerler)
    addSlider("Smoothness", "AimbotSmoothness", 0.05, 0.6, 0.01)
    addSlider("FOV", "AimbotFOV", 30, 300, 5)
    addSlider("Prediction", "Prediction", 0, 0.25, 0.01)

    mainBtn.MouseButton1Click:Connect(function()
        menu.Visible = not menu.Visible
    end)
end

-- ====================== BAŞLAT ======================
Players.PlayerRemoving:Connect(removeESP)

RunService.RenderStepped:Connect(function()
    updateESP()
    updateAimbot()
end)

createMobileMenu()

print("✅ Ayarlanabilir GUI Yüklendi! Smoothness, FOV ve Prediction menüden değiştirilebilir.")
