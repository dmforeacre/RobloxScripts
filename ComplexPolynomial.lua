--[[ Author: Daniel Foreacre (BahamutFierce)
     Date:   11/10/21
     Desc:   ModuleScript to implement a polynomial class using complex numbers. Requires Complex.lua.]]

local Complex = require(script.Parent.Complex)

local ComplexPolynomial = {}

ComplexPolynomial.__index = ComplexPolynomial

-- Constants
local ZERO = Complex.new(0,0)
local ONE = Complex.new(1,0)
local TOL = Complex.new(.001,0)
local MAX_ITER = 200

-- Constructor for new polynomial
-- @param		  ...		  	Variant number of arguments, each a {coefficient, exponent} pair
-- @return		The new polynomial
function ComplexPolynomial.new(...)
	local self = {}
	setmetatable(self, ComplexPolynomial)
	
	local args = {...}
	
	for i = 1, #args do
		table.insert(self, args[i])
	end
		
	return self
end

--[[ Overloaded tostring function
     @param     p     Polynomial to convert to a string
     @return    String representation of the polynomial]]
function ComplexPolynomial.__tostring(p)
	local str = ""
	for i = 1, #p do
		str = str.."("..p[i][1].."x^"..p[i][2]..")"
		if i ~= #p then
			str = str.." + "
		end
	end
	return str
end

--[[ Evaluates a polynomial at the given value
     @param     val     Value to evaluate as a complex number
     @return    Final value of the polynomial, as a complex number]]
function ComplexPolynomial:eval(val)
	local sum = ZERO
	for i = 1, #self do
		sum += Complex.pow(val, self[i][2]) * self[i][1]
	end
	return sum
end

--[[ Determines the derivative of the given polynomial
     @param     p       Polynomial to get derivative of
     @return    Derivative of p, as another ComplexPolynomial]]
function ComplexPolynomial:deriv(p)
	local d = {}
	for i = 1, #p do
		if p[i][2] ~= ZERO then
			table.insert(d, {p[i][1]*p[i][2], p[i][2] - ONE})
		end
	end
	return ComplexPolynomial.new(table.unpack(d))
end

--[[ Determines the closest root of the polynomial using Newton's Method recursively
     @param     deriv     Derivative of the calling function, as returned by :deriv
     @param     point     Point to begin at to determine closest root
     @param     iter      Count of the number of iterations
     @return    Determined root closest to original point, to within TOL]]
function ComplexPolynomial:newton(deriv, point, iter)
	local f = self:eval(point)
	local fp = deriv:eval(point)
	local quotient = f / fp
	local newPoint = point - quotient
	if Complex.abs(newPoint - point) < TOL  or iter > MAX_ITER then
		return newPoint, iter
	else
		return self:newton(deriv, newPoint, (iter + 1))
	end
end

return ComplexPolynomial
