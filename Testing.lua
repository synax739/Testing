-- // Delta ESP Script
-- // GitHub: https://github.com/kullaniciadi/delta-esp

-- Servisleri al
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui") or game:GetService("StarterGui")

-- ESP Settings
local ESP = {
    BoxEnabled = true,
    TracerEnabled = true,
    NameEnabled = true,
    DistanceEnabled = true,
    HealthBarEnabled = true,
    HeadDotEnabled = true,
    MaxDistance = 1000,
    TeamCheck = false,
    VisibleColor = Color3.fromRGB(0, 255, 0),
    InvisibleColor = Color3.fromRGB(255, 0, 0)
}

-- ESP Veri tablosu
local ESPData = {}

-- Drawing fonksiyonları
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
local function WorldToScreen(position)
    local screenPos, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen
end

-- Takım kontrolü
local function IsTeammate(player)
    if LocalPlayer.Team and player.Team then
        return LocalPlayer.Team == player.Team
    end
    return false
end

-- ESP oluşturma
local function CreateESP(player)
    if ESPData[player] then
        RemoveESP(player)
    end
    
    local drawings = {}
    
    -- Box
    drawings.Box = CreateDrawing("Square")
    if drawings.Box then
        drawings.Box.Visible = false
        drawings.Box.Thickness = 2
        drawings.Box.Filled = false
        drawings.Box.Color = Color3.fromRGB(255, 0, 0)
    end
    
    -- Tracer
    drawings.Tracer = CreateDrawing("Line")
    if drawings.Tracer then
        drawings.Tracer.Visible = false
        drawings.Tracer.Thickness = 1.5
        drawings.Tracer.Color = Color3.fromRGB(255, 0, 0)
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
    
    -- Health Bar Background
    drawings.HealthBg = CreateDrawing("Square")
    if drawings.HealthBg then
        drawings.HealthBg.Visible = false
        drawings.HealthBg.Filled = true
        drawings.HealthBg.Color = Color3.fromRGB(40, 40, 40)
    end
    
    -- Health Bar
    drawings.HealthBar = CreateDrawing("Square")
    if drawings.HealthBar then
        drawings.HealthBar.Visible = false
        drawings.HealthBar.Filled = true
        drawings.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    end
    
    -- Head Dot
    drawings.HeadDot = CreateDrawing("Circle")
    if drawings.HeadDot then
        drawings.HeadDot.Visible = false
        drawings.HeadDot.Filled = true
        drawings.HeadDot.NumSides = 30
        drawings.HeadDot.Color = Color3.fromRGB(255, 255, 0)
    end
    
    ESPData[player] = drawings
end

-- ESP silme
local function RemoveESP(player)
    if not ESPData[player] then return end
    
    for _, drawing in pairs(ESPData[player]) do
        if drawing then
            pcall(function()
                drawing:Remove()
            end)
        end
    end
    ESPData[player] = nil
end

-- Bounding Box hesaplama
local function GetBoundingBox(character)
    local head = character:FindFirstChild("Head")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    
    if not (head or hrp) or not humanoid then return nil end
    
    local cf, size = character:GetBoundingBox()
    local center = cf.Position
    local height = size.Y
    local width = height * 0.55
    
    local top = center + Vector3.new(0, height/2, 0)
    local bottom = center + Vector3.new(0, -height/2, 0)
    
    local topScreen, topOnScreen = WorldToScreen(top)
    local bottomScreen, bottomOnScreen = WorldToScreen(bottom)
    
    if not topOnScreen and not bottomOnScreen then return nil end
    
    return {
        Top = topScreen,
        Bottom = bottomScreen,
        Height = math.abs(topScreen.Y - bottomScreen.Y),
        Width = math.abs(topScreen.Y - bottomScreen.Y) * 0.55,
        Center = Vector2.new(
            (topScreen.X + bottomScreen.X) / 2,
            (topScreen.Y + bottomScreen.Y) / 2
        ),
        OnScreen = topOnScreen or bottomOnScreen
    }
end

-- Ana Render Fonksiyonu
local function RenderESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        -- Takım kontrolü
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
        
        -- Mesafe kontrolü
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
        
        -- ESP oluşturma
        if not ESPData[player] then
            CreateESP(player)
        end
        
        local drawings = ESPData[player]
        if not drawings then continue end
        
        local box = GetBoundingBox(character)
        if not box then continue end
        
        -- Görünürlük kontrolü
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
        
        -- Box ESP
        if ESP.BoxEnabled and drawings.Box then
            drawings.Box.Visible = true
            drawings.Box.Position = Vector2.new(box.Top.X - box.Width/2, box.Top.Y)
            drawings.Box.Size = Vector2.new(box.Width, box.Height)
            drawings.Box.Color = color
        end
        
        -- Tracer ESP
        if ESP.TracerEnabled and drawings.Tracer then
            drawings.Tracer.Visible = true
            drawings.Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
            drawings.Tracer.To = box.Bottom
            drawings.Tracer.Color = color
        end
        
        -- Name ESP
        if ESP.NameEnabled and drawings.Name then
            drawings.Name.Visible = true
            drawings.Name.Text = player.Name
            drawings.Name.Position = Vector2.new(box.Top.X, box.Top.Y - 15)
        end
        
        -- Distance ESP
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
            
            -- Renk: Yeşil -> Sarı -> Kırmızı
            local r = math.clamp(255 * (1 - healthPercent) * 2, 0, 255)
            local g = math.clamp(255 * healthPercent * 2, 0, 255)
            drawings.HealthBar.Color = Color3.fromRGB(r, g, 0)
        end
        
        -- Head Dot
        if ESP.HeadDotEnabled and drawings.HeadDot then
            local headPos, onScreen = WorldToScreen(head.Position)
            if onScreen then
                drawings.HeadDot.Visible = true
                drawings.HeadDot.Position = headPos
                drawings.HeadDot.Radius = 8
            end
        end
    end
end

-- Event bağlantıları
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        if ESPData[player] then RemoveESP(player) end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    RemoveESP(player)
end)

-- Render döngüsünü başlat
RunService.RenderStepped:Connect(RenderESP)
