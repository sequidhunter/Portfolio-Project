local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Libraries = Shared.Libraries

local Packets = require(Shared.packets)

local WeaponConfigs = require(Shared.Configs.WeaponsConfig)
local WeaponCast = require(script.Parent.WeaponCast)

local WeaponCore = {}
local enemiesFolder = workspace:WaitForChild("Enemies")
local castDistance = 500

function WeaponCore:Shoot(player : Player, playerWeapon : {}, origin : {}, lastShot : number)

	local bulletCount = playerWeapon.Bullets
	local pelletCount = playerWeapon.Pellets
	local damage = playerWeapon.Damage
	local spread = playerWeapon.Spread

	if playerWeapon.CurrentAmmo <= 0 then return end

	local character = player.Character
	local root = character:FindFirstChild("HumanoidRootPart")

	local rayParams = RaycastParams.new()
	rayParams.FilterDescendantsInstances = {character}
	
	
	local castParams = {
		origin = origin.origin,
		direction = origin.look,
		rayCount = pelletCount,
		rayDist = castDistance,
		raycastParams = rayParams,
		weaponSpread = spread,
	}

	local results = WeaponCast:Cast(castParams) :: {RaycastResult}
	if not results then
	else

	end

	for i,v in pairs(results) do
		if v.Instance then
			Packets.WeaponVFX.sendTo({goal = v.Position, normal = v.Normal},player)

		end
		if v.Instance:IsDescendantOf(enemiesFolder) then

			local enemyInstance = v.Instance.Parent
			local humanoid = enemyInstance:FindFirstChildOfClass("Humanoid")
			if not humanoid then continue end
			humanoid:TakeDamage(damage)
		end
	end

	playerWeapon.CurrentAmmo -= bulletCount
	local pos = root.Position

	Packets.SoundPacket.sendToAll({name = (playerWeapon.Name.."_Fire") ,parent = root})
	Packets.WeaponUpdate.sendTo(
		{
			currentAmmo  = playerWeapon.CurrentAmmo,
			maxAmmo = playerWeapon.Ammo,
			weapon = playerWeapon.Name,

		},
		player
	)
end

return WeaponCore
