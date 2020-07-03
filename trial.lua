--[[
    describe a trial in a learning phase
    it has:
        - an actionFunction (i.e. the action that the robot does iteratively);
        - an evalFunction (i.e. a numeric value that sums up current env situation);
        - times (i.e. how many times the tick function could be called);
        - a reward accumulated evaluating evalFunction at each tick;
    to use this mudule you need to:
        - set times value with putTimes function;
        - set actionFuction with putActionFunction;
        - set evalFunction with putEvalFunction;
]]--
local trial = {}
local resetTime = 0
local actionFunction = {}
local times = 0
local testTimes = 0
local evalFunction = {}
local accumulativeReward = 0
-- restore the current trial configuration
function trial.restart()
    accumulativeReward = 0
    testTimes = times
    resetTime = resetTime + 1
end
-- return current reward accumulated during the test
function trial.currentReward() return accumulativeReward end

function trial.putTimes(value) 
    times = value
    testTimes = value
end
function trial.putActionFunction(fun) actionFunction = fun end
function trial.putEvalFunction(fun) evalFunction = fun end
function trial.printStatistic() 
    print(":: TRIAL N " .. resetTime .. " TOTAL REWARD = " .. accumulativeReward)
end
--[[
    core function. it :
        1. eval current situation;
        2. increase the reward value; 
        3.execute the actionFunction 
        4.decrease times value
    if the trial is over, no actions are performed.
]]--
function trial.tick()
    if not trial.isEnd() then
        accumulativeReward = accumulativeReward + evalFunction()
        actionFunction()    
        testTimes = testTimes - 1
    end
end 

function trial.isEnd() 
    return testTimes == 0
end

return trial