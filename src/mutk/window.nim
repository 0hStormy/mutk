import sdl2
import widget
import layout
import style
import render

const styleAST = generateAST(staticRead("data/fallback.css"))

type
  TextureCacheEntry = object
    w: int
    h: int
    texture: TexturePtr

proc getOrCreateTexture(
  renderer: RendererPtr,
  cache: var seq[TextureCacheEntry],
  w, h: int
): TexturePtr =
  let targetW = max(1, w)
  let targetH = max(1, h)

  for entry in cache:
    if entry.w == targetW and entry.h == targetH and not entry.texture.isNil:
      return entry.texture

  let texture = createTexture(
    renderer,
    SDL_PIXELFORMAT_ARGB8888,
    cint(SDL_TEXTUREACCESS_STREAMING),
    cint(targetW),
    cint(targetH)
  )

  cache.add(TextureCacheEntry(w: targetW, h: targetH, texture: texture))
  return texture

proc destroyTextureCache(cache: var seq[TextureCacheEntry]): void =
  for entry in cache:
    if not entry.texture.isNil:
      destroy entry.texture
  cache.setLen(0)

proc renderWidgets(canvas: var Canvas, widget: Widget, style: seq[CSSNode]): void =
  if widget.isNil:
    return

  cssRender(canvas, widget, style)

  for child in widget.children:
    renderWidgets(canvas, child, style)

proc limitFrameRate(targetFramePeriod: uint32, frameTime: uint32): uint32 =
  let now = getTicks()
  if frameTime > now:
    delay(frameTime - now) # Delay to maintain steady frame rate
  return frameTime + targetFramePeriod

proc start*(root: Widget): int =
  discard sdl2.init(INIT_EVERYTHING)

  var
    window: WindowPtr
    renderer: RendererPtr
    frameTexture: TexturePtr
    textureCache: seq[TextureCacheEntry]
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
  frameTexture = getOrCreateTexture(renderer, textureCache, canvas.w, canvas.h)

  var mode: DisplayMode

  let frameRate = if mode.refresh_rate != 0:
    mode.refresh_rate
  else:
    60

  let targetFramePeriod: uint32 = uint32(1000 div frameRate)
  var frameTime: uint32 = 0

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
        frameTexture = getOrCreateTexture(renderer, textureCache, canvas.w, canvas.h)

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
    discard limitFrameRate(targetFramePeriod, frameTime)

  destroyTextureCache(textureCache)

  destroy renderer
  destroy window

  return 0
