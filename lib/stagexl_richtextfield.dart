library stagexl_richtextfield;

import 'dart:html' as html;
import 'dart:math' show min, max, sqrt;
import 'package:stagexl/stagexl.dart';

import 'dart:html' show
CanvasElement, CanvasRenderingContext2D, CanvasImageSource,
CanvasPattern, CanvasGradient, ImageData;

part 'src/richfontstylemetrics.dart';
part 'src/richtextfield.dart';
part 'src/richtextformat.dart';
part 'src/richtextlinemetrics.dart';
part 'src/tools.dart';

final CanvasElement _dummyCanvas = new CanvasElement(width: 16, height: 16);
final CanvasRenderingContext2D _dummyCanvasContext = _dummyCanvas.context2D;
