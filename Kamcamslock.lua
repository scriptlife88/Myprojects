local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- GUI Setup
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "KamCamLockUI"
screenGui.ResetOnSpawn = false

-- Message
local msg = Instance.new("TextLabel")
msg.Size = UDim2.new(0, 280, 0, 40)
msg.Position = UDim2.new(0.5, -140, 0.03, 0)
msg.BackgroundTransparency = 1
msg.TextColor3 = Color3.fromRGB(255, 255, 255)
msg.TextStrokeTransparency = 0.4
msg.TextScaled = true
msg.Font = Enum.Font.SourceSansBold
msg.Text = "Thanks for using Kamcams script"
msg.Parent = screenGui

-- Fade out after 5 seconds
task.delay(5, function()
	for i = 1, 20 do
		msg.TextTransparency = i / 20
		msg.TextStrokeTransparency = 0.4 + (i / 20)
		task.wait(0.05)
	end
	msg.Visible = false
end)

-- Lock Button
local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(0, 140, 0, 60) -- bigger button
lockBtn.Position = UDim2.new(0.5, -70, 0.12, 0)
lockBtn.AnchorPoint = Vector2.new(0.5, 0)
lockBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBtn.Text = "Scriptlife"
lockBtn.TextSize = 28
lockBtn.Font = Enum.Font.SourceSansBold
lockBtn.Draggable = true
lockBtn.Active = true
lockBtn.Parent = screenGui

-- Variables
local camlockOn = false
local currentTarget = nil
local lockSmoothness = 0.15      -- slightly smoother but less buttery
local predictionAmount = 0.25    -- stronger prediction for high ping

-- Highlight locked player
local function highlightTarget(target)
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(255, 0, 0)
	highlight.FillTransparency = 0.3
	highlight.OutlineTransparency = 1
	highlight.Name = "KamTargetHighlight"
	highlight.Parent = target.Character
end

local function removeHighlight()
	if currentTarget and currentTarget.Character then
		local old = currentTarget.Character:FindFirstChild("KamTargetHighlight")
		if old then old:Destroy() end
	end
end

-- Get closest player to center of screen
local function getClosestPlayerToCursor()
	local closest = nil
	local shortestDistance = math.huge
	local mouseLocation = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

	for _, player in pairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character then
			local head = player.Character:FindFirstChild("Head")
			local torso = player.Character:FindFirstChild("UpperTorso") or player.Character:FindFirstChild("Torso") or player.Character:FindFirstChild("HumanoidRootPart")
			if head and torso then
				local avgPos = (head.Position + torso.Position) / 2
				local screenPos, onScreen = Camera:WorldToViewportPoint(avgPos)
				if onScreen then
					local distance = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
					if distance < shortestDistance then
						shortestDistance = distance
						closest = player
					end
				end
			end
		end
	end

	return closest
end

-- Unlock function
local function unlock()
	removeHighlight()
	camlockOn = false
	currentTarget = nil
	lockBtn.Text = "Scriptlife"
	lockBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
end

-- RenderStepped loop with midpoint prediction
RunService.RenderStepped:Connect(function()
	if camlockOn and currentTarget and currentTarget.Character then
		local char = currentTarget.Character
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local head = char:FindFirstChild("Head")
		local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso") or char:FindFirstChild("HumanoidRootPart")

		if head and torso and humanoid and humanoid.Health > 0 then
			local state = humanoid:GetState()
			local isDowned = state == Enum.HumanoidStateType.Physics
				or state == Enum.HumanoidStateType.GettingUp
				or (humanoid.WalkSpeed < 1 and humanoid.Health < 15)

			if not isDowned then
				local avgPos = (head.Position + torso.Position) / 2
				local avgVel = (head.Velocity + torso.Velocity) / 2
				local predictedPosition = avgPos + (avgVel * predictionAmount)

				local newCFrame = CFrame.new(Camera.CFrame.Position, predictedPosition)
				Camera.CFrame = Camera.CFrame:Lerp(newCFrame, lockSmoothness)
				return
			end
		end
	end

	unlock()
end)

-- Toggle lock function
local function toggleLock()
	if camlockOn then
		unlock()
	else
		currentTarget = getClosestPlayerToCursor()
		if currentTarget then
			removeHighlight()
			highlightTarget(currentTarget)
			camlockOn = true
			lockBtn.Text = "UNLOCK"
			lockBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		end
	end
end

-- Button click connection
lockBtn.MouseButton1Click:Connect(toggleLock)

-- Keyboard Q keybind toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.Keyboard then
		if input.KeyCode == Enum.KeyCode.Q then
			toggleLock()
		end
	end
end)

-- Unlock if player leaves
Players.PlayerRemoving:Connect(function(player)
	if currentTarget == player then
		unlock()
	end
end)
