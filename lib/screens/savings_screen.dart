import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaction.dart';

class SavingsScreen extends StatefulWidget {
  @override
  _SavingsScreenState createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Transaction>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _firebaseService.getTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('貯金額'),
      ),
      body: FutureBuilder<List<Transaction>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('データの読み込みに失敗しました'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('データがありません'));
          }

          final transactions = snapshot.data!;
          final savingsData = _calculateSavings(transactions);

          return Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final months = savingsData['months'] as List<String>;
                              if (value.toInt() < months.length) {
                                return Text(months[value.toInt()]);
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      barGroups: _buildBarGroups(savingsData['monthlySavings'] as List<double>),
                      gridData: FlGridData(show: false),
                    ),
                  ),
                ),
              ),
              const Divider(thickness: 1),
              Expanded(
                child: _buildSavingsList(savingsData),
              ),
            ],
          );
        },
      ),
    );
  }

  // 貯金データを計算する
  Map<String, dynamic> _calculateSavings(List<Transaction> transactions) {
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final date = DateTime(now.year, now.month - i, 1);
      return DateFormat('yyyy-MM').format(date);
    }).reversed.toList();

    final monthlySavings = <double>[];
    final monthlyNetSavings = <double>[];

    double accumulatedSavings = 0;

    for (var month in months) {
      final monthlyTransactions = transactions.where((tx) {
        return DateFormat('yyyy-MM').format(tx.date) == month;
      });

      double netSavings = 0;
      for (var tx in monthlyTransactions) {
        netSavings += (tx.type == 'income') ? tx.amount : -tx.amount;
      }

      accumulatedSavings += netSavings;
      accumulatedSavings = accumulatedSavings < 0 ? 0 : accumulatedSavings; // マイナスの場合は0で止まる
      monthlySavings.add(accumulatedSavings);
      monthlyNetSavings.add(netSavings); // 月ごとのプラス/マイナス分
    }

    return {
      'months': months.map((m) => DateFormat('M').format(DateTime.parse('$m-01'))).toList(),
      'monthlySavings': monthlySavings,
      'monthlyNetSavings': monthlyNetSavings,
    };
  }

  // 棒グラフのデータを作成
  List<BarChartGroupData> _buildBarGroups(List<double> monthlySavings) {
    final maxSavings = monthlySavings.reduce((a, b) => a > b ? a : b);
    return List.generate(monthlySavings.length, (index) {
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: monthlySavings[index],
            color: Colors.blue,
            width: 20,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxSavings,
              color: Colors.grey.shade300,
            ),
          ),
        ],
      );
    });
  }

  // 毎月の貯金をリストで表示
  Widget _buildSavingsList(Map<String, dynamic> savingsData) {
    final months = savingsData['months'] as List<String>;
    final monthlyNetSavings = savingsData['monthlyNetSavings'] as List<double>;

    return ListView.builder(
      itemCount: months.length,
      itemBuilder: (context, index) {
        final savings = monthlyNetSavings[index];
        return ListTile(
          leading: Text('${months[index]}月', style: const TextStyle(fontSize: 16)),
          trailing: Text(
            '¥${savings.toInt()}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: savings < 0 ? Colors.red : Colors.green, // マイナスは赤、プラスは緑
            ),
          ),
        );
      },
    );
  }
}
