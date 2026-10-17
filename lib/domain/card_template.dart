import 'occasion.dart';
import 'weather.dart';

/// Parses "#RGB", "#RRGGBB" or "#RRGGBBAA" (alpha last, as in CSS) into
/// a 0xAARRGGBB integer, the layout Flutter's `Color` expects.
int parseHexColor(String hex) {
  var h = hex.trim();
  if (h.startsWith('#')) h = h.substring(1);
  if (h.length == 3) h = h.split('').map((c) => '$c$c').join();
  if (h.length == 6) h = '${h}FF';
  if (h.length != 8) throw FormatException('Cor inválida: $hex');
  final rgba = int.parse(h, radix: 16);
  final alpha = rgba & 0xFF;
  return (alpha << 24) | (rgba >> 8);
}

double _num(Object? v, [double fallback = 0]) => v is num ? v.toDouble() : fallback;

/// A rectangle expressed as fractions of the card's width and height.
class FractionBox {
  const FractionBox(this.x, this.y, this.w, this.h);

  final double x;
  final double y;
  final double w;
  final double h;

  factory FractionBox.fromJson(Map<String, dynamic> json) => FractionBox(
        _num(json['x']),
        _num(json['y']),
        _num(json['w'], 1),
        _num(json['h'], 1),
      );
}

enum SlotType { greeting, phrase, date, weather, watermark, text }

enum SlotAlign { left, center, right }

class TemplateSlot {
  const TemplateSlot({
    required this.type,
    required this.font,
    required this.color,
    required this.box,
    this.text,
    this.format,
    this.align = SlotAlign.center,
    this.shadow = false,
    this.maxFontSize = 64,
    this.weight = 400,
    this.strokeColor,
    this.strokeWidth = 0,
  });

  final SlotType type;

  /// Literal text or pattern; `{nome}` is replaced by the recipient's name.
  final String? text;

  /// `intl` date pattern for `date`, or a `{cidade}`/`{temp}`/`{icone}`
  /// pattern for `weather`.
  final String? format;
  final String font;

  /// 0xAARRGGBB.
  final int color;
  final FractionBox box;
  final SlotAlign align;
  final bool shadow;

  /// Largest font size, in pixels of the template's own size.
  final double maxFontSize;

  /// CSS-like font weight (100–900).
  final int weight;

  /// Optional outline around the letters (`"stroke": {"color", "width"}`),
  /// for text over busy photos. [strokeWidth] is a fraction of the font size.
  final int? strokeColor;
  final double strokeWidth;

  factory TemplateSlot.fromJson(Map<String, dynamic> json) {
    final typeName = json['type'] as String;
    final stroke = json['stroke'] as Map<String, dynamic>?;
    return TemplateSlot(
      type: SlotType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => throw FormatException('Tipo de slot desconhecido: $typeName'),
      ),
      text: json['text'] as String?,
      format: json['format'] as String?,
      font: json['font'] as String? ?? 'Montserrat',
      color: parseHexColor(json['color'] as String? ?? '#FFFFFF'),
      box: FractionBox.fromJson(json['box'] as Map<String, dynamic>),
      align: SlotAlign.values.firstWhere(
        (a) => a.name == json['align'],
        orElse: () => SlotAlign.center,
      ),
      shadow: json['shadow'] as bool? ?? false,
      maxFontSize: _num(json['maxFontSize'], 64),
      weight: (json['weight'] as num?)?.toInt() ?? 400,
      strokeColor: stroke == null ? null : parseHexColor(stroke['color'] as String? ?? '#00000080'),
      strokeWidth: stroke == null ? 0 : _num(stroke['width'], 0.06),
    );
  }
}

enum BackgroundType { gradient, solid, image }

class TemplateBackground {
  const TemplateBackground({
    required this.type,
    required this.colors,
    this.angle = 180,
    this.image,
    this.focusX = 0.5,
    this.focusY = 0.5,
  });

  final BackgroundType type;

  /// 0xAARRGGBB colors; one color for `solid`, two or more for `gradient`.
  /// For `image` the first color is painted while the image is unavailable.
  final List<int> colors;

  /// CSS angle in degrees: 0 points up, 90 right, 180 down.
  final double angle;

  /// Optional asset path, drawn with `BoxFit.cover`.
  final String? image;

  /// Point of the photo (fractions) kept in view when `cover` has to crop,
  /// e.g. `"focus": {"x": 0.5, "y": 0.3}` keeps the upper middle.
  final double focusX;
  final double focusY;

  factory TemplateBackground.fromJson(Map<String, dynamic> json) {
    final focus = json['focus'] as Map<String, dynamic>? ?? const {};
    final colors = (json['colors'] as List<dynamic>? ?? const ['#FFF8E7'])
        .map((c) => parseHexColor(c as String))
        .toList();
    final image = json['image'] as String?;
    final typeName = json['type'] as String? ?? (image != null ? 'image' : 'gradient');
    return TemplateBackground(
      type: BackgroundType.values.firstWhere(
        (t) => t.name == typeName,
        orElse: () => BackgroundType.gradient,
      ),
      colors: colors.isEmpty ? [0xFFFFF8E7] : colors,
      angle: _num(json['angle'], 180),
      image: image,
      focusX: _num(focus['x'], 0.5).clamp(0.0, 1.0),
      focusY: _num(focus['y'], 0.5).clamp(0.0, 1.0),
    );
  }
}

/// A layer painted over the background.
/// Solid: `{"color": "#000000", "opacity": 0.15}`.
/// Gradient scrim: `{"type": "gradient", "colors": ["#00000000", "#000000B3"],
/// "stops": [0.45, 1], "angle": 180}`, alpha set per color, to darken only
/// where the text sits and keep the photo bright elsewhere.
class TemplateOverlay {
  const TemplateOverlay({
    this.color = 0xFF000000,
    this.opacity = 0,
    this.colors = const [],
    this.stops,
    this.angle = 180,
  });

  final int color;
  final double opacity;

  /// Two or more colors make this a gradient; [color]/[opacity] are then ignored.
  final List<int> colors;
  final List<double>? stops;
  final double angle;

  bool get isGradient => colors.length >= 2;

  factory TemplateOverlay.fromJson(Map<String, dynamic> json) {
    final colors = (json['colors'] as List<dynamic>? ?? const [])
        .map((c) => parseHexColor(c as String))
        .toList();
    final stops = (json['stops'] as List<dynamic>?)?.map((s) => (s as num).toDouble()).toList();
    return TemplateOverlay(
      color: parseHexColor(json['color'] as String? ?? '#000000'),
      opacity: _num(json['opacity']).clamp(0.0, 1.0),
      colors: colors,
      stops: stops != null && stops.length == colors.length ? stops : null,
      angle: _num(json['angle'], 180),
    );
  }
}

enum DecorationType { emoji, circle, sparkle }

/// Ornaments drawn between the background and the text.
/// `emoji`: [value] centered at ([x], [y]), [size] is a fraction of the width.
/// `circle`: soft blurred disc; [size] is the radius as a fraction of the width.
/// `sparkle`: four-pointed glint with a glow; [size] is its radius.
class TemplateDecoration {
  const TemplateDecoration({
    required this.type,
    required this.x,
    required this.y,
    required this.size,
    this.value,
    this.color = 0xFFFFFFFF,
    this.opacity = 1,
  });

  final DecorationType type;
  final String? value;
  final double x;
  final double y;
  final double size;
  final int color;
  final double opacity;

  factory TemplateDecoration.fromJson(Map<String, dynamic> json) => TemplateDecoration(
        type: DecorationType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => DecorationType.emoji,
        ),
        value: json['value'] as String?,
        x: _num(json['x'], 0.5),
        y: _num(json['y'], 0.5),
        size: _num(json['size'], 0.1),
        color: parseHexColor(json['color'] as String? ?? '#FFFFFF'),
        opacity: _num(json['opacity'], 1).clamp(0.0, 1.0),
      );
}

class CardTemplate {
  const CardTemplate({
    required this.id,
    required this.occasions,
    required this.background,
    required this.slots,
    this.weather = const [],
    this.width = 1080,
    this.height = 1350,
    this.overlays = const [],
    this.decorations = const [],
    this.premium = false,
  });

  final String id;
  final List<Occasion> occasions;

  /// Weather this template suits. Empty means any weather.
  final List<WeatherCondition> weather;
  final double width;
  final double height;
  final TemplateBackground background;
  /// Painted in order over the background. In JSON, `overlay` may be one
  /// object or a list.
  final List<TemplateOverlay> overlays;
  final List<TemplateDecoration> decorations;
  final List<TemplateSlot> slots;
  final bool premium;

  bool suitsWeather(WeatherCondition? condition) =>
      condition == null || weather.isEmpty || weather.contains(condition);

  factory CardTemplate.fromJson(Map<String, dynamic> json) {
    final size = json['size'] as Map<String, dynamic>? ?? const {};
    final rawOverlay = json['overlay'];
    return CardTemplate(
      id: json['id'] as String,
      // Unknown ids are skipped so an older app keeps working with a newer catalog.
      occasions: (json['occasions'] as List<dynamic>? ?? const [])
          .map((o) => Occasion.fromId(o as String))
          .whereType<Occasion>()
          .toList(),
      weather: (json['weather'] as List<dynamic>? ?? const [])
          .map((w) => WeatherCondition.fromId(w as String))
          .whereType<WeatherCondition>()
          .toList(),
      width: _num(size['width'], 1080),
      height: _num(size['height'], 1350),
      background: TemplateBackground.fromJson(
        json['background'] as Map<String, dynamic>? ?? const {},
      ),
      overlays: [
        for (final o in rawOverlay is List ? rawOverlay : [?rawOverlay])
          TemplateOverlay.fromJson(o as Map<String, dynamic>),
      ],
      decorations: (json['decorations'] as List<dynamic>? ?? const [])
          .map((d) => TemplateDecoration.fromJson(d as Map<String, dynamic>))
          .toList(),
      slots: (json['slots'] as List<dynamic>? ?? const [])
          .map((s) => TemplateSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
      premium: json['premium'] as bool? ?? false,
    );
  }
}
