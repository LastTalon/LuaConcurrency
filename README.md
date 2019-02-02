<div align="center">
	<h1>Lua Concurrency</h1>
</div>

**Lua Concurrency** is a lightweight library that lets you easily write concurrent Lua code. It is pure Lua allowing it to be included in any Lua project that doesn't provide useful concurrency or asynchronous functionality. It doesn't depend on modifying the C side of Lua, so you can use it within the API you already use.

## Features
This library provides several modules to make writing concurrent code easier in Lua. The primary modules are the `Asynchronous`, `Task`, and `TaskManager` modules.

Across all modules Lua Concurrency includes:
 * `async` and `await` functions
 * Callbacks and a callback constructor to easily create callbacks from functions
 * Tasks as an underlying framework that act as promises
 * A robust task framework for using tasks directly and making your own concurrency tools
 * Task control and chaining th rough `Start`, `Wait`, and `Then` methods
 * A task managment system for keeping track of running tasks as well as determining the current running task
 * Basic sleep functionality (see [Sleeping](#sleeping))

### Asynchronous
The Asynchronous module provides asynchronous functions such as `async`, `await`, and `callback` for creating asynchronous functions allowing you to easily create asynchronous code with little effort. These async functions are based on Tasks behind the scenes, but you don't need to deal with tasks directly to use this module, you just tell which async and callback functions you want to create. This module also provides `task` as a convenience function for the task constructor.

### Task
The Task module provides an interface for creating and manipulating `Task` objects. These are the same objects used behind the scenes in the Asynchronous module. It provides a `new` constructor for creating tasks, convenience methods `Completed` and `Canceled` to explicitly check a task's status, a `Persist` method to change whether tasks persist beyond completion, and a `Destroy` method to explicitly destroy tasks that are persistent. Tasks allow you to `Start`, and `Wait` on them as well as chaining tasks asynchronously with `Then`.

### TaskManager
The TaskManager module is responsible for keeping track of running tasks. The primary use of this will most likely be the `running` function to check which task is the current one running (the one calling the function).

## Usage
Add the library files to your project and require `Asynchronous`, `Task`, and `TaskManager`, or any auxiliary modules as needed.

### Sleeping
Unfortunately Lua provides no sleep functionality by default. This library depends on some sleep functionality and attempts to provide some basic forms of sleep to choose from.

By default this library uses an empty sleep function that doesn't do anything (the entire library will work, but it will not be asynchronous), when including you will need to choose which sleep to use by modifying the require in the `Task` module. All modules ending in `Sleep` provide a single sleep method.

Be sure to check the API you're using. Many provide sleep functionality of some form to Lua. The best method by far is to use the sleep provided to Lua this way. If you wish to do this, modify `Sleep.lua` to call this function with the appropriate duration. Be sure the sleep is a yielding sleep and will not cause the rest of your asynchronous code to block.

## Contributing
Contributing is welcome. Please make a pull request or get in touch.

## License
Lua Concurrency is free software licensed under the zlib license. See the [license](LICENSE.md) for details.
