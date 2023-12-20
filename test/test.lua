--!strict
local testkit = require 'test/testkit'
local BENCH, START = testkit.benchmark()

local function TITLE(name: string)
	print()
	print(testkit.color.white(name))
end

local stew = require 'src/init'

local function entityToString(entity)
	local w, a, b, c, d, e, f, g, h = string.byte(entity, 1, 9)
	local id = (h or 0) * 256 ^ 7
		+ (g or 0) * 256 ^ 6
		+ (f or 0) * 256 ^ 5
		+ (e or 0) * 256 ^ 4
		+ (d or 0) * 256 ^ 3
		+ (c or 0) * 256 ^ 2
		+ (b or 0) * 256
		+ a
	return 'e' .. id
end

local function BULK_CREATE_IDS(reg: stew.World, n: number): { string }
	local ids = table.create(n)
	for i = 1, n do
		ids[i] = reg.entity()
	end
	return ids
end

local N = 2 ^ 16 - 2 -- 65,534

local function REG_INIT()
	local world = stew.world()

	local A, B, C, D, E, F, G, H =
		world.tag(), world.tag(), world.tag(), world.tag(), world.tag(), world.tag(), world.tag(), world.tag()
	return world, A, B, C, D, E, F, G, H
end

--[[do TITLE "entities"

    BENCH("create (init)", function()
        local reg = REG_INIT()

        for i = 1, START(N) do
            reg.entity()
        end
    end)

    BENCH("release", function()
        local reg = REG_INIT()
        local id = table.create(N)

        for i = 1, N do
            id[i] = reg.entity()
        end

        for i = 1, START(N) do
            reg.kill(id[1])
        end
    end)

end

do TITLE "add"

    local function setup(n: number)

        local reg, A, B, C, D = REG_INIT()
        local ids = table.create(N)

        for i = 1, N do
            ids[i] = reg.entity()
        end

        reg.query({A, B, C, D}, {})
        reg.query({A}, {})
        reg.query({B}, {})
        reg.query({C}, {})
        reg.query({D}, {})
        reg.query({A, B}, {})
        reg.query({A, B, C}, {})

        return reg, ids, A, B, C, D

    end

    BENCH("1 component", function()

        local _, ids, A = setup(N/4)

        for i = 1, START(N) do
            A.add(ids[i])
        end

    end)

    BENCH("2 component", function()

        local _, ids, A, B = setup(N/4)

        for i = 1, START(N) do
            A.add(ids[i])
            B.add(ids[i])
        end

    end)

    BENCH("3 component", function()

        local _, ids, A, B, C = setup(N/4)

        for i = 1, START(N) do
            A.add(ids[i])
            B.add(ids[i])
            C.add(ids[i])
        end

    end)

    BENCH("4 component", function()

        local _, ids, A, B, C, D = setup(N/4)

        for i = 1, START(N) do
            A.add(ids[i])
            B.add(ids[i])
            C.add(ids[i])
            D.add(ids[i])
        end

    end)

end

do TITLE "get"

    local reg, A, B, C, D, E, F, G, H = REG_INIT()
    local ids = table.create(N)

    for i = 1, N do
        local e = reg.entity()
        ids[i] = e

        A.add(e)
        B.add(e)
        C.add(e)
        D.add(e)
        E.add(e)
        F.add(e)
        G.add(e)
        H.add(e)
    end

    BENCH("1 component", function()
        for i = 1, START(N) do
            A.get(ids[i])
        end
    end)

    BENCH("2 components", function()
        for i = 1, START(N) do
            local e = ids[i]
            A.get(e)
            B.get(e)
        end
    end)

    BENCH("4 components", function()
        for i = 1, START(N) do
            local e = ids[i]
            A.get(e)
            B.get(e)
            C.get(e)
            D.get(e)
        end
    end)

end

do TITLE "remove"

    local function setup()
        local reg, A, B, C, D, E, F, G, H = REG_INIT()
        local ids = table.create(N)

        for i = 1, N do
            local e = reg.entity()
            ids[i] = e

            A.add(e)
            B.add(e)
            C.add(e)
            D.add(e)
            E.add(e)
            F.add(e)
            G.add(e)
            H.add(e)
        end

        return reg, ids, A, B, C, D, E, F, G, H
    end

    BENCH("1 unowned", function()
        local reg, ids, A = setup()

        for i = 1, N do
            A.remove(ids[i])
        end

        for i = 1, START(N) do
            A.remove(ids[i])
        end
    end)

    BENCH("1 component", function()
        local reg, ids, A = setup()

        for i = 1, START(N) do
            A.remove(ids[i])
        end
    end)

    BENCH("2 component", function()
        local reg, ids, A, B = setup()

        for i = 1, START(N) do
            local e = ids[i]
            A.remove(e)
            B.remove(e)
        end
    end)

    BENCH("4 component", function()
        local reg, ids, A, B, C, D = setup()

        for i = 1, START(N) do
            local e = ids[i]
            A.remove(e)
            B.remove(e)
            C.remove(e)
            D.remove(e)
        end
    end)

end

type AnyFactory = stew.Factory<any, any, any, ...any>

do

    local function view_bench(reg: stew.World, A: AnyFactory, B: AnyFactory, C: AnyFactory, D: AnyFactory, E: AnyFactory, F: AnyFactory, G: AnyFactory, H: AnyFactory)
        local function exact_size(include: {AnyFactory}, exclude: {AnyFactory}): number
            local i = 0
            for _ in reg.query(include, exclude) do
                i += 1
            end
            return i
        end

        BENCH("1 component", function()
            START(exact_size({A}, {}))
            for entity, a in reg.query({A}, {}) do end
        end)

        BENCH("2 components", function()
            START(exact_size({A, B}, {}))
            for entity, a in reg.query({A, B}, {}) do end
        end)

        BENCH("4 components", function()
            START(exact_size({A, B, C, D}, {}))
            for entity, a in reg.query({A, B, C, D}, {}) do end
        end)

        BENCH("8 components", function()
            START(exact_size({A, B, C, D, E, F, G, H}, {}))
            for entity, a in reg.query({A, B, C, D, E, F, G, H}, {}) do end
        end)
    end

    do TITLE("iter view (ordered)")
        local reg, A, B, C, D, E, F, G, H = REG_INIT()

        for i = 1, N do
            local e = reg.entity()
            A.add(e)
            B.add(e)
            C.add(e)
            D.add(e)
            E.add(e)
            F.add(e)
            G.add(e)
            H.add(e)
        end

        view_bench(reg, A, B, C, D, E, F, G, H)
    end

    do TITLE("iter view (RANDOM)")
        local reg, A, B, C, D, E, F, G, H = REG_INIT()

        local function flip() return math.random() > 0.5 end

        for i = 1, N do
            local e = reg.entity()
            if flip() then A.add(e) end
            if flip() then B.add(e) end
            if flip() then C.add(e) end
            if flip() then D.add(e) end
            if flip() then E.add(e) end
            if flip() then F.add(e) end
            if flip() then G.add(e) end
            if flip() then H.add(e) end
        end

        view_bench(reg, A, B, C, D, E, F, G, H)
    end

    do TITLE("iter view (random + common)")
        local reg, A, B, C, D, E, F, G, H = REG_INIT()

        local function flip() return math.random() > 0.5 end

        for i = 1, N do
            local ent = reg.entity()
            local b,c,d,e,f,g,h
            if flip() then b=true;B.add(ent) end
            if flip() then c=true;C.add(ent) end
            if flip() then d=true;D.add(ent) end
            if flip() then e=true;E.add(ent) end
            if flip() then f=true;F.add(ent) end
            if flip() then g=true;G.add(ent) end
            if flip() then h=true;H.add(ent) end

            if b and c and d and ent and f and g and h then A.add(ent) end
        end

        view_bench(reg, A, B, C, D, E, F, G, H)
    end

end]]

local PN = 2 ^ 11 -- 2048

do
	local logs = {}

	TITLE(`practical test Stew EC ({PN} entities)`)
	local world = stew.world()

	local Position = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = "Position"
	}

	local Velocity = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = "Velocity"
	}

	local Health = world.factory {
		add = function(factory, entity, value: number)
			return value
		end,

		data = "Health"
	}

	local Dead = world.tag()
	Dead.data = "Dead"

	local function init()
		for i = 1, PN do
			local id = world.entity()
			Position.add(id, i)
			Velocity.add(id, i)
			Health.add(id, 0)
		end
	end

	print('create entities with 3 components')
	-- BENCH('create entities with 3 components', function()
		init()
	-- end)

	print('update positions')
	-- BENCH('update positions', function()
		for id, data in world.query { Position, Velocity } do
			data[Position] += data[Velocity] * 1 / 60
		end
	-- end)

	print('add tags')
	-- BENCH('add tags', function()
		for id, data in world.query { Health } do
			if data[Health] <= 0 then
				Dead.add(id)
			end
		end
	-- end)

	print('destroy')
	-- BENCH('destroy', function()
		--local i = 0
		for id in world.query { Dead } do
			--i += 1
			--print("killed", i, "entities")
			world.kill(id)
		end
	-- end)

	-- We re-run the benchmarks again as Stew apparently caches the Query arhcetype.
	-- This turns every add/remove operation into a O(n) operation where it has to go
	-- through a bunch of associated collections and check if it matches

	print('create entities with 3 components (cached)')
	-- BENCH('create entities with 3 components (cached)', function()
		init()
	-- end)

	print('update positions (cached)')
	-- BENCH('update positions (cached)', function()
		local i = 0
		for id, data in world.query { Position, Velocity } do
			data[Position] += data[Velocity] * 1 / 60
		end
		print(i)
	-- end)

	print('add tags (cached)')
	-- BENCH('add tags (cached)', function()
		for id, data in world.query { Health } do
			local v = data[Health]
			if not v then
				local id = entityToString(id)
				print(id .. ' Health is nil')
				for _, log in logs do
					if string.find(log, id) then
						print(log)
					end
				end
				error(id .. ' Health is nil')
			end
			if v <= 0 then
				Dead.add(id)
			end
		end
	-- end)

	print('destroy (cached)')
	-- BENCH('destroy (cached)', function()
		--local i = 0
		for id in world.query { Dead } do
			--i += 1
			--print("killed", i, "entities")
			world.kill(id)
		end
	-- end)
end
