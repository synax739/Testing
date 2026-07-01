-- // Delta Mobil – Rivals: ESP (Gelişmiş Raycast) + Aimbot (Hareket Tahmini) + Speed Slider + Panel

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- AYARLAR
local cfg = {
    esp_on = true,
    esp_box = true,
    esp_name = true,
    esp_dist = true,
    esp_hp = true,
    esp_maxDist = 1000,
    esp_visibleColor = Color3.fromRGB(0, 255, 0),
    esp_hiddenColor = Color3.fromRGB(255, 0, 0),
    aim_on = false,
    aim_mode = "Always",
    aim_fov = 30,
    aim_maxDist = 500,
    aim_smoothBase = 1.8, -- daha hızlı tepki
    speed_on = false,
    speed_value = 16,      -- gerçek walkSpeed (slider'dan hesaplanacak)
    team_check = false
}

-- ==============================================
-- ESP SİSTEMİ (Raycast: FindPartOnRayWithIgnoreList)
-- ==============================================
local ESPData = {}

local function newDrawing(t)
    local ok, d = pcall(function() return Drawing.new(t) end)
    return ok and d or nil
end

local function createESP(plr)
    local d = {}
    d.box = newDrawing("Square")
    if d.box then d.box.Thickness = 2 d.box.Filled = false end
    d.name = newDrawing("Text")
    if d.name then d.name.Size = 13 d.name.Center = true d.name.Outline = true d.name.Color = Color3.new(1,1,1) end
    d.dist = newDrawing("Text")
    if d.dist then d.dist.Size = 12 d.dist.Center = true d.dist.Outline = true d.dist.Color = Color3.new(1,1,1) end
    d.hpBg = newDrawing("Square")
    if d.hpBg then d.hpBg.Filled = true d.hpBg.Color = Color3.fromRGB(40,40,40) end
    d.hpBar = newDrawing("Square")
    if d.hpBar then d.hpBar.Filled = true end
    ESPData[plr] = d
end

local function removeESP(plr)
    local d = ESPData[plr]
    if not d then return end
    for _, v in pairs(d) do pcall(function() v:Remove() end) end
    ESPData[plr] = nil
end

local function isInFront(pos)
    local camPos = Camera.CFrame.Position
    return Camera.CFrame.LookVector:Dot((pos - camPos).Unit) > 0
end

-- Görüş kontrolü (eski güvenilir yöntem)
local function isTargetVisible(character)
    if not character then return false end
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    local myChar = LocalPlayer.Character
    if not myChar then return false end

    local origin = Camera.CFrame.Position + Camera.CFrame.LookVector * 0.8
    local ignoreList = {myChar, character}

    local targets = {}
    if head then table.insert(targets, head.Position) end
    table.insert(targets, hrp.Position + Vector3.new(0, 1.5, 0))

    for _, targetPos in ipairs(targets) do
        local direction = (targetPos - origin).Unit * 500
        local ray = Ray.new(origin, direction)
        local hit = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
        if not hit then
            return true
        end
    end
    return false
end

local function getBox(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return nil end

    local top = head and (head.Position + Vector3.new(0, 1.5, 0)) or (hrp.Position + Vector3.new(0, 2.5, 0))
    local bottom = hrp.Position - Vector3.new(0, hum.HipHeight, 0)
    local ts, on1 = Camera:WorldToViewportPoint(top)
    local bs, on2 = Camera:WorldToViewportPoint(bottom)
    if not on1 and not on2 then return nil end

    local h = math.abs(ts.Y - bs.Y)
    local w = h * 0.5
    local cx = (ts.X + bs.X) / 2
    return {
        pos = Vector2.new(cx - w/2, math.min(ts.Y, bs.Y)),
        size = Vector2.new(w, h),
        top = Vector2.new(cx, math.min(ts.Y, bs.Y)),
        bottom = Vector2.new(cx, math.min(ts.Y, bs.Y) + h)
    }
end

local function updateESP()
    local my = LocalPlayer.Character
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if cfg.team_check and LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then
            if ESPData[plr] then removeESP(plr) end
            continue
        end
        local char = plr.Character
        if not char then
            if ESPData[plr] then removeESP(plr) end
            continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            if ESPData[plr] then removeESP(plr) end
            continue
        end

        if not cfg.esp_on then
            if ESPData[plr] then
                for _, v in pairs(ESPData[plr]) do v.Visible = false end
            end
            continue
        end

        if not isInFront(hrp.Position) then
            if ESPData[plr] then
                for _, v in pairs(ESPData[plr]) do v.Visible = false end
            end
            continue
        end

        local dist = 0
        if my and my:FindFirstChild("HumanoidRootPart") then
            dist = (my.HumanoidRootPart.Position - hrp.Position).Magnitude
        end
        if dist > cfg.esp_maxDist then
            if ESPData[plr] then
                for _, v in pairs(ESPData[plr]) do v.Visible = false end
            end
            continue
        end

        if not ESPData[plr] then createESP(plr) end
        local d = ESPData[plr]
        if not d then continue end

        local box = getBox(char)
        if not box then
            for _, v in pairs(d) do v.Visible = false end
            continue
        end

        -- Görüş rengi (düzeltilmiş raycast)
        local visible = isTargetVisible(char)
        local color = visible and cfg.esp_visibleColor or cfg.esp_hiddenColor

        if cfg.esp_box and d.box then
            d.box.Visible = true
            d.box.Position = box.pos
            d.box.Size = box.size
            d.box.Color = color
        end
        if cfg.esp_name and d.name then
            d.name.Visible = true
            d.name.Text = plr.Name
            d.name.Position = box.top - Vector2.new(0, 15)
        end
        if cfg.esp_dist and d.dist then
            d.dist.Visible = true
            d.dist.Text = math.floor(dist) .. "m"
            d.dist.Position = box.bottom + Vector2.new(0, 2)
        end
        if cfg.esp_hp and d.hpBg and d.hpBar then
            local hp = hum.Health / hum.MaxHealth
            local barX = box.pos.X - 8
            d.hpBg.Visible = true
            d.hpBg.Position = Vector2.new(barX, box.pos.Y)
            d.hpBg.Size = Vector2.new(3, box.size.Y)
            local fill = box.size.Y * hp
            d.hpBar.Visible = true
            d.hpBar.Position = Vector2.new(barX, box.pos.Y + (box.size.Y - fill))
            d.hpBar.Size = Vector2.new(3, fill)
            d.hpBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0)
        end
    end
end

-- ==============================================
-- AIMBOT (Hareket Tahmini Eklenmiş)
-- ==============================================
local currentTarget = nil

local function getBestTarget()
    local best = nil
    local bestDist = cfg.aim_maxDist
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position
    local camPos = Camera.CFrame.Position
    local lookVec = Camera.CFrame.LookVector

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if cfg.team_check and LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then continue end
        local char = plr.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (head or hrp) or not hum or hum.Health <= 0 then continue end
        local targetPart = head or hrp
        local targetPos = targetPart.Position
        local dist = (myPos - targetPos).Magnitude
        if dist >= bestDist then continue end

        local toTarget = (targetPos - camPos).Unit
        local angle = math.acos(math.clamp(lookVec:Dot(toTarget), -1, 1))
        if angle > math.rad(cfg.aim_fov) then continue end

        bestDist = dist
        best = plr
    end
    return best
end

local function aimAt(targetPlayer)
    local char = targetPlayer.Character
    if not char then return false end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local targetPart = head or hrp
    if not targetPart then return false end

    -- Hareket tahmini
    local velocity = (hrp and hrp.Velocity) or Vector3.zero
    local predictedPos = targetPart.Position + velocity * 0.15  -- 0.15 saniye ilerisi
    local camPos = Camera.CFrame.Position
    local desiredLook = CFrame.lookAt(camPos, predictedPos)

    local alpha = math.clamp(1 / cfg.aim_smoothBase, 0.1, 1)
    Camera.CFrame = Camera.CFrame:Lerp(desiredLook, alpha)

    -- Karakteri yatayda döndür
    local myChar = LocalPlayer.Character
    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
        local root = myChar.HumanoidRootPart
        local flatTarget = Vector3.new(predictedPos.X, root.Position.Y, predictedPos.Z)
        local rootLookAt = CFrame.lookAt(root.Position, flatTarget)
        local hum = myChar:FindFirstChildOfClass("Humanoid")
        if hum then hum.AutoRotate = false end
        pcall(function()
            root.CFrame = root.CFrame:Lerp(rootLookAt, alpha)
        end)
    end
    return true
end

local aimTick = 0
local function updateAimbot()
    if not cfg.aim_on then
        currentTarget = nil
        return
    end

    local shouldAim = (cfg.aim_mode == "Always") or
        UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or
        UserInputService:IsMouseButtonPressed(Enum.UserInputType.Touch)

    if not shouldAim then
        currentTarget = nil
        return
    end

    aimTick = aimTick + 1
    if aimTick % 2 ~= 0 then
        if currentTarget and currentTarget.Character and currentTarget.Character:FindFirstChildOfClass("Humanoid") then
            aimAt(currentTarget)
        end
        return
    end

    local newTarget = getBestTarget()
    if newTarget then
        currentTarget = newTarget
        aimAt(currentTarget)
    else
        currentTarget = nil
    end
end

-- ==============================================
-- SPEED HACK (Otomatik yeniden uygulama)
-- ==============================================
local function applySpeed()
    if LocalPlayer.Character then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and cfg.speed_on then
            hum.WalkSpeed = cfg.speed_value
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function()
    -- Yeniden doğduktan hemen sonra birkaç kere dene
    for i = 1, 10 do
        task.wait(0.1)
        applySpeed()
    end
end)

-- ==============================================
-- PANEL (Slider'lı Speed, Kategoriler)
-- ==============================================
local function createPanel()
    local gui = Instance.new("ScreenGui")
    gui.Name = "RivalsHack"
    gui.Parent = game.CoreGui or LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Açma butonu
    local openBtn = Instance.new("TextButton")
    openBtn.Size = UDim2.new(0, 40, 0, 40)
    openBtn.Position = UDim2.new(1, -50, 0, 10)
    openBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    openBtn.Text = "⚙"
    openBtn.TextColor3 = Color3.new(1,1,1)
    openBtn.Font = Enum.Font.SourceSansBold
    openBtn.TextSize = 20
    openBtn.Parent = gui
    Instance.new("UICorner", openBtn).CornerRadius = UDim.new(0, 20)

    -- Panel
    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 300, 0, 240)
    panel.Position = UDim2.new(1, -310, 0, 60)
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)

    -- Sürükleme
    local drag = false
    local dragStart = nil
    local startPos = nil
    panel.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            drag = true
            dragStart = input.Position
            startPos = panel.Position
        end
    end)
    panel.InputEnded:Connect(function() drag = false end)
    panel.InputChanged:Connect(function(input)
        if drag and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Başlık
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 28)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    title.Text = "Rivals Panel"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold
    title.Parent = panel

    -- Sol menü
    local sidebar = Instance.new("Frame")
    sidebar.Size = UDim2.new(0, 80, 1, -28)
    sidebar.Position = UDim2.new(0, 0, 0, 28)
    sidebar.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    sidebar.Parent = panel

    -- Sağ içerik
    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -80, 1, -28)
    content.Position = UDim2.new(0, 80, 0, 28)
    content.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    content.Parent = panel

    local currentPage = nil

    local function showPage(page)
        if currentPage then currentPage.Visible = false end
        if page then page.Visible = true end
        currentPage = page
    end

    -- Kategori butonları
    local function addCategory(name, y, page)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -6, 0, 32)
        btn.Position = UDim2.new(0, 3, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.Text = name
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSansBold
        btn.TextSize = 13
        btn.Parent = sidebar
        btn.MouseButton1Click:Connect(function() showPage(page) end)
    end

    -- Toggle yardımcısı
    local function addToggle(parent, name, default, callback, yPos)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, yPos)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        btn.Text = name .. ": " .. (default and "AÇIK" or "KAPALI")
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 12
        btn.Parent = parent
        local toggled = default
        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            btn.Text = name .. ": " .. (toggled and "AÇIK" or "KAPALI")
            btn.BackgroundColor3 = toggled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
            callback(toggled)
        end)
        return btn
    end

    -- SAYFA: ESP
    local espPage = Instance.new("Frame")
    espPage.Size = UDim2.new(1, 0, 1, 0)
    espPage.BackgroundTransparency = 1
    espPage.Parent = content

    addToggle(espPage, "ESP", cfg.esp_on, function(v) cfg.esp_on = v end, 5)
    addToggle(espPage, "Kutu", cfg.esp_box, function(v) cfg.esp_box = v end, 35)
    addToggle(espPage, "İsim", cfg.esp_name, function(v) cfg.esp_name = v end, 65)
    addToggle(espPage, "Mesafe", cfg.esp_dist, function(v) cfg.esp_dist = v end, 95)
    addToggle(espPage, "Can Barı", cfg.esp_hp, function(v) cfg.esp_hp = v end, 125)

    -- SAYFA: AIMBOT
    local aimPage = Instance.new("Frame")
    aimPage.Size = UDim2.new(1, 0, 1, 0)
    aimPage.BackgroundTransparency = 1
    aimPage.Parent = content

    addToggle(aimPage, "Aimbot", cfg.aim_on, function(v) cfg.aim_on = v end, 5)

    local modeBtn = Instance.new("TextButton")
    modeBtn.Size = UDim2.new(1, -10, 0, 28)
    modeBtn.Position = UDim2.new(0, 5, 0, 35)
    modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    modeBtn.Text = "Mod: " .. cfg.aim_mode
    modeBtn.TextColor3 = Color3.new(1,1,1)
    modeBtn.Font = Enum.Font.SourceSans
    modeBtn.TextSize = 12
    modeBtn.Parent = aimPage
    modeBtn.MouseButton1Click:Connect(function()
        cfg.aim_mode = (cfg.aim_mode == "Always") and "Touch" or "Always"
        modeBtn.Text = "Mod: " .. cfg.aim_mode
    end)

    addToggle(aimPage, "Takım Kontrol", cfg.team_check, function(v) cfg.team_check = v end, 65)

    -- SAYFA: SPEED (Slider)
    local speedPage = Instance.new("Frame")
    speedPage.Size = UDim2.new(1, 0, 1, 0)
    speedPage.BackgroundTransparency = 1
    speedPage.Parent = content

    addToggle(speedPage, "Speed Hack", cfg.speed_on, function(v)
        cfg.speed_on = v
        if v then
            applySpeed()
        else
            if LocalPlayer.Character then
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end, 5)

    -- Slider yapımı
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(1, -10, 0, 20)
    sliderLabel.Position = UDim2.new(0, 5, 0, 40)
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.Text = "Gerçek Hız: " .. cfg.speed_value
    sliderLabel.TextColor3 = Color3.new(1,1,1)
    sliderLabel.Font = Enum.Font.SourceSans
    sliderLabel.TextSize = 12
    sliderLabel.Parent = speedPage

    -- Slider çubuğu arkaplan
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Size = UDim2.new(1, -20, 0, 10)
    sliderTrack.Position = UDim2.new(0, 10, 0, 65)
    sliderTrack.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = speedPage
    Instance.new("UICorner", sliderTrack).CornerRadius = UDim.new(0, 5)

    -- Slider doldurma (opsiyonel)
    local sliderFill = Instance.new("Frame")
    sliderFill.Size = UDim2.new(0, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(0, 180, 0)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 5)

    -- Tutamak
    local handle = Instance.new("TextButton")
    handle.Size = UDim2.new(0, 22, 0, 22)
    handle.Position = UDim2.new(0, 0, 0.5, -11)
    handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    handle.Text = ""
    handle.BorderSizePixel = 0
    handle.Parent = sliderTrack
    Instance.new("UICorner", handle).CornerRadius = UDim.new(1, 0)

    -- Slider değer aralığı: min 16, max 100 (gerçek WalkSpeed 32-200)
    local minSpeed = 16
    local maxSpeed = 100
    local function updateSliderValue(relativeX)
        local trackWidth = sliderTrack.AbsoluteSize.X
        local clampedX = math.clamp(relativeX, 0, trackWidth)
        local fraction = clampedX / trackWidth
        local rawValue = minSpeed + (maxSpeed - minSpeed) * fraction
        cfg.speed_value = math.floor(rawValue + 0.5)
        -- Gerçek WalkSpeed iki katı
        local displaySpeed = cfg.speed_value * 2
        sliderLabel.Text = "Gerçek Hız: " .. displaySpeed .. " (" .. cfg.speed_value .. ")"
        handle.Position = UDim2.new(0, clampedX - handle.Size.X.Offset/2, 0.5, -11)
        sliderFill.Size = UDim2.new(0, clampedX, 1, 0)
        if cfg.speed_on then applySpeed() end
    end

    -- Başlangıç konumu
    local ini
