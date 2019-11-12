--- === PassAutoType ===
---
--- Provides a function to automatically type the username and password into the current (browser) window, retrieved from the pass password store

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "PassAutotype"
obj.version = "1.1"
obj.author = "Wolfgang Schnerring <wosc@wosc.de>"
obj.homepage = "https://github.com/wosc/pass-autotype"
obj.license = "BSD - https://opensource.org/licenses/BSD-3-Clause"

obj.USER_FIELD = "^login:"
obj.AUTOTYPE_FIELD = "^autotype:"
obj.AUTOTYPE_DEFAULT = ":user |Tab :password |Return"
obj.BASENAME = "^(.*)/([^/]*)$"


--- ReloadConfiguration:bindHotkeys(mapping)
--- Method
--- Binds hotkeys for ReloadConfiguration
---
--- Parameters:
---  * mapping - A table containing hotkey modifier/key details for the following items:
---   * autotype
function obj:bindHotKeys(mapping)
   local def = {autotype = hs.fnutils.partial(self.autotype, self)}
   hs.spoons.bindHotkeysToSpec(def, mapping)
end

function obj:autotype()
    local window = hs.window.focusedWindow()
    local window_title = window:title()

    -- If `pass find` didn't insist on using `tree` for output,
    -- we wouldn't have to do this ourselves, sigh.
    -- XXX No idea why a simple "echo $PASSWORD_STORE_DIR" does not work.
    local password_store_dir = string.gsub(hs.execute(
       "set | sed -ne '/^PASSWORD_STORE_DIR/s/.*[ =]//p'", true), "\n", "")
    if password_store_dir == "" then
       password_store_dir = os.getenv("HOME") .. "/.password-store"
    end
    local entries = hs.execute(
        'find ' .. password_store_dir .. ' -type f -name "*.gpg" | sort')
    local matches = {}
    for entry in string.gmatch(entries, "([^\n]*)") do
        if entry ~= "" then
           entry = string.sub(entry, 0, -5)  -- cut off '.gpg' extension
           local entry_name = string.gsub(entry, self.BASENAME, "%2")
           -- patterns don't seem to support escaping their magic characters,
           -- so we replace them with "any char" instead.
           entry_name = string.gsub(entry_name, '-', '.')
           if string.match(window_title, entry_name) then
              matches[#matches + 1] = string.gsub(entry, password_store_dir .. '/', '')
           end
        end
    end

    if #matches == 1 then
       self:execute(self:readEntry(matches[1]))
    else
       entries = {}
       for i = 1, #matches do
          local entry = self:readEntry(matches[i])
          entry["text"] = entry["group"] .. " / " .. entry["name"]
          entry["subText"] = entry["user"]
          entries[#entries + 1] = entry
       end

       local chooser = hs.chooser.new(hs.fnutils.partial(self.chooserDone, self))
       chooser:choices(entries)
       chooser:rows(#entries)
       chooser:show()
    end
end


function obj:chooserDone(entry)
   if entry then
      self:execute(entry)
   end
end


function obj:execute(entry)
    for item in string.gmatch(entry["autotype"], "([^ ]*)") do
       local typ = string.sub(item, 0, 1)
       local arg = string.sub(item, 2)
       if typ == ":" then
          hs.eventtap.keyStrokes(entry[arg])
       elseif typ == "|" then
          -- XXX lower() suffices for xdotool compatibility for "Tab" and "Return".
          hs.eventtap.keyStroke(nil, string.lower(arg))
       elseif typ == "!" then
          hs.timer.usleep(arg * 1000)
       end
    end
end


function obj:readEntry(name)
   local data = hs.execute("pass show " .. name, true)
   local user = nil
   local password = nil
   local autotype = self.AUTOTYPE_DEFAULT
   local i = 0
   for line in string.gmatch(data, "([^\n]*)") do
      if i == 0 then
         password = line
      elseif string.match(line, self.USER_FIELD) then
         user = string.gsub(line, self.USER_FIELD, "", 1)
      elseif string.match(line, self.AUTOTYPE_FIELD) then
         autotype = string.gsub(line, self.AUTOTYPE_FIELD, "", 1)
      end
      i = i + 1
   end
   return {
      group = string.gsub(name, self.BASENAME, "%1"),
      name = string.gsub(name, self.BASENAME, "%2"),
      password = password,
      user = user,
      autotype = autotype,
   }
end

return obj
