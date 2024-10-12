// Refactored TransactionList widget
import 'package:flutter/material.dart';
import 'package:sms_reader/pages/details/userdetails.dart';
import './transactionCard.dart';
class TransactionList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedTransactions;

  const TransactionList({Key? key, required this.groupedTransactions}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: groupedTransactions.keys.length,
      itemBuilder: (context, index) {
        String phoneNumber = groupedTransactions.keys.elementAt(index);
        List<Map<String, dynamic>> transactions = groupedTransactions[phoneNumber]!;

        // Calculate total amount
        double totalAmount = calculateTotalAmount(transactions);

        // Determine color
        Color amountColor = totalAmount < 0 ? Colors.red : Colors.green;

        return TransactionCard(
          icon: Icons.person,
          title: phoneNumber,
          time: "${transactions.length} transactions",
          amount: totalAmount.toStringAsFixed(2),
          amountColor: amountColor,
          onClick: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(transactions: transactions, name: phoneNumber),
              ),
            );
          },
        );
      },
    );
  }

  double calculateTotalAmount(List<Map<String, dynamic>> transactions) {
    double totalAmount = 0;
    for (var transaction in transactions) {
      if (transaction['type'] == 'sent') {
        totalAmount -= transaction['amount'];
      } else {
        totalAmount += transaction['amount'];
      }
    }
    return totalAmount;
  }
}
