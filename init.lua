--!strict

local function StringBAnd(String1 : string, String2 : string): string
	local Length = math.max(#String1, #String2)
	local String3 = table.create(Length, 0)

	for i in ipairs(String3) do
		String3[i] = (string.byte(String1, i) == 49 and string.byte(String2, i) == 49) and 1 or 0
	end

	for i = Length, 1, -1 do
		if String3[i] ~= 0 then break end
		String3[i] = nil
	end

	return #String3 == 0 and "0" or table.concat(String3, '')
end

local function StringBOr(String1 : string, String2 : string): string
	local Length = math.max(#String1, #String2)
	local String3 = table.create(Length, 0)

	for i in ipairs(String3) do
		String3[i] = (string.byte(String1, i) == 49 or string.byte(String2, i) == 49) and 1 or 0
	end

	for i = Length, 1, -1 do
		if String3[i] ~= 0 then break end
		String3[i] = nil
	end

	return #String3 == 0 and "0" or table.concat(String3, '')
end

local function StringBXOr(String1 : string, String2 : string): string
	local Length = math.max(#String1, #String2)
	local String3 = table.create(Length, 0)

	for i in ipairs(String3) do
		String3[i] = string.byte(String1, i) == string.byte(String2, i) and 0 or 1
	end

	for i = #String3, 1, -1 do
		if String3[i] ~= 0 then break end
		String3[i] = nil
	end

	return #String3 == 0 and "0" or table.concat(String3, '')
end

local function StringPlace(Place : number): string
	local String = table.create(Place, 0)

	String[Place] = 1

	return #String == 0 and "0" or table.concat(String, '')
end

type Signature = string

export type Name = any
export type Component = any
export type Entity<E> = E

export type Collection = { [Entity<any>] : true }

export type Template<E, N, C> = {
	Constructor : ((Entity : Entity<E>, Name: N, ...any) -> C)?;
	constructor : ((Entity : Entity<E>, Name: N, ...any) -> C)?;

	Destructor : ((Entity : Entity<E>, Name : N, ...any) -> ())?;
	destructor : ((Entity : Entity<E>, Name : N, ...any) -> ())?;
}

type Data<E, N, C> = {
	Signature : Signature;
	Constructor : (Entity : Entity<E>, Name: N, ...any) -> C;
	Destructor : (Entity : Entity<E>, Name : N, ...any) -> ();
}

type Archetype = {
	Signature : Signature;
	Collection : Collection;
}

local Module = {}

Module._NextPlace = 1
Module._UniversalSignature = "0"

Module._SignatureToArchetype = {} :: { [Signature] : Archetype }
Module._NameToData = {} :: { [Name] : Data<any, Name, Component> }
Module._EntityToData = {} :: {
	[Entity<any>] : {
		Signature : Signature;
		Components : { [Name] : Component };
	}
}

local function GetArchetype(Signature : Signature): Archetype
	local FoundArchetype = Module._SignatureToArchetype[Signature]
	if FoundArchetype then return FoundArchetype end

	local Archetype: Archetype = {
		Signature = Signature;
		Collection = {} :: Collection;
	}
	Module._SignatureToArchetype[Signature] = Archetype

	local UniversalArchetype = Module._SignatureToArchetype[Module._UniversalSignature]
	for Entity in UniversalArchetype.Collection do
		local EntityData = Module._EntityToData[Entity]
		if StringBAnd(Archetype.Signature, EntityData.Signature) == Archetype.Signature then
			Archetype.Collection[Entity] = true
		end
	end

	return Archetype
end

--Initialize the Universal collection
GetArchetype(Module._UniversalSignature)

local function DefaultConstructor() : true
	return true
end

local function DefaultDestructor()
end

-- The Collection namespace, has methods for dealing with collections
Module.Collection = {}

-- Gets the collection of entities that have all of the specified components
function Module.Collection.Get(Names : { any }) : Collection
	local Signature = Module._UniversalSignature

	for _, Name in Names do
		local Data = Module._NameToData[Name]
		assert(Data, "Attempting to get collection of non-existant " .. tostring(Name) .. " component")

		Signature = StringBOr(Signature, Data.Signature)
	end

	return GetArchetype(Signature).Collection
end

-- Gets the first entity in a collection of entities that have all of the specified components. Order is not guaranteed.
function Module.Collection.GetFirst(Names : { any }) : Entity<any>?
	return next(Module.Collection.Get(Names))
end

-- The Component namespace, has methods for dealing with components
Module.Component = {}

-- Builds a component, this must be called before any components of this type can be created
function Module.Component.Build<E, N, C>(Name : N, Template : Template<E, N, C>?)
	assert(not Module._NameToData[Name], "Attempting to build component " .. tostring(Name) .. " twice")

	local Template = Template or {} :: Template<E, N, C>

	Module._NameToData[Name] = {
		Signature = StringPlace(Module._NextPlace);

		Constructor = Template.Constructor or Template.constructor or DefaultConstructor;
		Destructor = Template.Destructor or Template.destructor or DefaultDestructor;
	}

	Module._NextPlace += 1
end

-- Creates a component, associates it with the entity, and returns it
function Module.Component.Create<E, N>(Entity : Entity<E>, Name : N, ... : any): Component?
	local ComponentData = Module._NameToData[Name]
	assert(ComponentData, "Attempting to create instance of non-existant " .. tostring(Name) .. " component")

	local EntityData = Module._EntityToData[Entity]
	if not EntityData then
		Module.Entity.Create(Entity)
		EntityData = Module._EntityToData[Entity]
	end

	if EntityData.Components[Name] then return end
	local Component = ComponentData.Constructor(Entity, Name, ...)
	if Component == nil then return end
	EntityData.Components[Name] = Component

	local Signature = StringBOr(EntityData.Signature, ComponentData.Signature)
	EntityData.Signature = Signature

	for ArchetypeSignature, Archetype in Module._SignatureToArchetype do
		if
			not Archetype.Collection[Entity] and
			StringBAnd(ArchetypeSignature, Signature) == ArchetypeSignature
		then
			Archetype.Collection[Entity] = true
		end
	end

	return EntityData.Components[Name]
end

-- Deletes and disassociates a component from the entity
function Module.Component.Delete<E, N>(Entity : Entity<E>, Name : N, ... : any)
	local ComponentData = Module._NameToData[Name]
	assert(ComponentData, "Attempting to delete instance of non-existant " .. tostring(Name) .. " component")

	local EntityData = Module._EntityToData[Entity]
	if not EntityData then return end
	if not EntityData.Components[Name] then return end

	if ComponentData.Destructor(Entity, Name, ...) ~= nil then return end
	EntityData.Components[Name] = nil
	EntityData.Signature = StringBXOr(EntityData.Signature, ComponentData.Signature)

	for ArchetypeSignature, Archetype in Module._SignatureToArchetype do
		if
			Archetype.Collection[Entity] and
			StringBAnd(ComponentData.Signature, ArchetypeSignature) == ComponentData.Signature
		then
			Archetype.Collection[Entity] = nil
		end
	end
end

local Default = {
	Components = {},
}

-- Gets a component from an entity
function Module.Component.Get<E, N>(Entity : Entity<E>, Name : N): Component?
	local EntityData = (Module._EntityToData[Entity] or Default) :: typeof(Default)
	return EntityData.Components[Name]
end

-- Gets all components from an entity
function Module.Component.GetAll<E>(Entity : Entity<E>): { [Name] : Component }
	local EntityData = Module._EntityToData[Entity] or Default
	return EntityData.Components
end

-- The Entity namespace, has methods for dealing with entities
Module.Entity = {}

-- Creates an entity from an existing thing or creates a new one if none is provided
function Module.Entity.Create<E>(Any: E?) : Entity<E>
	local Entity: Entity<E> = if Any ~= nil then Any else newproxy()
	Module._EntityToData[Entity] = {
		Signature = Module._UniversalSignature;
		Components = {};
	}

	local UniversalArchetype = GetArchetype(Module._UniversalSignature)
	UniversalArchetype.Collection[Entity] = true

	return Entity
end

-- Deletes an entity internally and all of its components
function Module.Entity.Delete<E>(Entity : Entity<E>)
	local EntityData = Module._EntityToData[Entity]
	if not EntityData then return end

	for Name in EntityData.Components do
		Module.Component.Delete(Entity, Name)
	end

	local UniversalArchetype = GetArchetype(Module._UniversalSignature)
	UniversalArchetype.Collection[Entity] = nil
end

return Module