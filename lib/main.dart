import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'data/database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Banco local (offline) — aberto antes da primeira tela.
  await AppDatabase.open();
  runApp(const ProviderScope(child: NexusApp()));
}
