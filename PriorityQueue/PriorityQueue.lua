local PriorityQueue = {}

local Node = require(script.Parent.Node)

PriorityQueue.__index = PriorityQueue

-- Constructor
function PriorityQueue.new()
    local self = {}
    setmetatable(self, PriorityQueue)

    self.Root = nil
    self.Count = 0

    return self
end

-- Recursively inserts a node with lower priority values (higher priority) to the left
-- @param           node            Node            The current node to examine
-- @param           value           Any             The value to insert
-- @param           priority        Any             The priority of the given value
function RecursiveInsert(node, value, priority)
    if priority > node.Priority then
        if node.Right == nil then
            node.Right = Node.new(value, priority)
            node.Right.Parent = node
        else
            RecursiveInsert(node.Right, value, priority)
        end
    else
        if node.Left == nil then
            node.Left = Node.new(value, priority)
            node.Left.Parent = node
        else
            RecursiveInsert(node.Left, value, priority)
        end
    end
end

-- Adds a value with the given priorty to the queue
-- @param           value           Any             The value to insert
-- @param           priority        Any             The priority of the given value
function PriorityQueue:Enqueue(value, priority)
    if self.Root == nil then
        self.Root = Node.new(value, priority)
    else
        RecursiveInsert(self.Root, value, priority)
    end
    self.Count += 1
end

-- Recursively searches the tree for the lowest priority node
-- @param           node            Node            The current node to check
-- @return          Node            The lowest priority node of the tree
function PriorityQueue:RecursiveRemove(node)
    local myNode
    if node.Left == nil then
        if node.Parent == nil then
            self.Root = node.Right
        end
        if node.Right == nil then
            node.Parent.Left = nil
        else
            node.Parent.Left = node.Right
        end
        
        return node
    else
        myNode = self:RecursiveRemove(node.Left)
    end
    return myNode
end

-- Removes the value with the lowest priority
-- @return          Any         The value of the lowest priority node
-- @return          Any         The priority of that node
function PriorityQueue:Dequeue()
    if self.Count <= 0 then return end

    self.Count -= 1
    local myNode = self:RecursiveRemove(self.Root)
    if myNode.Parent == nil then
        self.Root = myNode.Right
    end
    
    return myNode.Value, myNode.Priority
end

-- Checks the lowest priority value in the queue without removing it
-- @return          Any         The value of the lowest priority node
-- @return          Any         The priority of that node
function PriorityQueue:Peek()
    local myNode

    return myNode.Value, myNode.Priority
end

-- Recursively builds a string to display the queue in order of priorty from least to greatest
-- @param           node            Node            The current node
-- @return          String          A string representation of the node
function RecursivePrint(node)
    if node == nil then
        return ""
    else
        local str = tostring(node.Value)
        return RecursivePrint(node.Left).." "..str.." "..RecursivePrint(node.Right)
    end
end

-- Overloaded function to display the priority queue as a string
-- @param           pq              PriorityQueue           The PriorityQueue to display as a string
-- @return          String          A string representation of the PriorityQueue
function PriorityQueue.__tostring(pq)
    local str = string.format("\n=== %i elements ===\n", pq.Count)
    str = str..RecursivePrint(pq.Root)
    return str
end

return PriorityQueue