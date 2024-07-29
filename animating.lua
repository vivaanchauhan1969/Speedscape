function   waitForChild(parent, childName)
	local child = parent:findFirstChild(childName)
	if child then return child end
	while true do
		child = parent.ChildAdded:wait()
		if child.Name==childName then return child end
	end
end

local Figure = script.Parent
local Torso = waitForChild(Figure, "Torso")
local RightShoulder = waitForChild(Torso, "Right Shoulder")
local LeftShoulder = waitForChild(Torso, "Left Shoulder")
local RightHip = waitForChild(Torso, "Right Hip")
local LeftHip = waitForChild(Torso, "Left Hip")
local Neck = waitForChild(Torso, "Neck")
local Humanoid = waitForChild(Figure, "Humanoid")
local pose = "Standing"

local currentAnim = ""
local currentAnimTrack = nil
local currentAnimKeyframeHandler = nil
local currentAnimSpeed = 1.0
local animTable = {}
local animNames = {
	idle = 	{
				{ id = "http://www.roblox.com/asset/?id=125750544", weight = 9 },
				{ id = "http://www.roblox.com/asset/?id=125750618", weight = 1 }
			},
	walk = 	{
				{ id = "http://www.roblox.com/asset/?id=125749145", weight = 10 }
			},
	run = 	{
				{ id = "run.xml", weight = 10 }
			},
	jump = 	{
				{ id = "http://www.roblox.com/asset/?id=125750702", weight = 10 }
			},
	fall = 	{
				{ id = "http://www.roblox.com/asset/?id=125750759", weight = 10 }
			},
	climb = {
				{ id = "http://www.roblox.com/asset/?id=125750800", weight = 10 }
			},
	toolnone = {
				{ id = "http://www.roblox.com/asset/?id=125750867", weight = 10 }
			},
	toolslash = {
				{ id = "http://www.roblox.com/asset/?id=129967390", weight = 10 }
--				{ id = "slash.xml", weight = 10 }
			},
	toollunge = {
				{ id = "http://www.roblox.com/asset/?id=129967478", weight = 10 }
			},
	wave = {
				{ id = "http://www.roblox.com/asset/?id=128777973", weight = 10 }
			},
	point = {
				{ id = "http://www.roblox.com/asset/?id=128853357", weight = 10 }
			},
	dance = {
				{ id = "http://www.roblox.com/asset/?id=130018893", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=132546839", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=132546884", weight = 10 }
			},
	dance2 = {
				{ id = "http://www.roblox.com/asset/?id=160934142", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=160934298", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=160934376", weight = 10 }
			},
	dance3 = {
				{ id = "http://www.roblox.com/asset/?id=160934458", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=160934530", weight = 10 },
				{ id = "http://www.roblox.com/asset/?id=160934593", weight = 10 }
			},
	laugh = {
				{ id = "http://www.roblox.com/asset/?id=129423131", weight = 10 }
			},
	cheer = {
				{ id = "http://www.roblox.com/asset/?id=129423030", weight = 10 }
			},
}


local emoteNames = { wave = false, point = false, dance = true, dance2 = true, dance3 = true, laugh = false, cheer = false}

math.randomseed(tick())

function configureAnimationSet(name, fileList)
	if (animTable[name] ~= nil) then
		for _, connection in pairs(animTable[name].connections) do
			connection:disconnect()
		end
	end
	animTable[name] = {}
	animTable[name].count = 0
	animTable[name].totalWeight = 0
	animTable[name].connections = {}


	local config = script:FindFirstChild(name)
	if (config ~= nil) then
		table.insert(animTable[name].connections, config.ChildAdded:connect(function(child) configureAnimationSet(name, fileList) end))
		table.insert(animTable[name].connections, config.ChildRemoved:connect(function(child) configureAnimationSet(name, fileList) end))
		local idx = 1
		for _, childPart in pairs(config:GetChildren()) do
			if (childPart:IsA("Animation")) then
				table.insert(animTable[name].connections, childPart.Changed:connect(function(property) configureAnimationSet(name, fileList) end))
				animTable[name][idx] = {}
				animTable[name][idx].anim = childPart
				local weightObject = childPart:FindFirstChild("Weight")
				if (weightObject == nil) then
					animTable[name][idx].weight = 1
				else
					animTable[name][idx].weight = weightObject.Value
				end
				animTable[name].count = animTable[name].count + 1
				animTable[name].totalWeight = animTable[name].totalWeight + animTable[name][idx].weight
	--			print(name .. " [" .. idx .. "] " .. animTable[name][idx].anim.AnimationId .. " (" .. animTable[name][idx].weight .. ")")
				idx = idx + 1
			end
		end
	end
	if (animTable[name].count <= 0) then
		for idx, anim in pairs(fileList) do
			animTable[name][idx] = {}
			animTable[name][idx].anim = Instance.new("Animation")
			animTable[name][idx].anim.Name = name
			animTable[name][idx].anim.AnimationId = anim.id
			animTable[name][idx].weight = anim.weight
			animTable[name].count = animTable[name].count + 1
			animTable[name].totalWeight = animTable[name].totalWeight + anim.weight
--			print(name .. " [" .. idx .. "] " .. anim.id .. " (" .. anim.weight .. ")")
		end
	end
end

-- Setup animation objects
function scriptChildModified(child)
	local fileList = animNames[child.Name]
	if (fileList ~= nil) then
		configureAnimationSet(child.Name, fileList)
	end
end

script.ChildAdded:connect(scriptChildModified)
script.ChildRemoved:connect(scriptChildModified)


for name, fileList in pairs(animNames) do
	configureAnimationSet(name, fileList)
end
end

local toolAnim = "None"
local toolAnimTime = 0

local jumpAnimTime = 0
local jumpAnimDuration = 0.3

local toolTransitionTime = 0.1
local fallTransitionTime = 0.3
local jumpMaxLimbVelocity = 0.75


function stopAllAnimations()
	local oldAnim = currentAnim

	if (emoteNames[oldAnim] ~= nil and emoteNames[oldAnim] == false) then
		oldAnim = "idle"
	end

	currentAnim = ""
	if (currentAnimKeyframeHandler ~= nil) then
		currentAnimKeyframeHandler:disconnect()
	end

	if (currentAnimTrack ~= nil) then
		currentAnimTrack:Stop()
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end
	return oldAnim
end
	if (currentAnimTrack ~= nil) then
		currentAnimTrack:Stop()
		currentAnimTrack:Destroy()
		currentAnimTrack = nil
	end
	return oldAnim
end

function setAnimationSpeed(speed)
	if speed ~= currentAnimSpeed then
		currentAnimSpeed = speed
		currentAnimTrack:AdjustSpeed(currentAnimSpeed)
	end
end

function keyFrameReachedFunc(frameName)
	if (frameName == "End") then
		print("Keyframe : ".. frameName)
		local repeatAnim = stopAllAnimations()
		local animSpeed = currentAnimSpeed
		playAnimation(repeatAnim, 0.0, Humanoid)
		setAnimationSpeed(animSpeed)
	end
end


function playAnimation(animName, transitionTime, humanoid)
	local idleFromEmote = (animName == "idle" and emoteNames[currentAnim] ~= nil)
	if (animName ~= currentAnim and not idleFromEmote) then

		if (currentAnimTrack ~= nil) then
			currentAnimTrack:Stop(transitionTime)
			currentAnimTrack:Destroy()
		end

		currentAnimSpeed = 1.0
		local roll = math.random(1, animTable[animName].totalWeight)
		local origRoll = roll
		local idx = 1
		while (roll > animTable[animName][idx].weight) do
			roll = roll - animTable[animName][idx].weight
			idx = idx + 1
		end
		local anim = animTable[animName][idx].anim


		currentAnimTrack = humanoid:LoadAnimation(anim)


		currentAnimTrack:Play(transitionTime)
		currentAnim = animName

		if (currentAnimKeyframeHandler ~= nil) then
			currentAnimKeyframeHandler:disconnect()
		end
		currentAnimKeyframeHandler = currentAnimTrack.KeyframeReached:connect(keyFrameReachedFunc)
	end
end



local toolAnimName = ""
local toolAnimTrack = nil
local currentToolAnimKeyframeHandler = nil

function toolKeyFrameReachedFunc(frameName)
	if (frameName == "End") then
		local repeatAnim = stopToolAnimations()
		playToolAnimation(repeatAnim, 0.0, Humanoid)
	end
end


function playToolAnimation(animName, transitionTime, humanoid)
	if (animName ~= toolAnimName) then

		if (toolAnimTrack ~= nil) then
			toolAnimTrack:Stop()
			toolAnimTrack:Destroy()
			transitionTime = 0
		end
