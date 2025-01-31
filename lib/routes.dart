import 'package:aiapp_kakeibo3/screens/auth_screen.dart';
import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import './screens/add_transaction_screen.dart';
import './screens/savings_screen.dart';
import './screens/progress_screen.dart';
import './screens/auth_screen.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => HomeScreen(),
  '/addTransaction': (context) => AddTransactionScreen(),
  '/savings': (context) => SavingsScreen(),
  '/progress': (context) => ProgressScreen(),
  '/login': (context) => AuthScreen(),
};
