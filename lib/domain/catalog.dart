import 'card_template.dart';
import 'occasion.dart';

/// Short phrases grouped by occasion, from `phrases.json`.
class PhraseBook {
  const PhraseBook(this._byOccasion);

  final Map<Occasion, List<String>> _byOccasion;

  /// Phrases for [occasion], falling back to the generic ones.
  List<String> phrasesFor(Occasion occasion) {
    final list = _byOccasion[occasion];
    if (list != null && list.isNotEmpty) return list;
    return _byOccasion[Occasion.generico] ?? const [];
  }

  Iterable<Occasion> get occasions => _byOccasion.keys;

  factory PhraseBook.fromJson(Map<String, dynamic> json) {
    final map = <Occasion, List<String>>{};
    json.forEach((key, value) {
      final occasion = Occasion.fromId(key);
      if (occasion == null || value is! List) return;
      map[occasion] = value.cast<String>();
    });
    return PhraseBook(map);
  }
}

class TemplateCatalog {
  const TemplateCatalog({required this.templates, required this.phrases});

  final List<CardTemplate> templates;
  final PhraseBook phrases;

  /// `catalog.json` may be a bare list or `{"templates": [...]}`.
  static List<CardTemplate> parseTemplates(Object? json) {
    final list = json is Map<String, dynamic> ? json['templates'] : json;
    return (list as List<dynamic>)
        .map((t) => CardTemplate.fromJson(t as Map<String, dynamic>))
        .toList();
  }
}
