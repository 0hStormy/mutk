import widget

proc measure*(widget: Widget) =
  if widget.children.len == 0:
    return

  for child in widget.children:
    measure(child)

  let isVertical = widget.direction == Vertical

  if isVertical:
    var totalHeight = 0
    var maxWidth = 0

    for child in widget.children:
      totalHeight += child.height
      maxWidth = max(maxWidth, child.width)

    if not widget.vexpand:
      widget.height = totalHeight
    if not widget.hexpand:
      widget.width = maxWidth

  else:
    var totalWidth = 0
    var maxHeight = 0

    for child in widget.children:
      totalWidth += child.width
      maxHeight = max(maxHeight, child.height)

    if not widget.hexpand:
      widget.width = totalWidth
    if not widget.vexpand:
      widget.height = maxHeight

proc layoutWidgets*(widget: Widget) =
  ## Lay out widgets according to given tree

  if widget.children.len == 0:
    return

  let isVertical = widget.direction == Vertical

  # Total fixed space and expandable count
  var totalFixed = 0
  var expandCount = 0

  for child in widget.children:
    if isVertical:
      if child.vexpand:
        inc expandCount
      else:
        totalFixed += child.height
    else:
      if child.hexpand:
        inc expandCount
      else:
        totalFixed += child.width

  # Available space for expanders
  let containerSize = if isVertical: widget.height else: widget.width
  var remaining = containerSize - totalFixed
  if remaining < 0:
    remaining = 0

  let expandSize =
    if expandCount > 0: remaining div expandCount
    else: 0

  # Determine starting offset for main alignment
  var mainCursor = 0
  if expandCount == 0:
    case widget.align
    of AlignTop, AlignLeft:
      mainCursor = 0
    of AlignBottom, AlignRight:
      mainCursor = remaining
    of AlignCenter:
      mainCursor = remaining div 2

  for child in widget.children:

    if isVertical:
      # Height
      if child.vexpand:
        child.height = expandSize

      # Width
      if child.hexpand:
        child.width = widget.width

      # Position X
      case child.align
      of AlignLeft:
        child.x = widget.x
      of AlignRight:
        child.x = widget.x + widget.width - child.width
      of AlignCenter:
        child.x = widget.x + (widget.width - child.width) div 2
      else:
        child.x = widget.x

      # Position Y
      if child.inline == false:
        child.y = widget.y + mainCursor
        mainCursor += child.height
      else:
        child.y = widget.y + mainCursor

    else:
      # Width
      if child.hexpand:
        child.width = expandSize

      # Height
      if child.vexpand:
        child.height = widget.height

      # Position Y
      case child.align
      of AlignTop:
        child.y = widget.y
      of AlignBottom:
        child.y = widget.y + widget.height - child.height
      of AlignCenter:
        child.y = widget.y + (widget.height - child.height) div 2
      else:
        child.y = widget.y

      # Position X
      if child.inline == false:
        child.x = widget.x + mainCursor
        mainCursor += child.width
      else:
        child.x = widget.x + mainCursor

    # Recursively layout children
    layoutWidgets(child)