import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show DateFormat;

import '../../app/providers.dart';
import '../../domain/recipient.dart';

/// Name as it appears on the card and an optional birth date. Nothing else.
/// Pops with the saved [Recipient], or null when deleted or cancelled.
class RecipientEditScreen extends ConsumerStatefulWidget {
  const RecipientEditScreen({super.key, this.recipient});

  final Recipient? recipient;

  @override
  ConsumerState<RecipientEditScreen> createState() => _RecipientEditScreenState();
}

class _RecipientEditScreenState extends ConsumerState<RecipientEditScreen> {
  late final _name = TextEditingController(text: widget.recipient?.name ?? '');
  late DateTime? _birthDate = widget.recipient?.birthDate;
  bool get _isNew => widget.recipient == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 60, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      // Typing dd/mm/aaaa is easier than paging back decades in a calendar.
      initialEntryMode: DatePickerEntryMode.input,
      helpText: 'Data de nascimento',
      fieldLabelText: 'Data (dd/mm/aaaa)',
      fieldHintText: 'dd/mm/aaaa',
      errorFormatText: 'Use o formato dd/mm/aaaa',
      errorInvalidText: 'Data inválida',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escreva o nome que vai aparecer no cartão.')),
      );
      return;
    }
    final notifier = ref.read(recipientsProvider.notifier);
    Recipient saved;
    if (_isNew) {
      saved = await notifier.add(name: name, birthDate: _birthDate);
      ref.read(analyticsProvider).recipientAdded(hasBirthDate: _birthDate != null);
    } else {
      saved = widget.recipient!.copyWith(
        name: name,
        birthDate: _birthDate,
        clearBirthDate: _birthDate == null,
      );
      await notifier.edit(saved);
    }
    if (mounted) Navigator.of(context).pop(saved);
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar este nome?'),
        content: Text('"${widget.recipient!.name}" sai da sua lista.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Apagar')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(recipientsProvider.notifier).remove(widget.recipient!.id);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'Novo nome' : 'Editar nome')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Como o nome vai aparecer no cartão', style: textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _name,
            autofocus: _isNew,
            maxLength: 30,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 22),
            decoration: const InputDecoration(hintText: 'Ex.: Dona Cida, Grupo da família'),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          Text('Data de nascimento (opcional)', style: textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('No dia do aniversário, o app sugere um cartão especial.', style: textTheme.bodySmall),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.cake_outlined, size: 26),
            label: Text(_birthDate == null
                ? 'Escolher data'
                : DateFormat("d 'de' MMMM 'de' y", 'pt_BR').format(_birthDate!)),
          ),
          if (_birthDate != null)
            TextButton(
              onPressed: () => setState(() => _birthDate = null),
              child: const Text('Remover data'),
            ),
          const SizedBox(height: 28),
          FilledButton(onPressed: _save, child: const Text('Salvar')),
          if (!_isNew) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline, size: 26),
              label: const Text('Apagar este nome'),
            ),
          ],
        ],
      ),
    );
  }
}
