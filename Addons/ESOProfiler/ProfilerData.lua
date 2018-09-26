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
	self.startTime = startTime
	self.upTime = upTime
end

function ProfilerData:GetClosureInfo(recordDataIndex)
	if(not self.closureInfo[recordDataIndex]) then
		self.closureInfo[recordDataIndex] = {
			info = { GetScriptProfilerClosureInfo(recordDataIndex) },
			callCount = 0,
			wallTime = 0,
			selfTime = 0,
			maxTime = 0
		}
	end
	return self.closureInfo[recordDataIndex]
end

function ProfilerData:ProcessRecord(frameIndex, recordIndex)
	local recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex = GetScriptProfilerRecordInfo(frameIndex, recordIndex)
	local closureInfo = self:GetClosureInfo(recordDataIndex)
	local start = (startTimeNS - self.upTime) / 1000
	local duration = (endTimeNS - startTimeNS) / 1000
	closureInfo.callCount = closureInfo.callCount + 1
	closureInfo.wallTime = closureInfo.wallTime + duration
	closureInfo.selfTime = closureInfo.selfTime + duration
	closureInfo.maxTime = math.max(closureInfo.maxTime, duration)

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

local function GetEmptySaveData(startTime, upTime)
	local events = { }
	local stackFrames = { }
	local closures = { }
	local data = {
		traceEvents = events,
		stackFrames = stackFrames,
		closures = closures,
		otherData =
		{
			startTime = startTime,
			upTime = string.format("%.3f",upTime / 1000),
			version = GetESOVersionString(),
		}
	}
	return data, events, stackFrames, closures
end
ESO_PROFILER.GetEmptySaveData = GetEmptySaveData

function ProfilerData:Export(task)
	local data, events, stackFrames, closures = GetEmptySaveData(self.startTime, self.upTime)
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
	-- return immediately with an empty list to be filled
	return data
end
