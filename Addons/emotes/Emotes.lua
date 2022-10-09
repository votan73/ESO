local function ShowEmotes(withInput)
  local list = {}
  local num = GetNumEmotes()
  if (withInput == nil) then
    for i = 1,num do
      list[i] = GetEmoteSlashNameByIndex(i)
    end
  else
    local t = 0
    for i = 1,num do
      local emote = GetEmoteSlashNameByIndex(i)
      if (string.find(emote, withInput) ~= nil) then
        t = t + 1
        list[t] = emote
      end
    end
    num = t
  end
  
  table.sort(list)
  for i=1,num do
    d(list[i])
  end
  
end

SLASH_COMMANDS["/emotes"] = ShowEmotes

