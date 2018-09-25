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
	self.frameIdLookup = {}
	self.events = {}
	self.stackFrames = {}
	self.startTime = startTime
	self.upTime = upTime
end

function ProfilerData:ProcessRecord(frameIndex, recordIndex)
	local recordDataIndex, startTimeNS, endTimeNS, calledByRecordIndex = GetScriptProfilerRecordInfo(frameIndex, recordIndex)
	local name, filename, lineDefined = GetScriptProfilerClosureInfo(recordDataIndex)

	local strackId = self:GetStackFrameId(frameIndex, recordDataIndex)
	local stackFrame = {name, filename, lineDefined}
	if(calledByRecordIndex) then
		stackFrame[#stackFrame] = self:GetStackFrameId(frameIndex, calledByRecordIndex)
	end
	self.stackFrames[strackId] = stackFrame

	local start = (startTimeNS - self.upTime) / 1000
	local duration = (endTimeNS - startTimeNS) / 1000
	self.events[#self.events + 1] = {start, duration, strackId}
end

function ProfilerData:GetStackFrameId(frameIndex, recordIndex)
	local key = string.format("%d_%d", frameIndex, recordIndex)
	if(not self.frameIdLookup[key]) then
		self.frameIdLookup[key] = self.nextStackFrameId
		self.nextStackFrameId = self.nextStackFrameId + 1
	end
	return self.frameIdLookup[key]
end

local function GetEmptySaveData(startTime, upTime)
	local events = {}
	local stackFrames = {}
	local data = {
		traceEvents = events,
		stackFrames = stackFrames,
		otherData = {
			startTime = startTime,
			upTime = string.format("%.3f", upTime / 1000),
			version = GetESOVersionString(),
		}
	}
	return data, events, stackFrames
end
ESO_PROFILER.GetEmptySaveData = GetEmptySaveData

function ProfilerData:Export()
	local data, events, stackFrames = GetEmptySaveData(self.startTime, self.upTime)
	for i = 1, #self.events do
		events[i] = string.format("%.3f,%.3f,%d", unpack(self.events[i]))
	end
	for id, frame in pairs(self.stackFrames) do
		if(#frame == 4) then
			stackFrames[id] = string.format("%s,%s,%d,%d", unpack(frame))
		else
			stackFrames[id] = string.format("%s,%s,%d", unpack(frame))
		end
	end
	return data
end
