"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[658],{90687:e=>{e.exports=JSON.parse('{"functions":[{"name":"factory","desc":"Creates a new factory from an `add` constructor and optional `remove` destructor. An optional `data` field can be defined here and accessed from the factory to store useful metadata like identifiers.\\n\\n```lua\\nlocal world = Stew.world()\\n\\nlocal position = world.factory {\\n\\tadd = function(factory, entity: any, x: number, y: number, z: number)\\n\\t\\treturn Vector3.new(x, y, z)\\n\\tend,\\n}\\n\\nprint(position.data)\\n-- nil\\n\\nprint(position.add(\'A really cool entity\', 5, 7, 9))\\n-- Vector3.new(5, 7, 9)\\n\\nposition.remove(\'A really cool entity\')\\n\\nlocal body = world.factory {\\n\\tadd = function(factory, entity: Instance, model: Model)\\n\\t\\tmodel.Parent = entity\\n\\t\\treturn model\\n\\tend,\\n\\tremove = function(factory, entity: Instance, component: Model)\\n\\t\\tcomponent:Destroy()\\n\\tend,\\n\\tdata = \'A temple one might say...\',\\n}\\n\\nprint(body.data)\\n-- \'A temple one might say...\'\\n\\nprint(body.add(LocalPlayer, TemplateModel))\\n-- TemplateModel\\n\\nbody.remove(LocalPlayer)\\n\\n-- If you\'d like to listen for interesting events to happen, define these callbacks:\\n\\n-- Called when an entity recieves this factory\'s component\\nfunction body.added(entity: Instance, component: Model) end\\n\\n-- Called when an entity loses this factory\'s component\\nfunction body.removed(entity: Instance, component: Model) end\\n```\\n\\t","params":[{"name":"factoryArgs","desc":"","lua_type":"FactoryArgs"}],"returns":[{"desc":"","lua_type":"Factory"}],"function_type":"static","source":{"line":367,"path":"src/init.lua"}},{"name":"tag","desc":"Syntax sugar for defining a factory that adds a `true` component. It is used to mark the *existence* of the component, like a tag does.\\n\\n```lua\\nlocal world = Stew.world()\\n\\nlocal sad = world.tag()\\nlocal happy = world.tag()\\nlocal sleeping = world.tag()\\nlocal poisoned = world.tag()\\n\\nlocal allHappyPoisonedSleepers = world.query { happy, poisoned, sleeping }\\n```\\n\\t","params":[],"returns":[{"desc":"","lua_type":"Factory"}],"function_type":"static","source":{"line":578,"path":"src/init.lua"}},{"name":"entity","desc":"Creates an arbitrary entity and registers it. Keep in mind, in Stew, *anything* can be an Entity (except nil). If you don\'t have a pre-existing object to use as an entity, this will create a unique identifier you can use.\\n\\nCan be sent over remotes and is unique across worlds!\\n\\n```lua\\nlocal World = require(path.to.world)\\nlocal Move = require(path.to.move.factory)\\nlocal Chase = require(path.to.chase.factory)\\nlocal Model = require(path.to.model.factory)\\n\\nlocal enemy = World.entity()\\nModel.add(enemy)\\nMove.add(enemy)\\nChase.add(enemy)\\n\\n-- continues to below example\\n```\\n\\t","params":[],"returns":[{"desc":"","lua_type":"string\\r\\n"}],"function_type":"static","source":{"line":603,"path":"src/init.lua"}},{"name":"kill","desc":"Removes all components from an entity and unregisters it.\\n\\nFires the world `killed` callback.\\n\\n```lua\\n-- continued from above example\\n\\ntask.wait(5)\\n\\nWorld.kill(enemy)\\n```\\n\\t","params":[{"name":"entity","desc":"","lua_type":"any"},{"name":"...","desc":"","lua_type":"any"}],"returns":[],"function_type":"static","source":{"line":624,"path":"src/init.lua"}},{"name":"get","desc":"Gets all components of an entity in a neat table you can iterate over.\\n\\nThis is a reference to the internal representation, so mutating this table directly will cause Stew to be out-of-sync.\\n\\n```lua\\nlocal World = require(path.to.world)\\nlocal Move = require(path.to.move.factory)\\nlocal Chase = require(path.to.chase.factory)\\nlocal Model = require(path.to.model.factory)\\n\\nlocal enemy = World.entity()\\n\\nModel.add(enemy)\\n\\nlocal components = world.get(enemy)\\n\\nfor factory, component in components do\\n\\tprint(factory, component)\\nend\\n-- Model, Model\\n\\nMove.add(enemy)\\n\\nfor factory, component in components do\\n\\tprint(factory, component)\\nend\\n-- Model, Model\\n-- Move, BodyMover\\n\\nChase.add(enemy)\\n\\nfor factory, component in components do\\n\\tprint(factory, component)\\nend\\n-- Model, Model\\n-- Move, BodyMover\\n-- Chase, TargetInstance\\n\\nprint(world.get(entity)[Chase]) -- TargetInstance\\n```\\n\\t","params":[{"name":"entity","desc":"","lua_type":"any"}],"returns":[{"desc":"","lua_type":"Components"}],"function_type":"static","tags":["Do Not Modify"],"source":{"line":686,"path":"src/init.lua"}},{"name":"query","desc":"Gets a set of all entities that have all included components, and do not have any excluded components. (This is the magic sauce of it all!)\\n\\nThis is a reference to the internal representation, so mutating this table directly will cause Stew to be out-of-sync.\\n\\n```lua\\nlocal World = require(path.to.world)\\nlocal Invincible = require(path.to.invincible.tag)\\nlocal Poisoned = require(path.to.poisoned.factory)\\nlocal Health = require(path.to.health.factory)\\nlocal Color = require(path.to.color.factory)\\n\\nlocal poisonedHealths = world.query({ Poisoned, Health }, { Invincible })\\n\\n-- This is a very cool system\\nRunService.Heartbeat:Connect(function(deltaTime)\\n\\tfor entity, components in poisonedHealths do\\n\\t\\tlocal health = components[Health]\\n\\t\\tlocal poison = components[Poison]\\n\\t\\thealth.current -= deltaTime * poison\\n\\n\\t\\tif health.current < 0 then\\n\\t\\t\\tWorld.kill(entity)\\n\\t\\tend\\n\\tend\\nend)\\n\\n-- This is another very cool system\\nRunService.RenderStepped:Connect(function(deltaTime)\\n\\tfor entity, components in world.query { Poisoned, Color } do\\n\\t\\tlocal color = components[Color]\\n\\t\\tcolor.hue += deltaTime * (120 - color.hue)\\n\\t\\tcolor.saturation += deltaTime * (1 - color.saturation)\\n\\tend\\nend)\\n```\\n\\t","params":[{"name":"include","desc":"","lua_type":"{ Factory }"},{"name":"exclude","desc":"","lua_type":"{ Factory }?"}],"returns":[{"desc":"","lua_type":"{ [Entity]: Components }"}],"function_type":"static","tags":["Do Not Modify"],"source":{"line":734,"path":"src/init.lua"}}],"properties":[],"types":[{"name":"Archetype","desc":"","fields":[{"name":"factory","lua_type":"Factory<E, C, D, A..., R...>,","desc":""},{"name":"create","lua_type":"(factory, entity: E, A...) -> C,","desc":""},{"name":"delete","lua_type":"(factory, entity: E, component: C, R...) -> ()","desc":""},{"name":"signature","lua_type":"string,","desc":""}],"source":{"line":232,"path":"src/init.lua"}},{"name":"FactoryArgs","desc":"\\t","fields":[{"name":"add","lua_type":"(factory: Factory, entity: E, A...) -> C","desc":""},{"name":"remove","lua_type":"(factory: Factory, entity: E, component: C, R...) -> ()?","desc":""},{"name":"data","lua_type":"D?","desc":""}],"source":{"line":314,"path":"src/init.lua"}},{"name":"Components","desc":"\\t","lua_type":"{ [Factory]: Component }","source":{"line":639,"path":"src/init.lua"}}],"name":"World","desc":"Worlds are containers for everything in your ECS. They hold all the state and factories you define later. They are very much, an isolated tiny world.\\n\\n\\"Oh what a wonderful world!\\" - Louis Armstrong\\n\\t","source":{"line":281,"path":"src/init.lua"}}')}}]);