if GetAPIVersion() < 100025 then return end

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
	self.closureInfo = { }
	self.events = { }
	self.stackFrames = { }
	self.frameStats = { }
	self.startTime = startTime
	self.upTime = upTime
end

function ProfilerData:GetClosureInfo(recordDataIndex, frameIndex, startTime)
	if(not self.closureInfo[recordDataIndex]) then
		local name, file, line = GetScriptProfilerClosureInfo(recordDataIndex)
		local fps, latency, memory = file:match("statsF(%d+)L(%d+)M(%d+)")
		if(not fps or not frameIndex) then
			self.closureInfo[recordDataIndex] = {
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
	return self.closureInfo[recordDataIndex]
end

function ProfilerData:ProcessRecord(frameIndex, recordIndex)
	local recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex = GetScriptProfilerRecordInfo(frameIndex, recordIndex)
	local start = (startTimeNS - self.upTime) / 1000

	local closureInfo = self:GetClosureInfo(recordDataIndex, frameIndex, start)
	if(not closureInfo) then return end

	local duration = (endTimeNS - startTimeNS) / 1000

	local stackId, parentId
	if (calledByRecordIndex) then
		local parentRecordDataIndex, _, _, grandParentRecordIndex = GetScriptProfilerRecordInfo(frameIndex, calledByRecordIndex)
		local calledByInfo = self:GetClosureInfo(parentRecordDataIndex)
		calledByInfo.selfTime = calledByInfo.selfTime - duration

		stackId = self:GetStackFrameId(recordDataIndex, parentRecordDataIndex)
		local grandParentDataRecordIndex
		if(grandParentRecordIndex) then
			grandParentDataRecordIndex = GetScriptProfilerRecordInfo(frameIndex, grandParentRecordIndex)
		end
		parentId = self:GetStackFrameId(parentRecordDataIndex, grandParentDataRecordIndex)
	else
		stackId = self:GetStackFrameId(recordDataIndex)
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
	self.stackFrames[stackId] = { recordDataIndex, parentId }
end

function ProfilerData:GetStackFrameId(recordDataIndex, parentRecordDataIndex)
	local key = string.format("%d_%d", recordDataIndex, parentRecordDataIndex or 0)
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
	local recordDataIndex, parentId = unpack(self.stackFrames[stackId])
	return self.closureInfo[recordDataIndex], parentId
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
		local recordDataIndex, parentId = unpack(frame)
		if (parentId) then
			stackFrames[id] = string.format("%d,%d", recordDataIndex, parentId)
		else
			stackFrames[id] = string.format("%d", recordDataIndex)
		end
	end )
	task:For(pairs(self.closureInfo)):Do( function(recordDataIndex, closureInfo)
		local name, file, line = unpack(closureInfo.info)
		closures[recordDataIndex] = string.format("%s,%s,%d", name, file, line)
	end )
	task:For(pairs(self.frameStats)):Do( function(frameIndex, stats)
		frameStats[frameIndex] = string.format("%.3f,%d,%d,%d", stats.start, stats.fps, stats.latency, stats.memory)
	end )
	-- return immediately with an empty list to be filled
	return data
end
