local braitenberg = require "braitenberg"
local utils = require "utils"
local trial = require "trial"
trialCount = 0
oldFitness = 0
MAX_VEL = 10
goodConfig = {}
trialCount = 5000
--scelgo i livelli da mettere nel controllo

rewardFile = io.open("rewards.lua", "w")
config = io.open("config.lua", "w")
io.output(config)
function action() 
	leftProximity = robot.proximity[2].value
	rightProximity = robot.proximity[23].value
	braitenberg.putSensors(Pair(leftProximity, rightProximity))
	velocity = braitenberg.computeCurrentVelocity()
	robot.wheels.set_velocity(MAX_VEL * velocity(x), MAX_VEL * velocity(y))
end

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
	braitenberg.putSensors(Pair(leftProximity, rightProximity))
	braitenberg.randomConfiguration()
	conf = braitenberg.getCoefficients()
	conf[VLO] = conf[VRO]
	io.write(table.concat(braitenberg.getCoefficients(), ", "))
	io.write("\n")
	io.output(rewardFile)
	trial.putTimes(trialCount)
	trial.putActionFunction(action)
	trial.putEvalFunction(fitness)
end

function mutateCoefs()
	braitenberg.alterRandomTimes(10)
end

function step()
	trial.tick()
	if trial.isEnd() then
		io.write(trial.currentReward())
		io.write("\n")
		printStatistics()
		if oldFitness < trial.currentReward() then
			print("good..")
			oldFitness = trial.currentReward()
			copyTableIn(goodConfig, braitenberg.getCoefficients(), 4)
		else
			print("revert..")
			braitenberg.revert()
		end
		trial.restart()
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
