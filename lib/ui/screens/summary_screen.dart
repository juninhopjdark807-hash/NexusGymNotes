import 'package:flutter/material.dart';

import '../widgets/session_summary_dialog.dart';

/// Compatibilidade: abre o modal único de resumo da sessão.
///
/// Preferir [finishWorkoutAndShowSummary] / [showSessionSummaryDialog].
class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final nav = Navigator.of(context, rootNavigator: true);
      // Remove esta rota placeholder e mostra o dialog na home.
      if (nav.canPop()) nav.pop();
      await Future<void>.delayed(Duration.zero);
      if (!nav.context.mounted) return;
      await showSessionSummaryDialog(
        nav.context,
        sessionId: widget.sessionId,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
