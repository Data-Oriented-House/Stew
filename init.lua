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

export type Name<N> = N

export type Component<C> = C

export type Entity = {
	[Name<any>] : Component<any>;
}

export type Collection = { Entity }

export type Template<N, C> = {
	Constructor : ((Entity : Entity, Name: Name<N>, ...any) -> Component<C>)?;
	constructor : ((Entity : Entity, Name: Name<N>, ...any) -> Component<C>)?;

	Destructor : ((Entity : Entity, Name : Name<N>, ...any) -> ())?;
	destructor : ((Entity : Entity, Name : Name<N>, ...any) -> ())?;
}

type Data<N, C> = {
	Signature : Signature;
	Constructor : ((Entity : Entity, Name: Name<N>, ...any) -> Component<C>)?;
	Destructor : ((Entity : Entity, Name : Name<N>, ...any) -> ())?;
}

type InternalCollection = {
	Signature : Signature;
	Entities : { Entity };
	EntityToIndex : { [Entity] : number };
}

local Module = {}

Module._NextPlace = 1
Module._UniversalSignature = "0"

Module._NameToData = {} :: { [Name<any>] : Data<any, any> }
Module._EntitySignatures = {} :: { [Entity] : Signature }
Module._SignatureToCollection = {} :: { [Signature] : InternalCollection }

local function InsertEntity(Entity : Entity, Collection : Collection)
	local Index = #Collection.Entities + 1
	Collection.Entities[Index] = Entity
	Collection.EntityToIndex[Entity] = Index
end

local function RemoveEntity(Entity : Entity, Collection : Collection)
	local Index = Collection.EntityToIndex[Entity]
	local LastIndex = #Collection.Entities
	local LastEntity = Collection.Entities[LastIndex]
	Collection.Entities[Index], Collection.Entities[LastIndex] = LastEntity, nil
	Collection.EntityToIndex[LastEntity], Collection.EntityToIndex[Entity] = Index, nil
end

local function GetCollection(Signature : Signature): Collection
	local FoundCollection = Module._SignatureToCollection[Signature]
	if FoundCollection then return FoundCollection end

	local Collection: InternalCollection = {
		Signature = Signature;
		Entities = {} :: {Entity};
		EntityToIndex = {} :: { [Entity] : number };
	}

	Module._SignatureToCollection[Signature] = Collection

	for _, Entity in ipairs(Module._SignatureToCollection[Module._UniversalSignature].Entities) do
		if StringBAnd(Collection.Signature, Module._EntitySignatures[Entity]) == Collection.Signature then
			InsertEntity(Entity, Collection)
		end
	end

	return Collection
end

local function DefaultConstructor<N>(Entity : Entity, Name : Name<N>, ... : any) : true
	return true
end

local function DefaultDestructor<N>(Entity : Entity, Name : Name<N>, ... : any)
end

--Initialize the Universal collection
GetCollection(Module._UniversalSignature)

Module.Collection = {}

function Module.Collection.Get(Names : { Name<any> }) : Collection
	local Signature = Module._UniversalSignature

	for _, Name in ipairs(Names) do
		local Data = Module._NameToData[Name]
		assert(Data, "Attempting to get collection of non-existant " .. Name .. " component")

		Signature = StringBOr(Signature, Data.Signature)
	end

	return GetCollection(Signature).Entities
end

Module.Component = {}

function Module.Component.Build<N, C>(Name : Name<N>, Template : Template<N, C>?)
	assert(not Module._NameToData[Name], "Attempting to build component "..Name.." twice")

	Template = Template or {}

	Module._NameToData[Name] = {
		Signature = StringPlace(Module._NextPlace);

		Constructor = Template.Constructor or Template.constructor or DefaultConstructor;
		Destructor = Template.Destructor or Template.destructor or DefaultDestructor;
	}

	Module._NextPlace += 1
end

function Module.Component.Create<N>(Entity : Entity, Name : Name<N>, ... : any)
	local Data = Module._NameToData[Name]
	assert(Data, "Attempting to create instance of non-existant " .. Name .. " component")

    if Entity[Name] then
        return
    end

	Entity[Name] = Data.Constructor(Entity, ...)
    if Entity[Name] == nil then return end

	Module._EntitySignatures[Entity] = StringBOr(Module._EntitySignatures[Entity], Data.Signature)

	for CollectionSignature, Collection in pairs(Module._SignatureToCollection) do
		if
			not Collection.EntityToIndex[Entity] and
			StringBAnd(CollectionSignature, Module._EntitySignatures[Entity]) == CollectionSignature
		then
			InsertEntity(Entity, Collection)
		end
	end
end

function Module.Component.Delete<N>(Entity : Entity, Name : Name<N>, ... : any)
	local Data = Module._NameToData[Name]
	assert(Data, "Attempting to delete instance of non-existant " .. Name .. " component")

	local Component = Entity[Name]
	if not Component then return end

    if Data.Destructor(Entity, Component, ...) ~= nil then return end

	Entity[Name] = nil
	Module._EntitySignatures[Entity] = StringBXOr(Module._EntitySignatures[Entity], Data.Signature)

	for CollectionSignature, Collection in pairs(Module._SignatureToCollection) do
		if
			StringBAnd(Data.Signature, CollectionSignature) == Data.Signature and
			Collection.EntityToIndex[Entity]
		then
			RemoveEntity(Entity, Collection)
		end
	end
end

Module.Entity = {}

function Module.Entity.Create() : Entity
	local Entity: Entity = {}
	Module._EntitySignatures[Entity] = Module._UniversalSignature

	InsertEntity(Entity, GetCollection(Module._UniversalSignature))

	return Entity
end

function Module.Entity.Delete(Entity : Entity)
	for Name in pairs(Entity) do
		Module.Component.Delete(Entity, Name)
	end

	RemoveEntity(Entity, GetCollection(Module._UniversalSignature))

	Module._EntitySignatures[Entity] = nil
end

return Module