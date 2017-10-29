
do
	local orgCalculateConstraints = SharedChatContainer.CalculateConstraints
	function SharedChatContainer.CalculateConstraints(...)
		local self = ...
		local w, h = GuiRoot:GetDimensions()
		self.system.maxContainerWidth, self.system.maxContainerHeight = w * 0.75, h * 0.75
		return orgCalculateConstraints(...)
	end
end