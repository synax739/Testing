local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Ayarlar
local esp_on = true
local esp_box = true
local esp_maxDist = 1000
local visibleColor = Color3.fromRGB(0, 255, 0)
local hiddenColor = Color3.fromRGB(255, 0, 0)

-- ESP çizimleri
local ESP = {}

local function newDrawing(t)
    local ok, d = pcall(function() return Drawing.new(t) end)
    return ok and d or nil
end

local function createESP(plr)
    local d = {}
    d.box = newDrawing("Square")
    if d.box then
        d.box.Thickness = 2
        d.box.Filled = false
        d.box.Visible = false
    end
    ESP[plr] = d
end

local function removeESP(plr)
    local d = ESP[plr]
    if d and d.box then
        pcall(function() d.box:Remove() end)
    end
    ESP[plr] = nil
end

local function isInFront(pos)
    return Camera.CFrame.LookVector:Dot((pos - Camera.CFrame.Position).Unit) > 0
end

local function isVisible(char)
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local my = LocalPlayer.Character
    if not my then return false end
    local origin = Camera.CFrame.Position
    local target = hrp.Position + Vector3.new(0, 1.5, 0)
    local ray = Ray.new(origin, (target - origin).Unit * 500)
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {my, char})
    return hit == nil
end

local function getBox(char)
    local head = char:FindFirstChild("Head")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
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

local function updateESP()
    local my = LocalPlayer.Character
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char then removeESP(plr) continue end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then removeESP(plr) continue end

        if not esp_on then
            if ESP[plr] and ESP[plr].box then ESP[plr].box.Visible = false end
            continue
        end

        if not isInFront(hrp.Position) then
            if ESP[plr] and ESP[plr].box then ESP[plr].box.Visible = false end
            continue
        end

        local dist = my and my:FindFirstChild("HumanoidRootPart") and (my.HumanoidRootPart.Position - hrp.Position).Magnitude or 0
        if dist > esp_maxDist then
            if ESP[plr] and ESP[plr].box then ESP[plr].box.Visible = false end
            continue
        end

        if not ESP[plr] then createESP(plr) end
        local d = ESP[plr]
        if not d or not d.box then continue end

        local box = getBox(char)
        if not box then d.box.Visible = false continue end

        d.box.Visible = true
        d.box.Position = box.pos
        d.box.Size = box.size
        d.box.Color = isVisible(char) and visibleColor or hiddenColor
    end
end

-- PANEL
local function createPanel()
    local gui = Instance.new("ScreenGui", game.CoreGui)
    gui.Name = "MainGUI"

    local open = Instance.new("TextButton", gui)
    open.Size = UDim2.new(0,40,0,40)
    open.Position = UDim2.new(1,-50,0,10)
    open.BackgroundColor3 = Color3.fromRGB(60,60,60)
    open.Text = "⚙"
    open.TextColor3 = Color3.new(1,1,1)
    open.Font = Enum.Font.SourceSansBold
    open.TextSize = 20

    local panel = Instance.new("Frame", gui)
    panel.Size = UDim2.new(0,180,0,80)
    panel.Position = UDim2.new(1,-190,0,55)
    panel.BackgroundColor3 = Color3.fromRGB(25,25,25)
    panel.Visible = false

    local btn = Instance.new("TextButton", panel)
    btn.Size = UDim2.new(1,-10,0,30)
    btn.Position = UDim2.new(0,5,0,10)
    btn.BackgroundColor3 = esp_on and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
    btn.Text = "ESP: " .. (esp_on and "ACIK" or "KAPALI")
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.SourceSans
    btn.TextSize = 14
    btn.MouseButton1Click:Connect(function()
        esp_on = not esp_on
        btn.Text = "ESP: " .. (esp_on and "ACIK" or "KAPALI")
        btn.BackgroundColor3 = esp_on and Color3.fromRGB(0,150,0) or Color3.fromRGB(150,0,0)
    end)

    open.MouseButton1Click:Connect(function()
        panel.Visible = not panel.Visible
    end)
end

Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
createPanel()
RunService.RenderStepped:Connect(updateESP)

print("✅ Panel + ESP calisiyor.")
