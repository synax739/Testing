-- // Delta Mobil – Rivals TEMEL SÜRÜM (Panel + ESP)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Ayarlar
local cfg = {
    esp_on = true,
    esp_box = true,
    esp_name = false,
    esp_dist = false,
    esp_maxDist = 1000,
    esp_visibleColor = Color3.fromRGB(0, 255, 0),
    esp_hiddenColor = Color3.fromRGB(255, 0, 0)
}

-- ESP Verisi
local ESPData = {}

-- Güvenli Drawing oluşturma
local function newDrawing(t)
    local ok, d = pcall(function() return Drawing.new(t) end)
    return ok and d or nil
end

-- Oyuncu için ESP oluştur
local function createESP(plr)
    local d = {}
    d.box = newDrawing("Square")
    if d.box then
        d.box.Thickness = 2
        d.box.Filled = false
        d.box.Visible = false
    end
    ESPData[plr] = d
end

-- Oyuncu ESP'sini sil
local function removeESP(plr)
    local d = ESPData[plr]
    if not d then return end
    if d.box then pcall(function() d.box:Remove() end) end
    ESPData[plr] = nil
end

-- Kameranın önünde mi?
local function isInFront(pos)
    local camPos = Camera.CFrame.Position
    return Camera.CFrame.LookVector:Dot((pos - camPos).Unit) > 0
end

-- Görüş kontrolü (basit raycast)
local function isTargetVisible(character)
    if not character then return false end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local myChar = LocalPlayer.Character
    if not myChar then return false end

    local origin = Camera.CFrame.Position
    local targetPos = hrp.Position + Vector3.new(0, 1.5, 0)
    local ray = Ray.new(origin, (targetPos - origin).Unit * 500)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {myChar, character})
    return hit == nil
end

-- Karakterin ekran kutusunu hesapla
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
        size = Vector2.new(w, h)
    }
end

-- Ana ESP döngüsü
local function updateESP()
    local my = LocalPlayer.Character
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
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

        -- ESP kapalıysa çizimleri gizle
        if not cfg.esp_on then
            if ESPData[plr] and ESPData[plr].box then
                ESPData[plr].box.Visible = false
            end
            continue
        end

        if not isInFront(hrp.Position) then
            if ESPData[plr] and ESPData[plr].box then
                ESPData[plr].box.Visible = false
            end
            continue
        end

        local dist = 0
        if my and my:FindFirstChild("HumanoidRootPart") then
            dist = (my.HumanoidRootPart.Position - hrp.Position).Magnitude
        end
        if dist > cfg.esp_maxDist then
            if ESPData[plr] and ESPData[plr].box then
                ESPData[plr].box.Visible = false
            end
            continue
        end

        if not ESPData[plr] then createESP(plr) end
        local d = ESPData[plr]
        if not d or not d.box then continue end

        local box = getBox(char)
        if not box then
            d.box.Visible = false
            continue
        end

        -- Görünürlük rengi
        local visible = isTargetVisible(char)
        local color = visible and cfg.esp_visibleColor or cfg.esp_hiddenColor

        d.box.Visible = true
        d.box.Position = box.pos
        d.box.Size = box.size
        d.box.Color = color
    end
end

-- ==============================================
-- BASİT PANEL (Sadece ESP aç/kapat)
-- ==============================================
local function createPanel()
    local gui = Instance.new("ScreenGui")
    gui.Name = "TestPanel"
    gui.Parent = game.CoreGui or LocalPlayer:WaitForChild("PlayerGui")
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

    local panel = Instance.new("Frame")
    panel.Size = UDim2.new(0, 200, 0, 100)
    panel.Position = UDim2.new(1, -210, 0, 60)
    panel.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    panel.BorderSizePixel = 0
    panel.Visible = false
    panel.Parent = gui

    -- ESP Toggle butonu
    local espBtn = Instance.new("TextButton")
    espBtn.Size = UDim2.new(1, -10, 0, 30)
    espBtn.Position = UDim2.new(0, 5, 0, 10)
    espBtn.BackgroundColor3 = cfg.esp_on and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    espBtn.Text = "ESP: " .. (cfg.esp_on and "AÇIK" or "KAPALI")
    espBtn.TextColor3 = Color3.new(1,1,1)
    espBtn.Font = Enum.Font.SourceSans
    espBtn.TextSize = 14
    espBtn.Parent = panel

    espBtn.MouseButton1Click:Connect(function()
        cfg.esp_on = not cfg.esp_on
        espBtn.Text = "ESP: " .. (cfg.esp_on and "AÇIK" or "KAPALI")
        espBtn.BackgroundColor3 = cfg.esp_on and Color3.fromRGB(0, 150, 0) or Color3.fromRGB(150, 0, 0)
    end)

    openBtn.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
    end)
end

-- ==============================================
-- BAŞLATMA
-- ==============================================
Players.PlayerRemoving:Connect(function(p) removeESP(p) end)

createPanel()

RunService.RenderStepped:Connect(updateESP)

print("✅ Temel panel ve ESP çalışıyor. Sağ üstteki ⚙ butonuna bas.")
