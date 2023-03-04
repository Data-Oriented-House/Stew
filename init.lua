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

export type ComponentArgs<E, N, C> = {
	Constructor : ((Entity : Entity<E>, Name : N, ...any) -> C)?;
	Destructor  : ((Entity : Entity<E>, Name : N, ...any) -> ())?;
}

export type WorldArgs = {
	OnComponentBuild  : ((Name: Name, ComponentArgs: ComponentArgs<any, any, any>) -> ())?;
	OnComponentCreate : ((Entity: Entity<any>, Name: Name, ...any) -> ())?;
	OnComponentDelete : ((Entity: Entity<any>, Name: Name, ...any) -> ())?;

	OnEntityCreate : ((Entity: Entity<any>) -> ())?;
	OnEntityDelete : ((Entity: Entity<any>) -> ())?;
}

export type ComponentData<E, N, C> = {
	Constructor : (Entity : Entity<E>, Name: N, ...any) -> C;
	Destructor  : (Entity : Entity<E>, Name : N, ...any) -> ();
	Signature   : Signature;
}

export type EntityData = {
	Signature  : Signature;
	Components : { [Name] : Component };
}

export type Archetype = {
	Signature  : Signature;
	Collection : Collection;
}
export type World = {
	_NextPlace : number;

	_NameToData           : { [Name] : ComponentData<any, Name, Component> };
	_EntityToData         : { [Entity<any>] : EntityData };
	_SignatureToArchetype : { [Signature] : Archetype };

	_On : {
		Component : {
			Build  : <E, N, C>(Name : N, ComponentData : ComponentData<E, N, C>) -> ();
			Create : <E, N, C>(Entity : Entity<any>, Name : N, Component: C) -> ();
			Delete : <E, N, D>(Entity : Entity<E>, Name : N, Deleted: D?) -> ();
		};

		Entity : {
			Create : <E>(Entity: Entity<E>) -> ();
			Delete : <E>(Entity: Entity<E>) -> ();
		};
	};

	Collection : {
		Get      : (Names : { Name }) -> Collection;
		GetFirst : (Names : { Name }) -> Entity<any>;
	};

	Component : {
		Build  : <E, N, C>(Name : N, ComponentArgs : ComponentArgs<E, N, C>) -> ();
		Create : <E, N, C>(Entity : Entity<E>, Name : N, ...any) -> C;
		Delete : <E, N, D>(Entity : Entity<E>, Name : N) -> D?;
		Get    : <E, N, C>(Entity : Entity<E>, Name : N) -> C;
		GetAll : <E, N, C>(Entity : Entity<E>) -> { [N] : C };
	};

	Entity : {
		Create : () -> Entity<any>;
		Delete : <E>(Entity: Entity<E>) -> ();
	};
}

local Module = {}

local function GetArchetype(World: World, Signature : Signature): Archetype
	local FoundArchetype = World._SignatureToArchetype[Signature]
	if FoundArchetype then return FoundArchetype end

	local Archetype: Archetype = {
		Signature = Signature;
		Collection = {} :: Collection;
	}
	World._SignatureToArchetype[Signature] = Archetype

	local UniversalArchetype = World._SignatureToArchetype["0"]
	for Entity in UniversalArchetype.Collection do
		local EntityData = World._EntityToData[Entity]
		if String.BAnd(Archetype.Signature, EntityData.Signature) == Archetype.Signature then
			Archetype.Collection[Entity] = true
		end
	end

	return Archetype
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
	WorldArgs = (WorldArgs or {}) :: WorldArgs

	local World = {
		_NextPlace = 1;
		_NameToData = {};
		_EntityToData = {};

		_SignatureToArchetype = {
			["0"] = {
				Signature = "0";
				Collection = {} :: Collection;
			};
		};

		_On = {
			Component = {
				Build  = WorldArgs.OnComponentBuild or DefaultOn;
				Create = WorldArgs.OnComponentCreate or DefaultOn;
				Delete = WorldArgs.OnComponentDelete or DefaultOn;
			};

			Entity = {
				Create = WorldArgs.OnEntityCreate or DefaultOn;
				Delete = WorldArgs.OnEntityDelete or DefaultOn;
			};
		};
	} :: World

	-- The Collection namespace, has methods for dealing with collections
	World.Collection = {}

	-- Gets the collection of entities that have all of the specified components
	function World.Collection.Get(Names : { any }) : Collection
		local Signature = "0"

		for _, Name in Names do
			local Data = World._NameToData[Name]
			assert(Data, "Attempting to get collection of non-existant " .. tostring(Name) .. " component")

			Signature = String.BOr(Signature, Data.Signature)
		end

		return GetArchetype(World, Signature).Collection
	end

	-- Gets the first entity in a collection of entities that have all of the specified components. Order is not guaranteed.
	function World.Collection.GetFirst(Names : { any }) : Entity<any>?
		return next(World.Collection.Get(Names))
	end

	-- The Component namespace, has methods for dealing with components
	World.Component = {}

	-- Builds a component, this must be called before any components of this type can be created
	function World.Component.Build<E, N, C>(Name : N, ComponentArgs : ComponentArgs<E, N, C>?)
		assert(not World._NameToData[Name], "Attempting to build component " .. tostring(Name) .. " twice")

		ComponentArgs = (ComponentArgs or {}) :: ComponentArgs<E, N, C>

		local ComponentData = {
			Signature = String.Place(World._NextPlace);
			Constructor = ComponentArgs.Constructor or DefaultConstructor;
			Destructor = ComponentArgs.Destructor or DefaultDestructor;
		}

		World._NameToData[Name] = ComponentData
		World._NextPlace += 1

		World._On.Component.Build(Name, ComponentData)
	end

	-- Creates a component, associates it with the entity, and returns it. Automatically registers the entity if it hasn't been registered yet
	function World.Component.Create<E, N>(Entity : Entity<E>, Name : N, ... : any): Component?
		local ComponentData = World._NameToData[Name]
		assert(ComponentData, "Attempting to create instance of non-existant " .. tostring(Name) .. " component")

		local EntityData = World._EntityToData[Entity]
		if not EntityData then
			World.Entity.Register(Entity)
			EntityData = World._EntityToData[Entity]
		end

		if EntityData.Components[Name] then return end
		local Component = ComponentData.Constructor(Entity, Name, ...)
		if Component == nil then return Component end

		EntityData.Components[Name] = Component
		World._On.Component.Create(Entity, Name, Component)

		local Signature = String.BOr(EntityData.Signature, ComponentData.Signature)
		EntityData.Signature = Signature

		for ArchetypeSignature, Archetype in World._SignatureToArchetype do
			if
				not Archetype.Collection[Entity] and
				String.BAnd(ArchetypeSignature, Signature) == ArchetypeSignature
			then
				Archetype.Collection[Entity] = true
			end
		end

		return Component
	end

	-- Deletes and disassociates a component from the entity, returns whatever the destructor returns
	function World.Component.Delete<E, N, D>(Entity : Entity<E>, Name : N, ... : any): D?
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

		for ArchetypeSignature, Archetype in World._SignatureToArchetype do
			if
				Archetype.Collection[Entity] and
				String.BAnd(ComponentData.Signature, ArchetypeSignature) == ComponentData.Signature
			then
				Archetype.Collection[Entity] = nil
			end
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
	World.Entity = {}

	-- Registers an entity internally
	function World.Entity.Register<A>(Any: A)
		assert(not World._EntityToData[Any], "Attempting to register entity twice")

		World._EntityToData[Any] = {
			Signature = "0";
			Components = {};
		}

		local UniversalArchetype = GetArchetype(World, "0")
		UniversalArchetype.Collection[Any] = true

		World._On.Entity.Create(Any)
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

		for Name in EntityData.Components do
			World.Component.Delete(Entity, Name)
		end

		local UniversalArchetype = GetArchetype(World, "0")
		UniversalArchetype.Collection[Entity] = nil

		World._On.Entity.Delete(Entity)
	end

	return World
end

return Module