import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:sms_reader/providers/ContactProvider.dart';
import 'package:sms_reader/providers/sms_provider.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:sms_reader/widgets/contactsTransactionList.dart';
import 'package:sms_reader/widgets/transactionListFromSortedEntries.dart';
import '../../utility/transaction_helpers.dart';
import '../../widgets/transactionList.dart';

class ModernSearchBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;

  const ModernSearchBar({
    Key? key,
    this.hintText = 'Search transactions',
    this.onChanged,
  }) : super(key: key);

  @override
  _ModernSearchBarState createState() => _ModernSearchBarState();
}

class _ModernSearchBarState extends State<ModernSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _isFocused ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color:
              _isFocused ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: 2,
        ),
        boxShadow: _isFocused
            ? [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ]
            : [],
      ),
      child: TextField(
        focusNode: _focusNode,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.search,
              color: _isFocused
                  ? Theme.of(context).primaryColor
                  : Colors.grey[400],
            ),
          ),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontSize: 16),
        cursorColor: Theme.of(context).primaryColor,
      ),
    );
  }
}

class TransactionPage extends StatefulWidget {
  const TransactionPage({Key? key}) : super(key: key);

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _filterQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    setState(() {
      _filterQuery = query.toLowerCase();
    });
  }


  Map<String, List<Map<String, dynamic>>> _filterTransactions(
      Map<String, List<Map<String, dynamic>>> transactions,
      List<Contact> contacts) {
    if (_filterQuery.isEmpty) {
      return transactions;
    }
    final isPhoneNumber = RegExp(r'^\d+$')
        .hasMatch(_filterQuery); // Check if the query is a phone number

    if (isPhoneNumber) {
      // Switch to "All" tab and filter transactions by phone number
      _tabController.animateTo(0);
    } else {
      // Switch to "Contacts" tab and filter contacts by name
      _tabController.animateTo(2);
    }

    return Map.fromEntries(transactions.entries.where((entry) {
      String phoneNumber = entry.key;
      List<Map<String, dynamic>> transactionList = entry.value;

      // Check if phone number contains the query
      if (phoneNumber.toLowerCase().contains(_filterQuery)) {
        return true;
      }

      // Check if any transaction contains the query in any of its fields
      if (transactionList.any((transaction) => transaction.values.any(
          (value) => value.toString().toLowerCase().contains(_filterQuery)))) {
        return true;
      }

      // Check if the contact name associated with this phone number contains the query
      bool hasMatchingContact = contacts.any((contact) {
        return contact.phones != null &&
            contact.phones!.any((phone) =>
                phone.value?.toLowerCase() == phoneNumber.toLowerCase()) &&
            contact.displayName != null &&
            contact.displayName!.toLowerCase().contains(_filterQuery);
      });

      return hasMatchingContact;
    }));
  }

  @override
  Widget build(BuildContext context) {
    final smsProvider = Provider.of<SmsProvider>(context);
    final contactProvider = Provider.of<ContactProvider>(context);

    List<Map<String, dynamic>> transactions = smsProvider.allFormattedMessages;
    Map<String, List<Map<String, dynamic>>> groupedTransactions =
        groupTransactionsByPhoneNumber(transactions);

    // Apply filter
    Map<String, List<Map<String, dynamic>>> filteredTransactions =
        _filterTransactions(groupedTransactions, contactProvider.contacts);



    List<MapEntry<String, List<Map<String, dynamic>>>>
        sortedByTransactionCount =
        sortGroupedTransactionsByCount(filteredTransactions);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          ModernSearchBar(
            hintText: 'Search transaction',
            onChanged: _handleSearch,
          ),
          const SizedBox(height: 20),
          // Tab Bar (unchanged)
          // ...
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4.0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double tabTextSize = constraints.maxWidth < 400 ? 12 : 16;
                  double horizontalPadding =
                      constraints.maxWidth < 400 ? 8 : 16;

                  return TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: Color(0xff13BC8D),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    indicatorColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.black,
                    labelPadding: EdgeInsets.symmetric(horizontal: 16),
                    tabs: [
                      Tab(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding, vertical: 8),
                          child: Text(
                            'All',
                            style: TextStyle(fontSize: tabTextSize),
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding, vertical: 8),
                          child: Text(
                            'Relative',
                            style: TextStyle(fontSize: tabTextSize),
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: horizontalPadding, vertical: 8),
                          child: Text(
                            'Contacts',
                            style: TextStyle(fontSize: tabTextSize),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                TransactionList(groupedTransactions: filteredTransactions),
                TransactionListFromSortedEntries(
                    sortedTransactions: sortedByTransactionCount),
                ContactsTransactionList(
                    groupedTransactions: filteredTransactions,
                    contacts: contactProvider.contacts),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
