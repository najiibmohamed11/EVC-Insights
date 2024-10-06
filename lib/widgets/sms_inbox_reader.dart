import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';

class SmsPage extends StatefulWidget {
  @override
  _SmsPageState createState() => _SmsPageState();
}

class _SmsPageState extends State<SmsPage> {
  final SmsQuery _query = SmsQuery();

  // Request SMS Permission and fetch messages
  Future<void> _fetchAndPrintSms() async {
    var permission = await Permission.sms.status;
    
    if (!permission.isGranted) {
      permission = await Permission.sms.request();
    }
    
    if (permission.isGranted) {
      try {
        final messages = await _query.querySms(
          kinds: [SmsQueryKind.inbox],
          count: 10, // Get the last 10 messages
        );
        // Log the messages to the console
        messages.forEach((message) {
          print('From: ${message.address}');
          print('Message: ${message.body}');
          print('Date: ${message.date}');
          print('---');
        });
      } catch (e) {
        print('Error fetching SMS: $e');
      }
    } else {
      print('SMS permission denied');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SMS Reader'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _fetchAndPrintSms,
          child: Text('Fetch and Print SMS'),
        ),
      ),
    );
  }
}

