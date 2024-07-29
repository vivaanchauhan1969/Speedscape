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

