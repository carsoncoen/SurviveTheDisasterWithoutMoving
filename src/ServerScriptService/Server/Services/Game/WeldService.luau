----------------------------------------
-- WELD SERVICE
-- @carsondev7
----------------------------------------

local WeldingService = {}

-- Weld all structures in map
function WeldingService:WeldMapStructures(map)
	if not map then return end
	
	for _, structure in ipairs(map.InteractiveParts:GetDescendants()) do
		if structure:IsA("Model") then
			self:WeldStructure(structure)
		end
	end
end

function WeldingService:WeldStructure(structure)
	local parts = {}

	-- Collect all BaseParts in the structure
	for _, descendant in ipairs(structure:GetDescendants()) do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
		end
	end

	-- Weld each part to nearby parts using overlap detection
	for i, part in ipairs(parts) do
		for j = i + 1, #parts do
			local otherPart = parts[j]

			if WeldingService:ArePartsTouching(part, otherPart) then
				-- Create weld between these two parts
				local weld = Instance.new("WeldConstraint")
				weld.Part0 = part
				weld.Part1 = otherPart
				weld.Parent = part
			end
		end
	end
	
	
	-- Weld each part to everything it's touching
	for _, part in ipairs(parts) do
		local touching = part:GetTouchingParts()

		for _, touchingPart in ipairs(touching) do
			-- Only weld if the touching part is also in this structure
			if table.find(parts, touchingPart) then
				-- Check if already welded (avoid duplicates)
				local alreadyWelded = false
				for _, child in ipairs(part:GetChildren()) do
					if child:IsA("WeldConstraint") then
						if child.Part0 == touchingPart or child.Part1 == touchingPart then
							alreadyWelded = true
							break
						end
					end
				end

				-- Create the weld
				if not alreadyWelded then
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = part
					weld.Part1 = touchingPart
					weld.Parent = part
				end
			end
		end
	end
end

-- Check if two parts are touching using region overlap
function WeldingService:ArePartsTouching(part1, part2)
	local tolerance = 0.5 -- Small gap tolerance

	-- Get the bounds of both parts
	local pos1, size1 = part1.Position, part1.Size
	local pos2, size2 = part2.Position, part2.Size

	-- Check if bounding boxes overlap on all axes
	local overlapX = math.abs(pos1.X - pos2.X) < (size1.X + size2.X) / 2 + tolerance
	local overlapY = math.abs(pos1.Y - pos2.Y) < (size1.Y + size2.Y) / 2 + tolerance
	local overlapZ = math.abs(pos1.Z - pos2.Z) < (size1.Z + size2.Z) / 2 + tolerance

	return overlapX and overlapY and overlapZ
end

return WeldingService