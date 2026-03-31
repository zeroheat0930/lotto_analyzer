import 'dart:math';
import '../models/lotto_round.dart';

enum AnalysisStrategy { conservative, aggressive, balanced }

class LottoAnalyzer {
  final List<LottoRound> historicalData;
  final Random _random = Random();

  LottoAnalyzer({required this.historicalData});

  /// Hot/Cold 가중치 계산: 최근 출현 빈도 기반
  Map<int, double> calculateHotColdWeights() {
    final weights = <int, double>{};
    for (int i = 1; i <= 45; i++) {
      weights[i] = 0.0;
    }

    final totalRounds = historicalData.length;
    if (totalRounds == 0) return weights;

    for (int idx = 0; idx < totalRounds; idx++) {
      final recencyWeight = pow(0.95, totalRounds - 1 - idx).toDouble();
      for (final num in historicalData[idx].numbers) {
        weights[num] = (weights[num] ?? 0) + recencyWeight;
      }
    }

    // 정규화 (0~1 범위)
    final maxWeight = weights.values.reduce(max);
    final minWeight = weights.values.reduce(min);
    final range = maxWeight - minWeight;

    if (range > 0) {
      for (final key in weights.keys) {
        weights[key] = (weights[key]! - minWeight) / range;
      }
    }

    return weights;
  }

  /// 전략에 따라 가중치 조정
  Map<int, double> _applyStrategy(
    Map<int, double> weights,
    AnalysisStrategy strategy,
  ) {
    final adjusted = Map<int, double>.from(weights);

    switch (strategy) {
      case AnalysisStrategy.conservative:
        // Hot 번호 가중치 2배 부스트
        for (final key in adjusted.keys) {
          if (adjusted[key]! > 0.5) {
            adjusted[key] = adjusted[key]! * 2.0;
          }
        }
      case AnalysisStrategy.aggressive:
        // Cold 번호 가중치 2배 부스트
        for (final key in adjusted.keys) {
          if (adjusted[key]! < 0.5) {
            adjusted[key] = (1.0 - adjusted[key]!) * 2.0;
          }
        }
      case AnalysisStrategy.balanced:
        break; // 기존 로직 유지
    }

    return adjusted;
  }

  bool passesOddEvenFilter(List<int> numbers) {
    final oddCount = numbers.where((n) => n % 2 == 1).length;
    final evenCount = numbers.length - oddCount;
    return (oddCount == 3 && evenCount == 3) ||
        (oddCount == 4 && evenCount == 2) ||
        (oddCount == 2 && evenCount == 4);
  }

  /// 연속 번호 방지: 3개 이상 연속 금지 (2개 연속은 허용)
  bool passesConsecutiveFilter(List<int> numbers) {
    final sorted = List<int>.from(numbers)..sort();
    int consecutiveCount = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i + 1] - sorted[i] == 1) {
        consecutiveCount++;
        if (consecutiveCount >= 3) return false;
      } else {
        consecutiveCount = 1;
      }
    }
    return true;
  }

  int _weightedRandomPick(
    Map<int, double> weights,
    Set<int> excluded,
  ) {
    final available = <int, double>{};
    for (final entry in weights.entries) {
      if (!excluded.contains(entry.key)) {
        available[entry.key] = entry.value + 0.1;
      }
    }

    final totalWeight = available.values.reduce((a, b) => a + b);
    var randomPoint = _random.nextDouble() * totalWeight;

    for (final entry in available.entries) {
      randomPoint -= entry.value;
      if (randomPoint <= 0) {
        return entry.key;
      }
    }

    return available.keys.last;
  }

  /// 전략 기반 번호 6개 생성
  List<int> generateNumbers({
    AnalysisStrategy strategy = AnalysisStrategy.balanced,
    int maxAttempts = 10000,
  }) {
    final baseWeights = calculateHotColdWeights();
    final weights = _applyStrategy(baseWeights, strategy);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final selected = <int>{};

      while (selected.length < 6) {
        final pick = _weightedRandomPick(weights, selected);
        selected.add(pick);
      }

      final numbers = selected.toList()..sort();

      if (!passesOddEvenFilter(numbers)) continue;
      if (!passesConsecutiveFilter(numbers)) continue;

      return numbers;
    }

    return _fallbackGenerate(weights);
  }

  List<int> _fallbackGenerate(Map<int, double> weights) {
    final selected = <int>{};
    while (selected.length < 6) {
      final pick = _weightedRandomPick(weights, selected);
      selected.add(pick);
    }
    return selected.toList()..sort();
  }

  /// 전략별 과거 적중률 시뮬레이션
  Map<AnalysisStrategy, StrategyResult> simulateStrategies({
    int simulations = 500,
  }) {
    final results = <AnalysisStrategy, StrategyResult>{};

    for (final strategy in AnalysisStrategy.values) {
      int totalMatches = 0;
      int threeOrMore = 0;

      for (int i = 0; i < simulations; i++) {
        final generated = generateNumbers(strategy: strategy);

        // 마지막 회차와 비교
        if (historicalData.isNotEmpty) {
          final lastRound = historicalData.last;
          final matches =
              generated.where((n) => lastRound.numbers.contains(n)).length;
          totalMatches += matches;
          if (matches >= 3) threeOrMore++;
        }
      }

      results[strategy] = StrategyResult(
        avgMatches: simulations > 0 ? totalMatches / simulations : 0,
        threeOrMoreRate:
            simulations > 0 ? (threeOrMore / simulations) * 100 : 0,
      );
    }

    return results;
  }

  /// 번호별 출현 빈도 (차트용)
  Map<int, int> getFrequencyMap() {
    final freq = <int, int>{};
    for (int i = 1; i <= 45; i++) {
      freq[i] = 0;
    }
    for (final round in historicalData) {
      for (final num in round.numbers) {
        freq[num] = (freq[num] ?? 0) + 1;
      }
    }
    return freq;
  }

  /// 최근 N회차에서 특정 번호 출현 여부 (추세 차트용)
  List<bool> getNumberTrend(int number, int recentCount) {
    final recent = historicalData.length > recentCount
        ? historicalData.sublist(historicalData.length - recentCount)
        : historicalData;
    return recent.map((r) => r.numbers.contains(number)).toList();
  }

  /// 홀짝 비율 통계
  Map<String, double> getOddEvenRatio() {
    int totalOdd = 0;
    int totalEven = 0;
    for (final round in historicalData) {
      for (final num in round.numbers) {
        if (num % 2 == 1) {
          totalOdd++;
        } else {
          totalEven++;
        }
      }
    }
    final total = totalOdd + totalEven;
    if (total == 0) return {'odd': 50, 'even': 50};
    return {
      'odd': (totalOdd / total) * 100,
      'even': (totalEven / total) * 100,
    };
  }

  List<MapEntry<int, double>> getHotNumbers(int count) {
    final weights = calculateHotColdWeights();
    final sorted = weights.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(count).toList();
  }

  List<MapEntry<int, double>> getColdNumbers(int count) {
    final weights = calculateHotColdWeights();
    final sorted = weights.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return sorted.take(count).toList();
  }
}

class StrategyResult {
  final double avgMatches;
  final double threeOrMoreRate;

  StrategyResult({required this.avgMatches, required this.threeOrMoreRate});
}
