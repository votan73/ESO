# LibAsync

A powerful asynchronous execution library for Elder Scrolls Online (ESO) addons that prevents UI freezes by distributing intensive operations across multiple frames.

## Overview

LibAsync helps manage CPU-intensive operations by:
- Spreading execution across multiple frames
- Automatically adjusting execution time based on CPU load
- Providing intuitive async/await-like syntax
- Managing frame timing to maintain UI responsiveness

## Installation

1. Copy the `LibAsync` folder to your addon's directory
2. Add to your manifest:
```txt
## DependsOn: LibAsync
```

## Basic Usage

```lua
local async = LibAsync

-- Create a named task
local task = async:Create("MyTask")

-- Chain operations
task:Call(function(task)
    -- First operation
    DoSomething()
end):Then(function(task)
    -- Next operation
    DoSomethingElse()
end)
```

## Core API

### Task Management

```lua
-- Create new task
local task = async:Create("taskName")

-- Get current task context
local currentTask = async:GetCurrent()

-- Basic control
task:Resume()   -- Resume execution
task:Suspend()  -- Pause execution
task:Cancel()   -- Stop execution
```

### Sequential Operations

```lua
-- Chain operations
task:Call(function(task)
    -- Initial operation
end):Then(function(task)
    -- Next operation
end)

-- Delayed execution
task:Delay(1000, function(task)
    -- Executes after 1000ms
end)

-- Chain with delay
task:ThenDelay(1000, function(task)
    -- Continues chain after 1000ms
end)
```

### Loop Operations

```lua
-- Numeric for loop
task:For(1, 10):Do(function(index)
    ProcessItem(index)
end)

-- Table iteration
task:For(pairs(myTable)):Do(function(key, value)
    ProcessEntry(key, value)
end)

-- Array iteration
task:For(ipairs(myArray)):Do(function(index, value)
    ProcessItem(index, value)
end)

-- While loop
task:While(function()
    return condition
end):Do(function()
    -- Loop body
end)

-- Break from loops
task:For(1, 100):Do(function(index)
    if shouldStop then
        return async.BREAK
    end
end)
```

### Conditional Waiting

```lua
-- Wait for condition
task:WaitUntil(function()
    return someCondition
end)
```

### Error Handling

```lua
task:OnError(function(task)
    -- Handle errors
end):Finally(function(task)
    -- Cleanup code
end)
```

## Examples

### Basic Task Chain

```lua
local async = LibAsync
local task = async:Create("example")

local i = 1
local function Hello() d("Hello") end
local function World() d("World") end

task:Call(function(task)
    d(i)
    task:Call(Hello):Then(World)
    i = i + 1
    return i < 1000
end):Then(function()
    d("end")
end)
```

### Nested Loops

```lua
local async = LibAsync

async:For(1, 10):Do(function(index)
    d(index)
end):Then(function()
    async:For(pairs({"a", "b"})):Do(function(key, value)
        d(key, value)
        async:For(ipairs({"c", "d"})):Do(function(key, value)
            d(key, value)
        end)
    end)
end)
```

## Performance Notes

- Operations are automatically distributed across frames
- CPU load is monitored and managed automatically
- Frame time is adjusted based on scene state (UI/HUD)
- Total execution time increases but UI remains responsive
- Useful for:
  - Large data processing
  - Complex calculations
  - Multiple server requests
  - Heavy string operations
  - Resource-intensive loops

## Best Practices

1. Use descriptive task names for debugging
2. Keep individual operations lightweight
3. Use error handling for robustness
4. Clean up with Finally blocks
5. Break long loops when needed using `async.BREAK`
6. Monitor CPU load with `async:GetCpuLoad()`

## Debug Mode

```lua
-- Enable debug logging
async:SetDebug(true)

-- Check debug status
local isDebug = async:GetDebug()
```
