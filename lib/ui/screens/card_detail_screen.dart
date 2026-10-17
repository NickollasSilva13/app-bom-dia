import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/template_selector.dart';
import '../card_actions.dart';
import '../widgets/card_view.dart';
import '../widgets/send_button.dart';

/// A card picked in the gallery, big, with the send button.
class CardDetailScreen extends ConsumerStatefulWidget {
  const CardDetailScreen({super.key, required this.option});

  final CardOption option;

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final content = watchCardContent(ref, widget.option);
    return Scaffold(
      appBar: AppBar(title: Text(widget.option.occasion.label)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            children: [
              Expanded(child: Center(child: CardView(content: content))),
              const SizedBox(height: 20),
              SendButton(
                busy: _sending,
                onPressed: () async {
                  setState(() => _sending = true);
                  await shareCard(context, ref, widget.option, content);
                  if (mounted) setState(() => _sending = false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
