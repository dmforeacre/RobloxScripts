--[[ Author: Daniel Foreacre (BahamutFierce)
     Date:   11/10/21
     Desc:   Class to represent complex numbers in Roblox lua ]]

local Complex = {}

Complex.__index = Complex

--[[ Constructor for a new complex number composed of a .real and .imag part
     @param     r     Real number part
     @param     i     Imaginary part
     @return    The complex number type ]]
function Complex.new(r, i)
	local self = {}
	setmetatable(self, Complex)
	
	self.real = r
	self.imag = i
	
	return self
end

--[[ Overloaded add function, adds real parts and imaginary parts separately
     @param     c1      Left hand side
     @param     c2      Right hand side
     @return    Sum of both complex numbers ]]
function Complex.__add(c1, c2)
	return Complex.new(c1.real + c2.real, c1.imag + c2.imag)
end

--[[ Overloaded subtract function, subtracts real and imaginary parts separately
     @param     c1      Left hand side
     @param     c2      Right hand side
     @return    Difference of the complex numbers ]]
function Complex.__sub(c1, c2)
	return Complex.new(c1.real - c2.real, c1.imag - c2.imag)
end

--[[ Overloaded multiplication function, multiplies using FOIL & simplifies
     @param     c1      Left hand side
     @param     c2      Right hand side
     @return    Product of the complex numbers]]
function Complex.__mul(c1, c2)
	return Complex.new((c1.real * c2.real) - (c1.imag * c2.imag), (c1.real * c2.imag) + (c1.imag * c2.real))
end

--[[ Overloaded division function, uses formula for complex division
     @param     c1      Left hand side
     @param     c2      Right hand side
     @return    Quotient of the complex numbers]]
function Complex.__div(c1, c2)
	local denom = (c2.real * c2.real) + (c2.imag * c2.imag)
	local left = ((c1.real*c2.real)+(c2.imag*c1.imag))/denom
	local right = ((c2.real*c1.imag)-(c1.real*c2.imag))/denom
	return Complex.new(left, right)
end

--[[ Overloaded equals function
     @param     c1      Left hand side
     @param     c2      Right hand side
     @return    Returns true if both real and imaginary parts are equal]]
function Complex.__eq(c1, c2)
	return c1.real == c2.real and c1.imag == c2.imag
end

--[[ Overloaded less than function
     @param     c1      Left hand side
     @param     c2      Right hand side
     @return    Returns true if ONLY REAL parts are equal]]
function Complex.__lt(c1, c2)
	return c1.real < c2.real
end

--[[ Overloaded tostring function
     @param     c       Complex number to print
     @return    Complex number represented as a string]]
function Complex.__tostring(c)
	local str = "("..c.real
	if c.imag >= 0 then
		str = str.." + "
	else
		str = str.." - "
	end
	str = str..math.abs(c.imag).."i)"	
	return str 
end

--[[ Power function. Uses multiplication to multiply val by itself, p.real times
     @param     val     Complex number to multiply
     @param     p       Power to multiply to
     @return    Complex number resulting from val ^ p]]
function Complex.pow(val, p)
	local product = Complex.new(1,0)
	for i = 1, p.real do
		product *= val
	end
	return product
end

--[[ Absolute value function
     @param     c     Complex number to take absolute value of
     @return    A complex number with the absolute value of both real and imaginary parts of input]]
function Complex.abs(c)
	return Complex.new(math.abs(c.real),math.abs(c.imag))
end

return Complex
