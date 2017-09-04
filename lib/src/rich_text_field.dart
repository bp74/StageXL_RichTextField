part of stagexl_richtextfield;

class RichTextField extends InteractiveObject {

  RichTextParser parser = new DefaultRichTextParser();

  String _text = "";
  String _rawText = "";
  List<RichTextFormat> _textFormats = [new RichTextFormat("Arial", 12, 0x000000)];
  Map<String, RichTextFormat> presets = {};

  String _autoSize = TextFieldAutoSize.NONE;

  bool _wordWrap = false;
  bool _multiline = false;
  bool _background = false;
  bool _border = false;
  bool _parse = true;
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

  RenderTexture _renderTexture;
  RenderTextureQuad _renderTextureQuad;

  //-------------------------------------------------------------------------------------------------

  RichTextField([String text = "", RichTextFormat textFormat, bool parse = true]) {
    this.defaultTextFormat = textFormat ?? new RichTextFormat("Arial", 12, 0x000000);
    this.parse = parse;
    this.text = text;
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
      if(add.startIndex <= cur.startIndex && add.endIndex >= cur.startIndex &&
        ((add.endIndex < cur.endIndex && cur.endIndex != -1)
            || (add.endIndex != -1 && cur.endIndex == -1))) {
         cur.startIndex = add.endIndex + 1;
         _textFormats.add(add);
      }

      //right trim
      else if(add.startIndex > cur.startIndex && (add.startIndex <= cur.endIndex || cur.endIndex == -1)
          && ((add.endIndex >= cur.endIndex && cur.endIndex != -1) || (add.endIndex == -1 && cur.endIndex == -1))) {
        cur.endIndex = add.startIndex - 1;
        _textFormats.add(add);
      }

      //split
      else if(add.startIndex > cur.startIndex &&
          ((add.endIndex < cur.endIndex && add.endIndex != -1) || (add.endIndex != -1 && cur.endIndex == -1))) {
        RichTextFormat f1 = cur.clone();
        RichTextFormat f2 = f1.clone();

        f1.startIndex = cur.startIndex;
        f1.endIndex = add.startIndex - 1;

        f2.startIndex = add.endIndex +1;
        f2.endIndex = cur.endIndex;

        _textFormats.removeAt(i);
        _textFormats.add(f1);
        _textFormats.add(f2);
        _textFormats.add(add);
      }

      //remove
      else if(add.startIndex <= cur.startIndex
          && ((add.endIndex >= cur.endIndex && cur.endIndex != -1) || add.endIndex == -1)) {
        _textFormats.removeAt(i);
        _textFormats.add(add);
      }
    }

    _textFormats.sort((a,b) => a.startIndex-b.startIndex);
    _refreshPending |= 2;
    
    return;
  }

  //-------------------------------------------------------------------------------------------------

  RenderTexture get renderTexture => _renderTexture;
  String get text => _text;
  String get rawText => _rawText;
  int get textColor => _textFormats[0].color;
  RichTextFormat get defaultTextFormat => _textFormats[0];
  List<RichTextFormat> get textFormats => _textFormats;

  String get autoSize => _autoSize;

  bool get wordWrap => _wordWrap;
  bool get multiline => _multiline;
  bool get parse => _parse;
  bool get background => _background;
  bool get border => _border;
  bool get cacheAsBitmap => _cacheAsBitmap;

  int get backgroundColor => _backgroundColor;
  int get borderColor => _borderColor;
  int get maxChars => _maxChars;

  //-------------------------------------------------------------------------------------------------

  @override
  set width(num value) {
    _width = value.toDouble();
    _refreshPending |= 3;
  }

  @override
  set height(num value) {
    _height = value.toDouble();
    _refreshPending |= 3;
  }

  set text(String value) {
    value = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    if(parse && value != "") {
      _textFormats.removeRange(1, _textFormats.length);
      _textFormats[0].endIndex = -1;
      _rawText = value;
      _text = this.parser.parse(this, value);
    } else {
      _rawText = value;
      _text = value;
    }
    _refreshPending |= 3;
  }

  set textColor(int value) {
    _textFormats[0].color = value;
    _refreshPending |= 2;
  }

  set defaultTextFormat(RichTextFormat value) {
    _textFormats[0] = value.clone();
    _refreshPending |= 3;
  }

  set autoSize(String value) {
    _autoSize = value;
    _refreshPending |= 3;
  }

  set wordWrap(bool value) {
    _wordWrap = value;
    _refreshPending |= 3;
  }

  set multiline(bool value) {
    _multiline = value;
    _refreshPending |= 3;
  }

  set parse(bool value) {
    _parse = value;
    _refreshPending |= 3;
  }

  set background(bool value) {
    _background = value;
    _refreshPending |= 2;
  }

  set backgroundColor(int value) {
    _backgroundColor = value;
    _refreshPending |= 2;
  }

  set border(bool value) {
    _border = value;
    _refreshPending |= 2;
  }

  set borderColor(int value) {
    _borderColor = value;
    _refreshPending |= 2;
  }

  set maxChars(int value) {
    _maxChars = value;
  }

  set cacheAsBitmap(bool value) {
    if (value) _refreshPending |= 2;
    _cacheAsBitmap = value;
  }

  //-------------------------------------------------------------------------------------------------

  @override
  num get x {
    _refreshTextLineMetrics();
    return super.x;
  }

  @override
  num get width {
    _refreshTextLineMetrics();
    return _width;
  }

  @override
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

  RichTextFormat getFormatAt(int index) {
    return _textFormats.firstWhere((f) => !(f.startIndex > index || (f.endIndex < index && f.endIndex != -1)),
                          orElse: () => _textFormats[0]);
  }

  String getLineText(int lineIndex) {
    return getLineMetrics(lineIndex)._text;
  }

  int getLineLength(int lineIndex) {
    return getLineText(lineIndex).length;
  }

  //-------------------------------------------------------------------------------------------------
  //-------------------------------------------------------------------------------------------------

  @override
  Rectangle<num> get bounds {
    return new Rectangle<num>(0.0, 0.0, width, height);
  }

  @override
  DisplayObject hitTestInput(num localX, num localY) {
    if (localX < 0 || localX >= width) return null;
    if (localY < 0 || localY >= height) return null;
    return this;
  }

  @override
  void render(RenderState renderState) {

    _refreshTextLineMetrics();

    if (renderState.renderContext is RenderContextWebGL || _cacheAsBitmap ) {
      _refreshCache(renderState.globalMatrix);
      renderState.renderTextureQuad(_renderTextureQuad);
    } else {
      RenderContextCanvas renderContextCanvas = renderState.renderContext;
      renderContextCanvas.setTransform(renderState.globalMatrix);
      renderContextCanvas.setAlpha(renderState.globalAlpha);
      _renderText(renderContextCanvas.rawContext);
    }
  }

  @override
  void renderFiltered(RenderState renderState) {

    if (renderState.renderContext is RenderContextWebGL || _cacheAsBitmap) {
      _refreshTextLineMetrics();
      _refreshCache(renderState.globalMatrix);
      renderState.renderTextureQuadFiltered(_renderTextureQuad, this.filters);
    } else {
      super.renderFiltered(renderState);
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

  void _refreshTextLineMetrics() {

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
    var lineWidth = 0.0;
    var lineIndent = 0.0;

    RichTextFormat firstFormat = _textFormats[0];
    num strokeWidth = _ensureNum(defaultTextFormat.strokeWidth);
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
              lineIndent = 0.0;
            } else {
              _textLineMetrics.add(new RichTextLineMetrics._internal(validLine, startIndex));
              startIndex += validLine.length + 1;
              checkLine = word;
              lineIndent = 0.0;
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
      var lineEndIndex = textLineMetrics._text.length + lineIndex;
      var textFormatSize = 0;
      var lineFormat = _textFormats.firstWhere((f) => lineIndex>=f.startIndex && (lineIndex<=f.endIndex || f.endIndex == -1),
          orElse: () => null);
      
      if(lineFormat == null) continue; 
      
      //textFormatSize must be the max text size enountered on that line
      for(RichTextFormat rtf in _textFormats.where((f) => !(f.startIndex > lineEndIndex || (f.endIndex < lineIndex && f.endIndex != -1)))) {
        textFormatSize = max(_ensureNum(rtf.size),textFormatSize);
      }

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
        default:
          offsetX += strokeWidth;
      }

      offsetY += strokeWidth;
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
    
    _textWidth += strokeWidth * 2;
    _textHeight += strokeWidth * 2;

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

  void _refreshCache(Matrix globalMatrix) {

    var pixelRatioGlobal = sqrt(globalMatrix.det.abs());
    var pixelRatioCache = _renderTextureQuad?.pixelRatio ?? 0.0;
    if (pixelRatioCache < pixelRatioGlobal * 0.80) _refreshPending |= 2;
    if (pixelRatioCache > pixelRatioGlobal * 1.25) _refreshPending |= 2;
    if ((_refreshPending & 2) == 0) return;

    _refreshPending &= 255 - 2;

    var width = max(1, _width * pixelRatioGlobal).ceil();
    var height =  max(1, _height * pixelRatioGlobal).ceil();

    if (_renderTexture == null) {
      _renderTexture = new RenderTexture(width, height, Color.Transparent);
      _renderTextureQuad = _renderTexture.quad.withPixelRatio(pixelRatioGlobal);
    } else {
      _renderTexture.resize(width, height);
      _renderTextureQuad = _renderTexture.quad.withPixelRatio(pixelRatioGlobal);
    }

    var matrix = _renderTextureQuad.drawMatrix;
    var context = _renderTexture.canvas.context2D;
    context.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
    context.clearRect(0, 0, _width, _height);

    _renderText(context);
    _renderTexture.update();
  }

  //-------------------------------------------------------------------------------------------------

  void _renderText(CanvasRenderingContext2D context) {

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

        context.font = rtf._cssFontStyle;

        if(rtf.fillGradient != null) {
          context.fillStyle = _getCanvasGradient(context, rtf.fillGradient);
        } else {
          context.fillStyle = _color2rgb(rtf.color);
        }

        if(rtf.strokeWidth > 0) {
          context.lineWidth = rtf.strokeWidth * 2;
          context.strokeStyle = _color2rgb(rtf.strokeColor);
           
          for(RichTextLineMetrics lm in _textLineMetrics) {
            context.strokeText(text, lm.x, lm.y);
            }
        }
             
        context
          ..strokeStyle = _color2rgb(rtf.color)
          ..fillText(text, lm._x + offsetX, lm._y);
        
        
        tfWidth = context.measureText(text).width;

        if(rtf.underline || rtf.strikethrough || rtf.overline) {
          var lineWidth = (rtf.bold ? rtf.size / 10 : rtf.size / 20).ceil();
          num underlineY = (lm.y + lineWidth).round();
          if (lineWidth % 2 != 0) underlineY += 0.5;

          num strikethroughY = (lm.y - rtf.size / 4).round();
          num overlineY = (lm.y - rtf.size / 1.25).round();

          context
            ..strokeStyle = _color2rgb(rtf.color)
            ..lineWidth = lineWidth
            ..beginPath();

          if(rtf.underline) context..moveTo(lm.x + offsetX, underlineY)
                              ..lineTo(lm.x + offsetX + tfWidth, underlineY);

          if(rtf.strikethrough) context..moveTo(lm.x + offsetX, strikethroughY)
          ..lineTo(lm.x + offsetX + tfWidth, strikethroughY);

          if(rtf.overline) context..moveTo(lm.x + offsetX, overlineY)
            ..lineTo(lm.x + offsetX + tfWidth, overlineY);

          context..stroke()
            ..closePath();
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

}
