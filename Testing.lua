-- // Delta - Mobil ESP & Aimbot (Tamir Edilmiş)
-- // Aimbot: hedef kilitlendikten sonra bırakmaz, sürekli hedeftedir.
-- // ESP: hareketliyken kayma yapmaz, stabil.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ////////////////////////////////////////////////
-- // AYARLAR
-- ////////////////////////////////////////////////
local Settings = {
    ESP = true,
    Aimbot = false,
    AimbotSmoothness = 0.3,    -- Düşük = hızlı (0.1 anlık)
    AimbotMaxDistance = 500,
    TeamCheck = false,
    ESP_Box = true,
    ESP_Name = true,
    ESP_Distance = true,
    ESP_HealthBar = true,
    ESP_BoxColor = Color3.fromRGB(255, 0, 0),
    ESP_MaxDistance = 1000
}

-- ////////////////////////////////////////////////
-- // ESP SİSTEMİ (Stabil, Head + RootPart tabanlı)
-- ////////////////////////////////////////////////
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
    local cameraPos = Camera.CFrame.Position
    local toTarget = (position - cameraPos).Unit
    return Camera.CFrame.LookVector:Dot(toTarget) > 0
end

local function getESPBox(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    local hum = character:FindFirstChildOfClass("Humanoid")

    -- Üst nokta: Head varsa head, yoksa hrp'den 2.5 yukarı
    local topPos, bottomPos
    if head then
        topPos = head.Position + Vector3.new(0, 1.2, 0) -- başın biraz üstü
    else
        topPos = hrp.Position + Vector3.new(0, 2.5, 0)
    end
    -- Alt nokta: hrp'den aşağı (yaklaşık ayak hizası)
    bottomPos = hrp.Position - Vector3.new(0, 2.8, 0)

    -- Ekrana yansıt
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
        BottomCenter = Vector2.new(centerX, boxY + boxH),
        OnScreen = true
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
        if not hrp then
            if ESPObjects[player] then removeESP(player) end
            continue
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then
            if ESPObjects[player] then removeESP(player) end
            continue
        end

        -- ESP kapalıysa çizimleri gizle
        if not Settings.ESP then
            if ESPObjects[player] then
                for _, d in pairs(ESPObjects[player]) do d.Visible = false end
            end
            continue
        end

        -- Yalnızca kameranın önünde olanları göster
        if not isInFront(hrp.Position) then
            if ESPObjects[player] then
                for _, d in pairs(ESPObjects[player]) do d.Visible = false end
            end
            continue
        end

        -- Mesafe kontrolü
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

        -- ESP objesini oluştur
        if not ESPObjects[player] then createESP(player) end
        local obj = ESPObjects[player]
        if not obj then continue end

        -- Box hesapla
        local box = getESPBox(char)
        if not box then
            for _, d in pairs(obj) do d.Visible = false end
            continue
        end

        -- Box çiz
        if Settings.ESP_Box and obj.box then
            obj.box.Visible = true
            obj.box.Position = box.Position
            obj.box.Size = box.Size
            obj.box.Color = Settings.ESP_BoxColor
        end
        -- İsim
        if Settings.ESP_Name and obj.name then
            obj.name.Visible = true
            obj.name.Text = player.Name
            obj.name.Position = box.TopCenter - Vector2.new(0, 15)
        end
        -- Mesafe
        if Settings.ESP_Distance and obj.dist then
            obj.dist.Visible = true
            obj.dist.Text = math.floor(dist) .. "m"
            obj.dist.Position = box.BottomCenter + Vector2.new(0, 2)
        end
        -- Can barı
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

-- ////////////////////////////////////////////////
-- // AIMBOT (Kilit sistemi, hareketli hedefte kopmaz)
-- ////////////////////////////////////////////////
local currentAimbotTarget = nil

local function getBestTarget()
    local best = nil
    local bestDist = Settings.AimbotMaxDistance
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if Settings.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then continue end
        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (head or hrp) or not hum or hum.Health <= 0 then continue end
        local targetPart = head or hrp
        local dist = (myPos - targetPart.Position).Magnitude
        if dist < bestDist then
            -- Kameranın önünde olma şartı (ilk seçimde)
            local toTarget = (targetPart.Position - Camera.CFrame.Position).Unit
            if Camera.CFrame.LookVector:Dot(toTarget) > 0.05 then -- küçük bir eşik
                bestDist = dist
                best = player
            end
        end
    end
    return best
end

local function aimAtTarget(targetPlayer)
    local char = targetPlayer.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local targetPart = head or hrp
    if not targetPart then return false end

    local targetPos = targetPart.Position
    local lookAt = CFrame.lookAt(Camera.CFrame.Position, targetPos)

    local smooth = Settings.AimbotSmoothness
    if smooth <= 0.1 then
        Camera.CFrame = lookAt
    else
        local alpha = 1 / smooth
        if alpha > 1 then alpha = 1 end
        Camera.CFrame = Camera.CFrame:Lerp(lookAt, alpha)
    end
    return true
end

local function updateAimbot()
    if not Settings.Aimbot then
        currentAimbotTarget = nil
        return
    end

    -- Mevcut hedef geçerli mi?
    if currentAimbotTarget then
        local char = currentAimbotTarget.Character
        local valid = false
        if char then
            local head = char:FindFirstChild("Head")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if (head or hrp) and hum and hum.Health > 0 then
                local targetPart = head or hrp
                local dist = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position - targetPart.Position).Magnitude or 0
                if dist <= Settings.AimbotMaxDistance then
                    valid = true
                end
            end
        end
        if not valid then
            currentAimbotTarget = nil
        end
    end

    -- Yeni hedef bul
    if not currentAimbotTarget then
        currentAimbotTarget = getBestTarget()
    end

    -- Varsa kilitlen
    if currentAimbotTarget then
        aimAtTarget(currentAimbotTarget)
    end
end

-- ////////////////////////////////////////////////
-- // MOBİL MENÜ
-- ////////////////////////////////////////////////
local function createMobileMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "MobileESP_Aimbot"
    gui.Parent = game.CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local toggleMenuBtn = Instance.new("TextButton")
    toggleMenuBtn.Size = UDim2.new(0, 45, 0, 45)
    toggleMenuBtn.Position = UDim2.new(1, -55, 0, 10)
    toggleMenuBtn.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
    toggleMenuBtn.Text = "E"
    toggleMenuBtn.TextColor3 = Color3.new(1,1,1)
    toggleMenuBtn.Font = Enum.Font.SourceSansBold
    toggleMenuBtn.TextSize = 22
    toggleMenuBtn.Parent = gui
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = toggleMenuBtn

    local menuFrame = Instance.new("Frame")
    menuFrame.Name = "MainMenu"
    menuFrame.Size = UDim2.new(0, 200, 0, 260)
    menuFrame.Position = UDim2.new(1, -210, 0, 65)
    menuFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    menuFrame.BorderSizePixel = 0
    menuFrame.Visible = false
    menuFrame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    title.Text = "ESP & Aimbot"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 16
    title.Parent = menuFrame

    local yOffset = 35
    local function addToggle(name, default, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 32)
        btn.Position = UDim2.new(0, 5, 0, yOffset)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
        btn.Text = name .. ": " .. (default and "ON" or "OFF")
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 14
        btn.Parent = menuFrame

        local toggled = default
        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            btn.Text = name .. ": " .. (toggled and "ON" or "OFF")
            btn.BackgroundColor3 = toggled and Color3.fromRGB(0, 180, 0) or Color3.fromRGB(180, 0, 0)
            if callback then callback(toggled) end
        end)
        yOffset = yOffset + 35
    end

    addToggle("ESP", Settings.ESP, function(val) Settings.ESP = val end)
    addToggle("Aimbot", Settings.Aimbot, function(val) Settings.Aimbot = val end)
    addToggle("Team Check", Settings.TeamCheck, function(val) Settings.TeamCheck = val end)
    addToggle("Box", Settings.ESP_Box, function(val) Settings.ESP_Box = val end)
    addToggle("Name", Settings.ESP_Name, function(val) Settings.ESP_Name = val end)
    addToggle("Distance", Settings.ESP_Distance, function(val) Settings.ESP_Distance = val end)
    addToggle("Health Bar", Settings.ESP_HealthBar, function(val) Settings.ESP_HealthBar = val end)

    toggleMenuBtn.MouseButton1Click:Connect(function()
        menuFrame.Visible = not menuFrame.Visible
    end)
end

-- ////////////////////////////////////////////////
-- // TEMİZLİK VE BAŞLATMA
-- ////////////////////////////////////////////////
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if ESPObjects[p] then removeESP(p) end
    end)
end)

-- Ana döngü
RunService.RenderStepped:Connect(function()
    updateESP()
    updateAimbot()
end)

createMobileMenu()

print("✅ Mobil ESP & Gelişmiş Aimbot hazır!")
print("🔴 Sağ üstteki butona dokunarak menüyü aç.")
