# LAUDO — Central de Achados e Perdidos (Operação Resgate)

Projeto: `central_achados` (Flutter + Firebase Auth + Cloud Firestore)
Total: **12 bugs corrigidos** + 3 ajustes de ambiente (ao final).
Os números de linha se referem ao código **original** (antes da correção).

> **Nota de reprodução:** o campo "Como testei" traz o roteiro de teste de cada
> correção. Confirme cada item no app (2 janelas anônimas / 2 contas Google) e
> anexe o print das duas contas vendo a mesma ocorrência antes de entregar.

## Primeiro diagnóstico (caminho `main` → `GatePage` → `CentralPage` → `DetalhePage`)

- `main` e `GatePage` estão corretos (inicializam o Firebase e escutam `authStateChanges`).
- `CentralPage` → `DetalhePage`: a navegação **não compilava** (Bug 10), então o analisador acusava erro antes de qualquer teste.
- Os demais bugs estão na camada de dados (`Ocorrencia.fromDoc` e `CentralService`) e em condições lógicas invertidas nas telas.
- **Ordem importa:** os Bugs 05 e 09 ficam "escondidos" atrás do Bug 02. Enquanto `resolvido` estava invertido no modelo, o filtro e o toggle erravam duas vezes e acabavam parecendo certos. Ao corrigir o 02, eles aparecem.

---

## Bugs

Bug 01 | Arquivo: `lib/models/ocorrencia.dart`
Sintoma observado: o botão "Marcar como resolvido" nunca aparecia para o dono do registro; a checagem de dono falhava sempre.
Hipótese: `autorId` estava sendo lido do campo errado do documento.
Linha/trecho alterado: L21 — `autorId: d['autorNome']` → `autorId: d['autorId']`
Como testei a correção: registrar uma ocorrência e abrir o detalhe com a mesma conta → o botão de status aparece. Em outra conta, não aparece.

Bug 02 | Arquivo: `lib/models/ocorrencia.dart`
Sintoma observado: casos resolvidos aparecem como "Em aberto" e os abertos como "Resolvido".
Hipótese: o booleano foi negado ao converter o documento em objeto.
Linha/trecho alterado: L22 — `resolvido: !(d['resolvido'] as bool? ?? false)` → `resolvido: d['resolvido'] as bool? ?? false`
Como testei a correção: criar ocorrência (nasce `resolvido: false`) → lista mostra "Em aberto". Marcar como resolvido → lista mostra "Resolvido". Conferir o valor do campo no console do Firestore.

Bug 03 | Arquivo: `lib/services/central_service.dart`
Sintoma observado: o responsável pelo registro era identificado pelo e-mail; o dono nunca batia com `currentUser.uid`.
Hipótese: ao gravar, `autorId` recebia o e-mail em vez do UID.
Linha/trecho alterado: L17 — `'autorId': u.email ?? ''` → `'autorId': u.uid`
Como testei a correção: registrar ocorrência e verificar no console do Firestore que `autorId` é o UID da conta (não o e-mail). Documentos criados antes da correção continuam com e-mail: recriar os registros de teste.

Bug 04 | Arquivo: `lib/services/central_service.dart`
Sintoma observado: registros novos apareciam no fim da lista, os mais antigos no topo.
Hipótese: `orderBy` em ordem crescente.
Linha/trecho alterado: L9 — `orderBy('criadoEm', descending: false)` → `descending: true` (apenas em `acompanhar`; as pistas continuam em ordem cronológica).
Como testei a correção: registrar dois objetos em sequência → o mais recente aparece primeiro.

Bug 05 | Arquivo: `lib/services/central_service.dart`
Sintoma observado: (aparece só depois do Bug 02) ao clicar em "Marcar como resolvido", o status não mudava.
Hipótese: o método gravava o valor atual (`item.resolvido`) em vez do valor invertido. Antes, o modelo invertido mascarava o erro.
Linha/trecho alterado: L25 — `update({'resolvido': item.resolvido})` → `update({'resolvido': !item.resolvido})`
Como testei a correção: como dono, marcar como resolvido → status muda para "Resolvido" na lista; abrir de novo e clicar em "Reabrir" → volta para "Em aberto".

Bug 06 | Arquivo: `lib/services/central_service.dart`
Sintoma observado: a pista era enviada sem erro, mas nunca aparecia no caso.
Hipótese: o envio gravava em `ocorrencias/pistas/pistas` (documento literal "pistas") em vez de usar o id da ocorrência; a leitura, que usa o id correto, nunca encontrava nada.
Linha/trecho alterado: L30 — `.doc('pistas').collection('pistas')` → `.doc(ocorrenciaId).collection('pistas')`
Como testei a correção: enviar pista na ocorrência A → aparece só na A; a ocorrência B continua "Nenhuma pista ainda." A segunda conta vê a pista ao vivo.

Bug 07 | Arquivo: `lib/pages/central_page.dart`
Sintoma observado: era possível registrar objeto só com título ou só com local; a mensagem "Informe título e local." só aparecia com os dois vazios.
Hipótese: operador lógico errado (`&&` no lugar de `||`).
Linha/trecho alterado: L26 — `titulo...isEmpty && local...isEmpty` → `titulo...isEmpty || local...isEmpty`
Como testei a correção: tentar registrar com título vazio, depois com local vazio → em ambos aparece a mensagem e nada é gravado. Com os dois preenchidos → registra.

Bug 08 | Arquivo: `lib/pages/central_page.dart`
Sintoma observado: o switch "Somente não resolvidos" não ligava ao clicar (ficava sempre desligado), então o filtro nunca era aplicado.
Hipótese: o estado recebia a negação do valor do switch (clicar para ligar gravava `false`).
Linha/trecho alterado: L68 — `somenteAbertos = !value` → `somenteAbertos = value`
Como testei a correção: clicar no switch → ele liga e o filtro passa a valer; clicar de novo → desliga.

Bug 09 | Arquivo: `lib/pages/central_page.dart`
Sintoma observado: (aparece só depois do Bug 02) com o filtro ligado, a lista mostrava só os casos **resolvidos**.
Hipótese: o filtro usava `o.resolvido` onde deveria usar a negação.
Linha/trecho alterado: L75 — `todos.where((o) => o.resolvido)` → `todos.where((o) => !o.resolvido)`
Como testei a correção: ter 1 caso resolvido e 1 em aberto; ligar o filtro → só o em aberto permanece; desligar → os dois aparecem.

Bug 10 | Arquivo: `lib/pages/central_page.dart`
Sintoma observado: erro de compilação ("required named parameter 'ocorrencia' must be provided"); o projeto não rodava e o detalhe não abria.
Hipótese: `DetalhePage()` foi chamado sem o argumento obrigatório.
Linha/trecho alterado: L86 — `DetalhePage()` → `DetalhePage(ocorrencia: o)`
Como testei a correção: `flutter analyze` sem erro nessa linha; tocar em um item → abre o detalhe com título, local, autor e descrição **daquele** item.

Bug 11 | Arquivo: `lib/pages/detalhe_page.dart`
Sintoma observado: clicar em enviar com o campo preenchido não fazia nada; com o campo vazio, enviava.
Hipótese: condição de guarda invertida (`isNotEmpty` no lugar de `isEmpty`).
Linha/trecho alterado: L21 — `if (pista.text.trim().isNotEmpty) return;` → `if (pista.text.trim().isEmpty) return;`
Como testei a correção: enviar com campo vazio ou só espaços → nada é gravado; com texto → grava.

Bug 12 | Arquivo: `lib/pages/detalhe_page.dart`
Sintoma observado: (aparece só depois do Bug 11) a pista chegava ao Firestore com a mensagem em branco.
Hipótese: o método passava uma string vazia em vez do texto digitado.
Linha/trecho alterado: L23 — `enviarPista(widget.ocorrencia.id, '')` → `enviarPista(widget.ocorrencia.id, pista.text)`
Como testei a correção: digitar "Deixei na secretaria" e enviar → a mensagem aparece na lista e o campo é limpo; conferir o campo `mensagem` no Firestore.

---

## Ajustes de ambiente (fora dos 12 bugs)

- `test/widget_test.dart`: era o teste-modelo do Flutter (contador, `MyApp`, pacote `bugsresolver`) e não compilava neste projeto. Substituído por um teste de unidade do modelo `Ocorrencia`, usando o pacote `central_achados`.
- `pubspec.yaml`: faltava a seção `dev_dependencies` (`flutter_test` e `flutter_lints`), exigidos pelo teste e pelo `analysis_options.yaml`.
- `lib/pages/central_page.dart`: o stream de `acompanhar()` era recriado a cada `build`; agora é criado uma vez no `State` (evita reassinar o Firestore a cada clique no switch). Não altera o comportamento visível.

## Pendências que dependem do ambiente (não são bugs de código)

- `lib/firebase_options.dart` **não vem no ZIP** (README). Gerar com `flutterfire configure` ou copiar o arquivo do projeto Firebase da escola; sem ele, `main.dart` acusa erro no analisador.
- Habilitar Authentication > Google e cadastrar o domínio autorizado.
- A checagem "só o dono altera o status" no app (`alterarStatus` e botão oculto) é uma proteção de interface. A proteção real precisa estar nas **regras do Firestore** (`request.auth.uid == resource.data.autorId` para `update`). Não foram desativadas nem alteradas regras de segurança.
- Rodar: `flutter pub get` → `flutter analyze` → `flutter test` → `flutter run -d chrome`.
