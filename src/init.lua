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
export type Add<N, E> = (factory: Factory<N, E>, entity: E, ...any) -> Component?
export type Remove<N, E> = (factory: Factory<N, E>, entity: E, component: Component, ...any) -> any?
export type ComponentData<N, E> = {
	create: Add<N, E>,
	delete: Remove<N, E>,
	signature: Signature,
	factory: Factory<N, E>,
}
export type Factory<N, E> = {
	name: N,
	add: (entity: E, ...any) -> Component?,
	remove: (entity: E, component: Component, ...any) -> any?,
	added: (entity: E, component: Component) -> (),
	removed: (entity: E, component: Component, deleted: any) -> (),
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

		built = nop :: (componentData: ComponentData<Name, Entity>) -> (),
		spawned = nop :: (entity: Entity) -> (),
		killed = nop :: (entity: Entity) -> (),
		added = nop :: (factory: Factory<Name, Entity>, entity: Entity, component: Component) -> (),
		removed = nop :: (factory: Factory<Name, Entity>, entity: Entity, component: Component, deleted: any) -> (),
	}

	function world.factory<N, E>(
		name: N,
		componentArgs: {
			add: Add<N, E>?,
			remove: Remove<N, E>?,
		}?
	)
		assert(not world._nameToData[name], 'Attempting to build component ' .. tostring(name) .. ' twice')

		local factory = {
			name = name,
			added = nop,
			removed = nop,
		} :: Factory<N, E>

		local componentData = {
			factory = factory,
			signature = splace(world._nextPlace),
			create = (componentArgs and componentArgs.add or create) :: Add<N, E>,
			delete = (componentArgs and componentArgs.remove or nop) :: Remove<N, E>,
		}

		function factory.add(entity: E, ...: any): Component?
			local entityData = world._entityToData[entity]
			if not entityData then
				register(world, entity)
				entityData = world._entityToData[entity]
			end

			if entityData.components[name] then
				return nil
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

	function world.query(factories: { Factory<Name, Entity> }): Collection
		local signature = charZero

		for _, factory in factories do
			assert(typeof(factory) == 'table' and factory.name, 'Invalid factory in query, did you accidentally use the component name instead?')
			local data = world._nameToData[factory.name]
			signature = sor(signature, data.signature)
		end

		return getCollection(world, signature)
	end

	return world
end

export type World = typeof(Stew.world(...))

local W = Stew.world()
local F = W.factory('Moving')

return Stew
