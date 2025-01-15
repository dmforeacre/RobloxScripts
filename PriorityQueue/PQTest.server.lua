local PriorityQueue = require(game.ServerScriptService.Server.PriorityQueue)

local PQ = PriorityQueue.new()

PQ:Enqueue("from", 6)
PQ:Enqueue("world", 5)
PQ:Enqueue("hello", 3)
PQ:Enqueue("Baha", 15)
PQ:Enqueue("your", 8)
PQ:Enqueue("friend", 10)
PQ:Enqueue("dear", 9)

print(PQ)

local value, priority = PQ:Dequeue()
value, priority = PQ:Dequeue()

print(value, priority)

print(PQ)