--!strict

local charZero = '0'
local empty = table.freeze {}

local buffer4 = buffer.create(4)
local buffer4Str = buffer.tostring(buffer4)

local function toBits(num, bits)
	-- returns a table of bits, most significant first.
	bits = bits or math.max(1, select(2, math.frexp(num)))
	local t = {} -- will contain the bits
	for b = 1, bits do
		t[b] = math.fmod(num, 2)
		num = math.floor((num - t[b]) / 2)
	end
	return table.concat(t)
end

local function printBuffer(name: string, buf: buffer, bytes: number)
	local str = { name }
	for i = 0, bytes - 1 do
		table.insert(str, toBits(buffer.readu8(buf, i), 8))
	end
	print(table.concat(str, ' '))
end

local function compareMin(signature: buffer, collectionInclude: buffer, comp: (...number) -> number)
	local max, min
	if buffer.len(signature) > buffer.len(collectionInclude) then
		max = signature
		min = collectionInclude
	else
		max = collectionInclude
		min = signature
	end

	local len = buffer.len(min)
	local temp = buffer.create(len)
	buffer.copy(temp, 0, max, 0, len)

	for i = 0, len - 1, 4 do
		local maxVal = buffer.readu32(max, i)
		local minVal = buffer.readu32(min, i)
		local val = comp(maxVal, minVal)
		buffer.writeu32(temp, i, val)
	end

	for i = len - 4, 0, -4 do
		if buffer.readu32(temp, i) ~= 0 then
			break
		end
		len -= 4
	end

	len = math.max(len, 4)

	local final = buffer.create(len)
	buffer.copy(final, 0, temp, 0, len)

	return final
end

local function compare(signature: buffer, collectionInclude: buffer, comp: (...number) -> number)
	local max, min
	if buffer.len(signature) > buffer.len(collectionInclude) then
		max = signature
		min = collectionInclude
	else
		max = collectionInclude
		min = signature
	end

	local len = buffer.len(max)
	local temp = buffer.create(len)
	buffer.copy(temp, 0, max, 0, len)

	for i = 0, buffer.len(min) - 1, 4 do
		local maxVal = buffer.readu32(max, i)
		local minVal = buffer.readu32(min, i)
		local val = comp(maxVal, minVal)
		buffer.writeu32(temp, i, val)
	end

	for i = len - 4, 4, -4 do
		if buffer.readu32(temp, i) ~= 0 then
			break
		end
		len -= 4
	end

	local final = buffer.create(len)
	buffer.copy(final, 0, temp, 0, len)

	return final
end

local function bplace(place: number)
	place -= 1
	local i = place // 8
	local j = place % 8

	local buf = buffer.create(4 * (1 + place // 32))
	buffer.writeu8(buf, i, 2 ^ j)

	return buf
end

local function nextId(last: number)
	last += 1
	local bytes = math.ceil(math.log(last + 1, 256))
	local str = if bytes <= 1
		then string.char(math.floor(last) % 256)
		elseif bytes == 2 then string.char(math.floor(last) % 256, math.floor(last * 256 ^ -1) % 256)
		elseif bytes == 3 then string.char(
			math.floor(last) % 256,
			math.floor(last * 256 ^ -1) % 256,
			math.floor(last * 256 ^ -2) % 256
		)
		elseif bytes == 4 then string.char(
			math.floor(last) % 256,
			math.floor(last * 256 ^ -1) % 256,
			math.floor(last * 256 ^ -2) % 256,
			math.floor(last * 256 ^ -3) % 256
		)
		elseif bytes == 5 then string.char(
			math.floor(last) % 256,
			math.floor(last * 256 ^ -1) % 256,
			math.floor(last * 256 ^ -2) % 256,
			math.floor(last * 256 ^ -3) % 256,
			math.floor(last * 256 ^ -4) % 256
		)
		elseif bytes == 6 then string.char(
			math.floor(last) % 256,
			math.floor(last * 256 ^ -1) % 256,
			math.floor(last * 256 ^ -2) % 256,
			math.floor(last * 256 ^ -3) % 256,
			math.floor(last * 256 ^ -4) % 256,
			math.floor(last * 256 ^ -5) % 256
		)
		elseif bytes == 7 then string.char(
			math.floor(last) % 256,
			math.floor(last * 256 ^ -1) % 256,
			math.floor(last * 256 ^ -2) % 256,
			math.floor(last * 256 ^ -3) % 256,
			math.floor(last * 256 ^ -4) % 256,
			math.floor(last * 256 ^ -5) % 256,
			math.floor(last * 256 ^ -6) % 256
		)
		else string.char(
			math.floor(last) % 256,
			math.floor(last * 256 ^ -1) % 256,
			math.floor(last * 256 ^ -2) % 256,
			math.floor(last * 256 ^ -3) % 256,
			math.floor(last * 256 ^ -4) % 256,
			math.floor(last * 256 ^ -5) % 256,
			math.floor(last * 256 ^ -6) % 256,
			math.floor(last * 256 ^ -7) % 256
		)

	return last, str
end

--[=[
	@class Stew
]=]
local Stew = {}

export type Signature = string
export type Components = { [Factory<any, any, any, ...any, ...any>]: any }
export type Collection = {
	[any]: Components,
}
export type EntityData = {
	buffer: buffer,
	signature: Signature,
	components: Components,
}
export type Add<E, C, D, A..., R...> = (factory: Factory<E, C, D, A..., R...>, entity: E, A...) -> C
export type Remove<E, C, D, A..., R...> = (factory: Factory<E, C, D, A..., R...>, entity: E, component: C, R...) -> ()
export type Archetype<E, C, D, A..., R...> = {
	create: Add<E, C, D, A..., R...>,
	delete: Remove<E, C, D, A..., R...>,
	factory: Factory<E, C, D, A..., R...>,
	signature: Signature,
	buffer: buffer,
}
export type Factory<E, C, D, A..., R...> = {
	add: (entity: E, A...) -> C,
	remove: (entity: E, R...) -> (),
	get: (entity: E) -> C?,
	data: D,
	added: (entity: E, component: C) -> (),
	removed: (entity: E, component: C) -> (),
}

local function getCollection(world: World, include: buffer, exclude: buffer?): Collection
	local signature = buffer.tostring(include) .. if exclude then '!' .. buffer.tostring(exclude) else ''
	local found = world._signatureToCollection[signature]
	if found then
		return found
	end

	local includeStr = buffer.tostring(include)

	local collection = {} :: Collection
	world._signatureToCollection[signature] = collection

	local universal = world._signatureToCollection[buffer4Str]

	for entity in universal do
		local data = world._entityToData[entity]
		if
			buffer.tostring(compareMin(include, data.buffer, bit32.band)) == includeStr
			and (not exclude or buffer.tostring(compareMin(exclude, data.buffer, bit32.band)) == buffer4Str)
		then
			collection[entity] = data.components
		end
	end

	return collection
end

local function nop()
	return
end

local tag = {
	add = function(factory, entity: any)
		return true
	end,

	remove = nop,

	data = nil,
}

local function register(world: World, entity: any)
	assert(not world._entityToData[entity], 'Attempting to register entity twice')

	local entityData = {
		buffer = buffer4,
		components = {},
	}
	entityData.signature = buffer4Str

	world._entityToData[entity] = entityData

	getCollection(world, buffer4)[entity] = entityData.components

	world.spawned(entity)
end

local function unregister(world: World, entity: any)
	assert(world._entityToData[entity], 'Attempting to unregister entity twice')

	getCollection(world, buffer4)[entity] = nil
	world._entityToData[entity] = nil

	world.killed(entity)
end

local function updateCollections(world: World, entity: any, entityData: EntityData)
	local buf = entityData.buffer

	for collectionSignature, collection in world._signatureToCollection do
		local collectionSplit = string.split(collectionSignature, '!')
		local collectionInclude, collectionExclude = collectionSplit[1], collectionSplit[2]
		local includeBuffer, excludeBuffer =
			buffer.fromstring(collectionInclude), collectionExclude and buffer.fromstring(collectionExclude)

		if
			buffer.tostring(compareMin(includeBuffer, buf, bit32.band)) == collectionInclude
			and (not collectionExclude or buffer.tostring(compareMin(excludeBuffer, buf, bit32.band)) == charZero)
		then
			collection[entity] = entityData.components
		else
			collection[entity] = nil
		end
	end
end

--[=[
	@within World
	@interface Archetype
	.factory Factory<E, C, D, A..., R...>,
	.create (factory, entity: E, A...) -> C,
	.delete (factory, entity: E, component: C, R...) -> ()
	.signature string,
]=]

--[=[
	@within Stew
	@interface World
	. added (factory: Factory, entity: any, component: any)
	. removed (factory: Factory, entity: any, component: any)
	. spawned (entity: any) -> ()
	. killed (entity: any) -> ()
	. built (archetype: Archetype) -> ()
]=]

Stew._nextWorldId = -1

--[=[
	@within Stew
	@return World

	Creates a new world.

	```lua
	-- Your very own world to toy with
	local myWorld = Stew.world()

	-- If you'd like to listen for certain events, you can define these callbacks:

	-- Called whenever a new factory is built
	function myWorld.built(archetype: Archetype) end

	-- Called whenever a new entity is registered
	function myWorld.spawned(entity) end

	-- Called whenever an entity is unregistered
	function myWorld.killed(entity) end

	-- Called whenever an entity recieves a component
	function myWorld.added(factory, entity, component) end

	-- Called whenever an entity loses a component
	function myWorld.removed(factory, entity, component) end
	```
]=]
function Stew.world()
	--[=[
		@class World

		Worlds are containers for everything in your ECS. They hold all the state and factories you define later. They are very much, an isolated tiny world.

		"Oh what a wonderful world!" - Louis Armstrong
	]=]
	local world = {
		_nextPlace = 1,
		_nextEntityId = -1,
		_factoryToData = {},
		_entityToData = {},
		_signatureToCollection = {
			[buffer4Str] = {},
		},

		built = (nop :: any) :: <E, C, D, A..., R...>(archetype: Archetype<E, C, D, A..., R...>) -> (),
		spawned = nop :: (entity: any) -> (),
		killed = nop :: (entity: any) -> (),
		added = (nop :: any) :: <E, C, D, A..., R...>(
			factory: Factory<E, C, D, A..., R...>,
			entity: E,
			component: C
		) -> (),
		removed = (nop :: any) :: <E, C, D, A..., R...>(
			factory: Factory<E, C, D, A..., R...>,
			entity: E,
			component: C
		) -> (),
	}

	Stew._nextWorldId, world._id = nextId(Stew._nextWorldId)

	--[=[
		@within World
		@interface FactoryArgs
		.add (factory: Factory, entity: E, A...) -> C
		.remove (factory: Factory, entity: E, component: C, R...) -> ()?
		.data D?
	]=]

	--[=[
		@within World
		@param factoryArgs FactoryArgs
		@return Factory

		Creates a new factory from an `add` constructor and optional `remove` destructor. An optional `data` field can be defined here and accessed from the factory to store useful metadata like identifiers.

		```lua
		local world = Stew.world()

		local position = world.factory {
			add = function(factory, entity: any, x: number, y: number, z: number)
				return Vector3.new(x, y, z)
			end,
		}

		print(position.data)
		-- nil

		print(position.add('A really cool entity', 5, 7, 9))
		-- Vector3.new(5, 7, 9)

		position.remove('A really cool entity')

		local body = world.factory {
			add = function(factory, entity: Instance, model: Model)
				model.Parent = entity
				return model
			end,
			remove = function(factory, entity: Instance, component: Model)
				component:Destroy()
			end,
			data = 'A temple one might say...',
		}

		print(body.data)
		-- 'A temple one might say...'

		print(body.add(LocalPlayer, TemplateModel))
		-- TemplateModel

		body.remove(LocalPlayer)

		-- If you'd like to listen for interesting events to happen, define these callbacks:

		-- Called when an entity recieves this factory's component
		function body.added(entity: Instance, component: Model) end

		-- Called when an entity loses this factory's component
		function body.removed(entity: Instance, component: Model) end
		```
	]=]
	function world.factory<E, C, D, A..., R...>(factoryArgs: {
		add: Add<E, C, D, A..., R...>,
		remove: Remove<E, C, D, A..., R...>?,
		data: D?,
	})
		--[=[
			@class Factory

			Factories are little objects responsible for adding and removing their specific type of component from entities. They are also used to access their type of component from entities and queries. They are well, component factories!
		]=]
		local factory = {
			added = nop,
			removed = nop,
			data = factoryArgs.data,
		} :: Factory<E, C, D, A..., R...>

		local archetype = {
			factory = factory,
			buffer = bplace(world._nextPlace),
			create = factoryArgs.add :: Add<E, C, D, A..., R...>,
			delete = (factoryArgs.remove or nop) :: Remove<E, C, D, A..., R...>,
		}
		archetype.signature = buffer.tostring(archetype.buffer)

		--[=[
			@within Factory
			@param entity any
			@param ... any
			@return Component

			Adds the factory's type of component to the entity. If the component already exists, it just returns the old component and does not perform any further changes.

			Anything can be an Entity, if an unregistered object is given a component it is registered as an entity and fires the world `spawned` callback.

			Fires the world and factory `added` callbacks.

			```lua
			local World = require(path.to.world)
			local Move = require(path.to.move.factory)
			local Chase = require(path.to.chase.factory)
			local Model = require(path.to.model.factory)

			local enemy = World.entity()
			Model.add(enemy)
			Move.add(enemy)
			Chase.add(enemy)

			-- continues to below example
			```
		]=]
		function factory.add(entity: E, ...: A...): C
			local entityData = world._entityToData[entity]
			if not entityData then
				register(world, entity)
				entityData = world._entityToData[entity]
			end

			if entityData.components[factory] then
				return entityData.components[factory]
			end

			local component = archetype.create(factory, entity, ...)
			if component == nil then
				return (nil :: any) :: C
			end

			entityData.components[factory] = component

			entityData.buffer = compare(entityData.buffer, archetype.buffer, bit32.bor)
			entityData.signature = buffer.tostring(entityData.buffer)

			updateCollections(world, entity, entityData)

			factory.added(entity, component)
			world.added(factory, entity, component)

			return component
		end

		--[=[
			@within Factory
			@param entity any
			@param ... any
			@return void?

			Removes the factory's type of component from the entity. If the entity is unregistered, nothing happens.

			Fires the world and factory `removed` callbacks.

			If this is the last component the entity has, it kills the entity and fires the world `killed` callback.

			```lua
			-- continued from above example

			task.wait(5)

			Chase.remove(entity)
			Move.remove(entity)
			```
		]=]
		function factory.remove(entity: E, ...: R...): any?
			local entityData = world._entityToData[entity]
			if not entityData then
				return
			end

			local component = entityData.components[factory]
			if not component then
				return
			end

			archetype.delete(factory, entity, component, ...)

			entityData.buffer = compare(entityData.buffer, archetype.buffer, bit32.bxor)
			entityData.signature = buffer.tostring(entityData.buffer)

			entityData.components[factory] = nil

			updateCollections(world, entity, entityData)

			factory.removed(entity, component)
			world.removed(factory, entity, component)

			if not next(entityData.components) then
				unregister(world, entity)
			end

			return nil
		end

		--[=[
			@within Factory
			@param entity any
			@return Component?

			Returns the factory's type of component from the entity if it exists.

			If component is not a table or other referenced type it will not be mutable. Use `World.get` instead if this is a requirement.
			```lua
			local World = require(path.to.World)

			local Fly = World.factory { ... }

			for _, player in Players:GetPlayers() do
				Fly.add(player)
			end

			onPlayerTouched(BlackholeBrick, function(player: Player)
				local fly = Fly.get(player)
				if fly and fly.speed < Constants.LightSpeed then
					World.kill(player)
				end
			end)
			```
		]=]
		function factory.get(entity: E): C?
			local entityData = world._entityToData[entity]
			return if entityData then entityData.components[factory] else nil
		end

		world._factoryToData[factory] = archetype
		world._nextPlace += 1

		world.built(archetype :: any)

		return factory
	end

	--[=[
		@within World
		@return Factory

		Syntax sugar for defining a factory that adds a `true` component. It is used to mark the *existence* of the component, like a tag does.

		```lua
		local world = Stew.world()

		local sad = world.tag()
		local happy = world.tag()
		local sleeping = world.tag()
		local poisoned = world.tag()

		local allHappyPoisonedSleepers = world.query { happy, poisoned, sleeping }
		```
	]=]
	function world.tag()
		return world.factory(tag)
	end

	--[=[
		@within World

		Creates an arbitrary entity and registers it. Keep in mind, in Stew, *anything* can be an Entity (except nil). If you don't have a pre-existing object to use as an entity, this will create a unique identifier you can use.

		Can be sent over remotes and is unique across worlds!

		```lua
		local World = require(path.to.world)
		local Move = require(path.to.move.factory)
		local Chase = require(path.to.chase.factory)
		local Model = require(path.to.model.factory)

		local enemy = World.entity()
		Model.add(enemy)
		Move.add(enemy)
		Chase.add(enemy)

		-- continues to below example
		```
	]=]
	function world.entity(): string
		local entity
		world._nextEntityId, entity = nextId(world._nextEntityId)
		return world._id .. entity
	end

	--[=[
		@within World

		Removes all components from an entity and unregisters it.

		Fires the world `killed` callback.

		```lua
		-- continued from above example

		task.wait(5)

		World.kill(enemy)
		```
	]=]
	function world.kill(entity: any, ...: any)
		local entityData = world._entityToData[entity]
		if not entityData then
			return
		end

		for factory in entityData.components do
			factory.remove(entity, ...)
		end
	end

	--[=[
		@within World
		@type Components { [Factory]: Component }
	]=]

	--[=[
		@within World
		@tag Do Not Modify
		@return Components

		Gets all components of an entity in a neat table you can iterate over.

		This is a reference to the internal representation, so mutating this table directly will cause Stew to be out-of-sync.

		```lua
		local World = require(path.to.world)
		local Move = require(path.to.move.factory)
		local Chase = require(path.to.chase.factory)
		local Model = require(path.to.model.factory)

		local enemy = World.entity()

		Model.add(enemy)

		local components = world.get(enemy)

		for factory, component in components do
			print(factory, component)
		end
		-- Model, Model

		Move.add(enemy)

		for factory, component in components do
			print(factory, component)
		end
		-- Model, Model
		-- Move, BodyMover

		Chase.add(enemy)

		for factory, component in components do
			print(factory, component)
		end
		-- Model, Model
		-- Move, BodyMover
		-- Chase, TargetInstance

		print(world.get(entity)[Chase]) -- TargetInstance
		```
	]=]
	function world.get(entity: any): Components
		local data = world._entityToData[entity]
		return if data then data.components else empty
	end

	--[=[
		@within World
		@tag Do Not Modify
		@param include { Factory }
		@param exclude { Factory }?
		@return { [Entity]: Components }

		Gets a set of all entities that have all included components, and do not have any excluded components. (This is the magic sauce of it all!)

		This is a reference to the internal representation, so mutating this table directly will cause Stew to be out-of-sync.

		```lua
		local World = require(path.to.world)
		local Invincible = require(path.to.invincible.tag)
		local Poisoned = require(path.to.poisoned.factory)
		local Health = require(path.to.health.factory)
		local Color = require(path.to.color.factory)

		local poisonedHealths = world.query({ Poisoned, Health }, { Invincible })

		-- This is a very cool system
		RunService.Heartbeat:Connect(function(deltaTime)
			for entity, components in poisonedHealths do
				local health = components[Health]
				local poison = components[Poison]
				health.current -= deltaTime * poison

				if health.current < 0 then
					World.kill(entity)
				end
			end
		end)

		-- This is another very cool system
		RunService.RenderStepped:Connect(function(deltaTime)
			for entity, components in world.query { Poisoned, Color } do
				local color = components[Color]
				color.hue += deltaTime * (120 - color.hue)
				color.saturation += deltaTime * (1 - color.saturation)
			end
		end)
		```
	]=]
	function world.query(
		include: { Factory<any, any, any, ...any, ...any> },
		exclude: { Factory<any, any, any, ...any, ...any> }?
	): Collection
		local signatureInclude = buffer4

		for _, factory in include do
			local data = world._factoryToData[factory]
			if not data then
				error('Passed a non-factory or a different world\'s factory into an include query!', 2)
			end

			signatureInclude = compare(signatureInclude, data.buffer, bit32.bor)
		end

		local signatureExclude = nil

		if exclude then
			signatureExclude = buffer4
			for _, factory in exclude do
				local data = world._factoryToData[factory]
				if not data then
					error('Passed a non-factory or a different world\'s factory into an exclude query!', 2)
				end

				signatureExclude = compare(signatureExclude, data.buffer, bit32.bor)
			end
		end

		return getCollection(world, signatureInclude, signatureExclude)
	end

	return world
end

export type World = typeof(Stew.world(...))

local World = Stew.world()

local factories = {}

for i = 1, 1000 do
	local f = World.factory {
		add = function(f, e)
			return i
		end,

		data = i,
	}

	table.insert(factories, f)
end

local function getIds(factories: { any })
	local ids = {}

	for _, f in factories do
		table.insert(ids, f.data)
	end

	table.sort(ids)

	return table.concat(ids, '-')
end

local function getRandom(list)
	local i = math.random(1, #list)
	return i, list[i]
end

for i = 1, 10000 do
	local e = World.entity()

	for j = 1, 20 do
		local k, f = getRandom(factories)
		f.add(e)
	end
end

return Stew
