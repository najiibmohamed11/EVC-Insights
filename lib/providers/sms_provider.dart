import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class SmsProvider with ChangeNotifier {
  final SmsQuery _query = SmsQuery();

  List<Map<String, dynamic>> _allFormattedMessages = [];
  List<Map<String, dynamic>> _sentMessages = [];
  List<Map<String, dynamic>> _receivedMessages = [];
  double _balance = 0;
  String _currentFilter = 'Sent'; // 'All', 'Sent', or 'Received'
  bool _isDataFetched = false;

  List<Map<String, dynamic>> get allFormattedMessages => _allFormattedMessages;
  List<Map<String, dynamic>> get sentMessages => _sentMessages;
  List<Map<String, dynamic>> get receivedMessages => _receivedMessages;
  double get balance => _balance;
  String get currentFilter => _currentFilter;

  Future<void> fetchSms() async {
    final permission = await Permission.sms.status;
    print('what is going on $_isDataFetched');
    if (_isDataFetched) return; // Don't refetch if data is already loaded

    if (!permission.isGranted) {
      await Permission.sms.request();
    }

    if (await Permission.sms.isGranted) {
      try {
        final messages = await _query.querySms(address: '192');
        _allFormattedMessages = _processMessages(messages);
        _sentMessages = _allFormattedMessages
            .where((msg) => msg['type'] == 'sent')
            .toList();
        _receivedMessages = _allFormattedMessages
            .where((msg) => msg['type'] == 'received')
            .toList();
        _balance = _allFormattedMessages.isNotEmpty
            ? _allFormattedMessages.first['remainer']
            : 0;
        _isDataFetched = true; // Mark data as fetched

        notifyListeners();
      } catch (e) {
        print('Error fetching SMS: $e');
      }
    } else {
      print('SMS permission denied');
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  List<Map<String, dynamic>> getFilteredMessages() {
    switch (_currentFilter) {
      case 'Sent':
        return _sentMessages;
      case 'Received':
        return _receivedMessages;
      default:
        return _allFormattedMessages;
    }
  }

  List<Map<String, dynamic>> _processMessages(List<SmsMessage> messages) {
    return messages.map((message) {
      final body = message.body ?? '';
      final isReceived = body.contains("waxaad \$");
      final amount = double.tryParse(
              RegExp(r'\$(\d+(\.\d+)?)').firstMatch(body)?.group(1) ?? '0') ??
          0;
      final phoneNumber = RegExp(r'(\d{9,})').firstMatch(body)?.group(1) ?? '';

      final dateMatch = RegExp(r'Tar: (\d{2}/\d{2}/\d{2})').firstMatch(body);
      DateTime date;
      if (dateMatch != null) {
        final dateString = dateMatch.group(1)!;
        date = DateFormat('dd/MM/yy').parse(dateString);
      } else {
        date = message.date ?? DateTime.now();
      }

      final remainer = double.tryParse(
              RegExp(r'waa \$(\d+(\.\d+)?)').firstMatch(body)?.group(1) ??
                  '0') ??
          0;

      return {
        'type': isReceived ? 'received' : 'sent',
        'amount': amount,
        'phoneNumber': phoneNumber,
        'date': date,
        'remainer': remainer,
      };
    }).toList();
  }

  double calculateBalance() {
    return allFormattedMessages.isNotEmpty
        ? allFormattedMessages.first['remainer']
        : 0;
  }
}
