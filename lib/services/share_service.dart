import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'native_bridge.dart';

enum ShareTarget { whatsapp, systemSheet }

/// Saves the card PNG to the temporary directory and shares it, trying
/// WhatsApp directly first and falling back to the system share sheet.
class ShareService {
  const ShareService({this.bridge = const NativeBridge()});

  final NativeBridge bridge;
  static const _prefix = 'bom_dia_';

  Future<File> savePng(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    // Old cards are no longer needed once a new one is generated.
    try {
      for (final entity in dir.listSync()) {
        if (entity is File && entity.uri.pathSegments.last.startsWith(_prefix)) {
          entity.deleteSync();
        }
      }
    } on FileSystemException {
      // A file still in use by the share target; it is cleaned up next time.
    }
    final file = File('${dir.path}/$_prefix${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<ShareTarget> shareImage(File file) async {
    if (await bridge.shareToWhatsApp(file.path)) return ShareTarget.whatsapp;
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
    );
    return ShareTarget.systemSheet;
  }
}
