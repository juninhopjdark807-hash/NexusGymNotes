import 'package:flutter/material.dart';

import 'data/database.dart';
import 'ui/screens/splash_screen.dart';

/// Splash exibida enquanto o banco é aberto.
///
/// Em Android 12+ o sistema mascara o ícone da splash nativa em um círculo,
/// o que corta a parte inferior da arte. Por isso o logo completo (asset
/// "icone") é renderizado aqui, sem máscara, com fundo escuro idêntico ao
/// launch nativo — transição contínua e profissional.
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key, required this.child});

  /// Conteúdo exibido após a abertura do banco (shell do app).
  final Widget child;

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    // Mantém a marca visível por um momento mínimo (evita "piscar").
    final started = DateTime.now();
    await AppDatabase.open();
    const minVisible = Duration(milliseconds: 400);
    final elapsed = DateTime.now().difference(started);
    if (elapsed < minVisible) {
      await Future<void>.delayed(minVisible - elapsed);
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    return _ready ? widget.child : const SplashScreen();
  }
}
