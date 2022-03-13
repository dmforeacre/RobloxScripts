local function calcPath(player)
	print("Calculating path for "..player.Name)
	
	-- Get values from player data
	local board = PlayersClass[player]["board"]
	local maxX = PlayersClass[player]["boardMaxX"]
	local maxY = PlayersClass[player]["boardMaxY"]
	local start = board[1][1]
	local endBlock = board[maxX][maxY]
	
	-- Populate table of gScores and fScores with large numbers
	local gScore = table.create(maxX)
	local fScore = table.create(maxX)
	for i = 0, maxX do
		gScore[i] = table.create(maxY)
		fScore[i] = table.create(maxY)
		for j = 0, maxY do
			gScore[i][j] = 1000
			fScore[i][j] = 1000
		end
	end
	
	-- Set scores for start node
	gScore[1][1] = 0
	fScore[1][1] = (start.Body.Position - endBlock.Body.Position).Magnitude
	
	local prevNode = {}
	local open = {}
	local closed = {}
	table.insert(open, start)
	
	-- Main loop to find path
	local pathFound = false
	while #open ~= 0 do
		local current
		-- Get node with lowest fScore from open list
		local lowest = 1000
		local index
		for i = 1, #open do
			local x = open[i].xPos.Value
			local y = open[i].yPos.Value
			if fScore[x][y] < lowest then
				lowest = fScore[x][y]
				index = i
				current = open[i]
			end
		end
		
		-- Remove node from open
		table.remove(open, index)
		table.insert(closed, current)
		
		-- Exit loop if current node is the target
		if current == endBlock then
			pathFound = true
			break
		end

		-- Get list of neighbors
		local neighbors = table.create(4)
		local x = current.xPos.Value
		local y = current.yPos.Value
		-- Check if not at edge of board and not filled
		if x ~= 1 then
			table.insert(neighbors, board[x-1][y])
		end
		if y ~= 1 then
			table.insert(neighbors, board[x][y-1])
		end	
		if x ~= maxX then
			table.insert(neighbors, board[x+1][y])
		end
		if y ~= maxY then
			table.insert(neighbors, board[x][y+1])
		end
		
		-- Check neighbors for best path
		for i = 1, #neighbors do
			-- Check if neighbor is already in closed list and if so, remove
			local loc = table.find(closed, neighbors[i])
			if not loc then
				if neighbors[i] and (not neighbors[i].isFilled.Value or neighbors[i]==endBlock) then
					loc = table.find(open, neighbors[i])
					local nX = neighbors[i].xPos.Value
					local nY = neighbors[i].yPos.Value
					local tempGScore = gScore[x][y] + 1
					-- If the score of the neighbor is better then update path and values
					if tempGScore < gScore[nX][nY] or not loc then
						prevNode[neighbors[i]] = current
						gScore[nX][nY] = tempGScore
						fScore[nX][nY] = (neighbors[i].Body.Position - endBlock.Body.Position).Magnitude--(maxX - nX) + (maxY - nY)
						-- Check if neighbor is already in open
						if not loc then
							table.insert(open, neighbors[i])
						end
					end
				end
			end
		end
	end
	
	-- Remove previous nodes
	for _, part in pairs(WorkspaceService.Waypoints:GetChildren()) do
		part:Destroy()
	end
	
	local path = {}
	
	if not pathFound then
		path = {"Blocked"}
		sendMessage:FireClient(player, "The monsters grow furious!", 2)
	else
		local node = endBlock
		while prevNode[node] ~= nil do
			table.insert(path, node)
			node = prevNode[node]
		end
		
		--[[ Display waypoints
		for i = #path, 1, -1 do
			local x = path[i].xPos.Value
			local y = path[i].yPos.Value
			local waypoint = Instance.new("Part")
			waypoint.Shape = "Ball"
			waypoint.Material = "Neon"
			waypoint.Size = Vector3.new(0.6, 0.6, 0.6)
			waypoint.Anchored = true
			waypoint.CanCollide = false
			waypoint.Position = board[x][y].Body.Position
			waypoint.Parent = WorkspaceService.Waypoints
		end]]
	end
	
	PlayersClass[player]["path"] = path
	return path
end
