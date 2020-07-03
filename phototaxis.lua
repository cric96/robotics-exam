local braitenberg = require "braitenberg"
local utils = require "utils"
local trial = require "trial"
local vector = require "vector"
MAX_VEL = 10
oldFitness = 0
initialPos = {}
initialRotation = {}
rewardFile = io.open("rewards.lua", "w")
config = io.open("config.lua", "w")
goodConfig = {}
trialCount = 2000
--scelgo i livelli da mettere nel controllo

function degFromQuaternion(quaternion)
	return math.deg(quaternion.toeulerangles(quaternion))
end

function spin() robot.wheels.set_velocity(2,-2) end

function action() 
	leftLight = robot.light[2].value
	rightRight = robot.light[23].value
	braitenberg.putSensors(Pair(leftLight, rightRight))
	velocity = braitenberg.computeCurrentVelocity()
	robot.wheels.set_velocity(MAX_VEL * velocity(x), MAX_VEL * velocity(y))
end

function fitness()
	velocity = braitenberg.computeCurrentVelocity()
	avgVelocity = (velocity(x) + velocity(y)) / 2
	velocityDiff = math.abs((velocity(x) - velocity(y)))
	maxLight = robot.maxSensorValue(robot.light)
	return avgVelocity * (1 - math.sqrt(velocityDiff)) * (maxLight)
end

function printStatistics() 
	trial.printStatistic()
end

function mutateCoefs()
	braitenberg.alterRandomTimes(10)
end

function init() 
	initialPos = robot.positioning.position
	oldPos = robot.positioning.position
	initialRotation = degFromQuaternion(robot.positioning.orientation)
	leftLight = robot.light[2].value
	rightRight = robot.light[23].value
	print(leftLight, rightRight)
	braitenberg.putSensors(Pair(leftLight, rightRight))
	braitenberg.randomConfiguration()
	io.output(config)
	io.write(table.concat(braitenberg.getCoefficients(), ", "))
	io.write("\n")
	io.output(rewardFile)
	trial.putTimes(trialCount)
	trial.putActionFunction(action)
	trial.putEvalFunction(fitness)
end
-- FSM for trail and repositioning
TRIAL = 0
REPOSITIONING = 1
RETURN_AT_START = 2
RETURN_TO_ANGLE = 3
state = TRIAL
targetAngle = 0

function prepareRepositioning() 
	currentPos = robot.positioning.position
	deltaX = initialPos["x"] - currentPos["x"]
	deltaY = initialPos["y"] - currentPos["y"] 
	startVector = vector.vec2_new_cart(deltaX, deltaY)
	angleTarget = vector.vec2_angle(startVector)
	angleTarget = math.floor((math.deg(angleTarget)))
	state = REPOSITIONING
end

function trialStateAction() 
	trial.tick()
	if trial.isEnd() then
		io.write(trial.currentReward())
		io.write("\n")
		printStatistics()
		if oldFitness < trial.currentReward() then
			oldFitness = trial.currentReward()
			copyTableIn(goodConfig, braitenberg.getCoefficients(), 4)
		else
			--braitenberg.revert()
		end
		spin()
		trial.restart()
		mutateCoefs()
		prepareRepositioning()
	end
end

function isAngleReached(target)
	currentAngle = degFromQuaternion(robot.positioning.orientation)
	return math.abs((currentAngle - target)) < 2
end

function repositioningStateAction() 
	if(isAngleReached(angleTarget)) then
		robot.wheels.set_velocity(MAX_VEL,MAX_VEL)
		state = RETURN_AT_START
	end
end 

function returnToStart() 
	currentPos = robot.positioning.position
	deltaX = math.abs(currentPos["x"] - initialPos["x"])
	deltaY = math.abs(currentPos["y"] - initialPos["y"])
	if deltaX < 0.2 and deltaY < 0.2 then
		spin()
		state = RETURN_TO_ANGLE
		--state = TRIAL
	end
end

function returnToAngle()
	if(isAngleReached(initialRotation)) then
		robot.wheels.set_velocity(0,0)
		state = TRIAL
	end
end

function step()
	if state == TRIAL then
		trialStateAction()
	elseif state == REPOSITIONING then
		repositioningStateAction()
	elseif state == RETURN_AT_START then
		returnToStart()
	elseif state == RETURN_TO_ANGLE then
		returnToAngle()
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
