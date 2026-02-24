import std/options

type
  # Nim is a bum and makes me explicitly make each variable public with a *
  # Even though it's an object, freaking Nim sucks but it's also awesome
  # I will not let you PR this out of the code cuz im spitting bars yo
  Widget* = ref object of RootObj
    ## Widget object, all widgets are based on this object.
    ## Never make widgets solely with this object, use `createWidget`.
    identifier*: string
    name*: string
    data*: string
    disabled*: bool
    width*: int
    height*: int
    align*: string
    hexpand*: bool
    vexpand*: bool
    parent*: Widget
    children*: seq[Widget]


type
  ## Widget defaults object, used basically as a dictionary.
  WidgetDefaults = object
    disabled: bool
    width: int
    height: int
    align: string
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
      align: "center",
      hexpand: false,
      vexpand: false
    )
  else:
    result = WidgetDefaults(
      disabled: false,
      width: 0,
      height: 0,
      align: "auto",
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
    align: Option[string] = none(string);
    hexpand: Option[bool] = none(bool);
    vexpand: Option[bool] = none(bool);
    disabled: Option[bool] = none(bool)
  ): Widget =
  ## Creates a widget and automatically applies defaults if no value was passed
  result = Widget()
  result.identifier = identifier
  result.parent = parent
  result.name = name
  result.data = data
  result.children = @[]

  let defaults = widgetDefaults(identifier)

  # Use user value if provided, otherwise fallback to default
  result.width = if width.isSome: width.get() else: defaults.width
  result.height = if height.isSome: height.get() else: defaults.height
  result.align = if align.isSome: align.get() else: defaults.align
  result.hexpand = if hexpand.isSome: hexpand.get() else: defaults.hexpand
  result.vexpand = if vexpand.isSome: vexpand.get() else: defaults.vexpand
  result.disabled = if disabled.isSome: disabled.get() else: defaults.disabled

  if parent != nil:
    parent.children.add(result)

proc createRoot*(): Widget =
  ## Creates root widget and therefore the widget tree.
  result = createWidget(identifier = "root", width = some(640), height = some(480))