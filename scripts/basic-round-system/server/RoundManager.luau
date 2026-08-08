--!strict

--Types

export type RoundManager = {
	__index : RoundManager,
	init : () -> RoundManager,

	StartTimer: (self : RoundManager, timerDuration : number) -> (),
	EndTimer : (self : RoundManager) -> (),

	RoundConnection : thread
}

--Modules


local Types = require(script:WaitForChild("Types"))
local RoundLogic = require(script:WaitForChild("RoundLogic"))

local RoundManager : RoundManager = {} :: RoundManager
RoundManager.__index = RoundManager

--Initializes the round manager, starts the round logic.
function RoundManager.init() : RoundManager
	local self = setmetatable({} :: RoundManager, RoundManager)

	--Creates a thread for the "RoundConnection" variable in order to do all the timers and logic
	self.RoundConnection = task.spawn(function()

		local ROUND_TIMER = 60
		local INTERMISSION_TIMER = 5
		local END_TIMER = 5

		--Round logic is contained in a while loop for simplicity
		while task.wait(1) do

			RoundLogic:Intermission()
			self:StartTimer(INTERMISSION_TIMER)

			RoundLogic:RoundStart()
			self:StartTimer(ROUND_TIMER)

			RoundLogic:RoundEnd()
			self:StartTimer(END_TIMER)

		end

	end)

	return self
end

--Starts a timer with a customizable duration for the timer.
function RoundManager:StartTimer(timerDuration : number)
	for i = 1,timerDuration do
		task.wait(1)
	end
	return
end


return RoundManager