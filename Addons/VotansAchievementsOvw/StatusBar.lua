--- Add pooled status bar to AchievementTooltip --
function AchievementTooltip:VotanAddStatusBar()
  if not self.votanStatusBarPool then
    local statusBarPool = ZO_ControlPool:New(GetAPIVersion() <= 100022 and "ZO_AchievementsAchievementStatusBar" or "ZO_AchievementsStatusBar", self, "VotanAchievementStatusBar")
    statusBarPool:SetCustomFactoryBehavior(function(control)
      control.label = control:GetNamedChild("Label")
      control.progress = control:GetNamedChild("Progress")
      ZO_StatusBar_SetGradientColor(control, ZO_XP_BAR_GRADIENT_COLORS)

      control:GetNamedChild("BGLeft"):SetDrawLevel(2)
      control:GetNamedChild("BGRight"):SetDrawLevel(2)
      control:GetNamedChild("BGMiddle"):SetDrawLevel(2)
    end)
    self.votanStatusBarPool = statusBarPool
    ZO_PreHookHandler(AchievementTooltip, "OnCleared", function(...) AchievementTooltip:VotanClearStatusBars() return false end)
  end

  local statusBar = self.votanStatusBarPool:AcquireObject()

  if statusBar then
    self:AddControl(statusBar)
    statusBar:SetAnchor(CENTER)
  end
  return statusBar
end

function AchievementTooltip:VotanClearStatusBars()
  if self.votanStatusBarPool then
    self.votanStatusBarPool:ReleaseAllObjects()
  end
end
