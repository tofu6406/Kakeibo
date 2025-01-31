import 'package:cloud_firestore/cloud_firestore.dart' as firestore;
import '../models/transaction.dart';
import '../models/goal.dart';

class FirebaseService {
  final firestore.FirebaseFirestore _db = firestore.FirebaseFirestore.instance;

  // 収支データの追加
  Future<void> addTransaction(Transaction transaction) async {
    await _db.collection('transactions').add(transaction.toMap());
  }

  // 収支データの取得
  Future<List<Transaction>> getTransactions() async {
    var snapshot = await _db.collection('transactions').get();
    return snapshot.docs.map((doc) {
      return Transaction.fromMap(doc.data() as Map<String, dynamic>)
          .copyWith(id: doc.id); // IDを設定
    }).toList();
  }

  // 収支データの更新
  Future<void> updateTransaction(String id, Transaction transaction) async {
    await _db.collection('transactions').doc(id).update(transaction.toMap());
  }

  // 収支データの削除
  Future<void> deleteTransaction(String id) async {
    await _db.collection('transactions').doc(id).delete();
  }

  // 予算データの追加
  Future<void> addBudget(double budget) async {
    await _db.collection('budget').doc('monthly').set({
      'budget': budget,
      'timestamp': firestore.FieldValue.serverTimestamp(),
    });
  }

  // 目標データの追加
  Future<void> addGoal(Goal goal) async {
    await _db.collection('goals').add(goal.toMap());
  }

  // 目標データの取得
  Future<List<Goal>> getGoals() async {
    var snapshot = await _db.collection('goals').get();
    return snapshot.docs.map((doc) {
      return Goal.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  }

}
