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

local function InsertEntity(Entity, Collection)
    local Index = #Collection.Entities + 1
    Collection.Entities[Index] = Entity
    Collection.EntityToIndex[Entity] = Index
end

local function RemoveEntity(Entity, Collection)
    local Index = Collection.EntityToIndex[Entity]
    local LastIndex = #Collection.Entities
    local LastEntity = Collection.Entities[LastIndex]
    Collection.Entities[Index], Collection.Entities[LastIndex] = LastEntity, nil
    Collection.EntityToIndex[LastEntity], Collection.EntityToIndex[Entity] = Index, nil
end

local function GetCollection(Signature)
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

Module.ConstructComponent = function(Name : Name, Template : Template)
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
        if
            StringBAnd(CollectionSignature, EntitySignatures[Entity]) == EntitySignatures[Entity] and
            not Collection.EntityToIndex[Entity]
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

--[=[
    @class Stew
]=]

--[=[
    @within Stew
    @type Name any

    A name is a unique identifier used as a key to access components in entities.
]=]

--[=[
    @within Stew
    @type Component any

    A component is user-defined data that is stored in an entity. It is defined through the Stew.ConstructComponent function. It is created through the Stew.CreateComponent function.
]=]

--[=[
    @within Stew
    @tag Read Only
    @interface Entity
    .[Name] Component

    An entity is a table storing unique components by their names. It is created through the Stew.CreateEntity function. The entity's components can be accessed through the entity and modified. The entity table itself is read-only however.
]=]

--[=[
    @within Stew
    @type Collection {Entity}

    An array of entities containing at least specific components.
]=]

--[=[
    @within Stew
    @interface Template
    .Constructor|constructor (Entity : Entity, ... : any) -> Component
    .Destructor|destructor (Entity : Entity, Component : Component, ... : any) -> ()
]=]

--[=[
    @within Stew
    @function GetCollection
    @tag Read Only

    @param Names {Name} -- An array of component names.
    @return Collection -- Returns a collection of all entities that have all the components specified.

    Used to get all entities containing specific signatures. This is useful for implementing systems. **This array is unsafe to modify and should be treated as read-only.**

    ```lua
    local Collection : Stew.Collection = Stew.GetCollection{"Health", "Starving"}

    RunService.Heartbeat:Connect(function(DeltaTime : number)
        for _, Entity : Stew.Entity in ipairs(Collection) do
            Entity.Health -= DeltaTime
        end
    end)
    ```
]=]

--[=[
    @within Stew
    @function ConstructComponent

    @param Name Name -- The name of the component.
    @param Template Template -- The template of the component.

    Sets up an internal constructor and destructor for a component. This is used to create and destroy components in entities.
    The constructor passes the entity as the first argument, and any additional arguments passed in.
    The destructor passes the entity, the component being destructed, and any additional arguments passed in.

    ```lua
    Stew.ConstructComponent("Model", {
        Constructor = function(Entity : Stew.Entity, Model : Model)
            return Model:Clone()
        end;

        Destructor = function(Entity : Stew.Entity, Component : Model)
            Component:Destroy()
        end;
    })
    ```
]=]

--[=[
    @within Stew
    @function CreateComponent
        
        @param Entity Entity -- The entity to create the component in.
        @param Name Name -- The name of the component to be created.
    @param ... any -- The arguments of the constructor specified in the template.

    Creates a unique component in an entity.

    ```lua
    local Entity1 : Stew.Entity = Stew.CreateEntity()

    print(Entity1.Model) --> nil

    Stew.CreateComponent(Entity1, "Model", workspace.CoolModel)

    print(Entity1.Model) --> CoolModel
    ```
]=]

--[=[
    @within Stew
    @function DeleteComponent

    @param Entity Entity -- The entity to delete the component from.
    @param Name Name -- The name of the component to be deleted.
    @param ... any -- The arguments of the destructor specified in the template.

    Deletes the unique component from an entity.

    ```lua
    print(Entity1.Model) --> CoolModel

    Stew.DeleteComponent(Entity1, "Model")

    print(Entity1.Model) --> nil
    ```
]=]

--[=[
    @within Stew
    @function CreateEntity
    @return Entity

    Creates a new entity. Entities are tables that contain components via their names.

    ```lua
    local Entity1 : Stew.Entity = Stew.CreateEntity()
    ```
]=]

--[=[
    @within Stew
    @function DeleteEntity
    @param Entity Entity

    Removes all components from the entity and deletes from all internal storage.

    ```lua
    Stew.DeleteEntity(Entity1)
    ```
]=]