-- Global workspaces: keep the pre-4.5 behavior where workspace 3 is workspace 3
-- on every monitor, instead of 4.5's per-monitor blocks (laptop panel 1-10,
-- next monitor 11-20, ...; see default/hypr/monitor-workspaces.lua).
--
-- There's no flag to turn the blocks off -- omarchy.lua requires
-- monitor-workspaces unconditionally -- so this replaces its pieces instead.
-- Pairs with the recon.workspaces bar widget clone, which shows the same
-- global 1-10 on every bar.

local W = o.workspaces

-- Same as monitor-workspaces' own helper: lets the keybindings menu replay a
-- function bind as `hyprctl dispatch <expression>`.
local function action(fn, expression)
  o.bind_expressions[fn] = expression
  return fn
end

-- Stop the renumbering. Its start/reload/monitor-added/removed handlers look
-- up W.reconcile at call time, so replacing it here disarms all of them.
W.reconcile = function() end

-- Replaced (not just rebound) so anything else dispatching
-- o.workspaces.focus(...) -- the keybindings menu, or the stock bar widget if
-- a reset ever puts it back -- gets the global version too. The stock focus
-- also pulls the workspace onto the focused monitor; this just focuses it
-- wherever it lives, as Hyprland does natively.
function W.focus(slot)
  return action(function()
    hl.dispatch(hl.dsp.focus({ workspace = tostring(slot) }))
  end, "o.workspaces.focus(" .. slot .. ")")
end

function W.move_window(slot, follow)
  return action(function()
    hl.dispatch(hl.dsp.window.move({ workspace = tostring(slot), follow = follow ~= false }))
  end, "o.workspaces.move_window(" .. slot .. (follow == false and ", false" or "") .. ")")
end

-- Plain move, keeping the workspace's number (stock renumbers it into the
-- target monitor's block).
function W.move_to_monitor(direction)
  return action(function()
    -- Hyprland reports a move toward no monitor as an error on screen.
    local target = hl.get_monitor(direction)
    if target then
      hl.dispatch(hl.dsp.workspace.move({ monitor = target.name }))
    end
  end, "o.workspaces.move_to_monitor(" .. string.format("%q", direction) .. ")")
end

-- The stock binds captured the old functions when tiling.lua ran, so rebind
-- them to the replacements.
for workspace = 1, 10 do
  local key = "code:" .. tostring(workspace + 9)
  o.rebind("SUPER + " .. key, "Switch to workspace " .. workspace, W.focus(workspace))
  o.rebind("SUPER + SHIFT + " .. key, "Move window to workspace " .. workspace, W.move_window(workspace))
  o.rebind("SUPER + SHIFT + ALT + " .. key, "Move window silently to workspace " .. workspace, W.move_window(workspace, false))
end

for _, dir in ipairs({ { "LEFT", "l", "left" }, { "RIGHT", "r", "right" }, { "UP", "u", "up" }, { "DOWN", "d", "down" } }) do
  o.rebind("SUPER + SHIFT + ALT + " .. dir[1], "Move workspace to " .. dir[3] .. " monitor", W.move_to_monitor(dir[2]))
end
