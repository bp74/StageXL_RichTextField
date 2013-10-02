part of stagexl_richtextfield;

class RichTextFormat {

  String font;
  num size;
  int color;

  int startIndex;
  int endIndex;
  bool bold;
  bool italic;
  bool underline;
  String align;

  num topMargin;
  num bottomMargin;
  num leftMargin;
  num rightMargin;
  num indent;
  num leading;

  //-------------------------------------------------------------------------------------------------

  RichTextFormat(this.font, this.size, this.color, {
    this.startIndex   : 0,
    this.endIndex     : -1,
    this.bold         : false,
    this.italic       : false,
    this.underline    : false,
    this.align        : "left",
    this.topMargin    : 0.0,
    this.bottomMargin : 0.0,
    this.leftMargin   : 0.0,
    this.rightMargin  : 0.0,
    this.indent       : 0.0,
    this.leading      : 0.0
  });

  //-------------------------------------------------------------------------------------------------

  RichTextFormat clone() {
    return new RichTextFormat(font, size, color, startIndex: startIndex, endIndex: endIndex,
        bold: bold, italic: italic, underline: underline, align: align,
        topMargin: topMargin, bottomMargin: bottomMargin, leftMargin: leftMargin, rightMargin: rightMargin,
        indent: indent, leading: leading);
  }

  //-------------------------------------------------------------------------------------------------

  String get _cssFontStyle {
    var fontStyle = "${size}px ${font}, sans-serif";
    if (bold) fontStyle = "bold $fontStyle";
    if (italic) fontStyle = "italic $fontStyle";
    return fontStyle;
  }

}
