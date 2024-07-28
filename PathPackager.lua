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
