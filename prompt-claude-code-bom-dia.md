# Prompt para o Claude Code — App "Bom Dia" (MVP)

> Cole tudo abaixo no Claude Code, dentro de uma pasta vazia.

---

Você vai criar o MVP de um aplicativo Android em **Flutter** que gera imagens de "bom dia" personalizadas para compartilhar no WhatsApp. O público principal são brasileiros acima de 45 anos, então simplicidade e legibilidade importam mais do que qualquer outra coisa.

## Objetivo do produto

Em até 3 toques, o usuário abre o app, vê o card de hoje já pronto, escolhe para quem é ("Dona Cida", "Grupo da família") e envia no WhatsApp. A imagem traz o nome do destinatário, a data por extenso em português, o clima da cidade e uma frase adequada ao dia.

## Decisões de arquitetura (obrigatórias)

1. **A imagem é montada no aparelho**, a partir de modelos (templates) descritos em JSON. Nada de geração de imagem no servidor nem chamada de IA em tempo de execução.
2. **Funciona offline.** O catálogo inicial vem empacotado em `assets/`. A busca remota do catálogo fica atrás de uma interface, para ligar depois (Supabase).
3. **Nenhum dado pessoal sai do aparelho.** Os nomes dos destinatários ficam salvos localmente. Não peça permissão de contatos.
4. **Serviços pagos ficam atrás de interfaces com implementação fake** (anúncios e assinatura), controlados por flags. Não coloque chaves reais.
5. Código em inglês, textos da interface em **português do Brasil**.

## Stack

- Flutter estável mais recente, Dart com null safety, apenas Android por enquanto (mas sem nada que impeça iOS depois).
- Estado: `flutter_riverpod`.
- Persistência local: `shared_preferences` (os dados são pequenos).
- Clima: API **Open-Meteo** (`https://api.open-meteo.com/v1/forecast`, sem chave), via `http`. Localização aproximada com `geolocator`. Se a permissão for negada, o usuário digita a cidade e você usa a geocodificação do Open-Meteo (`https://geocoding-api.open-meteo.com/v1/search`). Faça cache do clima por 3 horas.
- Datas: `intl` com locale `pt_BR`.
- Compartilhamento: `share_plus`. Adicione também um `MethodChannel` Android que tenta abrir o WhatsApp diretamente (pacotes `com.whatsapp` e `com.whatsapp.w4b`) e, se não encontrar, cai no `share_plus`.
- Notificação diária: `flutter_local_notifications` + `timezone`, às 6h no fuso `America/Sao_Paulo`, com o texto "Seu bom dia de hoje está pronto ☀️".
- Fontes: **empacotadas em `assets/fonts`** (não baixar em tempo de execução). Use 4 fontes de licença OFL do Google Fonts: uma cursiva elegante (ex.: Great Vibes), uma serifada (ex.: Playfair Display), uma sem serifa forte (ex.: Montserrat) e uma manuscrita amigável (ex.: Pacifico).

## Formato do template (JSON)

Crie `assets/templates/catalog.json` com uma lista de templates neste formato:

```json
{
  "id": "flores-domingo-01",
  "occasions": ["domingo", "generico"],
  "weather": ["sol", "nublado"],
  "size": { "width": 1080, "height": 1350 },
  "background": {
    "type": "gradient",
    "colors": ["#FDE68A", "#F59E0B"],
    "angle": 135,
    "image": null
  },
  "overlay": { "color": "#000000", "opacity": 0.15 },
  "decorations": [
    { "type": "emoji", "value": "🌻", "x": 0.85, "y": 0.1, "size": 0.12 }
  ],
  "slots": [
    { "type": "greeting", "text": "Bom dia, {nome}!", "font": "GreatVibes", "color": "#FFFFFF",
      "box": { "x": 0.08, "y": 0.12, "w": 0.84, "h": 0.18 }, "align": "center", "shadow": true, "maxFontSize": 120 },
    { "type": "phrase", "font": "PlayfairDisplay", "color": "#FFFFFF",
      "box": { "x": 0.1, "y": 0.42, "w": 0.8, "h": 0.25 }, "align": "center", "shadow": true, "maxFontSize": 64 },
    { "type": "date", "format": "EEEE, d 'de' MMMM", "font": "Montserrat", "color": "#FFFFFF",
      "box": { "x": 0.1, "y": 0.78, "w": 0.8, "h": 0.06 }, "align": "center", "maxFontSize": 44 },
    { "type": "weather", "format": "{cidade} • {temp}°C {icone}", "font": "Montserrat", "color": "#FFFFFF",
      "box": { "x": 0.1, "y": 0.85, "w": 0.8, "h": 0.05 }, "align": "center", "maxFontSize": 40 },
    { "type": "watermark", "text": "Feito com o app Bom Dia", "font": "Montserrat", "color": "#FFFFFFAA",
      "box": { "x": 0.55, "y": 0.95, "w": 0.42, "h": 0.03 }, "align": "right", "maxFontSize": 24 }
  ]
}
```

Regras:
- Coordenadas são **frações** da largura e altura, para que o mesmo template sirva para outros tamanhos no futuro.
- O texto de cada slot precisa **caber automaticamente** na caixa: reduza a fonte a partir de `maxFontSize` até caber, com quebra de linha.
- Se `{nome}` estiver vazio, use "Bom dia!" sem vírgula.
- Se o clima não estiver disponível, o slot `weather` simplesmente não aparece.
- `background.image` é o caminho opcional de um asset. No MVP, todos os templates usam gradientes, para o app rodar sem imagens. Deixe o renderizador pronto para imagens com `BoxFit.cover`.

Frases ficam em `assets/templates/phrases.json`, agrupadas por ocasião (`segunda`, `sexta`, `domingo`, `chuva`, `frio`, `calor`, `aniversario`, `feriado`, `natal`, `dia_das_maes` etc.). Escreva **pelo menos 10 frases por ocasião**, curtas, calorosas e no tom que esse público usa ("Que Deus abençoe seu dia" pode aparecer, mas não domine: mantenha a maioria neutra).

Crie **pelo menos 40 templates** variados no catálogo (paletas douradas, flores, café, céu, pôr do sol, tons pastel), cobrindo todas as ocasiões.

## Lógica de seleção do card do dia

Implemente um `TemplateSelector` puro (sem Flutter, fácil de testar) que recebe data, clima e destinatário e decide a ocasião nesta ordem de prioridade:

1. Aniversário do destinatário (se a data de nascimento estiver cadastrada).
2. Feriado nacional ou data comemorativa.
3. Clima marcante: chuva, frio (≤ 15 °C) ou calor (≥ 32 °C).
4. Dia da semana (segunda, sexta, sábado, domingo).
5. Genérico.

A escolha deve ser **determinística por dia** (semente = data + id do destinatário), para o card não mudar cada vez que o app abre. O botão "Trocar" avança para a próxima opção válida.

Crie um `BrazilianCalendar` que calcula:
- Feriados nacionais fixos (1/1, 21/4, 1/5, 7/9, 12/10, 2/11, 15/11, 20/11, 25/12).
- Feriados móveis a partir da Páscoa (Carnaval, Sexta-feira Santa, Corpus Christi).
- Datas comemorativas: Dia das Mães (2º domingo de maio), Dia dos Pais (2º domingo de agosto), Dia dos Namorados (12/6), Dia das Crianças (12/10), Dia dos Avós (26/7), Natal e Ano Novo.

## Renderização

- Um `CardRenderer` que desenha o template em um `dart:ui` `Canvas` via `PictureRecorder` e exporta PNG em 1080×1350. A mesma lógica de desenho deve servir para a pré-visualização na tela (por exemplo, com `CustomPainter`), para o que a pessoa vê ser exatamente o que é enviado.
- Sombra suave no texto quando `shadow: true`, para garantir leitura sobre qualquer fundo.
- O PNG é salvo em diretório temporário antes de compartilhar.

## Telas

1. **Hoje (tela inicial).** Card de hoje grande, em destaque. Abaixo, chips com os destinatários salvos (mais "+ Adicionar"). Tocar em um chip atualiza o nome no card. Dois botões grandes: **"Enviar no WhatsApp"** (verde, principal) e "Trocar".
2. **Adicionar/editar destinatário.** Nome como vai aparecer e data de nascimento opcional. Nada mais.
3. **Galeria por ocasião.** Abas como Bom dia, Boa noite, Aniversário e Datas especiais, com uma grade de cards já com o nome escolhido.
4. **Ajustes.** Cidade, horário da notificação, ligar/desligar notificação e "Remover marca d'água" (abre o paywall fake).

Requisitos de interface:
- Fonte mínima de 18 sp em todo o app, botões com pelo menos 56 dp de altura, alto contraste.
- Sem cadastro, sem login, sem onboarding longo: no máximo uma tela pedindo a cidade ou a localização na primeira abertura.
- Tema claro, quente (tons de dourado e creme).

## Monetização (stubs)

- `AdsService` com implementação fake que registra no log "mostraria intersticial". Chame-o **depois** do compartilhamento, no máximo 1 vez a cada 3 envios. Nunca antes de enviar.
- `SubscriptionService` com implementação fake e flag `isPremium` salva localmente. O premium remove a marca d'água e libera os templates marcados com `"premium": true`.
- Deixe comentários `TODO` indicando onde entram AdMob e RevenueCat.

## Analytics (stub)

`AnalyticsService` com eventos: `app_open`, `card_generated`, `card_shared` (com `occasion` e `template_id`), `card_swapped`, `recipient_added` e `paywall_viewed`. A implementação inicial só registra no log. Deixe pronto para trocar por Firebase Analytics.

## Estrutura de pastas sugerida

```
lib/
  main.dart
  app/            (tema, rotas)
  domain/         (modelos: Template, Slot, Recipient, Occasion, Weather)
  services/       (calendar, template_selector, weather, share, notifications, ads, subscription, analytics)
  data/           (template_repository: local agora, remoto depois; recipient_repository)
  render/         (card_renderer, text_fit)
  ui/             (screens e widgets)
assets/
  templates/catalog.json
  templates/phrases.json
  fonts/
test/
```

## Testes

- Testes unitários do `BrazilianCalendar` (Páscoa, Carnaval e Corpus Christi de 2025 a 2030, e os Dias das Mães e dos Pais).
- Testes unitários do `TemplateSelector`: prioridade das ocasiões e determinismo por dia.
- Teste do ajuste de texto (`text_fit`): um texto longo sempre cabe na caixa.
- Um golden test do renderizador com um template fixo.

## Ordem de trabalho

1. Criar o projeto, as dependências e a estrutura de pastas.
2. Modelos de domínio e parsing do JSON, com testes.
3. `BrazilianCalendar` e `TemplateSelector`, com testes.
4. `CardRenderer` e ajuste de texto, com golden test.
5. Tela "Hoje" com destinatários e compartilhamento.
6. Clima com cache e fallback.
7. Notificação diária.
8. Galeria, ajustes e stubs de anúncio, assinatura e analytics.
9. Catálogo completo (40+ templates e frases).

Ao final, rode `flutter analyze` e `flutter test`, corrija tudo o que falhar e escreva um `README.md` curto explicando como rodar, como adicionar templates novos editando o JSON e quais `TODO`s faltam para publicar (AdMob, RevenueCat, Firebase, catálogo remoto e widget de tela inicial).

Não implemente agora: login, backend, upload de fotos, geração de imagens com IA, iOS e widget de tela inicial. Isso fica para depois do MVP.
