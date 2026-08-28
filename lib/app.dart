import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'state/providers.dart';
import 'ui/app_frame.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/more_screen.dart';
import 'ui/screens/progress_screen.dart';

/// Raiz do aplicativo.
class NexusApp extends StatelessWidget {
  const NexusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus Gym',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      builder: (context, child) => Container(color: C.bg, child: child),
      home: const RootShell(),
    );
  }
}

/// Shell com navegação inferior:
/// Treinos | Histórico | (+) | Progressão | Mais
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    // 0 Treinos, 1 Histórico, 2 Progressão, 3 Mais  (FAB = adicionar)
    final bodyIndex = tab.clamp(0, 3);
    return AppFrame(
      child: Scaffold(
        body: IndexedStack(
          index: bodyIndex,
          children: const [
            HomeScreen(),
            HistoryScreen(),
            ProgressScreen(),
            MoreScreen(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          tab: bodyIndex,
          onChanged: (t) => ref.read(tabProvider.notifier).state = t,
          onAdd: () => HomeScreen.pushNewTemplate(context),
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tab,
    required this.onChanged,
    required this.onAdd,
  });

  final int tab;
  final ValueChanged<int> onChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: C.bg,
        border: Border(top: BorderSide(color: C.strokeSoft)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            children: [
              Expanded(
                child: _NavTab(
                  icon: Icons.fitness_center_rounded,
                  label: 'Treinos',
                  selected: tab == 0,
                  onTap: () => onChanged(0),
                ),
              ),
              Expanded(
                child: _NavTab(
                  icon: Icons.history_rounded,
                  label: 'Histórico',
                  selected: tab == 1,
                  onTap: () => onChanged(1),
                ),
              ),
              // Ação principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: _AddButton(onTap: onAdd),
              ),
              Expanded(
                child: _NavTab(
                  icon: Icons.insights_rounded,
                  label: 'Progressão',
                  selected: tab == 2,
                  onTap: () => onChanged(2),
                ),
              ),
              Expanded(
                child: _NavTab(
                  icon: Icons.more_horiz_rounded,
                  label: 'Mais',
                  selected: tab == 3,
                  onTap: () => onChanged(3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: C.accent,
            boxShadow: [
              BoxShadow(
                color: C.accent.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: C.accentInk, size: 28),
        ),
      ),
    );
  }
}

class _NavTab extends StatelessWidget {
  const _NavTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? C.accentSecondary : C.textFaint;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: color,
                ),
              ),
              const SizedBox(height: 3),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 16 : 0,
                height: 2,
                decoration: BoxDecoration(
                  color: C.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
