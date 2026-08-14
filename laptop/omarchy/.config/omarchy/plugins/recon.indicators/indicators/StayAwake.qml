import QtQuick
import qs.Ui

BarIndicator {
  id: root

  // Looks up the idle service by its own id rather than "omarchy.idle" --
  // service lookups don't follow a clone's clonedFrom manifest field (that's
  // only used for IPC target routing), so once recon.idle replaced
  // omarchy.idle this hardcoded id returned null and Stay Awake went dead.
  readonly property var idleService: bar?.shell?.firstPartyServiceFor("recon.idle")

  active: idleService ? idleService.stayAwake : false
  activeText: "󰅶"
  inactiveText: "󰅶"
  activeTooltipText: "Allow Idle Lock & Screensaver"
  inactiveTooltipText: "Stay Awake"

  function toggle() {
    if (root.idleService) root.idleService.setIdleEnabled(root.active)
  }

  onPressed: function() { root.toggle() }
}
