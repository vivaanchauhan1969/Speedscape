local RoomPackager = {}

function RoomPackager:CornersOfPart(part)
	local cframe = part.CFrame
	local halfSizeX = part.Size.X / 2
	local halfSizeY = part.Size.Y / 2
	local halfSizeZ = part.Size.Z / 2

	local corners = {
		RightTopBack =		cframe:pointToWorldSpace(Vector3.new(halfSizeX, halfSizeY, halfSizeZ)),
		RightBottomBack =	cframe:pointToWorldSpace(Vector3.new(halfSizeX, -halfSizeY, halfSizeZ)),
		RightTopFront =		cframe:pointToWorldSpace(Vector3.new(halfSizeX, halfSizeY, -halfSizeZ)),
		RightBottomFront =	cframe:pointToWorldSpace(Vector3.new(halfSizeX, -halfSizeY, -halfSizeZ)),
		LeftTopBack =		cframe:pointToWorldSpace(Vector3.new(-halfSizeX, halfSizeY, halfSizeZ)),
		LeftBottomBack =	cframe:pointToWorldSpace(Vector3.new(-halfSizeX, -halfSizeY, halfSizeZ)),
		LeftTopFront =		cframe:pointToWorldSpace(Vector3.new(-halfSizeX, halfSizeY, -halfSizeZ)),
		LeftBottomFront =	cframe:pointToWorldSpace(Vector3.new(-halfSizeX, -halfSizeY, -halfSizeZ)),
	}

	return corners
end


function RoomPackager:TopCornersOfBasePlate(basePlate)
	local corners = self:CornersOfPart(basePlate)
	local centerY = basePlate.Position.Y
	local topCorners = {}
	for _, corner in pairs(corners) do
		if corner.Y > centerY then
			table.insert(topCorners, corner)
		end
	end
	return topCorners
end


function RoomPackager:RegionsFromBasePlate(basePlate)
	local topCorners = self:TopCornersOfBasePlate(basePlate)
	local arbitraryCorner = topCorners[1]
	local minX = arbitraryCorner.X
	local minZ = arbitraryCorner.Z
	local maxX = arbitraryCorner.X
	local maxZ = arbitraryCorner.Z
	for _, corner in pairs(topCorners) do
		minX = math.min(minX, corner.X)
		minZ = math.min(minZ, corner.Z)
		maxX = math.max(maxX, corner.X)
		maxZ = math.max(maxZ, corner.Z)
	end
	local minY = topCorners[1].Y
	local lowerCorner = Vector3.new(minX, minY, minZ)
	local maxY = minY + 70
	local upperCorner = Vector3.new(maxX, maxY, maxZ)

	local segmentHeight = math.floor(100000/(math.abs(maxX-minX)*math.abs(maxZ-minZ)))

	local regions = {}

	local currentHeight = minY
	while currentHeight - minY < 70 do
		currentHeight = currentHeight + segmentHeight
		lowerCorner = Vector3.new(lowerCorner.x, currentHeight - segmentHeight, lowerCorner.z)
		upperCorner = Vector3.new(upperCorner.x, currentHeight, upperCorner.z)
		table.insert(regions, Region3.new(lowerCorner, upperCorner))
	end

	return regions
end


local function closestParentToWorkspace(object, roomModel)
	if object.Parent == roomModel then
		return nil
	end
	if object.Parent == game.Workspace then
		return object
	else
		return closestParentToWorkspace(object.Parent, roomModel)
	end
end


function RoomPackager:CategoriseModel(pathModel)
	if pathModel:FindFirstChild("EndParts") then
		return game.ReplicatedStorage.PathModules.Branch
	elseif pathModel.Start.Position.Y < pathModel.End.Position.Y - 5 then
		return game.ReplicatedStorage.PathModules.GoingUp
	elseif pathModel.Start.Position.Y > pathModel.End.Position.Y + 5 then
		return game.ReplicatedStorage.PathModules.GoingDown
	else
		return game.ReplicatedStorage.PathModules.SameHeight
	end
end

local function addBehavioursRecur(model, behaviourFolder)
	local children = model:GetChildren()
	for i = 1, #children do
		if children[i]:isA("BasePart") then
			behaviourFolder:Clone().Parent = children[i]
		else
			addBehavioursRecur(children[i], behaviourFolder)
		end
	end
end

RoomPackager.setUpBehaviours = function(roomModel)
	if roomModel:FindFirstChild("Behaviours") then
		addBehavioursRecur(roomModel, roomModel.Behaviours)
		return
	end
	local children = roomModel:GetChildren()
	for i = 1, #children do
		RoomPackager.setUpBehaviours(children[i])
	end
end

local function processPart(roomModel, part, parts)
	if part.Parent == roomModel then return end
	if part.Name == "End" and roomModel:FindFirstChild("End") then
		local endsModel = Instance.new("Model") --Used for branching the path
		endsModel.Name = "EndParts"
		endsModel.Parent = roomModel
		part.Parent = endsModel
		roomModel:FindFirstChild("End").Parent = endsModel
	elseif part.Name == "End" and roomModel:FindFirstChild("EndParts") then
		part.Parent = roomModel:FindFirstChild("EndParts")
	elseif part.Name == "End" then
		part.Parent = roomModel
	else
		local topLevelParent = closestParentToWorkspace(part, roomModel)
		if topLevelParent ~= nil then
			if topLevelParent:isA("BasePart") then
				local connectedParts = topLevelParent:GetConnectedParts(true)
				for _, connectedPart in pairs(connectedParts) do
					if connectedPart.Name == "End" then
						table.insert(parts, connectedPart)
					else
						local conTopLevelParent = closestParentToWorkspace(connectedPart, roomModel)
						if conTopLevelParent and conTopLevelParent ~= topLevelParent then
							conTopLevelParent.Parent = roomModel
						end
					end
				end
			end
			topLevelParent.Parent = roomModel
		end
	end
end

function RoomPackager:PackageRoom(roomBasePlate)
	local roomModel = Instance.new("Model")
	roomModel.Name = "Path"
	roomModel.Parent = game.ReplicatedStorage.PathModules

	local regions = self:RegionsFromBasePlate(roomBasePlate)
	
	for i = 1, #regions do
		--Repeatedly finds 200 parts in the region until none are left
		while true do
			local parts = game.Workspace:FindPartsInRegion3(regions[i], nil, 200)
			if #parts == 0 then
				break
			end
			for _, part in pairs(parts) do
				processPart(roomModel, part, parts)
			end
		end
	end

	roomBasePlate.Transparency = 1
	roomBasePlate.Parent = roomModel
	roomModel:FindFirstChild("Start", true).Parent = roomModel
	roomModel:FindFirstChild("Start", true).Transparency = 1
	if roomModel:FindFirstChild("EndParts") then
		local ends = roomModel:FindFirstChild("EndParts"):GetChildren()
		for i = 1, #ends do
			ends[i].Transparency = 1
		end
	else
		roomModel.End.Transparency = 1
	end
	roomModel.PrimaryPart = roomBasePlate
	roomModel.Parent = self:CategoriseModel(roomModel)
	RoomPackager.setUpBehaviours(roomModel)
	return roomModel
end
return RoomPackager
