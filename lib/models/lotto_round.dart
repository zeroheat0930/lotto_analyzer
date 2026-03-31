class LottoRound {
  final int round;
  final List<int> numbers;
  final int bonusNumber;
  final String drawDate;

  LottoRound({
    required this.round,
    required this.numbers,
    required this.bonusNumber,
    required this.drawDate,
  });

  factory LottoRound.fromJson(Map<String, dynamic> json) {
    return LottoRound(
      round: json['drwNo'] as int,
      numbers: [
        json['drwtNo1'] as int,
        json['drwtNo2'] as int,
        json['drwtNo3'] as int,
        json['drwtNo4'] as int,
        json['drwtNo5'] as int,
        json['drwtNo6'] as int,
      ],
      bonusNumber: json['bnusNo'] as int,
      drawDate: json['drwNoDate'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'round': round,
      'num1': numbers[0],
      'num2': numbers[1],
      'num3': numbers[2],
      'num4': numbers[3],
      'num5': numbers[4],
      'num6': numbers[5],
      'bonus': bonusNumber,
      'drawDate': drawDate,
    };
  }

  factory LottoRound.fromMap(Map<String, dynamic> map) {
    return LottoRound(
      round: map['round'] as int,
      numbers: [
        map['num1'] as int,
        map['num2'] as int,
        map['num3'] as int,
        map['num4'] as int,
        map['num5'] as int,
        map['num6'] as int,
      ],
      bonusNumber: map['bonus'] as int,
      drawDate: map['drawDate'] as String,
    );
  }
}
