----------------------------------------
-- STRUCTURE SERVICE
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
local StructureService = {}

-- FUNCTIONS --


function StructureService:Collapse(part, applyImpulse)
	-- Check if part is a support part
	local isSupportPart = StructureService:CheckForSupportPart(part)
	if isSupportPart then
		-- If no remaining support parts, collapse structure
		if not StructureService:CheckForRemainingSupports(part) then
			StructureService:CollapseStructure(part, applyImpulse)
		end
	else
		StructureService:CollapsePart(part, applyImpulse)
	end
end

-- Check if structure has a support part
function StructureService:CheckForSupportPart(part)
	if part then
		if CollectionService:HasTag(part, "Support") then
			CollectionService:RemoveTag(part, "Support")
			return true
		end
	end
	return false
end

-- Check if any remaining support parts exist in structure
function StructureService:CheckForRemainingSupports(part)
	if part and part.Parent then
		for _, child in ipairs(part.Parent:GetChildren()) do
			if CollectionService:HasTag(child, "Support") then
				return true
			end
		end
	end
	return false
end

-- Collapse entire structure
function StructureService:CollapseStructure(part, applyImpulse)
	if part and part.Parent then
		for _, child in ipairs(part.Parent:GetDescendants()) do	
			if child:IsA("BasePart") then
				-- Unanchor all parts
				child.Anchored = false

				if applyImpulse then
					self:ApplyImpulse(part)
				end
			end
		end
	end
end

-- Collapse singular part
function StructureService:CollapsePart(part, applyImpulse)
	if part and part:IsA("BasePart") then
		-- Unanchor part
		part.Anchored = false

		if applyImpulse then
			self:ApplyImpulse(part)
		end
	end
end

function StructureService:ApplyImpulse(part)
	if part and part:IsA("BasePart") then
		-- Add small force to part
		part.AssemblyLinearVelocity = Vector3.new(math.random(-10, 10), math.random(10, 20), math.random(-10, 10))
		part.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
	end
end


return StructureService
