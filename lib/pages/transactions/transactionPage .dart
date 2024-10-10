import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sms_reader/pages/details/userdetails.dart';
import 'package:sms_reader/providers/sms_provider.dart';
import 'dart:collection'; // To use LinkedHashMap
import '../../widgets/transactionCard.dart'; // Import the TransactionCard widget
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> contacts = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); 
    _getContactsPermission();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getContactsPermission() async {
    PermissionStatus permissionStatus = await Permission.contacts.status;

    if (!permissionStatus.isGranted) {
      permissionStatus = await Permission.contacts.request();
    }

    if (permissionStatus.isGranted) {
      _fetchContacts();
    } else {
      _showPermissionDeniedDialog();
    }
  }

  Future<void> _fetchContacts() async {
    try {
      Iterable<Contact> contactsList = await ContactsService.getContacts();

      setState(() {
        contacts = contactsList.toList();
      });
    } catch (e) {
      print('Error fetching contacts: $e');
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Permission Denied'),
        content: Text(
            'Please allow access to contacts from the app settings to use this feature.'),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final smsProvider = Provider.of<SmsProvider>(context);

    // Fetch all transactions
    // smsProvider.setFilter("All");
    List<Map<String, dynamic>> transactions = smsProvider.allFormattedMessages;

    // Group transactions by phone number
    Map<String, List<Map<String, dynamic>>> groupedTransactions =
        groupTransactionsByPhoneNumber(transactions);

    // Sort grouped transactions by the number of transactions for the "Most Interacted" tab
    List<MapEntry<String, List<Map<String, dynamic>>>>
        sortedByTransactionCount =
        sortGroupedTransactionsByCount(groupedTransactions);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Search Bar and Filter Row
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search transaction',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.filter_list, color: Colors.grey),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Tab Bar
          // Replace the existing TabBar code with this:
          Container( 
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Color(0xff13BC8D),
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black,
                labelPadding: EdgeInsets.symmetric(horizontal: 16),
                tabs: [
                  Tab(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('All'),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('relative'),
                    ),
                  ),
                  Tab(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Contacts'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Expanded Widget for Scrollable TabBarView content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // "All" Tab Content
                transactionList(groupedTransactions),
                // "Most Interacted" Tab Content
                transactionListFromSortedEntries(sortedByTransactionCount),
                contactsTransactionList(groupedTransactions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? _getContactName(String phoneNumber) {
    for (var contact in contacts) {
      if (contact.phones != null) {
        for (var phone in contact.phones!) {
          if (phone.value != null && phone.value!.contains(phoneNumber)) {
            return contact.displayName; // Return contact's name if matched
          }
        }
      }
    }
    return null; // Return null if no contact found
  }

  // Function to group transactions by phoneNumber
  Map<String, List<Map<String, dynamic>>> groupTransactionsByPhoneNumber(
      List<Map<String, dynamic>> transactions) {
    Map<String, List<Map<String, dynamic>>> grouped = LinkedHashMap();

    for (var transaction in transactions) {
      final phoneNumber = transaction['phoneNumber'];
      if (grouped.containsKey(phoneNumber)) {
        grouped[phoneNumber]!.add(transaction);
      } else {
        grouped[phoneNumber] = [transaction];
      }
    }

    return grouped;
  }

  // Function to sort grouped transactions and filter for those with more than 5 transactions
  List<MapEntry<String, List<Map<String, dynamic>>>>
      sortGroupedTransactionsByCount(
          Map<String, List<Map<String, dynamic>>> groupedTransactions) {
    // Sort by the number of transactions
    List<MapEntry<String, List<Map<String, dynamic>>>> sortedEntries =
        groupedTransactions.entries.toList();

    // Filter out entries with less than 5 transactions and sort
    sortedEntries = sortedEntries
        .where((entry) =>
            entry.value.length >
            5) // Keep only entries with more than 5 transactions
        .toList()
      ..sort((a, b) => b.value.length
          .compareTo(a.value.length)); // Sort by transaction count

    return sortedEntries;
  }

  // Function to display the grouped transaction list (sorted by transaction count)
  Widget transactionListFromSortedEntries(
      List<MapEntry<String, List<Map<String, dynamic>>>> sortedTransactions) {
    return ListView.builder(
      itemCount: sortedTransactions.length,
      itemBuilder: (context, index) {
        String phoneNumber = sortedTransactions[index].key;
        List<Map<String, dynamic>> transactions =
            sortedTransactions[index].value;

        // Calculate total amount for this phoneNumber
        double totalAmount = 0;
        for (var transaction in transactions) {
          if (transaction['type'] == 'sent') {
            totalAmount -= transaction['amount']; // Sent: negative
          } else {
            totalAmount += transaction['amount']; // Received: positive
          }
        }
        String name = _getContactName(phoneNumber) ?? phoneNumber;

        // Determine color based on whether totalAmount is positive or negative
        Color amountColor = totalAmount < 0 ? Colors.red : Colors.green;

        return TransactionCard(
          icon: Icons.person, // Static user icon
          title: name,
          time:
              "${transactions.length} transactions", // Display number of transactions
          amount: totalAmount.toStringAsFixed(2), // Display total amount
          amountColor: amountColor,
          onClick: () {
            // Pass the transactions for the clicked phoneNumber to the Details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(
                    transactions: transactions,
                    name: name), // Pass transactions
              ),
            );
          },
        );
      },
    );
  }

  // Function to display the grouped transaction list
  Widget transactionList(
      Map<String, List<Map<String, dynamic>>> groupedTransactions) {
    return ListView.builder(
      itemCount: groupedTransactions.keys.length,
      itemBuilder: (context, index) {
        String phoneNumber = groupedTransactions.keys.elementAt(index);
        List<Map<String, dynamic>> transactions =
            groupedTransactions[phoneNumber]!;

        // Calculate total amount for this phoneNumber
        double totalAmount = 0;
        for (var transaction in transactions) {
          if (transaction['type'] == 'sent') {
            totalAmount -= transaction['amount']; // Sent: negative
          } else {
            totalAmount += transaction['amount']; // Received: positive
          }
        }
        String name = _getContactName(phoneNumber) ?? phoneNumber;

        // Determine color based on whether totalAmount is positive or negative
        Color amountColor = totalAmount < 0 ? Colors.red : Colors.green;

        return TransactionCard(
          icon: Icons.person, // Static user icon
          title: name,
          time:
              "${transactions.length} transactions", // Display number of transactions
          amount: totalAmount.toStringAsFixed(2), // Display total amount
          amountColor: amountColor,
          onClick: () {
            print('this is ..... ');
            print(transactions);

            // Pass the transactions for the clicked phoneNumber to the Details page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(
                    transactions: transactions,
                    name: name), // Pass transactions
              ),
            );
          },
        );
      },
    );
  }

  Widget contactsTransactionList(
      Map<String, List<Map<String, dynamic>>> groupedTransactions) {
    // Filter out transactions where contactName is null
    List<String> validPhoneNumbers = groupedTransactions.keys
        .where((phoneNumber) => _getContactName(phoneNumber) != null)
        .toList();

    return ListView.builder(
      itemCount: validPhoneNumbers.length,
      itemBuilder: (context, index) {
        String phoneNumber = validPhoneNumbers[index];
        List<Map<String, dynamic>> transactions =
            groupedTransactions[phoneNumber]!;

        // Find the contact name for this phone number
        String? contactName = _getContactName(phoneNumber);
        // We have already filtered, so contactName should never be null at this point.

        // Calculate total amount for this phoneNumber
        double totalAmount = 0;
        for (var transaction in transactions) {
          if (transaction['type'] == 'sent') {
            totalAmount -= transaction['amount']; // Sent: negative
          } else {
            totalAmount += transaction['amount']; // Received: positive
          }
        }

        // Determine color based on whether totalAmount is positive or negative
        Color amountColor = totalAmount < 0 ? Colors.red : Colors.green;

        return TransactionCard(
          icon: Icons.person, // Static user icon
          title: contactName!, // Use contact name (we know it's not null)
          time: "${transactions.length} transactions", // Number of transactions
          amount: totalAmount.toStringAsFixed(2), // Total amount
          amountColor: amountColor,
          onClick: () {
            // Navigate to details page with the transactions
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Details(
                    transactions: transactions,
                    name: contactName), // Pass transactions
              ),
            );
          },
        );
      },
    );
  }

// Helper function to get contact name by phone number
}
