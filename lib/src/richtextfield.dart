part of stagexl_richtextfield;

class RichTextField extends InteractiveObject {

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
  var parser;

  int _refreshPending = 3;   // bit 0: textLineMetrics, bit 1: cache
  bool _cacheAsBitmap = true;
  CanvasElement _cacheAsBitmapCanvas;
  RenderTexture _renderTexture;

  //-------------------------------------------------------------------------------------------------

  RichTextField([String text = "", RichTextFormat textFormat, bool parse = true]) {

    this.defaultTextFormat = (textFormat != null) ? textFormat : new RichTextFormat("Arial", 12, 0x000000);
    this.parse = parse;
    this.parser = defaultParser;
    if(parse && text != "") {
      this._rawText = this.text;
      parser(text);
    } else this.text = text;

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
        RichTextFormat f2 = cur.clone();

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

  }

  defaultParser(String rawtext) {
    int pos = 0;
    String action;
    String newtext = '';
    var arg;
    List<List> formatRanges = [];
    List split = rawtext.split('{');
    split.forEach((chunk) {
      List actText = chunk.split('}');
      if(actText.length==1) { //text prior to first tag
        newtext = newtext + actText[0];
      } else { //get action
        action = actText[0];
        if(!action.startsWith('/')) { //opening a range
          //check for argument
          if(action.contains('=')) {
            List actArg = action.split('=');
            action = actArg[0];
            arg = actArg[1];
          }
          formatRanges.add([action,arg,pos,-1]); //second+ appearance
        } else { //closing a range
          action = action.substring(1);
          formatRanges.lastWhere((e) => e[3] == -1)[3] = pos-1; //get last unclosed range for that action
        }
        newtext = newtext + actText[1];
      }
      pos = newtext.length;
    });

    this._text = newtext;

    RichTextFormat base;
    formatRanges.forEach((range) {
      //get known format for starting position
      base = getFormatAt(range[2]).clone();
      //if format here ends before this one, make two
      switch(range[0]) {
        case 'b': base.bold = true; break;
        case 'u': base.underline = true; break;
        case 'i': base.italic = true; break;
        case 's': base.strikethrough = true; break;
        case 'o': base.overline = true; break;
        case 'color': base.color = _applyTextTagArg(range[1], base.color).toInt(); break;
        case 'size': base.size = _applyTextTagArg(range[1],base.size); break;
        case 'font': base.font = range[1]; break;
        default:
          if(presets.containsKey(range[0])) base = presets[range[0]];
          break;
      }

      setFormat(base, range[2], range[3]);

    });

  }

  num _applyTextTagArg(String arg, base) {
    num result = 0;
    if('+-*/'.contains(arg.substring(0, 1))) {
      String op = arg.substring(0, 1);
      result = arg.contains('x')?int.parse(arg.substring(1)):double.parse(arg.substring(1));
      switch(op) {
        case '+': result = base + result; break;
        case '-': result = base - result; break;
        case '*': result = base * result; break;
        case '/': result = base / result; break;
      }
    } else result = arg.contains('x')?int.parse(arg):double.parse(arg);

    return result;

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
    _rawText = _text;
    if(parse && value != "") {
      _textFormats.removeRange(1, _textFormats.length);
      _textFormats[0].endIndex = -1;
      parser(text);
    }
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

  void set parse(bool value) {
    _parse = value;
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
    
    var renderContext = renderState.renderContext;

    if (_cacheAsBitmap || renderContext is! RenderContextCanvas) {
      _refreshCache();
      renderState.renderQuad(_renderTexture.quad);
    } else {
      var renderContextCanvas = renderState.renderContext as RenderContextCanvas;
      var context = renderContextCanvas.rawContext;
      var matrix = renderState.globalMatrix;
      context.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
      context.globalAlpha = renderState.globalAlpha;
      _renderText(renderContextCanvas.rawContext);
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
      var lineEndIndex = textLineMetrics._text.length + lineIndex;
      var textFormatSize = 0;
      RichTextFormat lineFormat = _textFormats.firstWhere((f) => lineIndex>=f.startIndex && (lineIndex<=f.endIndex || f.endIndex == -1));
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

  _refreshCache() {

    if ((_refreshPending & 2) == 0) {
      return;
    } else {
      _refreshPending &= 255 - 2;
    }

    var pixelRatio = Stage.autoHiDpi ? _devicePixelRatio : 1.0;
    var width = max(1, _width).ceil();
    var height =  max(1, _height).ceil();

    if (_renderTexture == null) {
      _renderTexture = new RenderTexture(width, height, true, Color.Transparent, pixelRatio);
    } else {
      _renderTexture.resize(width, height);
    }

    var matrix = _renderTexture.quad.drawMatrix;
    var context = _renderTexture.canvas.context2D;
    context.setTransform(matrix.a, matrix.b, matrix.c, matrix.d, matrix.tx, matrix.ty);
    context.clearRect(0, 0, _width, _height);

    _renderText(context);
    _renderTexture.update();
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

        context.font = rtf._cssFontStyle;

        if(rtf.fillGradient != null) {
          context.fillStyle = rtf.fillGradient.getCanvasGradient(context);
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

   //-------------------------------------------------------------------------------------------------

  _onMouseDown(MouseEvent mouseEvent) {
    //use this for simple "did user click on this textfield" logic

  }
}
