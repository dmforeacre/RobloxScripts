local Poly = require(script.Parent.ComplexPolynomial)
local Complex = require(script.Parent.Complex)

-- Create folder to store parts in
local pixels = Instance.new("Folder")
pixels.Name = "Pixels"
pixels.Parent = workspace

-- Function to normalize a complex number-- rounds it to 2 decimal places
local function norm(c)
	return(Complex.new(math.round(c.real*100)/100,math.round(c.imag*100)/100))
end

-- Constants
-- Color scheme to use for found roots
local COLORS = {Color3.fromRGB(140,95,102),Color3.fromRGB(172,188,165),Color3.fromRGB(232,185,171),
	Color3.fromRGB(224,152,145),Color3.fromRGB(203,118,158),Color3.fromRGB(44, 17, 30),
	Color3.fromRGB(49, 33, 35),Color3.fromRGB(78, 94, 69)}
-- Color to use if no root is found
local NO_ROOT = Color3.fromRGB(0,0,0)
-- Dimensions of fractal
local MAX_X = 200
local MAX_Y = 200
-- Number of threads to use in rendering
local NUM_THREADS = 12

-- Point to start placing parts at
local origin = Vector3.new(0,-125,0)

-- Current polynomial: x^3 - 1
local roots = {Complex.new(1,0),norm(Complex.new(-.5,math.sqrt(3)/2)),norm(Complex.new(-.5,-math.sqrt(3)/2))}
local term1 = {Complex.new(1,0),Complex.new(3,0)}
local term2 = {Complex.new(-1,0),Complex.new(0,0)}
local poly = Poly.new(term1, term2)
local deriv = Poly:deriv(poly)

-- Create grid and begin calculating roots
local grid = table.create(MAX_X)
for t = 1, NUM_THREADS do
	task.spawn(function()
		local startX = (t * MAX_X) / NUM_THREADS
		local endX = ((t+1) * MAX_X) / NUM_THREADS
		for x = startX, endX do
			grid[x] = table.create(MAX_Y)
			for y = 1, MAX_Y do
				local root, iter = poly:newton(deriv, Complex.new(x - (MAX_X/2),y - (MAX_Y/2)), 0)
				local color = COLORS[table.find(roots,norm(root))]
				if color == nil then
					color = NO_ROOT
				end
        -- Adjust final color based on number of iterations
				color = Color3.fromRGB(color.R - (iter/200), color.G - (iter/200), color.B - (iter/200))
        -- Create 'pixel' parts
				local pixel = Instance.new("Part")
				pixel.Color = color
				pixel.Size = Vector3.new(.1,.1,.1)
				pixel.Position = origin + Vector3.new(x/10,y/10,0)
				pixel.Anchored = true
				pixel.Parent = pixels
				task.wait()		
			end
		end
	end)
end
