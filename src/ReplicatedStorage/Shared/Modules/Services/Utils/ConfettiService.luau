----------------------------------------
-- CONFETTI SERVICE MODULE SCRIPT 
-- @carsondev7
----------------------------------------
-- SERVICES --
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- VARIABLES --
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local confettiGui = playerGui:WaitForChild("ConfettiGUI")
local sizes = confettiGui:WaitForChild("Sizes"):GetChildren()
local container = confettiGui:WaitForChild("Container")

local CONFETTI_AMOUNT = 75
local RNG = Random.new()

local Colors = {
	Color3.fromRGB(255, 0, 0),
	Color3.fromRGB(255, 217, 24),
	Color3.fromRGB(127, 255, 0),
	Color3.fromRGB(0, 170, 255),
	Color3.fromRGB(183, 0, 255),
	Color3.fromRGB(255, 115, 249),	
}

local function getTweenInfo(duration)
	return TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)
end

local ConfettiService = {}

local function confettiVisual()
	for i = 1, CONFETTI_AMOUNT do
		local randomConfetti = sizes[RNG:NextInteger(1, #sizes)]
		local newConfetti = randomConfetti:Clone()
		newConfetti.BackgroundColor3 = Colors[RNG:NextInteger(1, #Colors)]

		local xPos = RNG:NextNumber(-0.3, 1.3)
		newConfetti.Position = UDim2.new(xPos, 0, -0.2, 0)
		newConfetti.Rotation = RNG:NextNumber(10, 350)
		newConfetti.Visible = true
		newConfetti.Parent = container

		local duration = RNG:NextNumber(1, 2.5)
		local confettiFallInfo = getTweenInfo(duration)
		local confettiTween = TweenService:Create(
			newConfetti, 
			confettiFallInfo, 
			{Position = UDim2.new(xPos, 0, 1.1, 0)}
		)
		confettiTween:Play()

		task.delay(duration + 2.8, function()
			if newConfetti and newConfetti.Parent then
				newConfetti:Destroy()
			end
		end)
	end

	task.delay(5.3, function()
		for _, frame in ipairs(container:GetChildren()) do
			if frame:IsA("Frame") then
				frame:Destroy()
			end
		end
	end)
end

function ConfettiService:Play()

	task.spawn(function()
		for i = 1, 5 do
			confettiVisual()
			task.wait(0.35)
		end
	end)
end

return ConfettiService