import 'dart:collection';

Map<String, List<Map<String, dynamic>>> groupTransactionsByPhoneNumber(
    List<Map<String, dynamic>> transactions) {
  Map<String, List<Map<String, dynamic>>> grouped = LinkedHashMap();

  for (var transaction in transactions) {
    // Check if the phone number exists and is not empty
    final phoneNumber = transaction['phoneNumber'];
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      if (grouped.containsKey(phoneNumber)) {
        grouped[phoneNumber]!.add(transaction);
      } else {
        grouped[phoneNumber] = [transaction];
      }
    }
  }

  return grouped;
}

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
    ..sort((a, b) =>
        b.value.length.compareTo(a.value.length)); // Sort by transaction count

  return sortedEntries;
}
