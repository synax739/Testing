-- // Delta ESP Script (Sade - Tracer ve Head Dot Kaldırıldı)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ESP Ayarları
local ESP = {
    BoxEnabled = true,
    NameEnabled = true,
    DistanceEnabled = true,
    HealthBarEnabled = true,
    MaxDistance = 1000,
    TeamCheck = false,
    VisibleColor = Color3.fromRGB(0, 255, 0),
    InvisibleColor = Color3.fromRGB(255, 0, 0)
}

local ESPData = {}

-- Drawing oluşturma (Delta uyumlu)
local function CreateDrawing(type)
    local success, drawing = pcall(function()
        return Drawing.new(type)
    end)
    if success and drawing then
        return drawing
    end
    return nil
end

-- World to Screen
local function WorldToScreen(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- Takım kontrolü
local function IsTeammate(player)
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team == player.Team
    end
    return false
end

-- ESP oluştur
local function CreateESP(player)
    if ESPData[player] then RemoveESP(player) end

    local drawings = {}

    -- Box
    drawings.Box = CreateDrawing("Square")
    if drawings.Box then
        drawings.Box.Visible = false
        drawings.Box.Thickness = 2
        drawings.Box.Filled = false
    end

    -- Name
    drawings.Name = CreateDrawing("Text")
    if drawings.Name then
        drawings.Name.Visible = false
        drawings.Name.Size = 13
        drawings.Name.Center = true
        drawings.Name.Outline = true
        drawings.Name.Color = Color3.fromRGB(255, 255, 255)
    end

    -- Distance
    drawings.Distance = CreateDrawing("Text")
    if drawings.Distance then
        drawings.Distance.Visible = false
        drawings.Distance.Size = 12
        drawings.Distance.Center = true
        drawings.Distance.Outline = true
        drawings.Distance.Color = Color3.fromRGB(255, 255, 255)
    end

    -- Health Bar arka plan
    drawings.HealthBg = CreateDrawing("Square")
    if drawings.HealthBg then
        drawings.HealthBg.Visible = false
        drawings.HealthBg.Filled = true
        drawings.HealthBg.Color = Color3.fromRGB(40, 40, 40)
    end

    -- Health Bar dolu kısım
    drawings.HealthBar = CreateDrawing("Square")
    if drawings.HealthBar then
        drawings.HealthBar.Visible = false
        drawings.HealthBar.Filled = true
    end

    ESPData[player] = drawings
end

-- ESP sil
local function RemoveESP(player)
    if not ESPData[player] then return end
    for _, d in pairs(ESPData[player]) do
        if d then pcall(function() d:Remove() end) end
    end
    ESPData[player] = nil
end

-- Bounding Box hesapla
local function GetBoundingBox(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")

    if not (head or hrp) or not humanoid then return nil end

    local cf, size = character:GetBoundingBox()
    local center = cf.Position
    local height = size.Y

    local topPos = center + Vector3.new(0, height/2, 0)
    local bottomPos = center + Vector3.new(0, -height/2, 0)

    local top, topOnScreen = WorldToScreen(topPos)
    local bottom, bottomOnScreen = WorldToScreen(bottomPos)

    if not topOnScreen and not bottomOnScreen then return nil end

    local boxHeight = math.abs(top.Y - bottom.Y)
    local boxWidth = boxHeight * 0.55

    return {
        Top = top,
        Bottom = bottom,
        Height = boxHeight,
        Width = boxWidth,
        Center = Vector2.new((top.X + bottom.X) / 2, (top.Y + bottom.Y) / 2),
        OnScreen = true
    }
end

-- Ana Render
local function RenderESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if ESP.TeamCheck and IsTeammate(player) then
            if ESPData[player] then RemoveESP(player) end
            continue
        end

        local character = player.Character
        if not character then
            if ESPData[player] then RemoveESP(player) end
            continue
        end

        local head = character:FindFirstChild("Head")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local hrp = character:FindFirstChild("HumanoidRootPart")

        if not (head or hrp) or not humanoid then continue end

        -- Mesafe
        local distance = 0
        local myChar = LocalPlayer.Character
        if myChar and myChar:FindFirstChild("HumanoidRootPart") then
            distance = (myChar.HumanoidRootPart.Position - (hrp or head).Position).Magnitude
        end

        if distance > ESP.MaxDistance then
            if ESPData[player] then
                for _, d in pairs(ESPData[player]) do
                    if d then d.Visible = false end
                end
            end
            continue
        end

        if not ESPData[player] then
            CreateESP(player)
        end

        local drawings = ESPData[player]
        if not drawings then continue end

        local box = GetBoundingBox(character)
        if not box then continue end

        -- Görünürlük kontrolü (raycast)
        local isVisible = false
        pcall(function()
            local raycastParams = RaycastParams.new()
            local ignoreList = {character}
            if myChar then table.insert(ignoreList, myChar) end
            raycastParams.FilterDescendantsInstances = ignoreList
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist

            local rayOrigin = Camera.CFrame.Position
            local rayDir = (head.Position - rayOrigin).Unit * 500
            local result = workspace:Raycast(rayOrigin, rayDir, raycastParams)
            isVisible = (result == nil)
        end)

        local color = isVisible and ESP.VisibleColor or ESP.InvisibleColor

        -- Box
        if ESP.BoxEnabled and drawings.Box then
            drawings.Box.Visible = true
            drawings.Box.Position = Vector2.new(box.Top.X - box.Width/2, box.Top.Y)
            drawings.Box.Size = Vector2.new(box.Width, box.Height)
            drawings.Box.Color = color
        end

        -- Name
        if ESP.NameEnabled and drawings.Name then
            drawings.Name.Visible = true
            drawings.Name.Text = player.Name
            drawings.Name.Position = Vector2.new(box.Top.X, box.Top.Y - 15)
        end

        -- Distance
        if ESP.DistanceEnabled and drawings.Distance then
            drawings.Distance.Visible = true
            drawings.Distance.Text = math.floor(distance) .. "m"
            drawings.Distance.Position = Vector2.new(box.Bottom.X, box.Bottom.Y + 2)
        end

        -- Health Bar
        if ESP.HealthBarEnabled and drawings.HealthBg and drawings.HealthBar then
            local healthPercent = humanoid.Health / humanoid.MaxHealth
            local barX = box.Top.X - box.Width/2 - 6
            local barHeight = box.Height

            drawings.HealthBg.Visible = true
            drawings.HealthBg.Position = Vector2.new(barX, box.Top.Y)
            drawings.HealthBg.Size = Vector2.new(3, barHeight)

            local filledHeight = barHeight * healthPercent
            drawings.HealthBar.Visible = true
            drawings.HealthBar.Position = Vector2.new(barX, box.Top.Y + (barHeight - filledHeight))
            drawings.HealthBar.Size = Vector2.new(3, filledHeight)

            local r = math.clamp(255 * (1 - healthPercent) * 2, 0, 255)
            local g = math.clamp(255 * healthPercent * 2, 0, 255)
            drawings.HealthBar.Color = Color3.fromRGB(r, g, 0)
        end
    end
end

-- Oyuncu eventleri
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if ESPData[player] then RemoveESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Render bağla
RunService.RenderStepped:Connect(RenderESP)
