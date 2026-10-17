import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/providers.dart';
import '../render/card_renderer.dart';
import '../services/template_selector.dart';
import 'screens/paywall_screen.dart';

/// Renders [content] to PNG and sends it: WhatsApp first, share sheet as
/// fallback. Ads run only after the share. Returns false on failure.
Future<bool> shareCard(BuildContext context, WidgetRef ref, CardOption option, CardContent content) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    // The preview may hold a downsampled photo (or none yet): export with the
    // full-size one so the PNG stays sharp.
    final imagePath = content.template.background.image;
    final fullImage = imagePath == null ? null : await decodeAssetImage(imagePath);
    final Uint8List bytes;
    try {
      bytes = await cardRenderer.renderPng(content.withBackgroundImage(fullImage));
    } finally {
      fullImage?.dispose();
    }
    final share = ref.read(shareServiceProvider);
    final file = await share.savePng(bytes);
    final target = await share.shareImage(file);
    await ref.read(analyticsProvider).cardShared(
          occasion: option.occasion.id,
          templateId: option.template.id,
          target: target.name,
        );
    await ref.read(adsServiceProvider).onCardShared(isPremium: ref.read(premiumProvider));
    return true;
  } catch (e) {
    debugPrint('[Share] falhou: $e');
    messenger.showSnackBar(
      const SnackBar(content: Text('Não foi possível enviar. Tente de novo.')),
    );
    return false;
  }
}

Future<void> openPaywall(BuildContext context, WidgetRef ref, {required String source}) {
  ref.read(analyticsProvider).paywallViewed(source: source);
  return Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const PaywallScreen()));
}
