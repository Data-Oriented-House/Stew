--!strict
local testkit = require 'test/testkit'
local BENCH, START = testkit.benchmark()

local function TITLE(name: string)
	print()
	print(testkit.color.white(name))
end

local stew = require 'src/init'

local PN = 2 ^ 11 -- 2048

-- do
	local logs = {}

	TITLE(`practical test Stew EC ({PN} entities)`)
	local world = stew.world()

	local Position = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = 'Position',
	}

	local Velocity = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = 'Velocity',
	}

	local Health = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = 'Health',
	}

	local Dead = world.tag()
	Dead.data = 'Dead'

	local function init()
		for i = 1, PN do
			local id = world.entity()
			Position.add(id, i)
			Velocity.add(id, i)
			Health.add(id, 0)
		end
	end

	BENCH('create entities with 3 components', function()
		init()
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
		init()
	end)

	-- BENCH('update positions (cached)', function()
		for id, data in world.query { Position, Velocity } do
			data[Position] += data[Velocity] * 1 / 60
		end
	-- end)

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
