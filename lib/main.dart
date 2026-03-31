import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/lotto_provider.dart';
import 'screens/home_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/history_screen.dart';

void main() {
  runApp(const LottoAnalyzerApp());
}

class LottoAnalyzerApp extends StatelessWidget {
  const LottoAnalyzerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LottoProvider(),
      child: MaterialApp(
        title: '로또 딥러닝 분석기',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0D0D0D),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFFD700),
            secondary: Color(0xFFDAA520),
            surface: Color(0xFF1A1A2E),
          ),
        ),
        home: const MainNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    AnalysisScreen(),
    HistoryScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LottoProvider>().loadHistoricalData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: const Color(0xFFDAA520).withAlpha(30),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          backgroundColor: const Color(0xFF0D0D0D),
          selectedItemColor: const Color(0xFFFFD700),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 10,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.casino),
              label: '번호생성',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: '분석',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: '히스토리',
            ),
          ],
        ),
      ),
    );
  }
}
