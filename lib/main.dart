import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // O banco é aberto dentro do AppBootstrap, com a splash (asset "icone")
  // já visível na tela — sem tela preta vazia durante a inicialização.
  runApp(const ProviderScope(child: NexusApp()));
}
