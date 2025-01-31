import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/transaction.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  Map<DateTime, List<Transaction>> _transactionsByDay = {};
  DateTime _selectedDay = DateTime.now(); // クラスフィールドとして定義
  DateTime _focusedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    List<Transaction> transactions = await _firebaseService.getTransactions();
    Map<DateTime, List<Transaction>> groupedTransactions = {};

    for (var tx in transactions) {
      DateTime day = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groupedTransactions[day] = groupedTransactions[day] ?? [];
      groupedTransactions[day]!.add(tx);
    }

    if (mounted) {
      setState(() {
        _transactionsByDay = groupedTransactions;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('カレンダー'),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 500.0,
            child: TableCalendar(
              shouldFillViewport: true,
              firstDay: DateTime.utc(2000, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                  );
                  _focusedDay = focusedDay;
                });

                // 新しい画面に遷移
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DailyTransactionsScreen(
                      selectedDay: _selectedDay,
                      transactions: _transactionsByDay[_selectedDay] ?? [],
                    ),
                  ),
                );
              },
              onPageChanged: (focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              // calendarStyle: CalendarStyle(
              //   selectedDecoration: BoxDecoration(), // 選択時の装飾をなくす
              //   todayDecoration: BoxDecoration(
              //     color: Colors.grey.shade200, // 今日の日付を軽く強調（任意）
              //     shape: BoxShape.circle,
              //   ),
              // ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) {
                  final dayKey = DateTime(day.year, day.month, day.day);
                  List<Transaction>? dayTransactions = _transactionsByDay[dayKey];

                  double income = dayTransactions != null
                      ? dayTransactions
                          .where((tx) => tx.type == 'income')
                          .fold(0.0, (sum, tx) => sum + tx.amount)
                      : 0.0;

                  double expense = dayTransactions != null
                      ? dayTransactions
                          .where((tx) => tx.type == 'expense')
                          .fold(0.0, (sum, tx) => sum + tx.amount)
                      : 0.0;

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${day.day}',
                          style: const TextStyle(fontSize: 20),
                        ),
                        if (income > 0)
                          Text(
                            '+¥${income.toInt()}',
                            style: const TextStyle(fontSize: 10, color: Colors.green),
                          ),
                        if (expense > 0)
                          Text(
                            '-¥${expense.toInt()}',
                            style: const TextStyle(fontSize: 10, color: Colors.red),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class DailyTransactionsScreen extends StatelessWidget {
  final DateTime selectedDay;
  final List<Transaction> transactions;
  final FirebaseService _firebaseService = FirebaseService(); // プロパティとして宣言

  DailyTransactionsScreen({
    required this.selectedDay,
    required this.transactions,
  });

  void _editTransaction(BuildContext context, Transaction transaction) {
    String newCategory = transaction.category;
    String newAmount = transaction.amount.toInt().toString();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('取引の編集'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: newCategory),
                decoration: const InputDecoration(labelText: 'カテゴリー'),
                onChanged: (value) {
                  newCategory = value;
                },
              ),
              TextField(
                controller: TextEditingController(text: newAmount),
                decoration: const InputDecoration(labelText: '金額'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  newAmount = value;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _firebaseService.deleteTransaction(transaction.id).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('記録が削除されました'),
                      backgroundColor: Colors.red,
                    ),
                  );
                });
              },
              child: const Text(
                '削除',
                style: TextStyle(color: Colors.red),
              ),
            ),
            TextButton(
              onPressed: () {
                _firebaseService
                    .updateTransaction(
                  transaction.id,
                  Transaction(
                    id: transaction.id,
                    category: newCategory,
                    amount: double.parse(newAmount),
                    date: transaction.date,
                    type: transaction.type,
                  ),
                )
                    .then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('記録が保存されました'),
                      backgroundColor: Colors.green,
                    ),
                  );
                });
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('yyyy年MM月dd日').format(selectedDay)),
      ),
      body: transactions.isEmpty
          ? const Center(
              child: Text(
                'この日の記録はありません。',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return ListTile(
                  title: Text(transaction.category),
                  subtitle: Text(
                    '¥${transaction.amount.toInt()}',
                    style: TextStyle(
                      color: transaction.type == 'income'
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: Text(DateFormat('HH:mm').format(transaction.date)),
                  onTap: () => _editTransaction(context, transaction),
                );
              },
            ),
    );
  }
}
