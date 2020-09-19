part of stagexl_richtextfield;

class RichTextLineMetrics {
  final String _text;
  final int _textIndex;

  // ignore: prefer_final_fields
  num _x = 0.0;
  // ignore: prefer_final_fields
  num _y = 0.0;
  // ignore: prefer_final_fields
  num _width = 0.0;
  // ignore: prefer_final_fields
  num _height = 0.0;
  // ignore: prefer_final_fields
  num _ascent = 0.0;
  // ignore: prefer_final_fields
  num _descent = 0.0;
  // ignore: prefer_final_fields
  num _leading = 0.0;
  // ignore: prefer_final_fields
  num _indent = 0.0;

  RichTextLineMetrics._internal(this._text, this._textIndex);

  //-----------------------------------------------------------------------------------------------

  num get x => _x;
  num get y => _y;

  num get width => _width;
  num get height => _height;

  num get ascent => _ascent;
  num get descent => _descent;
  num get leading => _leading;
  num get indent => _indent;
}
