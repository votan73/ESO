local async = {}
-- async.registered = {}
local MAJOR = "LibAsync"

async.log = LibDebugLogger and LibDebugLogger(MAJOR)

async.Debug = async.log and function(...)
    async.log:Debug(...)
  end or df

async.Warn = async.log and function(...)
    async.log:Warn(...)
  end or df

local Debug = async.Debug
local Warn = async.Warn

local log_to_chat = false

-- Main Constants
local UPPER_FPS_BOUND = 60.1
local ASYNC_DEFAULT_STALL_THRESHOLD = 15
local ASYNC_STALL_THRESHOLD = ASYNC_DEFAULT_STALL_THRESHOLD
local ASYNC_MIN_STALL_THRESHOLD = 15
local CPU_ADJUSTMENT_RATE = 0.03
local IDLE_UI_ADJUSTMENT_FACTOR = 0.8335
local IDLE_NO_UI_ADJUSTMENT_FACTOR = 1.0
local THROTTLE_UI_ADJUSTMENT_FACTOR = 0.75
local THROTTLE_NO_UI_ADJUSTMENT_FACTOR = 1.0

-- Constants for CPU measurement
local MIN_DELAY_FOR_ASYNC = 10 -- minimum ms before using async delay
local INIT_DELAY_MS = 50 -- delay for initialization
local DEBUG_FREEZE_THRESHOLD = 0.01667
local DEBUG_TIME_MULTIPLIER = 1000 -- Multiplier to convert time to milliseconds for debug output

local em = GetEventManager()
local remove = table.remove
local format = string.format
local min = zo_min
local max = zo_max
local next = next
local pcall = pcall
local error = error
local tonumber = tonumber
local floor = zo_floor
local GetCVar = GetCVar
local ZO_ClearNumericallyIndexedTable = ZO_ClearNumericallyIndexedTable
local GetFrameTimeSeconds = GetFrameTimeSeconds
local GetGameTimeSeconds = GetGameTimeSeconds

--- @param job any
--- @param callstackIndex number
local function RemoveCall(job, callstackIndex)
  remove(job.callstack, callstackIndex)
  job.lastCallIndex = min(job.lastCallIndex, #job.callstack)
end

local current, call
local currentStackIndex = 0
--- @return any
local function safeCall()
  return call(current)
end

--- @param job any
--- @param callstackIndex number
local function DoCallback(job, callstackIndex)
  currentStackIndex = callstackIndex
  local success, shouldContinue = pcall(safeCall)
  if success then
    -- If the call returns true, the call wants to be called again
    if not shouldContinue then
      RemoveCall(job, callstackIndex)
    end
  else
    -- shouldContinue is the value returned by error or assert
    job.Error = shouldContinue
    RemoveCall(job, callstackIndex)

    call = job.onError
    if call then
      local msg
      success, msg = pcall(safeCall)
      if not success then
        Warn(msg)
      end
    else
      job:Suspend()
      error(job.Error)
    end
  end
end

local jobs = async.jobs or {}
async.jobs = jobs

--- @param job any
local function DoJob(job)
  current = job
  -- assert(job.lastCallIndex >= 0, "lastCallIndex gets negative.")
  local index = #job.callstack
  call = job.callstack[index]
  if call then
    DoCallback(job, index)
  else
    -- assert(index == 0, "No call on non-empty stack?!")
    jobs[job.name] = nil
    call = job.finally
    if call then
      pcall(safeCall)
    end
  end
  current, call = nil, nil
end

-- Create local variables from AsyncSavedVars
do
	-- Initialize AsyncSavedVars if not already defined
	AsyncSavedVars = AsyncSavedVars or {}

	-- Use ASYNC_DEFAULT_STALL_THRESHOLD if ASYNC_STALL_THRESHOLD is not defined
	AsyncSavedVars.ASYNC_STALL_THRESHOLD = AsyncSavedVars.ASYNC_STALL_THRESHOLD or ASYNC_DEFAULT_STALL_THRESHOLD

	-- Create local variable from AsyncSavedVars
	ASYNC_STALL_THRESHOLD = AsyncSavedVars.ASYNC_STALL_THRESHOLD
end

local debug = false
local running

-- return to upperFrameTimeTarget when no jobs are in the callstack
local upperFrameTimeTarget = 1.0 / UPPER_FPS_BOUND
local spendTime = upperFrameTimeTarget

local job = nil
local cpuLoad = 0
function async.Scheduler()
	local currentFrameRate = GetFramerate()
	local lowerFrameRate = zo_max(ASYNC_STALL_THRESHOLD, zo_floor(currentFrameRate * 0.25))
	local lowerFrameTimeTarget = (1 / lowerFrameRate)

	--InfoBarFormRepair:SetText(1 / spendTime)
	if not running then
		local hudUiAdjustmentFactor = (not HUD_SCENE:IsShowing() and not HUD_UI_SCENE:IsShowing()) and IDLE_UI_ADJUSTMENT_FACTOR or IDLE_NO_UI_ADJUSTMENT_FACTOR
		spendTime = zo_max(upperFrameTimeTarget, spendTime - spendTime * CPU_ADJUSTMENT_RATE)
		return
	end

	job = nil
	local name = nil
	local runTime
	local start, now = GetFrameTimeSeconds(), GetGameTimeSeconds()
	async.frameTimeSeconds = start
	runTime, cpuLoad = start, now - start

	if cpuLoad > spendTime then
		-- Gradually increase spendTime while capping it based on lowerFrameTimeTarget.
		local hudUiAdjustmentFactor = (not HUD_SCENE:IsShowing() and not HUD_UI_SCENE:IsShowing()) and THROTTLE_UI_ADJUSTMENT_FACTOR or THROTTLE_NO_UI_ADJUSTMENT_FACTOR
		spendTime = zo_min(lowerFrameTimeTarget * hudUiAdjustmentFactor, spendTime + spendTime * CPU_ADJUSTMENT_RATE)
		if debug then
			Debug("[LibAsync - spendtime Adjustment ] lowerFrameTimeTarget: %.3f, initial gap: %.3f, new threshold: %.3f", lowerFrameTimeTarget, (GetGameTimeSeconds() - start), spendTime)
		end
		return
	end

	-- oncePerFrame
	while (now - start) <= spendTime do
		name, job = next(jobs, name)
		if job then
			runTime = now
			DoJob(job)
			now = GetGameTimeSeconds()
		else
			break
		end
	end

	-- Process additional jobs if there is remaining time
	if (now - start) <= spendTime then
		-- loops
		local allOnlyOnce = true
		while (now - start) <= spendTime do
			name, job = next(jobs, name)
			if not job then
				if allOnlyOnce then
					break
				end
				name, job = next(jobs)
				allOnlyOnce = true
			end
			if job then
				if not job.oncePerFrame then
					allOnlyOnce = false
					runTime = now
					DoJob(job)
					now = GetGameTimeSeconds()
				end
			else
				running = next(jobs) ~= nil
				-- Do not adjust spendTime abruptly
				-- 'spendTime will return to upperFrameTimeTarget when 'not running'
				return
			end
		end
	end

	if debug and job then
		local freezeTime = now - start
		local hudUiAdjustmentFactor = (not HUD_SCENE:IsShowing() and not HUD_UI_SCENE:IsShowing()) and THROTTLE_UI_ADJUSTMENT_FACTOR or THROTTLE_NO_UI_ADJUSTMENT_FACTOR
		if freezeTime >= DEBUG_FREEZE_THRESHOLD then
			Warn("[LibAsync] %s freeze. allowed: '%.5f: %.0fms', used %.3fms starting at %.3fms, resulting fps %.3f, currentFrameRate: %.5f, lowerFrameRate: %.5f, lowerFrameTimeTarget: '%.5f: %.0fms', upperFrameTimeTarget: '%.5f: %.0fms'.",
				job.name,
				spendTime, spendTime * 1000,
				(now - runTime) * 1000,
				(runTime - start) * 1000,
				(1 / freezeTime),
				currentFrameRate,
				lowerFrameRate,
				(lowerFrameTimeTarget * hudUiAdjustmentFactor), (lowerFrameTimeTarget * hudUiAdjustmentFactor) * DEBUG_TIME_MULTIPLIER,
				upperFrameTimeTarget, upperFrameTimeTarget * DEBUG_TIME_MULTIPLIER
			)
		end
	end
end

--- @return boolean
function async:GetDebug()
  return debug
end

--- @param enabled boolean
function async:SetDebug(enabled)
  debug = enabled
end

--- @return number
function async:GetCpuLoad()
	return cpuLoad / upperFrameTimeTarget
end

--- Enable or disable logging to chat
--- @param enabled boolean Whether to enable chat logging
function async:SetLogToChat(enabled)
  log_to_chat = enabled
end

--- Get whether logging to chat is enabled
--- @return boolean enabled Whether chat logging is enabled
function async:GetLogToChat()
  return log_to_chat
end

-- Class task

local task = async.task or ZO_InitializingCallbackObject:Subclass()
async.task = task

-- Called from async:Create()
--- @param name string
--- @return any
function task:New(name)
  local instance = ZO_InitializingCallbackObject.New(self)
  instance.name = name or tostring(instance)
  instance:Initialize()
  return instance
end

function task:Initialize()
  self.callstack = {}
  self.lastCallIndex = 0
  -- async.registered[#async.registered + 1] = self
end

-- Resume the execution context.
function task:Resume()
  running = true
  jobs[self.name] = self
  -- Debug("Task %s resumed", self.name)
  return self
end

-- Suspend the execution context and allow to resume anytime later.
function task:Suspend()
  jobs[self.name] = nil
  -- Debug("Task %s suspended", self.name)
  return self
end

-- Interupt and fully stop the execution context. Can be called from outside to stop everything.
function task:Cancel()
  ZO_ClearNumericallyIndexedTable(self.callstack)
  self.lastCallIndex = 0
  if jobs[self.name] then
    if not self.finally then
      jobs[self.name] = nil
    -- Debug("Task %s cancelled", self.name)
    -- else run job with empty callstack to run finalizer
    end
  end
  return self
end

do
  local insert = table.insert
  -- Run the given FuncOfTask in your task context execution.
  function task:Call(funcOfTask)
    self.lastCallIndex = self.lastCallIndex + 1
    if current == self then
      -- assert(self.lastCallIndex > 0 and self.lastCallIndex <= #self.callstack, "cap!")
      insert(self.callstack, self.lastCallIndex, funcOfTask)
    else
      insert(self.callstack, 1, funcOfTask)
    end
    return self:Resume()
  end

  -- Continue your task context execution with the given FuncOfTask after the previous as finished.
  function task:Then(funcOfTask)
    if current == self then
      if self.lastCallIndex <= currentStackIndex then
        -- first nested Then should be a Call
        return self:Call(funcOfTask)
      end
      insert(self.callstack, self.lastCallIndex, funcOfTask)
    else
      if self.lastCallIndex == 0 then
        -- First Then should be a Call
        return self:Call(funcOfTask)
      end
      insert(self.callstack, 1, funcOfTask)
      self.lastCallIndex = self.lastCallIndex + 1
    end
    -- assert(self.lastCallIndex > 0 and self.lastCallIndex <= #self.callstack, "cap!")
    return self
  end
end

-- Start an interruptible for-loop.
function task:For(p1, p2, p3)
  -- If called as a normal job, false will prevent it is kept in callstack doing an endless loop
  self:Call(
    function()
      return false, p1, p2, p3
    end
  )
  return self
end

-- Start an interruptible while-loop.
function task:While(func)
  -- If called as a normal job, false will prevent it is kept in callstack doing an endless loop
  self:Call(
    function()
      return false, func
    end
  )
  return self
end

do
  local function ForConditionAlreadyFalse()
  end
  local function ContinueForward(index, endIndex)
    return index <= endIndex
  end
  local function ContinueBackward(index, endIndex)
    return index >= endIndex
  end

  local function asyncForWithStep(self, func, index, endIndex, step)
    step = step or 1
    if step == 0 then
      error("step is zero")
    end

    local ShouldContinue
    if step > 0 then
      if index > endIndex then
        return ForConditionAlreadyFalse
      end
      ShouldContinue = ContinueForward
    else
      if index < endIndex then
        return ForConditionAlreadyFalse
      end
      ShouldContinue = ContinueBackward
    end
    return function()
      if func(index) ~= async.BREAK then
        index = index + step
        return ShouldContinue(index, endIndex)
      end
    end
  end

  local function asyncForPairs(self, func, iter, list, key)
    return function()
      local value
      key, value = iter(list, key)
      return key and func(key, value) ~= async.BREAK
    end
  end

  -- Execute the async-for with the given step-function. The parameters of the step-function are those you would use in your for body.
  function task:Do(func)
    local callstackIndex = current == self and self.lastCallIndex or 1
    local shouldBeFalse, p1, p2, p3 = self.callstack[callstackIndex]()
    assert(shouldBeFalse == false and p1, "Do without For")
    remove(self.callstack, callstackIndex)

    local DoLoop = type(p1) == "number" and asyncForWithStep(self, func, p1, p2, p3) or asyncForPairs(self, func, p1, p2, p3)

    self.lastCallIndex = self.lastCallIndex - 1
    return self:Call(DoLoop)
  end
end

-- Suspend the execution of your task context for the given delay in milliseconds and then call the given FuncOfTask to continue.
function task:Delay(delay, funcOfTask)
  self:StopTimer()
  if delay < MIN_DELAY_FOR_ASYNC then
    return self:Call(funcOfTask)
  end
  self:Suspend()

  -- Generate unique identifier for this delay
  self.currentCallLaterId = "AsyncDelay" .. tostring(self)

  em:RegisterForUpdate(
    self.currentCallLaterId,
    delay,
    function()
      em:UnregisterForUpdate(self.currentCallLaterId)
      self.currentCallLaterId = nil
      self:Call(funcOfTask)
    end
  )
  return self
end

function task:ThenDelay(delay, funcOfTask)
  self:Then(
    function(innerTask)
      innerTask:Delay(delay, funcOfTask)
    end
  )
  return self
end

function task:WaitUntil(funcOfTask)
  self:Then(
    function(innerTask)
      innerTask.oncePerFrame = not funcOfTask(innerTask)
      return innerTask.oncePerFrame
    end
  )
  return self:Resume()
end

-- Stop the delay created by task:Delay or task:Interval.
function task:StopTimer()
  if self.currentCallLaterId then
    em:UnregisterForUpdate(self.currentCallLaterId)
    self.currentCallLaterId = nil
  end
  return self
end

-- Set a FuncOfTask as a final handler.
-- This handler will run regardless of whether the task completes successfully,
-- encounters an error, or is manually canceled.
function task:Finally(funcOfTask)
  self.finally = funcOfTask
  return self
end

-- Set a FuncOfTask as an error handler.
-- This handler will execute if an error occurs in the task, allowing graceful handling.
function task:OnError(funcOfTask)
  self.onError = funcOfTask
  return self
end

do
  --- @see https://www.lua.org/source/5.1/ltablib.c.html

  local function simpleCompare(a, b)
    return a < b
  end

  -- Helper function to swap elements
  local function swap(array, i, j)
    array[i], array[j] = array[j], array[i]
  end

  local function sort(innerTask, array, compare)
    local function quicksort(left, right)
      if right - left <= 1 then -- Handle small arrays directly
        if right > left and not compare(array[left], array[right]) then
          swap(array, left, right)
        end
        return
      end

      -- Select pivot using median-of-three
      local mid = floor((left + right) / 2)
      if compare(array[right], array[left]) then
        swap(array, left, right)
      end
      if compare(array[mid], array[left]) then
        swap(array, left, mid)
      end
      if compare(array[right], array[mid]) then
        swap(array, mid, right)
      end

      local pivot = array[mid]
      swap(array, mid, right - 1) -- Hide pivot

      -- Partition phase
      local i, j = left, right - 1
      innerTask:Call(
        function()
          while true do
            -- Scan from left
            while i < right - 1 and compare(array[i], pivot) do
              i = i + 1
            end
            -- Scan from right
            while j > left and compare(pivot, array[j]) do
              j = j - 1
            end

            if i >= j then
              break
            end
            swap(array, i, j)
            i = i + 1
            j = j - 1
            return true -- Continue this phase
          end
        end
      )

      innerTask:Then(
        function()
          -- Restore pivot
          swap(array, i, right - 1)

          -- Recursively sort partitions
          quicksort(left, i - 1) -- Sort left partition
          quicksort(i + 1, right) -- Sort right partition
        end
      )
    end

    quicksort(1, #array)
  end

  -- This sort function works like table.sort(). The compare function is optional.
  function task:Sort(array, compare)
    return self:Then(
      function(innerTask)
        sort(innerTask, array, compare or simpleCompare)
      end
    )
  end
end

-- Class async

-- Get the current context, if you are within a FuncOfTask or nil.
function async:GetCurrent()
  return current
end

-- Create an interruptible task context.
function async:Create(name)
  return task:New(name)
end

do
  local Default = task:New("*Default Task*")

  local function DEFAULT_TASK_SENTINEL()
    error("Not allowed on default task. Use your_lib_var:Create(optional_name) for an interruptible task context.", 2)
  end

  Default.Cancel = DEFAULT_TASK_SENTINEL
  Default.Finally = DEFAULT_TASK_SENTINEL
  Default.OnError = DEFAULT_TASK_SENTINEL

  -- Start a non-interruptible task or start a nested call in the current context.
  function async:Call(funcOfTask)
    -- if async:Call is called from within a task callback (the moment where GetCurrent() is not nil) use it for nested calls
    return (async:GetCurrent() or Default):Call(funcOfTask)
  end
  -- Start a non-interruptible for-loop or start a nested for-loop in the current context.
  function async:For(p1, p2, p3)
    return (self:GetCurrent() or Default):For(p1, p2, p3)
  end
  -- Start a non-interruptible for-loop or start a nested for-loop in the current context.
  function async:While(func)
    return (self:GetCurrent() or Default):While(func)
  end

  function async:WaitUntil(func)
    return (self:GetCurrent() or Default):WaitUntil(func)
  end

  -- Start a non-interruptible sort or start a nested sort in the current context.
  function async:Sort(array, compare)
    return (self:GetCurrent() or Default):Sort(array, compare)
  end
end

-- async.BREAK is the new 'break' for breaking loops. As Lua would not allow the keyword 'break' in that context.
-- To break a for-loop, return async.BREAK
async.BREAK = true

function async.Slash(...)
	local num_args = select("#", ...)
	local allArgs = ""

	-- Concatenate arguments into a single string
	if num_args > 0 then
		for i = 1, num_args do
			local value = select(i, ...)
			if type(value) == "string" then
				allArgs = allArgs .. " " .. value
			elseif type(value) == "number" then
				allArgs = allArgs .. " " .. tostring(value)
			end
		end
		allArgs = zo_strtrim(allArgs)
	end

	local args, argValue = "", nil
	for w in zo_strgmatch(allArgs, "%w+") do
		if args == "" then
			args = w
		else
			argValue = tonumber(w) or zo_strlower(w)
		end
	end

	args = zo_strlower(args)

	if args == "stall" then
		if type(argValue) == "number" then
			-- Validate the FPS number
			if argValue < ASYNC_MIN_STALL_THRESHOLD then
				d(string.format("[LibAsync] Invalid FPS value. The stall threshold must be at least %d FPS. Use /async stall <number>.", ASYNC_MIN_STALL_THRESHOLD))
				return
			elseif argValue > UPPER_FPS_BOUND then
				d(string.format("[LibAsync] Invalid FPS value. The stall threshold must be no greater than %d FPS. Use /async stall <number>.", UPPER_FPS_BOUND))
				return
			end

			-- Clamp and apply the value
			local adjustedFps = zo_min(UPPER_FPS_BOUND, zo_max(ASYNC_MIN_STALL_THRESHOLD, argValue))
			AsyncSavedVars.ASYNC_STALL_THRESHOLD = adjustedFps
			ASYNC_STALL_THRESHOLD = AsyncSavedVars.ASYNC_STALL_THRESHOLD

			-- Notify the user of the updated stall threshold
			d(string.format("[LibAsync] Stall threshold set to %d FPS.", adjustedFps))

		elseif type(argValue) == "string" and argValue == "default" then
			-- Set to the default stall threshold
			AsyncSavedVars.ASYNC_STALL_THRESHOLD = ASYNC_DEFAULT_STALL_THRESHOLD
			ASYNC_STALL_THRESHOLD = AsyncSavedVars.ASYNC_STALL_THRESHOLD

			-- Notify the user of the reset to default
			d(string.format("[LibAsync] Stall threshold reset to the default value of %d FPS.", ASYNC_DEFAULT_STALL_THRESHOLD))
		else
			-- Invalid argument
			d("[LibAsync] Invalid argument. Use /async stall <number> or /async stall default.")
		end
	else
		-- Unknown command
		d("[LibAsync] Unknown command. Use /async stall <number> or /async stall default.")
	end
end

-- Scheduler Management
local SchedulerManager = {
  schedulerId = nil,
  initId = nil,
  isRunning = false
}

function SchedulerManager:stopScheduler()
  if self.schedulerId then
    em:UnregisterForUpdate(self.schedulerId)
    self.schedulerId = nil
  end
end

function SchedulerManager:startScheduler()
  self:stopScheduler()
  self.schedulerId = "AsyncScheduler"
  em:RegisterForUpdate(
    self.schedulerId,
    0,
    function()
      async.Scheduler()
    end
  )
end

function SchedulerManager:initialize(delay)
  if self.initId then
    em:UnregisterForUpdate(self.initId)
  end

  self.initId = "AsyncInit"
  em:RegisterForUpdate(
    self.initId,
    delay or INIT_DELAY_MS,
    function()
      em:UnregisterForUpdate(self.initId)
      self.initId = nil
      self:startScheduler()
    end
  )
end

do
  local identifier = "ASYNCTASKS_JOBS"

  em:RegisterForEvent(
    identifier,
    EVENT_PLAYER_ACTIVATED,
    function()
      em:UnregisterForEvent(identifier, EVENT_PLAYER_ACTIVATED)
      SchedulerManager:initialize()
    end
  )
  SLASH_COMMANDS['/async'] = function(...) async:Slash(...) end
  SchedulerManager:startScheduler()
end

rawset(_G, "LibAsync", async)
