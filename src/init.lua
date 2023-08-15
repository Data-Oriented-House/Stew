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
export type Add = (factory: Factory, entity: Entity, ...any) -> Component?
export type Remove = (factory: Factory, entity: Entity, component: Component, ...any) -> any?
export type ComponentData = {
	create: Add,
	delete: Remove,
	signature: Signature,
	factory: Factory,
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

local function create()
	return true
end

local function delete()
	return
end

local function built(name: any, componentData: ComponentData) end
local function spawned(entity: any) end
local function killed(entity: any) end
local function worldadded(factory: any, entity: any, component: any) end
local function worldremoved(factory: any, entity: any, component: any, deleted: any) end
local function factoryadded(entity: any, component: any) end
local function factoryremoved(entity: any, component: any, deleted: any) end

local function register(world: World, entity: Entity)
	assert(not world._entityToData[entity], 'Attempting to register entity twice')

	local entityData = {
		signature = charZero,
		components = {},
	}

	world._entityToData[entity] = entityData

	getCollection(world, charZero)[entity] = entityData.components

	if world.spawned then
		world.spawned(entity)
	end
end

function Stew.world()
	local world = {
		_nextPlace = 1,
		_nameToData = {},
		_entityToData = {},
		_signatureToCollection = {
			[charZero] = {},
		},

		built = built,
		spawned = spawned,
		killed = killed,
		added = worldadded,
		removed = worldremoved,
	}

	function world.factory(
		name: Name,
		componentArgs: {
			add: Add?,
			remove: Remove?,
		}?
	)
		assert(not world._nameToData[name], 'Attempting to build component ' .. tostring(name) .. ' twice')

		local factory = {
			name = name,
			added = factoryadded,
			removed = factoryremoved,
		}

		local componentData = {
			factory = factory,
			signature = splace(world._nextPlace),
			create = (componentArgs and componentArgs.add or create) :: Add,
			delete = (componentArgs and componentArgs.remove or delete) :: Remove,
		}

		function factory.add(entity: Entity, ...: any): Component?
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

			if factory.added then
				factory.added(entity, component)
			end

			if world.added then
				world.added(factory, entity, component)
			end

			return component
		end

		function factory.remove(entity: Entity, ...: any): any?
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

			if factory.removed then
				factory.removed(entity, component, deleted)
			end

			if world.removed then
				world.removed(factory, entity, component, deleted)
			end

			return nil
		end

		world._nameToData[name] = componentData
		world._nextPlace += 1

		if world.built then
			world.built(name, componentData)
		end

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

		if world.killed then
			world.killed(entity)
		end
	end

	function world.get(entity: Entity): Components
		local data = world._entityToData[entity]
		return if data then data.components else empty
	end

	function world.query(factories: { Factory }): Collection
		local signature = charZero

		for _, factory in factories do
			local data = world._nameToData[factory.name]
			signature = sor(signature, data.signature)
		end

		return getCollection(world, signature)
	end

	return world
end

export type World = typeof(Stew.world(...))
export type Factory = typeof(Stew.world(...).factory(...))

return Stew
