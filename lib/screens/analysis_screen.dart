import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lotto_provider.dart';
import '../services/lotto_analyzer.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  int _selectedNumber = 1;

  @override
  Widget build(BuildContext context) {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        if (!provider.isDataLoaded) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFD700)),
          );
        }

        final analyzer = LottoAnalyzer(historicalData: provider.historicalData);

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E), Color(0xFF0D0D0D)],
            ),
          ),
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSectionTitle('번호별 출현 빈도'),
                const SizedBox(height: 12),
                _buildFrequencyChart(analyzer),
                const SizedBox(height: 32),
                _buildSectionTitle('번호 출현 추세'),
                const SizedBox(height: 8),
                _buildNumberSelector(),
                const SizedBox(height: 12),
                _buildTrendChart(analyzer),
                const SizedBox(height: 32),
                _buildSectionTitle('홀짝 비율'),
                const SizedBox(height: 12),
                _buildOddEvenChart(analyzer),
                const SizedBox(height: 32),
                _buildSectionTitle('전략별 시뮬레이션'),
                const SizedBox(height: 12),
                _buildStrategyComparison(analyzer),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Color(0xFFFFD700),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildFrequencyChart(LottoAnalyzer analyzer) {
    final freq = analyzer.getFrequencyMap();
    final maxFreq = freq.values.reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxFreq + 2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${group.x}번: ${rod.toY.toInt()}회',
                  const TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() % 5 == 0) {
                    return Text(
                      '${value.toInt()}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(120),
                        fontSize: 9,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(45, (i) {
            final num = i + 1;
            final count = freq[num] ?? 0;
            return BarChartGroupData(
              x: num,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  width: 4,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      const Color(0xFFDAA520).withAlpha(100),
                      const Color(0xFFFFD700),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2),
                    topRight: Radius.circular(2),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNumberSelector() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 45,
        itemBuilder: (context, index) {
          final num = index + 1;
          final isSelected = num == _selectedNumber;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _selectedNumber = num),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? const Color(0xFFFFD700)
                      : Colors.white.withAlpha(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFFFFD700)
                        : Colors.white.withAlpha(40),
                  ),
                ),
                child: Center(
                  child: Text(
                    '$num',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 11,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendChart(LottoAnalyzer analyzer) {
    final trend = analyzer.getNumberTrend(_selectedNumber, 10);

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minY: -0.2,
          maxY: 1.2,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < trend.length) {
                    return Text(
                      '${idx + 1}',
                      style: TextStyle(
                        color: Colors.white.withAlpha(100),
                        fontSize: 10,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return Text('X',
                        style: TextStyle(
                            color: Colors.red.withAlpha(150), fontSize: 10));
                  }
                  if (value == 1) {
                    return Text('O',
                        style: TextStyle(
                            color: Colors.green.withAlpha(150), fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withAlpha(20),
              strokeWidth: 0.5,
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                trend.length,
                (i) => FlSpot(i.toDouble(), trend[i] ? 1.0 : 0.0),
              ),
              isCurved: false,
              color: const Color(0xFFFFD700),
              barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 4,
                    color: spot.y > 0
                        ? const Color(0xFFFFD700)
                        : Colors.grey.shade700,
                    strokeWidth: 1,
                    strokeColor: Colors.white24,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFFFFD700).withAlpha(20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOddEvenChart(LottoAnalyzer analyzer) {
    final ratio = analyzer.getOddEvenRatio();
    final oddPct = ratio['odd'] ?? 50;
    final evenPct = ratio['even'] ?? 50;

    return SizedBox(
      height: 180,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 35,
                sections: [
                  PieChartSectionData(
                    value: oddPct,
                    title: '홀\n${oddPct.toStringAsFixed(1)}%',
                    color: const Color(0xFFFFD700),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  PieChartSectionData(
                    value: evenPct,
                    title: '짝\n${evenPct.toStringAsFixed(1)}%',
                    color: const Color(0xFFDAA520).withAlpha(150),
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegend('홀수', const Color(0xFFFFD700)),
              const SizedBox(height: 8),
              _buildLegend('짝수', const Color(0xFFDAA520).withAlpha(150)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStrategyComparison(LottoAnalyzer analyzer) {
    final results = analyzer.simulateStrategies(simulations: 200);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withAlpha(10),
        border: Border.all(color: const Color(0xFFDAA520).withAlpha(40)),
      ),
      child: Column(
        children: AnalysisStrategy.values.map((strategy) {
          final result = results[strategy];
          final name = switch (strategy) {
            AnalysisStrategy.conservative => '보수적 (Hot 위주)',
            AnalysisStrategy.aggressive => '공격적 (Cold 위주)',
            AnalysisStrategy.balanced => '밸런스',
          };
          final icon = switch (strategy) {
            AnalysisStrategy.conservative => Icons.shield,
            AnalysisStrategy.aggressive => Icons.bolt,
            AnalysisStrategy.balanced => Icons.balance,
          };

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFFD700), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '평균 ${result?.avgMatches.toStringAsFixed(1)}개 일치 · 3개+ 적중률 ${result?.threeOrMoreRate.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
