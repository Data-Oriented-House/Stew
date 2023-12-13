--!strict

local charEmpty = ''
local charZero = '0'
local asciiOne = string.byte '1'
local empty = table.freeze {}

local function sand(string1: string, string2: string): string
	local length = math.max(#string1, #string2)
	local string3 = table.create(length, 0)

	for i in string3 do
		string3[i] = (string.byte(string1, i) == asciiOne and string.byte(string2, i) == asciiOne) and 1 or 0
	end

	for i = length, 1, -1 do
		if string3[i] ~= 0 then
			break
		end
		string3[i] = nil
	end

	return #string3 == 0 and charZero or table.concat(string3, charEmpty)
end

local function sor(string1: string, string2: string): string
	local length = math.max(#string1, #string2)
	local string3 = table.create(length, 0)

	for i in string3 do
		string3[i] = (string.byte(string1, i) == asciiOne or string.byte(string2, i) == asciiOne) and 1 or 0
	end

	for i = length, 1, -1 do
		if string3[i] ~= 0 then
			break
		end
		string3[i] = nil
	end

	return #string3 == 0 and charZero or table.concat(string3, charEmpty)
end

local function sxor(string1: string, string2: string): string
	local length = math.max(#string1, #string2)
	local string3 = table.create(length, 0)

	for i in string3 do
		string3[i] = string.byte(string1, i) == string.byte(string2, i) and 0 or 1
	end

	for i = #string3, 1, -1 do
		if string3[i] ~= 0 then
			break
		end
		string3[i] = nil
	end

	return #string3 == 0 and charZero or table.concat(string3, charEmpty)
end

local function splace(place: number): string
	local String = table.create(place, 0)

	String[place] = 1

	return #String == 0 and charZero or table.concat(String, charEmpty)
end

--[=[
	@class Stew
]=]
local Stew = {}

export type Signature = string
export type Component = any
export type Entity = any
export type Components = { [Factory<Entity, any, any, ...any, ...any>]: any }
export type Collection = {
	[Entity]: Components,
}
export type EntityData = {
	signature: Signature,
	components: Components,
}
export type Add<E, C, D, A..., R...> = (factory: Factory<E, C, D, A..., R...>, entity: E, A...) -> C
export type Remove<E, C, D, A..., R...> = (factory: Factory<E, C, D, A..., R...>, entity: E, component: C, R...) -> ()
export type Archetype<E, C, D, A..., R...> = {
	create: Add<E, C, D, A..., R...>,
	delete: Remove<E, C, D, A..., R...>,
	signature: Signature,
	factory: Factory<E, C, D, A..., R...>,
}
export type Factory<E, C, D, A..., R...> = {
	add: (entity: E, A...) -> C,
	remove: (entity: E, R...) -> (),
	get: (entity: E) -> C?,
	data: D,
	added: (entity: E, component: C) -> (),
	removed: (entity: E, component: C) -> (),
}

local function getCollection(world: World, signature: Signature): Collection
	local found = world._signatureToCollection[signature]
	if found then
		return found
	end

	local collection = {} :: Collection
	world._signatureToCollection[signature] = collection

	local universal = world._signatureToCollection[charZero]
	for entity in universal do
		local data = world._entityToData[entity]
		if sand(signature, data.signature) == signature then
			collection[entity] = data.components
		end
	end

	return collection
end

local function nop()
	return
end

local tag = {
	add = function(factory, entity: Entity)
		return true
	end,

	remove = nop,

	data = nil,
}

local function register<E>(world: World, entity: E)
	assert(not world._entityToData[entity], 'Attempting to register entity twice')

	local entityData = {
		signature = charZero,
		components = {},
	}

	world._entityToData[entity] = entityData

	getCollection(world, charZero)[entity] = entityData.components

	world.spawned(entity)
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
		_factoryToData = {},
		_entityToData = {},
		_signatureToCollection = {
			[charZero] = {},
		},

		built = nop :: (archetype: Archetype<Entity, Component, any, ...any, ...any>) -> (),
		spawned = nop :: (entity: Entity) -> (),
		killed = nop :: (entity: Entity) -> (),
		added = nop :: (
			factory: Factory<Entity, Component, any, ...any, ...any>,
			entity: Entity,
			component: Component
		) -> (),
		removed = nop :: (
			factory: Factory<Entity, Component, any, ...any, ...any>,
			entity: Entity,
			component: Component
		) -> (),
	}

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
			signature = splace(world._nextPlace),
			create = factoryArgs.add,
			delete = (factoryArgs.remove or nop) :: Remove<E, C, D, A..., R...>,
		}

		--[=[
			@within Factory
			@param entity any
			@param ... any
			@return Component

			Adds the factory's type of component to the entity. If the component already exists, it just returns the old component and does not perform any further changes.

			Anything can be an Entity, if an unregistered object is given a component it is registered as an entity.

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

			local signature = sor(entityData.signature, archetype.signature)
			entityData.signature = signature

			for collectionSignature, collection in world._signatureToCollection do
				if collection[entity] or sand(collectionSignature, signature) ~= collectionSignature then
					continue
				end
				collection[entity] = entityData.components
			end

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

			entityData.components[factory] = nil
			entityData.signature = sxor(entityData.signature, archetype.signature)

			for collectionSignature, collection in world._signatureToCollection do
				if not collection[entity] or sand(archetype.signature, collectionSignature) ~= archetype.signature then
					continue
				end
				collection[entity] = nil
			end

			factory.removed(entity, component)
			world.removed(factory, entity, component)

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

		world.built(archetype)

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

		Cannot be sent over remotes. (If this is a feature you believe would be beneficial, make an issue in the repository for it!)

		Fires the world `spawned` callback.

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
	function world.entity(): Entity
		local entity = newproxy() :: Entity
		register(world, entity)
		return entity
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
	function world.kill(entity: Entity, ...: any)
		local entityData = world._entityToData[entity]
		if not entityData then
			return
		end

		for factory in entityData.components do
			factory.remove(entity, ...)
		end

		getCollection(world, charZero)[entity] = nil
		world._entityToData[entity] = nil

		world.killed(entity)
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
	function world.get(entity: Entity): Components
		local data = world._entityToData[entity]
		return if data then data.components else empty
	end

	--[=[
		@within World
		@tag Do Not Modify
		@param factories { Factory }
		@return { [Entity]: Components }

		Gets a set of all entities that have at least the queried components. (This is the magic sauce of it all!)

		This is a reference to the internal representation, so mutating this table directly will cause Stew to be out-of-sync.

		```lua
		local World = require(path.to.world)
		local Poisoned = require(path.to.poisoned.factory)
		local Health = require(path.to.health.factory)
		local Color = require(path.to.color.factory)

		local poisonedHealths = world.query { Poisoned, Health }

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
	function world.query(factories: { Factory<Entity, Component, any, ...any, ...any> }): Collection
		local signature = charZero

		for _, factory in factories do
			local data = world._factoryToData[factory]
			if not data then
				error('Passed a non-factory or a different world\'s factory into a query!', 2)
			end

			signature = sor(signature, data.signature)
		end

		return getCollection(world, signature)
	end

	return world
end

export type World = typeof(Stew.world(...))

return Stew
