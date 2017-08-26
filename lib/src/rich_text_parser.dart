part of stagexl_richtextfield;

abstract class RichTextParser {
  String parse(RichTextField richTextField, String rawtext);
}

class DefaultRichTextParser extends RichTextParser {

  @override
  String parse(RichTextField richTextField, String rawtext) {

    String action = '';
    String newtext = '';
    String arg = '';
    int pos = 0;

    List<List<Object>> formatRanges = new List<List<Object>>();
    List<String> split = rawtext.split('{');

    for(var chunk in split) {
      List actText = chunk.split('}');
      if (actText.length == 1) { //text prior to first tag
        newtext = newtext + actText[0];
      } else { //get action
        action = actText[0];
        if (!action.startsWith('/')) { //opening a range
          //check for argument
          if (action.contains('=')) {
            var actArg = action.split('=');
            action = actArg[0];
            arg = actArg[1];
          }
          formatRanges.add([action, arg, pos, -1]); //second+ appearance
        } else { //closing a range
          action = action.substring(1);
          formatRanges.lastWhere((e) => e[3] == -1)[3] =
              pos - 1; //get last unclosed range for that action
        }
        newtext = newtext + actText[1];
      }
      pos = newtext.length;
    }

    RichTextFormat base;

    formatRanges.forEach((range) {
      //get known format for starting position
      base = richTextField.getFormatAt(range[2]).clone();
      //if format here ends before this one, make two
      switch (range[0]) {
        case 'b':
          base.bold = true;
          break;
        case 'u':
          base.underline = true;
          break;
        case 'i':
          base.italic = true;
          break;
        case 's':
          base.strikethrough = true;
          break;
        case 'o':
          base.overline = true;
          break;
        case 'color':
          base.color = _applyTextTagArg(range[1], base.color).toInt();
          break;
        case 'size':
          base.size = _applyTextTagArg(range[1], base.size);
          break;
        case 'font':
          base.font = range[1];
          break;
        default:
          if (richTextField.presets.containsKey(range[0])) {
            base = richTextField.presets[range[0]];
          }
          break;
      }

      richTextField.setFormat(base, range[2], range[3]);
    });

    return newtext;
  }

  num _applyTextTagArg(String arg, base) {

    num result = 0;

    if ('+-*/'.contains(arg.substring(0, 1))) {
      String op = arg.substring(0, 1);
      result = arg.contains('x') ? int.parse(arg.substring(1)) : double.parse(arg.substring(1));
      switch (op) {
        case '+':
          result = base + result;
          break;
        case '-':
          result = base - result;
          break;
        case '*':
          result = base * result;
          break;
        case '/':
          result = base / result;
          break;
      }
    } else {
      result = arg.contains('x') ? int.parse(arg) : double.parse(arg);
    }

    return result;
  }
}