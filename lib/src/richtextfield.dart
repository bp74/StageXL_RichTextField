part of stagexl_richtextfield;

class RichTextField extends InteractiveObject {

  String _text = "";
  List<RichTextFormat> _textFormats = [new RichTextFormat("Arial", 12, 0x000000)];

  String _autoSize = TextFieldAutoSize.NONE;

  bool _wordWrap = false;
  bool _multiline = false;
  bool _background = false;
  bool _border = false;
  int _backgroundColor = 0xFFFFFF;
  int _borderColor = 0x000000;
  int _maxChars = 0;
  num _width = 100;
  num _height = 100;

  num _textWidth = 0.0;
  num _textHeight = 0.0;
  final List<RichTextLineMetrics> _textLineMetrics = new List<RichTextLineMetrics>();

  int _refreshPending = 3;   // bit 0: textLineMetrics, bit 1: cache
  bool _cacheAsBitmap = true;
  CanvasElement _cacheAsBitmapCanvas;

  //-------------------------------------------------------------------------------------------------

  RichTextField([String text, RichTextFormat textFormat]) {

    this.text = (text != null) ? text : "";
    this.defaultTextFormat = (textFormat != null) ? textFormat : new RichTextFormat("Arial", 12, 0x000000);

    this.onMouseDown.listen(_onMouseDown);
  }

  //-------------------------------------------------------------------------------------------------

  void setFormat(RichTextFormat setFormat, [int startIndex = 0, int endIndex = -1])
  {
    RichTextFormat add = setFormat.clone();
    if(startIndex == 0 && endIndex == -1) {
      _textFormats = [add];
      return;
    }

    add.startIndex = startIndex;
    add.endIndex = endIndex;
    int numFormats = _textFormats.length;

    for(var i = 0; i < numFormats; i++) {
      RichTextFormat cur = _textFormats[i];
      //left trim
      if(add.startIndex <= cur.startIndex &&
        ((add.endIndex >= cur.startIndex && add.endIndex < cur.endIndex && cur.endIndex != -1)
            || (add.endIndex != -1 && cur.endIndex == -1))) {
         cur.startIndex = add.endIndex + 1;
      }

      //right trim
      else if(add.startIndex > cur.startIndex && (add.startIndex <= cur.endIndex || cur.endIndex == -1)
          && ((add.endIndex >= cur.endIndex && cur.endIndex != -1) || (add.endIndex == -1 && cur.endIndex == -1))) {
        cur.endIndex = add.startIndex - 1;
      }

      //split
      else if(add.startIndex > cur.startIndex &&
          ((add.endIndex < cur.endIndex && add.endIndex != -1) || (add.endIndex != -1 && cur.endIndex == -1))) {
        RichTextFormat f1 = cur.clone();
        RichTextFormat f2 = cur.clone();

        f1.startIndex = cur.startIndex;
        f1.endIndex = add.startIndex - 1;

        f2.startIndex = add.endIndex +1;
        f2.endIndex = cur.endIndex;

        _textFormats.removeAt(i);
        _textFormats.add(f1);
        _textFormats.add(f2);
      }

      //remove
      else if(add.startIndex <= cur.startIndex
          && (add.endIndex >= cur.endIndex || add.endIndex == -1)) {
         _textFormats.removeAt(i);
      }
    }

    _textFormats.add(add);
    _textFormats.sort((a,b) => a.startIndex-b.startIndex);

    _refreshPending |= 2;

  }


  //-------------------------------------------------------------------------------------------------

  String get text => _text;
  int get textColor => _textFormats[0].color;
  RichTextFormat get defaultTextFormat => _textFormats[0];

  String get autoSize => _autoSize;

  bool get wordWrap => _wordWrap;
  bool get multiline => _multiline;
  bool get background => _background;
  bool get border => _border;
  bool get cacheAsBitmap => _cacheAsBitmap;

  int get backgroundColor => _backgroundColor;
  int get borderColor => _borderColor;
  int get maxChars => _maxChars;

  //-------------------------------------------------------------------------------------------------

  void set width(num value) {
    _width = value.toDouble();
    _refreshPending |= 3;
  }

  void set height(num value) {
    _height = value.toDouble();
    _refreshPending |= 3;
  }

  void set text(String value) {
    _text = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    _refreshPending |= 3;
  }

  void set textColor(int value) {
    _textFormats[0].color = value;
    _refreshPending |= 2;
  }

  void set defaultTextFormat(RichTextFormat value) {
    _textFormats[0] = value.clone();
    _refreshPending |= 3;
  }

  void set autoSize(String value) {
    _autoSize = value;
    _refreshPending |= 3;
  }

  void set wordWrap(bool value) {
    _wordWrap = value;
    _refreshPending |= 3;
  }

  void set multiline(bool value) {
    _multiline = value;
    _refreshPending |= 3;
  }

  void set background(bool value) {
    _background = value;
    _refreshPending |= 2;
  }

  void set backgroundColor(int value) {
    _backgroundColor = value;
    _refreshPending |= 2;
  }

  void set border(bool value) {
    _border = value;
    _refreshPending |= 2;
  }

  void set borderColor(int value) {
    _borderColor = value;
    _refreshPending |= 2;
  }

  void set maxChars(int value) {
    _maxChars = value;
  }

  void set cacheAsBitmap(bool value) {
    if (value) _refreshPending |= 2;
    _cacheAsBitmap = value;
  }

  //-------------------------------------------------------------------------------------------------

  num get x {
    _refreshTextLineMetrics();
    return super.x;
  }

  num get width {
    _refreshTextLineMetrics();
    return _width;
  }

  num get height {
    _refreshTextLineMetrics();
    return _height;
  }

  num get textWidth {
    _refreshTextLineMetrics();
    return _textWidth;
  }

  num get textHeight {
    _refreshTextLineMetrics();
    return _textHeight;
  }

  int get numLines {
    _refreshTextLineMetrics();
    return _textLineMetrics.length;
  }

  RichTextLineMetrics getLineMetrics(int lineIndex) {
    _refreshTextLineMetrics();
    return _textLineMetrics[lineIndex];
  }

  String getLineText(int lineIndex) {
    return getLineMetrics(lineIndex)._text;
  }

  int getLineLength(int lineIndex) {
    return getLineText(lineIndex).length;
  }

  //-------------------------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------

  Rectangle getBoundsTransformed(Matrix matrix, [Rectangle returnRectangle]) {
    return _getBoundsTransformedHelper(matrix, _width, _height, returnRectangle);
  }

  //-------------------------------------------------------------------------------------------------

  DisplayObject hitTestInput(num localX, num localY) {

    if (localX >= 0 && localY >= 0 && localX < _width && localY < _height)
      return this;

    return null;
  }

  //-------------------------------------------------------------------------------------------------

  void render(RenderState renderState) {

    _refreshTextLineMetrics();
    _refreshCache();

    // draw text

    var renderContext = renderState.context;

    if (_cacheAsBitmap) {
      var canvas = _cacheAsBitmapCanvas;
      if (canvas != null) renderContext.drawImageScaled(canvas, 0.0, 0.0, _width, _height);
    } else {
      _renderText(renderContext);
    }

  }

  //-------------------------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------

  num _getLineWidth(String line, [int startIndex = 0]) {
    num lineWidth = 0;
    int endIndex = startIndex + line.length;

    var canvasContext = _dummyCanvasContext
      ..textAlign = "start"
      ..textBaseline = "alphabetic"
      ..setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);

    for(RichTextFormat rtf in _textFormats.where((f) => !(f.startIndex > endIndex || (f.endIndex < startIndex && f.endIndex != -1)))) {
      canvasContext.font = rtf._cssFontStyle;
      int rtfEndIndex = rtf.endIndex==-1?line.length:rtf.endIndex-startIndex+1;
      lineWidth += canvasContext.measureText(line.substring(max(rtf.startIndex-startIndex,0), min(rtfEndIndex, line.length))).width;
    }

    return lineWidth;
  }

  _refreshTextLineMetrics() {

    if ((_refreshPending & 1) == 0) {
      return;
    } else {
      _refreshPending &= 255 - 1;
    }

    _textLineMetrics.clear();

    //-----------------------------
    // split lines

    var startIndex = 0;
    var checkLine = '';
    var validLine = '';
    var lineWidth = 0;
    var lineIndent = 0;

    RichTextFormat firstFormat = _textFormats[0];

    var textFormatIndent = _ensureNum(firstFormat.indent);
    var textFormatLeftMargin = _ensureNum(firstFormat.leftMargin);
    var textFormatRightMargin = _ensureNum(firstFormat.rightMargin);
    var availableWidth = _width - textFormatLeftMargin - textFormatRightMargin;

    var paragraphLines = new List<int>();

    var canvasContext = _dummyCanvasContext
      ..textAlign = "start"
      ..textBaseline = "alphabetic"
      ..setTransform(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);

    for(var paragraph in _text.split('\n')) {

      paragraphLines.add(_textLineMetrics.length);

      if (_wordWrap == false) {

        _textLineMetrics.add(new RichTextLineMetrics._internal(paragraph, startIndex));
        startIndex += paragraph.length + 1;

      } else {

        checkLine = null;
        lineIndent = textFormatIndent;

        for(var word in paragraph.split(' ')) {

          validLine = checkLine;
          checkLine = (validLine == null) ? word : "$validLine $word";

          lineWidth = _getLineWidth(checkLine, startIndex);

          if (lineIndent + lineWidth >= availableWidth) {
            if (validLine == null) {
              _textLineMetrics.add(new RichTextLineMetrics._internal(checkLine, startIndex));
              startIndex += checkLine.length + 1;
              checkLine = null;
              lineIndent = 0;
            } else {
              _textLineMetrics.add(new RichTextLineMetrics._internal(validLine, startIndex));
              startIndex += validLine.length + 1;
              checkLine = word;
              lineIndent = 0;
            }
          }
        }

        if (checkLine != null) {
          _textLineMetrics.add(new RichTextLineMetrics._internal(checkLine, startIndex));
          startIndex += checkLine.length + 1;
        }
      }
    }

    //-----------------------------
    // calculate metrics

    _textWidth = 0.0;
    _textHeight = 0.0;

    num lineHeights = 0;
    for(int line = 0; line < _textLineMetrics.length; line++) {

      var textLineMetrics = _textLineMetrics[line];
      if (textLineMetrics is! RichTextLineMetrics) continue; // dart2js_hint

      var lineIndex = textLineMetrics._textIndex;
      RichTextFormat lineFormat = _textFormats.firstWhere((e) => lineIndex>=e.startIndex && (lineIndex<=e.endIndex || e.endIndex == -1));
      var textFormatSize = _ensureNum(lineFormat.size);
      var textFormatTopMargin = _ensureNum(lineFormat.topMargin);
      var textFormatBottomMargin = _ensureNum(lineFormat.bottomMargin);
      var textFormatLeading = _ensureNum(lineFormat.leading);
      var textFormatAlign = _ensureString(lineFormat.align);

      var fontStyle = lineFormat._cssFontStyle;
      var fontStyleMetrics = _getFontStyleMetrics(fontStyle);
      var fontStyleMetricsAscent = _ensureNum(fontStyleMetrics.ascent);
      var fontStyleMetricsDescent = _ensureNum(fontStyleMetrics.descent);

      canvasContext.font = fontStyle;

      var indent = paragraphLines.contains(line) ? textFormatIndent : 0;
      var offsetX = textFormatLeftMargin + indent;
      var offsetY = textFormatTopMargin + textFormatSize + lineHeights;
      lineHeights+= textFormatTopMargin + textFormatSize;

      var width = _getLineWidth(textLineMetrics._text, textLineMetrics._textIndex);

      switch(textFormatAlign) {
        case TextFormatAlign.CENTER:
        case TextFormatAlign.JUSTIFY:
          offsetX += (availableWidth - width) / 2;
          break;
        case TextFormatAlign.RIGHT:
        case TextFormatAlign.END:
          offsetX += (availableWidth - width);
          break;
      }

      textLineMetrics._x = offsetX;
      textLineMetrics._y = offsetY;
      textLineMetrics._width = width;
      textLineMetrics._height = textFormatSize;
      textLineMetrics._ascent = fontStyleMetricsAscent;
      textLineMetrics._descent = fontStyleMetricsDescent;
      textLineMetrics._leading = textFormatLeading;
      textLineMetrics._indent = indent;

      _textWidth = max(_textWidth, textFormatLeftMargin + indent + width + textFormatRightMargin);
      _textHeight = offsetY + fontStyleMetricsDescent + textFormatBottomMargin;
    }

    //-----------------------------
    // calculate autoSize

    var autoWidth = _wordWrap ? _width : _textWidth.ceil();
    var autoHeight = _textHeight.ceil();

    if (_width != autoWidth || _height != autoHeight) {

      switch(_autoSize) {
        case TextFieldAutoSize.LEFT:
          _width = autoWidth;
          _height = autoHeight;
          break;
        case TextFieldAutoSize.RIGHT:
          super.x -= (autoWidth - _width);
          _width = autoWidth;
          _height = autoHeight;
          break;
        case TextFieldAutoSize.CENTER:
          super.x -= (autoWidth - _width) / 2;
          _width = autoWidth;
          _height = autoHeight;
          break;
      }
    }

  }

  //-------------------------------------------------------------------------------------------------

  _refreshCache() {

    if ((_refreshPending & 2) == 0) {
      return;
    } else {
      _refreshPending &= 255 - 2;
    }

    if (_cacheAsBitmap == false) {
      return;
    }

    var pixelRatio = (Stage.autoHiDpi ? _devicePixelRatio : 1.0) / _backingStorePixelRatio;
    var canvasWidth = (_width * pixelRatio).ceil();
    var canvasHeight =  (_height * pixelRatio).ceil();

    if (canvasWidth <= 0 || canvasHeight <= 0) {
      _cacheAsBitmapCanvas = null;
      return;
    }

    if (_cacheAsBitmapCanvas == null) {
      _cacheAsBitmapCanvas = new CanvasElement(width: canvasWidth, height: canvasHeight);
    }

    if (_cacheAsBitmapCanvas.width != canvasWidth) _cacheAsBitmapCanvas.width = canvasWidth;
    if (_cacheAsBitmapCanvas.height != canvasHeight) _cacheAsBitmapCanvas.height = canvasHeight;

    var context = _cacheAsBitmapCanvas.context2D;
    context.setTransform(pixelRatio, 0.0, 0.0, pixelRatio, 0.0, 0.0);
    context.clearRect(0, 0, _width, _height);

    _renderText(context);
  }

  //-------------------------------------------------------------------------------------------------

  _renderText(CanvasRenderingContext2D context) {

    context
      ..save()
      ..beginPath()
      ..rect(0, 0, _width, _height)
      ..clip()
      ..textAlign = "start"
      ..textBaseline = "alphabetic";

    if (_background) {
      context
        ..fillStyle = _color2rgb(_backgroundColor)
        ..fillRect(0, 0, _width, _height);
    }

    for(int i = 0; i < _textLineMetrics.length; i++) {
      var lm = _textLineMetrics[i];
      int startIndex = lm._textIndex;
      int endIndex = startIndex + lm._text.length;
      num tfWidth = 0;
      num offsetX = 0;
      for(RichTextFormat rtf in _textFormats.where((f) => !(f.startIndex > endIndex || (f.endIndex < startIndex  && f.endIndex != -1)))) {
        int rtfEndIndex = rtf.endIndex==-1?lm._text.length:rtf.endIndex-startIndex+1;

        String text = lm._text.substring(max(rtf.startIndex-startIndex,0), min(rtfEndIndex, lm._text.length));

        context
          ..font = rtf._cssFontStyle
          ..fillStyle = _color2rgb(rtf.color)
          ..fillText(text, lm._x + offsetX, lm._y);

        tfWidth = context.measureText(text).width;

        if(rtf.underline) {
          var lineWidth = (rtf.bold ? rtf.size / 10 : rtf.size / 20).ceil();
          num underlineY = (lm.y + lineWidth).round();
          if (lineWidth % 2 != 0) underlineY += 0.5;
          context
            ..strokeStyle = _color2rgb(rtf.color)
            ..lineWidth = lineWidth
            ..beginPath()
            ..moveTo(lm.x + offsetX, underlineY)
            ..lineTo(lm.x + offsetX + tfWidth, underlineY)
            ..stroke();
        }

        offsetX+=tfWidth;

      }

    }

    if (_border) {
      context.strokeStyle = _color2rgb(_borderColor);
      context.lineWidth = 1;
      context.strokeRect(0, 0, _width, _height);
    }

    context.restore();
  }

   //-------------------------------------------------------------------------------------------------

  _onMouseDown(MouseEvent mouseEvent) {
    //use this for simple "did user click on this textfield" logic

  }
}
