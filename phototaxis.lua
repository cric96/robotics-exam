local braitenberg = require "braitenberg"
local utils = require "utils"
local trial = require "trial"
local vector = require "vector"
-- fixed max velocity at motors 
MAX_VEL = 10
-- the last best fitness value  
oldFitness = 0
-- initial position of the robot
initialPos = {}
-- initial rotation of the robot
initialRotation = {}
-- the file used to store all reward computed after each trial
rewardFile = io.open("rewards.lua", "w")
-- the file used to store initial configuration and the best configuration found
config = io.open("config.lua", "w")
-- best configuration found during the training
goodConfig = {}
-- trial lenght expessed in number of ticks
trialCount = 2000
-- return the rotation in deg from a quaternion
function degFromQuaternion(quaternion)
	return math.deg(quaternion.toeulerangles(quaternion))
end

-- the robot spin indefinitely
function spin() robot.wheels.set_velocity(2,-2) end
--[[
	main function called at each tick, it:
		1 - eval light from sensors 2 and 23
		2 - update the braitenberg model
		3 - compute velocity
		4 - put the amplified velocity in the motors
]]--
function action() 
	leftLight = robot.light[2].value
	rightRight = robot.light[23].value
	braitenberg.putSensors(Pair(leftLight, rightRight))
	velocity = braitenberg.computeCurrentVelocity()
	robot.wheels.set_velocity(MAX_VEL * velocity(x), MAX_VEL * velocity(y))
end

-- fitness function inspired from paper "Automatic  creation  of  an  autonomous agent"
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
-- perform a random mutation to the Braitenberg model
function mutateCoefs()
	braitenberg.alterRandomTimes(10)
end

function init() 
	-- this part is used to store initial position and direction, usefull at the end of each trial during the repositioning
	initialPos = robot.positioning.position
	oldPos = robot.positioning.position
	initialRotation = degFromQuaternion(robot.positioning.orientation)
	-- init the Braitenberg configuration
	leftLight = robot.light[2].value
	rightRight = robot.light[23].value
	print(leftLight, rightRight)
	braitenberg.putSensors(Pair(leftLight, rightRight))
	braitenberg.randomConfiguration()
	-- output file used for statistics
	io.output(config)
	io.write(table.concat(braitenberg.getCoefficients(), ", "))
	io.write("\n")
	io.output(rewardFile)
	-- init trial with trial lenght, action function and eval function (fitness)
	trial.putTimes(trialCount)
	trial.putActionFunction(action)
	trial.putEvalFunction(fitness)
end
-- FSM for trail and repositioning
-- standard start, it use trial module
TRIAL = 0
-- called after the end of a trial, the robot spin until the robot direction point to the start
TURN_TOWARD_START = 1
-- the robot go straight until it doesn't reach a position near to the initial one
RETURN_TO_START = 2
-- OPTIONAL PHASE: after reaching the initial position, the robot spin untile it reach initial direction
RETURN_TO_ANGLE = 3
state = TRIAL

targetAngle = 0
-- compute the angle that point to the inital position using the positioning module
function prepareRepositioning() 
	currentPos = robot.positioning.position
	deltaX = initialPos["x"] - currentPos["x"]
	deltaY = initialPos["y"] - currentPos["y"] 
	startVector = vector.vec2_new_cart(deltaX, deltaY)
	targetAngle = vector.vec2_angle(startVector)
	targetAngle = math.floor((math.deg(targetAngle)))
	state = TURN_TOWARD_START
end

function trialStateAction() 
	-- continue a trial
	trial.tick()
	-- a trial is over, now it control the fitness value accumulated
	if trial.isEnd() then
		io.write(trial.currentReward())
		io.write("\n")
		printStatistics()
		-- new configuration perform better then the older, maitain it as the best.
		if oldFitness < trial.currentReward() then
			oldFitness = trial.currentReward()
			copyTableIn(goodConfig, braitenberg.getCoefficients(), 4)
		else
			-- new configuration goes worse the the older, revert to the older configuration.
			braitenberg.revert()
		end
		spin()
		-- restart the trial, clear the accumulative reward and tick times.
		trial.restart()
		-- perform a random mutation
		mutateCoefs()
		-- end standard adaptation scheme, prepare the robot to return at the initial position
		prepareRepositioning()
	end
end
-- return tru if the current robot direction is near (a varation of 2 degree) to the target 
function isAngleReached(target)
	currentAngle = degFromQuaternion(robot.positioning.orientation)
	return math.abs((currentAngle - target)) < 2
end
-- spin on itself until the robot direction is near to the target angle, after it alter wheels velocity to go straight.
function turnTowardStart() 
	if(isAngleReached(targetAngle)) then
		robot.wheels.set_velocity(MAX_VEL,MAX_VEL)
		state = RETURN_TO_START
	end
end 

-- go straight until it doesn't reach initial position. At that moment, the trial restarts.
-- OPTION: after, if spin on itself and goes to RETURN_TO_ANGLE STATE
function returnToStart() 
	currentPos = robot.positioning.position
	deltaX = math.abs(currentPos["x"] - initialPos["x"])
	deltaY = math.abs(currentPos["y"] - initialPos["y"])
	if deltaX < 0.2 and deltaY < 0.2 then
		--spin()
		--state = RETURN_TO_ANGLE
		state = TRIAL
	end
end
-- spin on itself until the robot direction is near to initial one. At the moment, the trial restarts.
function returnToAngle()
	if(isAngleReached(initialRotation)) then
		robot.wheels.set_velocity(0,0)
		state = TRIAL
	end
end

-- main function that implements a FSM with if-elseif.
function step()
	if state == TRIAL then
		trialStateAction()
	elseif state == TURN_TOWARD_START then
		turnTowardStart()
	elseif state == RETURN_TO_START then
		returnToStart()
	elseif state == RETURN_TO_ANGLE then
		returnToAngle()
	end
end

function reset()

end

-- close file and store the best configuration
function destroy()
	io.output(config)
	io.write(table.concat(goodConfig,", "))
	io.close(config)
	io.close(rewardFile)
end
