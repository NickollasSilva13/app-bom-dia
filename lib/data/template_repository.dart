import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../domain/catalog.dart';

/// Where templates and phrases come from.
abstract class TemplateSource {
  Future<TemplateCatalog> load();
}

/// The catalog bundled in `assets/templates/`. Always available, offline.
class AssetTemplateSource implements TemplateSource {
  AssetTemplateSource({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  @override
  Future<TemplateCatalog> load() async {
    final templatesJson = await _bundle.loadString('assets/templates/catalog.json');
    final phrasesJson = await _bundle.loadString('assets/templates/phrases.json');
    return TemplateCatalog(
      templates: TemplateCatalog.parseTemplates(jsonDecode(templatesJson)),
      phrases: PhraseBook.fromJson(jsonDecode(phrasesJson) as Map<String, dynamic>),
    );
  }
}

// TODO(remote-catalog): Implement with Supabase (supabase_flutter): read the
// `templates` and `phrases` tables (or a JSON in Storage), cache the result
// on disk and keep the bundled catalog as the fallback.
class RemoteTemplateSource implements TemplateSource {
  @override
  Future<TemplateCatalog> load() =>
      Future.error(UnimplementedError('Catálogo remoto ainda não implementado'));
}

/// Tries the remote catalog when enabled, falling back to the bundled one.
class TemplateRepository {
  TemplateRepository({required this.local, this.remote});

  final TemplateSource local;
  final TemplateSource? remote;

  Future<TemplateCatalog> load() async {
    final r = remote;
    if (r != null) {
      try {
        final catalog = await r.load();
        if (catalog.templates.isNotEmpty) return catalog;
      } catch (e) {
        debugPrint('[Catalog] remoto indisponível, usando o local: $e');
      }
    }
    return local.load();
  }
}
