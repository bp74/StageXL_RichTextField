library stagexl_richtextfield;

import 'dart:html' as html;
import 'dart:math' show min, max, sqrt;
import 'dart:html' show CanvasElement, CanvasRenderingContext2D, CanvasGradient;
import 'package:stagexl/stagexl.dart';

part 'src/rich_font_style_metrics.dart';
part 'src/rich_text_field.dart';
part 'src/rich_text_format.dart';
part 'src/rich_text_line_metrics.dart';
part 'src/rich_text_parser.dart';
part 'src/tools.dart';

final CanvasElement _dummyCanvas = new CanvasElement(width: 16, height: 16);
final CanvasRenderingContext2D _dummyCanvasContext = _dummyCanvas.context2D;
