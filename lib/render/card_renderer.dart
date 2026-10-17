import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../domain/card_template.dart';
import '../domain/card_text.dart';
import '../domain/weather.dart';
import 'text_fit.dart';

/// Everything needed to draw one card.
class CardContent {
  const CardContent({
    required this.template,
    required this.recipientName,
    required this.phrase,
    required this.date,
    this.weather,
    this.showWatermark = true,
    this.backgroundImage,
  });

  final CardTemplate template;
  final String recipientName;
  final String phrase;
  final DateTime date;

  /// Without weather the `weather` slot is skipped.
  final Weather? weather;
  final bool showWatermark;

  /// Decoded `background.image`, when the template has one.
  final ui.Image? backgroundImage;

  CardContent withBackgroundImage(ui.Image? image) => CardContent(
        template: template,
        recipientName: recipientName,
        phrase: phrase,
        date: date,
        weather: weather,
        showWatermark: showWatermark,
        backgroundImage: image,
      );

  @override
  bool operator ==(Object other) =>
      other is CardContent &&
      identical(other.template, template) &&
      other.recipientName == recipientName &&
      other.phrase == phrase &&
      other.date.year == date.year &&
      other.date.month == date.month &&
      other.date.day == date.day &&
      other.weather == weather &&
      other.showWatermark == showWatermark &&
      identical(other.backgroundImage, backgroundImage);

  @override
  int get hashCode => Object.hash(template.id, recipientName, phrase, date.year,
      date.month, date.day, weather, showWatermark, backgroundImage);
}

/// Draws a [CardTemplate] on a canvas in the template's own pixel space
/// (1080×1350 by default). The on-screen preview ([CardPainter]) and the PNG
/// export use this same code, so what is shown is exactly what is sent.
class CardRenderer {
  const CardRenderer();

  static const _dateLocale = 'pt_BR';

  void paint(Canvas canvas, CardContent content) {
    final t = content.template;
    final rect = Rect.fromLTWH(0, 0, t.width, t.height);
    canvas.save();
    canvas.clipRect(rect);
    _paintBackground(canvas, rect, t.background, content.backgroundImage);
    for (final overlay in t.overlays) {
      if (overlay.isGradient) {
        canvas.drawRect(
          rect,
          Paint()..shader = _linearGradient(rect, overlay.angle, overlay.colors, overlay.stops),
        );
      } else if (overlay.opacity > 0) {
        canvas.drawRect(rect, Paint()..color = Color(overlay.color).withValues(alpha: overlay.opacity));
      }
    }
    for (final d in t.decorations) {
      _paintDecoration(canvas, rect.size, d);
    }
    for (final slot in t.slots) {
      final text = textForSlot(slot, content);
      if (text == null || text.isEmpty) continue;
      _paintText(canvas, rect.size, slot, text);
    }
    canvas.restore();
  }

  /// The text a slot shows, or null when it should not be drawn.
  String? textForSlot(TemplateSlot slot, CardContent content) {
    switch (slot.type) {
      case SlotType.greeting:
        return fillName(slot.text ?? 'Bom dia, {nome}!', content.recipientName);
      case SlotType.phrase:
        return content.phrase;
      case SlotType.date:
        final pattern = slot.format ?? "EEEE, d 'de' MMMM";
        return capitalizeFirst(DateFormat(pattern, _dateLocale).format(content.date));
      case SlotType.weather:
        final w = content.weather;
        if (w == null) return null;
        return formatWeather(slot.format ?? '{cidade} • {temp}°C {icone}', w);
      case SlotType.watermark:
        return content.showWatermark ? (slot.text ?? 'Feito com o app Bom Dia') : null;
      case SlotType.text:
        return slot.text == null ? null : fillName(slot.text!, content.recipientName);
    }
  }

  /// Renders at the template's full size (1080×1350).
  Future<ui.Image> renderImage(CardContent content) {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), content);
    final picture = recorder.endRecording();
    final t = content.template;
    return picture.toImage(t.width.round(), t.height.round()).whenComplete(picture.dispose);
  }

  Future<Uint8List> renderPng(CardContent content) async {
    final image = await renderImage(content);
    try {
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  /// CSS-style linear gradient: 0° points up, 90° right. Stops default to
  /// evenly spaced.
  static Shader _linearGradient(Rect rect, double angle, List<int> argb, List<double>? stops) {
    final radians = angle * math.pi / 180;
    final dir = Offset(math.sin(radians), -math.cos(radians));
    final halfLength =
        (rect.width * math.sin(radians).abs() + rect.height * math.cos(radians).abs()) / 2;
    final center = rect.center;
    return ui.Gradient.linear(
      center - dir * halfLength,
      center + dir * halfLength,
      argb.map(Color.new).toList(),
      stops ?? [for (var i = 0; i < argb.length; i++) i / (argb.length - 1)],
    );
  }

  void _paintBackground(Canvas canvas, Rect rect, TemplateBackground bg, ui.Image? image) {
    if (bg.type == BackgroundType.gradient && bg.colors.length >= 2) {
      canvas.drawRect(rect, Paint()..shader = _linearGradient(rect, bg.angle, bg.colors, null));
    } else {
      // Also the placeholder while a photo is still loading.
      canvas.drawRect(rect, Paint()..color = Color(bg.colors.first));
    }
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: rect,
        image: image,
        fit: BoxFit.cover,
        alignment: Alignment(bg.focusX * 2 - 1, bg.focusY * 2 - 1),
        filterQuality: FilterQuality.medium,
      );
    }
  }

  void _paintDecoration(Canvas canvas, Size size, TemplateDecoration d) {
    final center = Offset(d.x * size.width, d.y * size.height);
    switch (d.type) {
      case DecorationType.circle:
        final radius = d.size * size.width;
        canvas.drawCircle(
          center,
          radius,
          Paint()
            ..color = Color(d.color).withValues(alpha: d.opacity)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.35),
        );
      case DecorationType.sparkle:
        final r = d.size * size.width;
        final color = Color(d.color);
        // Soft halo, then a thin four-pointed star.
        canvas.drawCircle(
          center,
          r * 0.55,
          Paint()
            ..color = color.withValues(alpha: d.opacity * 0.45)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.35),
        );
        final w = r * 0.14;
        final star = Path()
          ..moveTo(center.dx, center.dy - r)
          ..quadraticBezierTo(center.dx + w, center.dy - w, center.dx + r, center.dy)
          ..quadraticBezierTo(center.dx + w, center.dy + w, center.dx, center.dy + r)
          ..quadraticBezierTo(center.dx - w, center.dy + w, center.dx - r, center.dy)
          ..quadraticBezierTo(center.dx - w, center.dy - w, center.dx, center.dy - r)
          ..close();
        canvas.drawPath(star, Paint()..color = color.withValues(alpha: d.opacity));
      case DecorationType.emoji:
        final value = d.value;
        if (value == null || value.isEmpty) return;
        final painter = TextPainter(
          text: TextSpan(
            text: value,
            style: TextStyle(
              fontSize: d.size * size.width,
              color: Color.fromRGBO(0, 0, 0, d.opacity),
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
        painter.dispose();
    }
  }

  void _paintText(Canvas canvas, Size size, TemplateSlot slot, String text) {
    final box = Rect.fromLTWH(
      slot.box.x * size.width,
      slot.box.y * size.height,
      slot.box.w * size.width,
      slot.box.h * size.height,
    );
    final color = Color(slot.color);
    final weight = slot.weight.clamp(100, 900);
    final style = TextStyle(
      fontFamily: slot.font,
      color: color,
      fontWeight: FontWeight.values[(weight ~/ 100) - 1],
      // The bundled Montserrat and Playfair are variable fonts.
      fontVariations: [FontVariation('wght', weight.toDouble())],
      height: 1.15,
    );
    final fitted = fitText(
      text: text,
      style: style,
      box: box.size,
      maxFontSize: slot.maxFontSize,
      minFontSize: math.min(14, slot.maxFontSize),
      align: switch (slot.align) {
        SlotAlign.left => TextAlign.left,
        SlotAlign.center => TextAlign.center,
        SlotAlign.right => TextAlign.right,
      },
    );
    var painter = fitted.painter;
    if (slot.shadow) {
      // Re-layout with shadows sized to the final font size.
      final fs = fitted.fontSize;
      // Dark shadow behind light text, light glow behind dark text.
      final lightText = color.computeLuminance() > 0.5;
      final shade = lightText ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
      final shadowed = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontSize: fs, shadows: [
            Shadow(color: shade.withValues(alpha: 0.45), offset: Offset(0, fs * 0.04), blurRadius: fs * 0.18),
            Shadow(color: shade.withValues(alpha: 0.35), offset: Offset(0, fs * 0.015), blurRadius: fs * 0.05),
          ]),
        ),
        textAlign: painter.textAlign,
        textDirection: TextDirection.ltr,
        maxLines: painter.maxLines,
        ellipsis: painter.ellipsis,
      )..layout(minWidth: box.width, maxWidth: box.width);
      painter.dispose();
      painter = shadowed;
    }
    final offset = Offset(box.left, box.top + (box.height - painter.height) / 2);
    final strokeColor = slot.strokeColor;
    if (strokeColor != null && slot.strokeWidth > 0) {
      // Same text and layout as the fill, drawn first as an outline.
      final outline = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(
            fontSize: fitted.fontSize,
            color: null,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = fitted.fontSize * slot.strokeWidth
              ..strokeJoin = StrokeJoin.round
              ..color = Color(strokeColor),
          ),
        ),
        textAlign: painter.textAlign,
        textDirection: TextDirection.ltr,
        maxLines: painter.maxLines,
        ellipsis: painter.ellipsis,
      )..layout(minWidth: box.width, maxWidth: box.width);
      outline.paint(canvas, offset);
      outline.dispose();
    }
    painter.paint(canvas, offset);
    painter.dispose();
  }
}

/// Paints a card scaled to the widget's size, using [CardRenderer].
class CardPainter extends CustomPainter {
  const CardPainter(this.content, {this.renderer = const CardRenderer()});

  final CardContent content;
  final CardRenderer renderer;

  @override
  void paint(Canvas canvas, Size size) {
    final t = content.template;
    canvas.save();
    canvas.scale(size.width / t.width, size.height / t.height);
    renderer.paint(canvas, content);
    canvas.restore();
  }

  @override
  bool shouldRepaint(CardPainter oldDelegate) => oldDelegate.content != content;
}
