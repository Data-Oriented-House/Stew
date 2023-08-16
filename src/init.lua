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

local Stew = {}

export type Signature = string
export type Name = any
export type Component = any
export type Entity = any
export type Components = { [Name]: Component }
export type Collection = {
	[Entity]: Components,
}
export type EntityData = {
	signature: Signature,
	components: Components,
}
export type Add<N, E, C> = (factory: Factory<N, E, C>, entity: E, ...any) -> C
export type Remove<N, E, C> = (factory: Factory<N, E, C>, entity: E, component: C, ...any) -> any?
export type ComponentData<N, E, C> = {
	create: Add<N, E, C>,
	delete: Remove<N, E, C>,
	signature: Signature,
	factory: Factory<N, E, C>,
}
export type Factory<N, E, C> = {
	name: N,
	add: (entity: E, ...any) -> C?,
	remove: (entity: E, component: C, ...any) -> any?,
	added: (entity: E, component: C) -> (),
	removed: (entity: E, component: C, deleted: any) -> (),
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

local function create()
	return true
end

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

function Stew.world()
	local world = {
		_nextPlace = 1,
		_nameToData = {},
		_entityToData = {},
		_signatureToCollection = {
			[charZero] = {},
		},

		built = nop :: (componentData: ComponentData<Name, Entity, Component>) -> (),
		spawned = nop :: (entity: Entity) -> (),
		killed = nop :: (entity: Entity) -> (),
		added = nop :: (factory: Factory<Name, Entity, Component>, entity: Entity, component: Component) -> (),
		removed = nop :: (
			factory: Factory<Name, Entity, Component>,
			entity: Entity,
			component: Component,
			deleted: any
		) -> (),
	}

	function world.factory<N, E, C>(
		name: N,
		componentArgs: {
			add: Add<N, E, C>,
			remove: Remove<N, E, C>?,
		}
	)
		assert(not world._nameToData[name], 'Attempting to build component ' .. tostring(name) .. ' twice')

		local factory = {
			name = name,
			added = nop,
			removed = nop,
		} :: Factory<N, E, C>

		local componentData = {
			factory = factory,
			signature = splace(world._nextPlace),
			create = componentArgs.add,
			delete = componentArgs.remove or nop,
		}

		function factory.add(entity: E, ...: any): C?
			local entityData = world._entityToData[entity]
			if not entityData then
				register(world, entity)
				entityData = world._entityToData[entity]
			end

			if entityData.components[name] then
				return entityData.components[name]
			end

			local component = componentData.create(factory, entity, ...)
			if component == nil then
				return nil
			end

			entityData.components[name] = component

			local signature = sor(entityData.signature, componentData.signature)
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

		function factory.remove(entity: E, ...: any): any?
			local entityData = world._entityToData[entity]
			if not entityData then
				return
			end

			local component = entityData.components[name]
			if not component then
				return
			end

			local deleted = componentData.delete(factory, entity, component, ...)
			if deleted ~= nil then
				return deleted
			end

			entityData.components[name] = nil
			entityData.signature = sxor(entityData.signature, componentData.signature)

			for collectionSignature, collection in world._signatureToCollection do
				if
					not collection[entity]
					or sand(componentData.signature, collectionSignature) ~= componentData.signature
				then
					continue
				end
				collection[entity] = nil
			end

			factory.removed(entity, component, deleted)
			world.removed(factory, entity, component, deleted)

			return nil
		end

		world._nameToData[name :: Name] = componentData
		world._nextPlace += 1

		world.built(componentData)

		return factory
	end

	function world.tag<N>(name: N)
		return world.factory(name, {
			add = function(factory, entity: Entity)
				return true
			end,
			remove = function(factory, entity: Entity, component: boolean)
				return nil
			end,
		})
	end

	function world.entity(): Entity
		local entity = newproxy() :: Entity
		register(world, entity)
		return entity
	end

	function world.kill(entity: Entity, ...: any)
		local entityData = world._entityToData[entity]
		if not entityData then
			return
		end

		for name in entityData.components do
			local factory = world._nameToData[name].factory
			factory.remove(entity, ...)
		end

		getCollection(world, charZero)[entity] = nil
		world._entityToData[entity] = nil

		world.killed(entity)
	end

	function world.get(entity: Entity): Components
		local data = world._entityToData[entity]
		return if data then data.components else empty
	end

	function world.query(factories: { Factory<Name, Entity, Component> }): Collection
		local signature = charZero

		for _, factory in factories do
			assert(
				typeof(factory) == 'table' and factory.name,
				'Invalid factory in query, did you accidentally use the component name instead?'
			)
			local data = world._nameToData[factory.name]
			signature = sor(signature, data.signature)
		end

		return getCollection(world, signature)
	end

	return world
end

export type World = typeof(Stew.world(...))

return Stew
