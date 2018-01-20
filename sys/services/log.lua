_G.requireInjector(_ENV)

--[[
  Adds a task and the control-d hotkey to view the kernel log.
--]]

local kernel     = _G.kernel
local keyboard   = _G.device.keyboard
local multishell = _ENV.multishell
local os         = _G.os
local term       = _G.term

if multishell then
  multishell.setTitle(multishell.getCurrent(), 'System Log')
end

local w, h = kernel.window.getSize()
kernel.window.reposition(1, 2, w, h - 1)

local routine = kernel.getCurrent()
routine.terminal = kernel.window
routine.window = kernel.window
term.redirect(kernel.window)

local previousId

kernel.hook('mouse_scroll', function(_, eventData)
  local dir, y = eventData[1], eventData[3]

  if y > 1 then
    local currentTab = kernel.getFocused()
    if currentTab.terminal.scrollUp and not currentTab.terminal.noAutoScroll then
      if dir == -1 then
        currentTab.terminal.scrollUp()
      else
        currentTab.terminal.scrollDown()
      end
    end
  end
end)

keyboard.addHotkey('control-d', function()
  local current = kernel.getFocused()
  if current.uid ~= routine.uid then
    previousId = current.uid
    kernel.raise(routine.uid)
  elseif previousId then
    kernel.raise(previousId)
  end
end)

os.pullEventRaw('terminate')
keyboard.removeHotkey('control-d')
