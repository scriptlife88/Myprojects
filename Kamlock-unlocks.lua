-- FULL SCRIPT: Scriptlife Camlock (Updated with health check <7%)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- Settings
local prediction = 0.24
local aimPart = "UpperTorso"
local lockKey = Enum.KeyCode.Q

-- GUI Setup
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ScriptlifeCamlock"

local button = Instance.new("TextButton", gui)
button.Size = UDim2.new(0, 160, 0, 60)
button.Position = UDim2.new(0.5, -80, 0.1, 0)
button.AnchorPoint = Vector2.new(0.5, 0)
button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextSize = 22
button.Text = "Scriptlife 🔒"
button.Font = Enum.Font.SourceSansBold
button.Draggable = true
button.Active = true

-- Lock Variables
local isLocking = false
local target = nil
local highlight = nil

-- Highlight Management
local function removeHighlight()
    if highlight then
        highlight:Destroy()
        highlight = nil
    end
end

local function addHighlight(char)
    removeHighlight()
    highlight = Instance.new("Highlight", char)
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 1
end

-- Closest Target to Cursor
local function getClosestPlayer()
    local closest, dist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(aimPart) then
            local part = p.Character[aimPart]
            local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                local mag = (Vector2.new(screenPos.X, screenPos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
                if mag < dist then
                    closest = p
                    dist = mag
                end
            end
        end
    end
    return closest
end

-- Validity Check
local function isInvalidTarget()
    if not target or not target.Character then return true end
    local hum = target.Character:FindFirstChildWhichIsA("Humanoid")
    if not hum or hum.Health <= 0 or hum.Health / hum.MaxHealth < 0.07 then return true end

    local root = target.Character:FindFirstChild("HumanoidRootPart")
    if not root then return true end

    if target.Character:FindFirstChild("Ragdoll") or target.Character:FindFirstChild("KnockedOut") or target.Character:FindFirstChild("KO") then
        return true
    end

    return false
end

-- Toggle Lock
local function toggleLock()
    if isLocking then
        isLocking = false
        removeHighlight()
        target = nil
        button.Text = "Scriptlife 🔓"
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    else
        target = getClosestPlayer()
        if target and target.Character then
            isLocking = true
            addHighlight(target.Character)
            button.Text = "Scriptlife 🔒"
            button.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
        end
    end
end

-- Bind Button + Key
button.MouseButton1Click:Connect(toggleLock)
UIS.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == lockKey then
        toggleLock()
    end
end)

-- Aim Tracking
RunService.RenderStepped:Connect(function()
    if isLocking and target and target.Character and target.Character:FindFirstChild(aimPart) then
        if isInvalidTarget() then
            isLocking = false
            removeHighlight()
            target = nil
            button.Text = "Scriptlife 🔓"
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            return
        end

        local torso = target.Character:FindFirstChild(aimPart)
        local head = target.Character:FindFirstChild("Head")
        if torso and head then
            local averagePos = (torso.Position + head.Position) / 2
            local predicted = averagePos + torso.Velocity * prediction

            -- Slight human-like shake
            local shake = Vector3.new(
                math.random(-1, 1) / 450,
                math.random(-1, 1) / 450,
                math.random(-1, 1) / 450
            )

            Camera.CFrame = CFrame.new(Camera.CFrame.Position, predicted + shake)
        end
    end
end)
