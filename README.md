StageXL RichTextField
=====================

Rich Text Field add-on package for [StageXL](https://github.com/bp74/StageXL) - allows for multiple format ranges within a given text field.

*NOTE:* as of version 0.10.0-dev, `StageXL_RichTextField` requires a Dart 2 SDK.

[![Build Status](https://travis-ci.org/bp74/StageXL_RichTextField.svg?branch=master)](https://travis-ci.org/bp74/StageXL_RichTextField)

Usage
-----

To use StageXL RichTextFields, simply import the package after importing stagexl itself...
```dart
import 'package:stagexl/stagexl.dart';
import 'package:stagexl_richtextfield/stagexl_richtextfield.dart';

void main() {

  CanvasElement canvas = querySelector("#richtext");
  Stage stage = new Stage('richtext', canvas)
    ..scaleMode = StageScaleMode.SHOW_ALL;
  RenderLoop render = new RenderLoop();
  RichTextFormat format = new RichTextFormat('Calibri, sans-serif', 25, 0x000000, align: TextFormatAlign.LEFT);
  RichTextField rtf = new RichTextField()
    ..defaultTextFormat = format
    ..text = 'Here is some sample {b}bold{/b} text.'
    ..width = stage.sourceWidth
    ..height = stage.sourceHeight
    ..wordWrap = true
    ..y = 0;

  render.addStage(stage);
  stage.addChild(rtf);

}
```

Doing it by hand
----------------

`RichTextField` adds `startIndex` and `endIndex` fields to the RichTextFormat class.  A `-1` in `endIndex`
will anchor the format through the end of the string.  These are commonly specified in the `RichTextField.setFormat`
method, as follows:

```dart
RichTextFormat format = new RichTextFormat('Calibri, sans-serif', 25, 0x000000, align: TextFormatAlign.LEFT);
RichTextField rtf = new RichTextField('Manually setting some bold text', format, false)
    ..width = 400;

//the word "bold" above is at character positions 22 through 25
rtf.setFormat(format..bold=true, 22, 25);
```

As you add "ranged formats" to your `RichTextField` it applies logic to maintain mutually exclusive format ranges.
This means that if you added `italic=true` from `5` through `25`, and then `bold=true` from `10` through `15`, the
range from `10` to `15` will *not* be _italicized_, only **bold** - the original `5` to `25` italic is automatically
split into two ranges, one from `5` to `9`, the other from `16` to `25`.

The easy way
------------

As you can imagine, having to count character ranges simply to apply some formatting is not ideal.  To address
this, a simple parser is included which understand the set of "text tags" (wrapped in `{}`) defined below:

| Tag           | Meaning       | Example                                                  |
|---------------|---------------|----------------------------------------------------------|
| {b}           | Bold          | Some {b}bold{/b} text                                    |
| {i}           | Italic        | Now {i}italic{/i} text                                   |
| {u}           | Underline     | Can do {u}underlines{/u}                                 |
| {o}           | Overline      | And {o}overlines{/o}                                     |
| {s}           | Strikethrough | Even {s}strikethrough{/s} text                           |
| {color=}      | Set color     | Some {color=0xFF0000}red text{/color}                    |
| {font=}       | Set font      | {font=Georgia}Georgia{/font} on my mind                  |
| {size=[+-*/]} | Set size      | {size=*2}Double{/size} and {size=-5}smaller{/size}       |
| {[preset]}    | Apply preset  | I'm so {excited}excited, I just can't hide it!{/excited} |

The {[preset]} tag bears some explanation. `RichTextField` also has a public `Map<String, RichTextFormat>` field
named `presets`.  If you have some combination of styles that you use regularly, instead of wrapping multiple
tags every time, you can simply add the preset to your field and call it with a tag:

```
RichTextField rtf = new RichTextField()
    ..presets['excited'] = format.clone()..bold=true..italic=true..size=30..color=0xFF00FF;
```

### Try out the [sandbox example](http://www.stagexl.org/show/richtextfield/sandbox/example.html) to get better acquainted.

Roll your own parser
--------------------

The default included parser may not meet all of your needs.  Beyond wrapping the low-level functions,
the `parser` method itself is publically settable, so you can override with your own.
(Note: this approach could use a code review to make pluggable parsers more robust).
