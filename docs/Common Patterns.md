---
sidebar_position: 4
---

# Common Patterns

As Stew's usage grows, patterns to achieve common tasks make themselves apparent and will find themselves here. These are by no means strict guidelines on how to use Stew, but rather suggestions on how to use it in a way that is more efficient and easier to understand.

## Deferred Execution

Sometimes you may find yourself needing to execute code *after* the constructor or other callback fires. To do this, and to not do more than you have to, you can use the factory's `added` callback.

```lua
local world = Stew.world()

local myComponent = world.factory {
	added = function(factory, entity)
		print("Before")
		return true
	end,
}

function myComponent.added(entity, component)
	print("After")
end
```

## Modularity + Event Decoupling

More often than not you will want to separate code execution from where it is being called, so you do not couple unrelated or modular code. Stew provides component-level and world-level ways to achieve this, both along the same lines and very simple. Since arbitrary code can be executed whenever a component is constructed, events of your choice can be fired.

This also ties well into using Module Scripts when defining Worlds or Components, since you can easily define extra data alongside everything else and encourage more flexible data accessing. It pairs well with the idea of registries, modules of purely constant data.
```lua
local Module = {}

Module.signals = {
	built = Instance.new 'BindableEvent',
	added = Instance.new 'BindableEvent',
}

Module.world = Stew.world()

function Module.world.built(archetype)
	-- oooooh fancy under-the-hood stuffffffffff
	Module.signals.built:Fire(archetype.signature)
end

function Module.world.added(factory, entity, component)
	Module.signals.added:Fire(factory, entity, component)
end

return Module
```
```lua
local World = require(path.to.module).world

local Module = {}

Module.signals = {
	added = Instance.new 'BindableEvent',
	removed = Instance.new 'BindableEvent',
}

Module.factory = World.factory {
	added = function(factory, entity: Player, x: number, y: number)
		return x + y
	end,
}

export type Component = typeof(Module.factory.add(...))

function Module.factory.added(entity: Player, component: Component)
	Module.signals.added:Fire(entity, component)
end

function Module.factory.removed(entity: Player, component: Component)
	Module.signals.removed:Fire(entity, component)
end

return Module
```

## System Scheduling
Systems are just functions, and typically they run on a certain schedule. RunService tends to do the trick here, but you can use whatever you want. Often we may need systems to run in a certain order, so we start by centralizing this logic in a single place.

```lua
-- System1.lua
return function(deltaTime) ... end

-- System2.lua
return function(deltaTime) ... end

-- System3.lua
return function(deltaTime) ... end

-- System4.lua
return function(deltaTime) ... end

-- Main.server.lua
local System1 = require(path.to.System1)
local System2 = require(path.to.System2)
local System3 = require(path.to.System3)
local System4 = require(path.to.System4)

RunService.Heartbeat:Connect(function(deltaTime)
	System2(deltaTime)
	System4(deltaTime)
	System1(deltaTime)
	System3(deltaTime)
end)
```
However, this is both not very flexible and hard to maintain. We can't infer which systems depend on which, and we can't easily add or remove systems without coming back to this file. We can solve these by first inverting the relationship of each system to the event.

```lua
-- System1.server.lua
RunService.Heartbeat:Connect(function(deltaTime) ... end)

-- System2.server.lua
RunService.Heartbeat:Connect(function(deltaTime) ... end)

-- System3.server.lua
RunService.Heartbeat:Connect(function(deltaTime) ... end)

-- System4.server.lua
RunService.Heartbeat:Connect(function(deltaTime) ... end)
```

Now we can add new systems without having to go back to the main file (there is no main file!). This process can be generalized to a technique called Dependency Inversion. But now they aren't ordered! They have to be ordered or it breaks! We can solve this by using a signal implementation that is ordered. Priorities aren't a good idea here, like what RunService's RenderStepped provides, because they aren't flexible and don't tell us what depends on what. For this, we'll want to use [Topological Sorting](https://en.wikipedia.org/wiki/Topological_sorting). We can use this lightweight ordered signal implementation called [Sandwich](https://data-oriented-house.github.io/Sandwich/) to replace Heartbeat.

```lua
-- Schedules.lua
local Sandwich = require(path.to.Sandwich)
return {
	heartbeat = Sandwich.schedule(),
}

-- System1.lua
local System2 = require(path.to.System2)
return Schedules.heartbeat.job(function(deltaTime) ... end, System2)

-- System2.lua
return Schedules.heartbeat.job(function(deltaTime) ... end)

-- System3.lua
local System1 = require(path.to.System1)
return Schedules.heartbeat.job(function(deltaTime) ... end, System1)

-- System4.lua
local System2 = require(path.to.System2)
return Schedules.heartbeat.job(function(deltaTime) ... end, System2)

-- Main.server.lua
RunService.Heartbeat:Connect(Schedules.heartbeat.start)
```

And now we clearly see System1 and System4 depend on System2, and System3 depends on System1. This will force us to think about our systems and how they interact with each other, and force us to not design cyclical systems.

## Instances As Entities
There are many cases you'll want to use an Instance as an Entity, such as the Player, Character, monster model, etc. Stew allows this, but does not clean up components if the instance is destroyed (the instance still exists anyways!). To implement this, we can take advantage of the world `spawned` callback.

```lua
local world = Stew.world()

local connections = {}

function world.spawned(entity)
	if typeof(entity) == "Instance" then
		connections[entity] = entity.Destroyed:Once(function()
			world.kill(entity)
		end)
	end
end

function world.killed(entity)
	if typeof(entity) == "Instance" then
		connections[entity]:Disconnect()
		connections[entity] = nil
	end
end
```

## CollectionService Integration
CollectionService is a powerful tool and useful for tag replication. We can use our factory callbacks to integrate with it.

```lua
local world = Stew.world()

-- We could use a normal factory,
-- but since CollectionService tags only exist to be added and removed,
-- they can't have any data anyways, so we'll use a tag instead.
local poisoned = world.tag()

function poisoned.added(entity: Instance)
	entity:AddTag 'Poisoned'
end

function poisoned.removed(entity: Instance)
	entity:RemoveTag 'Poisoned'
end

CollectionService:GetInstanceAddedSignal('Poisoned'):Connect(world.factory.add)
CollectionService:GetInstanceRemovedSignal('Poisoned'):Connect(world.factory.remove)
```

Notice we have to come up with a new string for each tag. This is because CollectionService uses strings to identify tags while Stew uses factories. If you'd like, you can keep a registry mapping factories to names, but unless everything is centralized beforehand this can be a pain to maintain.

## Replication
Replication is a very complex topic, and Stew does not provide any replication out of the box because there are so many ways it can be done optimally. However, it does provide a very powerful foundation to build upon. The following is a very simple example of how you could implement replication.

First we need to understand the problem. We need to selectively copy the state of one world to another. Worse, these worlds are separated across the client/server boundary and can't communicate with each other directly. Let's tackle these one at a time, and work on a case-by-case basis.

To begin, we allow ourself to make the assumption world1 exists before world2. Any connections world1 performs will have happened before world2 is created. This is a reasonable assumption mimicking server/client relationships.

(*These code examples have not been tested and here solely for educational purposes*)

### Tag Callbacks

```lua
local world1 = Stew.world()
local tag1 = world1.tag()
```
```lua
local world2 = Stew.world()
local tag2 = world2.tag()

function tag1.added(entity)
	tag2.add(entity)
end

function tag1.removed(entity)
	tag2.remove(entity)
end
```
Pros:
- Entities can be anything
- Dead simple to setup and maintain
- Concise and scalable

Cons:
- Only works for tags
- Only works for this component
- Can't do anything more with tag1's callbacks
- Couples the two worlds together and their factories directly
- Doesn't account for entities that were added before the tag was created

### Tag Signals

To decouple the two worlds, we can use signals.

```lua
local world1 = Stew.world()
local tag1 = world1.tag()

local tagAdded = Instance.new 'BindableEvent'
local tagRemoved = Instance.new 'BindableEvent'

function tag1.added(entity)
	tagAdded:Fire(entity)
end

function tag1.removed(entity)
	tagRemoved:Fire(entity)
end
```
```lua
local world2 = Stew.world()
local tag2 = world2.tag()

tagAdded.Event:Connect(tag2.add)
tagRemoved.Event:Connect(tag2.remove)
```

Pros:
- Entities can be anything
- Decouples the two worlds
- Can do more with tag1's callbacks
- Still concise

Cons:
- Only works for tags
- Only works for this component
- Doesn't account for entities that were added before the tag was created
- Not as scalable

### Tag Signals + Entity Fetching

The only way we can guarantee that we get all the initial entities is by asking for them when ready.

```lua
local askForAllTag1 = Instance.new 'BindableEvent'
local giveAllTag1 = Instance.new 'BindableEvent'
```
```lua
local world1 = Stew.world()
local tag1 = world1.tag()

local tagAdded = Instance.new 'BindableEvent'
local tagRemoved = Instance.new 'BindableEvent'

function tag1.added(entity)
	tagAdded:Fire(entity)
end

function tag1.removed(entity)
	tagRemoved:Fire(entity)
end

askForAllTag1.Event:Connect(function()
	local tagged = world1.query { tag1 }

	local list = {}
	for entity in entities do
		table.insert(list, entity)
	end

	giveAllTag1:Fire(list)
end)
```
```lua
local world2 = Stew.world()
local tag2 = world2.tag()

tagAdded.Event:Connect(tag2.add)
tagRemoved.Event:Connect(tag2.remove)

giveAllTag1.Event:Connect(function(entities)
	for _, entity in entities do
		tag2.add(entity)
	end
end)

askForAllTag1:Fire()
```

Pros:
- Entities can be anything
- Decouples the two worlds
- Can do more with tag1's callbacks
- Accounts for entities that were added before the tag was created

Cons:
- Only works for tags
- Only works for this component
- Losing conciseness and scalability

### Factory Signals + Entity Fetching

To make this work for more than just tags, we need factories. However, now our components actually have data, and have to be reconstructed on the other side. This is where we get the decision to couple the worlds again by reducing the amount of data we send, or decouple the worlds and send all the data. For networking we typically assume we only have two worlds and must minimize the amount of data we send as much as possible. For scalability, we want to decouple any worlds as much as possible, implying we send all the data. Mix and match as you see fit. It is up to you to decide which is best for your usecase.

```lua
local askForAllComponent1 = Instance.new 'BindableEvent'
local giveAllComponent1 = Instance.new 'BindableEvent'
```
```lua
local ReactiveTable = require(path.to.reactiveTable) -- hypothetical implementation
local world1 = Stew.world()

local componentAdded = Instance.new 'BindableEvent'
local componentRemoved = Instance.new 'BindableEvent'
local componentChanged = Instance.new 'BindableEvent'

local component1 = world1.factory {
	added = function(factory, entity, name: string, height: number, occupation: string)
		local self = ReactiveTable.wrap {
			name = name,
			height = height,
			occupation = occupation,
		}

		self.Value.changed = self.Changed:Connect(function(key, value)
			componentChanged:Fire(entity, key, value)
		end)

		return self
	end,

	removed = function(factory, entity, self)
		self.Value.changed:Disconnect()
	end,
}

function component1.added(entity, component)
	componentAdded:Fire(entity, component)
end

function component1.removed(entity, component)
	componentRemoved:Fire(entity)
end

askForAllComponent1.Event:Connect(function()
	local queried = world1.query { component1 }

	local list = {}
	for entity in entities do
		list[entity] = world.get(entity)[component1]
	end

	giveAllComponent1:Fire(list)
end)
```
```lua
local world2 = Stew.world()

local component2 = world2.factory {
	added = function(factory, entity, height: number, occupation: string)
		return {
			height = height,
			occupation = occupation,
		}
	end,
}

componentAdded.Event:Connect(component2.add)
componentRemoved.Event:Connect(component2.remove)

componentChanged.Event:Connect(function(entity, key, value)
	local component = world2.get(entity)[component2]
	if key == 'height' or key == 'occupation' then
		component[key] = value
	end
end)

giveAllComponent1.Event:Connect(function(entities)
	for entity, component in entities do
		component2.add(entity, component.height, component.occupation)
	end
end)

askForAllComponent1:Fire()
```

Pros:
- Entities can be anything
- Works for any component type
- Decouples the two worlds
- Accounts for entities that were added before the tag was created

Cons:
- Only works for this component
- Really losing conciseness and scalability

### Centralized Signals + Entity Fetching

To fix the scalability issue, we can centralize everything into a "Replication" system. This centralized system will be responsible for all replication. Since this is centralized, we will inevitably start coupling other factories to this system to map the factories to names and from names to factories again. We can use this to our advantage though, and maintain our *selective* capabilities like before. Only certain factories will replicate.

We now face another issue, how do we know when to replicate? We want to replicate when a component changes, meaning we need to keep track of that somehow. To comply with this, we can no longer use any data type we want, and must use tables to support indirections.

```lua
local Module = {}

Module.askForAll = Instance.new 'BindableEvent'
Module.giveAll = Instance.new 'BindableEvent'
Module.update = Instance.new 'BindableEvent'

return Module
```
```lua
local World1 = require(path.to.World1)

local Module = {}

Module.factoriesToNames = {
	[require(path.to.component1.factory)] = 'a', -- strings save the most space,
	[require(path.to.component2.factory)] = 'b', -- consider automating this process
	[require(path.to.component4.tag)]	  = 'c', -- with a compression library like Squash
}

local Replicate = World1.factory {
	added = function(factory, entity)
		return {}
	end,
}

Module.factory = Replicate

-- This would be called whenever we want to enqueue the current state of a component
-- to be replicated, which can be automated if using a reactive table library
function Module.enqueue(entity, factory)
	local name = Module.factoriesToNames[factory]
	assert(name, 'Factory cannot be replicated!')

	local replicate = Replicate.add(entity) -- If it doesn't exist then it will be created else it will be returned

	local other = World1.get(entity)[factory]
	assert(other, `Entity does not have a {name} factory component`)

	replicate[name] = other
end

return Module
```
```lua
local World1 = require(path.to.World1)
local Replicate = require(path.to.Replicate.factory).factory
local Signals = require(path.to.Signals)

-- This is the centralized system, it is responsible for all replication
-- You can consider decreasing the frequency of this system for performance reasons
RunService.Heartbeat:Connect(function(deltaTime)
	local payload = {}
	for entity, components in World1.query { Replicate } do
		payload[entity] = components[Replicate]
		Replicate.remove(entity)
	end
	Signals.update:Fire(payload)
end)

Signals.askForAll.Event:Connect(function()
	local payload = {}
	for entity, components in World1.query {} do -- queries for all entities in the world
		local replicate = {}

		for factory, name in Replicate.factoriesToNames do
			replicate[name] = components[factory]
		end

		if next(replicate) then
			payload[entity] = replicate
		end
	end
	Signals.giveAll:Fire(payload)
end)
```
Then on one of the receiving ends:
```lua
local World2 = require(path.to.World2)
local Signals = require(path.to.Signals)

-- These are responsible for taking the recieved component data and somehow
-- mapping it to the new components, either by mutating or adding a new component to the entity
local namesToMaps = {}

function namesToMaps['a'](entity, component1)
	local Component5 = require(path.to.component5.factory) -- requires moved inside for demo only
	...
end

function namesToMaps['b'](entity, component2)
	local Component9 = require(path.to.component9.factory)
	...
end

function namesToMaps['c'](entity, component4)
	local Component8 = require(path.to.component8.factory)
	...
end

local function handlePayload(payload)
	for entity, replicate in payload do
		for name, component in replicate do
			local map = namesToMaps[name]
			assert(map, `A {name} map does not exist on the receiving end!`)

			map(entity, component)
		end
	end
end

Signals.update:Connect(handlePayload)

Signals.giveAll:Once(handlePayload)
Signals.askForAll:Fire()
```

Pros:
- Entities can be anything
- Works for any component type
- Works for all components
- Decouples the two worlds
- Accounts for entities that were added before the tag was created

Cons:
- Can't make enough assumptions to optimize
- This is a nontrivial section of the codebase now

### Final Notes
Clearly there are a lot of ways one can engineer replication. Aim for the simplest solution and don't try to overcomplicate it. Think about what will be most ergonomic to work with, maintain, and extend upon and roll with it. If you can't decide, try the simplest approach until you figure out what needs to be more complicated.