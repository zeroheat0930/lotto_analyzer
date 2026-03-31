import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/lotto_round.dart';
import 'lotto_sample_data.dart';

class LottoApiService {
  static const String _apiBase =
      'https://www.dhlottery.co.kr/common.do?method=getLottoNumber';
  static const String _corsProxy = 'https://corsproxy.io/?';

  String _buildUrl(int round) {
    final original = '$_apiBase&drwNo=$round';
    if (kIsWeb) {
      return '$_corsProxy${Uri.encodeComponent(original)}';
    }
    return original;
  }

  Future<LottoRound?> fetchRound(int round) async {
    try {
      final url = _buildUrl(round);
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty || body.startsWith('<') || body.startsWith('{"error')) {
          return null;
        }
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['returnValue'] == 'success') {
          return LottoRound.fromJson(data);
        }
      }
    } catch (_) {
      // 타임아웃, 네트워크 오류 등 무시 → fallback 사용
    }
    return null;
  }

  /// API 먼저 시도, 실패 시 내장 샘플 데이터 반환
  Future<List<LottoRound>> loadData() async {
    // 1차: API 시도 (최근 1회차만 테스트)
    final testRound = await fetchRound(1154);
    if (testRound != null) {
      // API 동작 → 최근 50회차 가져오기
      return _fetchFromApi();
    }

    // 2차: API 실패 → 내장 샘플 데이터 사용
    return LottoSampleData.getSampleData();
  }

  Future<List<LottoRound>> _fetchFromApi() async {
    final latestRound = await _findLatestRoundNumber();
    final startRound = (latestRound - 49).clamp(1, latestRound);

    final rounds = <LottoRound>[];
    for (int i = startRound; i <= latestRound; i += 5) {
      final end = (i + 4).clamp(i, latestRound);
      final futures = <Future<LottoRound?>>[];
      for (int j = i; j <= end; j++) {
        futures.add(fetchRound(j));
      }
      final results = await Future.wait(futures);
      for (final r in results) {
        if (r != null) rounds.add(r);
      }
    }

    if (rounds.isEmpty) return LottoSampleData.getSampleData();

    rounds.sort((a, b) => a.round.compareTo(b.round));
    return rounds;
  }

  Future<int> _findLatestRoundNumber() async {
    final firstDraw = DateTime(2002, 12, 7);
    final now = DateTime.now();
    final days = now.difference(firstDraw).inDays;
    var estimated = (days / 7).floor();

    for (int i = estimated; i > estimated - 5; i--) {
      try {
        final result = await fetchRound(i);
        if (result != null) return i;
      } catch (_) {
        continue;
      }
    }
    return estimated - 3;
  }
}
