local total = 0
local function count(parent)
  for _, i in pairs(parent:GetDescendants()) do
    if i:IsA("Script") or i:IsA("ModuleScript") or i:IsA("LocalScript") then
      local code = i.Source
      local s, lines = string.gsub(code, '\n', '\n')
      total += lines
    end
  end
end
count(workspace)
count(game.ReplicatedFirst)
count(game.ReplicatedStorage)
count(game.ServerScriptService)
count(game.ServerStorage)
count(game.StarterPlayer)
print(total,"lines")
