local MAJOR = "LibAsync"
local log = LibDebugLogger and LibDebugLogger(MAJOR)
local dbg = log and function(...)
		log:Debug(...)
	end or df
local warn = log and function(...)
		log:Warn(...)
	end or df

local async = {}
--async.registered = {}

local em = GetEventManager()
local remove, min, max, pcall = table.remove, math.min, math.max, pcall

local function RemoveCall(job, callstackIndex)
	remove(job.callstack, callstackIndex)
	job.lastCallIndex = min(job.lastCallIndex, #job.callstack)
end

local current, call
local currentStackIndex = 0
local function safeCall()
	return call(current)
end

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
				warn(msg)
			end
		else
			job:Suspend()
			error(job.Error)
		end
	end
end

local jobs = async.jobs or {}
async.jobs = jobs

local function DoJob(job)
	current = job
	--assert(job.lastCallIndex >= 0, "lastCallIndex gets negative.")
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

-- time we can spend until the next frame must be shown
local frameTimeTarget = GetCVar("VSYNC") == "1" and 0.014 or (math.max(0.0125, tonumber(GetCVar("MinFrameTime.2"))))

-- we allow a function to use 25% of the frame time before it gets critical
local spendTimeDef = frameTimeTarget * 0.75
local spendTimeDefNoHUD = 0.015
local spendTime = spendTimeDef

local debug = false

local running
local GetFrameTimeSeconds, GetGameTimeSeconds = GetFrameTimeSeconds, GetGameTimeSeconds

local function GetThreshold()
	return (HUD_SCENE:IsShowing() or HUD_UI_SCENE:IsShowing()) and spendTimeDef or spendTimeDefNoHUD
end

local job = nil
local cpuLoad = 0
function async.Scheduler()
	if not running then
		spendTime = max(GetThreshold(), spendTime - spendTime * 0.005)
		return
	end

	job = nil
	local name, runTime = nil, nil
	local GetGameTimeSeconds = GetGameTimeSeconds
	local start, now = GetFrameTimeSeconds(), GetGameTimeSeconds()
	async.frameTimeSeconds = start
	runTime, cpuLoad = start, now - start
	if cpuLoad > spendTime then
		spendTime = min(0.030, spendTime + spendTime * 0.02)
		if debug then
			dbg("initial gap: %ims. skip. new threshold: %ims", (GetGameTimeSeconds() - start) * 1000, spendTime * 1000)
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
	spendTime = max(GetThreshold(), spendTime * 0.5)
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
				--if not running then
				--	-- Finished
				--	spendTime = GetThreshold()
				--end
				return
			end
		end
	end
	if debug and job then
		local freezeTime = now - start
		if freezeTime >= 0.016 then
			warn("%s freeze. allowed: %.3fms, used %.3fms starting at %.3fms, resulting fps %i.", job.name, spendTime * 1000, (now - runTime) * 1000, (runTime - start) * 1000, 1 / freezeTime)
		end
	end
end

function async:GetDebug()
	return debug
end

function async:SetDebug(enabled)
	debug = enabled
end

function async:GetCpuLoad()
	return cpuLoad / frameTimeTarget
end

-- Class task

local task = async.task or ZO_Object:Subclass()
async.task = task

-- Called from async:Create()
function task:New(name)
	local instance = ZO_Object.New(self)
	instance.name = name or tostring(instance)
	instance:Initialize()
	return instance
end

function task:Initialize()
	self.callstack = {}
	self.lastCallIndex = 0
	--async.registered[#async.registered + 1] = self
end

-- Resume the execution context.
function task:Resume()
	running = true
	jobs[self.name] = self
	return self
end

-- Suspend the execution context and allow to resume anytime later.
function task:Suspend()
	jobs[self.name] = nil
	return self
end

-- Interupt and fully stop the execution context. Can be called from outside to stop everything.
function task:Cancel()
	ZO_ClearNumericallyIndexedTable(self.callstack)
	self.lastCallIndex = 0
	if jobs[self.name] then
		if not self.finally then
			jobs[self.name] = nil
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
	if delay < 10 then
		return self:Call(funcOfTask)
	end
	self:Suspend()
	em:RegisterForUpdate(
		self.name,
		delay,
		function()
			em:UnregisterForUpdate(self.name)
			self:Call(funcOfTask)
		end
	)
	return self
end

function task:ThenDelay(delay, funcOfTask)
	self:Then(
		function(self)
			self:Delay(delay, funcOfTask)
		end
	)
	return self
end

function task:WaitUntil(funcOfTask)
	self:Then(
		function(self)
			self.oncePerFrame = not funcOfTask(self)
			return self.oncePerFrame
		end
	)
	return self:Resume()
end

-- Stop the delay created by task:Delay or task:Interval.
function task:StopTimer()
	em:UnregisterForUpdate(self.name)
	return self
end

-- Set a FuncOfTask as a final handler. If you call Called if something went wrong in your context.
function task:Finally(funcOfTask)
	self.finally = funcOfTask
	return self
end

-- Set a FuncOfTask as an error handler. Called if something went wrong in your context.
function task:OnError(funcOfTask)
	self.onError = funcOfTask
	return self
end

do
	-- Thanks to: https://de.wikipedia.org/wiki/Quicksort

	local function simpleCompare(a, b)
		return a < b
	end
	local function sort(task, array, compare)
		local function quicksort(left, right)
			if left >= right then
				return
			end

			-- partition
			local i, j, pivot = left, right - 1, array[right]

			task:Call(
				function()
					while i < right and compare(array[i], pivot) do
						i = i + 1
					end
					while j > left and not compare(array[j], pivot) do
						j = j - 1
					end
					if i < j then
						array[i], array[j] = array[j], array[i]
						-- repeatly call this function until i >= j
						return true
					end
				end
			)
			task:Then(
				function()
					if compare(pivot, array[i]) then
						array[i], array[right] = array[right], array[i]
					end
					quicksort(left, i - 1)
					quicksort(i + 1, right)
				end
			)
		end
		quicksort(1, #array)
	end

	-- This sort function works like table.sort(). The compare function is optional.
	function task:Sort(array, compare)
		return self:Then(
			function(task)
				sort(task, array, compare or simpleCompare)
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
	function Default:Cancel()
		error("Not allowed on default task. Use your_lib_var:Create(optional_name) for an interruptible task context.")
	end
	Default.Finally = Default.Cancel
	Default.OnError = Default.Cancel

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

local function stateChange(oldState, newState)
	if newState == SCENE_SHOWN or newState == SCENE_HIDING then
		spendTime = GetThreshold()
	end
end

local identifier = "ASYNCTASKS_JOBS"

HUD_SCENE:RegisterCallback("StateChange", stateChange)
HUD_UI_SCENE:RegisterCallback("StateChange", stateChange)

do
	--Use another id, so that the slot for identifier is not re-used.
	local id2 = identifier .. "2"

	function async:Unload()
		HUD_SCENE:UnregisterCallback("StateChange", stateChange)
		HUD_UI_SCENE:UnregisterCallback("StateChange", stateChange)
		em:UnregisterForUpdate(id2)
		em:UnregisterForUpdate(identifier)
	end

	local function register2()
		em:UnregisterForUpdate(id2)
		em:RegisterForUpdate(identifier, 0, async.Scheduler)
	end
	-- Another delay to increase chance to be one of the last.
	local function register()
		em:UnregisterForUpdate(id2)
		em:RegisterForUpdate(id2, 50, register2)
	end

	em:RegisterForEvent(
		id2,
		EVENT_PLAYER_ACTIVATED,
		function()
			em:UnregisterForEvent(id2, EVENT_PLAYER_ACTIVATED)
			return register()
		end
	)
	em:RegisterForUpdate(id2, 0, async.Scheduler)
end

LibAsync = async
