import 'package:flutter/material.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sms_reader/pages/home.dart';

class SmsPage extends StatefulWidget {
  @override
  _SmsPageState createState() => _SmsPageState();
}

class _SmsPageState extends State<SmsPage> {
  final SmsQuery _query = SmsQuery();

  // Request SMS Permission and fetch messages

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SMS Reader'),
      ),
      body: Home()
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: SmsPage(),
  ));
}
