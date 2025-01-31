import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:intl/intl.dart'; // カンマ区切り用
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction.dart';
import '../services/firebase_service.dart';

class AddTransactionScreen extends StatefulWidget {
  @override
  _AddTransactionScreenState createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final PanelController _panelController = PanelController();

  late TabController _tabController;
  String _category = '食費';
  String _amount = ''; // 金額を直接管理
  DateTime _selectedDate = DateTime.now();
  String _type = 'expense'; // 現在のタイプ（支出または収入）

  String _targetSavings = '0';
  String _currentSavings = '0';
  bool _enableTargetSavings = true; // 目標設定が有効かどうか

  List<String> _expenseCategories = [
    '食費',
    '外食費',
    '日用品',
    '交通費',
    '衣服',
    '交際費',
    '趣味',
    'その他',
  ];
  List<String> _incomeCategories = ['給料', 'その他'];


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _type = _tabController.index == 0 ? 'expense' : 'income';
        _category =
            _tabController.index == 0 ? _expenseCategories[0] : _incomeCategories[0];
      });
    });
    _loadSavingsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // SharedPreferences から貯金データを読み込む
  Future<void> _loadSavingsData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableTargetSavings = prefs.getBool('enableTargetSavings') ?? true;
      _targetSavings = prefs.getString('targetSavings') ?? '0';
      _currentSavings = prefs.getString('currentSavings') ?? '0';
    });
  }

  // 数値をカンマ区切り形式に変換
  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0';
    final num value = int.tryParse(amount.replaceAll(',', '')) ?? 0;
    return NumberFormat('#,###').format(value);
  }

  // 収支のデータをFirebaseに送信
void _submitTransaction() {
    if (_formKey.currentState!.validate() && _amount.isNotEmpty) {
      final newTransaction = Transaction(
        id: DateTime.now().toString(),
        category: _category,
        amount: double.parse(_amount.replaceAll(',', '')), // カンマを除去して数値変換
        date: _selectedDate,
        type: _type,
      );

      _firebaseService.addTransaction(newTransaction).then((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存されました'),
            backgroundColor: Colors.green,
          ),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存に失敗しました: $error'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  // カテゴリー選択ダイアログ
  void _openCategorySelector() {
    List<String> categories =
        _type == 'expense' ? _expenseCategories : _incomeCategories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('カテゴリー選択', style: TextStyle(fontSize: 18)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        _showCategoryInputDialog(setModalState);
                      },
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(categories[index]),
                        onTap: () {
                          setState(() {
                            _category = categories[index];
                          });
                          Navigator.pop(context);
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _confirmCategoryDeletion(setModalState, categories[index]);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

    // カテゴリー追加ダイアログ
  void _showCategoryInputDialog(StateSetter setModalState) {
    String newCategory = '';
    List<String> targetCategories =
        _type == 'expense' ? _expenseCategories : _incomeCategories;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('新しいカテゴリー'),
        content: TextField(
          onChanged: (value) {
            newCategory = value;
          },
          decoration: InputDecoration(hintText: "カテゴリー名"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('キャンセル'),
          ),
          TextButton(
            onPressed: () {
              if (newCategory.isNotEmpty &&
                  !targetCategories.contains(newCategory)) {
                setModalState(() {
                  targetCategories.insert(0, newCategory);
                  _saveCategories();
                });
              }
              Navigator.pop(context);
            },
            child: Text('追加'),
          ),
        ],
      ),
    );
  }

  void _confirmCategoryDeletion(StateSetter setModalState, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('カテゴリーを削除'),
        content: Text('$category を削除しますか？この操作は元に戻せません。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () {
              _deleteCategory(setModalState, category);
              Navigator.pop(context);
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _deleteCategory(StateSetter setModalState, String category) {
    setModalState(() {
      if (_type == 'expense') {
        _expenseCategories.remove(category);
      } else {
        _incomeCategories.remove(category);
      }
    });
    _saveCategories();
  }

  void _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('expenseCategories', _expenseCategories);
    await prefs.setStringList('incomeCategories', _incomeCategories);
  }

  @override
Widget build(BuildContext context) {
    final targetSavings = int.tryParse(_targetSavings.replaceAll(',', '')) ?? 0;
    final currentSavings = int.tryParse(_currentSavings.replaceAll(',', '')) ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('収支を追加')),
      body: SlidingUpPanel(
        controller: _panelController,
        panel: _buildCustomKeypad(),
        minHeight: 0, // 初期状態で非表示
        maxHeight: 350, // キーパッドの高さ
        body: Column(
          children: [
            if (_enableTargetSavings) // 目標金額を有効にしている場合のみ表示
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '目標: ',
                        style: TextStyle(color: Colors.black, fontSize: 18),
                      ),
                      TextSpan(
                        text: '¥${_formatAmount(_targetSavings)}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (currentSavings >= targetSavings)
                        const TextSpan(
                          text: '\n目標達成！',
                          style: TextStyle(color: Colors.green, fontSize: 16),
                        )
                      else
                        TextSpan(
                          text: '\n達成まで ¥${_formatAmount((targetSavings - currentSavings).toString())}',
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                    ],
                  ),
                ),
              ),
            TabBar(
              controller: _tabController,
              labelColor: Theme.of(context).primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Theme.of(context).primaryColor,
              tabs: const [
                Tab(text: '支出'),
                Tab(text: '収入'),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _openCategorySelector,
                        child: InputDecorator(
                          decoration: const InputDecoration(labelText: 'カテゴリー'),
                          child: Text(_category),
                        ),
                      ),
                      TextField(
                        decoration: const InputDecoration(labelText: '金額'),
                        controller: TextEditingController(text: _formatAmount(_amount)),
                        readOnly: true,
                        onTap: () => _panelController.open(),
                      ),
                      Row(
                        children: [
                          Text('日付: ${_selectedDate.toLocal()}'.split(' ')[0]),
                          TextButton(
                            onPressed: () => showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            ).then((picked) {
                              if (picked != null) setState(() => _selectedDate = picked);
                            }),
                            child: const Text('日付を選択'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: _submitTransaction,
                          child: const Text('保存'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCustomKeypad() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            _amount.isEmpty ? '0' : '¥${_formatAmount(_amount)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const Divider(height: 10),
          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 5,
              crossAxisSpacing: 5,
              childAspectRatio: 2,
              children: [
                ...[7, 8, 9, 4, 5, 6, 1, 2, 3].map((number) {
                  return ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _amount += number.toString();
                      });
                    },
                    child: Text('$number'),
                  );
                }),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (_amount.isNotEmpty) {
                        _amount = _amount.substring(0, _amount.length - 1);
                      }
                    });
                  },
                  child: const Icon(Icons.backspace),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _amount += '0';
                    });
                  },
                  child: const Text('0'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _amount += '00';
                    });
                  },
                  child: const Text('00'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
