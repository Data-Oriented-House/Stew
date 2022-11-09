local function StringBAnd(String1 : string, String2 : string)
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

warn(StringBAnd("010", "111"))

local function StringBOr(String1 : string, String2 : string)
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

local function StringBNot(String1 : string)
	local String2 = table.create(#String1, 1)

	for i in ipairs(String2) do
		String2[i] = string.byte(String1, i) == 48 and 1 or 0
	end

	for i = #String2, 1, -1 do
		if String2[i] ~= 0 then break end
		String2[i] = nil
	end

	return #String2 == 0 and "0" or table.concat(String2, '')
end

local function StringPlace(Place : number)
	local String = table.create(Place, 0)

	String[Place] = 1

	return #String == 0 and "0" or table.concat(String, '')
end

type Signature = string

export type Name = any

export type Component = any

export type Entity = {
	[any] : Component;
}

export type Collection = { Entity }

export type Template = {
	Constructor : ((Entity : Entity, ...any) -> (any))?;
	constructor : ((Entity : Entity, ...any) -> (any))?;

	Destructor : ((Entity : Entity, Component : Component, ...any) -> ())?;
	destructor : ((Entity : Entity, Component : Component, ...any) -> ())?;
}

local NextPlace = 1
local NameToData = {}
local SignatureToCollection = {}
local UniversalSignature = "0"
local EntitySignatures = {}

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

local function GetCollection(Signature : Signature)
	local Collection = SignatureToCollection[Signature]
	if Collection then return Collection end

	Collection = {
		Signature = Signature;
		Entities = {};
		EntityToIndex = {};
	}

	SignatureToCollection[Signature] = Collection

	for _, Entity in ipairs(SignatureToCollection[UniversalSignature].Entities) do
		if StringBAnd(Collection.Signature, EntitySignatures[Entity]) == Collection.Signature then
			InsertEntity(Entity, Collection)
		end
	end

	return Collection
end

--Initialize the Universal collection
GetCollection(UniversalSignature)

local Module = {}

Module.GetCollection = function(Names : { Name }) : Collection
	local Signature = UniversalSignature

	for _, Name in ipairs(Names) do
		local Data = NameToData[Name]
		assert(Data, "Attempting to get collection of non-existant " .. Name .. " component")

		Signature = StringBOr(Signature, Data.Signature)
	end
	
	return GetCollection(Signature).Entities
end

Module.ConstructComponent = function(Name : Name, Template : Template?)
	assert(not NameToData[Name], "Attempting to construct component "..Name.." twice")

	Template = Template or {}

	NameToData[Name] = {
		Signature = StringPlace(NextPlace);

		Constructor = Template.Constructor or Template.constructor or function(Entity, ...) return true end;
		Destructor = Template.Destructor or Template.destructor or function(Entity, Component, ...) end;
	}

	NextPlace = NextPlace + 1
end

Module.CreateComponent = function(Entity : Entity, Name : Name, ... : any)
	local Data = NameToData[Name]
	assert(Data, "Attempting to create instance of non-existant " .. Name .. " component")

	if Entity[Name] then
		print("Attempting to create instance of " .. Name .. " component when it already exists, overwriting")
	end

	Entity[Name] = Data.Constructor(Entity, ...)
	EntitySignatures[Entity] = StringBOr(EntitySignatures[Entity], Data.Signature)

	for CollectionSignature, Collection in pairs(SignatureToCollection) do
		print(CollectionSignature, EntitySignatures[Entity], StringBAnd(CollectionSignature, EntitySignatures[Entity]), not Collection.EntityToIndex[Entity], StringBAnd(CollectionSignature, EntitySignatures[Entity]) == CollectionSignature)
		if
			not Collection.EntityToIndex[Entity] and
			StringBAnd(CollectionSignature, EntitySignatures[Entity]) == CollectionSignature
		then
			InsertEntity(Entity, Collection)
		end
	end
end

Module.DeleteComponent = function(Entity : Entity, Name : Name, ... : any)
	local Data = NameToData[Name]
	assert(Data, "Attempting to delete instance of non-existant " .. Name .. " component")

	local Component = Entity[Name]
	assert(Component, "Attempting to delete instance of " .. Name .. " when it doesn't exist")

	for CollectionSignature, Collection in pairs(SignatureToCollection) do
		if
			StringBAnd(CollectionSignature, EntitySignatures[Entity]) == CollectionSignature and
			Collection.EntityToIndex[Entity]
		then
			RemoveEntity(Entity, Collection)
		end
	end

	Data.Destructor(Entity, Component, ...)
	Entity[Name] = nil
	EntitySignatures[Entity] = StringBAnd(EntitySignatures[Entity], StringBNot(Data.Signature))
end

Module.CreateEntity = function() : Entity
	local Entity = {}
	EntitySignatures[Entity] = UniversalSignature

	InsertEntity(Entity, GetCollection(UniversalSignature))

	return Entity
end

Module.DeleteEntity = function(Entity : Entity)
	for Name in pairs(Entity) do
		Module.DeleteComponent(Entity, Name)
	end

	RemoveEntity(Entity, GetCollection(UniversalSignature))
end

return Module