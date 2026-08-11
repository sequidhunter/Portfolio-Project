--!strict

--Types

export type RoundLogic = {

	Intermission : () -> (),
	RoundStart : () -> (),
	RoundEnd : () -> (),

}

--Services

local Players = game:GetService("Players")

--This can be replaced with other round logic, this is just a basic template with existing logic.

--Modules

local Spawnpoints = workspace:WaitForChild("SpawnPoints")
local MainSpawn = workspace:WaitForChild("MainSpawn")

local RoundLogic = {}

--Teleports the selected player to a specific CFrame, and keeps the players original rotation.
local function TeleportPlayer(player : Player, cframe : CFrame)

	local character = player.Character :: Model
	if not character then return end

	local root = character:FindFirstChild("HumanoidRootPart") :: BasePart
	if not root then return end

	local rootRotation = CFrame.Angles(root.CFrame:ToEulerAnglesXYZ())

	root.CFrame = cframe*rootRotation

end


--Empty function, can be filled with voting, or any other important pre-round logic.
function RoundLogic:Intermission()
end


--Starts the round, teleports each player to random spawn points.
function RoundLogic:RoundStart()
	local spawnArray = Spawnpoints:GetChildren()

	for _,player in pairs(Players:GetPlayers()) do
		local randomSpawnpoint = spawnArray[math.random(1,#spawnArray)] :: BasePart
		TeleportPlayer(player,randomSpawnpoint.CFrame)
	end

end


--Ends the round, teleports each player to the main spawn point.
function RoundLogic:RoundEnd()
	for _,player in pairs(Players:GetPlayers()) do
		TeleportPlayer(player,MainSpawn.CFrame)
	end
end

return RoundLogic
