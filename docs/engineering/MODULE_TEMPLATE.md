# EANTrack — Module Template

> Use este template ao iniciar qualquer novo módulo.
> Preencha antes de escrever a primeira linha de código.

---

## Template de Documentação de Módulo

```markdown
# Módulo: {Nome}

## Visão Geral
{Descrição em 1-2 frases do que este módulo faz}

## Telas
| Tela | Equivalente FlutterFlow | Descrição |
|------|------------------------|-----------|
| {nome}_screen.dart | pag2_... | ... |

## Estado
| Estado | Quando ocorre |
|--------|--------------|
| Loading | ... |
| Loaded | ... |
| Error | ... |
| Empty | ... |

## Entidades de Domínio
- `{ModelName}` — {descrição}

## Tabelas Supabase Envolvidas
- `{table_name}` — leitura/escrita

## RPCs Utilizadas
- `{rpc_name}(params)` — {descrição}

## Fluxo Principal
1. Usuário acessa tela X
2. Notifier chama repository.load()
3. ...

## Preservado do FlutterFlow
- {lista do que foi mantido idêntico}

## Melhorado em relação ao FlutterFlow
- {lista de melhorias: responsividade, arquitetura, etc.}

## Casos de Borda
- {lista de edge cases conhecidos}

## Checklist de Implementação
- [ ] State sealed class
- [ ] Domain models
- [ ] Repository
- [ ] Notifier + Providers
- [ ] Telas
- [ ] Shared widgets necessários
- [ ] Unit tests
- [ ] Widget tests
- [ ] Comparação visual FlutterFlow
- [ ] Marcado como estável no REBUILD_ROADMAP.md
```

---

## Template de Estrutura de Arquivos

```
features/{nome}/
├── data/
│   └── {nome}_repository.dart
├── domain/
│   ├── {nome}_state.dart
│   └── {nome}_model.dart          # se necessário
└── presentation/
    ├── providers/
    │   └── {nome}_provider.dart
    └── screens/
        └── {nome}_screen.dart
```

---

## Template de State

```dart
sealed class {Nome}State {
  const {Nome}State();
}

class {Nome}Initial extends {Nome}State {
  const {Nome}Initial();
}

class {Nome}Loading extends {Nome}State {
  const {Nome}Loading();
}

class {Nome}Loaded extends {Nome}State {
  const {Nome}Loaded(this.data);
  final List<{Modelo}> data;
}

class {Nome}Error extends {Nome}State {
  const {Nome}Error(this.message);
  final String message;
}
```

---

## Template de Repository

```dart
class {Nome}Repository {
  const {Nome}Repository(this._client);
  final SupabaseClient _client;

  Future<List<{Modelo}>> list() async {
    try {
      final data = await _client.from('{tabela}').select();
      return (data as List).map({Modelo}.fromJson).toList();
    } on PostgrestException catch (e) {
      throw ServerException(e.message);
    } catch (_) {
      throw const ServerException();
    }
  }
}
```

---

## Template de Notifier

```dart
final {nome}NotifierProvider = StateNotifierProvider
    .autoDispose<{Nome}Notifier, {Nome}State>((ref) {
  return {Nome}Notifier(ref.read({nome}RepositoryProvider));
});

class {Nome}Notifier extends StateNotifier<{Nome}State> {
  {Nome}Notifier(this._repo) : super(const {Nome}Initial());

  final {Nome}Repository _repo;

  Future<void> load() async {
    state = const {Nome}Loading();
    try {
      final data = await _repo.list();
      state = {Nome}Loaded(data);
    } on AppException catch (e) {
      state = {Nome}Error(e.message);
    }
  }
}
```

---

## Template de Screen (estrutura mínima)

```dart
class {Nome}Screen extends ConsumerWidget {
  const {Nome}Screen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch({nome}NotifierProvider);

    return Scaffold(
      body: switch (state) {
        {Nome}Loading() => const _SkeletonContent(), // skeleton, nunca overlay global
        {Nome}Loaded(:final data) => _Content(data: data),
        {Nome}Error(:final message) => _ErrorView(message: message),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
```

---

## Template de Unit Test

```dart
void main() {
  late {Nome}Repository repository;
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = {Nome}Repository(mockClient);
  });

  group('{Nome}Repository', () {
    test('list() returns models on success', () async {
      // arrange
      // act
      // assert
    });

    test('list() throws ServerException on postgrest error', () async {
      // arrange
      // act
      // assert
    });
  });
}
```
