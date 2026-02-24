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
    disabled*: bool
    width*: int
    height*: int
    parent*: Widget
    children*: seq[Widget]

type
  ## Widget defaults object, used basically as a dictionary.
  WidgetDefaults = object
    disabled: bool
    width: int
    height: int

proc widgetDefaults(identifier: string): WidgetDefaults =
  ## Get default attributes for a specified widget.
  case identifier
    of "button":
      result = WidgetDefaults(
        disabled: false,
        width: 72,
        height: 32
      )
    else:
      result = WidgetDefaults(
        disabled: false,
        width: 0,
        height: 0
      )

proc createWidget*(
    parent: Widget = nil;
    identifier: string = "widget";
    name: string = "";
    width: Option[int] = none(int);
    height: Option[int] = none(int);
    disabled: Option[bool] = none(bool)
  ): Widget =
  ## Creates a widget based on specific identifier.
  ## Assign widget to a variable to use in program,
  ## otherwise, use with `discard` keyword
  result = Widget()
  result.identifier = identifier
  result.parent = parent
  result.name = name
  result.children = @[]

  let defaults = widgetDefaults(identifier)

  result.width = width.get(defaults.width)
  result.height = height.get(defaults.height)
  result.disabled = disabled.get(defaults.disabled)

  if parent != nil:
    parent.children.add(result)

proc createRoot*(): Widget =
  ## Creates root widget and therefore the widget tree.
  result = createWidget(identifier = "root")