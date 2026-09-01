import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme.dart';
import '../../state/providers.dart';
import '../app_frame.dart';
import '../widgets/nexus_card.dart';
import 'body_evolution_screen.dart';
import 'profile_screen.dart';

/// Tela "Mais" — perfil, evolução e identidade.
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 110),
          children: [
            const Text('MAIS', style: AppText.displayM),
            const SizedBox(height: 6),
            Text(
              profile == null
                  ? 'Configure seu perfil físico'
                  : 'Olá, ${profile.name}',
              style: AppText.bodyDim,
            ),
            const SizedBox(height: 22),
            NexusCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AppFrame(child: ProfileScreen()),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_outline_rounded, color: C.accentSecondary),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Perfil físico',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Dados, medidas e avaliações',
                          style: AppText.bodyFaint,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: C.textFaint),
                ],
              ),
            ),
            const SizedBox(height: 10),
            NexusCard(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const AppFrame(child: BodyEvolutionScreen()),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.show_chart_rounded, color: C.accentSecondary),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Evolução corporal',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Peso, BF, medidas ao longo do tempo',
                          style: AppText.bodyFaint,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: C.textFaint),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NexusCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: C.accentSoft,
                        ),
                        child: const Icon(
                          Icons.bolt_rounded,
                          color: C.accentSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'NEXUS GYM',
                              style: TextStyle(
                                fontFamily: AppFonts.display,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Registro de treinos · offline',
                              style: AppText.bodyFaint,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
