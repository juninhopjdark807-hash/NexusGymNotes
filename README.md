# Nexus Gym

App mobile de **registro de treinos de musculação** — rápido, offline e com interface
clean, elegante e futurista. Prioridade absoluta: **mínimo de cliques durante o treino**.

- **Plataforma atual:** Android (instalável, 100% offline)
- **Arquitetura:** Flutter + Dart multiplataforma — o mesmo código-base prepara o **iOS**
- **Dados:** SQLite local no dispositivo (sem login, sem internet, sem servidor)
- **IDs:** UUID + timestamps absolutos — estrutura pronta para a futura sincronização
  `Android ↔ Servidor ↔ iOS`

---

## Como rodar

Pré-requisito: [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable).

```bash
flutter pub get
flutter run            # em um dispositivo/emulador Android conectado
```

Para gerar o APK:

```bash
flutter build apk --release
```

Para rodar os testes (regras de negócio):

```bash
flutter test
```

> O projeto inclui as pastas `android/` e `ios/` geradas a partir dos templates oficiais
> do Flutter stable. Se o seu Flutter for uma versão muito diferente e algo ficar
> desalinhado, rode `flutter create . --platforms=android,ios` para regenerar as
> pastas de plataforma (o código em `lib/` não é afetado).
>
> **Nota:** a persistência usa `sqflite` (SQLite), disponível em Android e iOS.
> O build web ainda não é suportado nesta fase (a pasta `web/` está presente
> apenas como scaffolding do template).

### Preview web do UX (opcional)

`preview/` contém um protótipo web interativo (vanilla JS) que espelha exatamente a
mesma interface, fluxos e regras de negócio do app — útil para revisões de UX sem
dispositivo. As regras de negócio têm testes:

```bash
cd preview && node --test logic.test.mjs
```

Para visualizar: abra `preview/index.html` em um navegador (ou sirva a pasta).

---

## Fluxo principal

```
Criar treino → adicionar exercícios (ordem por drag & drop)
→ INICIAR TREINO
→ referência (maior carga de trabalho anterior)
→ aquecimento (30% da referência, par)
→ preparatória (90% da referência, par)
→ séries de trabalho (quantas quiser)
→ PRÓXIMO EXERCÍCIO (botão ou swipe)
→ CARDIO (ou pular)
→ FINALIZAR → resumo → HISTÓRICO
```

Durante o treino:

- **1 exercício por tela** — sem listas intermediárias;
- **Números grandes** (peso, reps) com botões de passo (±2,5 kg / ±1 rep) e digitação direta;
- O **último peso permanece preenchido** na próxima série;
- Tocar em uma série registrada → **editar**; botão/“deslizar” → **excluir** (com *desfazer*);
- Aquecimento e preparatória podem ser **desativados por exercício** (chips AQ/PR);
- Se o app for fechado no meio do treino, a tela inicial oferece **retomar**;
- **ENCERRAR** (header) salva tudo que já foi registrado.

## Regra de progressão

> A referência do próximo treino é a **maior carga de trabalho** registrada na
> execução anterior daquele exercício.
>
> **Somente séries de TRABALHO** participam do cálculo. Aquecimento e preparatória
> **não** alteram a referência.

Exemplo: trabalho `100, 100, 110 kg` → referência `110 kg` →
aquecimento `30% = 33 → 34 kg` · preparatória `90% = 99 → 100 kg`.

### Arredondamento

Valores calculados de aquecimento/preparatória são arredondados para **números pares**
(mais próximo; empate arredonda para cima): `33 → 34`, `99 → 100`, `30 → 30`, `90 → 90`.

Implementado em `lib/domain/logic/progression.dart` (funções puras, testadas em
`test/progression_test.dart`).

### Primeira execução

Sem histórico **não existe referência** — o app não inventa carga: os campos ficam em
branco para o usuário informar. Depois da primeira execução, as sugestões passam a ser
calculadas automaticamente.

---

## Arquitetura

```
lib/
├── main.dart               # bootstrap: abre o banco local e inicia o app
├── app.dart                # MaterialApp, tema, shell de navegação (Treinos | Histórico)
├── core/
│   ├── theme.dart          # tokens visuais: escuro, 1 cor de destaque (volt), tipografia
│   └── format.dart         # formatação pt-BR (kg, datas, duração) e parsing de entrada
├── domain/                 # ← REGRAS DE NEGÓCIO (sem UI, sem persistência)
│   ├── models/
│   │   ├── exercise.dart           # Exercise + MuscleGroup
│   │   ├── workout_template.dart   # WorkoutTemplate (planejado) + WorkoutExercise (ordem/config)
│   │   ├── workout_session.dart    # WorkoutSession (executado)
│   │   ├── set_record.dart         # Set + SetStage (aquecimento | preparatoria | trabalho)
│   │   └── cardio_record.dart      # CardioRecord + CardioType
│   └── logic/
│       └── progression.dart        # referência, 30%/90%, arredondamento para par
├── data/                   # ← PERSISTÊNCIA (SQLite local, offline)
│   ├── database.dart               # schema + conexão
│   ├── exercise_repository.dart
│   ├── template_repository.dart
│   └── session_repository.dart     # sessões, séries, cardio, consulta de referência
├── state/                  # ← ESTADO DA APLICAÇÃO (Riverpod)
│   ├── providers.dart          # providers reativos (streams do banco)
│   └── active_workout.dart     # Notifier do treino em andamento (navegação, iniciar, encerrar)
└── ui/                     # ← APENAS INTERFACE (sem regras de negócio)
    ├── app_frame.dart
    ├── screens/              # home, template, editor, workout, cardio, summary,
    │                         # history, session detail, exercise history, picker
    └── widgets/              # botões, campos de peso/reps, linhas de série, sheet de edição
```

**Separação de responsabilidades**

| Camada | Regra |
|---|---|
| `domain/` | Lógica pura e modelos. Testável sem Flutter. |
| `data/` | Repositórios + SQLite. Emitem “change streams” — o banco é a fonte da verdade. |
| `state/` | Riverpod: reage a mudanças do banco e mantém o treino em andamento. |
| `ui/` | Widgets consome providers; nunca acessa o banco diretamente. |

**Treino planejado × treino executado:** `WorkoutTemplate` é a receita;
`WorkoutSession` é a execução (com snapshot do nome do treino e contagens). Essa
distinção fica explícita nos modelos e no banco — essencial para as futuras
funcionalidades de personal trainer e sincronização.

## Modelo de dados (SQLite)

| Tabela | Campos principais |
|---|---|
| `exercises` | id (UUID), name, muscle_group, created_at |
| `templates` | id, name, **assigned_by** (reservado p/ personal), created_at, updated_at |
| `template_exercises` | id, template_id, exercise_id, position, warmup_enabled, prep_enabled |
| `sessions` | id, template_id, template_name, **assigned_by** (reservado), started_at, ended_at, exercise_count, total_sets |
| `sets` | id, session_id, exercise_id, stage (`aquecimento`/`preparatoria`/`trabalho`), weight_kg, reps, position, created_at |
| `cardio` | id, session_id (única), type, duration_minutes, distance_km, note |

FKs: `sets`/`cardio` → `sessions` (CASCADE); `template_exercises` → `templates` (CASCADE)
e `exercises` (RESTRICT — não se exclui exercício em uso); `sessions.template_id` →
`templates` (SET NULL — o histórico sobrevive à exclusão do treino).

## Fase 1 — o que **não** está implementado (de propósito)

Login/cadastro · personal trainer · sincronização em nuvem · assinaturas/pagamentos ·
rede social/ranking · IA · gráficos avançados · banco online de exercícios ·
notificações · smartwatch.

A arquitetura já prepara essas evoluções: IDs globais, timestamps absolutes,
`assigned_by` reservado nos modelos, repositórios isolados da UI e regras de negócio
puras e testáveis.

---

## Design

- Tema **exclusivamente escuro** (`#0B0B0D`), superfícies discretas;
- **Uma única cor de destaque** (volt `#C8F542`) para ações importantes;
- Tipografia: **Space Grotesk** (números/nome do exercício) + **Inter** (texto) —
  fontes embutidas em `assets/fonts/`;
- Botões grandes (≥ 54px), alvos de toque amplos, poucos menus:
  navegação inferior com apenas **Treinos** e **Histórico**;
- Splash dark no Android e modo dark forçado no iOS.
