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
					local pathModelsSameHeight = game
