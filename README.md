# Bom Dia (MVP)

App Android em Flutter que monta, no próprio aparelho, cartões de "bom dia" com o nome de quem vai receber, a data por extenso, o clima da cidade e uma frase do dia, prontos para enviar no WhatsApp.

- Funciona offline: catálogo, frases e fontes vêm em `assets/`.
- Nenhum dado pessoal sai do aparelho: os nomes ficam no `shared_preferences`, e o app não pede acesso aos contatos.
- Anúncios, assinatura e analytics são stubs (só escrevem no log).

## Como rodar

Requisitos: Flutter estável (testado com 3.47.7 / Dart 3.13), Android SDK e um aparelho ou emulador.

```bash
flutter pub get
flutter run
```

Testes e análise:

```bash
flutter analyze
flutter test
```

O golden test (`test/goldens/card_golden_01.png`) foi gerado no Windows. Se ele falhar em outro sistema só por diferença de fonte ou antialiasing, regenere a imagem com `flutter test --update-goldens` e confira o resultado.

Flags de build (veja `lib/services/app_config.dart`):

```bash
flutter run --dart-define=ADS_ENABLED=false
```

## Estrutura

```
lib/
  main.dart                 inicialização (datas pt_BR, prefs, notificações)
  app/                      tema, providers (Riverpod), MaterialApp
  domain/                   modelos: CardTemplate, Occasion, Recipient, Weather, textos
  services/                 BrazilianCalendar, TemplateSelector, clima, localização,
                            compartilhamento, notificação, anúncios, assinatura, analytics
  data/                     repositórios de templates, destinatários e ajustes
  render/                   CardRenderer (Canvas → PNG 1080×1350) e text_fit
  ui/                       telas: Hoje, destinatário, Galeria, detalhe, cidade, Ajustes, paywall
android/app/src/main/kotlin/.../MainActivity.kt
                            MethodChannel "bom_dia/native": envio direto ao WhatsApp
                            (com.whatsapp / com.whatsapp.w4b) e nome da cidade pelo Geocoder
```

A pré-visualização (`CardPainter`) e o PNG enviado usam o mesmo `CardRenderer.paint`, então o que aparece na tela é exatamente o que vai para o WhatsApp.

## Como adicionar um template

Edite `assets/templates/catalog.json` e acrescente um objeto à lista `templates`:

```json
{
  "id": "cafe-03",
  "occasions": ["generico", "segunda"],
  "weather": ["sol", "nublado"],
  "premium": false,
  "size": { "width": 1080, "height": 1350 },
  "background": { "type": "gradient", "colors": ["#C8A27A", "#4A2C17"], "angle": 180, "image": null },
  "overlay": { "color": "#000000", "opacity": 0.15 },
  "decorations": [
    { "type": "emoji", "value": "☕", "x": 0.5, "y": 0.3, "size": 0.2 },
    { "type": "circle", "x": 0.2, "y": 0.2, "size": 0.15, "color": "#FFFFFF", "opacity": 0.2 }
  ],
  "slots": [
    { "type": "greeting", "text": "Bom dia, {nome}!", "font": "GreatVibes", "color": "#FFFFFF",
      "box": { "x": 0.08, "y": 0.5, "w": 0.84, "h": 0.17 }, "align": "center", "shadow": true, "maxFontSize": 120 },
    { "type": "phrase", "font": "PlayfairDisplay", "color": "#FFFFFF",
      "box": { "x": 0.1, "y": 0.68, "w": 0.8, "h": 0.2 }, "align": "center", "shadow": true, "maxFontSize": 60 },
    { "type": "date", "format": "EEEE, d 'de' MMMM", "font": "Montserrat", "weight": 600, "color": "#FFFFFF",
      "box": { "x": 0.1, "y": 0.05, "w": 0.8, "h": 0.05 }, "align": "center", "maxFontSize": 40 },
    { "type": "weather", "format": "{cidade} • {temp}°C {icone}", "font": "Montserrat", "weight": 600, "color": "#FFFFFF",
      "box": { "x": 0.1, "y": 0.105, "w": 0.8, "h": 0.045 }, "align": "center", "maxFontSize": 36 },
    { "type": "watermark", "text": "Feito com o app Bom Dia", "font": "Montserrat", "color": "#FFFFFFB3",
      "box": { "x": 0.5, "y": 0.955, "w": 0.46, "h": 0.03 }, "align": "right", "maxFontSize": 24 }
  ]
}
```

Regras:

- `box`, `x`, `y` e `size` são frações da largura e da altura do cartão.
- O texto de cada slot encolhe a partir de `maxFontSize` até caber na caixa, com quebra de linha.
- `{nome}` vazio vira só "Bom dia!" (sem vírgula). Sem clima, o slot `weather` não aparece. Para assinantes, a marca d'água não aparece.
- Cores: `#RRGGBB` ou `#RRGGBBAA` (alfa no fim).
- Fontes disponíveis: `GreatVibes`, `PlayfairDisplay`, `Montserrat`, `Pacifico`. `weight` (100–900) vale para Montserrat e Playfair.
- `background.image` aceita o caminho de um asset (declare-o no `pubspec.yaml`); ele é desenhado com `BoxFit.cover` sobre as cores. A primeira cor de `colors` aparece enquanto a foto carrega. `"focus": {"x": 0.5, "y": 0.3}` escolhe que parte da foto fica visível quando ela precisa ser recortada. As fotos ficam em `assets/photos/` (1080×1350, JPEG), com os créditos em `docs/CREDITOS-FOTOS.md`.
- `overlay` pode ser um objeto ou uma lista. Sólido: `{"color": "#000000", "opacity": 0.15}`. Véu em degradê, que escurece só onde fica o texto: `{"type": "gradient", "colors": ["#00000000", "#000000BF"], "stops": [0.6, 1], "angle": 180}`.
- `"stroke": {"color": "#00000059", "width": 0.04}` num slot desenha um contorno nas letras (largura em fração do tamanho da fonte), útil sobre fotos com muitos detalhes.
- Decoração `sparkle` (`{"type": "sparkle", "x": 0.8, "y": 0.1, "size": 0.04, "color": "#FFF6D5"}`) desenha um brilho de quatro pontas.
- Ocasiões: `generico`, `segunda`, `sexta`, `sabado`, `domingo`, `chuva`, `frio`, `calor`, `aniversario`, `feriado`, `carnaval`, `natal`, `ano_novo`, `dia_das_maes`, `dia_dos_pais`, `dia_dos_namorados`, `dia_das_criancas`, `dia_dos_avos`, `boa_noite`.
- Um template com saudação específica ("Bom sábado") deve listar só a ocasião dele. Os que dizem "Bom dia" podem incluir `generico`.

As frases ficam em `assets/templates/phrases.json`, agrupadas pelas mesmas ocasiões. O teste `test/domain_test.dart` confere se toda ocasião tem template gratuito e pelo menos 10 frases.

## Como o cartão do dia é escolhido

`TemplateSelector` (Dart puro) define a ocasião nesta ordem: aniversário do destinatário → feriado ou data comemorativa (`BrazilianCalendar`) → clima (chuva, frio ≤ 15 °C, calor ≥ 32 °C) → dia da semana (segunda, sexta, sábado, domingo) → genérico. A escolha usa como semente a data e o id do destinatário, então o cartão não muda ao reabrir o app. "Trocar" avança para a próxima combinação de template e frase da mesma ocasião. Finados não recebe cartão festivo.

## O que falta para publicar (TODOs)

- **AdMob**: implementar `AdsService` com `google_mobile_ads` (`lib/services/ads_service.dart`). Mostrar o intersticial quando o app voltar ao primeiro plano depois do envio, no máximo 1 a cada 3 envios.
- **RevenueCat**: implementar `SubscriptionService` com `purchases_flutter` e trocar o paywall fake (`lib/services/subscription_service.dart`, `lib/ui/screens/paywall_screen.dart`).
- **Firebase Analytics**: implementar `AnalyticsService` com `firebase_analytics` (`lib/services/analytics_service.dart`).
- **Catálogo remoto**: implementar `RemoteTemplateSource` com Supabase, com cache em disco e o catálogo local como reserva (`lib/data/template_repository.dart`, ligado por `--dart-define=REMOTE_CATALOG=true`).
- **Widget de tela inicial**: ainda não existe.
- Publicação: application id definitivo, assinatura de release, ícone e nome na loja, política de privacidade.

Fora do MVP: login, backend, envio de fotos, imagens geradas por IA e iOS.

## Licenças das fontes

Great Vibes, Playfair Display, Montserrat e Pacifico estão sob a SIL Open Font License 1.1. As licenças estão em `assets/fonts/OFL-*.txt`.
