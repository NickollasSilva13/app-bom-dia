import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Logs provider failures, which Riverpod otherwise keeps inside AsyncError.
final class ProviderLogger extends ProviderObserver {
  const ProviderLogger();

  @override
  void providerDidFail(ProviderObserverContext context, Object error, StackTrace stackTrace) {
    debugPrint('[Provider] ${context.provider.name ?? context.provider.runtimeType} falhou: $error\n$stackTrace');
  }
}
