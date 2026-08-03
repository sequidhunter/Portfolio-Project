local WeaponCast = {}

export type castParams = {
	origin : Vector3,
	direction : Vector3,
	rayCount : number,
	rayDist : number,
	rayParams : RaycastParams,
	weaponSpread : number,
}

local function CastRays(origin : Vector3,direction : Vector3, rayCount : number, rayDist : number, rayParams : RaycastParams?, weaponSpread : number)
	local random = Random.new()
	local castResults  : {RaycastResult} = {}
	
	for i = 1,rayCount do

		local spread = weaponSpread
		local x,y,z = random:NextNumber(-spread,spread), random:NextNumber(-spread,spread), random:NextNumber(-spread,spread)
		
		local spread = (direction + Vector3.new(x,y,z))
		
		local result = workspace:Raycast(origin, spread*rayDist,rayParams)

		if result then
			table.insert(castResults,result)
		end
	end
	return castResults
end


function WeaponCast:Cast(castParams : {})

	local origin = castParams.origin
	local direction = castParams.direction
	local rayCount = castParams.rayCount
	local rayDist = castParams.rayDist
	local rayParams = castParams.raycastParams
	local weaponSpread = castParams.weaponSpread

	return CastRays(origin,direction,rayCount,rayDist,rayParams,weaponSpread)
end

return WeaponCast
