import 'package:bom_dia/render/text_fit.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const style = TextStyle(fontFamily: 'Montserrat', height: 1.15);
  const longText =
      'Que o seu dia seja leve como uma manhã de domingo, cheio de café quentinho, '
      'conversa boa, abraço apertado e aquela paz que só quem a gente ama sabe dar. '
      'Que nada tire o seu sorriso hoje, nem amanhã, nem depois de amanhã.';

  void expectFits(FittedText f, Size box) {
    expect(f.painter.height, lessThanOrEqualTo(box.height));
    expect(f.painter.width, lessThanOrEqualTo(box.width));
  }

  test('texto curto usa o tamanho máximo', () {
    const box = Size(800, 200);
    final f = fitText(text: 'Bom dia!', style: style, box: box, maxFontSize: 64);
    expect(f.fontSize, 64);
    expectFits(f, box);
  });

  test('texto longo reduz a fonte e cabe', () {
    const box = Size(860, 340);
    final f = fitText(text: longText, style: style, box: box, maxFontSize: 120);
    expect(f.fontSize, lessThan(120));
    expect(f.painter.computeLineMetrics().length, greaterThan(1));
    expectFits(f, box);
  });

  test('texto longo sempre cabe, mesmo em caixas pequenas', () {
    for (final box in const [Size(300, 40), Size(120, 30), Size(1000, 20), Size(50, 200)]) {
      final f = fitText(text: longText * 3, style: style, box: box, maxFontSize: 90, minFontSize: 12);
      expectFits(f, box);
    }
  });

  test('palavra enorme quebra e cabe', () {
    const box = Size(200, 300);
    final f = fitText(text: 'Supercalifragilisticexpialidocious' * 2, style: style, box: box, maxFontSize: 80);
    expectFits(f, box);
  });
}
