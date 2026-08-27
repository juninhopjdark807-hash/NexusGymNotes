import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'state/providers.dart';
import 'ui/app_frame.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/home_screen.dart';

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

/// Shell com navegação inferior mínima: Treinos | Histórico.
class RootShell extends ConsumerWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    return AppFrame(
      child: Scaffold(
        body: IndexedStack(
          index: tab.clamp(0, 1),
          children: const [HomeScreen(), HistoryScreen()],
        ),
        bottomNavigationBar: _BottomNav(
          tab: tab,
          onChanged: (t) => ref.read(tabProvider.notifier).state = t,
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.tab, required this.onChanged});

  final int tab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(28, 10, 28, 10),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: C.stroke)),
        ),
        child: Row(
          children: [
            _NavTab(
              icon: Icons.fitness_center,
              label: 'TREINOS',
              selected: tab == 0,
              onTap: () => onChanged(0),
            ),
            const SizedBox(width: 28),
            _NavTab(
              icon: Icons.history_rounded,
              label: 'HISTÓRICO',
              selected: tab == 1,
              onTap: () => onChanged(1),
            ),
            const Spacer(),
          ],
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
    final color = selected ? C.accent : C.textFaint;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
