import std/options

type
  Direction* = enum
    ## Layout direction for widget's children
    Horizontal, Vertical

type
  Alignment* = enum
    ## Alignment options for widget's children
    AlignLeft,
    AlignRight,
    AlignTop,
    AlignBottom,
    AlignCenter

type
  # Nim is a bum and makes me explicitly make each variable public with a *
  # Even though it's an object, freaking Nim sucks but it's also awesome
  # I will not let you PR this out of the code cuz im spitting bars yo
  Widget* = ref object of RootObj
    ## Widget object, all widgets are based on this object.
    ## Never make widgets solely with this object, use `createWidget`.
    ## Although x and y positions are public, you should not use them,
    ## Instead you should let `layoutWidgets` in render.nim do the hard work.
    identifier*: string
    name*: string
    data*: string
    disabled*: bool
    x*: int
    y*: int
    width*: int
    height*: int
    align*: Alignment
    inline*: bool
    hexpand*: bool
    vexpand*: bool
    direction*: Direction
    onclick*: proc (widget: Widget) {.nimcall.}
    parent*: Widget
    children*: seq[Widget]

type
  ## Widget defaults object, used basically as a dictionary.
  WidgetDefaults = object
    disabled: bool
    width: int
    height: int
    hexpand: bool
    vexpand: bool

proc widgetDefaults(identifier: string): WidgetDefaults =
  ## Get default attributes for a specified widget.
  case identifier
  of "button":
    result = WidgetDefaults(
      disabled: false,
      width: 72,
      height: 32,
      hexpand: false,
      vexpand: false
    )
  of "box":
    result = WidgetDefaults(
      disabled: false,
      width: 0,
      height: 0,
      hexpand: false,
      vexpand: false
    )
  else:
    result = WidgetDefaults(
      disabled: false,
      width: 0,
      height: 0,
      hexpand: false,
      vexpand: false
    )

proc createWidget*(
    parent: Widget = nil;
    identifier: string = "widget";
    name: string = "";
    data: string = "";
    width: Option[int] = none(int);
    height: Option[int] = none(int);
    align: Alignment = AlignCenter;
    inline: bool = false;
    hexpand: Option[bool] = none(bool);
    vexpand: Option[bool] = none(bool);
    direction: Direction = Vertical;
    onclick: proc (widget: Widget) {.nimcall.} = nil;
    disabled: Option[bool] = none(bool)
  ): Widget =
  ## Creates a widget and automatically applies defaults if no value was passed.
  result = Widget()
  result.identifier = identifier
  result.parent = parent
  result.name = name
  result.data = data
  result.children = @[]
  result.x = 0
  result.y = 0
  result.direction = direction
  result.align = align
  result.inline = inline

  let defaults = widgetDefaults(identifier)

  # Use user value if provided, otherwise fallback to default
  result.width = if width.isSome: width.get() else: defaults.width
  result.height = if height.isSome: height.get() else: defaults.height
  result.hexpand = if hexpand.isSome: hexpand.get() else: defaults.hexpand
  result.vexpand = if vexpand.isSome: vexpand.get() else: defaults.vexpand
  result.disabled = if disabled.isSome: disabled.get() else: defaults.disabled
  result.onclick = onclick

  if parent != nil:
    parent.children.add(result)

proc createRoot*(): Widget =
  ## Creates root widget and therefore the widget tree.
  result = createWidget(
    identifier = "root",
    width = some(640),
    height = some(480),
    hexpand = some(true),
    vexpand = some(true)
  )

proc containsPoint*(widget: Widget, px: int, py: int): bool =
  ## Checks if a widget contains a point.
  if widget.isNil:
    return false

  result =
    px >= widget.x and
    py >= widget.y and
    px < widget.x + widget.width and
    py < widget.y + widget.height

proc findWidgetAt*(widget: Widget, px: int, py: int): Widget =
  ## Finds widget at specified point, 
  ## returns nil if no widget is found.
  if widget.isNil or not containsPoint(widget, px, py):
    return nil

  for i in countdown(widget.children.high, 0):
    let found = findWidgetAt(widget.children[i], px, py)
    if not found.isNil:
      return found

  return widget