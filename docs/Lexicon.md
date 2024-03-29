---
sidebar_position: 2
---

With ECS and other Data Oriented patterns / techniques, an extensive vocabulary is born. As time continues this will be fleshed out and extended upon.

## What is an Entity?
An entity is a unique identifier used to relate components together. They represent a single *thing* in your world. In lua this is trivial with the efficient implementations of hash maps. Because of this superpower, anything that can be hashed can be used as an entity, and in lua that's basically everything. So in short, entities can be anything as long as they are unique.

## What is a Component?
A component is a fundamental unit of data. Components are used to represent instantiable state. Each entity will have its own set of components. The combination of components simulates an implicit type that can change at runtime. By creating and deleting components, you can take advantage of dynamic runtime polymorphism. For more information about polymorphism and its usecases, refer to online resources. Keep in mind that polymorphism extends far beyond object-oriented programming, and is a fundamental concept in mathematics and computer-science.

### What does it mean to be Dynamic?
This means changeable, or not static / constant.

### What does it mean to be during Runtime?
This means as the program runs, not during compilation or before.

## What is a System?
A system is a transform that operates on a set of entities with certain components.

### What is a Transform?
This is a procedure that takes in a certain number of inputs, processes them, and potentially returns a certain number of outputs. More information can be found in the [Data Oriented Design](https://www.dataorienteddesign.com/dodbook/node9.html#SECTION00950000000000000000) book by Richard Fabian.

## What is a World?
A world is an instantiable container for all entities, components, and other state. You create entities and components in worlds, and you can create different components in different worlds. For example, your server and clients will always have different worlds.

## What is a Factory?
A factory is an instantiable component "factory" that is responsible for adding, removing, and getting certain components from entities.

## What is a Tag?
A tag in the context of Stew is syntax sugar for a factory that makes `true` components. They solely mark the *existence* of something.