import 'package:aiapp_kakeibo3/screens/savings_screen.dart';
import 'package:flutter/material.dart';
import 'add_transaction_screen.dart';  // 各画面のインポート
import 'calendar_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;  // 最初に収支入力画面を表示する

  // BottomNavigationBarで表示する画面のリスト
  final List<Widget> _screens = [
    AddTransactionScreen(),
    CalendarScreen(),
    ProgressScreen(),
    SavingsScreen(),
    SettingScreen(),
  ];

  // BottomNavigationBarでアイテムがタップされたときの処理
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],  // 選択された画面を表示
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: '収支入力',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'カレンダー',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart),
            label: '円グラフ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.attach_money),
            label: '貯金',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}

