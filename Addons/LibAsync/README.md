# LibAsync

A powerful asynchronous execution library for Elder Scrolls Online (ESO) addons that prevents UI freezes by distributing intensive operations across multiple frames.

## Overview

LibAsync helps manage CPU-intensive tasks by:
- Spreading execution across multiple frames
- Automatically adjusting execution time based on the current frame rate and scene (HUD or menu)
- Providing an intuitive, chainable syntax
- Managing frame timing to maintain UI responsiveness

Why use LibAsync?
- Prevents frame drops during intensive operations
- Enables heavy data processing without impacting gameplay
- Simplifies asynchronous logic with an intuitive API

## Installation

1. Install LibAsync as a separate addon: copy the `LibAsync` folder to your `AddOns` directory
2. Add to your addon's manifest:
```txt
## DependsOn: LibAsync
```

## Basic Usage

```lua
local async = LibAsync

-- Create a named task
local task = async:Create("MyTask")

-- Chain tasks
task:Call(function(task)
    -- First task
    DoSomething()
end):Then(function(task)
    -- Next task
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

### Sequential Tasks

```lua
-- Chain tasks
task:Call(function(task)
    -- Initial task
end):Then(function(task)
    -- Next task
end)

-- Delayed execution (suspends the task immediately; delays below 10 ms run as a normal Call)
task:Delay(1000, function(task)
    -- Executes after 1000ms
end)

-- Stop a pending Delay (also done by Cancel)
task:StopTimer()

-- Chain with delay
task:ThenDelay(1000, function(task)
    -- Continues chain after 1000ms
end)
```

### Loop Tasks

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

### Sorting

```lua
-- Works like table.sort(); the compare function is optional
task:Sort(myArray, function(a, b) return a.value < b.value end)
```

### Default Task (without Create)

`async:Call`, `async:For`, `async:While`, `async:WaitUntil` and `async:Sort` run on a shared default task. It is not cancellable, and `Cancel`, `Finally` and `OnError` raise an error on it. Inside a running step these functions become nested calls of the current task.

```lua
async:For(1, 100):Do(function(index)
    ProcessItem(index)
end)
```

### Conditional Waiting

```lua
-- Wait for condition
task:WaitUntil(function()
    return someCondition
end)
```

### Error Handling and Cleanup

LibAsync allows you to define error-handling and cleanup logic for tasks. The `OnError` method handles errors in task execution, while the `Finally` method ensures final cleanup logic runs regardless of success or failure. You can also use `Finally` independently to clean up after a task, even if it is canceled.

#### Example: Error Handling with Cleanup

```lua
local async = LibAsync
local task = async:Create("ErrorExample")

task:Call(function()
    error("Simulated task error")
end)
:OnError(function(task)
    d("An error occurred: " .. task.Error)
end)
:Finally(function(task)
    d("Cleaning up after the task, even if canceled or errored.")
end)

-- Canceling the task
task:Cancel()  -- Will still trigger the Finally block
```

## Quick Reference

| Function        | Description                                      |
|-----------------|--------------------------------------------------|
| `async:Create`  | Creates a new asynchronous task.                |
| `task:Call`     | Executes a function within the task.            |
| `task:Then`     | Chains another function to execute after `Call`.|
| `task:Delay`    | Suspends the task for a specified time (ms).    |
| `task:Cancel`   | Cancels the task.                               |
| `task:For`      | Starts a loop over a range or collection.       |
| `task:WaitUntil`| Waits until a condition is met.                 |
| `task:Finally`  | Ensures cleanup logic runs after the task ends. |
| `task:OnError`  | Handles errors raised inside the task.          |
| `task:While`    | Starts a loop that runs while a condition holds.|
| `task:Sort`     | Sorts an array asynchronously.                  |
| `task:ThenDelay`| Delays at the current position in the chain.    |
| `task:StopTimer`| Stops a pending `Delay`.                        |

## Examples

### Basic Examples

#### Basic Task Chain
```lua
local async = LibAsync
local task = async:Create("example")

local i = 1
local function Hello() d("Hello") end
local function World() d("World") end

-- Create a task that loops until `i` reaches 1000
task:Call(function(task)
    d(i)
    task:Call(Hello):Then(World)
    i = i + 1
    return i < 1000
end):Then(function()
    d("end")
end)
```

### Advanced Examples

#### Nested Loops
```lua
local async = LibAsync

-- Process nested data using loops
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

## Performance Insights and Considerations

LibAsync runs the steps of **all** addons that use it in one shared scheduler. How fast a task finishes therefore depends on the time budget the scheduler grants per frame.

### How the time budget is chosen

1. The current frame rate selects a target slice of 1, 2, 3 or 4 frames (16.7 ms at more than 65 fps, 33 ms above 45 fps, 50 ms above 30 fps, otherwise 67 ms).
2. While the HUD is visible (gameplay) the slice is reduced (x0.91). In menus and other full-screen UI it is enlarged (x1.21), because stutter is less noticeable there.
3. The slice never exceeds `1 / stall threshold` seconds (default 15 fps, see `/async stall`) and is smoothed over time.
4. If the scheduler overran last frame, the next slice is reduced.
5. On console the remaining add-on CPU budget of the frame is respected.

### What this means in practice

- Tasks finish fastest while a menu is open and the frame rate is high, and slowest in busy areas during gameplay with a low frame rate. Large jobs can take minutes in crowded places such as a city bank.
- Performance-intensive tasks of one addon slow down the tasks of all other addons.
- When tasks seem to "stall", the frame rate is usually low and the slice small; LibAsync is still working.

### Recommendations for Developers

1. **Optimize task granularity**: Break work into small units (one item or a small batch per `Do` body) so a single step does not dominate the slice.
2. **Test across scenarios**: Validate in cities, player homes and during high-CPU activities.
3. **Offer settings**: Consider configurable batch sizes to let users adapt performance to their system.


## Guide for addon authors (scheduler, sharing, errors)

This section answers common integration questions when several addons use LibAsync at once (for example trading/price tools, minimaps, and map overlays).

### One global scheduler

- LibAsync runs a single `RegisterForUpdate` scheduler every frame.
- Every active task from every addon is stored in one table, keyed by the string you pass to `async:Create("YourTaskName")`.
- There is **no per-addon queue**, **no priority**, and **no fair-share guarantee** beyond walking active tasks with `next(jobs)` until the frame budget is used up.

If your addon and another both run heavy work at login, you share the same time slice.

### When work moves to the next frame

The scheduler stops starting new `DoJob` calls for the current frame when elapsed time exceeds `spendTime` (measured with `GetGameTimeSeconds()`).

`spendTime` is **not** a fixed millisecond constant. It is adapted from:

- Current framerate (higher FPS → smaller target slice; lower FPS → larger slice, up to a cap)
- Whether HUD / HUD UI scenes are showing (gameplay vs menus)
- `ASYNC_STALL_THRESHOLD` (default 15 FPS equivalent cap via saved var; users can tune with `/async stall <fps>`)
- `nextFrameReduce` if the scheduler overran last frame (backs off next frame)
- On console / Game Core UI: `min(..., GetConsoleRemainingBudgetSeconds())` using `GetTotalUserAddOnCPUTimeAvailableEachFrameMS()` and `GetTotalUserAddOnCPUTimeUsedNowMS()`

**Cooperative yielding:** LibAsync only splits work you express as steps:

| Pattern | Yields between frames? |
|--------|-------------------------|
| `task:For(...):Do(function() ... end)` | Yes — one loop body per scheduler step (return `async.BREAK` to stop early) |
| `task:Call(function() return true end)` | Yes — return `true` to run again; any other return removes the step |
| `task:Call(function() ... huge block ... end)` with no `true` | **No** — entire function runs in one `pcall` |
| Top-level `async:For(...):Do(...)` (default task) | Yes, same as `For`/`Do` on a task |
| Top-level `async:Call(function() ... end)` without returning `true` | **No** — same as a single non-yielding `Call` |

Rule of thumb: **one iteration or one small batch per `Do` body**, or explicit `return true` from `Call`. Decoding thousands of items inside one callback will still hitch and still counts toward the engine’s per-frame addon CPU limit.

### LibAsync budget vs the “1000 ms” UI error

These are different limits:

1. **LibAsync** tries to keep its scheduler near a small target per frame (on the order of tens of milliseconds at default settings, before console clamping).
2. **The game client** enforces a much larger **total user-addon CPU budget per frame** (the familiar UI error: CPU time budget of 1000 ms reached this frame, no further add-on scripts until next frame).

When that engine error appears, the stack trace often shows `LibAsync.lua` inside `DoCallback` because that is where your callback was running under `pcall`. The **job name** in the error (for example `VOTANS_MAP_DO_CALLBACKS`) is the **task name of whoever was executing at cutoff**, not a full attribution of which addon consumed the most time in that frame.

Earlier in the same frame, other addons may have run:

- Other LibAsync tasks (including yours)
- Event handlers, XML, and Lua that never went through LibAsync

All of that shares the engine’s single per-frame addon CPU pool.

### Can I wait until other addons finish their LibAsync work?

**Not with a built-in API today.** LibAsync does not expose:

- A list of all addons’ tasks
- A global “idle” or “all jobs complete” event
- `Finally` hooks on another addon’s task

What you **can** use:

- **Per task:** `:Finally(function() ... end)` on **your** `async:Create(...)` task only
- **Rough load:** `async:GetCpuLoad()` — recent scheduler activity for LibAsync, not total engine headroom or non-LibAsync work
- **Stagger:** `task:Delay` / `task:ThenDelay` after `EVENT_PLAYER_ACTIVATED` or after your UI opens, instead of starting huge jobs at load
- **Heuristic:** `task:WaitUntil(function() return async:GetCpuLoad() < threshold end)` (optional; still does not account for heavy non-LibAsync code)
- **Load events:** `EVENT_ADD_ON_LOADED` means an addon’s files ran, **not** that its async price decode or map build finished

Coordinating “wait until minimap/price fetcher is done” requires an explicit contract between addons (shared event, library API, or settings), not LibAsync alone.

### Practical recommendations

1. **Name tasks** with your addon prefix (`MYADDON_DECODE_PRICES`) so errors and debug output are identifiable.
2. **Chunk data work** with `For`/`Do` or repeated `Call` returning `true`; avoid one callback that processes thousands of rows.
3. **Defer heavy jobs** until after the first UI frame or when the player opens the feature that needs the data.
4. **Use `:OnError` and `:Finally`** on long-running tasks so failures and cancel do not leave state half-built.
5. On console, assume **`GetConsoleRemainingBudgetSeconds()`** may shrink your slice when other addons have already used CPU this frame.
6. Tell users that **many LibAsync addons at once** will slow everyone’s background tasks in cities and at login; reducing batch size often helps more than blaming LibAsync itself.

### Slash command (users and support)

```
/async stall <fps>     -- clamp stall threshold (15–200), saved in AsyncSavedVars
/async stall default   -- reset to default (15)
```

The per-frame target of LibAsync is capped at `1 / fps` seconds. A lower stall FPS therefore allows a larger slice per frame (faster completion, but lower frame rates); a higher value keeps frames short and smooth, but tasks take longer. Use low values carefully on low-end hardware.

## Testing

LibAsync includes a comprehensive test suite using the [Taneth](https://www.esoui.com/downloads/info2334-Taneth.html) testing framework. Tests are automatically registered when Taneth is available.

### Running Tests In-Game

1. Install the [Taneth addon](https://www.esoui.com/downloads/info2334-Taneth.html)
2. Load LibAsync (tests automatically register if Taneth is available)
3. Use the following slash commands in-game:

```
/libasynctests          - Show test help and available commands
/libasynctest           - Run all LibAsync tests
/libasynctest LibAsync  - Run the LibAsync test suite
```

### Test Suites

The test suite is organized into the following test groups:

#### Basic Task Management
- Task creation with names
- Getting current task context
- Basic task execution

#### Sequential Tasks
- Chaining tasks with `Call` and `Then`
- Nested `Call`/`Then` operations
- Task sequencing and dependencies

#### Loop Tasks
- Numeric `For` loops (with and without step)
- `pairs` iteration over tables
- `ipairs` iteration over arrays
- `While` loops with conditions
- Breaking loops with `LibAsync.BREAK`

#### Delay Tasks
- `Delay` execution with timeouts
- `ThenDelay` chaining with delays
- Timing validation

#### WaitUntil Tasks
- Conditional waiting for conditions
- Polling until conditions are met

#### Error Handling
- `OnError` callback execution
- `Finally` block execution on success
- `Finally` block execution on error
- `Finally` block execution on cancel

#### Task Control
- Resuming suspended tasks
- Canceling tasks
- Task state management

#### Sorting
- Array sorting with default comparison
- Array sorting with custom comparators
- Sorting large arrays asynchronously

#### Async Static Methods
- Task instance operations
- Default task behavior validation

#### Nested Tasks and Complex Scenarios
- Deeply nested task structures
- Loops within tasks
- Delays within loops
- Complex async workflows

#### Edge Cases
- Empty tasks
- Zero delay handling
- Multiple resume calls
- Canceling non-existent tasks
- Boundary conditions

#### Debug and Utility Functions
- Debug state management (`SetDebug`/`GetDebug`)
- Log to chat state (`SetLogToChat`/`GetLogToChat`)
- CPU load monitoring (`GetCpuLoad`)

#### Console CPU Budget Integration
- Respecting the add-on CPU budget on console / Game Core UI

#### Integration Tests
- Complex async workflows with multiple steps
- Error recovery in complex workflows
- Real-world usage scenarios

### Writing Tests

Tests use Taneth's BDD-style syntax. For async operations, use `it.async` and call `done()` when the test completes:

```lua
describe("Feature Name", function()
    it("should do something synchronously", function()
        -- Synchronous test code
        assert.is_true(condition)
    end)

    it.async("should handle async operations", function(done)
        local task = LibAsync:Create("TestTask")
        task:Call(function()
            -- Do async work
        end):Finally(function()
            assert.equals(expected, actual)
            done() -- Signal test completion
        end)
    end)
end)
```

**Important Notes:**
- Always use `:Finally()` or proper async waiting mechanisms in async tests to ensure operations complete before assertions
- Use `done()` callback to signal when async tests are complete
- Test delays use shorter timeouts (5-10ms) for faster test execution
- Tests automatically restore original state for debug/log settings

## Best Practices

1. Use descriptive task names for debugging (see [Guide for addon authors](#guide-for-addon-authors-scheduler-sharing-errors))
2. Keep individual tasks lightweight; chunk with `For`/`Do` or `Call` returning `true`
3. Use error handling for robustness
4. Clean up with Finally blocks
5. Break long loops when needed using `async.BREAK`
6. Monitor CPU load with `async:GetCpuLoad()` (LibAsync scheduler only, not global idle)
7. Do not rely on LibAsync to serialize or prioritize work across unrelated addons

## Debug Mode

```lua
-- Enable debug logging
async:SetDebug(true)

-- Check debug status
local isDebug = async:GetDebug()
```

With debug enabled, LibAsync warns when a single step (`step`), `OnError`, or `Finally` takes 1ms or longer, including `job.name` and callstack depth—use this to find hot tasks without reading raw `pcall` stacks. `Finally` failures set `task.FinallyError` and are logged without re-raising.
