-- CLASS
local WindService = {}
WindService.__index = WindService

-- SERVICES
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- VARIABLES
local Player = Players.LocalPlayer
local RNG = Random.new()

-- FUNCTIONS
function WindService.new(setting)
	local Object = {}
	setmetatable(Object, WindService)
	
	Object.Location = setting.Location or game.Workspace.Camera
	Object.Randomized = setting.Randomized or false
	Object.Velocity = setting.Velocity or Vector3.new(0.45, 0, 0)
	Object.Amount = setting.Amount or 10
	Object.Current = 0
	Object.Frequency = setting.Frequency or 0.5
	Object.Lifetime = setting.Lifetime or 2
	Object.Amplitude = setting.Amplitude or 0.35
	Object.Range = setting.Range or 50
	Object.Part = script:WaitForChild("Wind")
	Object.Time = setting.Time or nil
	Object.Direction = (setting.Direction or Vector3.new(1, 0, 0)).Unit
	Object.Speed = setting.Speed or 15
	
	Object.ActiveConnections = {}
	Object.Running = true


	
	return Object
end

-- METHODS
function WindService:Start()
	if self.Time then
		local Timer = tick()
		self.While = RunService.Heartbeat:Connect(function()
			if (tick() - Timer) >= self.Time then
				Timer += self.Time
				if self.Current < self.Amount then
					self:CreateWind()
				end
			end
		end)
	else
		self.While = RunService.Heartbeat:Connect(function()
			if not self.Running then return end
			if self.Current < self.Amount then
				self:CreateWind()
			end
		end)

	end
end

function WindService:Stop()
	self.Running = false

	-- stop spawner
	if self.While and self.While.Connected then
		self.While:Disconnect()
	end

	-- stop all motion
	for _, conn in ipairs(self.ActiveConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	self.ActiveConnections = {}

	self.Current = 0
end


function WindService:GetRandomPosition()
	if not Player.Character.PrimaryPart then
		return
	end
	return Vector3.new(
		Player.Character.PrimaryPart.Position.X + RNG:NextInteger(-self.Range, self.Range), 
		Player.Character.PrimaryPart.Position.Y + RNG:NextInteger(1, self.Range), -- Replace to: "1, self.Range / 1.5" or see more wind nearby.
		Player.Character.PrimaryPart.Position.Z + RNG:NextInteger(-self.Range, self.Range)
	)
end

function WindService:CalculateSineWave(amp, x, freq, phase)
	return amp * math.sin((x / freq) + phase)
end

function WindService:FadeWind(part)
	for i = 0, 1, 0.01 do wait(0.01)
		part.Trail.Transparency = NumberSequence.new{
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.3, i),
			NumberSequenceKeypoint.new(0.6, i),
			NumberSequenceKeypoint.new(1, 1),
		}
	end
	wait(0.1)
end

function WindService:CreateWind()
	
	local Part = self.Part:Clone()
	Part.Parent = self.Location
	Part.Position = self:GetRandomPosition()
	self.Current += 1
		
	-- CHECK RANDOM STATE:
	if self.Randomized then
		-- GET RANDOM VALUES:
		local Towards = Vector3.new(RNG:NextNumber(-self.Velocity.X, self.Velocity.X), RNG:NextNumber(-self.Velocity.Y, self.Velocity.Y), RNG:NextNumber(-self.Velocity.Z, -self.Velocity.Z))
		local Latency = RNG:NextNumber(self.Lifetime, self.Lifetime + RNG:NextNumber(0.5, 1.5))
		
		-- MOVEMENT:
		local Render = RunService.RenderStepped:Connect(function()
			local Formula = WindService:CalculateSineWave(self.Amplitude, tick(), self.Frequency, 0)
			Part.CFrame = Part.CFrame * CFrame.new(0, 0, Formula) + Towards
		end)
		
		table.insert(self.ActiveConnections, Render)
		
		-- CLEANUP:
		delay(Latency, function()
			WindService:FadeWind(Part)
			Render:Disconnect()
			Part:Destroy()
			self.Current -= 1
		end)
	else
		-- MOVEMENT:
		local Render
		Render = RunService.RenderStepped:Connect(function(dt)
			-- forward wind movement
			local forwardMove = self.Direction * self.Speed * dt

			-- sine wobble (sideways)
			local sineOffset = math.sin(tick() * self.Frequency) * self.Amplitude
			local right = self.Direction:Cross(Vector3.yAxis).Unit
			local sway = right * sineOffset

			-- apply movement
			Part.Position += forwardMove + sway
		end)
		
		table.insert(self.ActiveConnections, Render)

		
		-- START ENDING:
		delay(self.Lifetime, function()
			WindService:FadeWind(Part)
			Render:Disconnect()
			Part:Destroy()
			self.Current -= 1
		end)
	end
end




return WindService