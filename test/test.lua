--!strict
local testkit = require 'test/testkit'
local BENCH = testkit.benchmark()

if false then
	BENCH = function(_, c)
		c()
	end
end

local function TITLE(name: string)
	print()
	print(testkit.color.white(name))
end

local stew = require 'src/init'

local PN = 2 ^ 15 -- 2048

-- do
TITLE(`practical test Stew EC ({PN} entities)`)

local world
BENCH('create world', function()
	world = stew.world {}
end)

local Position, Velocity, Health, Dead

BENCH('create factories', function()
	Position = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = 'Position',
	}

	Velocity = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = 'Velocity',
	}

	Health = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = 'Health',
	}

	Dead = world.tag {
		data = 'Dead',
	}
end)

BENCH('create entities with 3 components', function()
	for i = 1, PN do
		local id = world.entity()
		Position.add(id, i)
		Velocity.add(id, i)
		Health.add(id, 0)
	end
end)

BENCH('update positions', function()
	for id, data in world.query { Position, Velocity } do
		data[Position] += data[Velocity] * 1 / 60
	end
end)

BENCH('add tags', function()
	for id, data in world.query { Health } do
		if data[Health] <= 0 then
			Dead.add(id)
		end
	end
end)

BENCH('destroy', function()
	--local i = 0
	for id in world.query { Dead } do
		--i += 1
		--print("killed", i, "entities")
		world.kill(id)
	end
end)

-- We re-run the benchmarks again as Stew apparently caches the Query arhcetype.
-- This turns every query into an O(1) operation and every add/remove operation into a O(n) operation where it has to go
-- through each collection and check if it matches

BENCH('create entities with 3 components (cached)', function()
	for i = 1, PN do
		local id = world.entity()
		Position.add(id, i)
		Velocity.add(id, i)
		Health.add(id, 0)
	end
end)

BENCH('update positions (cached)', function()
	local i = 0
	for id, data in world.query { Position, Velocity } do
		data[Position] += data[Velocity] * 1 / 60
		i += 1
	end
	print(i)
end)

BENCH('add tags (cached)', function()
	for id, data in world.query { Health } do
		local v = data[Health]
		if v <= 0 then
			Dead.add(id)
		end
	end
end)

BENCH('destroy (cached)', function()
	--local i = 0
	for id in world.query { Dead } do
		--i += 1
		--print("killed", i, "entities")
		world.kill(id)
	end
end)
-- end
