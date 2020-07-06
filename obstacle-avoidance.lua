local braitenberg = require "braitenberg"
local utils = require "utils"
local trial = require "trial"
-- the last best fitness value  
oldFitness = 0
-- fixed max velocity at motors 
MAX_VEL = 10
-- best configuration found during the execution
goodConfig = {}
-- trial lenght expessed in number of ticks
trialCount = 5000
-- the file used to store all reward computed after each trial
rewardFile = io.open("rewards.lua", "w")
-- the file used to store initial configuration and the best configuration found
config = io.open("config.lua", "w")
io.output(config)
--[[
	main function called at each tick, it:
		1 - eval proximity from sensors 2 and 23
		2 - update the braitenberg model
		3 - compute velocity
		4 - put the amplified velocity in the motors
]]--
function action() 
	leftProximity = robot.proximity[2].value
	rightProximity = robot.proximity[23].value
	braitenberg.putSensors(Pair(leftProximity, rightProximity))
	velocity = braitenberg.computeCurrentVelocity()
	robot.wheels.set_velocity(MAX_VEL * velocity(x), MAX_VEL * velocity(y))
end

-- fitness function inspired from paper "Automatic  creation  of  an  autonomous agent"
function fitness()
	velocity = braitenberg.computeCurrentVelocity()
	avgVelocity = (velocity(x) + velocity(y)) / 2
	velocityDiff = math.abs((velocity(x) - velocity(y)))
	maxProx = robot.maxSensorValue(robot.proximity)
	return avgVelocity * (1 - math.sqrt(velocityDiff)) * (1 - maxProx)
end

function printStatistics() 
	trial.printStatistic()
	print("MAX REWARD " .. oldFitness)
	print(table.concat(goodConfig,", "))
end

function init() 
	leftProximity = robot.proximity[2].value
	rightProximity = robot.proximity[23].value
	-- init the Braitenberg configuration, force the initial velocity to the same value
	braitenberg.putSensors(Pair(leftProximity, rightProximity))
	braitenberg.randomConfiguration()
	conf = braitenberg.getCoefficients()
	conf[VLO] = conf[VRO]
	-- output file used for statistics
	io.write(table.concat(braitenberg.getCoefficients(), ", "))
	io.write("\n")
	io.output(rewardFile)
	-- init trial with trial lenght, action function and eval function (fitness)
	trial.putTimes(trialCount)
	trial.putActionFunction(action)
	trial.putEvalFunction(fitness)
end

-- perform a random mutation of Braitenberg model
function mutateCoefs()
	braitenberg.alterRandomTimes(10)
end

-- loop function, it perform an online training schema, controlling the last best fitness function taken.
function step()
	-- continue a trial
	trial.tick()
	-- a trial is over, now it control the fitness value accumulated
	if trial.isEnd() then
		io.write(trial.currentReward())
		io.write("\n")
		printStatistics()
		-- new configuration perform better then the older, maitain it as the best.
		if oldFitness < trial.currentReward() then
			copyTableIn(goodConfig, braitenberg.getCoefficients(), 4)
			oldFitness = trial.currentReward()
		else
			-- new configuration goes worse the the older, revert to the older configuration.
			braitenberg.revert()
		end
		-- restart the trial, clear the accumulative reward and tick times.
		trial.restart()
		-- perform a random mutation
		mutateCoefs()
	end
end

function reset()

end

function destroy()
	io.output(config)
	io.write(table.concat(goodConfig,", "))
	io.close(config)
	io.close(rewardFile)
end
