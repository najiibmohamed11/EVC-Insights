import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:sms_reader/widgets/chartPart.dart';
import 'package:sms_reader/widgets/transactionCard.dart';

class Details extends StatefulWidget {
  final List<Map<String, dynamic>> transactions; // Transactions list
  final String name;
  const Details({super.key, required this.transactions,required this.name});

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(widget.name),
      ),
      body: Column(
        children: [
          DetailsChartWidget(transactions: widget.transactions),
          Expanded(
            child: ListView.builder(
              itemCount: widget.transactions.length,
              itemBuilder: (context, index) {
                var transaction = widget.transactions[index];
                // Use null-aware operators to handle potential null values
                String phoneNumber =
                    transaction['phoneNumber'] ?? 'Unknown Number';
                String time = transaction['date'].toString();
                double amount = transaction['amount'] ?? 0.0;
                String type = transaction['type'] ??
                    'received'; // Assume 'received' if null
                double remainer = transaction['remainer'] ?? 0.0;

                return TransactionCard(
                  title: time,
                  icon: type == 'sent' ? Icons.call_made : Icons.call_received,
                  time: 'haragaagu ${remainer.toString()}',
                  amount: "${type == 'sent' ? '-' : '+'}$amount",
                  amountColor: type == 'sent' ? Colors.red : Colors.green,
                  onClick: () => {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
