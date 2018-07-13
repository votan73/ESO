local MAJOR, MINOR = "LibAsync", 1.7
local async, oldminor = LibStub:NewLibrary(MAJOR, MINOR)
if not async then return end -- the same or newer version of this lib is already loaded into memory

if async.Unload then
	async:Unload()
end

local em = GetEventManager()
local remove, min = table.remove, math.min

local function RemoveCall(job, callstackIndex)
	remove(job.callstack, callstackIndex)
	job.lastCallIndex = min(job.lastCallIndex, #job.callstack)
end

local current, call
local function safeCall() return call(current) end

local function DoCallback(job, callstackIndex)
	local success, shouldContinue = pcall(safeCall)
	if success then
		-- If the call returns true, the call wants to be called again
		if not shouldContinue then RemoveCall(job, callstackIndex) end
	else
		-- shouldContinue is the value returned by error or assert
		job.Error = shouldContinue
		RemoveCall(job, callstackIndex)

		call = job.onError
		if call then
			pcall(safeCall)
		else
			job:Suspend()
			error(job.Error)
		end
	end
end

local jobs = async.jobs or { }
async.jobs = jobs
-- async.registered = { }

local function DoJob(job)
	current = job
	local index = #job.callstack
	call = job.callstack[index]
	if call then
		DoCallback(job, index)
	else
		-- assert(index == 0, "No call on non-empty stack?!")
		jobs[job.name] = nil
		call = job.finally
		if call then pcall(safeCall) end
	end
	current, call = nil, nil
end

-- time we can spend until the next frame must be shown
local frameTimeTarget = GetCVar("VSYNC") == "1" and 14 or(tonumber(GetCVar("MinFrameTime.2")) * 1000)

-- we allow a function to use 25% of the frame time before it gets critical
local spendTimeDef = frameTimeTarget * 0.75
local spendTimeDefNoHUD = 15
local spendTime = spendTimeDef

local debug = false

local running
local GetFrameTimeMilliseconds, GetGameTimeMilliseconds = GetFrameTimeMilliseconds, GetGameTimeMilliseconds

local function GetThreshold()
	return(HUD_SCENE:IsShowing() or HUD_UI_SCENE:IsShowing()) and spendTimeDef or spendTimeDefNoHUD
end

local job = nil
local cpuLoad = 0
local name
local function Scheduler()
	if not running then return end

	job = nil
	local start = GetFrameTimeMilliseconds()
	local runTime, cpuLoad = start, GetGameTimeMilliseconds() - start
	if cpuLoad > spendTime then
		spendTime = math.min(30, spendTime + spendTime * 0.02)
		if debug then
			df("initial gap: %ims. skip. new threshold: %ims", GetGameTimeMilliseconds() - start, spendTime)
		end
		return
	end
	if debug then
		df("initial gap: %ims", GetGameTimeMilliseconds() - start)
	end
	while (GetGameTimeMilliseconds() - start) <= spendTime do
		name, job = next(jobs, name)
		if not job then name, job = next(jobs) end
		if job then
			runTime = GetGameTimeMilliseconds()
			DoJob(job)
			spendTime = spendTime - 0.001
		else
			-- Finished
			running = false
			spendTime = GetThreshold()
			return
		end
	end
	-- spendTime = GetThreshold()
	if debug and job then
		local now = GetGameTimeMilliseconds()
		local freezeTime = now - start
		if freezeTime >= 16 then
			runTime = now - runTime
			df("%s freeze. allowed: %ims, used %ims, resulting fps %i.", job.name, spendTime, runTime, 1000 / freezeTime)
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
	self.callstack = { }
	self.lastCallIndex = 0
	-- async.registered[#async.registered + 1] = self
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
	-- Run the given FuncOfTask in your task context execution.
	function task:Call(funcOfTask)
		self.lastCallIndex = #self.callstack + 1
		self.callstack[self.lastCallIndex] = funcOfTask
		return self:Resume()
	end

	local insert = table.insert
	-- Continue your task context execution with the given FuncOfTask after the previous as finished.
	function task:Then(funcOfTask)
		-- assert(self.lastCallIndex > 0 and self.lastCallIndex <= #self.callstack, "cap!")
		insert(self.callstack, self.lastCallIndex, funcOfTask)
		return self
	end
end

-- Start an interruptible for-loop.
function task:For(p1, p2, p3)
	-- If called as a normal job, false will prevent it is kept in callstack doing an endless loop
	self.callstack[#self.callstack + 1] = function() return false, p1, p2, p3 end
	return self
end

do
	local function ForConditionAlreadyFalse() end
	local function ContinueForward(index, endIndex) return index <= endIndex end
	local function ContinueBackward(index, endIndex) return index >= endIndex end

	local function asyncForWithStep(self, func, index, endIndex, step)
		step = step or 1
		if step == 0 then error("step is zero") end

		local ShouldContinue
		if step > 0 then
			if index > endIndex then return ForConditionAlreadyFalse end
			ShouldContinue = ContinueForward
		else
			if index < endIndex then return ForConditionAlreadyFalse end
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
		local callstackIndex = #self.callstack
		local shouldBeFalse, p1, p2, p3 = self.callstack[callstackIndex]()
		assert(shouldBeFalse == false and p1, "Do without For")
		remove(self.callstack, callstackIndex)

		local DoLoop = type(p1) == "number" and
		asyncForWithStep(self, func, p1, p2, p3) or
		asyncForPairs(self, func, p1, p2, p3)

		if current or #self.callstack == 0 then return self:Call(DoLoop) else return self:Then(DoLoop) end
	end
end

-- Suspend the execution of your task context for the given delay in milliseconds and then call the given FuncOfTask to continue.
function task:Delay(delay, funcOfTask)
	self:StopTimer()
	if delay < 10 then return self:Call(funcOfTask) end
	self:Suspend()
	em:RegisterForUpdate(self.name, delay, function()
		em:UnregisterForUpdate(self.name)
		self:Call(funcOfTask)
	end )
	return self
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

	local function simpleCompare(a, b) return a < b end
	local function sort(task, array, compare)
		local function quicksort(left, right)
			if left >= right then return end

			-- partition
			local i, j, pivot = left, right - 1, array[right]

			task:Call( function()
				while i < right and compare(array[i], pivot) do i = i + 1 end
				while j > left and not compare(array[j], pivot) do j = j - 1 end
				if i < j then
					array[i], array[j] = array[j], array[i]
					-- repeatly call this function until i >= j
					return true
				end
			end )
			task:Then( function()
				if compare(pivot, array[i]) then array[i], array[right] = array[right], array[i] end
				quicksort(left, i - 1)
				quicksort(i + 1, right)
			end )
		end
		quicksort(1, #array)
	end

	-- This sort function works like table.sort(). The compare function is optional.
	function task:Sort(array, compare)
		local sortJob = function(task) sort(task, array, compare or simpleCompare) end
		if current or #self.callstack == 0 then return self:Call(sortJob) else return self:Then(sortJob) end
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
	function Default:Cancel() error("Not allowed on default task. Use your_lib_var:Create(optional_name) for an interruptible task context.") end
	Default.Finally = Default.Cancel
	Default.OnError = Default.Cancel

	-- Start a non-interruptible task or start a nested call in the current context.
	function async:Call(funcOfTask)
		-- if async:Call is called from within a task callback (the moment where GetCurrent() is not nil) use it for nested calls
		return(async:GetCurrent() or Default):Call(funcOfTask)
	end
	-- Start a non-interruptible for-loop or start a nested for-loop in the current context.
	function async:For(p1, p2, p3)
		return(self:GetCurrent() or Default):For(p1, p2, p3)
	end

	-- Start a non-interruptible sort or start a nested sort in the current context.
	function async:Sort(array, compare)
		return(self:GetCurrent() or Default):Sort(array, compare)
	end
end

-- async.BREAK is the new 'break' for breaking loops. As Lua would not allowed the keyword 'break' in that context.
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

function async:Unload()
	HUD_SCENE:UnregisterCallback("StateChange", stateChange)
	HUD_UI_SCENE:UnregisterCallback("StateChange", stateChange)
end

em:UnregisterForUpdate(identifier)
em:RegisterForUpdate(identifier, 0, Scheduler)
