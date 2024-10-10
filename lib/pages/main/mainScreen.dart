import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:sms_reader/pages/home/home.dart';
import 'package:sms_reader/pages/settings/settings.dart';
import 'package:sms_reader/pages/transactions/transactionPage%20.dart';

class MaineScreen extends StatefulWidget {
  const MaineScreen({super.key});

  @override
  State<MaineScreen> createState() => _MaineScreenState();
}

class _MaineScreenState extends State<MaineScreen> {
  int _selectedIndex = 0; // Track the selected tab index

  // Define the list of pages that correspond to the tabs
  final List<Widget> _pages = [
    Home(),
    TransactionPage(),
    SettingPage(), // Create this page as well
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.white,
        color: Color(0xff13BC8D),
        animationDuration: Duration(milliseconds: 300),
        items: <Widget>[
          Icon(
            Icons.home,
            size: 30,
            color: Colors.white,
          ),
          Icon(
            Icons.message,
            size: 30,
            color: Colors.white,
          ),
          Icon(
            Icons.settings,
            size: 30,
            color: Colors.white,
          ),
        ],
        onTap: (index) {
          //Handle button tap
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      appBar: AppBar(
        title: Text("SMS Reader"),
      ),
      body: _pages[_selectedIndex], // Display the selected page
    );
  }
}
