--[[ 
    a module that describe a braitenber type two vehicles. 
    TODO add documentation
]]--
local braitenberg = {}
local utils = require "utils"

local sensors = {}
local coefficients = {}
local oldVariation = {}

MAX_VALUE = 0.5
MIN_STEP = 0.01
--TEST with MIN_STEP = 0.2
VRO = 1
VLO = 2
ALPHA = 3
BETA = 4

function randomCoefs()
    return robot.random.uniform(0,MAX_VALUE)
end

-- TODO PUT IT EXTERNAL 
function littleVariation()
    return robot.random.uniform(0, MIN_STEP) - (MIN_STEP / 2)
end

function braitenberg.putSensors(_sensors)
    sensors = _sensors
end

function braitenberg.randomConfiguration()
    for i=1,4 do
        coefficients[i] = randomCoefs()
        oldVariation[i] = coefficients[i]
    end
end

function braitenberg.storeOld()
    for i=1,4 do
        oldVariation[i] = coefficients[i]
    end
end
function braitenberg.alterRandom()
    braitenberg.alter(math.floor(robot.random.uniform(1,5)))
end

function braitenberg.alterRandomTimes(elements)
    braitenberg.storeOld()
    for i=1,elements do
        __alterSingle(math.floor(robot.random.uniform(1,5)))
    end
end

function braitenberg.alter(index)
    braitenberg.storeOld()
    __alterSingle(index)
end

function __alterSingle(index)
    coefficients[index] = coefficients[index] + littleVariation()
    if coefficients[index] > MAX_VALUE then
        coefficients[index] = MAX_VALUE
    elseif coefficients[index] < 0 then
        coefficients[index] = 0
    end
end
function braitenberg.getCoefficients()
    return coefficients
end

function braitenberg.revert()
    for i=1,4 do
        coefficients[i] = oldVariation[i]
    end
end

function braitenberg.computeCurrentVelocity()
    left_motor = coefficients[VLO] + coefficients[ALPHA] * sensors(x) + (MAX_VALUE - coefficients[ALPHA]) * sensors(y)
    right_motor = coefficients[VRO] + coefficients[BETA] * sensors(x) + (MAX_VALUE - coefficients[ALPHA]) * sensors(y)

    --left_motor = 0.46105581213395 + 0.1742672518965 * sensors(x) + (MAX_VALUE - 0.1742672518965) * sensors(y)
    --right_motor = 0.42527259294765 + 0.22395700629427 * sensors(x) + (MAX_VALUE - 0.22395700629427) * sensors(y)
    
    return Pair(left_motor, right_motor)
end

return braitenberg
