import 'package:flutter/foundation.dart';
import '../models/lotto_round.dart';
import '../services/lotto_api_service.dart';
import '../services/lotto_analyzer.dart';
import '../services/lotto_neural_predictor.dart';
import '../services/database_service.dart';

class LottoProvider extends ChangeNotifier {
  final LottoApiService _apiService = LottoApiService();
  final LottoNeuralPredictor _neuralPredictor = LottoNeuralPredictor();
  final DatabaseService _dbService = DatabaseService();

  List<int> _generatedNumbers = [];
  List<LottoRound> _historicalData = [];
  List<SavedNumbers> _savedNumbers = [];
  bool _isLoading = false;
  bool _isDataLoaded = false;
  bool _useNeural = false;
  String _statusMessage = '번호를 생성하려면 버튼을 누르세요';
  int _latestRound = 0;
  AnalysisStrategy _strategy = AnalysisStrategy.balanced;

  List<int> get generatedNumbers => _generatedNumbers;
  List<LottoRound> get historicalData => _historicalData;
  List<SavedNumbers> get savedNumbers => _savedNumbers;
  bool get isLoading => _isLoading;
  bool get isDataLoaded => _isDataLoaded;
  bool get useNeural => _useNeural;
  String get statusMessage => _statusMessage;
  int get latestRound => _latestRound;
  AnalysisStrategy get strategy => _strategy;

  Future<void> loadHistoricalData() async {
    _isLoading = true;
    _statusMessage = '역대 당첨 데이터 로딩 중...';
    notifyListeners();

    try {
      _historicalData = await _apiService.loadData();
      if (_historicalData.isNotEmpty) {
        _latestRound = _historicalData.last.round;
      }

      // 신경망 학습
      _statusMessage = 'AI 신경망 학습 중...';
      notifyListeners();
      _neuralPredictor.train(_historicalData, epochs: 50);

      // 저장된 번호 로드
      _savedNumbers = await _dbService.getSavedNumbers();

      _isDataLoaded = true;
      _statusMessage =
          '최근 ${_historicalData.length}회차 데이터 로드 완료 (제$_latestRound회)';
    } catch (e) {
      _statusMessage = '데이터 로딩 실패: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void setStrategy(AnalysisStrategy strategy) {
    _strategy = strategy;
    notifyListeners();
  }

  void toggleNeural() {
    _useNeural = !_useNeural;
    notifyListeners();
  }

  void generateNumbers() {
    if (!_isDataLoaded || _historicalData.isEmpty) {
      _statusMessage = '먼저 데이터를 로드해주세요';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _statusMessage = _useNeural ? 'AI 신경망 예측 중...' : 'AI 분석 중...';
    notifyListeners();

    if (_useNeural && _neuralPredictor.isTrained) {
      _generatedNumbers =
          _neuralPredictor.predict(_historicalData.last.numbers);
      _statusMessage = 'AI 신경망 예측 완료';
    } else {
      final analyzer = LottoAnalyzer(historicalData: _historicalData);
      _generatedNumbers = analyzer.generateNumbers(strategy: _strategy);
      final strategyName = switch (_strategy) {
        AnalysisStrategy.conservative => '보수적',
        AnalysisStrategy.aggressive => '공격적',
        AnalysisStrategy.balanced => '밸런스',
      };
      _statusMessage = '$strategyName 전략 + 필터 적용 완료';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveCurrentNumbers() async {
    if (_generatedNumbers.isEmpty) return;

    await _dbService.saveNumbers(_generatedNumbers, _strategy);
    _savedNumbers = await _dbService.getSavedNumbers();
    notifyListeners();
  }

  Future<void> deleteNumber(int id) async {
    await _dbService.deleteNumber(id);
    _savedNumbers = await _dbService.getSavedNumbers();
    notifyListeners();
  }

  Future<void> checkAllWinning() async {
    if (_historicalData.isEmpty) return;
    await _dbService.checkAllAgainstRound(_historicalData.last);
    _savedNumbers = await _dbService.getSavedNumbers();
    notifyListeners();
  }
}
