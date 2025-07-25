local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local prediction = 0.21
local lockKey = Enum.KeyCode.Q
local bodyParts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm"}
local partIndex = 1
local aimPartName = bodyParts[partIndex]
local currentHealth = nil

-- Notification
pcall(function()
	StarterGui:SetCore("SendNotification", {
		Title = "Kamcams Script",
		Text = "Thank you for using Kamcams! Join our Discord 💬",
		Duration = 5,
	})
end)

-- GUI setup
local gui = Instance.new("ScreenGui", game.CoreGui)
gui.Name = "ScriptlifeCamLock"
gui.ResetOnSpawn = false

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 230, 0, 120)
frame.Position = UDim2.new(0.5, -115, 0.1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
frame.BorderSizePixel = 0
frame.Draggable = true
frame.Active = true

local toggleButton = Instance.new("TextButton", frame)
toggleButton.Size = UDim2.new(0, 200, 0, 40)
toggleButton.Position = UDim2.new(0.5, -100, 0, 5)
toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
toggleButton.TextColor3 = Color3.new(1, 1, 1)
toggleButton.Text = "Scriptlife 🔒"
toggleButton.TextSize = 22
toggleButton.Font = Enum.Font.SourceSansBold
toggleButton.Draggable = false

local predBox = Instance.new("TextBox", frame)
predBox.Size = UDim2.new(0, 200, 0, 35)
predBox.Position = UDim2.new(0.5, -100, 0, 55)
predBox.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
predBox.PlaceholderText = "Prediction (e.g. 0.21)"
predBox.TextColor3 = Color3.new(1, 1, 1)
predBox.Font = Enum.Font.SourceSans
predBox.TextSize = 20
predBox.Text = tostring(prediction)

-- State
local isLocking = false
local target = nil
local highlight = nil

-- Functions
local function getClosestPlayer()
	local closestPlayer, shortestDistance = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local root = player.Character:FindFirstChild("HumanoidRootPart")
			if root then
				local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)).Magnitude
					if dist < shortestDistance then
						closestPlayer = player
						shortestDistance = dist
					end
				end
			end
		end
	end
	return closestPlayer
end

local function isTargetDown()
	if not target or not target.Character then return true end
	local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.Health < 3 then return true end
	local root = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("LowerTorso")
	if root and (root:FindFirstChild("Velocity") and root.Velocity.Magnitude < 2) then
		if target.Character:FindFirstChild("Ragdoll") or target.Character:FindFirstChild("KnockedOut") then
			return true
		end
	end
	return false
end

local function addHighlight(char)
	if highlight then highlight:Destroy() end
	highlight = Instance.new("Highlight", char)
	highlight.Name = "ScriptlifeHighlight"
	highlight.FillColor = Color3.new(1, 0, 0)
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 1
end

local function removeHighlight()
	if highlight then
		highlight:Destroy()
		highlight = nil
	end
end

local function toggleLock()
	if isLocking then
		isLocking = false
		removeHighlight()
		target = nil
		toggleButton.Text = "Scriptlife 🔓"
		toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	else
		local newTarget = getClosestPlayer()
		if newTarget and newTarget.Character then
			isLocking = true
			target = newTarget
			local humanoid = newTarget.Character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				currentHealth = humanoid.Health
			end
			addHighlight(newTarget.Character)
			toggleButton.Text = "Scriptlife 🔒"
			toggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		end
	end
end

-- Events
toggleButton.MouseButton1Click:Connect(toggleLock)
UIS.InputBegan:Connect(function(input, gp)
	if not gp and input.KeyCode == lockKey then
		toggleLock()
	end
end)

predBox.FocusLost:Connect(function()
	local num = tonumber(predBox.Text)
	if num then
		prediction = num
	end
end)

RunService.RenderStepped:Connect(function()
	if isLocking and target and target.Character then
		local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		if isTargetDown() then
			isLocking = false
			removeHighlight()
			target = nil
			toggleButton.Text = "Scriptlife 🔓"
			toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			return
		end

		local myHumanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
		if myHumanoid and myHumanoid.Health < 4 then
			isLocking = false
			removeHighlight()
			target = nil
			toggleButton.Text = "Scriptlife 🔓"
			toggleButton.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			return
		end

		if humanoid.Health < currentHealth then
			partIndex = (partIndex % #bodyParts) + 1
			aimPartName = bodyParts[partIndex]
			currentHealth = humanoid.Health
		end

		local aimPart = target.Character:FindFirstChild(aimPartName)
		local head = target.Character:FindFirstChild("Head")
		if aimPart and head then
			local velocity = aimPart.Velocity
			local centerPos = (aimPart.Position + head.Position) / 2
			local predictedPos = centerPos + velocity * prediction
			local shake = Vector3.new(
				math.random(-2, 2) / 500,
				math.random(-2, 2) / 500,
				math.random(-2, 2) / 500
			)
			local camPos = Camera.CFrame.Position
			Camera.CFrame = CFrame.new(camPos, predictedPos + shake)
		end
	end
end)
