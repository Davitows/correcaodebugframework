import 'package:central_achados/models/ocorrencia.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Ocorrencia guarda autorId (uid) separado do nome do autor', () {
    const o = Ocorrencia(
      id: '1',
      titulo: 'Casaco',
      local: 'Quadra',
      descricao: '',
      autorId: 'uid-123',
      autorNome: 'Ana',
      resolvido: false,
      criadoEm: null,
    );
    expect(o.autorId, 'uid-123');
    expect(o.autorNome, 'Ana');
    expect(o.resolvido, isFalse);
  });
}
