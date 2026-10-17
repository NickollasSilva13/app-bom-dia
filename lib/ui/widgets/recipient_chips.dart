import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../domain/recipient.dart';
import '../screens/recipient_edit_screen.dart';

/// Saved recipients as chips, plus "+ Adicionar". Tapping selects the name
/// shown on the card; tapping the selected one again clears it. Long press edits.
class RecipientChips extends ConsumerWidget {
  const RecipientChips({super.key});

  Future<void> _openEditor(BuildContext context, WidgetRef ref, [Recipient? recipient]) async {
    final saved = await Navigator.of(context).push<Recipient>(
      MaterialPageRoute(builder: (_) => RecipientEditScreen(recipient: recipient)),
    );
    if (saved != null) ref.read(selectedRecipientIdProvider.notifier).select(saved.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipients = ref.watch(recipientsProvider);
    final selectedId = ref.watch(selectedRecipientProvider)?.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Para quem é?', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final r in recipients)
              GestureDetector(
                onLongPress: () => _openEditor(context, ref, r),
                child: ChoiceChip(
                  label: Text(r.name),
                  selected: r.id == selectedId,
                  onSelected: (on) => ref
                      .read(selectedRecipientIdProvider.notifier)
                      .select(on ? r.id : null),
                ),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 24),
              label: const Text('Adicionar'),
              onPressed: () => _openEditor(context, ref),
            ),
          ],
        ),
        if (recipients.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Toque e segure um nome para editar.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
