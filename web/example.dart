import 'dart:html' show CanvasElement, query;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_richtextfield/stagexl_richtextfield.dart';

void main() {

  CanvasElement canvas = query("#richtext");
  Stage stage = new Stage('richtext', canvas)
    ..scaleMode = StageScaleMode.SHOW_ALL;
  RenderLoop render = new RenderLoop();
  RichTextFormat format = new RichTextFormat('Calibri, sans-serif', 25, 0x000000, align: TextFormatAlign.LEFT);
  RichTextField rtf = new RichTextField(
      'Trying this out - making some bold, some italic, some underline, some bigger, some smaller, and some bold-blue',
     //00000000001111111111222222222233333333334444444444555555555566666666667777777777888888888899999999990000000000
     //01234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789
      format)
    ..width = stage.sourceWidth
    ..wordWrap = true
    ..y = 50;

  rtf.setFormat(format.clone()..bold=true, 18, 33);
  rtf.setFormat(format.clone()..italic=true, 36, 46);
  rtf.setFormat(format.clone()..underline=true, 49, 62);
  rtf.setFormat(format.clone()..size=40, 65, 75);
  rtf.setFormat(format.clone()..size=10, 78, 89);
  rtf.setFormat(format.clone()..color=Color.Blue..bold=true, 92, -1);

  render.addStage(stage);
  stage.addChild(rtf);

}

