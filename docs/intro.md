---
sidebar_position: 1
---

# Introduction

<!-- ![Stew Logo](/SoupWhiteBlack.png) -->

Stew is a minimalistic data-oriented entity-component module. It is designed to be used in conjunction with the Roblox Studio game engine. It was designed to be smaller than competitors, efficient, non-restrictive, and easy to use.

## Some Notes
Stew is a very templated piece of software regarding data formats, allowing for things most others won't. This extends Stew's usefulness as a behavior-implementation and state-management solution. The internals of Stew are volatile and expected to change, potentially rapidly.

### Style
Style was chosen to be concise, easy to type, and easy to read. Please feel no pressure to use Stew conventions in your own code if undesired.

### No Dependencies; Self Contained
Stew commits to not depending on resources outside of its own ecosystem, this leads to interesting design consequences. In place of events where you may connect and listen for things to happen, Stew provides defineable callbacks that can execute arbitrary code at any of these stages. This allows any user to use their own event implementation such as Sleitnick's Signal or Roblox's BindableEvent. It even allows the freedom to debug the entirety of all stew operations, and potentially build tooling to beautifully view Stew internals at runtime.

### Respecting The User
Stew respects your intelligence, needs, and desires, trusting you with how you want to use it. It wants to be integratable into a codebase of any style. As a consequence of this, it provides a different set of tools compared to other ECS-like projects. The implementation is aimed to be as generic as possible, allowing you maximum flexibility over data representation, logic execution, implementation details, etc.

This is why private fields are prefixed with `_` rather than being kept local to the module; if you know what you are doing, you may have at the internals as you please.

### DIY-Friendly Instructions; Batteries Not Included
Because of Stew's design philosophy it does not come with many of the bells and whistles of larger-scale competitors. This may be a turn-off for some people, and that's ok! Instead of coming with a way to do every little thing, it gives you the tools to be as flexible as possible while documenting how maintainers and other users have solved common problems. This way if you don't feel like doing it yourself, you can look up the code for it and call it a day!

#### Backend And Ecosystem Contributor
This is a great incentive to build upon Stew, either with packages or wrappers; if you find Stew to be lacking and are interested in developing your own ECS, Stew provides an amazing backend to, **spice things up**, and get your project out sooner without the hassle of archetypal memory management!