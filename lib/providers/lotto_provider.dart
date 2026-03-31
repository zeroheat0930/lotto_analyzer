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
  bool _numbersSaved = false;
  String _statusMessage = '번호를 생성하려면 버튼을 누르세요';
  int _latestRound = 0;
  AnalysisStrategy _strategy = AnalysisStrategy.balanced;
  int _analysisRange = 0; // 0 = 전체

  List<int> get generatedNumbers => _generatedNumbers;
  List<LottoRound> get historicalData => _historicalData;
  List<SavedNumbers> get savedNumbers => _savedNumbers;
  bool get isLoading => _isLoading;
  bool get isDataLoaded => _isDataLoaded;
  bool get useNeural => _useNeural;
  bool get numbersSaved => _numbersSaved;
  String get statusMessage => _statusMessage;
  int get latestRound => _latestRound;
  AnalysisStrategy get strategy => _strategy;
  int get analysisRange => _analysisRange;

  /// 분석 범위에 맞는 데이터 반환
  List<LottoRound> get filteredData {
    if (_analysisRange == 0 || _analysisRange >= _historicalData.length) {
      return _historicalData;
    }
    return _historicalData.sublist(_historicalData.length - _analysisRange);
  }

  /// 다음 추첨일 (토요일)
  DateTime get nextDrawDate {
    var now = DateTime.now();
    var daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
    if (daysUntilSaturday == 0 && now.hour >= 21) daysUntilSaturday = 7;
    if (daysUntilSaturday == 0 && now.hour < 21) daysUntilSaturday = 0;
    return DateTime(now.year, now.month, now.day + daysUntilSaturday);
  }

  /// 다음 추첨 회차
  int get nextDrawRound => _latestRound + 1;

  void setAnalysisRange(int range) {
    _analysisRange = range;
    notifyListeners();
  }

  Future<void> loadHistoricalData() async {
    _isLoading = true;
    _statusMessage = '역대 당첨 데이터 로딩 중...';
    notifyListeners();

    try {
      _historicalData = await _apiService.loadData();
      if (_historicalData.isNotEmpty) {
        _latestRound = _historicalData.last.round;
      }

      _statusMessage = 'AI 신경망 학습 중...';
      notifyListeners();
      _neuralPredictor.train(_historicalData, epochs: 50);

      _savedNumbers = await _dbService.getSavedNumbers();

      _isDataLoaded = true;
      _statusMessage = '제$_latestRound회 데이터 로드 완료';
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
    _numbersSaved = false;
    notifyListeners();

    if (_useNeural && _neuralPredictor.isTrained) {
      _generatedNumbers = _neuralPredictor.predict(_historicalData.last.numbers);
      _statusMessage = 'AI 신경망 단독 예측 완료 (전략 미적용)';
    } else {
      final analyzer = LottoAnalyzer(historicalData: filteredData);
      _generatedNumbers = analyzer.generateNumbers(strategy: _strategy);
      final strategyName = switch (_strategy) {
        AnalysisStrategy.conservative => '보수적',
        AnalysisStrategy.aggressive => '공격적',
        AnalysisStrategy.balanced => '밸런스',
      };
      _statusMessage = '$strategyName 전략 + 6개 필터 적용';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> saveCurrentNumbers() async {
    if (_generatedNumbers.isEmpty) return false;

    await _dbService.saveNumbers(
      _generatedNumbers,
      _strategy,
      isNeural: _useNeural,
    );
    _savedNumbers = await _dbService.getSavedNumbers();
    _numbersSaved = true;
    notifyListeners();
    return true;
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
