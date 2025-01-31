import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/firebase_service.dart';
import '../models/transaction.dart';
import 'package:intl/intl.dart'; // 日付フォーマット用

class ProgressScreen extends StatefulWidget {
  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _selectedSegment = '支出'; // デフォルトは「支出」
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now()); // 現在の月
  List<String> _availableMonths = []; // 利用可能な月のリスト

  @override
  void initState() {
    super.initState();
    _initializeAvailableMonths();
  }

  // 利用可能な月を取得
  Future<void> _initializeAvailableMonths() async {
    List<Transaction> transactions = await _firebaseService.getTransactions();
    Set<String> months = transactions.map((tx) {
      return DateFormat('yyyy-MM').format(tx.date);
    }).toSet();

    // 現在の月を必ず含むようにする
    String currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
    months.add(currentMonth);

    setState(() {
      _availableMonths = months.toList()..sort((a, b) => b.compareTo(a)); // 降順でソート
    });
  }

  // データを取得し、セグメントと月に応じたデータを集計
  Future<Map<String, double>> _loadCategoryData() async {
    List<Transaction> transactions = await _firebaseService.getTransactions();
    Map<String, double> categoryMap = {};

    for (var tx in transactions) {
      String transactionMonth = DateFormat('yyyy-MM').format(tx.date);

      if (transactionMonth == _selectedMonth) {
        if (_selectedSegment == '支出' && tx.type == 'expense') {
          categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
        } else if (_selectedSegment == '収入' && tx.type == 'income') {
          categoryMap[tx.category] = (categoryMap[tx.category] ?? 0) + tx.amount;
        }
      }
    }

    return categoryMap;
  }

  // セグメント変更時に更新
  void _onSegmentChanged(String newSegment) {
    setState(() {
      _selectedSegment = newSegment;
    });
  }

  // ドラムロール形式で年月選択
  void _showYearMonthPicker() {
    final DateTime now = DateTime.now();
    final int currentYear = now.year;
    final int currentMonth = now.month;

    int selectedYear = int.parse(_selectedMonth.split('-')[0]);
    int selectedMonth = int.parse(_selectedMonth.split('-')[1]);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        height: 300,
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              '年月を選択',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: Row(
                children: [
                  // 年のピッカー
                  Expanded(
                    flex: 2,
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: currentYear - selectedYear,
                      ),
                      onSelectedItemChanged: (index) {
                        selectedYear = currentYear - index;
                      },
                      children: List.generate(
                        10,
                        (index) => Center(
                          child: Text('${currentYear - index}年'),
                        ),
                      ),
                    ),
                  ),
                  // 月のピッカー
                  Expanded(
                    flex: 1,
                    child: CupertinoPicker(
                      itemExtent: 32,
                      scrollController: FixedExtentScrollController(
                        initialItem: selectedMonth - 1,
                      ),
                      onSelectedItemChanged: (index) {
                        selectedMonth = index + 1;
                      },
                      children: List.generate(
                        12,
                        (index) => Center(
                          child: Text('${index + 1}月'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedMonth = '$selectedYear-${selectedMonth.toString().padLeft(2, '0')}';
                });
                Navigator.pop(context);
              },
              child: const Text('決定'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_selectedSegment 表示'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoSegmentedControl<String>(
                    children: {
                      '支出': Text('支出'),
                      '収入': Text('収入'),
                    },
                    onValueChanged: _onSegmentChanged,
                    groupValue: _selectedSegment,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _showYearMonthPicker,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.blue.shade100,
                    ),
                    child: Text(
                      DateFormat('yyyy年MM月').format(DateTime.parse('$_selectedMonth-01')),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: _loadCategoryData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('データの読み込みに失敗しました'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('データがありません'));
                }

                final data = snapshot.data!;
                return _buildExpenseIncomeContent(data);
              },
            ),
          ),
        ],
      ),
    );
  }

  // 支出または収入のコンテンツ（円グラフ + カテゴリリスト）
  Widget _buildExpenseIncomeContent(Map<String, double> categoryData) {
    double totalAmount = categoryData.values.fold(0, (sum, amount) => sum + amount);
    final pieColors = _generatePieColors(categoryData.keys);

    return Column(
      children: [
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: PieChart(
              PieChartData(
                sections: _buildPieChartSections(categoryData, pieColors, totalAmount),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            '合計: ¥${totalAmount.toInt()}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          flex: 3,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: categoryData.length,
            itemBuilder: (context, index) {
              String category = categoryData.keys.elementAt(index);
              double amount = categoryData[category]!;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4.0),
                child: ListTile(
                  title: Text(
                    category,
                    style: TextStyle(
                      color: pieColors[category],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(
                    '¥${amount.toInt()}',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // onTap: () => _sh,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 円グラフのセクション作成
  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> categoryData, Map<String, Color> pieColors, double totalAmount) {
  const double thresholdPercentage = 0.05; // 表示しない閾値 (5%)

  return categoryData.entries.map((entry) {
    double percentage = entry.value / totalAmount; // カテゴリの全体に対する割合
    return PieChartSectionData(
      color: pieColors[entry.key],
      value: entry.value,
      title: percentage > thresholdPercentage ? entry.key : '', // 閾値未満の場合はタイトルを非表示
      radius: 50,
      titleStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }).toList();
}


  // カテゴリごとの色を生成
  Map<String, Color> _generatePieColors(Iterable<String> categories) {
    final List<Color> colors = [
      Colors.blue, Colors.red, Colors.green, Colors.yellow,
      Colors.orange, Colors.purple, Colors.brown, Colors.cyan,
    ];

    int colorIndex = 0;
    return {for (var category in categories) category: colors[colorIndex++ % colors.length]};
  }
}
