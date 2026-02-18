----------------------------------------
-- RAYCAST SERVICE
-- @carsondev7
----------------------------------------

-- SERVICES --
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

-- MODULES --

-- ENUMS --

-- REMOTES --

-- VARIABLES --
local RaycastService = {}

-- FUNCTIONS --

function RaycastService:HasLineOfSight(fromChar, toChar)
	local fromHRP = fromChar:FindFirstChild("HumanoidRootPart")
	local toHRP = toChar:FindFirstChild("HumanoidRootPart")
	if not fromHRP or not toHRP then return false end

	RaycastParams.FilterDescendantsInstances = { fromChar }

	local direction = toHRP.Position - fromHRP.Position
	local result = workspace:Raycast(fromHRP.Position, direction, RaycastParams)

	if not result then
		return true
	end

	return result.Instance:IsDescendantOf(toChar)
end

function RaycastService:GetSamplePoints(part)
	if not part then return end

	local cf = part.CFrame
	local size = part.Size

	return {
		cf.Position, -- center

		-- corners
		cf * Vector3.new( size.X/2, 0,  size.Z/2),
		cf * Vector3.new(-size.X/2, 0,  size.Z/2),
		cf * Vector3.new( size.X/2, 0, -size.Z/2),
		cf * Vector3.new(-size.X/2, 0, -size.Z/2),
	}
end

function RaycastService:GetExternalParts(currentMap, params)
	if not currentMap then return end

	local externalParts = {}
	for _, part in currentMap.InteractiveParts:GetDescendants() do
		if part:IsA("BasePart") then
			-- Check if part is external
			local isExternal = self:IsPartExternal(part, params)
			if isExternal then
				table.insert(externalParts, part)
				CollectionService:AddTag(part, "External")
			end
		end
	end
	return externalParts
end


function RaycastService:IsPartExternal(part, params)
	if not part then return end
	
	-- Check if part is already tagged as external
	if CollectionService:HasTag(part, "External") then
		return true
	end
	
	-- Check if part is external
	local samplePoints = self:GetSamplePoints(part)
	if not samplePoints then return false end
	
	for _, point in samplePoints do
		-- raycast up to see if part is outdoors
		local result = workspace:Raycast(point, Vector3.new(0, 100, 0), params)
		if result == nil then
			return true
		end
	end
end


return RaycastService
