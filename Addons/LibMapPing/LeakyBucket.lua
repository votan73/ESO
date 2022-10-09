-- LibMapPing & its files © sirinsidiator                       --
-- Distributed under The Artistic License 2.0 (see LICENSE)     --
------------------------------------------------------------------

local lib = LibMapPing2
local RollingAverage = lib.internal.class.RollingAverage

local LeakyBucket = ZO_Object:Subclass()
lib.internal.class.LeakyBucket = LeakyBucket

-- emulate how the game calculates when a player should get kicked for sending too many pings and prevent it
local DEFAULT_MODIFIER = 2.15
local COMBAT_MODIFIER = 39
local FILL_RATE = 0.512
local BUCKET_SIZE = 100
local SAFETY_THRESHOLD = 10
local TIME_FRAME = 3
local RESOLUTION = 10

function LeakyBucket:New(...)
    local obj = ZO_Object.New(self)
    obj:Initialize(...)
    return obj
end

function LeakyBucket:Initialize()
    self.average = RollingAverage:New(TIME_FRAME, RESOLUTION)
    self.size = BUCKET_SIZE
    self.generatedTokens = 1 / FILL_RATE
    self.safetyThreshold = SAFETY_THRESHOLD

    self.left = self.size
    self.lastCheck = GetGameTimeMilliseconds()
end

function LeakyBucket:GetTokensLeft()
    local now = GetGameTimeMilliseconds()
    local average = self.average:GetAverage()
    local modifier = IsUnitInCombat("player") and COMBAT_MODIFIER or DEFAULT_MODIFIER
    local burstRate = average * modifier

    local delta = (now - self.lastCheck) / 1000
    self.left = math.min(self.left + delta * self.generatedTokens, self.size);
    self.lastCheck = now
    return self.left
end

function LeakyBucket:HasTokensLeft()
    return self:GetTokensLeft() > self.safetyThreshold
end

function LeakyBucket:Take()
    if(self:HasTokensLeft()) then
        self.left = self.left - 1
        self.average:Increment()
        return true
    end
    return false
end
