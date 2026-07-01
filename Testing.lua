-- // Delta Mobil – Rivals ESP (Akıllı Renk) + Aimbot
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local cfg = {
    esp_on = true,
    esp_box = true,
    esp_name = true,
    esp_dist = true,
    esp_hp = true,
    esp_maxDist = 1000,
    esp_visibleColor = Color3.fromRGB(0, 255, 0),   -- Görüş açık = yeşil
    esp_hiddenColor = Color3.fromRGB(255, 0, 0),    -- Engel var = kırmızı
    aim_on = false,
    aim_mode = "Always",
    aim_fov = 30,
    aim_maxDist = 500,
    aim_smoothBase = 2.0,
    team_check = false
}

-- ESP çizim deposu
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

-- Güvenli görüş kontrolü (hata durumunda false döner)
local function checkVisibility(targetCharacter)
    if not targetCharacter then return false end
    local head = targetCharacter:FindFirstChild("Head")
    local hrp = targetCharacter:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end

    -- Önce kafa, yoksa gövdenin üst kısmı
    local targetPos = head and head.Position or (hrp.Position + Vector3.new(0, 1.5, 0))

    local myChar = LocalPlayer.Character
    if not myChar then return false end

    -- Kameranın biraz önünden başlat (kendi karakterine takılmayı önler)
    local origin = Camera.CFrame.Position + Camera.CFrame.LookVector * 0.5
    local direction = (targetPos - origin).Unit * 500

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {myChar, targetCharacter}
    params.FilterType = Enum.RaycastFilterType.Blacklist

    local success, result = pcall(function()
        return workspace:Raycast(origin, direction, params)
    end)
    if not success then return false end  -- hata alırsa görünmüyor say
    return result == nil
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

local refreshCounter = 0
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

        -- Görüş kontrolü (kafa/gövde üstü)
        local visible = checkVisibility(char)
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

    -- Anti-ban: rastgele sıfırlama
    refreshCounter = refreshCounter + 1
    if refreshCounter >= math.random(300, 600) then
        refreshCounter = 0
        for plr, _ in pairs(ESPData) do removeESP(plr) end
    end
end

-- ////////////////////////////////////////////////
-- // AIMBOT (En Yakın Hedef, Kamera + Yatay Karakter Dönüşü)
-- ////////////////////////////////////////////////
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

    local targetPos = targetPart.Position
    local camPos = Camera.CFrame.Position
    local desiredLook = CFrame.lookAt(camPos, targetPos)

    local randomSmooth = cfg.aim_smoothBase + math.random() * 1.5
    local alpha = 1 / randomSmooth
    if alpha > 1 then alpha = 1 end
    Camera.CFrame = Camera.CFrame:Lerp(desiredLook, alpha)

    -- Karakteri yalnızca yatayda döndür
    local myChar = LocalPlayer.Character
    if myChar and myChar:FindFirstChild("HumanoidRootPart") then
        local root = myChar.HumanoidRootPart
        local flatTarget = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
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
    if aimTick % math.random(2, 3) ~= 0 then
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

-- ////////////////////////////////////////////////
-- // MOBİL MENÜ
-- ////////////////////////////////////////////////
local function createMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SecureUI"
    gui.Parent = game.CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false

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

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 220)
    frame.Position = UDim2.new(1, -210, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 25)
    title.BackgroundColor3 = Color3.fromRGB(40,40,40)
    title.Text = "Rivals Panel"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.SourceSansBold

    local y = 30
    local function addToggle(name, default, callback)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        btn.Text = name .. ": " .. (default and "AÇIK" or "KAPALI")
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 13
        local toggled = default
        btn.MouseButton1Click:Connect(function()
            toggled = not toggled
            btn.Text = name .. ": " .. (toggled and "AÇIK" or "KAPALI")
            btn.BackgroundColor3 = toggled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
            callback(toggled)
        end)
        y = y + 30
    end

    addToggle("ESP", cfg.esp_on, function(v) cfg.esp_on = v end)
    addToggle("Aimbot", cfg.aim_on, function(v) cfg.aim_on = v end)
    addToggle("Takım Kontrol", cfg.team_check, function(v) cfg.team_check = v end)

    local modeBtn = Instance.new("TextButton", frame)
    modeBtn.Size = UDim2.new(1, -10, 0, 28)
    modeBtn.Position = UDim2.new(0, 5, 0, y)
    modeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    modeBtn.Text = "Aimbot: " .. cfg.aim_mode
    modeBtn.TextColor3 = Color3.new(1,1,1)
    modeBtn.Font = Enum.Font.SourceSans
    modeBtn.TextSize = 13
    modeBtn.MouseButton1Click:Connect(function()
        cfg.aim_mode = cfg.aim_mode == "Always" and "Touch" or "Always"
        modeBtn.Text = "Aimbot: " .. cfg.aim_mode
    end)

    openBtn.MouseButton1Click:Connect(function()
        frame.Visible = not frame.Visible
    end)
end

-- ////////////////////////////////////////////////
-- // BAŞLATMA
-- ////////////////////////////////////////////////
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function() if ESPData[p] then removeESP(p) end end)
end)

RunService.RenderStepped:Connect(function()
    updateESP()
    updateAimbot()
end)

createMenu()
print("✅ Rivals ESP (Canlı Renk) + Gelişmiş Aimbot hazır! Menü: sağ üst ⚙")
