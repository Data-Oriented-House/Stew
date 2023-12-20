--!strict

local charEmpty = ''
local charZero = '0'
local asciiOne = string.byte '1'
local asciiZero = string.byte '0'
local empty = table.freeze {}

local DEBUG = false

local function sand(string1: string, string2: string): string
	local length = math.max(#string1, #string2)
	local string3 = table.create(length, 0)

	for i in string3 do
		string3[i] = if string.byte(string1, i) == asciiOne and string.byte(string2, i) == asciiOne then 1 else 0
	end

	for i = length, 1, -1 do
		if string3[i] ~= 0 then
			break
		end
		string3[i] = nil
	end

	local out = #string3 == 0 and charZero or table.concat(string3, charEmpty)

	if DEBUG then
		print('sand', 'x ' .. string1, 'y ' .. string2, ' = ' .. out)
	end

	return out
end

local function sor(string1: string, string2: string): string
	local length = math.max(#string1, #string2)
	local string3 = table.create(length, 0)

	for i in string3 do
		string3[i] = if string.byte(string1, i) == asciiOne or string.byte(string2, i) == asciiOne then 1 else 0
	end

	for i = length, 1, -1 do
		if string3[i] ~= 0 then
			break
		end
		string3[i] = nil
	end

	local out = #string3 == 0 and charZero or table.concat(string3, charEmpty)

	if DEBUG then
		print('sor', 'x ' .. string1, 'y ' .. string2, ' = ' .. out)
	end

	return out
end

local function sxor(string1: string, string2: string): string
	local length = math.max(#string1, #string2)
	local string3 = table.create(length, 0)

	for i in string3 do
		string3[i] = if (string.byte(string1, i) or asciiZero) == (string.byte(string2, i) or asciiZero) then 0 else 1
	end

	for i = #string3, 1, -1 do
		if string3[i] ~= 0 then
			break
		end
		string3[i] = nil
	end

	local out = #string3 == 0 and charZero or table.concat(string3, charEmpty)

	if DEBUG then
		print('sxor', 'x ' .. string1, 'y ' .. string2, ' = ' .. out)
	end

	return out
end

local function splace(place: number): string
	local str = table.create(place, 0)

	str[place] = 1

	local out = #str == 0 and charZero or table.concat(str, charEmpty)

	if DEBUG then
		print('splace', 'place ' .. place, ' = ' .. out)
	end

	return out
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

	if DEBUG then
		print('nextId', ' = last ' .. last, 'str ' .. str)
	end

	return last, str
end

--[=[
	@class Stew
]=]
local Stew = {}

--[=[
	@within Stew

	A function to extract the unique entity and world ids encoded in World.entity() strings.

	Only works if there are less than 256 worlds. (This is reasonable right?)

	```lua
	local Stew = require(path.to.Stew)

	local w0 = Stew.world()
	local e00 = w0.entity()
	local e10 = w0.entity()
	local e20 = w0.entity()

	print(Stew.tonumber(e00)) -- 0, 0
	print(Stew.tonumber(e10)) -- 1, 0
	print(Stew.tonumber(e20)) -- 2, 0

	local w1 = Stew.world()

	local e01 = w1.entity()
	local e11 = w1.entity()
	local e21 = w1.entity()

	print(Stew.tonumber(e01)) -- 0, 1
	print(Stew.tonumber(e11)) -- 1, 1
	print(Stew.tonumber(e21)) -- 2, 1
	```
]=]
function Stew.tonumber(entity: string)
	-- Please don't make 256 or more worlds
	local world, a, b, c, d, e, f, g, h = string.byte(entity, 1, 9)
	local id = (h or 0) * 256 ^ 7
		+ (g or 0) * 256 ^ 6
		+ (f or 0) * 256 ^ 5
		+ (e or 0) * 256 ^ 4
		+ (d or 0) * 256 ^ 3
		+ (c or 0) * 256 ^ 2
		+ (b or 0) * 256
		+ a
	return id, world
end

export type Signature = string
export type Components = { [Factory<any, any, any, ...any, ...any>]: any }
export type Collection = {
	[any]: Components,
}
export type EntityData = {
	signature: Signature,
	components: Components,
}
export type Add<E, C, D, A..., R...> = (factory: Factory<E, C, D, A..., R...>, entity: E, A...) -> C
export type Remove<E, C, D, A..., R...> = (factory: Factory<E, C, D, A..., R...>, entity: E, component: C, R...) -> ()
export type Archetype<E, C, D, A..., R...> = {
	create: Add<E, C, D, A..., R...>,
	delete: Remove<E, C, D, A..., R...>?,
	signature: Signature,
	factory: Factory<E, C, D, A..., R...>,
}
export type Factory<E, C, D, A..., R...> = {
	add: (entity: E, A...) -> C,
	remove: (entity: E, R...) -> (),
	get: (entity: E) -> C?,
	data: D,
	added: (entity: E, component: C) -> ()?,
	removed: (entity: E, component: C) -> ()?,
}

export type World = {
	_nextPlace: number,
	_nextEntityId: number,
	_factoryToData: { [Factory<any, any, any, ...any, ...any>]: Archetype<any, any, any, ...any, ...any> },
	_entityToData: { [any]: EntityData },
	_signatureToCollection: { [Signature]: Collection },
	_id: string,

	built: <E, C, D, A..., R...>(archetype: Archetype<E, C, D, A..., R...>) -> ()?,
	spawned: (entity: any) -> ()?,
	killed: (entity: any) -> ()?,
	added: <E, C, D, A..., R...>(factory: Factory<E, C, D, A..., R...>, entity: E, component: C) -> ()?,
	removed: <E, C, D, A..., R...>(factory: Factory<E, C, D, A..., R...>, entity: E, component: C) -> ()?,

	factory: <E, C, D, A..., R...>(
		factoryArgs: {
			add: Add<E, C, D, A..., R...>,
			remove: Remove<E, C, D, A..., R...>?,
			data: D?,
		}
	) -> Factory<E, C, D, A..., R...>,
	tag: () -> Factory<any, boolean, any, (), ()>,
	entity: () -> string,
	kill: (entity: any) -> (),
	get: (entity: any) -> Components,
	query: (
		include: { Factory<any, any, any, ...any, ...any> },
		exclude: { Factory<any, any, any, ...any, ...any> }?
	) -> Collection,
}

local function getCollection(world: World, signature: string): Collection
	local found = world._signatureToCollection[signature]
	if found then
		if DEBUG then
			print('getCollection (cached)', 's' .. signature)
		end
		return found
	end

	local split = string.split(signature, '!')
	local include, exclude = split[1], split[2]

	local collection = {} :: Collection
	world._signatureToCollection[signature] = collection

	local universal = world._signatureToCollection[charZero]

	for entity in universal do
		local data = world._entityToData[entity]
		if sand(include, data.signature) == include and (not exclude or sand(exclude, data.signature) == charZero) then
			collection[entity] = data.components
		end
	end

	if DEBUG then
		print('getCollection', 's' .. signature)
	end

	return collection
end

local tag = {
	add = function(factory, entity: any)
		return true
	end,

	data = nil,
}

local function register(world: World, entity: any)
	assert(not world._entityToData[entity], 'Attempting to register entity twice')

	local entityData = {
		signature = charZero,
		components = {},
	}

	world._entityToData[entity] = entityData

	if DEBUG then
		print('register', 'e' .. Stew.tonumber(entity))
	end

	getCollection(world, charZero)[entity] = entityData.components

	if world.spawned then
		world.spawned(entity)
	end
end

local function unregister(world: World, entity: any)
	assert(world._entityToData[entity], 'Attempting to unregister entity twice')

	if DEBUG then
		local e, w = Stew.tonumber(entity)
		local s = world._entityToData[entity].signature
		print('unregister', 'e' .. e, 'w' .. w, 's' .. s)
	end

	getCollection(world, charZero)[entity] = nil
	world._entityToData[entity] = nil

	if world.killed then
		world.killed(entity)
	end
end

local function updateCollections(world: World, entity: any, entityData: EntityData)
	local signature = entityData.signature

	if DEBUG then
		local e, w = Stew.tonumber(entity)
		print('updateCollections', 'e' .. e, 'w' .. w, 's' .. signature)
	end

	for collectionSignature, collection in world._signatureToCollection do
		local collectionSplit = string.split(collectionSignature, '!')
		local collectionInclude, collectionExclude = collectionSplit[1], collectionSplit[2]

		local collectionIncludeAndSignature = sand(collectionInclude, signature)
		local collectionExcludeAndSignature = if collectionExclude then sand(collectionExclude, signature) else nil

		if DEBUG then
			print(
				'',
				's' .. signature,
				'cs' .. collectionInclude,
				collectionIncludeAndSignature,
				collectionIncludeAndSignature == collectionInclude
			)
			if collectionExclude then
				print(
					'',
					's' .. signature,
					'cs' .. collectionExclude,
					collectionExcludeAndSignature :: string,
					not collectionExclude or collectionExcludeAndSignature == charZero
				)
			end
			print(
				'',
				collectionIncludeAndSignature == collectionInclude
					and (not collectionExclude or collectionExcludeAndSignature == charZero)
			)
		end

		if
			collectionIncludeAndSignature == collectionInclude
			and (not collectionExclude or collectionExcludeAndSignature == charZero)
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
			[charZero] = {},
		},

		built = nil :: <E, C, D, A..., R...>(archetype: Archetype<E, C, D, A..., R...>) -> ()?,
		spawned = nil :: (entity: any) -> ()?,
		killed = nil :: (entity: any) -> ()?,
		added = nil :: <E, C, D, A..., R...>(
			factory: Factory<E, C, D, A..., R...>,
			entity: E,
			component: C
		) -> ()?,
		removed = nil :: <E, C, D, A..., R...>(
			factory: Factory<E, C, D, A..., R...>,
			entity: E,
			component: C
		) -> ()?,
	} :: World

	Stew._nextWorldId, world._id = nextId(Stew._nextWorldId)

	if DEBUG then
		print('Stew.world', '= w' .. string.byte(world._id))
	end

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
			added = nil,
			removed = nil,
			data = factoryArgs.data :: D,
		} :: Factory<E, C, D, A..., R...>

		local archetype = {
			factory = factory,
			signature = splace(world._nextPlace),
			create = factoryArgs.add :: Add<E, C, D, A..., R...>,
			delete = factoryArgs.remove :: Remove<E, C, D, A..., R...>?,
		}

		if DEBUG then
			print('world.factory', 'w' .. string.byte(world._id), 'f' .. archetype.signature, factory.data)
		end

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
			if DEBUG then
				print(
					'factory.add',
					'w' .. string.byte(world._id),
					'f' .. archetype.signature,
					factory.data,
					if type(entity) == 'string' then 'e' .. ({ Stew.tonumber(entity) })[1] else entity,
					'args',
					...
				)
			end

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

			local signature = sor(entityData.signature, archetype.signature)
			entityData.signature = signature

			updateCollections(world, entity, entityData)

			if factory.added then
				factory.added(entity, component)
			end

			if world.added then
				world.added(factory, entity, component)
			end

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
		function factory.remove(entity: E, ...: R...)
			if DEBUG then
				print(
					'factory.remove',
					'w' .. string.byte(world._id),
					'f' .. archetype.signature,
					factory.data,
					if type(entity) == 'string' then 'e' .. ({ Stew.tonumber(entity) })[1] else entity,
					'args',
					...
				)
			end

			local entityData = world._entityToData[entity]
			if not entityData then
				return
			end

			local component = entityData.components[factory]
			if not component then
				return
			end

			if archetype.delete then
				archetype.delete(factory, entity, component, ...)
			end

			local signature = sxor(entityData.signature, archetype.signature)
			entityData.signature = signature
			entityData.components[factory] = nil

			updateCollections(world, entity, entityData)

			if factory.removed then
				factory.removed(entity, component)
			end

			if world.removed then
				world.removed(factory, entity, component)
			end

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
			if DEBUG then
				print(
					'factory.get',
					'w' .. string.byte(world._id),
					'f' .. archetype.signature,
					factory.data,
					if type(entity) == 'string' then 'e' .. ({ Stew.tonumber(entity) })[1] else entity
				)
			end
			return if entityData then entityData.components[factory] else nil
		end

		world._factoryToData[factory] = archetype
		world._nextPlace += 1

		if world.built then
			world.built(archetype :: any)
		end

		return factory :: any
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
		if DEBUG then
			print 'world.tag'
		end

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

		if DEBUG then
			local e, w = Stew.tonumber(world._id .. entity)
			print('world.entity', 'e' .. e, 'w' .. w)
		end

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
		if DEBUG then
			print(
				'world.entity',
				if type(entity) == 'string' then 'e' .. ({ Stew.tonumber(entity) })[1] else entity,
				'w' .. string.byte(world._id),
				'args',
				...
			)
		end

		local entityData = world._entityToData[entity]
		if not entityData then
			return
		end

		local factories = {}
		for factory in entityData.components do
			table.insert(factories, factory)
		end
		-- table.sort(factories, function(a, b)
		-- 	return world._factoryToData[a].signature > world._factoryToData[b].signature
		-- end)
		for _, factory in factories do
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
		if DEBUG then
			print(
				'world.entity',
				if type(entity) == 'string' then 'e' .. ({ Stew.tonumber(entity) })[1] else entity,
				'w' .. string.byte(world._id)
			)
		end

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
		if DEBUG then
			local includes = {}
			local excludes = {}

			for _, inc in include do
				table.insert(includes, 'f' .. world._factoryToData[inc].signature .. ' ' .. tostring(inc.data))
			end

			if exclude then
				for _, exc in exclude do
					table.insert(includes, tostring(exc.data) .. ' f' .. world._factoryToData[exc].signature)
				end
			end

			local t = 'world.query\n', '\tinclude ' .. table.concat(includes, ', ')
			if excludes and #excludes > 0 then
				t ..= '\n\texclude ' .. table.concat(excludes, ', ')
			end
			print(t)
		end

		local signatureInclude = charZero

		for _, factory in include do
			local data = world._factoryToData[factory]
			if not data then
				error('Passed a non-factory or a different world\'s factory into an include query!', 2)
			end

			signatureInclude = sor(signatureInclude, data.signature)
		end

		if exclude and #exclude > 0 then
			local signatureExclude = charZero

			for _, factory in exclude do
				local data = world._factoryToData[factory]
				if not data then
					error('Passed a non-factory or a different world\'s factory into an exclude query!', 2)
				end

				signatureExclude = sor(signatureExclude, data.signature)
			end

			signatureInclude ..= '!' .. signatureExclude
		end

		local collection = getCollection(world, signatureInclude)

		if DEBUG then
			local entities = {}
			for entity in collection do
				local e = if type(entity) == 'string' then 'e' .. ({ Stew.tonumber(entity) })[1] else tostring(entity)
				local s = 's' .. world._entityToData[entity].signature
				table.insert(entities, e .. ' ' .. s)
			end
			print('{\n\t' .. table.concat(entities, ',\n\t') .. '\n}')
		end

		return collection
	end

	return world
end

return Stew
