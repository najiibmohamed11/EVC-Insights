import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String time;
  final String amount;
  final Color amountColor;
  final VoidCallback onClick; // Accepts a callback function for onClick

  const TransactionCard({
    required this.icon,
    required this.title,
    required this.time,
    required this.amount,
    required this.amountColor,
    required this.onClick,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onClick, // Calls the onClick function when tapped
        leading: CircleAvatar(
          backgroundColor: Colors.grey.shade200,
          child: Icon(icon, color: Colors.black),
        ),
        title: Text(title),
        subtitle: Text(time),
        trailing: Text(
          amount,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
