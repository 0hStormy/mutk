import math

type Canvas* = object
  w*: int
  h*: int
  pixels*: seq[uint32] # 0xAARRGGBB

proc rgba*(r, g, b, a: uint8): uint32 =
  (uint32(a) shl 24) or (uint32(r) shl 16) or (uint32(g) shl 8) or uint32(b)

proc clear*(c: var Canvas, col: uint32) =
  for i in 0..<c.pixels.len:
    c.pixels[i] = col

proc putPixel*(c: var Canvas, x, y: int, col: uint32) =
  if x < 0 or y < 0 or x >= c.w or y >= c.h:
    return
  c.pixels[y * c.w + x] = col

proc clamp01(value: float): float =
  if value < 0.0:
    return 0.0
  if value > 1.0:
    return 1.0
  return value

proc blendPixel*(c: var Canvas, x, y: int, col: uint32, coverage: float = 1.0) =
  if x < 0 or y < 0 or x >= c.w or y >= c.h:
    return

  let sourceA = (float((col shr 24) and 0xFF) / 255.0) * clamp01(coverage)
  if sourceA <= 0.0:
    return

  let sourceR = float((col shr 16) and 0xFF) / 255.0
  let sourceG = float((col shr 8) and 0xFF) / 255.0
  let sourceB = float(col and 0xFF) / 255.0

  let dst = c.pixels[y * c.w + x]
  let dstA = float((dst shr 24) and 0xFF) / 255.0
  let dstR = float((dst shr 16) and 0xFF) / 255.0
  let dstG = float((dst shr 8) and 0xFF) / 255.0
  let dstB = float(dst and 0xFF) / 255.0

  let outA = sourceA + dstA * (1.0 - sourceA)
  if outA <= 0.0:
    c.pixels[y * c.w + x] = 0'u32
    return

  let outR = (sourceR * sourceA + dstR * dstA * (1.0 - sourceA)) / outA
  let outG = (sourceG * sourceA + dstG * dstA * (1.0 - sourceA)) / outA
  let outB = (sourceB * sourceA + dstB * dstA * (1.0 - sourceA)) / outA

  c.pixels[y * c.w + x] = rgba(
    uint8(clamp01(outR) * 255.0),
    uint8(clamp01(outG) * 255.0),
    uint8(clamp01(outB) * 255.0),
    uint8(clamp01(outA) * 255.0)
  )

proc fillRect*(c: var Canvas, x, y, w, h: int, col: uint32) =
  let x0 = max(0, x)
  let y0 = max(0, y)
  let x1 = min(c.w, x + w)
  let y1 = min(c.h, y + h)
  for yy in y0..<y1:
    for xx in x0..<x1:
      c.putPixel(xx, yy, col)

proc insideRoundedRect*(localX, localY, w, h, radius: int): bool =
  if radius <= 0:
    return true

  let r = min(radius, min(w div 2, h div 2))
  if r <= 0:
    return true

  let dx =
    if localX < r: r - localX
    elif localX >= w - r: localX - (w - r - 1)
    else: 0

  let dy =
    if localY < r: r - localY
    elif localY >= h - r: localY - (h - r - 1)
    else: 0

  result = dx * dx + dy * dy <= r * r

proc roundedRectCoverage*(localX, localY, w, h, radius: int): float =
  if w <= 0 or h <= 0:
    return 0.0

  if radius <= 0:
    if localX < 0 or localY < 0 or localX >= w or localY >= h:
      return 0.0
    return 1.0

  let cornerRadius = float(min(radius, min(w div 2, h div 2)))
  if cornerRadius <= 0.0:
    return 1.0

  let halfWidth = float(w) / 2.0
  let halfHeight = float(h) / 2.0
  let centerX = float(localX) + 0.5 - halfWidth
  let centerY = float(localY) + 0.5 - halfHeight

  let boxX = max(halfWidth - cornerRadius, 0.0)
  let boxY = max(halfHeight - cornerRadius, 0.0)

  let qx = abs(centerX) - boxX
  let qy = abs(centerY) - boxY
  let outsideX = max(qx, 0.0)
  let outsideY = max(qy, 0.0)
  let signedDistance = sqrt(outsideX * outsideX + outsideY * outsideY) - cornerRadius

  return clamp01(0.5 - signedDistance)

proc fillRoundedRect*(c: var Canvas, x, y, w, h, radius: int, col: uint32) =
  if w <= 0 or h <= 0:
    return

  let x0 = max(0, x)
  let y0 = max(0, y)
  let x1 = min(c.w, x + w)
  let y1 = min(c.h, y + h)

  for yy in y0..<y1:
    for xx in x0..<x1:
      let localX = xx - x
      let localY = yy - y
      let coverage = roundedRectCoverage(localX, localY, w, h, radius)
      if coverage > 0.0:
        c.blendPixel(xx, yy, col, coverage)

proc drawRoundedBorder*(c: var Canvas, x, y, w, h, radius, borderWidth: int, col: uint32) =
  if w <= 0 or h <= 0:
    return

  let bw = min(borderWidth, min(w div 2, h div 2))
  if bw <= 0:
    return

  let innerW = w - (bw * 2)
  let innerH = h - (bw * 2)
  let innerRadius = max(0, radius - bw)

  let x0 = max(0, x)
  let y0 = max(0, y)
  let x1 = min(c.w, x + w)
  let y1 = min(c.h, y + h)

  for yy in y0..<y1:
    for xx in x0..<x1:
      let localX = xx - x
      let localY = yy - y
      let outerCoverage = roundedRectCoverage(localX, localY, w, h, radius)
      if outerCoverage <= 0.0:
        continue

      let innerX = localX - bw
      let innerY = localY - bw
      let innerCoverage =
        if innerW > 0 and innerH > 0:
          roundedRectCoverage(innerX, innerY, innerW, innerH, innerRadius)
        else:
          0.0

      let borderCoverage = clamp01(outerCoverage - innerCoverage)
      if borderCoverage > 0.0:
        c.blendPixel(xx, yy, col, borderCoverage)

proc linearGradient*(c: var Canvas, x, y, w, h: int, col1, col2: uint32, radius: int = 0) =
  if w <= 0 or h <= 0:
    return

  for i in 0..<h:
    let t = if h == 1: 0.0 else: float(i) / float(h - 1)
    let r = uint8((1 - t) * float((col1 shr 16) and 0xFF) + t * float((col2 shr 16) and 0xFF))
    let g = uint8((1 - t) * float((col1 shr 8) and 0xFF) + t * float((col2 shr 8) and 0xFF))
    let b = uint8((1 - t) * float(col1 and 0xFF) + t * float(col2 and 0xFF))
    let a = uint8((1 - t) * float((col1 shr 24) and 0xFF) + t * float((col2 shr 24) and 0xFF))
    let rowColor = rgba(r, g, b, a)

    if radius <= 0:
      c.fillRect(x, y + i, w, 1, rowColor)
    else:
      let yy = y + i
      if yy < 0 or yy >= c.h:
        continue
      let x0 = max(0, x)
      let x1 = min(c.w, x + w)
      for xx in x0..<x1:
        let localX = xx - x
        if insideRoundedRect(localX, i, w, h, radius):
          c.putPixel(xx, yy, rowColor)

proc resizeCanvas*(c: var Canvas, w, h: int): void =
  c.w = max(1, w)
  c.h = max(1, h)
  c.pixels.setLen(c.w * c.h)
