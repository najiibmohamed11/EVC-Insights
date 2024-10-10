import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sms_reader/pages/home/home.dart';
import 'package:sms_reader/pages/main/mainScreen.dart';
import 'package:sms_reader/pages/transactions/transactionPage%20.dart';
import 'package:sms_reader/providers/sms_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SmsProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(debugShowCheckedModeBanner: false, home: MaineScreen()
    );
  }
}



