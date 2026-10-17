import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';

/// Fake paywall: "buying" only flips a local flag. No charge is made.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final premium = ref.watch(premiumProvider);
    final price = ref.watch(subscriptionServiceProvider).priceLabel;
    final textTheme = Theme.of(context).textTheme;

    Widget benefit(IconData icon, String text) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 32, color: AppColors.deepGold),
              const SizedBox(width: 14),
              Expanded(child: Text(text, style: textTheme.bodyLarge)),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Bom Dia Premium')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: Text('✨', style: TextStyle(fontSize: 64))),
          const SizedBox(height: 8),
          Text(
            premium ? 'Você já é Premium!' : 'Cartões ainda mais bonitos',
            textAlign: TextAlign.center,
            style: textTheme.headlineSmall,
          ),
          const SizedBox(height: 20),
          benefit(Icons.hide_image_outlined, 'Sem a marca d\'água "Feito com o app Bom Dia"'),
          benefit(Icons.auto_awesome, 'Modelos exclusivos'),
          benefit(Icons.block, 'Sem anúncios'),
          const SizedBox(height: 28),
          if (!premium) ...[
            FilledButton(
              onPressed: () async {
                // TODO(subscription): RevenueCat purchase flow goes here.
                await ref.read(premiumProvider.notifier).purchase();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pronto! Agora você é Premium.')),
                );
                Navigator.of(context).pop();
              },
              child: Text('Assinar por $price'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () async {
                final ok = await ref.read(subscriptionServiceProvider).restore();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(ok ? 'Assinatura restaurada.' : 'Nenhuma assinatura encontrada.'),
                ));
              },
              child: const Text('Já assinei'),
            ),
          ] else
            OutlinedButton(
              onPressed: () => ref.read(premiumProvider.notifier).reset(),
              child: const Text('Desativar Premium (teste)'),
            ),
          const SizedBox(height: 20),
          Text(
            'Versão de teste: nenhuma cobrança é feita.',
            textAlign: TextAlign.center,
            style: textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
