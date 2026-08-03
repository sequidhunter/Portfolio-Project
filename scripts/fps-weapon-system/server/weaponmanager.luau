local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Shared = ReplicatedStorage.Shared
local Libraries = Shared.Libraries

local UpdateOrigin = ReplicatedStorage.Remotes.UpdateOrigin


local Packets = require(Shared.packets)

local WeaponConfigs = require(Shared.Configs.WeaponsConfig)
local PlayerTemplate = require(script.Template)
local WeaponCore = require(script.WeaponCore)
local DeepCopy = require(Shared.Libraries.DeepCopy)

local WeaponManager = {}
WeaponManager.Active = {} :: {[Player] : PlayerTemplate.Template }
WeaponManager.ActiveFiring = {}

local packetCallbacks = {
	onWeaponPacket = function(packetData : {}?, player : Player?)
		assert(packetData, "Unable to fetch packet data.")
		if type(packetData) ~= "table" then
			return nil
		end 

		local event = packetData.event
		if event and type(event) == "string" then
			local eventFunction = WeaponManager[event]
			if eventFunction then
				eventFunction(WeaponManager,player)
			end
		end

	end,
	onPositionUpdate = function(packetData : {},player : Player)
		local data = WeaponManager.Active[player]
		if not data then return end

		local random = Random.new()
		local weaponData = data.States.activeWeapon
		local spread = weaponData.Spread

		WeaponManager.Active[player].States.origin = packetData
		--print("New packet data:",packetData,"for",player)
	end,
}



local function OnPlayerAdded(player : Player)
	if WeaponManager.Active[player] then
		return
	end

	WeaponManager.Active[player] = DeepCopy.Copy(PlayerTemplate)
	local data = WeaponManager.Active[player] :: PlayerTemplate.Template
	WeaponManager.Active[player].States.activeWeapon = data.Weapons.Primary or data.Weapons.Secondary

	print("player added. Send weapon update event.")
	player.CharacterAppearanceLoaded:Connect(function()
		Packets.WeaponUpdate.sendTo(
			{
				currentAmmo  = data.States.activeWeapon.CurrentAmmo,
				maxAmmo = data.States.activeWeapon.Ammo,
				weapon = data.States.activeWeapon.Name,

			},
			player
		)
	end)

end

local function OnPlayerRemoved(player : Player)
	if not WeaponManager.Active[player] then
		return
	end

	WeaponManager.Active[player] = nil
	if WeaponManager.ActiveFiring[player] then
		WeaponManager.ActiveFiring[player] = nil
	end
end

function WeaponManager.init()
	Players.PlayerAdded:Connect(OnPlayerAdded)
	Players.PlayerRemoving:Connect(OnPlayerRemoved)

	Packets.WeaponPacket.listen(packetCallbacks.onWeaponPacket)
	Packets.PositionUpdatePacket.listen(packetCallbacks.onPositionUpdate)

	local FiringConn = RunService.Heartbeat:Connect(function(dt)
		for player,_ in pairs(WeaponManager.ActiveFiring) do
			local data = WeaponManager.Active[player] 
			
			if not data then
				return
			end
			
			if (os.clock() - data.States.lastShot) < data.States.activeWeapon.Firerate then
				return
			end

			WeaponCore:Shoot(player,data.States.activeWeapon,data.States.origin,data.States.lastShot)
			data.States.lastShot = os.clock()

		end

	end)

end

function WeaponManager:Shoot(player : Player)
	local data = WeaponManager.Active[player] 
	if not data then
		return
	end

	if data.States.isFiring 
		or data.States.isReloading
	then
		return
	end

	WeaponManager.Active[player].States.isFiring = true

	if data.States.activeWeapon.Firemode == "Automatic" then

		WeaponManager.ActiveFiring[player] = true
	else
		if (os.clock() - data.States.lastShot) < data.States.activeWeapon.Firerate then
			return
		end
 		WeaponCore:Shoot(player,data.States.activeWeapon,data.States.origin,data.States.lastShot)
		data.States.lastShot = os.clock()
	end

end

function WeaponManager:ShootEnded(player : Player)
	local data = WeaponManager.Active[player]
	if not data then
		return
	end


	if not data.States.isFiring then
		return
	end
	WeaponCore:ShootEnd(data.States.activeWeapon)

	WeaponManager.Active[player].States.isFiring = false
	if WeaponManager.ActiveFiring[player] then
		WeaponManager.ActiveFiring[player] = nil
	end
end

function WeaponManager:Reload(player : Player)
	local data = WeaponManager.Active[player]
	if not data then
		return
	end
	if WeaponManager.Active[player].States.isFiring then
		return
	end

	local weaponData = data.States.activeWeapon
	WeaponManager.Active[player].States.isReloading = true

	if not WeaponManager.Active[player].States.isReloading then
		return
	end
	WeaponManager.Active[player].States.isReloading = false
	WeaponManager.Active[player].States.activeWeapon.CurrentAmmo = weaponData.Ammo
	Packets.WeaponUpdate.sendTo(
		{
			currentAmmo  = data.States.activeWeapon.CurrentAmmo,
			maxAmmo = data.States.activeWeapon.Ammo,
			weapon = data.States.activeWeapon.Name,
			
		},
		player
	)

end

function WeaponManager:SetWeaponAndSlot(player : Player, weaponName : string, slot : string)
	local playerData = WeaponManager.Active[player]
	if not playerData then return end
	
	local weaponData = WeaponConfigs[weaponName]
	if not weaponData then return end


	if playerData.States.activeWeapon == playerData.Weapons[slot] then
		

		playerData.Weapons[slot] = DeepCopy.Copy(weaponData)
		WeaponManager:Swap(player,slot)
	else
		playerData.Weapons[slot] = DeepCopy.Copy(weaponData)

	end


end

function WeaponManager:ReloadCancel(player : Player)
	local data = WeaponManager.Active[player]
	if not data then
		return
	end
	if not data.States.isReloading then
		return
	end
	WeaponManager.Active[player].States.isReloading = false


end

function WeaponManager:Swap(player : Player, weaponSlot : string)
	local data = WeaponManager.Active[player]
	if not data then
		return
	end
	
	if not weaponSlot then

		local currentWeapon = data.States.activeWeapon

		for slot,weapon in pairs(data.Weapons) do
			if weapon == nil or weapon == {} then continue end
			
			if currentWeapon ~= weapon then
				data.States.activeWeapon = data.Weapons[slot]
				break
			end
		end
	else
		local newWeapon = data.Weapons[weaponSlot]
		if not newWeapon then return end

		if data.States.activeWeapon == newWeapon then
			return
		end
		data.States.activeWeapon = newWeapon

	end

	Packets.WeaponUpdate.sendTo(
		{
			currentAmmo  = data.States.activeWeapon.CurrentAmmo,
			maxAmmo = data.States.activeWeapon.Ammo,
			weapon = data.States.activeWeapon.Name,

		},
		player
	)
end

function WeaponManager:SwapToPrimary(player : Player)
	WeaponManager:Swap(player,"Primary")
end

function WeaponManager:SwapToSecondary(player : Player)
	WeaponManager:Swap(player,"Secondary")
end

return WeaponManager
