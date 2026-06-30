-- // Delta ESP - Tek Renk, Sadece Önündekiler
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Ayarlar
local ESP = {
    Box = true,
    Name = true,
    Distance = true,
    HealthBar = true,
    MaxDistance = 1000,
    TeamCheck = false,
    BoxColor = Color3.fromRGB(255, 0, 0) -- Tek renk, hep kırmızı
}

local ESPObjects = {}

-- Drawing
local function newDrawing(type)
    local s, d = pcall(function() return Drawing.new(type) end)
    return s and d or nil
end

-- ESP oluştur
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

-- ESP sil
local function removeESP(player)
    local obj = ESPObjects[player]
    if not obj then return end
    for _, v in pairs(obj) do pcall(function() v:Remove() end) end
    ESPObjects[player] = nil
end

-- Önde mi kontrolü
local function isInFront(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not (head or hrp) then return false end
    local targetPos = (head or hrp).Position
    local cameraPos = Camera.CFrame.Position
    local toTarget = (targetPos - cameraPos).Unit
    return Camera.CFrame.LookVector:Dot(toTarget) > 0
end

-- Ana döngü
local function render()
    local myChar = LocalPlayer.Character
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if ESP.TeamCheck and LocalPlayer.Team and player.Team and LocalPlayer.Team == player.Team then
            if ESPObjects[player] then removeESP(player) end
            continue
        end

        local char = player.Character
        if not char then
            if ESPObjects[player] then removeESP(player) end
            continue
        end

        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (head or hrp) or not hum then
            if ESPObjects[player] then removeESP(player) end
            continue
        end

        -- Sadece öndekiler
        if not isInFront(char) then
            if ESPObjects[player] then
                for _, d in pairs(ESPObjects[player]) do d.Visible = false end
            end
            continue
        end

        -- Mesafe
        local dist = 0
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            dist = (myChar.HumanoidRootPart.Position - (hrp or head).Position).Magnitude
        end
        if dist > ESP.MaxDistance then
            if ESPObjects[player] then
                for _, d in pairs(ESPObjects[player]) do d.Visible = false end
            end
            continue
        end

        if not ESPObjects[player] then createESP(player) end
        local obj = ESPObjects[player]
        if not obj then continue end

        -- Bounding box
        local cf, size = char:GetBoundingBox()
        local topPos = cf.Position + Vector3.new(0, size.Y/2, 0)
        local bottomPos = cf.Position - Vector3.new(0, size.Y/2, 0)
        local topScr, topOn = Camera:WorldToViewportPoint(topPos)
        local bottomScr, botOn = Camera:WorldToViewportPoint(bottomPos)
        if not topOn and not botOn then
            for _, d in pairs(obj) do d.Visible = false end
            continue
        end

        local boxH = math.abs(topScr.Y - bottomScr.Y)
        local boxW = boxH * 0.55
        local boxX = topScr.X - boxW/2
        local boxY = topScr.Y

        -- Box (tek renk, görünürlük kontrolü yok)
        if ESP.Box and obj.box then
            obj.box.Visible = true
            obj.box.Position = Vector2.new(boxX, boxY)
            obj.box.Size = Vector2.new(boxW, boxH)
            obj.box.Color = ESP.BoxColor -- Sabit renk
        end

        -- İsim
        if ESP.Name and obj.name then
            obj.name.Visible = true
            obj.name.Text = player.Name
            obj.name.Position = Vector2.new(topScr.X, topScr.Y - 15)
        end

        -- Mesafe
        if ESP.Distance and obj.dist then
            obj.dist.Visible = true
            obj.dist.Text = math.floor(dist) .. "m"
            obj.dist.Position = Vector2.new(bottomScr.X, bottomScr.Y + 2)
        end

        -- Can barı
        if ESP.HealthBar and obj.hpBg and obj.hpBar then
            local hp = hum.Health / hum.MaxHealth
            local barX = boxX - 8
            obj.hpBg.Visible = true
            obj.hpBg.Position = Vector2.new(barX, boxY)
            obj.hpBg.Size = Vector2.new(3, boxH)

            local fill = boxH * hp
            obj.hpBar.Visible = true
            obj.hpBar.Position = Vector2.new(barX, boxY + (boxH - fill))
            obj.hpBar.Size = Vector2.new(3, fill)
            obj.hpBar.Color = Color3.fromRGB(255 * (1 - hp), 255 * hp, 0) -- yeşil->kırmızı
        end
    end
end

-- Eventler
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function()
        if ESPObjects[p] then removeESP(p) end
    end)
end)

RunService.RenderStepped:Connect(render)
