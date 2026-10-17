import 'package:flutter/painting.dart';

/// A [TextPainter] already laid out to fit a box.
class FittedText {
  const FittedText(this.painter, this.fontSize);

  final TextPainter painter;
  final double fontSize;
}

/// Lays out [text] in a [box] with the largest font size, from [maxFontSize]
/// down to [minFontSize], whose wrapped lines fit. If even [minFontSize] is too
/// big, the text is cut with an ellipsis, so the result always fits.
///
/// The painter is laid out to the full box width, so [align] works inside it.
FittedText fitText({
  required String text,
  required TextStyle style,
  required Size box,
  required double maxFontSize,
  TextAlign align = TextAlign.center,
  double minFontSize = 10,
}) {
  final minSize = minFontSize.clamp(1.0, maxFontSize);

  TextPainter layout(double fontSize, {int? maxLines}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style.copyWith(fontSize: fontSize)),
      textAlign: align,
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
      ellipsis: maxLines == null ? null : '…',
    );
    painter.layout(minWidth: box.width, maxWidth: box.width);
    return painter;
  }

  bool fits(TextPainter p) => p.height <= box.height && !p.didExceedMaxLines;

  final atMax = layout(maxFontSize);
  if (fits(atMax)) return FittedText(atMax, maxFontSize);

  final atMin = layout(minSize);
  if (!fits(atMin)) {
    // Keep as many lines as fit and end with an ellipsis.
    final lineHeight = atMin.preferredLineHeight;
    final lines = (box.height / lineHeight).floor().clamp(1, 1000);
    atMin.dispose();
    return FittedText(layout(minSize, maxLines: lines), minSize);
  }

  // Binary search for the largest size that fits.
  var lo = minSize;
  var hi = maxFontSize;
  var best = atMin;
  var bestSize = minSize;
  atMax.dispose();
  while (hi - lo > 0.5) {
    final mid = (lo + hi) / 2;
    final candidate = layout(mid);
    if (fits(candidate)) {
      if (!identical(best, candidate)) best.dispose();
      best = candidate;
      bestSize = mid;
      lo = mid;
    } else {
      candidate.dispose();
      hi = mid;
    }
  }
  return FittedText(best, bestSize);
}
