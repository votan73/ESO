local legacy = GetAPIVersion() < 100027

-- ToDo: Remove
if legacy then
	local orgGetScriptProfilerRecordInfo = GetScriptProfilerRecordInfo
	function GetScriptProfilerRecordInfo(...)
		local recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex = orgGetScriptProfilerRecordInfo(...)
		return recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex, SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE
	end
end

local ProfilerData = ZO_Object:Subclass()
ESO_PROFILER.ProfilerData = ProfilerData

function ProfilerData:New(...)
	local object = ZO_Object.New(self)
	object:Initialize(...)
	return object
end

function ProfilerData:Initialize(startTime, upTime)
	self.nextStackFrameId = 1
	self.frameIdLookup = { }
	if legacy then
		self.closureInfo = {
			[SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE] = { },
		}
	else
		self.closureInfo = {
			[SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE] = { },
			[SCRIPT_PROFILER_RECORD_DATA_TYPE_CFUNCTION] = { },
			[SCRIPT_PROFILER_RECORD_DATA_TYPE_GARBAGE_COLLECTION] = { },
			[SCRIPT_PROFILER_RECORD_DATA_TYPE_USER_EVENT] = { },
		}
	end
	self.events = { }
	self.stackFrames = { }
	self.frameStats = { }
	self.startTime = startTime
	self.upTime = upTime
end

function ProfilerData:GetClosureInfo(recordDataIndex, recordDataType, frameIndex, startTime)
	if(not self.closureInfo[recordDataType][recordDataIndex]) then
		local name, file, line
		local fps, latency, memory

		if recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_CLOSURE then
			name, file, line = GetScriptProfilerClosureInfo(recordDataIndex)
			fps, latency, memory = file:match("statsF(%d+)L(%d+)M(%d+)")
		else
			line = 0
			if recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_CFUNCTION then
				-- C Functions are functions defined by ZOS as part of the game's API.
				name = GetScriptProfilerCFunctionInfo(recordDataIndex)
				file = "@Client"
			elseif recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_GARBAGE_COLLECTION then
				-- At arbitrary times, the lua intepreter will automatically try to reclaim memory you are no longer using. When it does this we generate a GC event to track it.
				name = GetScriptProfilerGarbageCollectionInfo(recordDataIndex) == SCRIPT_PROFILER_GARBAGE_COLLECTION_TYPE_AUTOMATIC and "Lua GC Step" or "Manual collectgarbage() GC step"
				file = "@Lua"
			elseif recordDataType == SCRIPT_PROFILER_RECORD_DATA_TYPE_USER_EVENT then
				-- You can fire off your own custom events using RecordScriptProfilerUserEvent(myEventString). Events with the same eventString will share a recordDataIndex.
				-- Similar to console.log() of javascript or System.Diagnostics.Debug.WriteLine() of C#.
				name = GetScriptProfilerUserEventInfo(recordDataIndex)
				file = "@UserEvent"
			end
			fps = nil
		end
		if(not fps or not frameIndex) then
			self.closureInfo[recordDataType][recordDataIndex] = {
				recordDataType = recordDataType,
				info = { name, file, line },
				callCount = 0,
				wallTime = 0,
				selfTime = 0,
				minTime = math.huge,
				maxTime = 0,
				slowestRun = 0
			}
		else
			assert(not self.frameStats[frameIndex], "more than one stats entry for same frame found")
			self.frameStats[frameIndex] = {
				start = startTime,
				fps = tonumber(fps) / 100,
				latency = tonumber(latency),
				memory = tonumber(memory)
			}
		end
	end
	return self.closureInfo[recordDataType][recordDataIndex]
end

function ProfilerData:ProcessRecord(frameIndex, recordIndex)
	local recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex, recordDataType = GetScriptProfilerRecordInfo(frameIndex, recordIndex)
	local start = (startTimeNS - self.upTime) / 1000

	local closureInfo = self:GetClosureInfo(recordDataIndex, recordDataType, frameIndex, start)
	if(not closureInfo) then return end

	local duration = (endTimeNS - startTimeNS) / 1000

	local stackId, parentId
	if (calledByRecordIndex) then
		local parentRecordDataIndex, _, _, grandParentRecordIndex, parentRecordDataType = GetScriptProfilerRecordInfo(frameIndex, calledByRecordIndex)
		local calledByInfo = self:GetClosureInfo(parentRecordDataIndex, parentRecordDataType)
		calledByInfo.selfTime = calledByInfo.selfTime - duration

		stackId = self:GetStackFrameId(recordDataIndex, recordDataType, parentRecordDataIndex, parentRecordDataType)
		local grandParentDataRecordIndex, grandParentRecordDataType
		if(grandParentRecordIndex) then
			grandParentDataRecordIndex, _, _, _, grandParentRecordDataType = GetScriptProfilerRecordInfo(frameIndex, grandParentRecordIndex)
		end
		parentId = self:GetStackFrameId(parentRecordDataIndex, parentRecordDataType, grandParentDataRecordIndex, grandParentRecordDataType)
	else
		stackId = self:GetStackFrameId(recordDataIndex, recordDataType)
	end

	closureInfo.callCount = closureInfo.callCount + 1
	closureInfo.wallTime = closureInfo.wallTime + duration
	closureInfo.selfTime = closureInfo.selfTime + duration
	closureInfo.minTime = math.min(closureInfo.minTime, duration)
	if(duration > closureInfo.maxTime) then
		closureInfo.maxTime = duration
		closureInfo.slowestRun = stackId
	end
	self.events[#self.events + 1] = { start, duration, stackId }
	self.stackFrames[stackId] = { recordDataIndex, recordDataType, parentId }
end

function ProfilerData:GetStackFrameId(recordDataIndex, recordDataType, parentRecordDataIndex, parentRecordDataType)
	local key = string.format(parentRecordDataIndex and "%d_%d_%d_%d" or "%d_%d", recordDataIndex, recordDataType, parentRecordDataIndex, parentRecordDataType)
	if (not self.frameIdLookup[key]) then
		self.frameIdLookup[key] = self.nextStackFrameId
		self.nextStackFrameId = self.nextStackFrameId + 1
	end
	return self.frameIdLookup[key]
end

function ProfilerData:GetClosureInfoList()
	return self.closureInfo
end

function ProfilerData:GetClosureByStackId(stackId)
	local recordDataIndex, recordDataType, parentId = unpack(self.stackFrames[stackId])
	return self.closureInfo[recordDataType][recordDataIndex], parentId
end

local function GetEmptySaveData(startTime, upTime)
	local events = { }
	local stackFrames = { }
	local closures = { }
	local frameStats = { }
	local data = {
		traceEvents = events,
		stackFrames = stackFrames,
		closures = closures,
		frameStats = frameStats,
		otherData =
		{
			startTime = startTime,
			upTime = string.format("%.3f",upTime / 1000),
			version = GetESOVersionString(),
		}
	}
	return data, events, stackFrames, closures, frameStats
end
ESO_PROFILER.GetEmptySaveData = GetEmptySaveData

function ProfilerData:Export(task)
	local data, events, stackFrames, closures, frameStats = GetEmptySaveData(self.startTime, self.upTime)
	task:For(1, #self.events):Do( function(i)
		events[i] = string.format("%.3f,%.3f,%d", unpack(self.events[i]))
	end )
	task:For(pairs(self.stackFrames)):Do( function(id, frame)
		local recordDataIndex, recordDataType, parentId = unpack(frame)
		if (parentId) then
			stackFrames[id] = string.format("%d,%d", recordDataIndex * 10 + recordDataType, parentId)
		else
			stackFrames[id] = string.format("%d", recordDataIndex * 10 + recordDataType)
		end
	end )
	task:For(pairs(self.closureInfo)):Do( function(recordDataType, recordTable)
		task:For(pairs(recordTable)):Do( function(recordDataIndex, closureInfo)
			local name, file, line = unpack(closureInfo.info)
			closures[recordDataIndex * 10 + recordDataType] = string.format("%s,%s,%d", name, file, line)
		end )
	end )
	task:For(pairs(self.frameStats)):Do( function(frameIndex, stats)
		frameStats[frameIndex] = string.format("%.3f,%d,%d,%d", stats.start, stats.fps, stats.latency, stats.memory)
	end )
	-- return immediately with an empty list to be filled
	return data
end
