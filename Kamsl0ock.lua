local p = game:GetService("Players")
local r = game:GetService("RunService")
local u = game:GetService("UserInputService")
local s = game:GetService("StarterGui")
local l = p.LocalPlayer
local c = workspace.CurrentCamera

local pred = 0.21
local key = Enum.KeyCode.Q
local parts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperArm", "RightUpperArm"}
local i = 1
local aim = parts[i]
local hp = nil

pcall(function()
	s:SetCore("SendNotification", {
		Title = "Kamcams Script",
		Text = "Thank you for using Kamcams! Join our Discord 💬",
		Duration = 5
	})
end)

local g = Instance.new("ScreenGui", game.CoreGui)
g.Name = "ScriptlifeCamLock"
g.ResetOnSpawn = false

-- Container Frame to hold both button and input box
local container = Instance.new("Frame", g)
container.Size = UDim2.new(0, 180, 0, 100)
container.Position = UDim2.new(0.5, -90, 0.1, 0)
container.BackgroundTransparency = 0.6
container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
container.Active = true
container.Draggable = true

local b = Instance.new("TextButton", container)
b.Size = UDim2.new(0, 150, 0, 60)
b.Position = UDim2.new(0.5, -75, 0, 0)
b.AnchorPoint = Vector2.new(0.5, 0)
b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
b.TextColor3 = Color3.new(1, 1, 1)
b.Text = "Scriptlife 🔒"
b.TextSize = 22
b.Font = Enum.Font.SourceSansBold
b.AutoButtonColor = false

local inputBox = Instance.new("TextBox", container)
inputBox.Size = UDim2.new(0, 150, 0, 30)
inputBox.Position = UDim2.new(0.5, -75, 0, 65)
inputBox.AnchorPoint = Vector2.new(0.5, 0)
inputBox.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
inputBox.TextColor3 = Color3.new(1, 1, 1)
inputBox.Text = tostring(pred)
inputBox.PlaceholderText = "Enter prediction (0-1)"
inputBox.ClearTextOnFocus = false
inputBox.Font = Enum.Font.SourceSans
inputBox.TextSize = 18

local locking = false
local targ = nil
local hl = nil

local function closest()
	local cl, nilDist = nil, math.huge
	for _, pl in ipairs(p:GetPlayers()) do
		if pl ~= l and pl.Character then
			local rt = pl.Character:FindFirstChild("HumanoidRootPart")
			if rt then
				local pos, on = c:WorldToViewportPoint(rt.Position)
				if on then
					local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(c.ViewportSize.X / 2, c.ViewportSize.Y / 2)).Magnitude
					if dist < nilDist then
						cl = pl
						nilDist = dist
					end
				end
			end
		end
	end
	return cl
end

local function down()
	if not targ or not targ.Character then return true end
	local hum = targ.Character:FindFirstChildOfClass("Humanoid")
	if not hum or hum.Health <= 0 or hum.Health < 3 then return true end
	local rt = targ.Character:FindFirstChild("HumanoidRootPart") or targ.Character:FindFirstChild("LowerTorso")
	if rt and (rt:FindFirstChild("Velocity") and rt.Velocity.Magnitude < 2) then
		if targ.Character:FindFirstChild("Ragdoll") or targ.Character:FindFirstChild("KnockedOut") then return true end
	end
	return false
end

local function addHL(ch)
	if hl then hl:Destroy() end
	hl = Instance.new("Highlight", ch)
	hl.Name = "ScriptlifeHighlight"
	hl.FillColor = Color3.new(1, 0, 0)
	hl.FillTransparency = 0.5
	hl.OutlineTransparency = 1
end

local function remHL()
	if hl then hl:Destroy() hl = nil end
end

local function toggle()
	if locking then
		locking = false
		remHL()
		targ = nil
		b.Text = "Scriptlife 🔓"
		b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	else
		local newT = closest()
		if newT and newT.Character then
			locking = true
			targ = newT
			local hum = newT.Character:FindFirstChildOfClass("Humanoid")
			if hum then hp = hum.Health end
			addHL(newT.Character)
			b.Text = "Scriptlife 🔒"
			b.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
		end
	end
end

b.MouseButton1Click:Connect(toggle)
u.InputBegan:Connect(function(inp, gp)
	if not gp and inp.KeyCode == key then toggle() end
end)

inputBox.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		local val = tonumber(inputBox.Text)
		if val and val > 0 and val < 1 then
			pred = val
			inputBox.TextColor3 = Color3.fromRGB(0, 255, 0)
			print("Prediction updated to:", pred)
		else
			inputBox.TextColor3 = Color3.fromRGB(255, 0, 0)
			print("Invalid prediction input")
		end
	end
end)

r.RenderStepped:Connect(function()
	if locking and targ and targ.Character then
		local hum = targ.Character:FindFirstChildOfClass("Humanoid")
		if not hum then return end

		if down() then
			locking = false
			remHL()
			targ = nil
			b.Text = "Scriptlife 🔓"
			b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			return
		end

		local myHum = l.Character and l.Character:FindFirstChildOfClass("Humanoid")
		if myHum and myHum.Health < 4 then
			locking = false
			remHL()
			targ = nil
			b.Text = "Scriptlife 🔓"
			b.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
			return
		end

		if hum.Health < hp then
			i = (i % #parts) + 1
			aim = parts[i]
			hp = hum.Health
		end

		local ap = targ.Character:FindFirstChild(aim)
		local hd = targ.Character:FindFirstChild("Head")
		if ap and hd then
			local v = ap.Velocity
			local pos = (ap.Position + hd.Position) / 2
			local predPos = pos + v * pred
			local shake = Vector3.new(
				math.random(-2, 2) / 500,
				math.random(-2, 2) / 500,
				math.random(-2, 2) / 500
			)
			local camPos = c.CFrame.Position
			c.CFrame = CFrame.new(camPos, predPos + shake)
		end
	end
end)
