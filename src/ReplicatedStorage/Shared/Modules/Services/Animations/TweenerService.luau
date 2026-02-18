----------------------------------------
-- TWEENER SERVICE MODULE SCRIPT 
-- @carsondev7
----------------------------------------

----------------------------
-- SERVICES --
----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

----------------------------
-- MODULES --
----------------------------

----------------------------
-- VARIABLES --
----------------------------
local originalVolumes = {}
local originalPositions = {}

local TweenerService = {}

-- ENUMS --
local SoundType = require(ReplicatedStorage.Shared.Modules.Enums.SoundType)

-- UTILS --
local freezeHighlight = ReplicatedStorage:WaitForChild("GUI"):WaitForChild("FreezeHighlight")

local tweenDirections = {
	UP = UDim2.new(0, 0, -1, 0),
	DOWN = UDim2.new(0, 0, 1, 0),
	LEFT = UDim2.new(-1, 0, 0, 0),
	RIGHT = UDim2.new(1, 0, 0, 0)
}

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

-- Hover scale: enlarge button slightly on MouseEnter, restore on MouseLeave (smooth tween)
local HOVER_SCALE = 1.08
local HOVER_TWEEN_DURATION = 0.12
local HOVER_TWEEN_STYLE = Enum.EasingStyle.Quad

function TweenerService:ApplyButtonHoverEffect(button, options)
	if not button or not button:IsA("GuiObject") then return end
	local scaleAmount = (options and options.Scale) or HOVER_SCALE
	local duration = (options and options.Duration) or HOVER_TWEEN_DURATION
	local uiscale = button:FindFirstChildOfClass("UIScale")
	if not uiscale then
		uiscale = Instance.new("UIScale")
		uiscale.Scale = 1
		uiscale.Parent = button
	end
	local tweenInfo = TweenInfo.new(duration, HOVER_TWEEN_STYLE, Enum.EasingDirection.Out)
	local connectionEnter
	local connectionLeave
	local function tweenTo(goalScale)
		local tween = TweenService:Create(uiscale, tweenInfo, { Scale = goalScale })
		tween:Play()
	end
	connectionEnter = button.MouseEnter:Connect(function()
		tweenTo(scaleAmount)
	end)
	connectionLeave = button.MouseLeave:Connect(function()
		tweenTo(1)
	end)
	-- Return disconnect so caller can clean up if needed
	return function()
		if connectionEnter then connectionEnter:Disconnect() end
		if connectionLeave then connectionLeave:Disconnect() end
	end
end

-- Shrinks a gui object to 0 scale
function TweenerService:ShrinkGui(guiObject, duration)
	if not guiObject then return end

	for _, frame in guiObject:GetChildren() do
		if not frame:IsA("Frame") then continue end
		
		local scale = frame:FindFirstChildOfClass("UIScale")
		if not scale then continue end

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local tween = TweenService:Create(scale, tweenInfo, { Scale = 0 })
		tween:Play()
	end

	task.spawn(function()
		task.wait(duration)
		guiObject.Enabled = false
	end)
end

-- Shrinks a gui object to 1 scale
function TweenerService:ExpandGui(guiObject, duration)
	if not guiObject then return end
	
	guiObject.Enabled = true
	
	for _, frame in guiObject:GetChildren() do
		if not frame:IsA("Frame") then continue end

		local scale = frame:FindFirstChildOfClass("UIScale")
		if not scale then continue end
		
		scale.Scale = 0

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local tween = TweenService:Create(scale, tweenInfo, { Scale = 1 })
		tween:Play()
	end
end


-- Tween a gui object outwards off the screen
function TweenerService:SlideGuiOut(guiObject, direction, duration)
	if not guiObject then return end
	
	for _, frame in guiObject:GetChildren() do
		if not frame:IsA("Frame") then continue end
		local originalPosition = originalPositions[frame] or frame.Position
		originalPositions[frame] = originalPosition
		
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
		
		local directionEffect = tweenDirections[direction] or UDim2.new(0, 0, 1, 0)
		
		local goal = {Position = originalPosition + directionEffect}

		local tween = TweenService:Create(frame, tweenInfo, goal)
		tween:Play()
	end
	
	task.spawn(function()
		task.wait(duration)
		guiObject.Enabled = false
	end)
end

-- Tween a gui object inwards onto the screen
function TweenerService:SlideGuiIn(guiObject, direction, duration)
	if not guiObject then return end

	for _, frame in guiObject:GetChildren() do
		if not frame:IsA("Frame") then continue end
		local originalPosition = originalPositions[frame] or frame.Position
		originalPositions[frame] = originalPosition

		frame.Position = originalPosition + (tweenDirections[direction] or UDim2.new(0, 0, 1, 0))
		
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

		local goal = {Position = originalPosition}

		local tween = TweenService:Create(frame, tweenInfo, goal)
		tween:Play()
	end
	
	guiObject.Enabled = true
end

-- Fade a text UI object in and then out
function TweenerService:Fade(guiObject: GuiObject, duration: number, delayTime: number)
	-- Fade in
	self:FadeIn(guiObject, duration)

	-- Delay, then fade out and destroy
	task.delay(duration + (delayTime or 0), function()
		self:FadeOut(guiObject, duration)
		task.delay(duration, function()
			guiObject:Destroy()
		end)
	end)
end

-- Fade in a frame/text UI object
function TweenerService:FadeIn(guiObject: GuiObject, duration: number)
	if guiObject:IsA("TextLabel") then
		local uiStroke = guiObject:FindFirstChild("UIStroke")
		if uiStroke then
			local originalStrokeTransparency = uiStroke.Transparency
			uiStroke.Transparency = 1
			local strokeTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local strokeTween = TweenService:Create(uiStroke, strokeTweenInfo, {Transparency = originalStrokeTransparency})
			strokeTween:Play()
		end
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(guiObject, tweenInfo, {TextTransparency = 0})
		tween:Play()
	else
		for _, descendant in guiObject:GetDescendants() do
			if descendant:IsA("TextLabel") then
				local uiStroke = descendant:FindFirstChild("UIStroke")
				if uiStroke then
					local originalStrokeTransparency = uiStroke.Transparency
					uiStroke.Transparency = 1
					local strokeTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local strokeTween = TweenService:Create(uiStroke, strokeTweenInfo, {Transparency = originalStrokeTransparency})
					strokeTween:Play()
				end
				descendant.TextTransparency = 1
				local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
				local tween = TweenService:Create(descendant, tweenInfo, {TextTransparency = 0})
				tween:Play()
			end
		end
	end
	
	guiObject.Visible = true
end

-- Fade out a frame/text UI object
function TweenerService:FadeOut(guiObject: GuiObject, duration: number)
	if guiObject:IsA("TextLabel") then
		local uiStroke = guiObject:FindFirstChild("UIStroke")
		if uiStroke then
			local strokeTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
			local strokeTween = TweenService:Create(uiStroke, strokeTweenInfo, {Transparency = 1})
			strokeTween:Play()
		end
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
		local tween = TweenService:Create(guiObject, tweenInfo, {TextTransparency = 1})
		tween:Play()
	else
		for _, descendant in guiObject:GetDescendants() do
			if descendant:IsA("TextLabel") then
				local uiStroke = descendant:FindFirstChild("UIStroke")
				if uiStroke then
					local strokeTweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
					local strokeTween = TweenService:Create(uiStroke, strokeTweenInfo, {Transparency = 1})
					strokeTween:Play()
				end
				local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
				local tween = TweenService:Create(descendant, tweenInfo, {TextTransparency = 1})
				tween:Play()
			end
		end
	end
end

function TweenerService:FadeTextColor(guiObject: GuiObject, newColor: Color3, duration: number, delayTime: number)
	if guiObject:IsA("TextLabel") then
		local originalColor = guiObject.TextColor3
		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local tween = TweenService:Create(guiObject, tweenInfo, {TextColor3 = newColor})
		tween:Play()
		
		task.delay(duration + (delayTime or 0), function()
			local tweenBack = TweenService:Create(guiObject, tweenInfo, {TextColor3 = originalColor})
			tweenBack:Play()
		end)
	end
end


--------------------------------------------------------------------------------
-- AUDIO
--------------------------------------------------------------------------------

function TweenerService:FadeSoundIn(sound: Sound)
	local originalVolume = originalVolumes[sound] or sound.Volume
	originalVolumes[sound] = originalVolume
	sound.Volume = 0
	sound:Play()
	
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	
	local goal = {Volume = originalVolume}
	
	local tween = TweenService:Create(sound, tweenInfo, goal)
	tween:Play()
end

function TweenerService:FadeSoundOut(sound: Sound)
	local originalVolume = originalVolumes[sound] or sound.Volume
	
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)

	local goal = {Volume = 0}

	local tween = TweenService:Create(sound, tweenInfo, goal)
	tween:Play()
	
	task.spawn(function()
		task.wait(0.5)
		sound:Stop()
		sound.Volume = originalVolume
	end)
end


--------------------------------------------------------------------------------
-- PLAYER
--------------------------------------------------------------------------------

-- Fade in the freeze effect
function TweenerService:FadeFreezeEffect(players, duration)
	for _, player in ipairs(players) do
		local char = player.Character
		if not char then continue end

		-- Remove old highlight if exists
		local existingHighlight = char:FindFirstChild("FreezeHighlight")
		if existingHighlight then
			existingHighlight:Destroy()
		end

		-- Create new highlight
		local newHighlight = freezeHighlight:Clone()
		newHighlight.Parent = char

		-- Tween from invisible to visible
		local tween = TweenService:Create(
			newHighlight, 
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
			{FillTransparency = 0.5}
		)
		tween:Play()
	end
end

-- Fade out the freeze effect
function TweenerService:FadeUnfreezeEffect(players, duration)
	for _, player in ipairs(players) do
		local char = player.Character
		if not char then continue end

		local highlight = char:FindFirstChild("FreezeHighlight")
		if not highlight then continue end

		-- Tween to invisible then destroy
		local tween = TweenService:Create(
			highlight, 
			TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In), 
			{FillTransparency = 1}
		)
		tween:Play()

		-- Destroy after tween completes
		tween.Completed:Connect(function()
			if highlight and highlight.Parent then
				highlight:Destroy()
			end
		end)
	end
end

-- Reset all tween effects on players
function TweenerService:ResetPlayerTweenEffects()
	-- Fade out all freeze effects
	self:FadeUnfreezeEffect(Players:GetPlayers(), 0.5)
end


----------------------------
-- MAIN --
----------------------------

return TweenerService
