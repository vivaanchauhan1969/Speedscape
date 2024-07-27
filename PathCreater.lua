local function makePathObject()
	local Path = {}

	local pathModels = nil

	local MODELS_AHEAD = 5

	Path.LastAdded = {}
	Path.pathModels = {}

	Path.Branches = {}

	Path.multipleBranches = false
	Path.BranchAt = nil
	Path.LastBranch = nil

	Path.AvailableModules = {}

	Path.CharacterHandler = require(script.CharacterHandler)()


	for _, pathCategory in pairs(game.ReplicatedStorage.PathModules:GetChildren()) do
		for _, pathModule in pairs(pathCategory:GetChildren()) do
			table.insert(Path.AvailableModules, pathModule)
		end
	end


	local function moveOffset(model, vector)
		if model:isA("Model") or model:isA("Folder") then
			for _, object in pairs(model:GetChildren()) do
				moveOffset(object, vector)
			end
		elseif model:isA("BasePart") then
			model.Position = model.Position - vector
		end
	end

	function Path:AddNewBranch(lastPathModel, playerName, pathType)
		Path.Branches = {}
		local endParts = lastPathModel:FindFirstChild("EndParts")
		endParts = endParts:GetChildren()
		if #endParts == 2 
			local top = nil
			local bottom = nil
			if endParts[1].Position.Y > endParts[2].Position.Y then
				top = endParts[1]
				bottom = endParts[2]
			else
				top = endParts[2]
				bottom = endParts[1]
			end
			top.Parent = lastPathModel
			local newBranch = self:addNewPathModel(lastPathModel, playerName, "GoingUp")
			newBranch.CurrentBranchValue.Value = newBranch.CurrentBranchValue.Value + 1
			Path.Branches[newBranch.CurrentBranchValue.Value] = top.Position
			top.Parent = lastPathModel.EndParts
			bottom.Parent = lastPathModel
			local newBranch = self:addNewPathModel(lastPathModel, playerName, "GoingDown")
			newBranch.CurrentBranchValue.Value = newBranch.CurrentBranchValue.Value + 2
			Path.Branches[newBranch.CurrentBranchValue.Value] = bottom.Position
		else
			table.sort(endParts,function(a, b) return a.Position.Y < b.Position.Y end)
			for i = 1, #endParts do
				endParts[i].Parent = lastPathModel
				if endParts[i].Position.Y > endParts[math.floor((#endParts + 1)/2)].Position.Y then
					local newBranch = self:addNewPathModel(lastPathModel, playerName, "GoingUp")
					newBranch.CurrentBranchValue.Value = newBranch.CurrentBranchValue.Value + i
					Path.Branches[newBranch.CurrentBranchValue.Value] = endParts[i].Position
				elseif endParts[i].Position.Y < endParts[math.floor((#endParts + 1)/2)].Position.Y then
					local newBranch = self:addNewPathModel(lastPathModel, playerName, "GoingDown")
					newBranch.CurrentBranchValue.Value = newBranch.CurrentBranchValue.Value + i
					Path.Branches[newBranch.CurrentBranchValue.Value] = endParts[i].Position
				else
					local newBranch = self:addNewPathModel(lastPathModel, playerName, "SameHeight")
					newBranch.CurrentBranchValue.Value = newBranch.CurrentBranchValue.Value + i
					Path.Branches[newBranch.CurrentBranchValue.Value] = endParts[i].Position
				end
				if i ~= #endParts then
					endParts[i].Parent = lastPathModel.EndParts
				end
			end
		end
	end

	function Path:addNewPathModel(lastPathModel, playerName, pathType)
		if lastPathModel:FindFirstChild("End") then
			local pathModelToAdd = nil
			if pathType == "random" then
				if Path.multipleBranches == false then
					pathModelToAdd = Path.AvailableModules[math.random(1, #Path.AvailableModules)]:Clone()
				else
					local pathModelsSameHeight = game.ReplicatedStorage.PathModules.SameHeight:GetChildren()
					pathModelToAdd = pathModelsSameHeight[math.random(1, #pathModelsSameHeight)]:Clone()
				end
			else
				local availModules = game.ReplicatedStorage.PathModules[pathType]:GetChildren()
				pathModelToAdd = availModules[math.random(1, #availModules)]:Clone()
			end
			local positionDifference = pathModelToAdd.Start.Position - lastPathModel.End.Position + Vector3.new(0, 0, (pathModelToAdd.Start.Size.Z + lastPathModel.End.Size.Z)/2)
			local addedPath = pathModelToAdd:Clone()
			moveOffset(addedPath, positionDifference)
			lastPathModel.CurrentBranchValue:Clone().Parent = addedPath
			addedPath.Parent = game.Workspace.Tracks[playerName]
			table.insert(Path.pathModels, addedPath)
			table.insert(Path.LastAdded, addedPath)
			if addedPath:FindFirstChild("EndParts") then
				Path.multipleBranches = true
				Path.BranchAt = addedPath.EndParts:FindFirstChild("End").Position.Z
			end
			return addedPath
		else
			self:AddNewBranch(lastPathModel, playerName, pathType)
		end
	end

	local function removeFromTable(item, theTable)
		for i = 1, #theTable do
			if theTable[i] == item then
				table.remove(theTable, i)
				break
			end
		end
	end

	function Path:tryCloseBranches(playerName)
		local player = game.Players:FindFirstChild(playerName)
		if player.Character.HumanoidRootPart.Position.Z < Path.BranchAt then
			Path.multipleBranches = false
			Path.LastBranch = Path.BranchAt
			local closest = nil
			local closestValue = nil
			
			for i, v in pairs(Path.Branches) do
				if closest == nil then
					closest = i
					closestValue = (player.Character.HumanoidRootPart.Position - v).magnitude
				else
					if (player.Character.HumanoidRootPart.Position - v).magnitude < closestValue then
						closest = i
						closestValue = (player.Character.HumanoidRootPart.Position - v).magnitude
					end
				end
			end

			for _, pathModel in pairs(game.Workspace.Tracks[player.Name]:GetChildren()) do
				if pathModel:isA("Model") then
					if pathModel:FindFirstChild("CurrentBranchValue") then
						if pathModel.CurrentBranchValue.Value ~= closest then
							game:GetService("Debris"):AddItem(pathModel, 3)
							removeFromTable(pathModel, Path.pathModels)
							removeFromTable(pathModel, Path.LastAdded)
						end
					end
				end
			end
		end
	end


	function Path:CheckExtendPath(playerName)
		local player = game.Players:FindFirstChild(playerName)
		if Path.LastAdded[1] then
			if player.Character.HumanoidRootPart.Position.Z < Path.LastAdded[1].Start.Position.Z + Path.LastAdded[1].PathBase.Size.Z*2 then
				self:addNewPathModel(Path.LastAdded[1], playerName, "random")
				table.remove(Path.LastAdded, 1)
			end
		else
			table.remove(Path.LastAdded, 1)
		end
	end


	function Path:CheckRemovePart(playerName)
		local player = game.Players:FindFirstChild(playerName)
		if player.Character.HumanoidRootPart.Position.Z < Path.pathModels[1].End.Position.Z - Path.pathModels[1].PathBase.Size.Z*3 then
			Path.pathModels[1]:Destroy()
			table.remove(Path.pathModels, 1)
		end
	end


	function Path:AddPathAsPlayerMoves(playerName)
		local player = game.Players:FindFirstChild(playerName)
		if player then
			if not player.Character then
				player.CharacterAdded:wait()
			end

			local extendPathConnection = game:GetService("RunService").Heartbeat:connect(function()
				if player.Character:FindFirstChild("HumanoidRootPart") then
					if Path.multipleBranches == true then
						self:tryCloseBranches(playerName)
					end
					self:CheckExtendPath(playerName)
					self:CheckRemovePart(playerName)
				end
			end)

			player.CharacterRemoving:connect(function() extendPathConnection:disconnect() end)
			player.Character.Humanoid.Died:connect(function() extendPathConnection:disconnect() end)
		end
	end


	function Path:AddFirstPathModel(trackModel)
		local pathToAdd = nil
		if game.ReplicatedStorage.PathModules:FindFirstChild("StartModule") ~= nil then
			pathToAdd = game.ReplicatedStorage.PathModules.StartModule:FindFirstChild("Start")
		else
			pathToAdd = Path.AvailableModules[math.random(1, #Path.AvailableModules)]
		end
		pathToAdd = pathToAdd:Clone()
		pathToAdd.Parent = trackModel
		pathToAdd:MoveTo(trackModel.Location.Value)

		local branchModifier = Instance.new("IntValue")
		branchModifier.Name = "CurrentBranchValue"
		branchModifier.Value = 0
		branchModifier.Parent = pathToAdd

		table.insert(Path.pathModels, pathToAdd)
		table.insert(Path.LastAdded, pathToAdd)
		return pathToAdd
	end


	local function findOpenSlot()
		local takenLocations = {}
		local defaultLocation = Vector3.new(0, 100, 0)
		for _, track in pairs(game.Workspace.Tracks:GetChildren()) do
			table.insert(takenLocations, track.Location.Value)
		end
		table.sort(takenLocations, function(a, b) return (a.X < b.X) end)
		for i = 1, #takenLocations do
			if (takenLocations[i].X > defaultLocation.X) then
				break
			else
				defaultLocation = Vector3.new(defaultLocation.X + 50, 100, 0)
			end
		end
		return defaultLocation
	end

	function Path:init(playerName)
		local previousTrack = game.Workspace.Tracks:FindFirstChild(playerName)
		if (previousTrack) thenw
			previousTrack:Destroy()
		end

		local trackModel = Instance.new("Model")
		trackModel.Name = playerName
		local location = Instance.new("Vector3Value")
		location.Name = "Location"
		location.Value = findOpenSlot()
		location.Parent = trackModel
		trackModel.Parent = game.Workspace.Tracks

		local firstAddedPath = self:
