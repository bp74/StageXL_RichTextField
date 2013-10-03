import 'dart:html';
import "package:stagexl/stagexl.dart";
import 'package:xml/xml.dart';
import "package:stagexl_richtextfield/stagexl_richtextfield.dart";

Stage _stage;
RichTextField textField;
void main()
{
  _stage = new Stage('stage',document.getElementById("stage"));
  _stage.scaleMode = "noScale";
  _stage.align = StageAlign.TOP_LEFT;
  RenderLoop renderLoop = new RenderLoop();
  renderLoop.addStage(_stage);


  String html = """
<HTML>
  <BODY>
     <P ALIGN="center">
        <FONT FACE="Arial" SIZE="40" COLOR="#333333" LETTERSPACING="0" KERNING="1">
           <FONT SIZE="52" COLOR="#ff5f13">
              <B>He</B>
           </FONT>
           <FONT SIZE="52" COLOR="#ebf500">
              <B>l</B>
           </FONT>
           <FONT SIZE="52" COLOR="#d5f202">
              <B>l</B>
           </FONT>
           <FONT SIZE="52" COLOR="#ff5f13">
              <B>o</B>
           </FONT>
           <FONT FACE="Calibri" SIZE="29" COLOR="#ff5f13">
              <B>
                 <I></I>
              </B>
           </FONT>
           <FONT SIZE="29" COLOR="#2325e9">
              <B>
                 <I>world</I>
              </B>
           </FONT>
        </FONT>
     </P>
     <P ALIGN="center">
        <FONT FACE="Arial" SIZE="40" COLOR="#333333" LETTERSPACING="0" KERNING="1">
           <FONT FACE="Calibri" SIZE="29" COLOR="#ff5f13">
              <B>
                 <I>
                    <U></U>
                 </I>
              </B>
           </FONT>
        </FONT>
     </P>
     <P ALIGN="center">
        <FONT FACE="Arial" SIZE="40" COLOR="#333333" LETTERSPACING="0" KERNING="1">
           <FONT FACE="Calibri" SIZE="29" COLOR="#ff5f13">
              <B>
                 <I>
                    <U></U>
                 </I>
              </B>
           </FONT>
        </FONT>
     </P>
     <P ALIGN="left">
        <FONT FACE="Arial" SIZE="40" COLOR="#333333" LETTERSPACING="0" KERNING="1">
           <FONT FACE="Times New Roman" SIZE="29" COLOR="#ff5f13">
              <I>
                 <U>Hello</U>
              </I>
           </FONT>
           <FONT FACE="Times New Roman" SIZE="29" COLOR="#ff5f13">
              <B>
                 <I>
                    <U></U>
                 </I>
              </B>
           </FONT>
           <FONT FACE="Times New Roman" SIZE="29" COLOR="#01ea14">
              <B>
                 <I>
                    <U>world</U>
                 </I>
              </B>
           </FONT>
        </FONT>
     </P>
  </BODY>
</HTML>""";


  addTextField();
  setHtmlText(html);
}

void addTextField()
{
  textField = new RichTextField();
  textField.width = 200;
  textField.height = 600;
  textField.wordWrap = true;
  _stage.addChild(textField);
}

void setHtmlText(String html)
{
  //I store the full text string in this prop so,
  //when I set it to the text field it only gets rendered once
  String fullText = "";

  XmlCollection lines = XML.parse(html).queryAll("P");

  //parse the html
  //for each line
  for(int i = 0; i < lines.length; i++)
  {
    XmlElement line = lines[i];

    //align is stored in the line (<P>) tag
    String align = line.attributes["ALIGN"];

    // lines with simpler styles only have a single <FONT> tag
    XmlElement baseFont = line.query("FONT").first;

    //lines with more complex styles have a set of child <FONT> tags
    XmlCollection fonts = baseFont.children.queryAll("FONT");

    String lineText = "";
    String textPart = "";
    if(fonts == null || fonts.length == 0)
    {
      textPart = _setFormatOfPart(baseFont, fullText.length, align);
      lineText += textPart;
      fullText += textPart;

    }
    else
    {
      for(int j = 0; j < fonts.length; j++)
      {
        XmlElement font = fonts[j] as XmlElement;
        textPart = _setFormatOfPart(font, fullText.length, align);
        lineText += textPart;
        fullText += textPart;
      }
    }
    if(lineText != "\n")
      fullText += "\n";
  }

  // erease the last \n and set the text to the text field
  fullText = fullText.substring(0,fullText.length-1);

  textField.text = fullText;
}
//what I do here is parse a single html element, that conitains styles and the accual text
//I set the styles to the text field for the correct range and return the text.
String _setFormatOfPart(XmlElement font, int startIndex, String align)
{

  String textPart = " ";
  String strColor;
  int color = 0;
  String family;
  num size;

  XmlCollection texts = font.queryAll(XmlNodeType.Text);
  if(texts != null && texts.length > 0)
  {
    XmlText nt  = texts.first as XmlText;
    textPart = nt.text;
  }
  else if(font.parent.children.length == 1)
  {
    textPart  ="\n";
  }

  bool bold = (font.queryAll("B").length > 0);
  bool italic = (font.queryAll("I").length > 0);
  bool underline = (font.queryAll("U").length > 0);


  if(font.attributes["FACE"] != null)
  {
    family = font.attributes["FACE"];
  }
  else
  {
    family = font.parent.attributes["FACE"];
  }

  if(font.attributes["SIZE"] != null)
  {
    size = int.parse(font.attributes["SIZE"]);
  }
  else
  {
    size = int.parse(font.parent.attributes["SIZE"]);
  }

  if(font.attributes["COLOR"] != null)
  {
    strColor = font.attributes["COLOR"];

    if(strColor != null)
      color = hexToNum(strColor.replaceAll("#", ""));
  }
  else
  {
    strColor = font.parent.attributes["COLOR"];

    if(strColor != null)
      color = hexToNum(strColor.replaceAll("#", ""));
  }

  int endIndex = startIndex+textPart.length-1;

  if(textPart == null || textPart.length == 0)
    endIndex += 1;

  textField.setFormat(new RichTextFormat(family, size, color, bold: bold, italic:italic, underline:underline, align:align)
  ,startIndex,endIndex);

  return textPart;
}
num hexToNum(String hex)
{
  int val = 0;

  int len = hex.length;
  for (int i = 0; i < len; i++) {
    int hexDigit = hex.codeUnitAt(i);// charCodeAt(i);
    if (hexDigit >= 48 && hexDigit <= 57) {
      val += (hexDigit - 48) * (1 << (4 * (len - 1 - i)));
    } else if (hexDigit >= 65 && hexDigit <= 70) {
      // A..F
      val += (hexDigit - 55) * (1 << (4 * (len - 1 - i)));
    } else if (hexDigit >= 97 && hexDigit <= 102) {
      // a..f
      val += (hexDigit - 87) * (1 << (4 * (len - 1 - i)));
    } else {
      throw new Exception("Bad hexidecimal value");
    }
  }

  return val;
}