import 'dart:math';
import '../models/lotto_round.dart';

enum AnalysisStrategy { conservative, aggressive, balanced }

class LottoAnalyzer {
  final List<LottoRound> historicalData;
  final Random _random = Random();

  static const List<int> primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43];
  static const List<int> fibonacci = [1, 2, 3, 5, 8, 13, 21, 34];
  static const Map<String, List<int>> colorGroups = {
    'yellow': [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
    'blue': [11, 12, 13, 14, 15, 16, 17, 18, 19, 20],
    'red': [21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
    'gray': [31, 32, 33, 34, 35, 36, 37, 38, 39, 40],
    'green': [41, 42, 43, 44, 45],
  };

  LottoAnalyzer({required this.historicalData});

  // ===== 기존 분석 =====

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

  Map<int, double> _applyStrategy(Map<int, double> weights, AnalysisStrategy strategy) {
    final adjusted = Map<int, double>.from(weights);
    switch (strategy) {
      case AnalysisStrategy.conservative:
        for (final key in adjusted.keys) {
          if (adjusted[key]! > 0.5) adjusted[key] = adjusted[key]! * 2.0;
        }
      case AnalysisStrategy.aggressive:
        for (final key in adjusted.keys) {
          if (adjusted[key]! < 0.5) adjusted[key] = (1.0 - adjusted[key]!) * 2.0;
        }
      case AnalysisStrategy.balanced:
        break;
    }
    return adjusted;
  }

  // ===== 필터들 =====

  /// 1. 홀짝 비율 필터 (3:3 / 4:2 / 2:4)
  bool passesOddEvenFilter(List<int> numbers) {
    final oddCount = numbers.where((n) => n % 2 == 1).length;
    final evenCount = numbers.length - oddCount;
    return (oddCount == 3 && evenCount == 3) ||
        (oddCount == 4 && evenCount == 2) ||
        (oddCount == 2 && evenCount == 4);
  }

  /// 2. 연속 번호 방지 (3연속 금지)
  bool passesConsecutiveFilter(List<int> numbers) {
    final sorted = List<int>.from(numbers)..sort();
    int count = 1;
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i + 1] - sorted[i] == 1) {
        count++;
        if (count >= 3) return false;
      } else {
        count = 1;
      }
    }
    return true;
  }

  /// 3. AC값 필터 (Arithmetic Complexity >= 7)
  int calculateAC(List<int> numbers) {
    final diffs = <int>{};
    for (int i = 0; i < numbers.length; i++) {
      for (int j = i + 1; j < numbers.length; j++) {
        diffs.add((numbers[j] - numbers[i]).abs());
      }
    }
    return diffs.length;
  }

  bool passesACFilter(List<int> numbers) => calculateAC(numbers) >= 7;

  /// 4. 합계 범위 필터 (100~175)
  int sumOfNumbers(List<int> numbers) => numbers.reduce((a, b) => a + b);

  bool passesSumFilter(List<int> numbers) {
    final s = sumOfNumbers(numbers);
    return s >= 100 && s <= 175;
  }

  /// 5. 저고 비율 필터 (저1~22 : 고23~45 = 3:3 or 4:2 or 2:4)
  bool passesLowHighFilter(List<int> numbers) {
    final lowCount = numbers.where((n) => n <= 22).length;
    final highCount = numbers.length - lowCount;
    return (lowCount == 3 && highCount == 3) ||
        (lowCount == 4 && highCount == 2) ||
        (lowCount == 2 && highCount == 4);
  }

  /// 6. 구간별 분포 필터 (5구간 중 최소 3구간 이상 커버)
  int countCoveredSections(List<int> numbers) {
    final sections = <int>{};
    for (final n in numbers) {
      if (n <= 10) sections.add(1);
      else if (n <= 20) sections.add(2);
      else if (n <= 30) sections.add(3);
      else if (n <= 40) sections.add(4);
      else sections.add(5);
    }
    return sections.length;
  }

  bool passesSectionFilter(List<int> numbers) => countCoveredSections(numbers) >= 3;

  /// 7. 끝수 합 필터 (끝자리 합 20~40)
  int endDigitSum(List<int> numbers) {
    return numbers.map((n) => n % 10).reduce((a, b) => a + b);
  }

  bool passesEndDigitSumFilter(List<int> numbers) {
    final s = endDigitSum(numbers);
    return s >= 15 && s <= 35;
  }

  // ===== 통계 분석 메서드들 =====

  /// 번호별 출현 빈도
  Map<int, int> getFrequencyMap() {
    final freq = <int, int>{};
    for (int i = 1; i <= 45; i++) freq[i] = 0;
    for (final round in historicalData) {
      for (final num in round.numbers) {
        freq[num] = (freq[num] ?? 0) + 1;
      }
    }
    return freq;
  }

  /// 최근 N회차 번호 출현 추세
  List<bool> getNumberTrend(int number, int recentCount) {
    final recent = historicalData.length > recentCount
        ? historicalData.sublist(historicalData.length - recentCount)
        : historicalData;
    return recent.map((r) => r.numbers.contains(number)).toList();
  }

  /// 홀짝 비율 통계
  Map<String, double> getOddEvenRatio() {
    int totalOdd = 0, totalEven = 0;
    for (final round in historicalData) {
      for (final num in round.numbers) {
        if (num % 2 == 1) totalOdd++; else totalEven++;
      }
    }
    final total = totalOdd + totalEven;
    if (total == 0) return {'odd': 50, 'even': 50};
    return {'odd': (totalOdd / total) * 100, 'even': (totalEven / total) * 100};
  }

  /// 8. 끝수(0~9) 분포 분석
  Map<int, int> getEndDigitDistribution() {
    final dist = <int, int>{};
    for (int i = 0; i <= 9; i++) dist[i] = 0;
    for (final round in historicalData) {
      for (final num in round.numbers) {
        dist[num % 10] = (dist[num % 10] ?? 0) + 1;
      }
    }
    return dist;
  }

  /// 9. 소수 포함 비율 분석
  Map<String, double> getPrimeRatio() {
    int primeCount = 0, totalCount = 0;
    for (final round in historicalData) {
      for (final num in round.numbers) {
        totalCount++;
        if (primes.contains(num)) primeCount++;
      }
    }
    if (totalCount == 0) return {'prime': 0, 'nonPrime': 100};
    return {
      'prime': (primeCount / totalCount) * 100,
      'nonPrime': ((totalCount - primeCount) / totalCount) * 100,
    };
  }

  /// 10. 3의 배수 분석
  Map<String, double> getMultipleOf3Ratio() {
    int mul3 = 0, total = 0;
    for (final round in historicalData) {
      for (final num in round.numbers) {
        total++;
        if (num % 3 == 0) mul3++;
      }
    }
    if (total == 0) return {'mul3': 0, 'other': 100};
    return {
      'mul3': (mul3 / total) * 100,
      'other': ((total - mul3) / total) * 100,
    };
  }

  /// 11. 저고 비율 통계
  Map<String, double> getLowHighRatio() {
    int low = 0, high = 0;
    for (final round in historicalData) {
      for (final num in round.numbers) {
        if (num <= 22) low++; else high++;
      }
    }
    final total = low + high;
    if (total == 0) return {'low': 50, 'high': 50};
    return {'low': (low / total) * 100, 'high': (high / total) * 100};
  }

  /// 12. 구간별(1-10,11-20,21-30,31-40,41-45) 출현 빈도
  Map<String, int> getSectionDistribution() {
    final sections = {'1-10': 0, '11-20': 0, '21-30': 0, '31-40': 0, '41-45': 0};
    for (final round in historicalData) {
      for (final n in round.numbers) {
        if (n <= 10) sections['1-10'] = sections['1-10']! + 1;
        else if (n <= 20) sections['11-20'] = sections['11-20']! + 1;
        else if (n <= 30) sections['21-30'] = sections['21-30']! + 1;
        else if (n <= 40) sections['31-40'] = sections['31-40']! + 1;
        else sections['41-45'] = sections['41-45']! + 1;
      }
    }
    return sections;
  }

  /// 13. 이월수 분석 - 이전 회차에서 반복 출현한 번호 통계
  Map<String, double> getCarryOverStats() {
    if (historicalData.length < 2) return {'avg': 0, 'maxRate': 0};
    int totalCarry = 0;
    int pairs = 0;
    for (int i = 1; i < historicalData.length; i++) {
      final prev = historicalData[i - 1].numbers;
      final curr = historicalData[i].numbers;
      totalCarry += curr.where((n) => prev.contains(n)).length;
      pairs++;
    }
    return {
      'avg': pairs > 0 ? totalCarry / pairs : 0,
      'total': totalCarry.toDouble(),
    };
  }

  /// 14. 동반출현 분석 - 가장 자주 함께 나오는 번호 쌍 Top N
  List<MapEntry<String, int>> getCoOccurrencePairs(int topN) {
    final pairCount = <String, int>{};
    for (final round in historicalData) {
      final nums = round.numbers;
      for (int i = 0; i < nums.length; i++) {
        for (int j = i + 1; j < nums.length; j++) {
          final key = '${nums[i]}-${nums[j]}';
          pairCount[key] = (pairCount[key] ?? 0) + 1;
        }
      }
    }
    final sorted = pairCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(topN).toList();
  }

  /// 15. 미출현 기간 분석 - 각 번호가 마지막으로 나온 후 경과 회차
  Map<int, int> getAbsencePeriod() {
    final lastSeen = <int, int>{};
    for (int i = 1; i <= 45; i++) lastSeen[i] = historicalData.length;

    for (int i = historicalData.length - 1; i >= 0; i--) {
      for (final num in historicalData[i].numbers) {
        if (lastSeen[num] == historicalData.length) {
          lastSeen[num] = historicalData.length - 1 - i;
        }
      }
    }
    return lastSeen;
  }

  /// 16. 번호 간격 패턴 분석
  Map<int, int> getGapDistribution() {
    final gaps = <int, int>{};
    for (final round in historicalData) {
      final sorted = List<int>.from(round.numbers)..sort();
      for (int i = 0; i < sorted.length - 1; i++) {
        final gap = sorted[i + 1] - sorted[i];
        gaps[gap] = (gaps[gap] ?? 0) + 1;
      }
    }
    return gaps;
  }

  /// 17. 색상별 분석 (노/파/빨/회/초)
  Map<String, int> getColorDistribution() {
    final colors = <String, int>{};
    for (final entry in colorGroups.entries) {
      colors[entry.key] = 0;
    }
    for (final round in historicalData) {
      for (final num in round.numbers) {
        for (final entry in colorGroups.entries) {
          if (entry.value.contains(num)) {
            colors[entry.key] = (colors[entry.key] ?? 0) + 1;
          }
        }
      }
    }
    return colors;
  }

  /// 18. 쌍수 분석 - 같은 십의자리 번호 쌍 빈도
  Map<String, int> getTwinNumberStats() {
    final twins = <String, int>{};
    for (final round in historicalData) {
      final decades = <int, List<int>>{};
      for (final n in round.numbers) {
        final decade = n ~/ 10;
        decades.putIfAbsent(decade, () => []).add(n);
      }
      for (final entry in decades.entries) {
        if (entry.value.length >= 2) {
          final key = '${entry.key}0대';
          twins[key] = (twins[key] ?? 0) + 1;
        }
      }
    }
    return twins;
  }

  /// 19. 골든존 분석 - 출현 빈도 상위 10개 번호
  List<MapEntry<int, int>> getGoldenZone() {
    final freq = getFrequencyMap();
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  /// 20. 피보나치 수 포함 비율
  Map<String, double> getFibonacciRatio() {
    int fibCount = 0, total = 0;
    for (final round in historicalData) {
      for (final num in round.numbers) {
        total++;
        if (fibonacci.contains(num)) fibCount++;
      }
    }
    if (total == 0) return {'fib': 0, 'nonFib': 100};
    return {
      'fib': (fibCount / total) * 100,
      'nonFib': ((total - fibCount) / total) * 100,
    };
  }

  /// 21. 대칭수 분석 - 합이 46이 되는 쌍 포함 빈도
  Map<String, double> getSymmetryStats() {
    int withSymmetry = 0;
    for (final round in historicalData) {
      bool hasSymmetry = false;
      for (int i = 0; i < round.numbers.length && !hasSymmetry; i++) {
        for (int j = i + 1; j < round.numbers.length; j++) {
          if (round.numbers[i] + round.numbers[j] == 46) {
            hasSymmetry = true;
            break;
          }
        }
      }
      if (hasSymmetry) withSymmetry++;
    }
    final total = historicalData.length;
    if (total == 0) return {'rate': 0};
    return {'rate': (withSymmetry / total) * 100};
  }

  /// 22. 미출현 후 출현 분석 - N회 이상 안 나오다 나온 번호들
  List<MapEntry<int, int>> getLongAbsenceThenAppeared(int minAbsence) {
    final result = <MapEntry<int, int>>[];
    for (int num = 1; num <= 45; num++) {
      int absence = 0;
      int maxAbsence = 0;
      for (final round in historicalData) {
        if (round.numbers.contains(num)) {
          if (absence >= minAbsence) {
            maxAbsence = max(maxAbsence, absence);
          }
          absence = 0;
        } else {
          absence++;
        }
      }
      if (maxAbsence > 0) result.add(MapEntry(num, maxAbsence));
    }
    result.sort((a, b) => b.value.compareTo(a.value));
    return result.take(10).toList();
  }

  /// 23. 회차별 번호합 추세 (최근 N회)
  List<int> getSumTrend(int recentCount) {
    final recent = historicalData.length > recentCount
        ? historicalData.sublist(historicalData.length - recentCount)
        : historicalData;
    return recent.map((r) => r.numbers.reduce((a, b) => a + b)).toList();
  }

  /// 24. 궁합수 분석 - 특정 번호가 나올 때 함께 나올 확률 높은 번호
  Map<int, double> getCompatibleNumbers(int targetNumber) {
    final coCount = <int, int>{};
    int targetAppearances = 0;

    for (final round in historicalData) {
      if (round.numbers.contains(targetNumber)) {
        targetAppearances++;
        for (final num in round.numbers) {
          if (num != targetNumber) {
            coCount[num] = (coCount[num] ?? 0) + 1;
          }
        }
      }
    }

    final result = <int, double>{};
    if (targetAppearances > 0) {
      for (final entry in coCount.entries) {
        result[entry.key] = (entry.value / targetAppearances) * 100;
      }
    }
    return result;
  }

  /// AC값 분포 통계
  Map<int, int> getACDistribution() {
    final dist = <int, int>{};
    for (final round in historicalData) {
      final ac = calculateAC(round.numbers);
      dist[ac] = (dist[ac] ?? 0) + 1;
    }
    return dist;
  }

  /// 합계 분포 통계
  Map<String, int> getSumRangeDistribution() {
    final ranges = <String, int>{
      '~99': 0, '100~124': 0, '125~149': 0, '150~175': 0, '176~': 0,
    };
    for (final round in historicalData) {
      final s = round.numbers.reduce((a, b) => a + b);
      if (s < 100) ranges['~99'] = ranges['~99']! + 1;
      else if (s <= 124) ranges['100~124'] = ranges['100~124']! + 1;
      else if (s <= 149) ranges['125~149'] = ranges['125~149']! + 1;
      else if (s <= 175) ranges['150~175'] = ranges['150~175']! + 1;
      else ranges['176~'] = ranges['176~']! + 1;
    }
    return ranges;
  }

  // ===== Hot/Cold =====

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

  // ===== 번호 생성 (모든 필터 통합) =====

  int _weightedRandomPick(Map<int, double> weights, Set<int> excluded) {
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
      if (randomPoint <= 0) return entry.key;
    }
    return available.keys.last;
  }

  List<int> generateNumbers({
    AnalysisStrategy strategy = AnalysisStrategy.balanced,
    int maxAttempts = 10000,
  }) {
    final baseWeights = calculateHotColdWeights();
    final weights = _applyStrategy(baseWeights, strategy);

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final selected = <int>{};
      while (selected.length < 6) {
        selected.add(_weightedRandomPick(weights, selected));
      }
      final numbers = selected.toList()..sort();

      if (!passesOddEvenFilter(numbers)) continue;
      if (!passesConsecutiveFilter(numbers)) continue;
      if (!passesACFilter(numbers)) continue;
      if (!passesSumFilter(numbers)) continue;
      if (!passesLowHighFilter(numbers)) continue;
      if (!passesSectionFilter(numbers)) continue;

      return numbers;
    }

    return _fallbackGenerate(weights);
  }

  List<int> _fallbackGenerate(Map<int, double> weights) {
    final selected = <int>{};
    while (selected.length < 6) {
      selected.add(_weightedRandomPick(weights, selected));
    }
    return selected.toList()..sort();
  }

  Map<AnalysisStrategy, StrategyResult> simulateStrategies({int simulations = 200}) {
    final results = <AnalysisStrategy, StrategyResult>{};
    for (final strategy in AnalysisStrategy.values) {
      int totalMatches = 0, threeOrMore = 0;
      for (int i = 0; i < simulations; i++) {
        final generated = generateNumbers(strategy: strategy);
        if (historicalData.isNotEmpty) {
          final matches = generated.where((n) => historicalData.last.numbers.contains(n)).length;
          totalMatches += matches;
          if (matches >= 3) threeOrMore++;
        }
      }
      results[strategy] = StrategyResult(
        avgMatches: simulations > 0 ? totalMatches / simulations : 0,
        threeOrMoreRate: simulations > 0 ? (threeOrMore / simulations) * 100 : 0,
      );
    }
    return results;
  }
}

class StrategyResult {
  final double avgMatches;
  final double threeOrMoreRate;
  StrategyResult({required this.avgMatches, required this.threeOrMoreRate});
}
