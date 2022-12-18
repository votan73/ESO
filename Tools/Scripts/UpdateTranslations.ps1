$client = [System.Net.WebClient]::new()

function update($url, $title, $path)
{
    $title
    $text = [System.Text.Encoding]::UTF8.GetString($client.DownloadData($url))
    [System.IO.File]::WriteAllText($path, $text, [System.Text.Encoding]::UTF8)
}

update -url "https://pastebin.com/raw/MXkN8fW9" -title "Votan's Achievements Overview" -path "Z:\live\AddOns\VotansAchievementsOvw\VotansAchievementFavorites\lang\fr.lua"
update -url "https://pastebin.com/raw/RwRZ2g2Z" -title "Votan's Addon List" -path "Z:\live\AddOns\LibVotansAddonList\lang\fr.lua"
update -url "https://pastebin.com/raw/28anSAZG" -title "Votan's Advanced Settings" -path "Z:\live\AddOns\VotansAdvancedSettings\lang\fr.lua"
update -url "https://pastebin.com/raw/unSPhxhk" -title "Votan's Collectible Most Recently Used" -path "Z:\live\AddOns\VotansCollectibleMRU\lang\fr.lua"
update -url "https://pastebin.com/raw/uJc1MN2u" -title "Votan's Fish Fillet" -path "Z:\live\AddOns\VotansFishFillet\lang\fr.lua"
update -url "https://pastebin.com/raw/iY5jWcb2" -title "Votan's Group Pins " -path "Z:\live\AddOns\VotansGroupPins\lang\fr.lua"
update -url "https://pastebin.com/raw/GdRtdXpY" -title "Votan's Housing Filter" -path "Z:\live\AddOns\VotansHousingFilter\lang\fr.lua"
update -url "https://pastebin.com/raw/ZPzCPeYa" -title "Votan's Improved Locations" -path "Z:\live\AddOns\VotansImprovedLocations\lang\fr.lua"
update -url "https://pastebin.com/raw/knaufCiB" -title "Votan's Improved Outfit Station" -path "Z:\live\AddOns\VotansImprovedOutfit\lang\fr.lua"
update -url "https://pastebin.com/raw/thixfkV4" -title "Votan's Improved Sets Book" -path "Z:\live\AddOns\VotansImprovedSetsBook\lang\fr.lua"
update -url "https://pastebin.com/raw/f4EQDmah" -title "Votan's Keybinder" -path "Z:\live\AddOns\VotansKeybinder\lang\fr.lua"
update -url "https://pastebin.com/raw/up3rLrfK" -title "Votan's Lore Library Search" -path "Z:\live\AddOns\VotansLoreLibrarySearch\lang\fr.lua"
update -url "https://pastebin.com/raw/AKX2TvcV" -title "Votan's Map Pin Colors" -path "Z:\live\AddOns\VotansMapPinColors\lang\fr.lua"
update -url "https://pastebin.com/raw/hv41EHRQ" -title "Votan's Minimap" -path "Z:\live\AddOns\VotansMiniMap\lang\fr.lua"
update -url "https://pastebin.com/raw/AYsVkKEL" -title "Votan's Rune Tooltips" -path "Z:\live\AddOns\VotansRuneTooltips\lang100015\fr.lua"
update -url "https://pastebin.com/raw/kbSwDVJZ" -title "Votan's Settings Menu" -path "Z:\live\AddOns\VotansSettingsMenu\lang\fr.lua"
update -url "https://pastebin.com/raw/ktA0iXvC" -title "Votan's Tamriel Map" -path "Z:\live\AddOns\VotansTamrielMap\lang\fr.lua"
update -url "https://pastebin.com/raw/VKt3Jnq5" -title "Votan's Vendor Set Tooltip" -path "Z:\live\AddOns\VotansVendorSetTooltip\lang\fr.lua"
