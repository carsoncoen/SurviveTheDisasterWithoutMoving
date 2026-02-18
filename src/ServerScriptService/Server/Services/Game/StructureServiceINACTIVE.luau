----------------------------------------
-- STRUCTURE SERVICE
-- @carsondev7
----------------------------------------
-- SERVICES --
local CollectionService = game:GetService("CollectionService")

-- VARIABLES --
local StructureService = {}

-- FUNCTIONS --

-- Add to StructureService

-- Collapse multiple parts efficiently
function StructureService:BatchCollapse(parts, applyImpulse)
	if not parts or #parts == 0 then return end

	-- Group parts by structure
	local structureGroups = {}
	for _, part in ipairs(parts) do
		if part and part:IsA("BasePart") and part.Anchored then
			local structure = part.Parent
			if structure then
				if not structureGroups[structure] then
					structureGroups[structure] = {}
				end
				table.insert(structureGroups[structure], part)
			end
		end
	end

	-- Process each structure once
	for structure, structureParts in pairs(structureGroups) do
		-- Collapse all parts in this structure
		for _, part in ipairs(structureParts) do
			StructureService:CollapsePart(part, applyImpulse)
		end

		-- Check structural integrity once per structure instead of per part
		StructureService:CheckStructuralIntegrity(structure, applyImpulse)
	end
end

-- Main entry point for collapsing a single part
function StructureService:Collapse(part, applyImpulse)
	if not part or not part:IsA("BasePart") then return end

	local structure = part.Parent
	if not structure then return end

	-- Collapse this specific part and break its welds
	StructureService:CollapsePart(part, applyImpulse)

	-- Check if any other parts lost their connection to anchored parts
	StructureService:CheckStructuralIntegrity(structure, applyImpulse)
end

-- Check which parts still have connection to anchored parts
function StructureService:CheckStructuralIntegrity(structure, applyImpulse)
	if not structure then return end
	-- Get all non support parts (non-anchored)
	local nonSupportParts = {}

	-- Simple approach: just get all descendants once
	for _, child in ipairs(structure:GetDescendants()) do
		if child:IsA("BasePart") and not CollectionService:HasTag(child, "Support") then
			table.insert(nonSupportParts, child)
		end
	end

	-- Collapse any parts not connected to an anchored part
	for _, part in ipairs(nonSupportParts) do
		if not StructureService:IsConnectedToSupportPart(part) then
			StructureService:CollapsePart(part, applyImpulse)
		end
	end
end

-- Check if a part is connected to any anchored part via welds
function StructureService:IsConnectedToSupportPart(part)
	if not part or not part:IsA("BasePart") then return false end

	-- Get all parts connected via welds/constraints
	local connectedParts = part:GetConnectedParts(true) -- recursive = true

	-- Check if any connected part is anchored
	for _, connectedPart in ipairs(connectedParts) do
		if CollectionService:HasTag(connectedPart, "Support") then
			return true
		end
	end

	return false
end

-- Collapse singular part and break all its connections
function StructureService:CollapsePart(part, applyImpulse)
	if not part or not part:IsA("BasePart") then return end

	-- Break all welds connected to this part or return early if part already collapsed
	local hasConnections = StructureService:BreakConnections(part)
	if not hasConnections then return end

	-- Unanchor the part
	part.Anchored = false

	-- Apply physics impulse if requested
	if applyImpulse then
		StructureService:ApplyImpulse(part)
	end
end

-- Break all weld constraints connected to a part
function StructureService:BreakConnections(part)
	
	local connectionsFound = 0 
	
	-- Destroy all constraints parented to this part
	for _, child in ipairs(part:GetChildren()) do
		if child:IsA("WeldConstraint") or child:IsA("Weld") or child:IsA("Motor6D") then
			connectionsFound += 1
			child:Destroy()
		end
	end

	-- Also destroy any joints connected to this part (covers welds parented elsewhere)
	for _, joint in ipairs(part:GetJoints()) do
		connectionsFound += 1
		joint:Destroy()
	end
	
	return connectionsFound > 0
end

-- Apply physics impulse to a part
function StructureService:ApplyImpulse(part)
	if not part or not part:IsA("BasePart") or part.Anchored then return end

	part.AssemblyLinearVelocity = Vector3.new(
		math.random(-10, 10), 
		math.random(10, 20), 
		math.random(-10, 10)
	)
	part.AssemblyAngularVelocity = Vector3.new(
		math.random(-10, 10), 
		math.random(-10, 10), 
		math.random(-10, 10)
	)
end

return StructureService