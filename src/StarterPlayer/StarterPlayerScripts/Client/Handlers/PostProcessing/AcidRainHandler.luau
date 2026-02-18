----------------------------------------
-- ACID RAIN HANDLER MODULE SCRIPT 
-- @carsondev7
----------------------------------------

----------------------------
-- SERVICES --
----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

----------------------------
-- MODULES --
----------------------------

----------------------------
-- VARIABLES --
----------------------------
local AcidRainHandler = {}

local RAIN_DEFAULT_DIRECTION = Vector3.new(0,-1,0)			-- Default direction for rain to fall into
local RAIN_EMITTER_DIM_DEFAULT = 40							-- Size of emitter block to the side/up
local RAIN_EMITTER_DIM_MAXFORWARD = 100						-- Size of emitter block forwards when looking at the horizon
local RAIN_EMITTER_UP_MODIFIER = 20							-- Maximum vertical displacement of emitter (when looking fully up/down)
local OFF_TRANSPARENCY = NumberSequence.new(1)				-- Transparency for disabling rain
local ON_TRANSPARENCY = NumberSequence.new(.3)				-- Transparency for enabling rain
local ON_TRANSPARENCY_OCCLUDED = NumberSequence.new(.5)		-- Transparency for occluded rain
local OCCLUDED_RAIN_COUNT = 20								-- Number of occluded rain particles to generate
local RAIN_UPDATE_PERIOD = 6								-- Update the transparency of the main emitters + volume of rain inside every X frames
local RAIN_OCCLUSION_INTENSITY = 2							-- How many occluded straight rain particles are emitted for every splash for max intensity

local player = Players.LocalPlayer

local emitterPart = script:WaitForChild("EmitterPart")
local isActive = false
local currentCeiling = nil

local acidRainAttachments do
	acidRainAttachments = {}
	for i = 1, OCCLUDED_RAIN_COUNT do
		-- occluded rain particle generation
		local acidRainAttachment = Instance.new("Attachment")
		acidRainAttachment.Name = "__AcidRainOccludedAttachment"
		local occludedRain = emitterPart.AcidRainEmitter:Clone()
		occludedRain.Enabled = false
		occludedRain.Parent = acidRainAttachment
		table.insert(acidRainAttachments, acidRainAttachment)
	end
end

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude

local globalRainConn = nil
local occludedRainConn = nil

----------------------------
-- PUBLIC FUNCTIONS --
----------------------------
function AcidRainHandler:Start()
	isActive = true
	local rand = Random.new()
	
	emitterPart.Parent = workspace.CurrentCamera
	emitterPart.AcidRainEmitter.Transparency = OFF_TRANSPARENCY
	emitterPart.AcidRainEmitter.Enabled = true
	
	for i = 1, OCCLUDED_RAIN_COUNT do
		acidRainAttachments[i].Parent = workspace.Terrain
	end
	
	-- HANDLE GLOBAL RAIN
	globalRainConn = RunService.RenderStepped:Connect(function()
		if not isActive then
			globalRainConn:Disconnect()
			return
		end
		
		-- Get the camera position
		local camera = workspace.CurrentCamera
		local camPos = camera.CFrame.Position
		
		local t = math.abs(camera.CFrame.LookVector:Dot(RAIN_DEFAULT_DIRECTION))
		local right = camera.CFrame.LookVector:Cross(-RAIN_DEFAULT_DIRECTION)
		right = right.Magnitude > 0.001 and right.Unit or -RAIN_DEFAULT_DIRECTION
		local forward = RAIN_DEFAULT_DIRECTION:Cross(right).Unit

		-- Configure emitter part size/cframe
		emitterPart.Size = Vector3.new(
			RAIN_EMITTER_DIM_DEFAULT,
			RAIN_EMITTER_DIM_DEFAULT,
			RAIN_EMITTER_DIM_DEFAULT + (1 - t) * (RAIN_EMITTER_DIM_MAXFORWARD - RAIN_EMITTER_DIM_DEFAULT)
		)
		emitterPart.CFrame =
			CFrame.new(
				camPos.x, camPos.y, camPos.z,
				right.x, -RAIN_DEFAULT_DIRECTION.x, forward.x,
				right.y, -RAIN_DEFAULT_DIRECTION.y, forward.y,
				right.z, -RAIN_DEFAULT_DIRECTION.z, forward.z
			)
			+ (1 - t) * camera.CFrame.LookVector * emitterPart.Size.Z / 3
		- t * RAIN_DEFAULT_DIRECTION * RAIN_EMITTER_UP_MODIFIER
		
		-- Check if player is under ceiling
		currentCeiling = workspace:Raycast(camPos, Vector3.new(0, 100, 0), params)
		
		-- If player is OUTSIDE
		if currentCeiling == nil then
			emitterPart.AcidRainEmitter.Transparency = ON_TRANSPARENCY
		-- If player is UNDER ceiling
		else
			emitterPart.AcidRainEmitter.Transparency = OFF_TRANSPARENCY
		end
	end)
	
	
	-- HANDLE RAIN OCCLUSION
	occludedRainConn = RunService.RenderStepped:Connect(function()
		if not isActive then
			occludedRainConn:Disconnect()
			return
		end		
		
		if currentCeiling ~= nil then
			--print("Player is INSIDE")
			local ceilingPosY = currentCeiling.Position.Y			
			local camPos = workspace.CurrentCamera.CFrame.Position
			local right = workspace.CurrentCamera.CFrame.LookVector:Cross(-RAIN_DEFAULT_DIRECTION).Unit
			local forward = RAIN_DEFAULT_DIRECTION:Cross(right).Unit

			--print("Ceiling y position: " .. ceilingPosY .. ", Camera y position: " .. camPos.Y)
			
			for _, attachment in pairs(acidRainAttachments) do
				
				-- Generate random position within 100 studs of camera
				local x = rand:NextNumber(-100, 100)
				local z = rand:NextNumber(-100, 100)
				
				local rayOrigin = Vector3.new(camPos.X + x, camPos.Y + 120, camPos.Z + z)
				local rayDirection = Vector3.new(0, -300, 0)

				-- raycast downwards to check if any part is hit
				local occlusionPoint = workspace:Raycast(rayOrigin, rayDirection, params)
				if occlusionPoint then
					local hitPos = occlusionPoint.Position

					-- Hit something below ceiling (occlusion)
					if hitPos.Y < camPos.Y then
						--print("Occlusion detected at: " .. hitPos.Y, ", Cam pos: " .. camPos.Y .. ", Ceiling pos: " .. ceilingPosY)
						attachment.AcidRainEmitter.Transparency = ON_TRANSPARENCY_OCCLUDED
						attachment.CFrame = CFrame.new(
							camPos.X + x,
							occlusionPoint.Position.Y + 15,
							camPos.Z + z
						)
						attachment.AcidRainEmitter:Emit(RAIN_OCCLUSION_INTENSITY)
					-- Hit something above ceiling (no occlusion)
					else
						--print("No occlusion detected at: " .. hitPos.Y)
						attachment.AcidRainEmitter.Transparency = OFF_TRANSPARENCY
					end
				end
			end
		end
	end)
end


function AcidRainHandler:Stop()
	-- Disable state
	isActive = false
	
	-- Ensure connections are disconnected
	if occludedRainConn then occludedRainConn:Disconnect() end
	if globalRainConn then globalRainConn:Disconnect() end
	
	-- Global rain
	emitterPart.AcidRainEmitter.Transparency = OFF_TRANSPARENCY
	emitterPart.AcidRainEmitter.Enabled = false
	
	-- Occluded rain
	for _, attachment in pairs(acidRainAttachments) do
		attachment.AcidRainEmitter.Transparency = OFF_TRANSPARENCY
	end
end


----------------------------
-- MAIN --
----------------------------
--AcidRainHandler:Start()

return AcidRainHandler
