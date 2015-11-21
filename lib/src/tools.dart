part of stagexl_richtextfield;

String _color2rgb(int color) {

  int r = (color >> 16) & 0xFF;
  int g = (color >>  8) & 0xFF;
  int b = (color >>  0) & 0xFF;

  return "rgb($r,$g,$b)";
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
