import std/options
import mutk

let root = mutk.createRoot()
root.direction = Horizontal

let sidebar = mutk.createWidget(
  parent = root,
  identifier = "box",
  direction = Vertical,
  vexpand = some(true),
  align=AlignTop
)

discard mutk.createWidget(
  parent = sidebar,
  identifier = "button"
)

discard mutk.createWidget(
  parent = sidebar,
  identifier = "button"
)

discard mutk.createWidget(
  parent = sidebar,
  identifier = "button"
)

let content = mutk.createWidget(
  parent = root,
  identifier = "box",
  hexpand = some(true),
  vexpand = some(true)
)

discard mutk.createWidget(
  parent = content,
  align = AlignCenter,
  identifier = "button",
)

discard mutk.start(root)