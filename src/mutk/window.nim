import sdl2
import widget
import layout
import style
import render

const styleAST = generateAST(staticRead("data/fallback.css"))

proc recreateTexture(renderer: RendererPtr, texture: var TexturePtr, w, h: int): void =
  if not texture.isNil:
    destroy texture

  texture = createTexture(
    renderer,
    SDL_PIXELFORMAT_ARGB8888,
    cint(SDL_TEXTUREACCESS_STREAMING),
    cint(max(1, w)),
    cint(max(1, h))
  )

proc renderWidgets(canvas: var Canvas, widget: Widget, style: seq[CSSNode]): void =
  if widget.isNil:
    return

  cssRender(canvas, widget, style)

  for child in widget.children:
    renderWidgets(canvas, child, style)

proc start*(root: Widget): int =
  discard sdl2.init(INIT_EVERYTHING)

  var
    window: WindowPtr
    renderer: RendererPtr
    frameTexture: TexturePtr
    canvas: Canvas

  window = createWindow(
    "MUTK Window",
    100, 100,
    640, 480,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE
  )

  renderer = createRenderer(
    window,
    -1,
    Renderer_Accelerated or Renderer_PresentVsync or Renderer_TargetTexture
  )

  canvas.resizeCanvas(640, 480)
  recreateTexture(renderer, frameTexture, canvas.w, canvas.h)

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
        activeWidget = clickedWidget
        if not clickedWidget.isNil and clickedWidget.onclick != nil:
          clickedWidget.onclick(clickedWidget)
      elif event.kind == MouseButtonUp:
        activeWidget = nil
      elif event.kind == WindowEvent and event.window.event == WindowEvent_Resized:
        root.width = event.window.data1
        root.height = event.window.data2
        measure(root)
        layoutWidgets(root)
        canvas.resizeCanvas(root.width, root.height)
        recreateTexture(renderer, frameTexture, canvas.w, canvas.h)

    canvas.clear(rgba(0, 0, 0, 255))
    renderWidgets(canvas, root, styleAST)

    if not frameTexture.isNil and canvas.pixels.len > 0:
      discard updateTexture(
        frameTexture,
        nil,
        cast[pointer](unsafeAddr(canvas.pixels[0])),
        cint(canvas.w * sizeof(uint32))
      )

    renderer.setDrawColor 0, 0, 0, 255
    renderer.clear

    if not frameTexture.isNil:
      discard renderer.copy(frameTexture, nil, nil)

    renderer.present

  if not frameTexture.isNil:
    destroy frameTexture

  destroy renderer
  destroy window

  return 0
