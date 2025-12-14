--- Test suite for LibAsync using Taneth framework
if not Taneth then
	return
end

-- Register the test suite
Taneth("LibAsync", function()
	-- Helper function to create a simple counter for testing
	local function createCounter()
		local count = 0
		return function()
			count = count + 1
			return count
		end
	end

	describe("Basic Task Management", function()
		it("should create a task with a name", function()
			local task = LibAsync:Create("TestTask")
			assert.is_not_nil(task)
			assert.equals(task.name, "TestTask")
		end)

		it("should get current task context", function()
			local currentTask = LibAsync:GetCurrent()
			assert.is_nil(currentTask) -- Should be nil outside of task execution
		end)

		it.async("should execute a basic task", function(done)
			local executed = false
			local task = LibAsync:Create("BasicTask")
			task:Call(function()
				executed = true
			end):Finally(function()
				assert.is_true(executed)
				done()
			end)
		end)
	end)

	describe("Sequential Tasks", function()
		it.async("should chain tasks with Call and Then", function(done)
			local step1 = false
			local step2 = false
			local step3 = false

			local task = LibAsync:Create("SequentialTask")
			task:Call(function()
				step1 = true
			end)
				:Then(function()
					step2 = true
				end)
				:Then(function()
					step3 = true
				end)
				:Finally(function()
					assert.is_true(step1)
					assert.is_true(step2)
					assert.is_true(step3)
					done()
				end)
		end)

		it.async("should handle nested Call/Then", function(done)
			local outer = false
			local inner1 = false
			local inner2 = false

			local task = LibAsync:Create("NestedTask")
			task:Call(function(task)
				outer = true
				task:Call(function()
					inner1 = true
				end):Then(function()
					inner2 = true
				end)
			end):Finally(function()
				assert.is_true(outer)
				assert.is_true(inner1)
				assert.is_true(inner2)
				done()
			end)
		end)
	end)

	describe("Loop Tasks", function()
		it.async("should handle numeric for loops", function(done)
			local sum = 0
			local task = LibAsync:Create("ForLoopTask")
			task:For(1, 5)
				:Do(function(i)
					sum = sum + i
				end)
				:Finally(function()
					assert.equals(sum, 15) -- 1+2+3+4+5
					done()
				end)
		end)

		it.async("should handle for loops with step", function(done)
			local values = {}
			local task = LibAsync:Create("StepLoopTask")
			task:For(2, 10, 2)
				:Do(function(i)
					table.insert(values, i)
				end)
				:Finally(function()
					assert.equals(#values, 5)
					assert.equals(values[1], 2)
					assert.equals(values[2], 4)
					assert.equals(values[3], 6)
					assert.equals(values[4], 8)
					assert.equals(values[5], 10)
					done()
				end)
		end)

		it.async("should handle pairs iteration", function(done)
			local result = {}
			local testTable = { a = 1, b = 2, c = 3 }
			local task = LibAsync:Create("PairsLoopTask")
			task:For(pairs(testTable))
				:Do(function(key, value)
					result[key] = value
				end)
				:Finally(function()
					assert.equals(result.a, 1)
					assert.equals(result.b, 2)
					assert.equals(result.c, 3)
					done()
				end)
		end)

		it.async("should handle ipairs iteration", function(done)
			local result = {}
			local testArray = { "first", "second", "third" }
			local task = LibAsync:Create("IpairsLoopTask")
			task:For(ipairs(testArray))
				:Do(function(index, value)
					result[index] = value
				end)
				:Finally(function()
					assert.equals(result[1], "first")
					assert.equals(result[2], "second")
					assert.equals(result[3], "third")
					done()
				end)
		end)

		it.async("should handle while loops", function(done)
			local count = 0
			local task = LibAsync:Create("WhileLoopTask")
			task:While(function()
				return count < 3
			end)
				:Do(function()
					count = count + 1
				end)
				:Finally(function()
					assert.equals(count, 3)
					done()
				end)
		end)

		it.async("should break loops with async.BREAK", function(done)
			local count = 0
			local task = LibAsync:Create("BreakLoopTask")
			task:For(1, 10)
				:Do(function(i)
					count = count + 1
					if i >= 3 then
						return LibAsync.BREAK
					end
				end)
				:Finally(function()
					assert.equals(count, 3)
					done()
				end)
		end)
	end)

	describe("Delay Tasks", function()
		it.async("should delay execution", function(done)
			local startTime = GetFrameTimeSeconds()
			local executed = false

			local task = LibAsync:Create("DelayTask")
			task:Delay(10, function() -- Use shorter delay for testing
				executed = true
				local elapsed = GetFrameTimeSeconds() - startTime
				assert.is_true(elapsed >= 0.01) -- At least 10ms
				done()
			end)
		end)

		it.async("should chain with ThenDelay", function(done)
			local step1 = false
			local step2 = false
			local startTime = GetFrameTimeSeconds()

			local task = LibAsync:Create("ThenDelayTask")
			task:Call(function()
				step1 = true
			end):ThenDelay(10, function() -- Use shorter delay for testing
				step2 = true
				local elapsed = GetFrameTimeSeconds() - startTime
				assert.is_true(step1)
				assert.is_true(step2)
				assert.is_true(elapsed >= 0.01) -- At least 10ms
				done()
			end)
		end)
	end)

	describe("WaitUntil Tasks", function()
		it.async("should wait for condition", function(done)
			local condition = false
			local executed = false

			-- Set up the condition to become true after a short delay
			zo_callLater(function()
				condition = true
			end, 5)

			local task = LibAsync:Create("WaitUntilTask")
			task:WaitUntil(function()
				return condition
			end):Then(function()
				executed = true
				assert.is_true(executed)
				done()
			end)
		end)
	end)

	describe("Error Handling", function()
		it.async("should handle errors with OnError", function(done)
			local errorHandled = false
			local errorMessage = nil

			local task = LibAsync:Create("ErrorTask")
			task:Call(function()
				error("Test error")
			end):OnError(function(task)
				errorHandled = true
				errorMessage = task.Error
				assert.is_true(errorHandled)
				-- Error message may include file/line info, just check it contains "Test error"
				assert.is_not_nil(string.find(errorMessage, "Test error", 1, true))
				done()
			end)
		end)

		it.async("should execute Finally block on success", function(done)
			local mainExecuted = false
			local finallyExecuted = false

			local task = LibAsync:Create("FinallySuccessTask")
			task:Call(function()
				mainExecuted = true
			end):Finally(function()
				finallyExecuted = true
				assert.is_true(mainExecuted)
				assert.is_true(finallyExecuted)
				done()
			end)
		end)

		it.async("should execute Finally block on error", function(done)
			local errorOccurred = false
			local finallyExecuted = false

			local task = LibAsync:Create("FinallyErrorTask")
			task
				:Call(function()
					errorOccurred = true
					error("Test error")
				end)
				:OnError(function() end) -- Suppress error logging
				:Finally(function()
					finallyExecuted = true
					assert.is_true(errorOccurred)
					assert.is_true(finallyExecuted)
					done()
				end)
		end)

		it.async("should execute Finally block on cancel", function(done)
			local finallyExecuted = false

			local task = LibAsync:Create("FinallyCancelTask")
			task:Call(function()
				-- This should never execute
				assert.fail("Should not execute")
			end):Finally(function()
				finallyExecuted = true
				assert.is_true(finallyExecuted)
				done()
			end)

			task:Cancel()
		end)
	end)

	describe("Task Control", function()
		it.async("should resume suspended task", function(done)
			local executed = false

			local task = LibAsync:Create("ResumeTask")
			task:Call(function()
				executed = true
			end):Finally(function()
				assert.is_true(executed)
				done()
			end)

			task:Suspend()
			assert.is_false(executed)

			task:Resume()
		end)

		it.async("should cancel task", function(done)
			local executed = false

			local task = LibAsync:Create("CancelTask")
			task:Call(function()
				executed = true
			end):Finally(function()
				assert.is_false(executed) -- Main task should not have executed
				done()
			end)

			task:Cancel()
		end)
	end)

	describe("Sorting", function()
		it.async("should sort array with default comparison", function(done)
			local array = { 3, 1, 4, 1, 5, 9, 2, 6 }

			local task = LibAsync:Create("SortTask")
			task:Sort(array)

			zo_callLater(function()
				assert.equals(array[1], 1)
				assert.equals(array[2], 1)
				assert.equals(array[3], 2)
				assert.equals(array[4], 3)
				assert.equals(array[5], 4)
				assert.equals(array[6], 5)
				assert.equals(array[7], 6)
				assert.equals(array[8], 9)
				done()
			end, 500)
		end)

		it.async("should sort array with custom comparison", function(done)
			local array = { 3, 1, 4, 1, 5, 9, 2, 6 }

			local task = LibAsync:Create("SortCustomTask")
			task:Sort(array, function(a, b)
				return a > b
			end):Finally(function() -- Descending
				assert.equals(array[1], 9)
				assert.equals(array[2], 6)
				assert.equals(array[3], 5)
				assert.equals(array[4], 4)
				assert.equals(array[5], 3)
				assert.equals(array[6], 2)
				assert.equals(array[7], 1)
				assert.equals(array[8], 1)
				done()
			end)
		end)
	end)

	describe("Async Static Methods", function()
		it.async("should execute Call on task instance", function(done)
			local executed = false

			local task = LibAsync:Create("CallTask")
			task:Call(function()
				executed = true
			end):Finally(function()
				assert.is_true(executed)
				done()
			end)
		end)

		it.async("should execute For loop on task instance", function(done)
			local sum = 0

			local task = LibAsync:Create("ForTask")
			task:For(1, 3)
				:Do(function(i)
					sum = sum + i
				end)
				:Finally(function()
					assert.equals(sum, 6) -- 1+2+3
					done()
				end)
		end)

		it.async("should execute While loop on task instance", function(done)
			local count = 0

			local task = LibAsync:Create("WhileTask")
			task:While(function()
				return count < 2
			end)
				:Do(function()
					count = count + 1
				end)
				:Finally(function()
					assert.equals(count, 2)
					done()
				end)
		end)

		it.async("should execute WaitUntil on task instance", function(done)
			local condition = false

			zo_callLater(function()
				condition = true
			end, 5)

			local task = LibAsync:Create("WaitUntilTask")
			task:WaitUntil(function()
				return condition
			end):Then(function()
				done()
			end)
		end)

		it.async("should execute Sort on task instance", function(done)
			local array = { 5, 2, 8, 1 }

			local task = LibAsync:Create("SortTask")
			task:Sort(array):Finally(function()
				assert.equals(array[1], 1)
				assert.equals(array[2], 2)
				assert.equals(array[3], 5)
				assert.equals(array[4], 8)
				done()
			end)
		end)
	end)

	describe("Nested Tasks and Complex Scenarios", function()
		it.async("should handle deeply nested tasks", function(done)
			local level1 = false
			local level2 = false
			local level3 = false

			local task = LibAsync:Create("NestedDeepTask")
			task:Call(function(task)
				level1 = true
				task:Call(function(task)
					level2 = true
					task:Call(function()
						level3 = true
					end)
				end)
			end):Finally(function()
				assert.is_true(level1)
				assert.is_true(level2)
				assert.is_true(level3)
				done()
			end)
		end)

		it.async("should handle loops within tasks", function(done)
			local results = {}

			local task = LibAsync:Create("LoopInTask")
			task:Call(function(task)
				task:For(1, 3):Do(function(i)
					table.insert(results, i * 2)
				end)
			end):Finally(function()
				assert.equals(#results, 3)
				assert.equals(results[1], 2)
				assert.equals(results[2], 4)
				assert.equals(results[3], 6)
				done()
			end)
		end)

		it.async("should handle delays within loops", function(done)
			local count = 0

			local task = LibAsync:Create("DelayInLoopTask")
			task:For(1, 2):Do(function(i)
				task:Delay(5, function() -- Shorter delay for testing
					count = count + 1
					if count == 2 then
						assert.equals(count, 2)
						done()
					end
				end)
			end)
		end)
	end)

	describe("Edge Cases", function()
		it("should handle empty tasks gracefully", function()
			local task = LibAsync:Create("EmptyTask")
			-- Just create and let it run without any calls
			assert.is_not_nil(task)
		end)

		it.async("should handle zero delay", function(done)
			local executed = false

			local task = LibAsync:Create("ZeroDelayTask")
			task:Delay(0, function()
				executed = true
				assert.is_true(executed)
				done()
			end)
		end)

		it.async("should handle multiple resumes", function(done)
			local executions = 0

			local task = LibAsync:Create("MultiResumeTask")
			task:Call(function()
				executions = executions + 1
			end):Finally(function()
				assert.equals(executions, 1)
				done()
			end)

			task:Suspend()
			task:Resume()
			task:Resume() -- Should be safe to call multiple times
		end)

		it("should handle canceling non-existent task", function()
			local task = LibAsync:Create("CancelNonExistentTask")
			task:Cancel() -- Should not error
			task:Cancel() -- Multiple cancels should be safe
		end)
	end)

	describe("Debug and Utility Functions", function()
		it("should set and get debug state", function()
			local originalDebug = LibAsync:GetDebug()

			LibAsync:SetDebug(true)
			assert.is_true(LibAsync:GetDebug())

			LibAsync:SetDebug(false)
			assert.is_false(LibAsync:GetDebug())

			-- Restore original state
			LibAsync:SetDebug(originalDebug)
		end)

		it("should set and get log to chat state", function()
			local originalLogToChat = LibAsync:GetLogToChat()

			LibAsync:SetLogToChat(true)
			assert.is_true(LibAsync:GetLogToChat())

			LibAsync:SetLogToChat(false)
			assert.is_false(LibAsync:GetLogToChat())

			-- Restore original state
			LibAsync:SetLogToChat(originalLogToChat)
		end)

		it("should get CPU load", function()
			local cpuLoad = LibAsync:GetCpuLoad()
			assert.is_not_nil(cpuLoad)
			assert.is_true(type(cpuLoad) == "number")
		end)
	end)

	describe("Integration Tests", function()
		it.async("should handle complex async workflow", function(done)
			local workflow = {
				initialized = false,
				dataFetched = false,
				dataProcessed = false,
				resultsSaved = false,
				cleanupDone = false,
			}

			local task = LibAsync:Create("ComplexWorkflow")

			-- Initialize
			task
				:Call(function()
					workflow.initialized = true
				end)
				-- Simulate data fetching with delay
				:ThenDelay(5, function() -- Shorter delay for testing
					workflow.dataFetched = true
				end)
				-- Process data in a loop
				:Then(function(task)
					task:For(1, 3):Do(function(i)
						-- Simulate processing each item
						workflow.dataProcessed = true
					end)
				end)
				-- Save results
				:ThenDelay(2, function() -- Shorter delay for testing
					workflow.resultsSaved = true
				end)
				-- Cleanup
				:Finally(function()
					workflow.cleanupDone = true
					assert.is_true(workflow.initialized)
					assert.is_true(workflow.dataFetched)
					assert.is_true(workflow.dataProcessed)
					assert.is_true(workflow.resultsSaved)
					assert.is_true(workflow.cleanupDone)
					done()
				end)
		end)

		it.async("should handle error recovery in complex workflow", function(done)
			local workflow = {
				started = false,
				errorOccurred = false,
				recovered = false,
				completed = false,
			}

			local task = LibAsync:Create("ErrorRecoveryWorkflow")

			task:Call(function()
				workflow.started = true
			end)
				:Then(function()
					error("Simulated workflow error")
				end)
				:OnError(function()
					workflow.errorOccurred = true
					-- Recovery action
					workflow.recovered = true
				end)
				:Then(function()
					workflow.completed = true
				end)
				:Finally(function()
					assert.is_true(workflow.started)
					assert.is_true(workflow.errorOccurred)
					assert.is_true(workflow.recovered)
					-- Should not complete due to error
					assert.is_false(workflow.completed)
					done()
				end)
		end)
	end)
end)

-- Test runner functions
local function RunAllTests()
	d("[LibAsync] Running LibAsync tests...")

	local result = Taneth:RunTestSuites({ "LibAsync" }, function()
		d("[LibAsync] LibAsync tests completed.")
	end)

	if not result then
		d("[LibAsync] No async tests were found, running synchronously...")
		-- If RunTestSuites returns nil, it means no async tests were started
		d("[LibAsync] Test execution completed.")
	end
end

local function RunSpecificTestSuite(suiteName)
	d("[LibAsync] Running test suite: " .. suiteName)

	local result = Taneth:RunTestSuite(suiteName, function()
		d("[LibAsync] Test suite '" .. suiteName .. "' completed.")
	end)

	if not result then
		d("[LibAsync] Test suite '" .. suiteName .. "' not found or completed synchronously.")
	end
end

-- Register slash commands for testing
SLASH_COMMANDS["/libasynctest"] = function(args)
	if not args or args == "" then
		RunAllTests()
	else
		RunSpecificTestSuite(args)
	end
end

SLASH_COMMANDS["/libasynctests"] = function()
	-- List available test suites
	d("[LibAsync] Available test commands:")
	d("  /libasynctest - Run all tests")
	d("  /libasynctest <suite_name> - Run specific test suite")
	d("Test suites in LibAsync_test.lua:")
	d("  - LibAsync (main test suite)")
end
