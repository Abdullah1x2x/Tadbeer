import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' as intl;

/// Direction of [text] judged from its own letters, so Arabic content stays
/// right to left even when the interface is in English (and the reverse).
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
