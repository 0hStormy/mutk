import sdl2
import widget
import layout

var hoveredWidget* = Widget()

proc renderWidgets(renderer: RendererPtr, widget: Widget, level: int = 0): void =
  if widget.isNil: return

  var rect: Rect
  rect.x = int32(widget.x)
  rect.y = int32(widget.y)
  rect.w = int32(widget.width)
  rect.h = int32(widget.height)

  if widget == hoveredWidget:
    renderer.setDrawColor 64,0,0,255
    renderer.fillRect(rect)

  renderer.setDrawColor 255,0,0,255
  renderer.drawRect(rect)

  for child in widget.children:
    renderWidgets(renderer, child, level + 1)
  return

proc start*(root: Widget): int =
  discard sdl2.init(INIT_EVERYTHING)

  var
    window: WindowPtr
    renderer: RendererPtr

  window = createWindow(
    "MUTK Window",
    100,100,
    640, 480,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE
  )

  renderer = createRenderer(
    window,
    -1,
    Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )

  var
    event = sdl2.defaultEvent
    running = true

  measure(root)
  layoutWidgets(root)

  while running:
    while pollEvent(event):
      if event.kind == QuitEvent:
        running = false
        break
      elif event.kind == MouseMotion:
        let (x, y) = (event.motion.x, event.motion.y)
        hoveredWidget = findWidgetAt(root, x, y)
      elif event.kind == MouseButtonDown:
        let clickedWidget = hoveredWidget
        if not clickedWidget.isNil and clickedWidget.onclick != nil:
          clickedWidget.onclick(clickedWidget)
      elif event.kind == WindowEvent and event.window.event == WindowEvent_Resized:
        root.width = event.window.data1
        root.height = event.window.data2
        measure(root)
        layoutWidgets(root)

    renderer.setDrawColor 0,0,0,255
    renderer.clear

    renderWidgets(renderer, root)

    renderer.present

  destroy renderer
  destroy window

  return 0