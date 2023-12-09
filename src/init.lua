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
export type Component = any
export type Entity = any
export type Components<C> = { [Factory<Entity, C, ...any, ...any>]: C }
export type Collection = {
	[Entity]: Components<any>,
}
export type EntityData = {
	signature: Signature,
	components: Components<any>,
}
export type Add<E, C, A..., R...> = (factory: Factory<E, C, A..., R...>, entity: E, A...) -> C
export type Remove<E, C, A..., R...> = (factory: Factory<E, C, A..., R...>, entity: E, component: C, R...) -> ()
export type ComponentData<E, C, A..., R...> = {
	create: Add<E, C, A..., R...>,
	delete: Remove<E, C, A..., R...>,
	signature: Signature,
	factory: Factory<E, C, A..., R...>,
}
export type Factory<E, C, A..., R...> = {
	add: (entity: E, A...) -> C,
	remove: (entity: E, R...) -> (),
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

function Stew.world()
	local world = {
		_nextPlace = 1,
		_factoryToData = {},
		_entityToData = {},
		_signatureToCollection = {
			[charZero] = {},
		},

		built = nop :: (componentData: ComponentData<Entity, Component, ...any, ...any>) -> (),
		spawned = nop :: (entity: Entity) -> (),
		killed = nop :: (entity: Entity) -> (),
		added = nop :: (
			factory: Factory<Entity, Component, ...any, ...any>,
			entity: Entity,
			component: Component
		) -> (),
		removed = nop :: (
			factory: Factory<Entity, Component, ...any, ...any>,
			entity: Entity,
			component: Component,
			deleted: any
		) -> (),
	}

	function world.factory<E, C, A..., R...>(
		componentArgs: {
			add: Add<E, C, A..., R...>,
			remove: Remove<E, C, A..., R...>?,
		}
	)
		local factory = {
			added = nop,
			removed = nop,
		} :: Factory<E, C, A..., R...>

		local componentData = {
			factory = factory,
			signature = splace(world._nextPlace),
			create = componentArgs.add,
			delete = componentArgs.remove or nop :: Remove<E, C, A..., R...>,
		}

		function factory.add(entity: E, ...: A...): C
			local entityData = world._entityToData[entity]
			if not entityData then
				register(world, entity)
				entityData = world._entityToData[entity]
			end

			if entityData.components[factory] then
				return entityData.components[factory]
			end

			local component = componentData.create(factory, entity, ...)
			if component == nil then
				return (nil :: any) :: C
			end

			entityData.components[factory] = component

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

		function factory.remove(entity: E, ...: R...): any?
			local entityData = world._entityToData[entity]
			if not entityData then
				return
			end

			local component = entityData.components[factory]
			if not component then
				return
			end

			componentData.delete(factory, entity, component, ...)

			entityData.components[factory] = nil
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

			factory.removed(entity, component)
			world.removed(factory, entity, component)

			return nil
		end

		world._factoryToData[factory] = componentData
		world._nextPlace += 1

		world.built(componentData)

		return factory
	end

	function world.tag()
		return world.factory(tag)
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

		for factory in entityData.components do
			factory.remove(entity, ...)
		end

		getCollection(world, charZero)[entity] = nil
		world._entityToData[entity] = nil

		world.killed(entity)
	end

	function world.get(entity: Entity): Components<any>
		local data = world._entityToData[entity]
		return if data then data.components else empty
	end

	function world.query(factories: { Factory<Entity, Component, ...any, ...any> }): Collection
		local signature = charZero

		for _, factory in factories do
			local data = world._factoryToData[factory]
			signature = sor(signature, data.signature)
		end

		return getCollection(world, signature)
	end

	return world
end

export type World = typeof(Stew.world(...))

return Stew
