--[[ 
    a module that describe a braitenberg type two vehicles. 
    it allow:
        1 - configure a random braitenberg vehicle;
        2 - perform a random mutation of coefficients;
        3 - controll current coefficients;
        4 - revert the last mutation;
        5 - compute current velocity (V_l and V_r).
]]--
local braitenberg = {}
local utils = require "utils"
-- sensors used to compute the motor velocity
local sensors = {}
--[[
    an array composing of four coefficients (due the limitation braitenberg type two vehicles )
        1 - VRO: initial velocity in the right motor;
        2 - VLO: initial velocity in the left motor;
        3 - ALPHA: coefficient used to manage sensor in the right part;
        4 - BETA: coefficient used to manage sensor in the left part;
]]--
local coefficients = {}
-- mantain the old varition before to act a mutation.
local oldVariation = {}
-- the maximum value of each coefficients
MAX_VALUE = 0.5
-- the maximum step of the random mutation
MAX_STEP = 0.01
-- standard index to the coefficents
VRO = 1
VLO = 2
ALPHA = 3
BETA = 4
-- internal function, return a random coefficent
function randomCoefs()
    return robot.random.uniform(0,MAX_VALUE)
end

-- internal function, return a mutation value in the range [ -MAX_STEP / 2, +MAX_STEP /]
function littleVariation()
    return robot.random.uniform(0, MAX_STEP) - (MAX_STEP / 2)
end

-- store current sensor perception.
function braitenberg.putSensors(_sensors) sensors = _sensors end

-- init the vehicles with a random configuration
function braitenberg.randomConfiguration()
    for i=1,4 do
        coefficients[i] = randomCoefs()
        oldVariation[i] = coefficients[i]
    end
end
-- store the current configuration. It is used before the mutation.
function braitenberg.storeConfig()
    for i=1,4 do
        oldVariation[i] = coefficients[i]
    end
end
-- alter a random coeficient and store current configuation
function braitenberg.alterRandom()
    braitenberg.alter(math.floor(robot.random.uniform(1,5)))
end
-- alter a random coefficient *elements* times and store current configuration
function braitenberg.alterRandomTimes(elements)
    braitenberg.storeConfig()
    for i=1,elements do
        __alterSingle(math.floor(robot.random.uniform(1,5)))
    end
end
-- alter a single coefficient in the *index* position
function braitenberg.alter(index)
    braitenberg.storeConfig()
    __alterSingle(index)
end
--[[
    internal function used to change a coefficient. It perform a mutation and check the correctness of the range.
    If it is out of bound, it force the coefficient to MAX of MIN (0) value 
]]--
function __alterSingle(index)
    coefficients[index] = coefficients[index] + littleVariation()
    if coefficients[index] > MAX_VALUE then
        coefficients[index] = MAX_VALUE
    elseif coefficients[index] < 0 then
        coefficients[index] = 0
    end
end
-- return current vehicles configuration
function braitenberg.getCoefficients() return coefficients end
-- revert the last mutation
function braitenberg.revert()
    for i=1,4 do
        coefficients[i] = oldVariation[i]
    end
end
--[[
    main function, compute the velocity following the model defined:
        V_r = VO_r + alpha * sensor_x + (0.5 - alpha) * sensor_y
        V_l = VO_l + beta * sensor_x + (0.5 - beta) * sensor_y
    it returns a pair. to access to the velocity you can follow this script:

    velocities = braitenberg.computeCurrentVelocity()
    vr = velocities(x)
    vl = velocities(y)
--]]
function braitenberg.computeCurrentVelocity()
    left_motor = coefficients[VLO] + coefficients[ALPHA] * sensors(x) + (MAX_VALUE - coefficients[ALPHA]) * sensors(y)
    right_motor = coefficients[VRO] + coefficients[BETA] * sensors(x) + (MAX_VALUE - coefficients[ALPHA]) * sensors(y)
    return Pair(left_motor, right_motor)
end

return braitenberg
