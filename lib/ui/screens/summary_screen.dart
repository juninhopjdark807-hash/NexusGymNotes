import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/session_summary_dialog.dart';

/// Compatibilidade: redireciona para o modal único de resumo da sessão.
///
/// Preferir [showSessionSummaryDialog] diretamente nos fluxos novos.
class SummaryScreen extends ConsumerStatefulWidget {
  const SummaryScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Substitui esta rota pelo dialog + volta ao início.
      Navigator.of(context).pop();
      await showSessionSummaryDialog(
        context,
        sessionId: widget.sessionId,
        ref: ref,
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
