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
