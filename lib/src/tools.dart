part of stagexl_richtextfield;

int _colorGetA(int color) => (color >> 24) & 0xFF;
int _colorGetR(int color) => (color >> 16) & 0xFF;
int _colorGetG(int color) => (color >>  8) & 0xFF;
int _colorGetB(int color) => (color      ) & 0xFF;

String _color2rgb(int color) {
  int r = _colorGetR(color);
  int g = _colorGetG(color);
  int b = _colorGetB(color);
  return "rgb($r,$g,$b)";
}

String _color2rgba(int color) {
  int r = _colorGetR(color);
  int g = _colorGetG(color);
  int b = _colorGetB(color);
  num a = _colorGetA(color) / 255.0;
  return "rgba($r,$g,$b,$a)";
}

num _ensureNum(num value) {
  if (value is num) {
    return value;
  } else {
    throw new ArgumentError("The supplied value ($value) is not a number.");
  }
}

String _ensureString(String value) {
  if (value is String) {
    return value;
  } else {
    throw new ArgumentError("The supplied value ($value) is not a string.");
  }
}

CanvasGradient _getCanvasGradient(CanvasRenderingContext2D context, GraphicsGradient gradient) {

  var sx = gradient.startX;
  var sy = gradient.startY;
  var sr = gradient.startRadius;
  var ex = gradient.endX;
  var ey = gradient.endY;
  var er = gradient.endRadius;

  CanvasGradient canvasGradient;

  if (gradient.type == GraphicsGradientType.Linear) {
    canvasGradient = context.createLinearGradient(sx, sy, ex, ey);
  } else if (gradient.type == GraphicsGradientType.Radial) {
    canvasGradient = context.createRadialGradient(sx, sy, sr, ex, ey, er);
  } else {
    throw new ArgumentError("Unknown gradient kind");
  }

  for (var colorStop in gradient.colorStops) {
    var offset = colorStop.offset;
    var color = _color2rgba(colorStop.color);
    canvasGradient.addColorStop(offset, color);
  }

  return canvasGradient;
}

