import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The big green "Enviar no WhatsApp" button, with a busy state.
class SendButton extends StatelessWidget {
  const SendButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.whatsapp,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(64),
        textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
      ),
      onPressed: busy ? null : onPressed,
      icon: busy
          ? const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
            )
          : const Icon(Icons.send_rounded, size: 28),
      label: Text(busy ? 'Preparando…' : 'Enviar no WhatsApp'),
    );
  }
}
