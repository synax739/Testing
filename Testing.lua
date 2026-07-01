-- // Delta Mobil – ESP + Gelişmiş Smooth Aimbot (2456 Optimizasyonu)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ====================== AYARLAR ======================
local Settings = {
    ESP = true,
    Aimbot = false,
    AimbotMaxDistance = 600,
    AimbotSmoothness = 0.15,      -- Ne kadar yumuşak (0.05 = çok hızlı, 0.4 = daha legit)
    AimbotFOV = 120,              -- Ekran merkezinden maksimum FOV
    TeamCheck = false,
    TriggerBot = false,           -- Opsiyonel: Hedef alındığında otomatik ateş (eğer silah varsa)

    ESP_Box = true,
    ESP_Name = true,
    ESP_Distance = true,
    ESP_HealthBar = true,
    ESP_BoxColor = Color3.fromRGB(255, 0, 100),
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
    if obj.box then obj.box.Thickness = 2; obj.box.Filled = false; obj.box.Transparency = 1 end
    
    obj.name = newDrawing("Text")
    if obj.name then 
        obj.name.Size = 14 
        obj.name.Center = true 
        obj.name.Outline = true 
        obj.name.Color = Color3.new(1,1,1) 
    end
    
    obj.dist = newDrawing("Text")
    if obj.dist then 
        obj.dist.Size = 13 
        obj.dist.Center = true 
        obj.dist.Outline = true 
        obj.dist.Color = Color3.new(1,1,1) 
    end
    
    obj.hpBg = newDrawing("Square")
    if obj.hpBg then obj.hpBg.Filled = true; obj.hpBg.Color = Color3.fromRGB(30,30,30); obj.hpBg.Transparency = 0.7 end
    
    obj.hpBar = newDrawing("Square")
    if obj.hpBar then obj.hpBar.Filled = true end

    ESPObjects[player] = obj
end

local function removeESP(player)
    local obj = ESPObjects[player]
    if obj then
        for _, v in pairs(obj) do pcall(function() v:Remove() end) end
        ESPObjects[player] = nil
    end
end

local function isInFront(position)
    local camPos = Camera.CFrame.Position
    local toTarget = (position - camPos).Unit
    return Camera.CFrame.LookVector:Dot(toTarget) > 0.1
end

local function getESPBox(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end

    local topPos = head and (head.Position + Vector3.new(0, 1.8, 0)) or (hrp.Position + Vector3.new(0, 3, 0))
    local bottomPos = hrp.Position - Vector3.new(0, 3, 0)

    local topScr = Camera:WorldToViewportPoint(topPos)
    local bottomScr = Camera:WorldToViewportPoint(bottomPos)

    if not topScr.Z > 0 and not bottomScr.Z > 0 then return nil end

    local boxH = math.abs(topScr.Y - bottomScr.Y)
    local boxW = boxH * 0.55
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

-- ====================== ESP ======================
local function updateESP()
    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.TeamCheck and player.Team == LocalPlayer.Team then
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

        local dist = myRoot and (myRoot.Position - hrp.Position).Magnitude or 0
        if dist > Settings.ESP_MaxDistance then
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

        if not ESPObjects[player] then createESP(player) end
        local obj = ESPObjects[player]

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
            obj.name.Position = box.TopCenter - Vector2.new(0, 18)
        end
        if Settings.ESP_Distance and obj.dist then
            obj.dist.Visible = true
            obj.dist.Text = math.floor(dist) .. "m"
            obj.dist.Position = box.BottomCenter + Vector2.new(0, 4)
        end
        if Settings.ESP_HealthBar and obj.hpBg and obj.hpBar then
            local hpRatio = hum.Health / hum.MaxHealth
            local barX = box.Position.X - 8
            local barH = box.Size.Y
            obj.hpBg.Visible = true
            obj.hpBg.Position = Vector2.new(barX, box.Position.Y)
            obj.hpBg.Size = Vector2.new(4, barH)
            
            local fillH = barH * hpRatio
            obj.hpBar.Visible = true
            obj.hpBar.Position = Vector2.new(barX, box.Position.Y + (barH - fillH))
            obj.hpBar.Size = Vector2.new(4, fillH)
            obj.hpBar.Color = Color3.fromRGB(255 * (1 - hpRatio), 255 * hpRatio, 0)
        end
    end
end

-- ====================== GELİŞMİŞ AIMBOT ======================
local CurrentTarget = nil

local function getClosestToCenter()
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local closestPlayer = nil
    local closestDist = math.huge

    local myChar = LocalPlayer.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myRoot then return nil end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.TeamCheck and player.Team == LocalPlayer.Team then continue end

        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not head or not hum or hum.Health <= 0 then continue end

        local dist = (myRoot.Position - head.Position).Magnitude
        if dist > Settings.AimbotMaxDistance then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
        if screenDist > Settings.AimbotFOV then continue end

        if screenDist < closestDist then
            closestDist = screenDist
            closestPlayer = player
        end
    end
    return closestPlayer
end

local function updateAimbot()
    if not Settings.Aimbot then 
        CurrentTarget = nil
        return 
    end

    local target = getClosestToCenter()
    CurrentTarget = target

    if target and target.Character then
        local head = target.Character:FindFirstChild("Head")
        if head then
            local currentCFrame = Camera.CFrame
            local targetCFrame = CFrame.lookAt(currentCFrame.Position, head.Position)
            
            -- Smooth interpolation (en önemli kısım)
            Camera.CFrame = currentCFrame:Lerp(targetCFrame, Settings.AimbotSmoothness)
        end
    end
end

-- ====================== MOBİL MENÜ ======================
local function createMobileMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "Delta_Kael_ESP"
    gui.ResetOnSpawn = false
    gui.Parent = game:GetService("CoreGui")

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 50, 0, 50)
    btn.Position = UDim2.new(1, -60, 0, 20)
    btn.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
    btn.Text = "Δ"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 28
    btn.Font = Enum.Font.GothamBold
    btn.Parent = gui

    local corner = Instance.new("UICorner", btn)
    corner.CornerRadius = UDim.new(1, 0)

    local menu = Instance.new("Frame")
    menu.Size = UDim2.new(0, 220, 0, 300)
    menu.Position = UDim2.new(1, -235, 0, 80)
    menu.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    menu.Visible = false
    menu.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.BackgroundColor3 = Color3.fromRGB(0, 100, 200)
    title.Text = "KAEL 2456 • ESP+AIM"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.Parent = menu

    local y = 45
    local function addToggle(text, default, settingKey)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(1, -20, 0, 35)
        toggle.Position = UDim2.new(0, 10, 0, y)
        toggle.BackgroundColor3 = default and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
        toggle.Text = text .. ": " .. (default and "AÇIK" or "KAPALI")
        toggle.TextColor3 = Color3.new(1,1,1)
        toggle.Font = Enum.Font.Gotham
        toggle.TextSize = 14
        toggle.Parent = menu

        toggle.MouseButton1Click:Connect(function()
            Settings[settingKey] = not Settings[settingKey]
            local state = Settings[settingKey]
            toggle.Text = text .. ": " .. (state and "AÇIK" or "KAPALI")
            toggle.BackgroundColor3 = state and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
        end)
        y += 45
    end

    addToggle("ESP", Settings.ESP, "ESP")
    addToggle("Aimbot", Settings.Aimbot, "Aimbot")
    addToggle("Team Check", Settings.TeamCheck, "TeamCheck")
    addToggle("Box", Settings.ESP_Box, "ESP_Box")
    addToggle("İsim", Settings.ESP_Name, "ESP_Name")
    addToggle("Mesafe", Settings.ESP_Distance, "ESP_Distance")
    addToggle("Can Barı", Settings.ESP_HealthBar, "ESP_HealthBar")

    btn.MouseButton1Click:Connect(function()
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

print("🚀 Kael 2456 Versiyonu Yüklendi - Daha az tespit, daha akıcı aimbot")
