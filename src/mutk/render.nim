import sdl2
import mutk/widget

proc renderWidgets(renderer: RendererPtr, widget: Widget, level: int = 0): void =
  if widget.isNil: return

  renderer.setDrawColor(255, 0, 0, 255)

  var rect: Rect
  rect.x = 0
  rect.y = 0
  rect.w = int32(widget.width)
  rect.h = int32(widget.height)
  renderer.drawRect(rect)

  for child in widget.children:
    renderWidgets(renderer, child, level + 1)
  return

proc start*(root: Widget): int =
  discard sdl2.init(INIT_EVERYTHING)

  var
    window: WindowPtr
    renderer: RendererPtr

  window = createWindow("MUTK Window", 100, 100, 640, 480, SDL_WINDOW_SHOWN)
  renderer = createRenderer(
    window,
    -1,
    Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )

  var
    evt = sdl2.defaultEvent
    runGame = true

  while runGame:
    while pollEvent(evt):
      if evt.kind == QuitEvent:
        runGame = false
        break

    renderer.setDrawColor 0,0,0,255
    renderer.clear

    renderWidgets(renderer, root)

    renderer.present

  destroy renderer
  destroy window

  return 0