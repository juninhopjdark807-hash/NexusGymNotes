import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../widgets/nexus_card.dart';

/// Tela "Mais" — atalhos e identidade (sem login/servidor na Fase 3).
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 110),
          children: [
            const Text('MAIS', style: AppText.displayM),
            const SizedBox(height: 6),
            const Text(
              'Nexus Gym Notes · offline · Fase 3',
              style: AppText.bodyDim,
            ),
            const SizedBox(height: 22),
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
                              'Registro de treinos premium',
                              style: AppText.bodyFaint,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: C.stroke, height: 1),
                  const SizedBox(height: 14),
                  const _InfoRow(
                    icon: Icons.cloud_off_rounded,
                    title: '100% offline',
                    subtitle: 'Dados ficam no dispositivo',
                  ),
                  const SizedBox(height: 12),
                  const _InfoRow(
                    icon: Icons.palette_outlined,
                    title: 'Identidade visual',
                    subtitle: 'Dark · accent roxo · tipografia geométrica',
                  ),
                  const SizedBox(height: 12),
                  const _InfoRow(
                    icon: Icons.library_books_outlined,
                    title: 'Biblioteca de exercícios',
                    subtitle: 'Catálogo + personalizados',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            NexusCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('EM BREVE', style: AppText.label),
                  SizedBox(height: 10),
                  Text(
                    'Sincronização, personal trainer e importação de treinos '
                    'estão preparados na arquitetura, mas não fazem parte desta fase.',
                    style: AppText.bodyDim,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: C.accentSecondary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppText.bodyFaint),
            ],
          ),
        ),
      ],
    );
  }
}
