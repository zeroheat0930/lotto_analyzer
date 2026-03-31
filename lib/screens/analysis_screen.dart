import 'dart:math';
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
  int _compatibleTarget = 1;

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
                _sectionTitle('1. 번호별 출현 빈도'),
                const SizedBox(height: 12),
                _buildFrequencyChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('2. 번호 출현 추세'),
                const SizedBox(height: 8),
                _buildNumberSelector(),
                const SizedBox(height: 12),
                _buildTrendChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('3. 홀짝 비율'),
                const SizedBox(height: 12),
                _buildPieRow(analyzer.getOddEvenRatio(), '홀수', '짝수', 'odd', 'even'),
                const SizedBox(height: 28),
                _sectionTitle('4. 저고 비율 (1~22 vs 23~45)'),
                const SizedBox(height: 12),
                _buildPieRow(analyzer.getLowHighRatio(), '저번호', '고번호', 'low', 'high'),
                const SizedBox(height: 28),
                _sectionTitle('5. 소수 포함 비율'),
                const SizedBox(height: 12),
                _buildPieRow(analyzer.getPrimeRatio(), '소수', '비소수', 'prime', 'nonPrime'),
                const SizedBox(height: 28),
                _sectionTitle('6. 3의 배수 비율'),
                const SizedBox(height: 12),
                _buildPieRow(analyzer.getMultipleOf3Ratio(), '3의 배수', '기타', 'mul3', 'other'),
                const SizedBox(height: 28),
                _sectionTitle('7. 피보나치 수 비율'),
                const SizedBox(height: 12),
                _buildPieRow(analyzer.getFibonacciRatio(), '피보나치', '기타', 'fib', 'nonFib'),
                const SizedBox(height: 28),
                _sectionTitle('8. 끝수(0~9) 분포'),
                const SizedBox(height: 12),
                _buildEndDigitChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('9. 구간별 분포'),
                const SizedBox(height: 12),
                _buildSectionChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('10. 색상별 분포'),
                const SizedBox(height: 12),
                _buildColorChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('11. AC값 분포'),
                const SizedBox(height: 12),
                _buildACChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('12. 합계 범위 분포'),
                const SizedBox(height: 12),
                _buildSumRangeChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('13. 회차별 번호합 추세'),
                const SizedBox(height: 12),
                _buildSumTrendChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('14. 번호 간격 패턴'),
                const SizedBox(height: 12),
                _buildGapChart(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('15. 미출현 기간 (오래 안 나온 번호)'),
                const SizedBox(height: 12),
                _buildAbsenceCard(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('16. 이월수 통계'),
                const SizedBox(height: 12),
                _buildStatCard(
                  '평균 이월수',
                  '${analyzer.getCarryOverStats()['avg']?.toStringAsFixed(1)}개',
                  '이전 회차에서 반복 출현한 번호 평균',
                ),
                const SizedBox(height: 28),
                _sectionTitle('17. 대칭수 출현율 (합=46)'),
                const SizedBox(height: 12),
                _buildStatCard(
                  '대칭수 포함 비율',
                  '${analyzer.getSymmetryStats()['rate']?.toStringAsFixed(1)}%',
                  '합이 46인 번호 쌍(1+45, 2+44...)이 포함된 회차',
                ),
                const SizedBox(height: 28),
                _sectionTitle('18. 동반출현 TOP 10'),
                const SizedBox(height: 12),
                _buildCoOccurrenceCard(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('19. 쌍수 분석 (같은 십의자리)'),
                const SizedBox(height: 12),
                _buildTwinCard(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('20. 골든존 TOP 10'),
                const SizedBox(height: 12),
                _buildGoldenZoneCard(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('21. 미출현 후 출현 (10회+ 공백)'),
                const SizedBox(height: 12),
                _buildLongAbsenceCard(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('22. 궁합수 분석'),
                const SizedBox(height: 8),
                _buildCompatibleSelector(),
                const SizedBox(height: 12),
                _buildCompatibleCard(analyzer),
                const SizedBox(height: 28),
                _sectionTitle('23. 전략별 시뮬레이션'),
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

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Color(0xFFFFD700),
        letterSpacing: 0.5,
      ),
    );
  }

  // === 바 차트 빌더 ===
  Widget _buildBarChartGeneric(Map<dynamic, int> data, {double barWidth = 8}) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxVal = data.values.reduce(max).toDouble();
    final entries = data.entries.toList();
    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          maxY: maxVal + 2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                '${entries[group.x.toInt()].key}: ${rod.toY.toInt()}',
                const TextStyle(color: Color(0xFFFFD700), fontSize: 11),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  final idx = v.toInt();
                  if (idx < entries.length) {
                    return Text('${entries[idx].key}',
                        style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 9));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(entries.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  width: barWidth,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xFFDAA520), Color(0xFFFFD700)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(3),
                    topRight: Radius.circular(3),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // === 기존 차트들 ===
  Widget _buildFrequencyChart(LottoAnalyzer analyzer) {
    final freq = analyzer.getFrequencyMap();
    final maxFreq = freq.values.reduce(max).toDouble();
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          maxY: maxFreq + 2,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (g, gi, rod, ri) => BarTooltipItem(
                '${g.x}번: ${rod.toY.toInt()}회',
                const TextStyle(color: Color(0xFFFFD700), fontSize: 11),
              ),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  if (v.toInt() % 5 == 0) {
                    return Text('${v.toInt()}',
                        style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 9));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(45, (i) {
            final num = i + 1;
            return BarChartGroupData(
              x: num,
              barRods: [
                BarChartRodData(
                  toY: (freq[num] ?? 0).toDouble(),
                  width: 4,
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [const Color(0xFFDAA520).withAlpha(100), const Color(0xFFFFD700)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(2), topRight: Radius.circular(2)),
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
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFFFFD700) : Colors.white.withAlpha(20),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFFFD700) : Colors.white.withAlpha(40)),
                ),
                child: Center(
                  child: Text('$num',
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400)),
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
      height: 140,
      child: LineChart(
        LineChartData(
          minY: -0.2, maxY: 1.2,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  final idx = v.toInt();
                  if (idx >= 0 && idx < trend.length) {
                    return Text('${idx + 1}',
                        style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 10));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true, reservedSize: 30,
                getTitlesWidget: (v, m) {
                  if (v == 0) return Text('X', style: TextStyle(color: Colors.red.withAlpha(150), fontSize: 10));
                  if (v == 1) return Text('O', style: TextStyle(color: Colors.green.withAlpha(150), fontSize: 10));
                  return const SizedBox.shrink();
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            drawVerticalLine: false, horizontalInterval: 1,
            getDrawingHorizontalLine: (v) => FlLine(color: Colors.white.withAlpha(20), strokeWidth: 0.5),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(trend.length, (i) => FlSpot(i.toDouble(), trend[i] ? 1.0 : 0.0)),
              isCurved: false, color: const Color(0xFFFFD700), barWidth: 2,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, p, b, idx) => FlDotCirclePainter(
                  radius: 4,
                  color: spot.y > 0 ? const Color(0xFFFFD700) : Colors.grey.shade700,
                  strokeWidth: 1, strokeColor: Colors.white24,
                ),
              ),
              belowBarData: BarAreaData(show: true, color: const Color(0xFFFFD700).withAlpha(20)),
            ),
          ],
        ),
      ),
    );
  }

  // === 파이 차트 ===
  Widget _buildPieRow(Map<String, double> data, String label1, String label2, String key1, String key2) {
    final v1 = data[key1] ?? 50;
    final v2 = data[key2] ?? 50;
    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: v1, title: '$label1\n${v1.toStringAsFixed(1)}%',
                    color: const Color(0xFFFFD700), radius: 45,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  PieChartSectionData(
                    value: v2, title: '$label2\n${v2.toStringAsFixed(1)}%',
                    color: const Color(0xFFDAA520).withAlpha(150), radius: 45,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legend(label1, const Color(0xFFFFD700)),
              const SizedBox(height: 8),
              _legend(label2, const Color(0xFFDAA520).withAlpha(150)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
      ],
    );
  }

  // === 새 차트들 ===
  Widget _buildEndDigitChart(LottoAnalyzer analyzer) {
    return _buildBarChartGeneric(analyzer.getEndDigitDistribution(), barWidth: 16);
  }

  Widget _buildSectionChart(LottoAnalyzer analyzer) {
    final data = analyzer.getSectionDistribution();
    return _buildBarChartGeneric(Map<dynamic, int>.from(data), barWidth: 24);
  }

  Widget _buildColorChart(LottoAnalyzer analyzer) {
    final data = analyzer.getColorDistribution();
    final colorMap = {
      'yellow': Colors.amber, 'blue': Colors.blue,
      'red': Colors.red, 'gray': Colors.grey, 'green': Colors.green,
    };
    final labelMap = {
      'yellow': '노랑', 'blue': '파랑', 'red': '빨강', 'gray': '회색', 'green': '초록',
    };
    return SizedBox(
      height: 150,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2, centerSpaceRadius: 25,
                sections: data.entries.map((e) {
                  return PieChartSectionData(
                    value: e.value.toDouble(),
                    title: '${e.value}',
                    color: colorMap[e.key] ?? Colors.white,
                    radius: 40,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: data.entries.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: _legend(labelMap[e.key] ?? e.key, colorMap[e.key] ?? Colors.white),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildACChart(LottoAnalyzer analyzer) {
    final data = analyzer.getACDistribution();
    final sorted = Map.fromEntries(data.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return _buildBarChartGeneric(Map<dynamic, int>.from(sorted), barWidth: 20);
  }

  Widget _buildSumRangeChart(LottoAnalyzer analyzer) {
    final data = analyzer.getSumRangeDistribution();
    return _buildBarChartGeneric(Map<dynamic, int>.from(data), barWidth: 30);
  }

  Widget _buildSumTrendChart(LottoAnalyzer analyzer) {
    final sums = analyzer.getSumTrend(20);
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, m) {
                  if (v.toInt() % 5 == 0 && v.toInt() < sums.length) {
                    return Text('${v.toInt() + 1}',
                        style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 9));
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(sums.length, (i) => FlSpot(i.toDouble(), sums[i].toDouble())),
              isCurved: true, color: const Color(0xFFFFD700), barWidth: 2,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: const Color(0xFFFFD700).withAlpha(30)),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(y: 100, color: Colors.red.withAlpha(60), strokeWidth: 1, dashArray: [5, 5]),
              HorizontalLine(y: 175, color: Colors.red.withAlpha(60), strokeWidth: 1, dashArray: [5, 5]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGapChart(LottoAnalyzer analyzer) {
    final data = analyzer.getGapDistribution();
    final sorted = Map.fromEntries(data.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    final limited = Map.fromEntries(sorted.entries.where((e) => e.key <= 20));
    return _buildBarChartGeneric(Map<dynamic, int>.from(limited), barWidth: 12);
  }

  // === 카드형 표시 ===
  Widget _buildCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withAlpha(8),
        border: Border.all(color: const Color(0xFFDAA520).withAlpha(40)),
      ),
      child: child,
    );
  }

  Widget _buildStatCard(String title, String value, String desc) {
    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(value, style: const TextStyle(color: Color(0xFFFFD700), fontSize: 20, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 4),
          Text(desc, style: TextStyle(color: Colors.white.withAlpha(100), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildAbsenceCard(LottoAnalyzer analyzer) {
    final absence = analyzer.getAbsencePeriod();
    final sorted = absence.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top10 = sorted.take(10).toList();
    return _buildCard(
      Column(
        children: top10.map((e) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD700).withAlpha(30),
                  ),
                  child: Center(child: Text('${e.key}',
                      style: const TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.w700))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: e.value / (sorted.first.value > 0 ? sorted.first.value : 1),
                    backgroundColor: Colors.white.withAlpha(10),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFDAA520)),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${e.value}회차', style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 11)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCoOccurrenceCard(LottoAnalyzer analyzer) {
    final pairs = analyzer.getCoOccurrencePairs(10);
    return _buildCard(
      Wrap(
        spacing: 8, runSpacing: 8,
        children: pairs.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFFFFD700).withAlpha(20),
            ),
            child: Text('${e.key} (${e.value}회)',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTwinCard(LottoAnalyzer analyzer) {
    final twins = analyzer.getTwinNumberStats();
    if (twins.isEmpty) return _buildCard(Text('데이터 없음', style: TextStyle(color: Colors.white.withAlpha(100))));
    final sorted = twins.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return _buildCard(
      Wrap(
        spacing: 8, runSpacing: 8,
        children: sorted.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withAlpha(10),
            ),
            child: Text('${e.key}: ${e.value}회',
                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 11)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoldenZoneCard(LottoAnalyzer analyzer) {
    final golden = analyzer.getGoldenZone();
    return _buildCard(
      Wrap(
        spacing: 8, runSpacing: 8,
        children: golden.map((e) {
          return Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFDAA520)]),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${e.key}', style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.w900)),
                Text('${e.value}', style: const TextStyle(color: Colors.black54, fontSize: 9)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLongAbsenceCard(LottoAnalyzer analyzer) {
    final data = analyzer.getLongAbsenceThenAppeared(10);
    if (data.isEmpty) return _buildCard(Text('해당 없음', style: TextStyle(color: Colors.white.withAlpha(100))));
    return _buildCard(
      Wrap(
        spacing: 8, runSpacing: 8,
        children: data.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.deepPurple.withAlpha(30),
            ),
            child: Text('${e.key}번 (${e.value}회 공백)',
                style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 11, fontWeight: FontWeight.w600)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCompatibleSelector() {
    return SizedBox(
      height: 36,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 45,
        itemBuilder: (context, index) {
          final num = index + 1;
          final isSelected = num == _compatibleTarget;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () => setState(() => _compatibleTarget = num),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.deepPurpleAccent : Colors.white.withAlpha(20),
                  border: Border.all(
                    color: isSelected ? Colors.deepPurpleAccent : Colors.white.withAlpha(40)),
                ),
                child: Center(
                  child: Text('$num',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w400)),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompatibleCard(LottoAnalyzer analyzer) {
    final data = analyzer.getCompatibleNumbers(_compatibleTarget);
    if (data.isEmpty) return _buildCard(Text('데이터 없음', style: TextStyle(color: Colors.white.withAlpha(100))));
    final sorted = data.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();
    return _buildCard(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$_compatibleTarget번과 자주 함께 나오는 번호',
              style: TextStyle(color: Colors.white.withAlpha(150), fontSize: 12)),
          const SizedBox(height: 10),
          ...top5.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Container(
                  width: 28, height: 28,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFD700)),
                  child: Center(child: Text('${e.key}',
                      style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.w800))),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LinearProgressIndicator(
                    value: e.value / 100,
                    backgroundColor: Colors.white.withAlpha(10),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFFFFD700)),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${e.value.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Color(0xFFFFD700), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildStrategyComparison(LottoAnalyzer analyzer) {
    final results = analyzer.simulateStrategies(simulations: 200);
    return _buildCard(
      Column(
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
                      Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        '평균 ${result?.avgMatches.toStringAsFixed(1)}개 일치 · 3개+ 적중률 ${result?.threeOrMoreRate.toStringAsFixed(1)}%',
                        style: TextStyle(color: Colors.white.withAlpha(120), fontSize: 11),
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
