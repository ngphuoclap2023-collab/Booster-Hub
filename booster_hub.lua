--[[ ═══════════════════════════════════════════════════════════════
     ⚔️ KING LEGACY - ULTIMATE PERFORMANCE SUITE v2.0 (INFINITY)
     
     [TƯ DUY 0.01%]
     - FPS: Can thiệp sâu vào Render & Lighting, loại bỏ PostEffect.
     - RAM: Smart Kill (chỉ xóa effect rác, bảo vệ skill & char) + Smart GC.
     - Ping: Triệt tiêu Replication Lag, ổn định gói tin.
     - Resilience: Auto-Execute & Auto-Rejoin (chống văng, an toàn bot).
     - HUD: UI kéo thả, cập nhật Real-time.
═══════════════════════════════════════════════════════════════ ]]

-- ==========================================
-- [0] KHỞI TẠO & CLEANUP PHIÊN TRƯỚC
-- ==========================================
if _G.__KL_ULT_CLEAN then pcall(_G.__KL_ULT_CLEAN) end
_G.__KL_ULT_CLEAN = nil

local Services = {
    Players = game:GetService("Players"),
    Lighting = game:GetService("Lighting"),
    Workspace = game:GetService("Workspace"),
    StarterGui = game:GetService("StarterGui"),
    RunService = game:GetService("RunService"),
    Stats = game:GetService("Stats"),
    TeleportService = game:GetService("TeleportService"),
    GuiService = game:GetService("GuiService")
}

local player = Services.Players.LocalPlayer
local connections = {}
local isRunning = true

-- ⚠️ LINK GITHUB CỦA BẠN (Bắt buộc phải có để Auto-Execute hoạt động)
local SCRIPT_URL = "https://raw.githubusercontent.com/ngphuoclap2023-collab/Booster-hub/main/king_legacy.lua"

-- ==========================================
-- [1] MODULE: HUD (GIAO DIỆN KÉO THẢ)
-- ==========================================
local HUD = { gui = nil, label = nil }

function HUD:Init()
    pcall(function()
        if self.gui then self.gui:Destroy() end
        local pg = player:WaitForChild("PlayerGui", 5)
        if not pg then return end

        self.gui = Instance.new("ScreenGui")
        self.gui.Name = "KL_Ultimate_HUD"
        self.gui.ResetOnSpawn = false
        self.gui.IgnoreGuiInset = true
        self.gui.DisplayOrder = 999
        self.gui.Parent = pg

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 290, 0, 120)
        frame.Position = UDim2.new(0, 10, 0, 10)
        frame.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
        frame.BackgroundTransparency = 0.1
        frame.BorderSizePixel = 0
        frame.Active = true
        frame.Draggable = true -- Tính năng kéo thả
        frame.Parent = self.gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = frame

        local stroke = Instance.new("UIStroke")
        stroke.Color = Color3.fromRGB(255, 190, 0)
        stroke.Thickness = 1.5
        stroke.Transparency = 0.2
        stroke.Parent = frame

        self.label = Instance.new("TextLabel")
        self.label.Size = UDim2.new(1, -20, 1, -16)
        self.label.Position = UDim2.new(0, 10, 0, 8)
        self.label.BackgroundTransparency = 1
        self.label.TextColor3 = Color3.fromRGB(255, 190, 0)
        self.label.Font = Enum.Font.GothamBold
        self.label.TextSize = 13
        self.label.TextXAlignment = Enum.TextXAlignment.Left
        self.label.TextYAlignment = Enum.TextYAlignment.Top
        self.label.Text = "⚔️ ULTIMATE v2.0\nĐang khởi động..."
        self.label.Parent = frame
    end)
end

function HUD:Update(fps, ram, rejoinCount, maxRejoin)
    if self.label and self.label.Parent then
        self.label.Text = string.format(
            "⚔️ ULTIMATE v2.0 ● ON\n" ..
            "FPS: %d | RAM: %d MB\n" ..
            "Auto-Exec: ON | Rejoin: %d/%d\n" ..
            "Trạng thái: Đang tối ưu",
            fps, math.floor(ram), rejoinCount, maxRejoin
        )
    end
end

HUD:Init()

-- ==========================================
-- [2] MODULE: FPS & RENDER OPTIMIZER
-- ==========================================
local function OptimizeRender()
    -- Ép FPS cap lên mức tối đa
    pcall(function() setfpscap(240) end)
    
    -- Hạ cấu hình đồ họa
    pcall(function()
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level04 -- Giữ mức 4 để thấy skill
        settings().Rendering.ShadowMapSize = 0
        settings().Rendering.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level02
    end)

    -- Tối ưu Lighting: Tắt Shadow toàn cục, xóa hiệu ứng mờ (Blur/Bloom)
    pcall(function()
        Services.Lighting.GlobalShadows = false
        Services.Lighting.FogEnd = 5000 -- Giữ sương mù nhẹ cho King Legacy
        for _, fx in ipairs(Services.Lighting:GetChildren()) do
            if fx:IsA("BlurEffect") or fx:IsA("BloomEffect") or fx:IsA("SunRaysEffect") then
                fx:Destroy()
            end
        end
    end)
end

-- ==========================================
-- [3] MODULE: RAM KILLER (SMART KILL)
-- ==========================================
-- Bộ lọc: Các class gây nặng RAM/CPU nhưng KHÔNG ảnh hưởng skill
local HARMFUL_CLASSES = {
    ["Smoke"] = true, ["Fire"] = true, ["Sparkles"] = true,
    ["PointLight"] = true, ["SpotLight"] = true, ["SurfaceLight"] = true
}

local function IsProtected(inst)
    -- Bảo vệ nhân vật và tool (vũ khí/trái) để không mất hiệu ứng skill
    local char = player.Character
    if char and inst:IsDescendantOf(char) then return true end
    
    -- Bảo vệ các part thuộc về UI hoặc Camera
    if inst:IsDescendantOf(Services.Workspace.CurrentCamera) then return true end
    
    return false
end

local function SmartKill(inst)
    if HARMFUL_CLASSES[inst.ClassName] and not IsProtected(inst) then
        pcall(function() inst:Destroy() end)
    end
end

-- 1. Quét dọn lần đầu
for _, v in ipairs(Services.Workspace:GetDescendants()) do
    SmartKill(v)
end

-- 2. Bắt sự kiện các object mới sinh ra (Không dùng vòng lặp while -> Chống lag)
table.insert(connections, Services.Workspace.DescendantAdded:Connect(SmartKill))

-- 3. Smart Garbage Collector (Dọn rác bộ nhớ)
table.insert(connections, task.spawn(function()
    while isRunning do
        task.wait(30) -- 30 giây dọn 1 lần để tránh khựng game
        local success, mb = pcall(function() return Services.Stats:GetTotalMemoryUsageMb() end)
        -- Chỉ dọn rác nếu RAM vượt ngưỡng 1400MB
        if success and mb and mb > 1400 then
            pcall(function() collectgarbage("collect") end)
        end
    end
end))

-- ==========================================
-- [4] MODULE: PING STABILIZER
-- ==========================================
pcall(function()
    -- Đưa độ trễ mạng (lag) về 0, giúp gói tin gửi/nhận mượt mà, giảm ping ảo
    settings().Network.IncomingReplicationLag = 0
end)

-- ==========================================
-- [5] MODULE: RESILIENCE (AUTO-EXEC & AUTO-REJOIN)
-- ==========================================
local RejoinSystem = {
    count = 0,
    max = 3,
    isRejoining = false
}

local function TriggerAutoExecute()
    local code = 'loadstring(game:HttpGet("' .. SCRIPT_URL .. '"))()'
    pcall(function()
        if type(queue_on_teleport) == "function" then
            queue_on_teleport(code)
        elseif syn and syn.queue_on_teleport then
            syn.queue_on_teleport(code)
        end
    end)
end

local function TriggerAutoRejoin()
    if RejoinSystem.isRejoining or RejoinSystem.count >= RejoinSystem.max then return end
    RejoinSystem.isRejoining = true
    RejoinSystem.count = RejoinSystem.count + 1
    
    -- Đợi 20s để tránh bị Roblox quét Bot
    task.wait(20)
    
    pcall(function()
        Services.TeleportService:TeleportToPlaceInstance(
            game.PlaceId, game.JobId, player
        )
    end)
end

-- Kích hoạt Auto-Execute ngay khi vào game
TriggerAutoExecute()

-- Lắng nghe sự kiện Teleport (Tự động chạy lại script ở server mới)
table.insert(connections, player.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Started then
        TriggerAutoExecute()
    end
end))

-- Lắng nghe sự kiện bị Kick/Văng (Tự động vào lại)
pcall(function()
    table.insert(connections, Services.GuiService.ErrorMessageChanged:Connect(function()
        local msg = Services.GuiService:GetErrorMessage()
        if msg and msg ~= "" then
            TriggerAutoRejoin()
        end
    end))
end)

-- ==========================================
-- [6] MODULE: MAIN LOOP (HIỂN THỊ HUD)
-- ==========================================
local frameCount, fpsTime, currentFPS = 0, 0, 0

-- Đo FPS
table.insert(connections, Services.RunService.RenderStepped:Connect(function(dt)
    frameCount = frameCount + 1
    fpsTime = fpsTime + dt
    if fpsTime >= 1 then
        currentFPS = math.floor(frameCount / fpsTime)
        frameCount, fpsTime = 0, 0
    end
end))

-- Cập nhật HUD
table.insert(connections, task.spawn(function()
    while isRunning do
        task.wait(1)
        if not isRunning then break end
        
        local mb = 0
        pcall(function() mb = Services.Stats:GetTotalMemoryUsageMb() end)
        HUD:Update(currentFPS, mb, RejoinSystem.count, RejoinSystem.max)
    end
end))

-- ==========================================
-- [7] MODULE: CLEANUP FUNCTION
-- ==========================================
_G.__KL_ULT_CLEAN = function()
    isRunning = false
    for _, conn in ipairs(connections) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
    end
    table.clear(connections)
    if HUD.gui then pcall(function() HUD.gui:Destroy() end) end
end

-- Khởi chạy tối ưu
OptimizeRender()

pcall(function()
    Services.StarterGui:SetCore("SendNotification", {
        Title = "⚔️ ULTIMATE v2.0",
        Text = "Hệ thống tối ưu đỉnh cao đã kích hoạt!",
        Duration = 4
    })
end)
