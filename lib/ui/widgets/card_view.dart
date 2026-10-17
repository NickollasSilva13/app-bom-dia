import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../render/card_renderer.dart';
import '../../services/template_selector.dart';

/// The [CardContent] for [option] with the current recipient, weather,
/// date and premium state. Call from a build method. A photo background is
/// decoded at [previewWidth]; [shareCard] swaps in the full-size photo.
CardContent watchCardContent(WidgetRef ref, CardOption option, {int previewWidth = 720}) {
  final imagePath = option.template.background.image;
  return CardContent(
    template: option.template,
    recipientName: ref.watch(selectedRecipientProvider)?.name ?? '',
    phrase: option.phrase,
    date: ref.watch(clockProvider)(),
    weather: ref.watch(weatherProvider).value,
    showWatermark: !ref.watch(premiumProvider),
    backgroundImage: imagePath == null
        ? null
        : ref.watch(backgroundImageProvider((path: imagePath, width: previewWidth))).value,
  );
}

/// On-screen preview, drawn with the same code as the exported PNG.
class CardView extends StatelessWidget {
  const CardView({super.key, required this.content, this.radius = 18, this.elevated = true});

  final CardContent content;
  final double radius;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final t = content.template;
    return AspectRatio(
      aspectRatio: t.width / t.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: elevated
              ? const [BoxShadow(color: Color(0x33000000), blurRadius: 18, offset: Offset(0, 6))]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Semantics(
            image: true,
            label: 'Cartão de bom dia',
            child: CustomPaint(painter: CardPainter(content), child: const SizedBox.expand()),
          ),
        ),
      ),
    );
  }
}
