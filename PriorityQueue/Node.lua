local Node = {}

Node.__index = Node

function Node.new(value, priority)
    local self = {}
    setmetatable(self, Node)

    self.Value = value
    self.Priority = priority

    self.Parent = nil
    self.Left = nil
    self.Right = nil

    return self
end

return Node