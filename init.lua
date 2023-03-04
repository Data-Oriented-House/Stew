--!strict

local String = {}

function String.BAnd(String1 : string, String2 : string): string
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

function String.BOr(String1 : string, String2 : string): string
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

function String.BXOr(String1 : string, String2 : string): string
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

function String.Place(Place : number): string
	local String = table.create(Place, 0)

	String[Place] = 1

	return #String == 0 and "0" or table.concat(String, '')
end

export type Signature = string
export type Name = any
export type Component = any
export type Entity<E> = E

export type Collection = {
	[Entity<any>] : true;
}

export type EntityData = {
	Signature  : Signature;
	Components : { [Name] : Component };
}

export type ComponentArgs<E, N, C, D> = {
	Constructor : (<T...>(Entity : Entity<E>, Name : N, T...) -> C)?;
	Destructor  : (<T...>(Entity : Entity<E>, Name : N, T...) -> D)?;
}

export type ComponentData<E, N, C, D> = {
	Constructor : <T...>(Entity : Entity<E>, Name : N, T...) -> C;
	Destructor  : <T...>(Entity : Entity<E>, Name : N, T...) -> D;
	Signature   : Signature;
}

export type WorldArgs = {
	On : {
		Component : {
			Build  : (<E, N, C, D>(Name : N, ComponentData : ComponentData<E, N, C, D>) -> ())?;
			Create : (<E, N, C>(Entity : Entity<any>, Name : N, Component: C) -> ())?;
			Delete : (<E, N, D>(Entity : Entity<E>, Name : N, Deleted: D) -> ())?;
		}?;

		Entity : {
			Create : (<E>(Entity: Entity<E>) -> ())?;
			Delete : (<E>(Entity: Entity<E>) -> ())?;
		}?;
	}?;
}

type WorldCollection = {
	Get      : (Names : { Name }) -> Collection;
	GetFirst : (Names : { Name }) -> Entity<any>;
}

type WorldComponent = {
	Build  : <E, N, C, D>(Name : N, ComponentArgs : ComponentArgs<E, N, C, D>?) -> ();
	Create : <E, N, C, T...>(Entity : Entity<E>, Name : N, T...) -> C?;
	Delete : <E, N, D, T...>(Entity : Entity<E>, Name : N, T...) -> D?;
	GetAll : <E>(Entity : Entity<E>) -> { [Name] : Component };
	Get    : <E, N, C>(Entity : Entity<E>, Name : N) -> C?;
}

type WorldEntity = {
	Create   : () -> Entity<any>;
	Delete   : <E>(Entity : Entity<E>) -> ();
	Register : <E>(Entity : Entity<E>) -> ();
}

export type World = {
	_NextPlace : number;

	_NameToData            : { [Name] : ComponentData<any, Name, Component, any> };
	_EntityToData          : { [Entity<any>] : EntityData };
	_SignatureToCollection : { [Signature] : Collection };

	_On : {
		Component : {
			Build  : <E, N, C, D>(Name : N, ComponentData : ComponentData<E, N, C, D>) -> ();
			Create : <E, N, C>(Entity : Entity<any>, Name : N, Component: C) -> ();
			Delete : <E, N, D>(Entity : Entity<E>, Name : N, Deleted: D) -> ();
		};

		Entity : {
			Create : <E>(Entity: Entity<E>) -> ();
			Delete : <E>(Entity: Entity<E>) -> ();
		};
	};

	Collection : WorldCollection;
	Component : WorldComponent;
	Entity : WorldEntity;
}

local Module = {}

local function GetCollection(World: World, Signature : Signature): Collection
	local FoundCollection = World._SignatureToCollection[Signature]
	if FoundCollection then return FoundCollection end

	local Collection = {} :: Collection
	World._SignatureToCollection[Signature] = Collection

	local UniversalCollection = World._SignatureToCollection["0"]
	for Entity in UniversalCollection do
		local EntityData = World._EntityToData[Entity]
		if String.BAnd(Signature, EntityData.Signature) == Signature then
			Collection[Entity] = true
		end
	end

	return Collection
end

local function DefaultConstructor() : true
	return true
end

local function DefaultDestructor()
end

local function DefaultOn()
end

-- The World namespace, has methods for dealing with worlds
Module.World = {}

-- Creates a new world, and for convenience, creates all methods that pass a world as the first argument, too
function Module.World.Create(WorldArgs: WorldArgs?) : World
	local WorldComponent = if WorldArgs and WorldArgs.On then WorldArgs.On.Component else nil
	local WorldEntity = if WorldArgs and WorldArgs.On then WorldArgs.On.Entity else nil

	local World = {
		_NextPlace = 1;
		_NameToData = {};
		_EntityToData = {};

		_SignatureToCollection = {
			["0"] = {};
		};

		_On = {
			Component = {
				Build  = if WorldComponent then WorldComponent.Build  else DefaultOn;
				Create = if WorldComponent then WorldComponent.Create else DefaultOn;
				Delete = if WorldComponent then WorldComponent.Delete else DefaultOn;
			};

			Entity = {
				Create = if WorldEntity then WorldEntity.Create else DefaultOn;
				Delete = if WorldEntity then WorldEntity.Delete else DefaultOn;
			};
		};
	} :: World

	-- The Collection namespace, has methods for dealing with collections
	World.Collection = {} :: WorldCollection

	-- Gets the collection of entities that have all of the specified components
	function World.Collection.Get(Names : { Name }) : Collection
		local Signature = "0"

		for _, Name in Names do
			local Data = World._NameToData[Name]
			assert(Data, "Attempting to get collection of non-existant " .. tostring(Name) .. " component")

			Signature = String.BOr(Signature, Data.Signature)
		end

		return GetCollection(World, Signature)
	end

	-- Gets the first entity in a collection of entities that have all of the specified components. Order is not guaranteed.
	function World.Collection.GetFirst(Names : { Name }) : Entity<any>?
		return next(World.Collection.Get(Names))
	end

	-- The Component namespace, has methods for dealing with components
	World.Component = {} :: WorldComponent

	-- Builds a component, this must be called before any components of this type can be created
	function World.Component.Build<E, N, C, D>(Name : N, ComponentArgs : ComponentArgs<E, N, C, D>?)
		assert(not World._NameToData[Name], "Attempting to build component " .. tostring(Name) .. " twice")

		local ComponentArgs = (ComponentArgs or {}) :: ComponentArgs<E, N, C, D>

		local ComponentData = {
			Signature = String.Place(World._NextPlace);
			Constructor = ComponentArgs.Constructor or DefaultConstructor;
			Destructor = ComponentArgs.Destructor or DefaultDestructor;
		} :: ComponentData<E, N, C, D>

		World._NameToData[Name] = ComponentData
		World._NextPlace += 1

		World._On.Component.Build(Name, ComponentData)
	end

	-- Creates a component, associates it with the entity, and returns it. Automatically registers the entity if it hasn't been registered yet
	function World.Component.Create<E, N, C, T...>(Entity : Entity<E>, Name : N, ...: T...): C?
		local ComponentData = World._NameToData[Name]
		assert(ComponentData, "Attempting to create instance of non-existant " .. tostring(Name) .. " component")

		local EntityData = World._EntityToData[Entity]
		if not EntityData then
			World.Entity.Register(Entity)
			EntityData = World._EntityToData[Entity]
		end

		if EntityData.Components[Name] then return nil end
		local Component = ComponentData.Constructor(Entity, Name, ...)
		if Component == nil then return Component end

		EntityData.Components[Name] = Component
		World._On.Component.Create(Entity, Name, Component)

		local Signature = String.BOr(EntityData.Signature, ComponentData.Signature)
		EntityData.Signature = Signature

		for CollectionSignature, Collection in World._SignatureToCollection do
			if Collection[Entity] or String.BAnd(CollectionSignature, Signature) ~= CollectionSignature then continue end
			Collection[Entity] = true
		end

		return Component
	end

	-- Deletes and disassociates a component from the entity, returns whatever the destructor returns
	function World.Component.Delete<E, N, D, T...>(Entity : Entity<E>, Name : N, ... : T...): D?
		local ComponentData = World._NameToData[Name]
		assert(ComponentData, "Attempting to delete instance of non-existant " .. tostring(Name) .. " component")

		local EntityData = World._EntityToData[Entity]
		if not EntityData then return end
		if not EntityData.Components[Name] then return end

		local Deleted = ComponentData.Destructor(Entity, Name, ...)
		if Deleted ~= nil then return Deleted end

		World._On.Component.Delete(Entity, Name, EntityData.Components[Name])
		EntityData.Components[Name] = nil
		EntityData.Signature = String.BXOr(EntityData.Signature, ComponentData.Signature)

		for CollectionSignature, Collection in World._SignatureToCollection do
			if not Collection[Entity] or String.BAnd(ComponentData.Signature, CollectionSignature) ~= ComponentData.Signature then continue end
			Collection[Entity] = nil
		end

		return nil
	end

	-- Gets a component from an entity
	function World.Component.Get<E, N, C>(Entity : Entity<E>, Name : N): C?
		local EntityData = (World._EntityToData[Entity] or { Components = {} }) :: typeof({ Components = {} })
		return EntityData.Components[Name]
	end

	-- Gets all components from an entity, clones the table to prevent tampering
	function World.Component.GetAll<E>(Entity : Entity<E>): { [Name] : Component }
		local EntityData = World._EntityToData[Entity] or { Components = {} }
		return table.clone(EntityData.Components)
	end

	-- The Entity namespace, has methods for dealing with entities
	World.Entity = {} :: WorldEntity

	-- Registers an entity internally
	function World.Entity.Register<E>(Entity: Entity<E>)
		assert(not World._EntityToData[Entity], "Attempting to register entity twice")

		World._EntityToData[Entity] = {
			Signature = "0";
			Components = {};
		}

		GetCollection(World, "0")[Entity] = true

		World._On.Entity.Create(Entity)
	end

	-- Creates a generic entity, registers it, and returns it
	function World.Entity.Create() : Entity<any>
		local Entity = newproxy() :: Entity<any>
		World.Entity.Register(Entity)
		return Entity
	end

	-- Deletes an entity and all its components, internally
	function World.Entity.Delete<E>(Entity : Entity<E>)
		local EntityData = World._EntityToData[Entity]
		if not EntityData then return end

		World._On.Entity.Delete(Entity)

		for Name in EntityData.Components do
			World.Component.Delete(Entity, Name)
		end

		GetCollection(World, "0")[Entity] = nil
	end

	return World
end

return Module