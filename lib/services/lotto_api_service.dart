import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../models/lotto_round.dart';
import 'lotto_sample_data.dart';

/// 데이터 로딩 우선순위:
/// 1. smok95/lotto GitHub Pages 미러 (전체 회차, 매주 자동 갱신, 안정적)
/// 2. 동행복권 직접 호출 (사용자 폰에서 IP 차단 안 되면 동작)
/// 3. 내장 sample data (오프라인 fallback, 1~1221회차)
class LottoApiService {
  static const String _dhBase =
      'https://www.dhlottery.co.kr/common.do?method=getLottoNumber';
  static const String _corsProxy = 'https://corsproxy.io/?';

  // smok95/lotto — GitHub Actions로 매주 자동 갱신되는 한국 로또 JSON 미러
  static const String _mirrorAll =
      'https://smok95.github.io/lotto/results/all.json';
  static const String _mirrorLatest =
      'https://smok95.github.io/lotto/results/latest.json';

  String _buildDhUrl(int round) {
    final original = '$_dhBase&drwNo=$round';
    if (kIsWeb) {
      return '$_corsProxy${Uri.encodeComponent(original)}';
    }
    return original;
  }

  Future<LottoRound?> fetchRound(int round) async {
    try {
      final url = _buildDhUrl(round);
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = response.body.trim();
        if (body.isEmpty ||
            body.startsWith('<') ||
            body.startsWith('{"error')) {
          return null;
        }
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['returnValue'] == 'success') {
          return LottoRound.fromJson(data);
        }
      }
    } catch (_) {
      // 타임아웃, 네트워크 오류 → fallback 으로 진행
    }
    return null;
  }

  /// 첫 추첨(2002-12-07, 토) 기준 동적 최신 회차 추정.
  int _estimateLatestRound() {
    final firstDraw = DateTime(2002, 12, 7);
    final now = DateTime.now();
    final days = now.difference(firstDraw).inDays;
    var weeks = (days / 7).floor() + 1; // 1회차 = 2002-12-07 토요일 자체
    // 추첨 당일(토) 21시 전이면 아직 미발표 → 한 회차 빼기
    if (now.weekday == DateTime.saturday && now.hour < 21) {
      weeks -= 1;
    }
    return weeks.clamp(1, 99999);
  }

  /// 메인 진입점.
  Future<List<LottoRound>> loadData() async {
    // ① 미러 (smok95 GitHub Pages) 우선 — 안정적 + 자동 갱신
    final mirror = await _fetchFromMirror();
    if (mirror.isNotEmpty) return mirror;

    // ② 동행복권 직접 — 사용자 폰에서 IP 차단 안 되면 동작
    final estimated = _estimateLatestRound();
    for (int probe = estimated; probe > estimated - 3; probe--) {
      final r = await fetchRound(probe);
      if (r != null) {
        final api = await _fetchRecentFromDh(r.round);
        if (api.isNotEmpty) return api;
        break;
      }
    }

    // ③ 내장 sample data
    return LottoSampleData.getSampleData();
  }

  /// 동행복권 직접 — 최근 50 회차 병렬 fetch.
  Future<List<LottoRound>> _fetchRecentFromDh(int latestRound) async {
    final startRound = (latestRound - 49).clamp(1, latestRound);
    final rounds = <LottoRound>[];
    for (int i = startRound; i <= latestRound; i += 5) {
      final end = (i + 4).clamp(i, latestRound);
      final futures = <Future<LottoRound?>>[
        for (int j = i; j <= end; j++) fetchRound(j),
      ];
      final results = await Future.wait(futures);
      for (final r in results) {
        if (r != null) rounds.add(r);
      }
    }
    rounds.sort((a, b) => a.round.compareTo(b.round));
    return rounds;
  }

  /// smok95 미러 — 전체 회차 한 번에 fetch.
  Future<List<LottoRound>> _fetchFromMirror() async {
    try {
      final response = await http
          .get(Uri.parse(_mirrorAll))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return const [];

      final list = jsonDecode(response.body) as List<dynamic>;
      final rounds = <LottoRound>[];
      for (final item in list) {
        final m = item as Map<String, dynamic>;
        final rawNumbers = (m['numbers'] as List).cast<int>();
        if (rawNumbers.length != 6) continue;
        final dateRaw = m['date'] as String;
        rounds.add(LottoRound(
          round: m['draw_no'] as int,
          numbers: rawNumbers,
          bonusNumber: m['bonus_no'] as int,
          drawDate: dateRaw.split('T').first, // ISO → "YYYY-MM-DD"
        ));
      }
      rounds.sort((a, b) => a.round.compareTo(b.round));
      return rounds;
    } catch (_) {
      return const [];
    }
  }

  /// 미러의 최신 1회차만 빠르게 가져오기 (가벼운 ping 용도).
  Future<LottoRound?> fetchLatestFromMirror() async {
    try {
      final response = await http
          .get(Uri.parse(_mirrorLatest))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return null;
      final m = jsonDecode(response.body) as Map<String, dynamic>;
      final nums = (m['numbers'] as List).cast<int>();
      if (nums.length != 6) return null;
      return LottoRound(
        round: m['draw_no'] as int,
        numbers: nums,
        bonusNumber: m['bonus_no'] as int,
        drawDate: (m['date'] as String).split('T').first,
      );
    } catch (_) {
      return null;
    }
  }
}
