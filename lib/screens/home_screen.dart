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
        child: Column(
          children: [
            const SizedBox(height: 30),
            _buildTitle(),
            const SizedBox(height: 12),
            _buildSubtitle(),
            const SizedBox(height: 24),
            _buildStrategySelector(),
            const SizedBox(height: 8),
            _buildNeuralToggle(),
            const Spacer(flex: 2),
            _buildNumberDisplay(),
            const SizedBox(height: 16),
            _buildStatusMessage(),
            const SizedBox(height: 12),
            _buildActionButtons(),
            const Spacer(flex: 2),
            _buildGenerateButton(),
            const SizedBox(height: 12),
            _buildDataInfo(),
            const SizedBox(height: 20),
          ],
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
        style: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 6,
        ),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Text(
      'AI Deep Learning Number Generator',
      style: TextStyle(
        fontSize: 13,
        color: const Color(0xFFDAA520).withAlpha(180),
        letterSpacing: 3,
        fontWeight: FontWeight.w300,
      ),
    );
  }

  Widget _buildStrategySelector() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: isSelected
                          ? const Color(0xFFFFD700).withAlpha(30)
                          : Colors.white.withAlpha(8),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFFFD700)
                            : Colors.white.withAlpha(30),
                        width: isSelected ? 1.5 : 0.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 14,
                          color: isSelected
                              ? const Color(0xFFFFD700)
                              : Colors.white54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            color: isSelected
                                ? const Color(0xFFFFD700)
                                : Colors.white54,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildNeuralToggle() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        return GestureDetector(
          onTap: provider.toggleNeural,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: provider.useNeural
                  ? Colors.deepPurple.withAlpha(40)
                  : Colors.white.withAlpha(8),
              border: Border.all(
                color: provider.useNeural
                    ? Colors.deepPurpleAccent
                    : Colors.white.withAlpha(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  size: 14,
                  color: provider.useNeural
                      ? Colors.deepPurpleAccent
                      : Colors.white38,
                ),
                const SizedBox(width: 6),
                Text(
                  'AI 신경망 모드',
                  style: TextStyle(
                    fontSize: 11,
                    color: provider.useNeural
                        ? Colors.deepPurpleAccent
                        : Colors.white38,
                    fontWeight:
                        provider.useNeural ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNumberDisplay() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        if (provider.generatedNumbers.isEmpty) {
          return _buildEmptyBalls();
        }
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
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFDAA520).withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: const Color(0xFFDAA520).withAlpha(100),
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
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
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.5 + (value * 0.5),
            child: child,
          ),
        );
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
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withAlpha(150),
              letterSpacing: 0.5,
              height: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        if (provider.generatedNumbers.isEmpty) return const SizedBox.shrink();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () async {
                await provider.saveCurrentNumbers();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('번호가 저장되었습니다'),
                      backgroundColor: const Color(0xFF1A1A2E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFFFFD700).withAlpha(60),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.save_alt,
                      size: 16,
                      color: const Color(0xFFFFD700).withAlpha(180),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '번호 저장',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFFFFD700).withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenerateButton() {
    return Consumer<LottoProvider>(
      builder: (context, provider, _) {
        final isReady = provider.isDataLoaded && !provider.isLoading;
        return GestureDetector(
          onTap: isReady ? () => provider.generateNumbers() : null,
          child: Container(
            width: 220,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                colors: isReady
                    ? [const Color(0xFFFFD700), const Color(0xFFDAA520)]
                    : [Colors.grey.shade800, Colors.grey.shade700],
              ),
              boxShadow: isReady
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withAlpha(60),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: provider.isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Text(
                      provider.isDataLoaded ? '번호 생성' : '데이터 로딩 중...',
                      style: TextStyle(
                        color: isReady ? Colors.black : Colors.grey.shade500,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2,
                      ),
                    ),
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
          '분석 데이터: 최근 ${provider.historicalData.length}회차',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withAlpha(80),
            letterSpacing: 1,
          ),
        );
      },
    );
  }
}
