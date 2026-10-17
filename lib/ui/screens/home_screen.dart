import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/occasion.dart';
import '../../services/template_selector.dart';
import '../card_actions.dart';
import '../widgets/card_view.dart';
import '../widgets/recipient_chips.dart';
import '../widgets/send_button.dart';

/// "Hoje": today's card, ready to send.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<CardOption>>(todayCardProvider, (previous, next) {
      final card = next.value;
      if (card != null && card.template.id != previous?.value?.template.id) {
        ref.read(analyticsProvider).cardGenerated(
              occasion: card.occasion.id,
              templateId: card.template.id,
            );
      }
    });

    final today = ref.watch(todayCardProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bom Dia ☀️')),
      body: today.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const _ErrorMessage(),
        data: (option) => _buildCard(context, option),
      ),
    );
  }

  Widget _buildCard(BuildContext context, CardOption option) {
    final content = watchCardContent(ref, option);
    final maxCardHeight = MediaQuery.sizeOf(context).height * 0.52;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text(
          _caption(option.occasion),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxCardHeight),
            child: CardView(content: content),
          ),
        ),
        const SizedBox(height: 20),
        const RecipientChips(),
        const SizedBox(height: 22),
        SendButton(
          busy: _sending,
          onPressed: () async {
            setState(() => _sending = true);
            await shareCard(context, ref, option, content);
            if (mounted) setState(() => _sending = false);
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _sending
              ? null
              : () {
                  ref.read(swapProvider.notifier).next();
                  ref.read(analyticsProvider).cardSwapped(occasion: option.occasion.id);
                },
          icon: const Icon(Icons.autorenew_rounded, size: 28),
          label: const Text('Trocar'),
        ),
      ],
    );
  }

  String _caption(Occasion occasion) => switch (occasion) {
        Occasion.generico => 'Seu cartão de hoje',
        Occasion.aniversario => 'Hoje é aniversário! 🎂',
        _ => 'Cartão de hoje: ${occasion.label}',
      };
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Não conseguimos montar o cartão. Feche e abra o app de novo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
}
