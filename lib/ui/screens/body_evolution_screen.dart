import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models/body_assessment.dart';
import '../../state/providers.dart';
import '../widgets/app_button.dart';
import '../widgets/nexus_card.dart';

enum _Period { d7, d30, m3, m6, y1, all }

enum _Metric {
  weight,
  bodyFat,
  leanMass,
  waist,
  hip,
  neck,
}

/// Evolução corporal a partir do histórico real de avaliações.
class BodyEvolutionScreen extends ConsumerStatefulWidget {
  const BodyEvolutionScreen({super.key});

  @override
  ConsumerState<BodyEvolutionScreen> createState() =>
      _BodyEvolutionScreenState();
}

class _BodyEvolutionScreenState extends ConsumerState<BodyEvolutionScreen> {
  _Period _period = _Period.all;
  _Metric _metric = _Metric.weight;

  List<BodyAssessment> _filter(
    List<BodyAssessment> all,
    _Period period,
  ) {
    if (period == _Period.all) return all;
    final now = DateTime.now();
    final days = switch (period) {
      _Period.d7 => 7,
      _Period.d30 => 30,
      _Period.m3 => 90,
      _Period.m6 => 180,
      _Period.y1 => 365,
      _Period.all => 0,
    };
    final from = now.subtract(Duration(days: days));
    return all.where((a) => !a.date.isBefore(from)).toList(growable: false);
  }

  double? _value(BodyAssessment a, _Metric m) => switch (m) {
        _Metric.weight => a.weightKg,
        _Metric.bodyFat => a.bodyFatPercent,
        _Metric.leanMass => a.leanMassKg,
        _Metric.waist => a.waistCm,
        _Metric.hip => a.hipCm,
        _Metric.neck => a.neckCm,
      };

  String _metricLabel(_Metric m) => switch (m) {
        _Metric.weight => 'Peso',
        _Metric.bodyFat => 'BF estimado',
        _Metric.leanMass => 'Massa magra',
        _Metric.waist => 'Cintura',
        _Metric.hip => 'Quadril',
        _Metric.neck => 'Pescoço',
      };

  String _periodLabel(_Period p) => switch (p) {
        _Period.d7 => '7d',
        _Period.d30 => '30d',
        _Period.m3 => '3m',
        _Period.m6 => '6m',
        _Period.y1 => '1a',
        _Period.all => 'Tudo',
      };

  @override
  Widget build(BuildContext context) {
    final all =
        ref.watch(bodyAssessmentsProvider).valueOrNull ?? const <BodyAssessment>[];
    // Ordem cronológica para o gráfico.
    final filtered = _filter(all, _period).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final points = <(DateTime, double)>[];
    for (final a in filtered) {
      final v = _value(a, _metric);
      if (v != null) points.add((a.date, v));
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 24, 0),
              child: Row(
                children: [
                  AppBackButton(onPressed: () => Navigator.of(context).pop()),
                  const SizedBox(width: 8),
                  const Text('EVOLUÇÃO CORPORAL', style: AppText.displayM),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (final p in _Period.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: _periodLabel(p),
                        selected: _period == p,
                        onTap: () => setState(() => _period = p),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  for (final m in _Metric.values)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _Chip(
                        label: _metricLabel(m),
                        selected: _metric == m,
                        onTap: () => setState(() => _metric = m),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
                children: [
                  NexusCard(
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 12),
                    child: points.length < 2
                        ? SizedBox(
                            height: 140,
                            child: Center(
                              child: Text(
                                points.isEmpty
                                    ? 'Sem dados neste período'
                                    : 'Registre mais uma avaliação para ver o gráfico',
                                style: AppText.bodyDim,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          )
                        : _SimpleLineChart(points: points),
                  ),
                  if (points.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    NexusCard(
                      child: Column(
                        children: [
                          for (final a in filtered.reversed.take(8))
                            if (_value(a, _metric) != null)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        formatDate(a.date),
                                        style: AppText.bodyDim,
                                      ),
                                    ),
                                    Text(
                                      _formatMetric(
                                        _value(a, _metric)!,
                                        _metric,
                                      ),
                                      style: const TextStyle(
                                        fontFamily: AppFonts.display,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMetric(double v, _Metric m) {
    return switch (m) {
      _Metric.weight || _Metric.leanMass => '${formatKg(v)} kg',
      _Metric.bodyFat => '${v.toStringAsFixed(1)} %',
      _ => '${formatKg(v)} cm',
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? C.accentSoft : C.surface2,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? C.accent : C.stroke),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? C.accentSecondary : C.textDim,
            ),
          ),
        ),
      ),
    );
  }
}

/// Gráfico de linha minimalista (sem dependência externa).
class _SimpleLineChart extends StatelessWidget {
  const _SimpleLineChart({required this.points});

  final List<(DateTime, double)> points;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      width: double.infinity,
      child: CustomPaint(
        painter: _LinePainter(points: points),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.points});

  final List<(DateTime, double)> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final values = points.map((p) => p.$2).toList();
    var minV = values.first;
    var maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    if ((maxV - minV).abs() < 0.001) {
      minV -= 1;
      maxV += 1;
    }
    final pad = 8.0;
    final w = size.width - pad * 2;
    final h = size.height - pad * 2;

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = pad + (i / (points.length - 1)) * w;
      final t = (points[i].$2 - minV) / (maxV - minV);
      final y = pad + h - (t * h);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final line = Paint()
      ..color = C.accent
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, line);

    final dot = Paint()..color = C.accentSecondary;
    for (var i = 0; i < points.length; i++) {
      final x = pad + (i / (points.length - 1)) * w;
      final t = (points[i].$2 - minV) / (maxV - minV);
      final y = pad + h - (t * h);
      canvas.drawCircle(Offset(x, y), 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.points != points;
}
