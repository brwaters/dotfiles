import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Pomodoro bar module: the Quickshell port of the old waybar custom/pomodoro.
//
// Reads the state the ~/.local/bin pomodoro-* scripts (base/bin) keep in
// $XDG_RUNTIME_DIR/omarchy-pomodoro/state: "<work|break> running <end epoch>"
// or "<work|break> paused <seconds left>"; no file means idle.
// Click starts/pauses/resumes (pomodoro-primary, also SUPER+P), right-click
// stops (pomodoro-stop, also SUPER+SHIFT+P).
//
// Placed with a { "id": "pomodoro", "type": "qml" } entry in shell.json's
// bar.layout. A user QML module, not a clone, so Omarchy updates don't touch it.
Item {
  id: root

  property var bar
  property string moduleName
  property var settings

  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")

  // Parsed state. phase is "" when idle.
  property string phase: ""
  property bool paused: false
  property int endEpoch: 0
  property int pausedSeconds: 0
  property int now: Math.floor(Date.now() / 1000)

  readonly property int remaining: phase === "" ? 0 : (paused ? pausedSeconds : Math.max(0, endEpoch - now))
  readonly property bool idle: phase === "" || remaining <= 0
  readonly property string timeText: Math.floor(remaining / 60) + ":" + String(remaining % 60).padStart(2, "0")

  // Glyphs as codepoints, never pasted characters (see CLAUDE.md).
  readonly property string idleGlyph: String.fromCodePoint(0xF254)
  readonly property string workGlyph: String.fromCodePoint(0xF051F)
  readonly property string breakGlyph: String.fromCodePoint(0xF0176)

  // The theme's red and green, falling back to the old waybar colors.
  property color workColor: "#a55555"
  property color breakColor: "#55aa55"

  function parseState(text) {
    var fields = String(text || "").trim().split(/\s+/)
    var value = parseInt(fields[2], 10)
    if ((fields[0] !== "work" && fields[0] !== "break") || !isFinite(value)) {
      root.phase = ""
      return
    }
    root.phase = fields[0]
    root.paused = fields[1] === "paused"
    if (root.paused) root.pausedSeconds = value
    else root.endEpoch = value
  }

  function parseColors(text) {
    var red = /^red\s*=\s*"(#[0-9a-fA-F]{6})"/m.exec(String(text || ""))
    var green = /^green\s*=\s*"(#[0-9a-fA-F]{6})"/m.exec(String(text || ""))
    if (red) root.workColor = red[1]
    if (green) root.breakColor = green[1]
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  FileView {
    id: stateFile
    path: root.runtimeDir + "/omarchy-pomodoro/state"
    printErrors: false
    onLoaded: root.parseState(text())
    onLoadFailed: root.phase = ""
  }

  FileView {
    path: root.stateHome + "/omarchy/current/theme/colors.toml"
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: root.parseColors(text())
  }

  // The scripts rewrite or delete the state file, so poll it rather than
  // watching a file that may not exist yet. One tick a second also drives
  // the countdown.
  Timer {
    interval: 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      root.now = Math.floor(Date.now() / 1000)
      stateFile.reload()
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.idle ? root.idleGlyph : (root.phase === "work" ? root.workGlyph : root.breakGlyph) + " " + root.timeText
    foreground: root.idle ? (root.bar ? root.bar.barForeground : Color.foreground) : (root.phase === "work" ? root.workColor : root.breakColor)
    dimmed: root.idle || root.paused
    tooltipText: root.idle
      ? "Pomodoro: click (or SUPER+P) to start a 25m session"
      : "Pomodoro: " + root.timeText + " left in " + root.phase
        + (root.paused ? " (paused; click to resume, right-click to stop)" : " (click to pause, right-click to stop)")
    onPressed: function(button) {
      if (!root.bar) return
      root.bar.run(button === Qt.RightButton ? "pomodoro-stop" : "pomodoro-primary")
    }
  }
}
