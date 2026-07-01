-- // Delta Mobil – Anti-Ban ESP (Highlight) & Gizli Aimbot
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Şifreli ayarlar (basit obfuscation)
local _A = {
    ESP = true,
    ESP_Mode = "Highlight", -- "Highlight" veya "Box"
    Aimbot = false,
    AimbotKey = "Touch",    -- Dokunma ile aktif
    AimbotSmoothness = 2.5, -- Yüksek = daha insansı (1-5)
    AimbotMaxDist = 400,
    AimbotFOV = 25,
    TeamCheck = false,
    ESP_BoxColor = Color3.fromRGB(255, 0, 0),
    ESP_MaxDist = 1000
}

-- Highlight nesnelerini sakla
local Highlights = {}

-- ////////////////////////////////////////////////
-- // ESP (Highlight veya Box)
-- ////////////////////////////////////////////////
local function updateESP()
    local myChar = LocalPlayer.Character
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if _A.TeamCheck and LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then
            -- Takım arkadaşını temizle
            if Highlights[plr] then Highlights[plr]:Destroy() Highlights[plr] = nil end
            continue
        end

        local char = plr.Character
        if not char then
            if Highlights[plr] then Highlights[plr]:Destroy() Highlights[plr] = nil end
            continue
        end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            if Highlights[plr] then Highlights[plr]:Destroy() Highlights[plr] = nil end
            continue
        end

        if not _A.ESP then
            if Highlights[plr] then Highlights[plr]:Destroy() Highlights[plr] = nil end
            continue
        end

        local dist = myChar and myChar:FindFirstChild("HumanoidRootPart") and (myChar.HumanoidRootPart.Position - hrp.Position).Magnitude or 0
        if dist > _A.ESP_MaxDist then
            if Highlights[plr] then Highlights[plr]:Destroy() Highlights[plr] = nil end
            continue
        end

        -- ESP Modu
        if _A.ESP_Mode == "Highlight" then
            if not Highlights[plr] then
                local hl = Instance.new("Highlight")
                hl.Name = "ESP_Highlight"
                hl.Adornee = char
                hl.FillColor = Color3.fromRGB(255, 0, 0)
                hl.FillTransparency = 0.5
                hl.OutlineColor = Color3.new(1, 0, 0)
                hl.OutlineTransparency = 0
                hl.Parent = char
                Highlights[plr] = hl
            end
            -- Mesafeye göre renk değişimi (isteğe bağlı)
            local hl = Highlights[plr]
            if hl then
                hl.FillColor = dist < 150 and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
            end
        else
            -- Drawing kullanarak Box ESP (dikkatli ol)
            -- (Bu kısmı önceki gibi ekleyebilirsin ama Highlight daha güvenli)
        end
    end
end

-- ////////////////////////////////////////////////
-- // AIMBOT (İnsansı, sadece dokununca)
-- ////////////////////////////////////////////////
local isTouching = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isTouching = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        isTouching = false
    end
end)

local function getBestTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local closest = nil
    local minDist = math.huge
    local myChar = LocalPlayer.Character
    if not myChar or not myChar:FindFirstChild("HumanoidRootPart") then return nil end
    local myPos = myChar.HumanoidRootPart.Position

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        if _A.TeamCheck and LocalPlayer.Team and plr.Team and LocalPlayer.Team == plr.Team then continue end
        local char = plr.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not (head or hrp) or not hum or hum.Health <= 0 then continue end
        local targetPart = head or hrp
        local worldDist = (myPos - targetPart.Position).Magnitude
        if worldDist > _A.AimbotMaxDist then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if onScreen then
            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            -- FOV kontrolü
            local angle = math.acos(math.clamp(Camera.CFrame.LookVector:Dot((targetPart.Position - Camera.CFrame.Position).Unit), -1, 1))
            if angle <= math.rad(_A.AimbotFOV) then
                if screenDist < minDist then
                    minDist = screenDist
                    closest = plr
                end
            end
        end
    end
    return closest
end

local function humanizedAim(targetPlayer)
    local char = targetPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local targetPart = head or hrp
    if not targetPart then return end

    local targetPos = targetPart.Position + Vector3.new(math.random(-0.1,0.1), math.random(-0.1,0.1), math.random(-0.1,0.1)) -- ufak rastgele sapma
    local camLookAt = CFrame.lookAt(Camera.CFrame.Position, targetPos)
    -- Yumuşak geçiş (insansı)
    local smooth = _A.AimbotSmoothness
    local alpha = math.clamp(1 / smooth, 0.05, 1) -- minimum 0.05 adım
    Camera.CFrame = Camera.CFrame:Lerp(camLookAt, alpha)
end

local aimTick = 0
local function updateAimbot()
    if not _A.Aimbot then return end
    if not isTouching then return end

    -- Her kare yerine her 2 karede bir çalış (yük azaltma)
    aimTick = aimTick + 1
    if aimTick % 2 ~= 0 then return end

    local target = getBestTarget()
    if target then
        humanizedAim(target)
    end
end

-- ////////////////////////////////////////////////
-- // MOBİL MENÜ (Basit, göze batmaz)
-- ////////////////////////////////////////////////
local function createMenu()
    local gui = Instance.new("ScreenGui")
    gui.Name = "SecureMenu"
    gui.Parent = game.CoreGui or game.Players.LocalPlayer:WaitForChild("PlayerGui")
    gui.ResetOnSpawn = false
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 40, 0, 40)
    btn.Position = UDim2.new(1, -50, 0, 10)
    btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    btn.Text = "⚙"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 20
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 20)

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 200)
    frame.Position = UDim2.new(1, -210, 0, 60)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = gui

    local t = Instance.new("TextLabel", frame)
    t.Size = UDim2.new(1, 0, 0, 25)
    t.BackgroundColor3 = Color3.fromRGB(40,40,40)
    t.Text = "Güvenli Mod"
    t.TextColor3 = Color3.new(1,1,1)
    t.Font = Enum.Font.SourceSansBold

    local y = 30
    local function addToggle(name, default, callback)
        local b = Instance.new("TextButton", frame)
        b.Size = UDim2.new(1, -10, 0, 28)
        b.Position = UDim2.new(0, 5, 0, y)
        b.BackgroundColor3 = default and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
        b.Text = name .. ": " .. (default and "AÇIK" or "KAPALI")
        b.TextColor3 = Color3.new(1,1,1)
        b.Font = Enum.Font.SourceSans
        b.TextSize = 13
        local toggled = default
        b.MouseButton1Click:Connect(function()
            toggled = not toggled
            b.Text = name .. ": " .. (toggled and "AÇIK" or "KAPALI")
            b.BackgroundColor3 = toggled and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
            callback(toggled)
        end)
        y = y + 30
    end

    addToggle("ESP", _A.ESP, function(v) _A.ESP = v end)
    addToggle("Aimbot", _A.Aimbot, function(v) _A.Aimbot = v end)
    addToggle("Takım Kontrol", _A.TeamCheck, function(v) _A.TeamCheck = v end)

    btn.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible end)
end

-- ////////////////////////////////////////////////
-- // TEMİZLİK
-- ////////////////////////////////////////////////
Players.PlayerRemoving:Connect(function(p)
    if Highlights[p] then Highlights[p]:Destroy() Highlights[p] = nil end
end)

-- Ana döngü
RunService.RenderStepped:Connect(function()
    updateESP()
    updateAimbot()
end)

createMenu()
print("🛡️ Anti-Ban sistemi aktif. Highlight + İnsansı Aimbot.")
