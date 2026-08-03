local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage.Shared

local WeaponConfigs = require(Shared.Configs.WeaponsConfig)
local DeepCopy = require(Shared.Libraries.DeepCopy)

export type Template = {
	
	States : {
		isFiring : boolean,
		isReloading : boolean,
		
		activeWeapon : {},
		currentAmmo : number,

		origin : {},
		lastShot : number,
	},

	Weapons : {
		Primary : {},
		Secondary : {},
	},
}

return {
	
	States = {
		isFiring = false,
		isReloading = false,

		activeWeapon = nil,
		currentAmmo = 0,

		origin = {origin = Vector3.new(), look = Vector3.new()},

		lastShot = 0
	},
	
	Weapons = {
		Primary = DeepCopy.Copy(WeaponConfigs["Assault Rifle"]),
		Secondary = DeepCopy.Copy(WeaponConfigs["Heavy Pistol"]),
	}

}
