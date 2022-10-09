-- LibMapPing & its files © sirinsidiator                       --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibMapPing2

local RollingAverage = ZO_Object:Subclass()
lib.internal.class.RollingAverage = RollingAverage

function RollingAverage:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function RollingAverage:Initialize(timeframe, resolution)
    self.timeframe = timeframe
    self.resolution = resolution
    self.count = timeframe * resolution
    self.sumList = {}
    self.lastIndex = self:GetCurrentIndex()

    for i = 1, self.count do
        self.sumList[i] = 0
    end
end

function RollingAverage:GetCurrentIndex()
    return math.floor(self.resolution * GetGameTimeMilliseconds() / 1000) % self.count
end

function RollingAverage:Increment()
    local index = self:GetCurrentIndex()
    while self.lastIndex ~= index do
        self.lastIndex = (self.lastIndex + 1) % self.count
        self.sumList[self.lastIndex] = 0
    end
    self.sumList[index] = self.sumList[index] + 1
end

function RollingAverage:GetAverage()
    local index = self:GetCurrentIndex()
    local average = 0
    for i = 1, self.count do
        if(i ~= index) then
            average = average + self.sumList[i]
        end
    end
    return math.floor(average / (self.count - 1) * self.resolution)
end
