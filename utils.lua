--[[ a module that contains some utility concepts.
    Pair : immutable sequence of two elements
    Triple : immutable sequence of three elements
    Quadruple : immutable sequence of four elements
example of usage:
pair = Pair(1,2)
pair(x); pair(y)
print_pair(pair)
triple = Triple(1,2,3)    
triple(x); triple(y); triple(z)
print_triple(triple)
quad = Quadruple(1,2,3,4)
quad(x); quad(y); quad(z); quad(k)
print_quadruple(quad)
]]--
local utils = {}

function Pair(_x, _y)
    return function(fn) return fn(_x, _y) end
end

function Triple(x, y, z)
        return function(fn) return fn(x, y, z) end
end
function Quadruple(x, y, z, k)
        return function(fn) return fn(x, y, z, k) end
end

function x(_x) return _x end
function y(_x, _y) return _y end
function z(_x, _y, _z) return _z end
function k(_x, _y, _z, _k) return _k end

function print_pair(pair) print(pair(x), pair(y)) end
function print_triple(triple) print(triple(x), triple(y), triple(z)) end
function print_quadruple(quad) print(quad(x), quad(y), quad(z), quad(k)) end

robot.maxSensorValue = function(sensors)
    value = -1 -- highest value found so far
	for i=1,#sensors do
		if value < sensors[i].value then
			value = sensors[i].value
		end
    end
    return value
end
function copyTableIn(result, reference, n)
    for i=1,n do
        result[i] = reference[i]
    end
end

return utils



