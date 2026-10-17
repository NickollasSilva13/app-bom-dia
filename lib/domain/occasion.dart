/// Reasons a card can be made for. The [id] is what appears in the JSON files.
enum Occasion {
  generico('generico', 'Bom dia'),
  segunda('segunda', 'Segunda-feira'),
  sexta('sexta', 'Sexta-feira'),
  sabado('sabado', 'Sábado'),
  domingo('domingo', 'Domingo'),
  chuva('chuva', 'Dia de chuva'),
  frio('frio', 'Dia frio'),
  calor('calor', 'Dia quente'),
  aniversario('aniversario', 'Aniversário'),
  feriado('feriado', 'Feriado'),
  carnaval('carnaval', 'Carnaval'),
  natal('natal', 'Natal'),
  anoNovo('ano_novo', 'Ano Novo'),
  diaDasMaes('dia_das_maes', 'Dia das Mães'),
  diaDosPais('dia_dos_pais', 'Dia dos Pais'),
  diaDosNamorados('dia_dos_namorados', 'Dia dos Namorados'),
  diaDasCriancas('dia_das_criancas', 'Dia das Crianças'),
  diaDosAvos('dia_dos_avos', 'Dia dos Avós'),
  boaNoite('boa_noite', 'Boa noite');

  const Occasion(this.id, this.label);

  final String id;

  /// Human label in pt-BR, shown in the UI.
  final String label;

  static Occasion? fromId(String id) {
    for (final o in Occasion.values) {
      if (o.id == id) return o;
    }
    return null;
  }
}
