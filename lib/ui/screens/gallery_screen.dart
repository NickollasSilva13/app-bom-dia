import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../domain/occasion.dart';
import '../../services/template_selector.dart';
import '../card_actions.dart';
import '../widgets/card_view.dart';
import '../widgets/recipient_chips.dart';
import 'card_detail_screen.dart';

class _GalleryTab {
  const _GalleryTab(this.label, this.occasions);

  final String label;
  final List<Occasion> occasions;
}

const _tabs = [
  _GalleryTab('Bom dia', [
    Occasion.generico,
    Occasion.segunda,
    Occasion.sexta,
    Occasion.sabado,
    Occasion.domingo,
    Occasion.chuva,
    Occasion.frio,
    Occasion.calor,
  ]),
  _GalleryTab('Boa noite', [Occasion.boaNoite]),
  _GalleryTab('Aniversário', [Occasion.aniversario]),
  _GalleryTab('Datas especiais', [
    Occasion.natal,
    Occasion.anoNovo,
    Occasion.diaDasMaes,
    Occasion.diaDosPais,
    Occasion.diaDosNamorados,
    Occasion.diaDasCriancas,
    Occasion.diaDosAvos,
    Occasion.carnaval,
    Occasion.feriado,
  ]),
];

/// Every card by occasion, already with the chosen name.
class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Galeria'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [for (final t in _tabs) Tab(height: 56, text: t.label)],
          ),
        ),
        body: TabBarView(children: [for (final t in _tabs) _GalleryGrid(tab: t)]),
      ),
    );
  }
}

class _GalleryGrid extends ConsumerWidget {
  const _GalleryGrid({required this.tab});

  final _GalleryTab tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selector = ref.watch(selectorProvider);
    final recipientId = ref.watch(selectedRecipientProvider)?.id;
    final date = ref.watch(clockProvider)();
    return selector.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(child: Text('Não foi possível carregar os cartões.')),
      data: (s) {
        // Photo cards first: they are the showcase. The sort is stable, so
        // each group keeps the selector's order.
        final options = s.galleryOptions(tab.occasions, date: date, recipientId: recipientId)
          ..sort((a, b) => (a.template.background.image == null ? 1 : 0)
              .compareTo(b.template.background.image == null ? 1 : 0));
        return CustomScrollView(
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              sliver: SliverToBoxAdapter(child: RecipientChips()),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1080 / 1350,
                ),
                itemCount: options.length,
                itemBuilder: (context, i) => _GalleryItem(option: options[i]),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GalleryItem extends ConsumerWidget {
  const _GalleryItem({required this.option});

  final CardOption option;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locked = option.template.premium && !ref.watch(premiumProvider);
    final content = watchCardContent(ref, option, previewWidth: 400);
    return Semantics(
      button: true,
      label: locked ? 'Cartão Premium, bloqueado' : 'Abrir cartão',
      child: GestureDetector(
        onTap: () {
          if (locked) {
            openPaywall(context, ref, source: 'gallery');
          } else {
            Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => CardDetailScreen(option: option)),
            );
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(child: CardView(content: content, radius: 12, elevated: false)),
            if (locked)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brown.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock, color: Colors.white, size: 20),
                      SizedBox(width: 4),
                      Text('Premium', style: TextStyle(color: Colors.white, fontSize: 18)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
