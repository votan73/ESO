local strings = {
    SI_HARVEN_CWP_WORLD_PINS = "World Pins",
    SI_HARVEN_CWP_WORLD_PIN_SIZE = "World pin size",
    SI_HARVEN_CWP_DISTANCE = "Distance",
    SI_HARVEN_CWP_DISTANCE_TOOLTIP = "If you have performance issues reducing the distance may helps. High distance with depth-buffer on is sometimes a bit exaggerated.",
    SI_HARVEN_CWP_USE_DEPTH_BUFFER = "Use depth-buffer",
    SI_HARVEN_CWP_USE_DEPTH_BUFFER_TOOLTIP = "Turn it off to see through walls and floors. You will see tricks and tweaks of level design as well.",
    SI_HARVEN_CWP_ROTATE_PINS = "Rotate pins",
    SI_HARVEN_CWP_ROTATE_PINS_TOOLTIP = "Turn it on to animate the pins for better visibility."
}

for stringId, stringValue in pairs(strings) do
    ZO_CreateStringId(stringId, stringValue)
    SafeAddVersion(stringId, 1)
end
