--!strict
-- Services
local RunService = game:GetService("RunService")

-- Packages
local Package = script
local Packages = Package.Parent
local Maid = require(Packages:WaitForChild("Maid"))
local ColdFusion = require(Packages:WaitForChild("ColdFusion"))
local GeometryUtil = require(Packages:WaitForChild("GeometryUtil"))

-- Modules

-- Constants
local Raycaster = {}
Raycaster.__index = Raycaster

function Raycaster:Destroy()
	local maid = self.Maid
	for k, v in pairs(self) do
		self[k] = nil
	end
	setmetatable(self, nil)
	maid:Destroy()
end

type State<T> = ColdFusion.State<T>
type ValueState<T> = ColdFusion.ValueState<T>
type ParameterValue<T> = T | State<T>

export type RaycasterParameters = {
	Name: ParameterValue<string>?,
	IsEnabled: ParameterValue<boolean>?,
	CollisionGroup: ParameterValue<string>?,
	FilterList: ParameterValue<{ [number]: Instance }?>?,
	FilterType: ParameterValue<Enum.RaycastFilterType>?,
	Origin: ParameterValue<Vector3>?,
	Direction: ParameterValue<Vector3>?,
	Parent: ParameterValue<Instance>?,
}

export type Raycaster = {
	CFrame: State<CFrame>,
	Material: State<Enum.Material>,
	Name: State<string>,
	IsEnabled: State<boolean>,
	CollisionGroup: State<string>,
	Whitelist: State<{ [number]: Instance }>,
	Origin: State<Vector3>,
	Direction: State<Vector3>,
	Parent: State<Instance?>,
	Instance: Configuration,
	_RaycastParams: State<RaycastParams>,
	_Result: State<{ Instance: Instance, Position: GeometryUtil.Point, Normal: GeometryUtil.Normal }?>,
	Hit: State<BasePart?>,
	Normal: State<GeometryUtil.Normal?>,
	Position: State<GeometryUtil.Point?>,
}

local function constructor(config: RaycasterParameters): Raycaster
	local _maid = Maid.new()
	local _fuse = ColdFusion.fuse(_maid)
	local _new = _fuse.new
	local _import = _fuse.import
	local _Value = _fuse.Value
	local _Computed = _fuse.Computed

	local Name = _import(config.Name, "Raycaster") :: ValueState<string>
	local Parent = _import(config.Parent, workspace)
	local IsEnabled = _import(config.IsEnabled, true) :: ValueState<boolean>
	local FilterType = _import(config.FilterType, Enum.RaycastFilterType.Include) :: ValueState<Enum.RaycastFilterType>

	local CollisionGroup = _import(config.CollisionGroup, "Default")
	local FilterList = _import(config.FilterList, {})
	local Origin = _import(config.Origin, Vector3.new(0, 0, 0))
	local Direction = _import(config.Direction, Vector3.new(0, 0, math.huge))

	--solving from properties
	local _RaycastParams: State<RaycastParams> = _Computed(function(list, group, filterType)
		-- print("L", list, "G", group, "F", filterType)
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = list or {}
		rayParams.FilterType = filterType
		rayParams.CollisionGroup = group
		-- _maid._rParams = rayParams
		return rayParams
	end, FilterList, CollisionGroup, FilterType)

	local _Result: State<RaycastResult?> = _Computed(function(enab: boolean, ori: Vector3, dir: Vector3, params: RaycastParams): RaycastResult?
		if not enab then
			return nil
		end
		return workspace:Raycast(ori, dir, params)
	end, IsEnabled, Origin, Direction, _RaycastParams)

	local Hit: State<BasePart?> = _Computed(function(res: RaycastResult?): BasePart?
		if res then
			local inst: BasePart = res.Instance :: any
			-- print("H-INST", inst)
			return inst
		end
		return nil
	end, _Result)
	local Normal: State<Vector3?> = _Computed(function(res: RaycastResult?): Vector3?
		if res then
			-- print("H-NOR", res.Normal)
			return res.Normal
		end
		return nil
	end, _Result)

	local Position: State<Vector3?> = _Computed(function(res: RaycastResult?): Vector3?
		if res then
			-- print("H-POS", res.Position)

			return res.Position
		end
		return nil
	end, _Result)
	local Material: State<Enum.Material?> = _Computed(function(res: RaycastResult?): Enum.Material?
		if res then
			return res.Material
		end
		return nil
	end, _Result)

	local function solveCF(hit: BasePart?, pos: Vector3?, norm: Vector3?): CFrame?
		if not hit or not pos or not norm then
			-- print("FAIL", hit, pos, norm)
			return nil
		end
		assert(hit ~= nil)
		assert(pos ~= nil)
		assert(norm ~= nil)
		local zVec = -norm
		local yVec
		if math.abs(Vector3.new(0, 1, 0):Dot(zVec)) < 0.5 then
			if math.abs(hit.CFrame.XVector:Dot(zVec)) > 0.5 then
				if math.abs(Vector3.new(0, 1, 0):Dot(hit.CFrame.YVector)) > 0.5 then
					yVec = hit.CFrame.YVector
				else
					yVec = hit.CFrame.ZVector
				end
			elseif math.abs(hit.CFrame.YVector:Dot(zVec)) > 0.5 then
				if math.abs(Vector3.new(0, 1, 0):Dot(hit.CFrame.XVector)) > 0.5 then
					yVec = hit.CFrame.XVector
				else
					yVec = hit.CFrame.ZVector
				end
			elseif math.abs(hit.CFrame.ZVector:Dot(zVec)) > 0.5 then
				if math.abs(Vector3.new(0, 1, 0):Dot(hit.CFrame.XVector)) > 0.5 then
					yVec = hit.CFrame.XVector
				else
					yVec = hit.CFrame.YVector
				end
			end
		else
			if math.abs(hit.CFrame.XVector:Dot(zVec)) > 0.5 then
				if math.abs(Vector3.new(0, 0, 1):Dot(hit.CFrame.YVector)) > 0.5 then
					yVec = hit.CFrame.YVector
				else
					yVec = hit.CFrame.ZVector
				end
			elseif math.abs(hit.CFrame.YVector:Dot(zVec)) > 0.5 then
				if math.abs(Vector3.new(0, 0, 1):Dot(hit.CFrame.XVector)) > 0.5 then
					yVec = hit.CFrame.XVector
				else
					yVec = hit.CFrame.ZVector
				end
			elseif math.abs(hit.CFrame.ZVector:Dot(zVec)) > 0.5 then
				if math.abs(Vector3.new(0, 0, 1):Dot(hit.CFrame.XVector)) > 0.5 then
					yVec = hit.CFrame.XVector
				else
					yVec = hit.CFrame.YVector
				end
			end
		end

		local xVec = yVec:Cross(zVec)
		-- print("DONE")
		return CFrame.fromMatrix(pos, xVec, yVec, zVec)
	end

	-- local RayCFrame: State<CFrame?> = _Computed(solveCF, Hit, Position, Normal)
	local RayCFrame: ValueState<CFrame?> = _Value(nil) :: any
	_maid:GiveTask(RunService.RenderStepped:Connect(function()
		local h: BasePart? = Hit:Get()
		local p: Vector3? = Position:Get()
		local n: Vector3? = Normal:Get()
		local cf: CFrame? = solveCF(h, p, n)
		RayCFrame:Set(cf)
	end))

	local self = {
		Maid = _maid,
		Name = Name,
		IsEnabled = IsEnabled,
		CollisionGroup = CollisionGroup,
		Whitelist = FilterList,
		Origin = Origin,
		Direction = Direction,
		Parent = Parent,
		_RaycastParams = _RaycastParams,
		_Result = _Result,
		Hit = Hit,
		Position = Position,
		Normal = Normal,
		Material = Material,
		["CFrame"] = RayCFrame,
		["Instance"] = _new("Configuration")({
			Parent = Parent,
			Name = Name,
		}),
	}

	setmetatable(self, Raycaster)

	return self :: any
end

return constructor
