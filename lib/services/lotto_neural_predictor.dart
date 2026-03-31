import 'dart:math';
import '../models/lotto_round.dart';

/// 순수 Dart 기반 간이 Feedforward 신경망 로또 번호 예측기
class LottoNeuralPredictor {
  static const int _inputSize = 45; // 1~45 번호 원핫 인코딩
  static const int _hiddenSize = 30;
  static const int _outputSize = 45;
  static const double _learningRate = 0.01;

  late List<List<double>> _weightsIH; // 입력 → 은닉
  late List<double> _biasH;
  late List<List<double>> _weightsHO; // 은닉 → 출력
  late List<double> _biasO;
  final Random _random = Random();

  bool _isTrained = false;
  bool get isTrained => _isTrained;

  LottoNeuralPredictor() {
    _initializeWeights();
  }

  void _initializeWeights() {
    // Xavier 초기화
    final ihScale = sqrt(2.0 / (_inputSize + _hiddenSize));
    final hoScale = sqrt(2.0 / (_hiddenSize + _outputSize));

    _weightsIH = List.generate(
      _inputSize,
      (_) => List.generate(
        _hiddenSize,
        (_) => (_random.nextDouble() * 2 - 1) * ihScale,
      ),
    );
    _biasH = List.filled(_hiddenSize, 0.0);

    _weightsHO = List.generate(
      _hiddenSize,
      (_) => List.generate(
        _outputSize,
        (_) => (_random.nextDouble() * 2 - 1) * hoScale,
      ),
    );
    _biasO = List.filled(_outputSize, 0.0);
  }

  double _sigmoid(double x) => 1.0 / (1.0 + exp(-x.clamp(-10, 10)));

  double _sigmoidDerivative(double x) => x * (1.0 - x);

  /// 순전파
  List<double> _forward(List<double> input) {
    // 은닉층
    final hidden = List<double>.filled(_hiddenSize, 0.0);
    for (int j = 0; j < _hiddenSize; j++) {
      double sum = _biasH[j];
      for (int i = 0; i < _inputSize; i++) {
        sum += input[i] * _weightsIH[i][j];
      }
      hidden[j] = _sigmoid(sum);
    }

    // 출력층
    final output = List<double>.filled(_outputSize, 0.0);
    for (int k = 0; k < _outputSize; k++) {
      double sum = _biasO[k];
      for (int j = 0; j < _hiddenSize; j++) {
        sum += hidden[j] * _weightsHO[j][k];
      }
      output[k] = _sigmoid(sum);
    }

    return output;
  }

  /// 역전파 학습
  void _backpropagate(List<double> input, List<double> target) {
    // 순전파 (중간값 저장)
    final hidden = List<double>.filled(_hiddenSize, 0.0);
    for (int j = 0; j < _hiddenSize; j++) {
      double sum = _biasH[j];
      for (int i = 0; i < _inputSize; i++) {
        sum += input[i] * _weightsIH[i][j];
      }
      hidden[j] = _sigmoid(sum);
    }

    final output = List<double>.filled(_outputSize, 0.0);
    for (int k = 0; k < _outputSize; k++) {
      double sum = _biasO[k];
      for (int j = 0; j < _hiddenSize; j++) {
        sum += hidden[j] * _weightsHO[j][k];
      }
      output[k] = _sigmoid(sum);
    }

    // 출력층 오차
    final outputErrors = List<double>.filled(_outputSize, 0.0);
    for (int k = 0; k < _outputSize; k++) {
      outputErrors[k] =
          (target[k] - output[k]) * _sigmoidDerivative(output[k]);
    }

    // 은닉층 오차
    final hiddenErrors = List<double>.filled(_hiddenSize, 0.0);
    for (int j = 0; j < _hiddenSize; j++) {
      double error = 0.0;
      for (int k = 0; k < _outputSize; k++) {
        error += outputErrors[k] * _weightsHO[j][k];
      }
      hiddenErrors[j] = error * _sigmoidDerivative(hidden[j]);
    }

    // 가중치 업데이트 (은닉 → 출력)
    for (int j = 0; j < _hiddenSize; j++) {
      for (int k = 0; k < _outputSize; k++) {
        _weightsHO[j][k] += _learningRate * outputErrors[k] * hidden[j];
      }
    }
    for (int k = 0; k < _outputSize; k++) {
      _biasO[k] += _learningRate * outputErrors[k];
    }

    // 가중치 업데이트 (입력 → 은닉)
    for (int i = 0; i < _inputSize; i++) {
      for (int j = 0; j < _hiddenSize; j++) {
        _weightsIH[i][j] += _learningRate * hiddenErrors[j] * input[i];
      }
    }
    for (int j = 0; j < _hiddenSize; j++) {
      _biasH[j] += _learningRate * hiddenErrors[j];
    }
  }

  /// 로또 번호를 원핫 인코딩으로 변환
  List<double> _numbersToOneHot(List<int> numbers) {
    final oneHot = List<double>.filled(_inputSize, 0.0);
    for (final n in numbers) {
      if (n >= 1 && n <= 45) {
        oneHot[n - 1] = 1.0;
      }
    }
    return oneHot;
  }

  /// 역대 당첨 데이터로 학습
  void train(List<LottoRound> data, {int epochs = 100}) {
    if (data.length < 2) return;

    for (int epoch = 0; epoch < epochs; epoch++) {
      for (int i = 0; i < data.length - 1; i++) {
        final input = _numbersToOneHot(data[i].numbers);
        final target = _numbersToOneHot(data[i + 1].numbers);
        _backpropagate(input, target);
      }
    }
    _isTrained = true;
  }

  /// 다음 회차 번호 예측
  List<int> predict(List<int> lastNumbers) {
    final input = _numbersToOneHot(lastNumbers);
    final output = _forward(input);

    // 출력값 상위 6개 인덱스 선택
    final indexed = <MapEntry<int, double>>[];
    for (int i = 0; i < output.length; i++) {
      indexed.add(MapEntry(i + 1, output[i])); // 1-indexed
    }
    indexed.sort((a, b) => b.value.compareTo(a.value));

    final predicted = indexed.take(6).map((e) => e.key).toList()..sort();
    return predicted;
  }
}
