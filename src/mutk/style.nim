import strutils
import sequtils

proc rgba*(r,g,b,a: uint8): uint32 =
  (uint32(a) shl 24) or (uint32(r) shl 16) or (uint32(g) shl 8) or uint32(b)

type
  CSSNode* = object
    ## Node of CSS AST.
    ## While this a public type,
    ## you should not use it directly,
    ## instead let the style engine generate nodes.
    selector*: string
    properties*: seq[(string, string)]

proc generateAST*(source: string): seq[CSSNode] =
  ## Parses a CSS string and generates an AST.
  ## Example input:
  ## ```
  ## button {
  ##   background-color: red;
  ## }
  let cleanedSource = source.replace("\n", "").strip()
  let rules = cleanedSource.split("}")
  for rule in rules:
    if rule.len == 0: continue
    let parts = rule.split("{")
    if parts.len != 2: continue
    let selector = parts[0].strip()
    let propertiesPart = parts[1]
    var properties: seq[(string, string)] = @[]
    for prop in propertiesPart.split(";"):
      let declaration = prop.strip()
      if declaration.len == 0: continue
      let colonIndex = declaration.find(':')
      if colonIndex < 0: continue
      let key = declaration[0 ..< colonIndex].strip()
      let value = declaration[colonIndex + 1 .. ^1].strip()
      if key.len == 0 or value.len == 0: continue
      properties.add((key, value))
    result.add(CSSNode(selector: selector, properties: properties))

proc hexToSDLColor*(hex: string): (uint8, uint8, uint8, uint8) =
  ## Converts a hex color string to an SDL color tuple.
  ## Example input: "#RRGGBBAA" or "#RRGGBB"
  var r, g, b, a: uint8
  if hex.len == 7 and hex[0] == '#':
    r = uint8(fromHex[int](hex[1..2]))
    g = uint8(fromHex[int](hex[3..4]))
    b = uint8(fromHex[int](hex[5..6]))
    a = 255
  elif hex.len == 9 and hex[0] == '#':
    r = uint8(fromHex[int](hex[1..2]))
    g = uint8(fromHex[int](hex[3..4]))
    b = uint8(fromHex[int](hex[5..6]))
    a = uint8(fromHex[int](hex[7..8]))
  else:
    raise newException(ValueError, "Invalid hex color format")
  return (r, g, b, a)

proc parsePx*(value: string): int =
  ## Parses a pixel value from a string.
  ## Example input: "16px"
  var trimmedValue = value.strip()
  if trimmedValue.endsWith("px"):
    trimmedValue = trimmedValue[0 ..< trimmedValue.len - 2].strip()
    if trimmedValue.len > 0:
      return trimmedValue.parseInt()
  raise newException(ValueError, "Invalid pixel value format")

proc applyStyleNode*(
  node: CSSNode,
  borderRadius: var int,
  hasBgColor: var bool,
  bgColor: var uint32,
  hasGradient: var bool,
  gradientStart: var uint32,
  gradientEnd: var uint32,  
  borderWidth: var int,
  borderColor: var uint32,
  shadow: var seq[string]
) =
  for (key, value) in node.properties:
    case key:
    of "border-radius":
      var radiusValue = value.strip()
      if radiusValue.endsWith("px"):
        radiusValue = radiusValue[0 ..< radiusValue.len - 2].strip()
      if radiusValue.len > 0:
        borderRadius = radiusValue.parseInt()
    of "background-color":
      let (r, g, b, a) = hexToSDLColor(value)
      bgColor = rgba(r, g, b, a)
      hasBgColor = true
    of "background-image":
      if value.startsWith("linear-gradient("):
        let stops = value[16 .. ^2].split(',').mapIt(it.strip())
        let (r1, g1, b1, a1) = hexToSDLColor(stops[0])
        let (r2, g2, b2, a2) = hexToSDLColor(stops[1])
        gradientStart = rgba(r1, g1, b1, a1)
        gradientEnd = rgba(r2, g2, b2, a2)
        hasGradient = true
    of "border":
      for part in value.splitWhitespace():
        let trimmedPart = part.strip()
        if trimmedPart.endsWith("px"):
          let widthValue = trimmedPart[0 ..< trimmedPart.len - 2].strip()
          if widthValue.len > 0:
            borderWidth = widthValue.parseInt()
        elif trimmedPart.startsWith("#"):
          let (r, g, b, a) = hexToSDLColor(trimmedPart)
          borderColor = rgba(r, g, b, a)
    of "border-color":
      let (r, g, b, a) = hexToSDLColor(value)
      borderColor = rgba(r, g, b, a)
    of "border-width":
      var widthValue = value.strip()
      if widthValue.endsWith("px"):
        widthValue = widthValue[0 ..< widthValue.len - 2].strip()
      if widthValue.len > 0:
        borderWidth = widthValue.parseInt()
    of "box-shadow":
      shadow = @[]
      for shadowEntry in value.split(','):
        let entry = shadowEntry.strip()
        if entry.len == 0 or entry == "inset":
          continue

        let parts = entry.splitWhitespace()
        if parts.len < 3:
          continue

        var colorToken = ""
        for part in parts:
          if part.startsWith("#"):
            colorToken = part.strip()
            break

        if colorToken.len == 0:
          continue

        var offsets: seq[string] = @[]
        for part in parts:
          let trimmedPart = part.strip()
          if trimmedPart == "inset" or trimmedPart == colorToken:
            continue
          if offsets.len < 2:
            offsets.add(trimmedPart)

        if offsets.len == 2:
          shadow = @[offsets[0], offsets[1], colorToken]
          break