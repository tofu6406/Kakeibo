import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import '../screens/auth_screen.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final FirebaseAuthService _authService = FirebaseAuthService();
  bool _enableTargetSavings = true; // 貯金目標を有効にするか
  bool _enableCategoryBudget = true; // カテゴリー予算を有効にするか
  String _targetSavings = '0';
  String _currentSavings = '0';
  Map<String, String> _categoryBudgets = {};
  String _currentKeypadValue = '';
  String _selectedCategory = '';
  final _categories = ['食費', '外食費', '日用品', '交通費', '衣服', '交際費', '趣味', 'その他'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _enableTargetSavings = prefs.getBool('enableTargetSavings') ?? true;
      _enableCategoryBudget = prefs.getBool('enableCategoryBudget') ?? true;
      _targetSavings = prefs.getString('targetSavings') ?? '0';
      _currentSavings = prefs.getString('currentSavings') ?? '0';
      _categories.forEach((category) {
        _categoryBudgets[category] = prefs.getString('budget_$category') ?? '0';
      });
    });
  }

  Future<void> _savePreferences(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else {
      await prefs.setString(key, value);
    }

    setState(() {
      if (key == 'enableTargetSavings') _enableTargetSavings = value;
      if (key == 'enableCategoryBudget') _enableCategoryBudget = value;
      if (key == 'targetSavings') _targetSavings = value;
      if (key == 'currentSavings') _currentSavings = value;
      if (key.startsWith('budget_')) {
        _categoryBudgets[key.replaceFirst('budget_', '')] = value;
      }
    });
  }

    // **アカウントの削除**
  Future<void> _deleteAccount() async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("アカウント削除"),
        content: const Text("本当にアカウントを削除しますか？この操作は元に戻せません。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("キャンセル"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("削除", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete) {
      bool success = await _authService.deleteAccount();
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("アカウント削除に失敗しました")),
        );
      }
    }
  }

  String _formatAmount(String amount) {
    if (amount.isEmpty) return '0';
    final num value = int.tryParse(amount.replaceAll(',', '')) ?? 0;
    return NumberFormat('#,###').format(value);
  }

  void _showCustomKeypad(String title, String key, {String? category}) {
    setState(() {
      _currentKeypadValue = category == null
          ? (key == 'targetSavings' ? _targetSavings : _currentSavings)
          : _categoryBudgets[category] ?? '0';
      _selectedCategory = category ?? '';
    });

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void _updateKeypadValue(String value) {
              setModalState(() {
                _currentKeypadValue = value;
              });
            }

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¥${_formatAmount(_currentKeypadValue)}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const Divider(height: 20, color: Colors.grey),
                  _buildKeypad(
                    onConfirm: () {
                      _savePreferences(
                          key.startsWith('budget_')
                              ? 'budget_${_selectedCategory}'
                              : key,
                          _currentKeypadValue);
                      Navigator.pop(context);
                    },
                    onValueChanged: _updateKeypadValue,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildKeypad({
    required VoidCallback onConfirm,
    required Function(String) onValueChanged,
  }) {
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 5,
      crossAxisSpacing: 5,
      shrinkWrap: true,
      childAspectRatio: 2,
      children: [
        ...[7, 8, 9, 4, 5, 6, 1, 2, 3].map((number) {
          return ElevatedButton(
            onPressed: () {
              onValueChanged(_currentKeypadValue + number.toString());
            },
            child: Text('$number', style: const TextStyle(fontSize: 18)),
          );
        }),
        ElevatedButton(
          onPressed: () {
            onValueChanged(
              _currentKeypadValue.isNotEmpty
                  ? _currentKeypadValue.substring(0, _currentKeypadValue.length - 1)
                  : '',
            );
          },
          child: const Icon(Icons.backspace),
        ),
        ElevatedButton(
          onPressed: () {
            onValueChanged(_currentKeypadValue + '0');
          },
          child: const Text('0', style: TextStyle(fontSize: 18)),
        ),
        ElevatedButton(
          onPressed: () {
            onValueChanged(_currentKeypadValue + '00');
          },
          child: const Text('00', style: TextStyle(fontSize: 18)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          child: const Text('確定', style: TextStyle(fontSize: 18)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: SettingsList(
        lightTheme: const SettingsThemeData(
          settingsListBackground: Color(0xFFF2F2F7),
          settingsSectionBackground: Colors.white,
        ),
        sections: [
          // 🔹 **アカウント設定セクション**
          SettingsSection(
            title: const Text('アカウント設定'),
            tiles: [
              SettingsTile.navigation(
                title: const Text('アカウントの変更（ログイン）'),
                leading: const Icon(Icons.person),
                onPressed: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                },
              ),
              SettingsTile.navigation(
                title: const Text('新しいアカウントを登録'),
                leading: const Icon(Icons.person_add),
                onPressed: (_) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                  );
                },
              ),
              SettingsTile.navigation(
                title: const Text('アカウントの削除'),
                leading: const Icon(Icons.delete, color: Colors.red),
                onPressed: (_) => _deleteAccount(),
              ),
            ],
          ),

          // 🔹 **貯金設定セクション**
          SettingsSection(
            title: const Text('貯金設定'),
            tiles: [
              SettingsTile.switchTile(
                title: const Text('貯金目標を有効にする'),
                leading: const Icon(Icons.savings),
                initialValue: _enableTargetSavings,
                onToggle: (value) =>
                    _savePreferences('enableTargetSavings', value),
              ),
              if (_enableTargetSavings)
                SettingsTile.navigation(
                  title: const Text('貯金目標設定'),
                  value: Text('¥${_targetSavings}'),
                  onPressed: (_) =>
                      _showCustomKeypad('貯金目標を設定', 'targetSavings'),
                ),
            ],
          ),

          // 🔹 **予算設定セクション**
          SettingsSection(
            title: const Text('毎月の予算設定'),
            tiles: [
              SettingsTile.switchTile(
                title: const Text('予算設定を有効にする'),
                leading: const Icon(Icons.category),
                initialValue: _enableCategoryBudget,
                onToggle: (value) =>
                    _savePreferences('enableCategoryBudget', value),
              ),
              if (_enableCategoryBudget)
                ..._categories.map((category) {
                  return SettingsTile.navigation(
                    title: Text(category),
                    value: Text('¥${_categoryBudgets[category] ?? '0'}'),
                    onPressed: (_) => _showCustomKeypad(
                        '予算を設定 ($category)', 'budget_$category',
                        category: category),
                  );
                }).toList(),
            ],
          ),
        ],
      ),
    );
  }
}