import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/lotto_round.dart';

class LottoApiService {
  static const String _baseUrl =
      'https://www.dhlottery.co.kr/common.do?method=getLottoNumber';

  Future<LottoRound?> fetchRound(int round) async {
    final response = await http.get(
      Uri.parse('$_baseUrl&drwNo=$round'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['returnValue'] == 'success') {
        return LottoRound.fromJson(data);
      }
    }
    return null;
  }

  Future<LottoRound?> fetchLatestRound() async {
    // 최신 회차를 이진 탐색으로 찾기
    int low = 1;
    int high = 3000;
    int latestRound = 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      try {
        final result = await fetchRound(mid);
        if (result != null) {
          latestRound = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      } catch (_) {
        high = mid - 1;
      }
    }

    return fetchRound(latestRound);
  }

  Future<int> findLatestRoundNumber() async {
    int low = 1;
    int high = 3000;
    int latestRound = 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      try {
        final result = await fetchRound(mid);
        if (result != null) {
          latestRound = mid;
          low = mid + 1;
        } else {
          high = mid - 1;
        }
      } catch (_) {
        high = mid - 1;
      }
    }

    return latestRound;
  }

  Future<List<LottoRound>> fetchMultipleRounds({
    required int from,
    required int to,
  }) async {
    final rounds = <LottoRound>[];
    for (int i = from; i <= to; i++) {
      final round = await fetchRound(i);
      if (round != null) {
        rounds.add(round);
      }
    }
    return rounds;
  }

  Future<List<LottoRound>> fetchRecentRounds(int count) async {
    final latestRound = await findLatestRoundNumber();
    final startRound = (latestRound - count + 1).clamp(1, latestRound);
    return fetchMultipleRounds(from: startRound, to: latestRound);
  }
}
