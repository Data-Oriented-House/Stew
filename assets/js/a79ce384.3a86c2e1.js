"use strict";(self.webpackChunkdocs=self.webpackChunkdocs||[]).push([[325],{21814:t=>{t.exports=JSON.parse('{"functions":[{"name":"Register","desc":"Register an entity with the world. This is done automatically when creating a component.\\n\\n```lua\\nlocal World = Stew.World.Create()\\n\\n-- They all work! :D\\nWorld.Entity.Register(5)\\nWorld.Entity.Register(\\"Hi\\")\\nWorld.Entity.Register({ Cool = true })\\nWorld.Entity.Register(newproxy())\\nWorld.Entity.Register(Instance.new(\\"Part\\"))\\n-- No entity left behind!\\n```\\n\\t","params":[{"name":"Entity","desc":"","lua_type":"any"}],"returns":[],"function_type":"static","errors":[{"lua_type":"Entity Registered Twice","desc":"An entity cannot be registered twice without first being deleted."}],"source":{"line":704,"path":"src/init.lua"}},{"name":"Create","desc":"Creates, registers, and returns an entity. Uses `newproxy` internally, so these entities cannot be sent over the network.\\n\\n```lua\\nlocal World = Stew.World.Create()\\n\\nlocal Entity1 : any = World.Entity.Create()\\nprint(Entity1) --\x3e userdata\\n```\\n\\t","params":[],"returns":[{"desc":"","lua_type":"Entity"}],"function_type":"static","source":{"line":731,"path":"src/init.lua"}},{"name":"Delete","desc":"Deletes all components associated with an entity and removes it from all internal storage.\\n\\nThe entity must be registered again to be used, though this is done automatically when creating components.\\n\\n```lua\\nlocal World = Stew.World.Create()\\n\\nlocal States = {\\n\\tHappy = 1;\\n\\tSad = 2;\\n}\\n\\nWorld.Component.Build(States.Happy)\\nWorld.Component.Build(States.Sad)\\n\\nlocal Entity : any = Stew.Entity.Create()\\nWorld.Component.Create(Entity, States.Happy)\\nWorld.Component.Create(Entity, States.Sad)\\nprint(Stew.Component.GetAll(Entity)) --\x3e { [1] = true, [2] = true }\\n\\nStew.Entity.Delete(Entity)\\nprint(Stew.Component.GetAll(Entity)) --\x3e {}\\n```\\n\\t","params":[{"name":"Entity","desc":"","lua_type":"Entity"}],"returns":[],"function_type":"static","source":{"line":767,"path":"src/init.lua"}}],"properties":[],"types":[],"name":"Entity","desc":"Contains methods for dealing with entities.\\n\\t","source":{"line":681,"path":"src/init.lua"}}')}}]);