import 'package:flutter/material.dart';
import '../models/transaction.dart';

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;

  TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return ListTile(
          title: Text(transaction.category),
          subtitle: Text(transaction.date.toLocal().toString()),
          trailing: Text(
            transaction.amount.toString(),
            style: TextStyle(
              color: transaction.type == 'expense' ? Colors.red : Colors.green,
            ),
          ),
        );
      },
    );
  }
}
