// Refactored ContactsTransactionList widget
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:sms_reader/pages/details/userdetails.dart';
import 'package:sms_reader/widgets/transactionCard.dart';

class ContactsTransactionList extends StatelessWidget {
  final Map<String, List<Map<String, dynamic>>> groupedTransactions;
  final List<Contact> contacts;

  const ContactsTransactionList({
    Key? key,
    required this.groupedTransactions,
    required this.contacts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<String> validPhoneNumbers = groupedTransactions.keys
        .where((phoneNumber) => _getContactName(phoneNumber) != null)
        .toList();

    return ListView.builder(
      itemCount: validPhoneNumbers.length,
      itemBuilder: (context, index) {
        String phoneNumber = validPhoneNumbers[index];
        List<Map<String, dynamic>> transactions = groupedTransactions[phoneNumber]!;

        // Find the contact name
        String? contactName = _getContactName(phoneNumber);

        // Calculate total amount
        double totalAmount = calculateTotalAmount(transactions);

        // Determine color
        Color amountColor = totalAmount < 0 ? Colors.red : Colors.green;

        return TransactionCard(
          icon: Icons.person,
          title: contactName!,
          time: "${transactions.length} transactions",
          amount: totalAmount.toStringAsFixed(2),
          amountColor: amountColor,
          onClick: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(transactions: transactions, name: contactName),
              ),
            );
          },
        );
      },
    );
  }

  String? _getContactName(String phoneNumber) {
    for (var contact in contacts) {
      if (contact.phones != null) {
        for (var phone in contact.phones!) {
          if (phone.value != null && phone.value!.contains(phoneNumber)) {
            return contact.displayName;
          }
        }
      }
    }
    return null;
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
