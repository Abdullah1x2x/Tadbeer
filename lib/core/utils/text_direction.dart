import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// اتجاه [text] من حروفه نفسها، فيبقى العربي من اليمين ولو كانت الواجهة
/// إنجليزية، والعكس.
TextDirection directionOfText(
  String text, {
  TextDirection fallback = TextDirection.rtl,
}) {
  final sample = text.length > 600 ? text.substring(0, 600) : text;
  if (sample.trim().isEmpty) return fallback;
  return intl.Bidi.detectRtlDirectionality(sample)
      ? TextDirection.rtl
      : TextDirection.ltr;
}
