local LogTimerBar = ZO_TimerBar:Subclass()
local LOG2 = 0.6931471805599453
merCharacterSheet.LogTimerBar = LogTimerBar


function LogTimerBar:New(control)
    local bar = ZO_TimerBar.New(self, control)
    local linearSetValue = bar.status.SetValue

    local function logSetValue(status, value)
        local min, max = status:GetMinMax()
        if value <= min then
            linearSetValue(status, min)
        elseif value >= max then
            linearSetValue(status, max)
        else
            local logval = math.log(1 + (value - min) / 60)
            local logmax = math.log(1 + (max - min) / 60)
            linearSetValue(status, min + (max - min) * logval / logmax)
            -- update interval needs to get shorter as time elapses,
            -- at 1 minute remaining the interval will be 2 seconds
            bar.barUpdateInterval = 1 + logval / LOG2
        end
    end

    bar.status.SetValue = logSetValue
    return bar
end


function LogTimerBar:Stop()
    if not self:IsStarted() then
        return
    end
    ZO_TimerBar.Stop(self)
    if self.onStop then
        self:onStop()
    end
end
