import 'dart:html'
    show CanvasElement, querySelector, TextAreaElement, ButtonElement;
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_richtextfield/stagexl_richtextfield.dart';

void main() {
  CanvasElement canvas = querySelector('#richtext');
  TextAreaElement textarea = querySelector('#texttodraw');
  ButtonElement reload = querySelector('#reload');

  var stage = Stage(canvas);
  var render = RenderLoop();

  var format = RichTextFormat('Calibri, sans-serif', 25, 0x000000,
      align: TextFormatAlign.LEFT);

  var excited = format.clone()
    ..bold = true
    ..italic = true
    ..size = 30
    ..color = 0xFF00FF;

  var rtf = RichTextField('', format)
    ..presets['excited'] = excited
    ..text = textarea.value
    ..width = stage.sourceWidth
    ..height = stage.sourceHeight
    ..wordWrap = true;

  render.addStage(stage);
  stage.addChild(rtf);

  reload.onClick.listen((e) {
    rtf.text = textarea.value;
  });
}
