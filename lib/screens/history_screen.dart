import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lotto_provider.dart';
import '../services/database_service.dart';
import '../widgets/lotto_ball.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

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
        child: Consumer<LottoProvider>(
          builder: (context, provider, _) {
            final saved = provider.savedNumbers;

            if (saved.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: const Color(0xFFDAA520).withAlpha(80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '저장된 번호가 없습니다',
                      style: TextStyle(
                        color: Colors.white.withAlpha(120),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '홈에서 번호를 생성하고 저장해보세요',
                      style: TextStyle(
                        color: Colors.white.withAlpha(80),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Text(
                        '저장된 번호',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFFD700),
                          letterSpacing: 1,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${saved.length}개',
                        style: TextStyle(
                          color: Colors.white.withAlpha(120),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: saved.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryItem(context, saved[index], provider);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    SavedNumbers item,
    LottoProvider provider,
  ) {
    final strategyLabel = switch (item.strategy) {
      'conservative' => '보수적',
      'aggressive' => '공격적',
      'balanced' => '밸런스',
      'neural' => 'AI 신경망',
      _ => item.strategy,
    };

    final date = DateTime.tryParse(item.createdAt);
    final dateStr = date != null
        ? '${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}'
        : item.createdAt;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withAlpha(8),
        border: Border.all(
          color: item.checked == true
              ? (item.matchCount != null && item.matchCount! >= 3
                  ? const Color(0xFFFFD700).withAlpha(80)
                  : Colors.white.withAlpha(15))
              : Colors.white.withAlpha(15),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFDAA520).withAlpha(30),
                ),
                child: Text(
                  strategyLabel,
                  style: const TextStyle(
                    color: Color(0xFFDAA520),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateStr,
                style: TextStyle(
                  color: Colors.white.withAlpha(80),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              if (item.checked == true && item.matchCount != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: item.matchCount! >= 3
                        ? const Color(0xFFFFD700).withAlpha(30)
                        : Colors.white.withAlpha(10),
                  ),
                  child: Text(
                    '${item.matchCount}개 일치',
                    style: TextStyle(
                      color: item.matchCount! >= 3
                          ? const Color(0xFFFFD700)
                          : Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Colors.white.withAlpha(60),
                  size: 18,
                ),
                onPressed: () {
                  if (item.id != null) {
                    provider.deleteNumber(item.id!);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: item.numbers.map((number) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: LottoBall(number: number, size: 38),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
