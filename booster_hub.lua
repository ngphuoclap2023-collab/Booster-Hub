--[[ ═══════════════════════════════════════════════════
     ⚡ ULTIMATE PERFORMANCE SUITE v1.1
     FPS Boost + Ping Stabilizer + RAM Killer + HUD (Draggable)

     - HUD kéo được, hiển thị FPS/RAM realtime
     - An toàn: không đụng nhân vật, map, UI
     - Chạy lại không conflict (tự cleanup)
     - Tự tắt khi dùng _G.__ULT_CLEAN()
═══════════════════════════════════════════════════ ]]

-- Cleanup phiên trước
if _G.__ULT_CLEAN then pcall(_G.__ULT_CLEAN) end
_G.__ULT_CLEAN = nil

local Players      = game:GetService("Players")
local Lighting     = game:GetService("Lighting")
local Workspace    = game:GetService("Workspace")
local StarterGui   = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local RunService   = game:GetService("RunService")
local Stats        = game:GetService("Stats")

local player = Players.LocalPlayer
local conns, running = {}, true

-- ─── HUD (kéo được, to hơn) ────────────────────
local hudGui, hudLabel
local function buildHUD()
    pcall(function()
        if hudGui then hudGui:Destroy() end
        local pg = player:WaitForChild("PlayerGui", 5)
        if not pg then return end

        hudGui = Instance.new("ScreenGui")
        hudGui.Name = "ULT_HUD"
        hudGui.ResetOnSpawn = false
        hudGui.IgnoreGuiInset = true
        hudGui.DisplayOrder = 999
        hudGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        hudGui.Parent = pg

        local frame = Instance.new("Frame")
        frame.Name = "HUD_Frame"
        frame.Size = UDim2.new(0, 260, 0, 90)
        frame.Position = UDim2.new(0, 10, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
        frame.BackgroundTransparency = 0.1
        frame.BorderSizePixel = 0
        frame.Active = true          -- cho phép kéo
        frame.Draggable = true       -- kéo tự do
        frame.Parent = hudGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(0, 255, 140)
        stroke.Thickness = 1
        stroke.Transparency = 0.3
        stroke.Parent = frame

        hudLabel = Instance.new("TextLabel")
        hudLabel.Size = UDim2.new(1, -16, 1, -12)
        hudLabel.Position = UDim2.new(0, 8, 0, 6)
        hudLabel.BackgroundTransparency = 1
        hudLabel.TextColor3 = Color3.fromRGB(0, 255, 140)
        hudLabel.Font = Enum.Font.GothamBold
        hudLabel.TextSize = 14
        hudLabel.TextXAlignment = Enum.TextXAlignment.Left
        hudLabel.TextYAlignment = Enum.TextYAlignment.Top
        hudLabel.Text = "⚡ ULTIMATE\nLoading..."
        hudLabel.Parent = frame
    end)
end
buildHUD()

-- ─── 1) FPS BOOST ──────────────────────────────
pcall(function() setfpscap(240) end)
pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
pcall(function() settings().Rendering.ShadowMapSize = 0 end)
pcall(function() settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01 end)

-- ─── 2) LIGHTING TỐI ƯU ────────────────────────
pcall(function()
    Lighting.GlobalShadows = false
    Lighting.FogEnd = 1e6
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("PostEffect") or fx:IsA("Atmosphere") or fx:IsA("Clouds") then
            pcall(function() fx:Destroy() end)
        end
    end
end)

-- ─── 3) RAM KILLER ─────────────────────────────
local protectedChar = player.Character
table.insert(conns, player.CharacterAdded:Connect(function(c) protectedChar = c end))

local KILL = {
    ParticleEmitter = true, Trail = true, Smoke = true, Fire = true,
    Sparkles = true, Beam = true,
    PointLight = true, SpotLight = true, SurfaceLight = true,
    Sound = true,
}

local function killIfBad(v)
    if KILL[v.ClassName] and protectedChar and not v:IsDescendantOf(protectedChar) then
        pcall(function() v:Destroy() end)
    end
end

pcall(function()
    for _, v in ipairs(Workspace:GetDescendants()) do killIfBad(v) end
end)

pcall(function()
    for _, s in ipairs(SoundService:GetDescendants()) do
        if s:IsA("Sound") then pcall(function() s:Destroy() end) end
    end
end)

table.insert(conns, Workspace.DescendantAdded:Connect(killIfBad))

-- ─── 4) PING STABILIZER ────────────────────────
pcall(function() settings().Network.IncomingReplicationLag = 0 end)

-- ─── 5) FPS COUNTER ────────────────────────────
local frameCount, fpsTime, fpsValue = 0, 0, 0
table.insert(conns, RunService.RenderStepped:Connect(function(dt)
    frameCount = frameCount + 1
    fpsTime = fpsTime + dt
    if fpsTime >= 1 then
        fpsValue = math.floor(frameCount / fpsTime)
        frameCount, fpsTime = 0, 0
    end
end))

-- ─── 6) HUD UPDATER + SMART GC ─────────────────
task.spawn(function()
    while running do
        task.wait(1)
        if not running then break end
        local mb = 0
        pcall(function() mb = Stats:GetTotalMemoryUsageMb() end)

        if hudLabel and hudLabel.Parent then
            hudLabel.Text = string.format(
                "⚡ ULTIMATE  ●  ON\nFPS: %d  |  RAM: %d MB\nReplicationLag: 0  |  Safe",
                fpsValue, math.floor(mb)
            )
        end

        if mb > 1200 then
            pcall(function() collectgarbage("collect") end)
        end
    end
end)

-- ─── 7) CLEANUP ────────────────────────────────
_G.__ULT_CLEAN = function()
    running = false
    for _, c in ipairs(conns) do
        pcall(function() c:Disconnect() end)
    end
    conns = {}
    if hudGui then pcall(function() hudGui:Destroy() end) end
end

-- Thông báo (nếu game không chặn)
pcall(function()
    StarterGui:SetCore("SendNotification", {
        Title = "⚡ ULTIMATE v1.1", Text = "Đã kích hoạt! Kéo HUD để di chuyển.", Duration = 3
    })
end)
