import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lotto_provider.dart';
import '../services/lotto_analyzer.dart';
import '../widgets/lotto_ball.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D0D0D), Color(0xFF1A1A2E), Color(0xFF0D0D0D)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 24),
              _buildTitle(),
              const SizedBox(height: 8),
              _buildSubtitle(),
              const SizedBox(height: 12),
              _buildDrawInfo(),
              const SizedBox(height: 20),
              _buildModeSection(),
              const SizedBox(height: 24),
              _buildNumberDisplay(),
              const SizedBox(height: 12),
              _buildStatusMessage(),
              const SizedBox(height: 8),
              _buildMyNumberAnalysis(),
              const SizedBox(height: 16),
              _buildGenerateButton(),
              const SizedBox(height: 10),
              _buildSaveButton(),
              const SizedBox(height: 12),
              _buildDataInfo(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Color(0xFFFFD700), Color(0xFFFFF8DC), Color(0xFFDAA520)],
      ).createShader(bounds),
      child: const Text(
        'LOTTO ANALYZER',
        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 6),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'AI Deep Learning Number Generator',
      style: TextStyle(fontSize: 13, color: const Color(0xFFDAA520).withAlpha(180), letterSpacing: 3, fontWeight: FontWeight.w300),
    );
  }

  /// 5번 피드백: 기초 정보 (다음 추첨일, 회차)
  Widget _buildDrawInfo() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        if (!provider.isDataLoaded) return const SizedBox.shrink();

        final nextDate = provider.nextDrawDate;
        final daysLeft = nextDate.difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)).inDays;
        final dayText = daysLeft == 0 ? '오늘!' : 'D-$daysLeft';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFFFD700).withAlpha(15),
            border: Border.all(color: const Color(0xFFFFD700).withAlpha(40)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event, color: Color(0xFFFFD700), size: 16),
              const SizedBox(width: 8),
              Text(
                '제${provider.nextDrawRound}회 추첨 | ${nextDate.month}/${nextDate.day}(토) $dayText',
                style: const TextStyle(color: Color(0xFFFFD700), fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 1번 피드백: 신경망 vs 전략 모드 명확 분리
  Widget _buildModeSection() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              // 모드 선택: 전략 분석 vs AI 신경망
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () { if (provider.useNeural) provider.toggleNeural(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: !provider.useNeural ? const Color(0xFFFFD700).withAlpha(25) : Colors.white.withAlpha(5),
                          border: Border.all(
                            color: !provider.useNeural ? const Color(0xFFFFD700) : Colors.white.withAlpha(20),
                            width: !provider.useNeural ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.analytics, size: 20,
                                color: !provider.useNeural ? const Color(0xFFFFD700) : Colors.white38),
                            const SizedBox(height: 4),
                            Text('전략 분석',
                                style: TextStyle(fontSize: 12,
                                    color: !provider.useNeural ? const Color(0xFFFFD700) : Colors.white38,
                                    fontWeight: !provider.useNeural ? FontWeight.w700 : FontWeight.w400)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () { if (!provider.useNeural) provider.toggleNeural(); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: provider.useNeural ? Colors.deepPurple.withAlpha(30) : Colors.white.withAlpha(5),
                          border: Border.all(
                            color: provider.useNeural ? Colors.deepPurpleAccent : Colors.white.withAlpha(20),
                            width: provider.useNeural ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.psychology, size: 20,
                                color: provider.useNeural ? Colors.deepPurpleAccent : Colors.white38),
                            const SizedBox(height: 4),
                            Text('AI 신경망',
                                style: TextStyle(fontSize: 12,
                                    color: provider.useNeural ? Colors.deepPurpleAccent : Colors.white38,
                                    fontWeight: provider.useNeural ? FontWeight.w700 : FontWeight.w400)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // 설명 텍스트
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withAlpha(5),
                ),
                child: Text(
                  provider.useNeural
                      ? '이전 당첨 번호 패턴을 학습한 신경망이 독립적으로 예측합니다.\n전략 설정과 무관하게 동작하며, 매번 다른 번호가 나옵니다.'
                      : '아래 전략을 선택하면 번호 선택 가중치가 달라집니다.\n6개 필터(AC값, 합계, 홀짝, 저고, 구간, 연속번호)가 항상 적용됩니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(100), height: 1.5),
                ),
              ),
              const SizedBox(height: 10),
              // 전략 선택 (신경망 모드가 아닐 때만)
              if (!provider.useNeural) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: AnalysisStrategy.values.map((strategy) {
                    final isSelected = provider.strategy == strategy;
                    final label = switch (strategy) {
                      AnalysisStrategy.conservative => '보수적',
                      AnalysisStrategy.aggressive => '공격적',
                      AnalysisStrategy.balanced => '밸런스',
                    };
                    final icon = switch (strategy) {
                      AnalysisStrategy.conservative => Icons.shield,
                      AnalysisStrategy.aggressive => Icons.bolt,
                      AnalysisStrategy.balanced => Icons.balance,
                    };
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => provider.setStrategy(strategy),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isSelected ? const Color(0xFFFFD700).withAlpha(30) : Colors.white.withAlpha(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFFD700) : Colors.white.withAlpha(30),
                              width: isSelected ? 1.5 : 0.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, size: 14, color: isSelected ? const Color(0xFFFFD700) : Colors.white54),
                              const SizedBox(width: 4),
                              Text(label, style: TextStyle(
                                fontSize: 12,
                                color: isSelected ? const Color(0xFFFFD700) : Colors.white54,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 6),
                Text(
                  switch (provider.strategy) {
                    AnalysisStrategy.conservative => '최근 자주 나온 번호 위주로 선택 ("흐름을 타자")',
                    AnalysisStrategy.aggressive => '최근 안 나온 번호 위주로 선택 ("이제 나올 때 됐다")',
                    AnalysisStrategy.balanced => '자주 나온 번호 + 안 나온 번호 균형 있게 선택',
                  },
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: Colors.white.withAlpha(80)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildNumberDisplay() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        if (provider.generatedNumbers.isEmpty) return _buildEmptyBalls();
        return _buildFilledBalls(provider.generatedNumbers);
      },
    );
  }

  Widget _buildEmptyBalls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(6, (index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFDAA520).withAlpha(80), width: 1.5),
              ),
              child: Center(
                child: Text('?', style: TextStyle(color: const Color(0xFFDAA520).withAlpha(100), fontSize: 20, fontWeight: FontWeight.w300)),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilledBalls(List<int> numbers) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        return Opacity(opacity: value, child: Transform.scale(scale: 0.5 + (value * 0.5), child: child));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: numbers.map((number) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: LottoBall(number: number, size: 50),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            provider.statusMessage,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.white.withAlpha(150), letterSpacing: 0.5, height: 1.5),
          ),
        );
      },
    );
  }

  /// 3번 피드백: 내 번호 분석 (생성된 번호의 AC값, 합계 등)
  Widget _buildMyNumberAnalysis() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        if (provider.generatedNumbers.isEmpty) return const SizedBox.shrink();

        final nums = provider.generatedNumbers;
        final analyzer = LottoAnalyzer(historicalData: provider.filteredData);
        final ac = analyzer.calculateAC(nums);
        final sum = analyzer.sumOfNumbers(nums);
        final oddCount = nums.where((n) => n % 2 == 1).length;
        final lowCount = nums.where((n) => n <= 22).length;
        final sections = analyzer.countCoveredSections(nums);
        final primeCount = nums.where((n) => LottoAnalyzer.primes.contains(n)).length;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withAlpha(6),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 번호 분석', style: TextStyle(color: const Color(0xFFFFD700).withAlpha(200), fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: [
                    _analysisChip('AC값 $ac', ac >= 7),
                    _analysisChip('합계 $sum', sum >= 100 && sum <= 175),
                    _analysisChip('홀짝 $oddCount:${6 - oddCount}', oddCount >= 2 && oddCount <= 4),
                    _analysisChip('저고 $lowCount:${6 - lowCount}', lowCount >= 2 && lowCount <= 4),
                    _analysisChip('구간 $sections/5', sections >= 3),
                    _analysisChip('소수 $primeCount개', true),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _analysisChip(String label, bool pass) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: pass ? const Color(0xFFFFD700).withAlpha(15) : Colors.red.withAlpha(15),
        border: Border.all(
          color: pass ? const Color(0xFFFFD700).withAlpha(40) : Colors.red.withAlpha(40)),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 10,
        color: pass ? const Color(0xFFFFD700) : Colors.redAccent,
        fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildGenerateButton() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        final isReady = provider.isDataLoaded && !provider.isLoading;
        return GestureDetector(
          onTap: isReady ? () => provider.generateNumbers() : null,
          child: Container(
            width: 220, height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: isReady
                    ? [const Color(0xFFFFD700), const Color(0xFFDAA520)]
                    : [Colors.grey.shade800, Colors.grey.shade700],
              ),
              boxShadow: isReady ? [BoxShadow(color: const Color(0xFFFFD700).withAlpha(60), blurRadius: 20, spreadRadius: 2)] : [],
            ),
            child: Center(
              child: provider.isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : Text(
                      provider.isDataLoaded ? '번호 생성' : '데이터 로딩 중...',
                      style: TextStyle(color: isReady ? Colors.black : Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ),
          ),
        );
      },
    );
  }

  /// 2번 피드백: 저장 버튼 + 저장 완료 표시
  Widget _buildSaveButton() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        if (provider.generatedNumbers.isEmpty) return const SizedBox.shrink();

        if (provider.numbersSaved) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green.withAlpha(200)),
                const SizedBox(width: 6),
                Text('저장 완료! 히스토리 탭에서 확인하세요',
                    style: TextStyle(fontSize: 12, color: Colors.green.withAlpha(200))),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: () async {
            final saved = await provider.saveCurrentNumbers();
            if (saved && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('번호가 저장되었습니다! 히스토리 탭에서 확인하세요'),
                  backgroundColor: const Color(0xFF1A1A2E),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFD700).withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.save_alt, size: 16, color: const Color(0xFFFFD700).withAlpha(180)),
                const SizedBox(width: 6),
                Text('이 번호 저장하기', style: TextStyle(fontSize: 13, color: const Color(0xFFFFD700).withAlpha(180), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDataInfo() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        if (!provider.isDataLoaded) return const SizedBox.shrink();
        return Text(
          '분석 데이터: ${provider.historicalData.length}회차 | ${provider.useNeural ? "AI 신경망" : "${_strategyLabel(provider.strategy)} 전략"}',
          style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(80), letterSpacing: 1),
        );
      },
    );
  }

  String _strategyLabel(AnalysisStrategy s) {
    return switch (s) {
      AnalysisStrategy.conservative => '보수적',
      AnalysisStrategy.aggressive => '공격적',
      AnalysisStrategy.balanced => '밸런스',
    };
  }
}
